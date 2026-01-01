import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:house_to_motive/utils/utils.dart';
import 'package:house_to_motive/views/login/loginwith_email.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/custom_field.dart';
import '../../widgets/custom_socialbutton.dart';
import '../../widgets/loginbutton.dart';
import '../screens/navigation_bar/home_page.dart';

class UserModel {
  String userName;
  String email;
  String? userId;
  String profilePic;
  String? deviceToken; // This can be nullable
  List<String> activeChatList; // Add this field to store active chat IDs

  UserModel({
    required this.userName,
    required this.email,
    this.userId,
    required this.profilePic,
    this.deviceToken,
    List<String>? activeChatList, // Make activeChatList optional
  }) : activeChatList = activeChatList ?? []; // Initialize with an empty list if null
}

class SignupController extends GetxController {
  // static SignupController get instance => Get.find();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  RxBool isLoading=false.obs;

  Future<void> signUp() async {
    // String? deviceToken = await FirebaseMessaging.instance.getToken();
    try {
      isLoading.value=true;
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      UserModel newUser = UserModel(
        userName: userNameController.text.trim(),
        email: userCredential.user!.email!,
        deviceToken: "",
        profilePic: '',
        activeChatList: [],// You can set the profile picture here
       userId: FirebaseAuth.instance.currentUser!.uid
      );

      await addUserDetails(newUser);
      isLoading.value=false;
      Get.offAll(() => LoginWithEmailScreen());
      Utils().ToastMessage('Registered successfully');
    } catch (error) {
      isLoading.value=false;
      Utils().ToastMessage(error.toString());
    }
  }

  Future<void> addUserDetails(UserModel user ) async {
    // Correctly await the getToken() future to get the device token
    // String? deviceToken = await FirebaseMessaging.instance.getToken();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({
      'User Name': user.userName,
      'Email': user.email,
      'profilePic': user.profilePic,
      'Device Token': "",
      'activeChatList':[],// Use the awaited value here
      'userId':FirebaseAuth.instance.currentUser!.uid
    });
  }

  Future<User?> signInWithGoogle() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    User? user;

    if (kIsWeb) {
      GoogleAuthProvider authProvider = GoogleAuthProvider();
      try {
        final UserCredential userCredential = await auth.signInWithPopup(authProvider);
        user = userCredential.user;

        if (user != null) {
          // Save user details to Firestore
          await addUserDetailsToFirestore(user);
        }
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    } else {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();

      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.authenticate();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
        googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
        );

        try {
          final UserCredential userCredential = await auth.signInWithCredential(credential);
          user = userCredential.user;

          if (user != null) {
            // Save user details to Firestore
            await addUserDetailsToFirestore(user);
            prefs.setBool('isLogin', true);
            prefs.setBool('isGuest', false);
            Get.to(() => HomePage());
          }
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
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    User? user;

    try {
      if (kIsWeb) {
        // Apple Sign-In is not natively supported on the web using FirebaseAuth
        log('Apple Sign-In is not supported on web with FirebaseAuth');
      } else {
        final AuthorizationCredentialAppleID appleCredential =
        await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        final OAuthCredential oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
        );

        final UserCredential userCredential =
        await auth.signInWithCredential(oauthCredential);

        user = userCredential.user;

        if (user != null) {
          // Save user details to Firestore
          await addUserDetailsToFirestore(user);

          prefs.setBool('isLogin', true);
          prefs.setBool('isGuest', false);
          // Navigate to HomePage
          Get.to(() => HomePage());
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        log('Account exists with different credential');
      } else if (e.code == 'invalid-credential') {
        log('Invalid Credential');
      }
    } on PlatformException catch (e) {
      log('Error during Apple Sign-In: ${e.message}');
    } catch (e) {
      log('Error: $e');
    }

    return user;
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

}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();
  static final RegExp alphaExp = RegExp('[a-zA-Z]');
  bool isTermsAccepted = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final controller = Get.put(SignupController());
    return Scaffold(
      body: SingleChildScrollView(
        child: Form(
          key: signupFormKey,
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
                            // Get.back();
                          },
                          child: SvgPicture.asset(
                            'assets/svgs/back_btn.svg',
                          )),
                    ),
                  ],
                ),
              ),
              // SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomSocialButton(
                            svg: "assets/apple.svg", ontap: () {
                              controller.signInWithApple();
                        }),
                        const SizedBox(width: 20),
                        CustomSocialButton(
                            svg: "assets/svgs/social/google.svg", ontap: () {
                              controller.signInWithGoogle();
                        }),
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
                    SizedBox(
                      height: screenHeight * 0.08,
                      child: TextFormField(
                        validator: (value) => value!.isEmpty
                            ? 'Enter Your Name'
                            : (alphaExp.hasMatch(value)
                                ? null
                                : 'Only Alphabets are allowed in a username'),
                        controller: controller.userNameController,
                        decoration: const InputDecoration(
                          hintText: 'User Name',
                          hintStyle: TextStyle(
                            fontFamily: 'ProximaNova',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xff7390A1),
                          ),
                          contentPadding: EdgeInsets.all(10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    CustomEmailField(
                      textEditingController: controller.emailController,
                      title: 'Email',
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    CustomPasswordField(
                      title: 'Enter password',
                      textEditingController: controller.passwordController,
                    ),
                  Row(
                    children: [
                      Checkbox(
                        value: isTermsAccepted,
                        onChanged: (value) {
                          setState(() {
                            isTermsAccepted = value!;
                          });
                        },
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: 'By signing up you agree to the ',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(
                                text: 'Terms and Conditions',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff025B8F),
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    launchUrl(Uri.parse('https://housetomotive.com/terms-conditions/'));
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                    SizedBox(height: screenHeight * 0.03),
                  Obx(() =>   controller.isLoading.value==true?const Center(child: CircularProgressIndicator(color: Color(0xff025B8F) ,),):  CustomButton(
                    title: "Continue",
                    ontap: () {
                      if (!isTermsAccepted) {
                        Utils().ToastMessage('You must accept the Terms and Conditions to continue.');
                        return;
                      }
                      if (signupFormKey.currentState!.validate()) {
                        controller.signUp();
                      }
                      // Get.to(() => const SignupWithPhoneNumberScreen());
                    },
                  ),),
                    SizedBox(height: screenHeight * 0.03),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Have an Account? ',
                          style: TextStyle(
                            fontFamily: 'ProximaNova',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xff424B5A),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Get.to(() => LoginWithEmailScreen());
                          },
                          child: const Text(
                            'Login',
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
    );
  }
}

