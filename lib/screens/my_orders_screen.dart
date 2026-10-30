import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';
import '../widgets/app_widgets.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: StreamBuilder<List<AppOrder>>(
        stream: OrderService().watchMyOrders(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const ErrorView(message: 'Could not load your orders');
          }
          if (!snap.hasData) return const LoadingView();
          final orders = snap.data!;
          if (orders.isEmpty) {
            return const EmptyView(
              icon: Icons.receipt_long_outlined,
              message: 'No orders yet',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final o = orders[i];
              return Card(
                child: ListTile(
                  title: Text('Order #${shortId(o.id)}'),
                  subtitle: Text('${formatDate(o.createdAt)}\n${money(o.totalPrice)}'),
                  isThreeLine: true,
                  trailing: StatusChip(status: o.status),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(orderId: o.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
