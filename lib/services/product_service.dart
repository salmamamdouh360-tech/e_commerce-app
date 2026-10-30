import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

class ProductService {
  final _col = FirebaseFirestore.instance.collection('products');

  Stream<List<Product>> watchProducts() => _col
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(Product.fromDoc).toList());

  Stream<Product?> watchProduct(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Product.fromDoc(d) : null);

  // Admin only (enforced by Firestore rules).
  Future<void> addProduct(Product p) => _col.add(p.toMap());
  Future<void> updateProduct(String id, Product p) =>
      _col.doc(id).update(p.toMap());
  Future<void> deleteProduct(String id) => _col.doc(id).delete();
}
