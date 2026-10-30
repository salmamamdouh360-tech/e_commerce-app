import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../services/auth_service.dart';
import '../shared/custom_text_form_filed.dart';
import '../widgets/app_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await AuthService().resetPassword(_email.text.trim());
      if (!mounted) return;
      showAppSnack(context, 'Reset link sent. Check your email.');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showAppSnack(context, AuthService.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Enter your email and we'll send you a reset link."),
              const Gap(20),
              AppTextField(
                controller: _email,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'enter a valid email'
                    : null,
              ),
              const Gap(24),
              PrimaryButton(
                text: 'Send reset link',
                onPressed: _send,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
