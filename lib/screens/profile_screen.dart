import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../services/auth_service.dart';
import '../shared/custom_text_form_filed.dart';
import '../widgets/app_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String _email = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    AuthService().getCurrentUser().then((u) {
      if (!mounted) return;
      if (u != null) {
        _name.text = u.name;
        _phone.text = u.phone;
        _address.text = u.address;
        _email = u.email;
      }
      setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await AuthService().updateProfile(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
      );
      if (!mounted) return;
      showAppSnack(context, 'Profile saved');
    } on FirebaseException catch (e) {
      if (!mounted) return;
      showAppSnack(context, e.message ?? 'Could not save profile', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(_email, style: const TextStyle(color: Colors.grey)),
                    const Gap(16),
                    AppTextField(
                      controller: _name,
                      label: 'Name',
                      icon: Icons.person_outline,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'this field is required'
                          : null,
                    ),
                    const Gap(16),
                    AppTextField(
                      controller: _phone,
                      label: 'Phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const Gap(16),
                    AppTextField(
                      controller: _address,
                      label: 'Delivery address',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                    const Gap(24),
                    PrimaryButton(
                        text: 'Save', onPressed: _save, isLoading: _saving),
                  ],
                ),
              ),
            ),
    );
  }
}
