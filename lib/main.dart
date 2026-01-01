import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:house_to_motive/views/login/splash_screen.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'firebase_options.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// 1/5: define a navigator key
  final navigatorKey = GlobalKey<NavigatorState>();

  /// 2/5: set navigator key to ZegoUIKitPrebuiltCallInvitationService
  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

  ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI(
    [ZegoUIKitSignalingPlugin()],
  );

  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp(navigatorKey: navigatorKey));
}



// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
// }

class MyApp extends StatefulWidget {
  GlobalKey<NavigatorState>? navigatorKey;

   MyApp({
    this.navigatorKey,
    super.key,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // void _setupFirebaseMessaging() {
  //   FirebaseMessaging.instance.getToken().then((String? token) {
  //     assert(token != null);
  //     log("Push Messaging token: $token");
  //     // Save the token
  //   }).catchError((error) {
  //     log("Error getting APNS token: $error");
  //   });
  //
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     log('Got a message whilst in the foreground!');
  //     log('Message data: ${message.data}');
  //
  //     if (message.notification != null) {
  //       log('Message also contained a notification: ${message.notification}');
  //     }
  //   });
  //
  //   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //     log('A new onMessageOpenedApp event was published!');
  //     log('Message data: ${message.data}');
  //   });
  // }
  //
  // Future<void> updateDeviceToken() async {
  //   String? deviceToken = await FirebaseMessaging.instance.getToken();
  //
  //   FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(FirebaseAuth.instance.currentUser?.uid)
  //       .update({'Device Token': deviceToken});
  // }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xff025B8F);
    return ResponsiveSizer(builder: (context, orientation, deviceType) {
      return GetMaterialApp(
        navigatorKey: widget.navigatorKey,
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: primaryColor,
          scaffoldBackgroundColor: const Color(0xFFF6F9FF),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        builder: (BuildContext context, Widget? child) {
          return Stack(
            children: [
              child!,
              ZegoUIKitPrebuiltCallMiniOverlayPage(
                avatarBuilder: (context, size, user, extraInfo) =>
                const CircleAvatar(backgroundColor: Colors.blue),
                contextQuery: () {
                  return widget.navigatorKey!.currentState!.context;
                },
              ),
            ],
          );
        },
      );
    });
  }
}