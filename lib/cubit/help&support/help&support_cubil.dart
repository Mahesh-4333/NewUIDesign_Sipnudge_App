import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/cubit/help&support/help&support_state.dart';

class HelpAndSupportCubit extends Cubit<HelpAndSupportState> {
  HelpAndSupportCubit() : super(const HelpAndSupportState());

  void updateTab(String tab) {
    emit(state.copyWith(activeTab: tab));
  }
}

//==========================================================================

// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hydrify/cubit/help&support/help&support_state.dart';

// class HelpAndSupportCubit extends Cubit<HelpAndSupportState> {
//   HelpAndSupportCubit() : super(const HelpAndSupportState());

//   void updateTab(String tab) {
//     emit(state.copyWith(activeTab: tab));
//   }
// }

//==========================================================================
