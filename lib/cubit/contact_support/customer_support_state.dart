// import 'package:equatable/equatable.dart';

// class CustomerSupportState extends Equatable {
//   final String activeTab;

//   const CustomerSupportState({this.activeTab = 'Home'});

//   CustomerSupportState copyWith({String? activeTab}) {
//     return CustomerSupportState(activeTab: activeTab ?? this.activeTab);
//   }

//   @override
//   List<Object> get props => [activeTab];
// }

// =======================================================================

import 'package:equatable/equatable.dart';

class CustomerSupportState extends Equatable {
  final String activeTab;

  const CustomerSupportState({this.activeTab = 'Home'});

  CustomerSupportState copyWith({String? activeTab}) {
    return CustomerSupportState(activeTab: activeTab ?? this.activeTab);
  }

  @override
  List<Object> get props => [activeTab];
}
