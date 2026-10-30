import 'package:flutter/material.dart';

import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../widgets/app_widgets.dart';
import '../order_details_screen.dart';

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppOrder>>(
      stream: OrderService().watchAllOrders(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const ErrorView(message: 'Could not load orders');
        }
        if (!snap.hasData) return const LoadingView();
        final orders = snap.data!;
        if (orders.isEmpty) {
          return const EmptyView(
              icon: Icons.receipt_long_outlined, message: 'No orders yet');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          itemBuilder: (_, i) {
            final o = orders[i];
            return Card(
              child: ListTile(
                title: Text('#${shortId(o.id)} • ${o.customerName}'),
                subtitle: Text('${formatDate(o.createdAt)}\n${money(o.totalPrice)}'),
                isThreeLine: true,
                trailing: StatusChip(status: o.status),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(orderId: o.id, admin: true),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
