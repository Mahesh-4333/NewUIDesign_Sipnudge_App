class ProfileState {
  final String activeTab;
  final List<ProfileMenuItem> menuItems;
  // final List<ProfileMenuItem> secondaryMenuItems;

  ProfileState({
    required this.activeTab,
    required this.menuItems,
    // required this.secondaryMenuItems,
  });

  ProfileState copyWith({
    String? activeTab,
    List<ProfileMenuItem>? menuItems,
    // List<ProfileMenuItem>? secondaryMenuItems,
  }) {
    return ProfileState(
      activeTab: activeTab ?? this.activeTab,
      menuItems: menuItems ?? this.menuItems,
      // secondaryMenuItems: secondaryMenuItems ?? this.secondaryMenuItems,
    );
  }
}

class ProfileMenuItem {
  final String iconPath;
  final String title;
  final bool isRed;

  ProfileMenuItem({
    required this.iconPath,
    required this.title,
    this.isRed = false,
  });
}
