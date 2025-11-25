import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hydrify/cubit/linkaccounts/link_accounts_state.dart';

class LinkAccountsCubit extends Cubit<LinkAccountsState> {
  LinkAccountsCubit()
      : super(
          LinkAccountsState(
            connectedAccounts: {"Google": false, "Apple": false},
            activeTab: "Home",
          ),
        );

  void toggleConnection(String account) {
    final current = state.connectedAccounts[account] ?? false;
    emit(
      state.copyWith(
        connectedAccounts: {...state.connectedAccounts, account: !current},
      ),
    );
  }

  void updateTab(String tab) {
    emit(state.copyWith(activeTab: tab));
  }
}
