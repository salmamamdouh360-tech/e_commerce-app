import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at users/{uid}/cart/{productId}.
/// name / price / imageUrl are only a display snapshot — the real price is
/// re-read from `products` when the order is placed.
class CartItem {
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;

  const CartItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  factory CartItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return CartItem(
      productId: doc.id,
      name: d['name'] ?? '',
      imageUrl: d['imageUrl'] ?? '',
      price: ((d['price'] ?? 0) as num).toDouble(),
      quantity: ((d['quantity'] ?? 1) as num).toInt(),
    );
  }
}
