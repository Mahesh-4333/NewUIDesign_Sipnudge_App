// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hydrify/cubit/personal_info_in_profile/personal_info_state.dart';

// class PersonalInfoCubit extends Cubit<PersonalInfoState> {
//   PersonalInfoCubit() : super(const PersonalInfoState());

//   void setActiveTab(String tab) {
//     emit(state.copyWith(activeTab: tab));
//   }

//   void updateInfo(String key, String value) {
//     final updated = Map<String, String>.from(state.personalInfo);
//     updated[key] = value;
//     emit(state.copyWith(personalInfo: updated));
//   }
// }

// ===========================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/cubit/personal_info_in_profile/personal_info_state.dart';

class PersonalInfoCubit extends Cubit<PersonalInfoState> {
  PersonalInfoCubit() : super(const PersonalInfoState());

  void setActiveTab(String tab) {
    emit(state.copyWith(activeTab: tab));
  }

  void updateInfo(String key, String value) {
    final updated = Map<String, String>.from(state.personalInfo);
    updated[key] = value;
    emit(state.copyWith(personalInfo: updated));
  }
}
