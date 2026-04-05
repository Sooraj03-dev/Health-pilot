import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/providers/auth_provider.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  RealtimeChannel? _subscription;

  Future<void> init() async {
    // Initialize standard permissions and settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'sos_alerts_channel',
      'SOS Alerts',
      channelDescription: 'Notifications for patient SOS alerts',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  void subscribeToSOSAlerts(String doctorId) {
    // Cancel any existing subscription
    _subscription?.unsubscribe();

    _subscription = supabase
        .channel('public:sos_alerts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'sos_alerts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'assigned_doctor_id',
            value: doctorId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            final String patientName = newRecord['patient_name'] ?? 'A patient';
            // Use local timestamp if created_at is null
            final String timestamp = newRecord['created_at'] != null 
              ? DateTime.parse(newRecord['created_at']).toLocal().toString() 
              : DateTime.now().toString();
            
            showNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000, 
              title: 'CRITICAL: SOS Alert!',
              body: '$patientName triggered an SOS alert at $timestamp',
            );
          },
        )
        .subscribe();
  }

  void unsubscribeFromSOSAlerts() {
    _subscription?.unsubscribe();
    _subscription = null;
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  // Ensure the instance is ready to receive method calls
  return service;
});

// A top-level provider that manages the SOS subscription by observing Auth state
final sosSubscriptionProvider = Provider<void>((ref) {
  final authState = ref.watch(authProvider);
  final notificationService = ref.read(notificationServiceProvider);

  // If user is a doctor, subscribe. Otherwise, ensure unsubscribed.
  if (authState.isAuthenticated &&
      authState.role?.toLowerCase() == 'doctor' &&
      authState.user?.id != null) {
    notificationService.subscribeToSOSAlerts(authState.user!.id);
  } else {
    notificationService.unsubscribeFromSOSAlerts();
  }
});
