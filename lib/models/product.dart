import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final int stock;
  final bool isAvailable;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.stock,
    required this.isAvailable,
  });

  bool get inStock => isAvailable && stock > 0;

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Product(
      id: doc.id,
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      price: ((d['price'] ?? 0) as num).toDouble(),
      imageUrl: d['imageUrl'] ?? '',
      category: d['category'] ?? '',
      stock: ((d['stock'] ?? 0) as num).toInt(),
      isAvailable: d['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'category': category,
        'stock': stock,
        'isAvailable': isAvailable,
      };
}
