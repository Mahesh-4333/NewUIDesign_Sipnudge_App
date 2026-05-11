import 'package:hydrify/helpers/logger.dart';

import 'package:bloc/bloc.dart';
import 'package:hydrify/models/responses/signin_response_model.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:local_auth/local_auth.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());

  final LocalAuthentication _localAuth = LocalAuthentication();
  final ApiService _apiService = ApiService();
  SigninResponseModel? get currentUser => state.loginData;

  Future<bool> authenticateWithBiometrics() async {
    try {
      emit(state.copyWith(isLoading: true, isError: false, errorMessage: null));

      final canCheck = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();

      if (!canCheck) {
        emit(state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: "Cannot check biometrics",
        ));
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to continue',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      emit(state.copyWith(
        isLoading: false,
        isBiometricAuthenticated: didAuthenticate,
        isError: !didAuthenticate,
        errorMessage:
            !didAuthenticate ? "Biometric authentication failed" : null,
      ));

      return didAuthenticate;
    } catch (e) {
      Console.log(tag: 'auth_cubit', value: 'Biometric auth error: $e');
      emit(state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: 'Biometric authentication failed: ${e.toString()}',
      ));
      return false;
    }
  }

  Future<void> createAccount(
      {required String email, required String password}) async {
    try {
      emit(
        state.copyWith(
          isLoading: true,
          isError: false,
          errorMessage: null,
          shouldWiggleEmail: false,
          shouldWigglePassword: false,
        ),
      );
      var response = await _apiService.signUp(email, password);
      emit(
        state.copyWith(
          isLoading: false,
          isError: false,
          errorMessage: null,
          shouldWiggleEmail: false,
          shouldWigglePassword: false,
        ),
      );
      if (response.statusCode == 200 && response.status == "success") {
        emit(
          state.copyWith(
            isLoading: false,
            isError: false,
            errorMessage: null,
            shouldWiggleEmail: false,
            shouldWigglePassword: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            isError: true,
            errorMessage: response.message,
            shouldWiggleEmail: false,
            shouldWigglePassword: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isError: false,
          errorMessage: e.toString(),
          shouldWiggleEmail: false,
          shouldWigglePassword: false,
        ),
      );
    }
  }

  Future<void> sendSignupOTP(
      {required String email, required String password}) async {
    try {
      emit(
        state.copyWith(
          isLoading: true,
          isError: false,
          errorMessage: null,
          shouldWiggleEmail: false,
          shouldWigglePassword: false,
        ),
      );
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      Console.log(tag: 'auth_cubit', value: 'SignUp OTP exception: $e');
      emit(state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: 'Failed to send OTP: ${e.toString()}',
      ));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      emit(state.copyWith(
        isLoading: true,
        isError: false,
        errorMessage: null,
        shouldWiggleEmail: false,
        shouldWigglePassword: false,
      ));
      if (!_isValidEmail(email)) {
        emit(state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: "Invalid email format",
          shouldWiggleEmail: true,
        ));
        return;
      }

      if (password.isEmpty) {
        emit(state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: "Password cannot be empty",
          shouldWigglePassword: true,
        ));
        return;
      }

      var signInResult = await _apiService.signIn(email, password);

      // Save userId to SharedPrefs
      final userId = signInResult.data?.userDetails?.id;
      if (userId != null) {
        await SharedPrefsHelper.setUserId(userId);
        Console.log(tag: "AUTH", value: "UserId saved: $userId");
      }

      emit(state.copyWith(
        isLoading: false,
        user: signInResult,
      ));
    } catch (e) {
      Console.log(tag: 'auth_cubit', value: 'SignIn exception: $e');
      emit(state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: 'Login failed: ${e.toString()}',
      ));
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return true;
  }

  void resetWiggleAnimations() {
    if (state.shouldWiggleEmail || state.shouldWigglePassword) {
      emit(state.copyWith(
        shouldWiggleEmail: false,
        shouldWigglePassword: false,
      ));
    }
  }

  void clearErrors() {
    if (state.isError) {
      emit(state.copyWith(
        isError: false,
        errorMessage: null,
        shouldWiggleEmail: false,
        shouldWigglePassword: false,
      ));
    }
  }

  void signOut() {
    emit(const AuthState());
  }
}
