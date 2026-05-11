import 'package:hydrify/helpers/logger.dart';
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
      Console.log(tag: "APP", value: "$endpoint  ${jsonDecode(response.body)}");
      return jsonDecode(response.body);
    } catch (e) {
      Console.log(tag: "APP", value: "Exception occurred in $endpoint : ${e.toString()}");
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
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        scopes: [
          'https://www.googleapis.com/auth/calendar.readonly',
          'https://www.googleapis.com/auth/calendar.events.readonly',
        ],
      ).signIn();

      if (googleUser == null) return null; // Cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Log Google user information
      Console.log(tag: "APP", value: '=== GOOGLE SIGN-IN DATA ===');
      Console.log(tag: "APP", value: 'User ID: ${googleUser.id}');
      Console.log(tag: "APP", value: 'Email: ${googleUser.email}');
      Console.log(tag: "APP", value: 'Display Name: ${googleUser.displayName}');
      Console.log(tag: "APP", value: 'Photo URL: ${googleUser.photoUrl}');
      Console.log(tag: "APP", value: 'Server Auth Code: ${googleUser.serverAuthCode}');

      // Log authentication tokens
      Console.log(tag: "APP", value: 'Access Token: ${googleAuth.accessToken}');
      Console.log(tag: "APP", value: 'ID Token: ${googleAuth.idToken}');
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
        Console.log(tag: "APP", value: '=== FIREBASE USER DATA (Google) ===');
        Console.log(tag: "APP", value: 'UID: ${user.uid}');
        Console.log(tag: "APP", value: 'Email: ${user.email}');
        Console.log(tag: "APP", value: 'Display Name: ${user.displayName}');
        Console.log(tag: "APP", value: 'Photo URL: ${user.photoURL}');
        Console.log(tag: "APP", value: 'Email Verified: ${user.emailVerified}');
        Console.log(tag: "APP", value: 'Creation Time: ${user.metadata.creationTime}');
        Console.log(tag: "APP", value: 'Last Sign In: ${user.metadata.lastSignInTime}');
        Console.log(tag: "APP", value: 'Provider Data: ${user.providerData.map((p) => {
              'providerId': p.providerId,
              'uid': p.uid,
              'email': p.email,
              'displayName': p.displayName,
              'photoURL': p.photoURL
            }).toList()}');
      }

      return userCredential;
    } catch (e) {
      Console.log(tag: "APP", value: 'Google Sign-In Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> signInWithApple() async {
    try {
      if (!await SignInWithApple.isAvailable()) {
        Console.log(tag: "APP", value: 'Apple Sign-In is not available on this device/simulator');
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

      Console.log(tag: "APP", value: '=== APPLE SIGN-IN DATA ===');
      Console.log(tag: "APP", value: 'User Identifier: ${appleCredential.userIdentifier}');
      Console.log(tag: "APP", value: 'Given Name: ${appleCredential.givenName}');
      Console.log(tag: "APP", value: 'Family Name: ${appleCredential.familyName}');
      Console.log(tag: "APP", value: 'Email: ${appleCredential.email}');
      Console.log(tag: "APP", value: 'Identity Token: ${appleCredential.identityToken}');
      Console.log(tag: "APP", value: 'Authorization Code: ${appleCredential.authorizationCode}');
      Console.log(tag: "APP", value: 'State: ${appleCredential.state}');

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      final user = userCredential.user;
      if (user != null) {
        Console.log(tag: "APP", value: '=== FIREBASE USER DATA (Apple) ===');
        Console.log(tag: "APP", value: 'UID: ${user.uid}');
        Console.log(tag: "APP", value: 'Email: ${user.email}');
        Console.log(tag: "APP", value: 'Display Name: ${user.displayName}');
        Console.log(tag: "APP", value: 'Photo URL: ${user.photoURL}');
        Console.log(tag: "APP", value: 'Email Verified: ${user.emailVerified}');
        Console.log(tag: "APP", value: 'Creation Time: ${user.metadata.creationTime}');
        Console.log(tag: "APP", value: 'Last Sign In: ${user.metadata.lastSignInTime}');
        Console.log(tag: "APP", value: 'Provider Data: ${user.providerData.map((p) => {
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
      Console.log(tag: "APP", value: 'Apple Sign-In Error: $e');

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