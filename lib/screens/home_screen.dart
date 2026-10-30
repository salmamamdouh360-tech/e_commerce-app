import 'package:e_commerce_app/models/product.dart';
import 'package:e_commerce_app/services/favorites_service.dart';
import 'package:e_commerce_app/services/product_service.dart';
import 'package:e_commerce_app/widgets/product_grid.dart';
import 'package:flutter/material.dart';

import '../widgets/app_widgets.dart';

/// Product catalog: search by name + filter/browse by category.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _products = ProductService();
  final _favs = FavoritesService();
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: StreamBuilder<List<Product>>(
        stream: _products.watchProducts(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const ErrorView(message: 'Could not load products');
          }
          if (!snap.hasData) return const LoadingView();

          final all = snap.data!;
          final categories =
              all
                  .map((p) => p.category)
                  .where((c) => c.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

          final shown = all.where((p) {
            final matchesName = p.name.toLowerCase().contains(
              _query.trim().toLowerCase(),
            );
            final matchesCategory =
                _category == null || p.category == _category;
            return matchesName && matchesCategory;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search products',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: _category == null,
                        onSelected: (_) => setState(() => _category = null),
                      ),
                    ),
                    for (final c in categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = c),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? const EmptyView(
                        icon: Icons.search_off,
                        message: 'No products found',
                      )
                    : StreamBuilder<Set<String>>(
                        stream: _favs.watchIds(),
                        builder: (context, favSnap) => ProductGrid(
                          products: shown,
                          favIds: favSnap.data ?? {},
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
