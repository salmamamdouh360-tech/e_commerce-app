import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../screens/order_details_screen.dart';

/// Runs in a separate isolate when a message arrives and the app is in the
/// background / terminated. The OS already shows the notification (because the
/// message has a `notification` payload), so we only need to init Firebase.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  final _fm = FirebaseMessaging.instance;

  Future<void> init() async {
    // Shows the permission dialog on Android 13+ / iOS.
    await _fm.requestPermission();

    // 1) Foreground: the OS does NOT show a notification, so we show a SnackBar.
    FirebaseMessaging.onMessage.listen(_onForeground);

    // 2) Background: user taps the notification -> app comes to foreground.
    FirebaseMessaging.onMessageOpenedApp.listen(_openOrder);

    // 3) Terminated: user taps the notification -> app launches.
    final initial = await _fm.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openOrder(initial));
    }

    // Token changes (reinstall, restore, expiry...).
    _fm.onTokenRefresh.listen(_storeToken);
  }

  /// Call after login (needs a signed-in user + an existing user document).
  Future<void> saveToken() async {
    final token = await _fm.getToken();
    if (token != null) await _storeToken(token);
  }

  Future<void> _storeToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (_) {/* user doc may not exist yet; saved again on next start */}
  }

  /// Call BEFORE sign-out so the previous user stops receiving this device's pushes.
  Future<void> removeToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final token = await _fm.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (_) {}
  }

  void _onForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${n.title ?? ''}\n${n.body ?? ''}'),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'VIEW',
            onPressed: () => _openOrder(message),
          ),
        ),
      );
  }

  void _openOrder(RemoteMessage message) {
    final orderId = message.data['orderId'];
    if (orderId == null || FirebaseAuth.instance.currentUser == null) return;
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: orderId)),
    );
  }
}
