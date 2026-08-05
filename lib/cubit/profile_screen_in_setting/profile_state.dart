class ProfileState {
  final String activeTab;
  final List<ProfileMenuItem> menuItems;

  ProfileState({
    required this.activeTab,
    required this.menuItems,
  });

  ProfileState copyWith({
    String? activeTab,
    List<ProfileMenuItem>? menuItems,
  }) {
    return ProfileState(
      activeTab: activeTab ?? this.activeTab,
      menuItems: menuItems ?? this.menuItems,
    );
  }
}

class ProfileMenuItem {
  final String iconPath;
  final String title;
  final bool isRed;
  final String? groupLabel;

  ProfileMenuItem({
    required this.iconPath,
    required this.title,
    this.isRed = false,
    this.groupLabel,
  });
}
