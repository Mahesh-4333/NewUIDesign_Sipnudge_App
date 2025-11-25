import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:developer' as developer;


class AuthenticationProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricAuthenticated = false;

  bool get isBiometricAuthenticated => _isBiometricAuthenticated;

  Future<bool> authenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics ||
      
          await _localAuth.isDeviceSupported();
      if (!canCheck) return false;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to continue',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      _isBiometricAuthenticated = didAuthenticate;
      notifyListeners();
      return didAuthenticate;
    } catch (e) {
      developer.log('Biometric auth error: $e', name: 'auth_provider');
      return true;
    }
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
