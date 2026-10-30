import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/favorites_service.dart';
import '../services/product_service.dart';
import '../widgets/app_widgets.dart';

class ProductDetailsScreen extends StatelessWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  Future<void> _addToCart(BuildContext context, Product p) async {
    try {
      await CartService().addToCart(p);
      if (!context.mounted) return;
      showAppSnack(context, 'Added to cart');
    } catch (_) {
      if (!context.mounted) return;
      showAppSnack(context, 'Could not add to cart', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Product?>(
      stream: ProductService().watchProduct(productId),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: const ErrorView(message: 'Could not load product'),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const LoadingView());
        }
        final p = snap.data;
        if (p == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyView(
                icon: Icons.inventory_2_outlined, message: 'Product not found'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(p.name),
            actions: [
              StreamBuilder<Set<String>>(
                stream: FavoritesService().watchIds(),
                builder: (context, favSnap) {
                  final isFav = favSnap.data?.contains(p.id) ?? false;
                  return IconButton(
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red),
                    onPressed: () =>
                        FavoritesService().toggle(p.id, isFavorite: isFav),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            children: [
              SizedBox(height: 300, child: ProductImage(url: p.imageUrl)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(money(p.price),
                        style: const TextStyle(
                            fontSize: 20,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (p.category.isNotEmpty) Chip(label: Text(p.category)),
                        Chip(
                          label: Text(p.inStock
                              ? 'In stock: ${p.stock}'
                              : 'Out of stock'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(p.description),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                text: p.inStock ? 'Add to cart' : 'Out of stock',
                onPressed: p.inStock ? () => _addToCart(context, p) : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
