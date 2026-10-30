import 'package:flutter/material.dart';

import '../widgets/app_widgets.dart';
import 'order_details_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 96, color: AppColors.success),
              const SizedBox(height: 16),
              const Text('Order placed!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Order #${shortId(orderId)}'),
              const SizedBox(height: 4),
              const Text("We'll notify you when the status changes."),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Track order',
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(orderId: orderId),
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Continue shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
