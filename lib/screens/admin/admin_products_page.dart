import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/app_widgets.dart';
import 'product_form_screen.dart';

class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key});

  Future<void> _delete(BuildContext context, Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('"${p.name}" will be removed permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ProductService().deleteProduct(p.id);
      if (!context.mounted) return;
      showAppSnack(context, 'Product deleted');
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      showAppSnack(context, e.message ?? 'Could not delete', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: ProductService().watchProducts(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const ErrorView(message: 'Could not load products');
        }
        if (!snap.hasData) return const LoadingView();
        final products = snap.data!;
        if (products.isEmpty) {
          return const EmptyView(
              icon: Icons.inventory_2_outlined,
              message: 'No products yet. Tap + to add one.');
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
          itemCount: products.length,
          itemBuilder: (_, i) {
            final p = products[i];
            return Card(
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                      width: 56, height: 56, child: ProductImage(url: p.imageUrl)),
                ),
                title: Text(p.name),
                subtitle: Text(
                    '${money(p.price)} • stock ${p.stock}${p.isAvailable ? '' : ' • hidden'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProductFormScreen(product: p)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => _delete(context, p),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
