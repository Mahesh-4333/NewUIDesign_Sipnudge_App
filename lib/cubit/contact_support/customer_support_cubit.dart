// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'customer_support_state.dart';

// class CustomerSupportCubit extends Cubit<CustomerSupportState> {
//   CustomerSupportCubit() : super(const CustomerSupportState());

//   void updateTab(String tab) {
//     emit(state.copyWith(activeTab: tab));
//   }
// }

// =======================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'customer_support_state.dart';

class CustomerSupportCubit extends Cubit<CustomerSupportState> {
  CustomerSupportCubit() : super(const CustomerSupportState());

  void updateTab(String tab) {
    emit(state.copyWith(activeTab: tab));
  }
}
