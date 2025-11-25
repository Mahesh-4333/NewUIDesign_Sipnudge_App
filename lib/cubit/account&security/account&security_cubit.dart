// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'account&security_state.dart';

// class AccountSecurityCubit extends Cubit<AccountSecurityState> {
//   AccountSecurityCubit() : super(const AccountSecurityState());

//   void toggleBiometrics(bool value) {
//     emit(state.copyWith(biometricsEnabled: value));
//   }

//   void toggleFaceId(bool value) {
//     emit(state.copyWith(faceIdEnabled: value));
//   }

//   // 👇 add this
//   void updateTab(String newTab) {
//     emit(state.copyWith(activeTab: newTab));
//   }
// }

//========================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'account&security_state.dart';

class AccountSecurityCubit extends Cubit<AccountSecurityState> {
  AccountSecurityCubit() : super(const AccountSecurityState());

  void toggleBiometrics(bool value) {
    emit(state.copyWith(biometricsEnabled: value));
  }

  void toggleFaceId(bool value) {
    emit(state.copyWith(faceIdEnabled: value));
  }

  // 👇 add this
  void updateTab(String newTab) {
    emit(state.copyWith(activeTab: newTab));
  }
}
