import 'dart:developer';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:house_to_motive/utils/utils.dart';
import 'package:house_to_motive/widgets/custom_socialbutton.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../utils/zegocalls/login_services.dart';
import '../../widgets/loginbutton.dart';
import '../../widgets/custom_field.dart';
import '../createan_account/signup_screen.dart';
import '../screens/navigation_bar/home_page.dart';

class LoginWithEmailScreen extends StatelessWidget {
  LoginWithEmailScreen({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final RxBool isLoading = false.obs;
  final loginFormKey = GlobalKey<FormState>();

  final FirebaseAuth auth = FirebaseAuth.instance;

  final AuthenticationController authenticationController =
      Get.put(AuthenticationController());

  void continueAsGuest() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isGuest', true);
    Get.to(
      () => HomePage(),
      transition: Transition.downToUp,
    );
  }

  void Login() async {
    // final _firebaseMessaging = FirebaseMessaging.instance;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    isLoading.value = true;

    auth
        .signInWithEmailAndPassword(
            email: emailController.text, password: passwordController.text)
        .then((value) async {
      // final fCMToken = await _firebaseMessaging.getToken();
      updateDeviceToken();
      login(
        userID: FirebaseAuth.instance.currentUser!.uid,
        userName: 'user_${FirebaseAuth.instance.currentUser!.uid}',
      ).then((value) {
        onUserLogin();
      });
      prefs.setBool('isLogin', true);
      prefs.setBool('isGuest', false);
      Get.to(
        () => HomePage(),
        transition: Transition.downToUp,
      );
      isLoading.value = false;
      Utils().ToastMessage('Login Successfully');
    }).onError((error, stackTrace) {
      isLoading.value = false;
      debugPrint(error.toString());
      Utils().ToastMessage(error.toString());
    });
  }

  Future<void> updateDeviceToken() async {
    // String? deviceToken = await FirebaseMessaging.instance.getToken();

    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .update({'Device Token': ""});
  }

  // Future<void> getAllToken() async {
  //   FirebaseFirestore.instance.collection('users').doc().get();
  //
  //   try {
  //     QuerySnapshot<Map<String, dynamic>> snapshot =
  //         await FirebaseFirestore.instance.collection('users').get();
  //     List<String> deviceTokens = [];
  //
  //     snapshot.docs.forEach((doc) {
  //       String deviceToken = doc.data()['Device Token'];
  //
  //       if (deviceToken != null || deviceToken.isNotEmpty) {
  //         deviceTokens.add(deviceToken);
  //         print('device token: ${deviceTokens.length}');
  //       }
  //     });
  //   } catch (e) {
  //     print(e.toString());
  //   }
  // }

  void dispose() {
    // TODO: implement dispose
    emailController.dispose();
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Form(
            key: loginFormKey,
            child: Column(
              children: [
                SizedBox(
                  height: screenHeight * 0.31,
                  child: Stack(
                    children: [
                      Opacity(
                        opacity: 0.1,
                        child: Image.asset(
                          'assets/pngs/htmimage1.png',
                        ),
                      ),
                      Center(
                        child: Image.asset(
                          'assets/svgs/splash-logo.png',
                          width: 144,
                          height: 144,
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 50,
                        child: InkWell(
                            onTap: () {
                              Get.back();
                            },
                            child: SvgPicture.asset(
                              'assets/svgs/back_btn.svg',
                            )),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, right: 12.0),
                  child: Column(
                    children: [
                      const Text(
                        'Login To Continue',
                        style: TextStyle(
                          fontFamily: 'Mont',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xff025B8F),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      const Text(
                        'Welcome to HouseToMotive ',
                        style: TextStyle(
                          fontFamily: 'ProximaNova',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff424B5A),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CustomButtonWithIcon(
                            ontap: () {
                              // Get.to(() => LoginWithEmailScreen());
                            },
                            title: 'With Email',
                            svg: "assets/svgs/social/Mail.svg",
                          ),
                          CustomSocialButton(
                              svg: "assets/svgs/social/google.svg",
                              ontap: () {
                                authenticationController.signInWithGoogle();
                              }),
                          CustomSocialButton(
                            svg: "assets/apple.svg",
                            ontap: () {
                              // signInWithFacebook();
                              authenticationController.signInWithApple();
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      const Text(
                        'Or with Email',
                        style: TextStyle(
                          fontFamily: 'ProximaNova',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff424B5A),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      CustomEmailField(
                        textEditingController: emailController,
                        title: 'Email',
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      CustomPasswordField(
                          title: 'Enter password',
                          textEditingController: passwordController),
                      SizedBox(height: screenHeight * 0.01),
                      Obx(
                        () => isLoading.value == true
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xff025B8F),
                                ),
                              )
                            : CustomButton(
                                title: "Login",
                                ontap: () {
                                  if (loginFormKey.currentState!.validate()) {
                                    Login();
                                  }
                                },
                              ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      CustomButton(
                          title: 'Continue as Guest',
                          ontap: () {
                            continueAsGuest();
                          }),
                      SizedBox(height: screenHeight * 0.03),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'New User?',
                            style: TextStyle(
                              fontFamily: 'ProximaNova',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xff424B5A),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Get.to(() => const SignupScreen());
                            },
                            child: const Text(
                              ' Sign Up',
                              style: TextStyle(
                                fontFamily: 'ProximaNova',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff025B8F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthenticationController extends GetxController {
  Future<User?> signInWithGoogle() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    if (kIsWeb) {
      GoogleAuthProvider authProvider = GoogleAuthProvider();
      try {
        final UserCredential userCredential =
            await auth.signInWithPopup(authProvider);

        user = userCredential.user;
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    } else {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();

      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.authenticate();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
        );

        try {
          final UserCredential userCredential =
              await auth.signInWithCredential(credential);

          user = userCredential.user;

          await addUserDetailsToFirestore(user!);

          prefs.setBool('isLogin', true);
          prefs.setBool('isGuest', false);
          Get.to(() => HomePage());
        } on FirebaseAuthException catch (e) {
          if (e.code == 'account-exists-with-different-credential') {
            log('Account exists with different credential');
          } else if (e.code == 'invalid-credential') {
            log('Invalid Credential');
          }
        } catch (e) {
          log(e.toString());
        }
      }
    }

    return user;
  }

  Future<User?> signInWithApple() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    if (kIsWeb) {
      // Web-specific implementation
      try {
        final OAuthProvider authProvider = OAuthProvider("apple.com");
        final UserCredential userCredential =
            await auth.signInWithPopup(authProvider);
        user = userCredential.user;
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    } else {
      // iOS and macOS implementation
      try {
        // Request Apple ID credentials
        final AuthorizationCredentialAppleID appleCredential =
            await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        // Create Firebase credential
        final OAuthCredential credential =
            OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
        );

        // Sign in to Firebase
        final UserCredential userCredential =
            await auth.signInWithCredential(credential);

        user = userCredential.user;

        await addUserDetailsToFirestore(user!);
        prefs.setBool('isLogin', true);
        prefs.setBool('isGuest', false);
        // Navigate to the home screen
        Get.to(() => HomePage());
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          log('Account exists with different credential');
        } else if (e.code == 'invalid-credential') {
          log('Invalid Credential');
        }
      } catch (e) {
        log(e.toString());
      }
    }

    return user;
  }

  Future<void> signOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    try {
      if (!kIsWeb) {
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      log(e.toString());
    }
  }

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    requestTrackingPermission();
  }

  Future<void> requestTrackingPermission() async {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;

    if (status == TrackingStatus.notDetermined) {
      // Show the tracking authorization prompt
      final newStatus =
          await AppTrackingTransparency.requestTrackingAuthorization();
      debugPrint('Tracking Authorization Status: $newStatus');
    } else {
      debugPrint('Tracking Authorization Status: $status');
    }

    // Optionally, get and log the IDFA
    final idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
    debugPrint('Advertising Identifier: $idfa');
  }
}

Future<void> addUserDetailsToFirestore(User user) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    // String? deviceToken = await FirebaseMessaging.instance.getToken();

    // Prepare user data
    Map<String, dynamic> userData = {
      'User Name': user.displayName ?? 'Unknown',
      'Email': user.email ?? 'No Email',
      'profilePic': user.photoURL ?? '',
      'Device Token': '',
      'activeChatList': [],
      'userId': user.uid,
    };

    // Save to Firestore
    await firestore.collection('users').doc(user.uid).set(userData);
  } catch (e) {
    log('Error saving user data to Firestore: $e');
  }
}

// Future<UserCredential> signInWithFacebook() async {
//   // Trigger the sign-in flow
//   final LoginResult loginResult = await FacebookAuth.instance.login();
//
//   // Create a credential from the access token
//   final OAuthCredential facebookAuthCredential =
//       FacebookAuthProvider.credential(loginResult.accessToken!.token);
//
//   // Once signed in, return the UserCredential
//   return FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
// }
