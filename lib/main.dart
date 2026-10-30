import 'package:e_commerce_app/models/app_user.dart';
import 'package:e_commerce_app/screens/admin/admin_dashboard.dart';
import 'package:e_commerce_app/screens/customer_shell.dart';
import 'package:e_commerce_app/screens/login_screen.dart';
import 'package:e_commerce_app/widgets/app_widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Commerce',
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
      scaffoldMessengerKey: NotificationService.messengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: const Color(0xFFF6F6FA),
      ),
      home: const AuthGate(),
    );
  }
}

/// Decides what to show: Login, Customer app, or Admin dashboard.
/// The role comes from Firestore (users/{uid}.role), never from the UI.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder<User?>(
      stream: auth.authChanges,
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
        }
        final user = authSnap.data;
        if (user == null) return const LoginScreen();

        return StreamBuilder<AppUser?>(
          stream: auth.watchUser(user.uid),
          builder: (context, userSnap) {
            if (userSnap.hasError) {
              return const Scaffold(
                body: ErrorView(message: 'Could not load your profile'),
              );
            }
            final appUser = userSnap.data;
            // Right after sign-up the user document may not exist for a moment.
            if (appUser == null) return const Scaffold(body: LoadingView());
            return appUser.isAdmin
                ? const AdminDashboard()
                : const CustomerShell();
          },
        );
      },
    );
  }
}
