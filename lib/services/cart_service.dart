import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import 'refs.dart';

class CartService {
  CollectionReference<Map<String, dynamic>> get _col =>
      currentUserDoc().collection('cart');

  Stream<List<CartItem>> watchCart() =>
      _col.snapshots().map((s) => s.docs.map(CartItem.fromDoc).toList());

  /// Adds 1 (or [qty]) of the product; never goes above the available stock.
  Future<void> addToCart(Product p, {int qty = 1}) {
    final ref = _col.doc(p.id);
    return FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current =
          snap.exists ? ((snap.data()!['quantity'] ?? 0) as num).toInt() : 0;
      tx.set(ref, {
        'productId': p.id,
        'name': p.name,
        'imageUrl': p.imageUrl,
        'price': p.price,
        'quantity': math.min(current + qty, p.stock),
      });
    });
  }

  Future<void> setQuantity(String productId, int quantity) {
    if (quantity <= 0) return remove(productId);
    return _col.doc(productId).update({'quantity': quantity});
  }

  Future<void> remove(String productId) => _col.doc(productId).delete();
}
