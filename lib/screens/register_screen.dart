import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../services/auth_service.dart';
import '../shared/custom_text_form_filed.dart';
import '../widgets/app_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'this field is required' : null;

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await AuthService().register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      if (!mounted) return;
      // AuthGate already switched the root screen; close this pushed route.
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showAppSnack(context, AuthService.errorMessage(e), error: true);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      showAppSnack(context, e.message ?? 'Could not create profile', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _name,
                label: 'Full name',
                icon: Icons.person_outline,
                validator: _required,
              ),
              const Gap(16),
              AppTextField(
                controller: _email,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (_required(v) != null) return _required(v);
                  if (!v!.contains('@')) return 'enter a valid email';
                  return null;
                },
              ),
              const Gap(16),
              AppTextField(
                controller: _password,
                label: 'Password',
                icon: Icons.lock_outline,
                isPassword: true,
                validator: (v) {
                  if (_required(v) != null) return _required(v);
                  if (v!.trim().length < 6) return 'at least 6 characters';
                  return null;
                },
              ),
              const Gap(16),
              AppTextField(
                controller: _confirm,
                label: 'Confirm password',
                icon: Icons.lock_outline,
                isPassword: true,
                validator: (v) =>
                    v != _password.text ? 'passwords do not match' : null,
              ),
              const Gap(24),
              PrimaryButton(
                text: 'Register',
                onPressed: _register,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
