import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/cubit/profile_screen_in_setting/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit()
      : super(
          ProfileState(
            activeTab: "Home",
            menuItems: [
              ProfileMenuItem(
                iconPath: "assets/personalinfo.png",
                title: "Personal Info",
              ),
              ProfileMenuItem(
                iconPath: "assets/drink_rem.png",
                title: "Drink Reminder",
              ),
              // ProfileMenuItem(
              //   iconPath: "assets/bottle.png",
              //   title: "Sipnudge Bottle",
              // ),
              ProfileMenuItem(
                iconPath: "assets/performance.png",
                title: "Preferences",
              ),

              ProfileMenuItem(
                iconPath: "assets/help_support.png",
                title: "Help & Support",
              ),
              ProfileMenuItem(
                iconPath: "assets/logout.png",
                title: "Logout",
                isRed: true,
              ),
            ],
            // secondaryMenuItems: [
            //   ProfileMenuItem(
            //     iconPath: "assets/data_analytics_icon.png",
            //     title: "Data & Analytics",
            //   ),
            //   ProfileMenuItem(
            //     iconPath: "assets/acc_security.png",
            //     title: "Account & Security",
            //   ),
            //   ProfileMenuItem(
            //     iconPath: "assets/link_account.png",
            //     title: "Linked Accounts",
            //   ),
            //   ProfileMenuItem(
            //     iconPath: "assets/help_support.png",
            //     title: "Help & Support",
            //   ),
            //   ProfileMenuItem(
            //     iconPath: "assets/logout.png",
            //     title: "Logout",
            //     isRed: true,
            //   ),
            // ],
          ),
        );

  void changeTab(String tab) {
    emit(state.copyWith(activeTab: tab));
  }
}
