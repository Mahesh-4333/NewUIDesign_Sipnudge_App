import 'package:equatable/equatable.dart';

class HelpAndSupportState extends Equatable {
  final String activeTab;

  const HelpAndSupportState({this.activeTab = "Home"});

  HelpAndSupportState copyWith({String? activeTab}) {
    return HelpAndSupportState(activeTab: activeTab ?? this.activeTab);
  }

  @override
  List<Object?> get props => [activeTab];
}

// ===========================================================================

// import 'package:equatable/equatable.dart';

// class HelpAndSupportState extends Equatable {
//   final String activeTab;

//   const HelpAndSupportState({this.activeTab = "Home"});

//   HelpAndSupportState copyWith({String? activeTab}) {
//     return HelpAndSupportState(activeTab: activeTab ?? this.activeTab);
//   }

//   @override
//   List<Object?> get props => [activeTab];
// }

// ===========================================================================
