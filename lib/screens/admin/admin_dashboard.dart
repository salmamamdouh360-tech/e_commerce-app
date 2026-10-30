import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'admin_orders_page.dart';
import 'admin_products_page.dart';
import 'product_form_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0 ? 'Products' : 'Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [AdminProductsPage(), AdminOrdersPage()],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductFormScreen()),
              ),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        ],
      ),
    );
  }
}
