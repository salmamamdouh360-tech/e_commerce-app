import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../widgets/app_widgets.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartService();
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: StreamBuilder<List<CartItem>>(
        stream: cart.watchCart(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const ErrorView(message: 'Could not load your cart');
          }
          if (!snap.hasData) return const LoadingView();
          final items = snap.data!;
          if (items.isEmpty) {
            return const EmptyView(
              icon: Icons.shopping_cart_outlined,
              message: 'Your cart is empty',
            );
          }
          final total = items.fold<double>(0, (s, i) => s + i.subtotal);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 70,
                                height: 70,
                                child: ProductImage(url: item.imageUrl),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(money(item.price)),
                                  Text('Subtotal: ${money(item.subtotal)}',
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () => cart.setQuantity(
                                          item.productId, item.quantity - 1),
                                    ),
                                    Text('${item.quantity}'),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () => cart.setQuantity(
                                          item.productId, item.quantity + 1),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: AppColors.error),
                                  onPressed: () => cart.remove(item.productId),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(money(total),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        text: 'Checkout',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(items: items),
                          ),
                        ),
                      ),
                    ],
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
