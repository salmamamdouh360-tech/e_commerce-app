import 'package:cloud_firestore/cloud_firestore.dart';

class OrderStatus {
  static const pending = 'pending';
  static const confirmed = 'confirmed';
  static const preparing = 'preparing';
  static const shipped = 'shipped';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';

  /// Business rules: which status can follow which.
  /// Cancellation is allowed until the order is shipped.
  static const Map<String, List<String>> transitions = {
    pending: [confirmed, cancelled],
    confirmed: [preparing, cancelled],
    preparing: [shipped, cancelled],
    shipped: [delivered],
    delivered: [],
    cancelled: [],
  };
}

class OrderItem {
  final String productId;
  final String name; // name at purchase time
  final double price; // price at purchase time
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productId: m['productId'] ?? '',
        name: m['name'] ?? '',
        price: ((m['price'] ?? 0) as num).toDouble(),
        quantity: ((m['quantity'] ?? 1) as num).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
      };
}

class AppOrder {
  final String id;
  final String userId;
  final String customerName;
  final List<OrderItem> items;
  final double totalPrice;
  final String shippingAddress;
  final String phone;
  final String status;
  final DateTime createdAt;

  const AppOrder({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.items,
    required this.totalPrice,
    required this.shippingAddress,
    required this.phone,
    required this.status,
    required this.createdAt,
  });

  factory AppOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppOrder(
      id: doc.id,
      userId: d['userId'] ?? '',
      customerName: d['customerName'] ?? '',
      items: ((d['items'] ?? []) as List)
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      totalPrice: ((d['totalPrice'] ?? 0) as num).toDouble(),
      shippingAddress: d['shippingAddress'] ?? '',
      phone: d['phone'] ?? '',
      status: d['status'] ?? OrderStatus.pending,
      // createdAt is null for a moment while serverTimestamp is pending.
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
