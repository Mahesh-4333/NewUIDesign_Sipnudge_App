// import 'package:equatable/equatable.dart';

// class AccountSecurityState extends Equatable {
//   final bool biometricsEnabled;
//   final bool faceIdEnabled;
//   final String activeTab; // 👈 add this

//   const AccountSecurityState({
//     this.biometricsEnabled = false,
//     this.faceIdEnabled = false,
//     this.activeTab = "Home", // 👈 default tab
//   });

//   AccountSecurityState copyWith({
//     bool? biometricsEnabled,
//     bool? faceIdEnabled,
//     String? activeTab,
//   }) {
//     return AccountSecurityState(
//       biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
//       faceIdEnabled: faceIdEnabled ?? this.faceIdEnabled,
//       activeTab: activeTab ?? this.activeTab,
//     );
//   }

//   @override
//   List<Object?> get props => [biometricsEnabled, faceIdEnabled, activeTab];
// }

//========================================================================

import 'package:equatable/equatable.dart';

class AccountSecurityState extends Equatable {
  final bool biometricsEnabled;
  final bool faceIdEnabled;
  final String activeTab; // 👈 add this

  const AccountSecurityState({
    this.biometricsEnabled = false,
    this.faceIdEnabled = false,
    this.activeTab = "Home", // 👈 default tab
  });

  AccountSecurityState copyWith({
    bool? biometricsEnabled,
    bool? faceIdEnabled,
    String? activeTab,
  }) {
    return AccountSecurityState(
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      faceIdEnabled: faceIdEnabled ?? this.faceIdEnabled,
      activeTab: activeTab ?? this.activeTab,
    );
  }

  @override
  List<Object?> get props => [biometricsEnabled, faceIdEnabled, activeTab];
}
