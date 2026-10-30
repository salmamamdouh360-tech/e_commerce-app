import 'package:flutter/material.dart';

import '../models/product.dart';
import '../screens/product_details_screen.dart';
import '../services/favorites_service.dart';
import 'app_widgets.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final Set<String> favIds;
  const ProductGrid({super.key, required this.products, required this.favIds});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => ProductCard(
        product: products[i],
        isFav: favIds.contains(products[i].id),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isFav;
  const ProductCard({super.key, required this.product, required this.isFav});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(productId: product.id),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(url: product.imageUrl),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      style: IconButton.styleFrom(backgroundColor: Colors.white70),
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: () => FavoritesService()
                          .toggle(product.id, isFavorite: isFav),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    money(product.price),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (!product.inStock)
                    const Text('Out of stock',
                        style: TextStyle(color: AppColors.error, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
