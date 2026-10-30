import 'package:cloud_firestore/cloud_firestore.dart';

import 'refs.dart';

class FavoritesService {
  CollectionReference<Map<String, dynamic>> get _col =>
      currentUserDoc().collection('favorites');

  /// The set of favorite product ids (the doc id is the product id).
  Stream<Set<String>> watchIds() =>
      _col.snapshots().map((s) => s.docs.map((d) => d.id).toSet());

  Future<void> toggle(String productId, {required bool isFavorite}) {
    if (isFavorite) return _col.doc(productId).delete();
    return _col.doc(productId).set({
      'productId': productId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
