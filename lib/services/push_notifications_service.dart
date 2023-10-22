import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();

  if(message.data.containsKey('data')) {
    final data = message.data['data'];
  }

  if(message.data.containsKey('notification')) {
    final notification = message.data['notification'];
  }
}

class PushNotificationsService {
  final streamCtrl = StreamController<String>.broadcast();
  final titleCtrl = StreamController<String>.broadcast();
  final bodyCtrl = StreamController<String>.broadcast();

  setNotifications() {
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);

    // handle when app is in active state
    foregroundNotifier();

    // handle when app is running in background
    backgroundNotifier();

    // handle when app is terminated
    terminatedNotifier();
  }

  foregroundNotifier() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data.containsKey('data')) {
        // handle data message
        streamCtrl.sink.add(message.data['data']);
      }
      if(message.data.containsKey('notification')) {
        // handle notification message
        streamCtrl.sink.add(message.data['notification']);
      }

      // or do other work
      titleCtrl.sink.add(message.notification.title);
      bodyCtrl.sink.add(message.notification.body);
    });
  }

  backgroundNotifier() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.containsKey('data')) {
        // handle data message
        streamCtrl.sink.add(message.data['data']);
      }
      if(message.data.containsKey('notification')) {
        // handle notification message
        streamCtrl.sink.add(message.data['notification']);
      }

      // or do other work
      titleCtrl.sink.add(message.notification.title);
      bodyCtrl.sink.add(message.notification.body);
    });
  }

  terminatedNotifier() async {
    RemoteMessage initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();

    if (initialMessage != null) {
      if (initialMessage.data.containsKey('data')) {
        // handle data message
        streamCtrl.sink.add(initialMessage.data['data']);
      }
      if (initialMessage.data.containsKey('notification')) {
        // handle notification message
        streamCtrl.sink.add(initialMessage.data['notification']);
      }

      // or do other work
      titleCtrl.sink.add(initialMessage.notification.title);
      bodyCtrl.sink.add(initialMessage.notification.body);
    }
  }

  dispose() {
    streamCtrl.close();
    titleCtrl.close();
    bodyCtrl.close();
  }
}