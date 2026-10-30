import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../models/cart_item.dart';
import '../services/app_exception.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../shared/custom_text_form_filed.dart';
import '../widgets/app_widgets.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;
  const CheckoutScreen({super.key, required this.items});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  String _customerName = FirebaseAuth.instance.currentUser?.displayName ?? '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill address / phone from the saved profile.
    AuthService().getCurrentUser().then((u) {
      if (u == null || !mounted) return;
      _address.text = u.address;
      _phone.text = u.phone;
      _customerName = u.name;
    });
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'this field is required' : null;

  Future<void> _placeOrder() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final orderId = await OrderService().placeOrder(
        customerName: _customerName,
        address: _address.text.trim(),
        phone: _phone.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: orderId)),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      showAppSnack(context, e.message, error: true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      showAppSnack(context, e.message ?? 'Could not place order', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.fold<double>(0, (s, i) => s + i.subtotal);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Order summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Gap(8),
          Card(
            child: Column(
              children: [
                for (final i in widget.items)
                  ListTile(
                    title: Text(i.name),
                    subtitle: Text('${money(i.price)} × ${i.quantity}'),
                    trailing: Text(money(i.subtotal)),
                  ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Total',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text(money(total),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Gap(20),
          const Text('Delivery information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Gap(8),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _address,
                  label: 'Delivery address',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                  validator: _required,
                ),
                const Gap(16),
                AppTextField(
                  controller: _phone,
                  label: 'Phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: _required,
                ),
              ],
            ),
          ),
          const Gap(20),
          const Card(
            child: ListTile(
              leading: Icon(Icons.payments_outlined),
              title: Text('Cash on Delivery'),
              subtitle: Text('Pay when your order arrives'),
            ),
          ),
          const Gap(20),
          PrimaryButton(
            text: 'Place Order',
            onPressed: _placeOrder,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
