import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';

/// Alertes de budget sous forme de notifications locales (Android et iOS).
/// Sur les autres plateformes, ces fonctions ne font rien.
final _plugin = FlutterLocalNotificationsPlugin();

bool get _supported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Box<String>? get _settings =>
    Hive.isBoxOpen('settings') ? Hive.box<String>('settings') : null;

/// `true` si l'utilisateur a accepté les alertes (choix enregistré).
bool get notificationsEnabled => _settings?.get('notifications') == '1';

Future<void> initNotifications() async {
  if (!_supported) return;
  await _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      // La permission iOS est demandée à l'écran d'autorisations, pas au lancement.
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );
}

/// Demande la permission système et mémorise le choix. Retourne `true` si accordée.
Future<bool> requestNotificationPermission() async {
  var granted = false;
  if (_supported) {
    granted = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }
  await setNotificationsEnabled(granted);
  return granted;
}

Future<void> setNotificationsEnabled(bool enabled) async {
  await _settings?.put('notifications', enabled ? '1' : '0');
}

/// Affiche une alerte de budget si les notifications sont activées.
Future<void> notifyBudgetAlert(String title, String body) async {
  if (!_supported || !notificationsEnabled) return;
  await _plugin.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'budget_alerts',
        'Alertes de budget',
        channelDescription: 'Prévient quand un budget approche de sa limite.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
  );
}
