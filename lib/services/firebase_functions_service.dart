import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FirebaseFunctionsService {
  static const String _baseUrl =
      'https://us-central1-sipnudge-7c920.cloudfunctions.net';

  // Helper method to send HTTP POST
  static Future<Map<String, dynamic>> _post(
      String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl/$endpoint');

    try {
      final response = await http.post(url, body: jsonEncode(body), headers: {
        'Content-Type': 'application/json',
      }).timeout(Duration(seconds: 20), onTimeout: () {
        throw SocketException("Server error");
      });
      log("$endpoint  ${jsonDecode(response.body)}");
      return jsonDecode(response.body);
    } catch (e) {
      log("Exception occurred in $endpoint : ${e.toString()}");
      return {
        "status": "failure",
        "statusCode": 500,
        "message": "Request timed out"
      };
    }
  }

  // Request Signup OTP
  static Future<Map<String, dynamic>> requestSignupOTP(
      String email, String password) {
    return _post('requestSignupOTP', {'email': email, 'password': password});
  }

  // Verify Signup OTP
  static Future<Map<String, dynamic>> verifySignupOTP(String email, int otp) {
    return _post('verifySignupOTP', {'email': email, 'otp': otp});
  }

  // Sign In
  static Future<Map<String, dynamic>> signIn(String email, String password) {
    return _post('signIn', {'email': email, 'password': password});
  }

  // Request Password Reset OTP
  static Future<Map<String, dynamic>> requestResetOTP(String email) {
    return _post('requestResetOTP', {'email': email});
  }

  // Verify Reset OTP
  static Future<Map<String, dynamic>> verifyResetOTP(
      String email, String otp, String newPassword) {
    return _post('verifyResetOTP',
        {'email': email, 'otp': otp, 'newPassword': newPassword});
  }

  static Future<Map<String, dynamic>> verifyResetOTPOnly(
      String email, int otp) {
    return _post('verifyResetOTPOnly', {
      'email': email,
      'otp': otp,
    });
  }

// Reset Password after OTP verified
  static Future<Map<String, dynamic>> resetPassword(
      String email, String newPassword) {
    return _post('resetPassword', {
      'email': email,
      'newPassword': newPassword,
    });
  }

  // Resend OTP (Firebase onCall)
  static Future<Map<String, dynamic>> resendOTP(String email) async {
    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('resendOTP');
      final result = await callable.call({'email': email});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      return {
        'status': 'error',
        'statusCode': 500,
        'message': 'Firebase function error',
        'data': null,
      };
    }
  }

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return null; // Cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Log Google user information
      log('=== GOOGLE SIGN-IN DATA ===');
      log('User ID: ${googleUser.id}');
      log('Email: ${googleUser.email}');
      log('Display Name: ${googleUser.displayName}');
      log('Photo URL: ${googleUser.photoUrl}');
      log('Server Auth Code: ${googleUser.serverAuthCode}');

      // Log authentication tokens
      log('Access Token: ${googleAuth.accessToken}');
      log('ID Token: ${googleAuth.idToken}');
      SharedPrefsHelper.setUserEmail(googleUser.email);

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Log Firebase user information
      final user = userCredential.user;
      if (user != null) {
        log('=== FIREBASE USER DATA (Google) ===');
        log('UID: ${user.uid}');
        log('Email: ${user.email}');
        log('Display Name: ${user.displayName}');
        log('Photo URL: ${user.photoURL}');
        log('Email Verified: ${user.emailVerified}');
        log('Creation Time: ${user.metadata.creationTime}');
        log('Last Sign In: ${user.metadata.lastSignInTime}');
        log('Provider Data: ${user.providerData.map((p) => {
              'providerId': p.providerId,
              'uid': p.uid,
              'email': p.email,
              'displayName': p.displayName,
              'photoURL': p.photoURL
            }).toList()}');
      }

      return userCredential;
    } catch (e) {
      log('Google Sign-In Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> signInWithApple() async {
    try {
      if (!await SignInWithApple.isAvailable()) {
        log('Apple Sign-In is not available on this device/simulator');
        return {
          'success': false,
          'message': 'Apple Sign-In is not available on this device'
        };
      }

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      log('=== APPLE SIGN-IN DATA ===');
      log('User Identifier: ${appleCredential.userIdentifier}');
      log('Given Name: ${appleCredential.givenName}');
      log('Family Name: ${appleCredential.familyName}');
      log('Email: ${appleCredential.email}');
      log('Identity Token: ${appleCredential.identityToken}');
      log('Authorization Code: ${appleCredential.authorizationCode}');
      log('State: ${appleCredential.state}');

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      final user = userCredential.user;
      if (user != null) {
        log('=== FIREBASE USER DATA (Apple) ===');
        log('UID: ${user.uid}');
        log('Email: ${user.email}');
        log('Display Name: ${user.displayName}');
        log('Photo URL: ${user.photoURL}');
        log('Email Verified: ${user.emailVerified}');
        log('Creation Time: ${user.metadata.creationTime}');
        log('Last Sign In: ${user.metadata.lastSignInTime}');
        log('Provider Data: ${user.providerData.map((p) => {
              'providerId': p.providerId,
              'uid': p.uid,
              'email': p.email,
              'displayName': p.displayName,
              'photoURL': p.photoURL
            }).toList()}');

        String userEmail = user.email ?? appleCredential.email ?? "";
        SharedPrefsHelper.setUserEmail(userEmail);
      }

      return {
        'success': true,
        'userCredential': userCredential,
        'message': 'Sign-in successful'
      };
    } catch (e) {
      log('Apple Sign-In Error: $e');

      String errorMessage = 'Apple Sign-In failed. Please try again.';

      if (e.toString().contains('canceled') ||
          e.toString().contains('CANCELED')) {
        errorMessage = 'Sign-in was canceled';
      } else if (e.toString().contains('network') ||
          e.toString().contains('Network')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('invalid_grant')) {
        errorMessage = 'Invalid credentials. Please try signing in again.';
      } else if (e.toString().contains('not_supported')) {
        errorMessage = 'Apple Sign-In is not supported on this device.';
      } else if (e.toString().contains('invalid-credential') ||
          e.toString().contains('audience')) {
        errorMessage = 'Configuration error. Please contact support.';
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  static Future<Map<String, dynamic>> checkUserFromGoogleOrApple(String email) {
    return _post('checkUserFromGoogleOrApple', {
      'email': email,
    });
  }

  static Future<Map<String, dynamic>> saveWaterIntakeGoal({
    required String? email,
    required double weightKg,
    required String dietType, // e.g., 'vegetarian', 'high_protein', etc.
    required String activityLevel, // e.g., 'sedentary', 'lightly_active'
  }) {
    return _post('saveWaterIntakeGoal', {
      'email': email ?? "",
      'weight_kg': weightKg,
      'diet_type': dietType,
      'activity_level': activityLevel,
    });
  }
}




/*



 */