import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enawra/auth/register/register.dart';
import 'package:enawra/services/push_notifications_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:enawra/components/life_cycle_event_handler.dart';
import 'package:enawra/screens/mainscreen.dart';
import 'package:enawra/services/user_service.dart';
import 'package:enawra/utils/config.dart';
import 'package:enawra/utils/constants.dart';
import 'package:enawra/utils/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Config.initFirebase();

  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    // final RemoteMessage remoteMessage = await FirebaseMessaging.instance.getInitialMessage();
    final RemoteMessage remoteMessage = Config.initFirebase();

    // await HelperNotification.initialize()
    // FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    print("fcm token $fcmToken");
    print(remoteMessage.data);
    print(remoteMessage.notification!.body);
    print("remote messageeeeee: $remoteMessage");

    // if(remoteMessage != null) {
    //
    // }

  } catch(e) {}

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(
      LifecycleEventHandler(
        detachedCallBack: () => UserService().setUserStatus(false),
        resumeCallBack: () => UserService().setUserStatus(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: Consumer<ThemeNotifier>(
        builder: (context, ThemeNotifier notifier, child) {
          return MaterialApp(
            title: Constants.appName,
            debugShowCheckedModeBanner: false,
            theme: notifier.dark ? Constants.darkTheme : Constants.lightTheme,
            home: StreamBuilder(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (BuildContext context, snapshot) {
                if (snapshot.hasData) {
                  return TabScreen();
                } else
                  return Register();
              },
            ),
          );
        },
      ),
    );
  }
}
