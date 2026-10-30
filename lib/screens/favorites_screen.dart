import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/favorites_service.dart';
import '../services/product_service.dart';
import '../widgets/app_widgets.dart';
import '../widgets/product_grid.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: StreamBuilder<Set<String>>(
        stream: FavoritesService().watchIds(),
        builder: (context, favSnap) {
          if (favSnap.hasError) {
            return const ErrorView(message: 'Could not load favorites');
          }
          if (!favSnap.hasData) return const LoadingView();
          final ids = favSnap.data!;

          return StreamBuilder<List<Product>>(
            stream: ProductService().watchProducts(),
            builder: (context, prodSnap) {
              if (!prodSnap.hasData) return const LoadingView();
              final favs =
                  prodSnap.data!.where((p) => ids.contains(p.id)).toList();
              if (favs.isEmpty) {
                return const EmptyView(
                  icon: Icons.favorite_border,
                  message: 'No favorites yet',
                );
              }
              return ProductGrid(products: favs, favIds: ids);
            },
          );
        },
      ),
    );
  }
}
