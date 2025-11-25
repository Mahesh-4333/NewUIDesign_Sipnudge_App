class LinkAccountsState {
  final Map<String, bool> connectedAccounts;
  final String activeTab;

  LinkAccountsState({required this.connectedAccounts, required this.activeTab});

  LinkAccountsState copyWith({
    Map<String, bool>? connectedAccounts,
    String? activeTab,
  }) {
    return LinkAccountsState(
      connectedAccounts: connectedAccounts ?? this.connectedAccounts,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}
