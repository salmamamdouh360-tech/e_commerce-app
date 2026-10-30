import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../services/order_service.dart';
import '../widgets/app_widgets.dart';

/// Used by the customer (read + cancel while pending), by the admin
/// (admin: true -> status buttons) and when a notification is tapped.
class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final bool admin;
  const OrderDetailsScreen({super.key, required this.orderId, this.admin = false});

  Future<void> _changeStatus(BuildContext context, String status) async {
    if (status == OrderStatus.cancelled) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cancel order?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, cancel')),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      await OrderService().updateStatus(orderId, status);
      if (!context.mounted) return;
      showAppSnack(context, 'Status updated to $status');
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      showAppSnack(context, e.message ?? 'Could not update order', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #${shortId(orderId)}')),
      body: StreamBuilder<AppOrder?>(
        stream: OrderService().watchOrder(orderId),
        builder: (context, snap) {
          if (snap.hasError) {
            return const ErrorView(message: 'Could not load this order');
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final o = snap.data;
          if (o == null) {
            return const EmptyView(
                icon: Icons.receipt_long_outlined, message: 'Order not found');
          }
          final next = OrderStatus.transitions[o.status] ?? const <String>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusChip(status: o.status),
                  Text(formatDate(o.createdAt)),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    for (final i in o.items)
                      ListTile(
                        title: Text(i.name),
                        subtitle: Text('${money(i.price)} × ${i.quantity}'),
                        trailing: Text(money(i.subtotal)),
                      ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Total',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(money(o.totalPrice),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Card(
                child: Column(
                  children: [
                    if (admin)
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(o.customerName),
                        subtitle: const Text('Customer'),
                      ),
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(o.shippingAddress),
                      subtitle: const Text('Delivery address'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone_outlined),
                      title: Text(o.phone),
                      subtitle: const Text('Phone'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.payments_outlined),
                      title: Text('Cash on Delivery'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (admin && next.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in next)
                      s == OrderStatus.cancelled
                          ? OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error),
                              onPressed: () => _changeStatus(context, s),
                              child: const Text('Cancel order'),
                            )
                          : ElevatedButton(
                              onPressed: () => _changeStatus(context, s),
                              child: Text('Mark as $s'),
                            ),
                  ],
                ),
              // Customers may cancel only while the order is still pending.
              if (!admin && o.status == OrderStatus.pending)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: () => _changeStatus(context, OrderStatus.cancelled),
                  child: const Text('Cancel order'),
                ),
            ],
          );
        },
      ),
    );
  }
}
