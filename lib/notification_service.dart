// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> initialize() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: initializationSettingsAndroid);

//     await _notificationsPlugin.initialize(initializationSettings);
//   }

//   static Future<void> showNotification({
//     required String title,
//     required String body,
//   }) async {
//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//           'order_channel', // unique id
//           'Orders', // channel name
//           channelDescription: 'Order notifications',
//           importance: Importance.max,
//           priority: Priority.high,
//         );

//     const NotificationDetails details = NotificationDetails(
//       android: androidDetails,
//     );

//     await _notificationsPlugin.show(
//       0, // notification id
//       title,
//       body,
//       details,
//     );
//   }
// }
