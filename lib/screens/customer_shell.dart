import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../services/notification_service.dart';
import 'cart_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';

/// Customer interface: bottom navigation with 5 tabs.
class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Store this device's FCM token on the signed-in user's document.
    NotificationService.instance.saveToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          FavoritesScreen(),
          CartScreen(),
          MyOrdersScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.storefront_outlined), label: 'Shop'),
          const NavigationDestination(
              icon: Icon(Icons.favorite_border), label: 'Favorites'),
          NavigationDestination(
            icon: StreamBuilder<List<CartItem>>(
              stream: CartService().watchCart(),
              builder: (context, snap) {
                final count = snap.data?.fold<int>(0, (s, i) => s + i.quantity) ?? 0;
                return Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.shopping_cart_outlined),
                );
              },
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
