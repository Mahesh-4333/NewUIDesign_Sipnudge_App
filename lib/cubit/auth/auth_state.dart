part of 'auth_cubit.dart';

class AuthState {
  final SigninResponseModel? loginData;
  final bool isLoading;
  final bool isBiometricAuthenticated;
  final bool isError;
  final String? errorMessage;
  final bool shouldWiggleEmail;
  final bool shouldWigglePassword;

  const AuthState({
    this.loginData,
    this.isLoading = false,
    this.isBiometricAuthenticated = false,
    this.isError = false,
    this.errorMessage,
    this.shouldWiggleEmail = false,
    this.shouldWigglePassword = false,
  });

  AuthState copyWith({
    SigninResponseModel? user,
    bool? isLoading,
    bool? isBiometricAuthenticated,
    bool? isError,
    String? errorMessage,
    bool? shouldWiggleEmail,
    bool? shouldWigglePassword,
  }) {
    return AuthState(
      loginData: user ?? loginData,
      isLoading: isLoading ?? this.isLoading,
      isBiometricAuthenticated:
          isBiometricAuthenticated ?? this.isBiometricAuthenticated,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      shouldWiggleEmail: shouldWiggleEmail ?? this.shouldWiggleEmail,
      shouldWigglePassword: shouldWigglePassword ?? this.shouldWigglePassword,
    );
  }
}
