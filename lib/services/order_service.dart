import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order_model.dart';
import '../models/product.dart';
import 'app_exception.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  /// Validates stock, snapshots name+price, creates the order, decrements
  /// stock — all inside ONE transaction so two customers can't buy the last
  /// item at the same time. Then clears the cart.
  Future<String> placeOrder({
    required String customerName,
    required String address,
    required String phone,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final cartCol = _db.collection('users').doc(uid).collection('cart');
    final cartSnap = await cartCol.get();
    if (cartSnap.docs.isEmpty) throw AppException('Your cart is empty');

    final orderRef = _orders.doc();

    await _db.runTransaction((tx) async {
      // 1) ALL reads first (Firestore requires reads before writes).
      final products = <Product>[];
      final quantities = <int>[];
      for (final doc in cartSnap.docs) {
        final qty = ((doc.data()['quantity'] ?? 1) as num).toInt();
        final pSnap = await tx.get(_db.collection('products').doc(doc.id));
        if (!pSnap.exists) {
          throw AppException('A product in your cart is no longer available');
        }
        final p = Product.fromDoc(pSnap);
        if (!p.inStock) throw AppException('"${p.name}" is out of stock');
        if (qty > p.stock) {
          throw AppException('Only ${p.stock} left of "${p.name}"');
        }
        products.add(p);
        quantities.add(qty);
      }

      // 2) Then all writes.
      double total = 0;
      final items = <Map<String, dynamic>>[];
      for (var i = 0; i < products.length; i++) {
        final p = products[i];
        total += p.price * quantities[i];
        items.add(OrderItem(
          productId: p.id,
          name: p.name, // snapshot, so later edits don't change history
          price: p.price,
          quantity: quantities[i],
        ).toMap());
        tx.update(_db.collection('products').doc(p.id),
            {'stock': p.stock - quantities[i]});
      }

      tx.set(orderRef, {
        'userId': uid,
        'customerName': customerName,
        'items': items,
        'totalPrice': total,
        'shippingAddress': address,
        'phone': phone,
        'status': OrderStatus.pending,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    // Clear the cart after a successful order.
    final batch = _db.batch();
    for (final doc in cartSnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    return orderRef.id;
  }

  Stream<List<AppOrder>> watchMyOrders() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    // Sorted on the client to avoid needing a composite index.
    return _orders.where('userId', isEqualTo: uid).snapshots().map((s) {
      final list = s.docs.map(AppOrder.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<AppOrder>> watchAllOrders() => _orders
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppOrder.fromDoc).toList());

  Stream<AppOrder?> watchOrder(String id) => _orders
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? AppOrder.fromDoc(d) : null);

  Future<void> updateStatus(String orderId, String status) =>
      _orders.doc(orderId).update({'status': status});
}
