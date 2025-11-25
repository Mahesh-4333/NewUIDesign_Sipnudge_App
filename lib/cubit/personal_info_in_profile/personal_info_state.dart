class PersonalInfoState {
  final String activeTab;
  final Map<String, String> personalInfo;

  const PersonalInfoState({
    this.activeTab = 'Home',
    this.personalInfo = const {
      'Gender': 'Male',
      'Height': '185 cm',
      'Weight': '78 kg',
      'Age': '25 years',
      'Wake-up Time': '06:00 Am',
      'Bedtime': '23:30 Pm',
      'Activity Level': 'Lightly Active',
    },
  });

  PersonalInfoState copyWith({
    String? activeTab,
    Map<String, String>? personalInfo,
  }) {
    return PersonalInfoState(
      activeTab: activeTab ?? this.activeTab,
      personalInfo: personalInfo ?? this.personalInfo,
    );
  }
}
