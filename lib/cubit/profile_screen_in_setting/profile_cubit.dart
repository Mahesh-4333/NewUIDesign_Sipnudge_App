import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/profile_screen_in_setting/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit()
      : super(
          ProfileState(
            activeTab: "Home",
            menuItems: [
              // ACCOUNT group
              ProfileMenuItem(
                iconPath: "assets/personalinfo.png",
                title: "Personal Info",
                groupLabel: "ACCOUNT",
              ),
              ProfileMenuItem(
                iconPath: "assets/acc_security.png",
                title: "Account & Security",
                groupLabel: "ACCOUNT",
              ),
              // ProfileMenuItem(
              //   iconPath: "assets/performance.png",
              //   title: "Billing & Subscription",
              //   groupLabel: "ACCOUNT",
              // ),

              // PREFERENCES group
              ProfileMenuItem(
                iconPath: "assets/drink_rem.png",
                title: "Drink Reminder",
                groupLabel: "PREFERENCES",
              ),
              ProfileMenuItem(
                iconPath: "assets/performance.png",
                title: "Preferences",
                groupLabel: "PREFERENCES",
              ),
              ProfileMenuItem(
                iconPath: "assets/images/language.png",
                title: "Language",
                groupLabel: "PREFERENCES",
              ),

              // CONNECTED HARDWARE group
              ProfileMenuItem(
                iconPath: "assets/bottle_icon11.png",
                title: "Sipnudge Bottle",
                groupLabel: "CONNECTED HARDWARE",
              ),
              ProfileMenuItem(
                iconPath: AssetsPath.wify,
                title: "Connect Wi-Fi",
                groupLabel: "CONNECTED HARDWARE",
              ),
              ProfileMenuItem(
                iconPath: "assets/unlink1.png",
                title: "Unlink Device",
                isRed: true,
                groupLabel: "CONNECTED HARDWARE",
              ),

              // DATA & SUPPORT group
              ProfileMenuItem(
                iconPath: AssetsPath.calendar,
                title: "Calendar",
                groupLabel: "DATA & SUPPORT",
              ),
              // ProfileMenuItem(
              //   iconPath: "assets/data_analytics_icon.png",
              //   title: "Data & Analytics",
              //   groupLabel: "DATA & SUPPORT",
              // ),
              ProfileMenuItem(
                iconPath: "assets/help_support.png",
                title: "Help & Support",
                groupLabel: "DATA & SUPPORT",
              ),
              // ProfileMenuItem(
              //   iconPath: "assets/drink_rem.png",
              //   title: "Timeline Intro",
              //   groupLabel: "DATA & SUPPORT",
              // ),

              // OTHER group (hidden)
              // ProfileMenuItem(
              //   iconPath: "assets/data_analytics_icon.png",
              //   title: "Export Log",
              //   groupLabel: "OTHER",
              // ),
              // ProfileMenuItem(
              //   iconPath: "assets/drink_rem.png",
              //   title: "Hydration Ring Guide",
              //   groupLabel: "OTHER",
              // ),
              // ProfileMenuItem(
              //   iconPath: "assets/drink_rem.png",
              //   title: "Home Screen Widget",
              //   groupLabel: "OTHER",
              // ),
              // ProfileMenuItem(
              //   iconPath: "assets/drink_rem.png",
              //   title: "Intro",
              //   groupLabel: "OTHER",
              // ),
              // ProfileMenuItem(
              //   iconPath: "assets/data_analytics_icon.png",
              //   title: "Leaderboard",
              //   groupLabel: "OTHER",
              // ),

              // LOGOUT (standalone)
              ProfileMenuItem(
                iconPath: "assets/logout.png",
                title: "Logout",
                isRed: true,
              ),
            ],
          ),
        );

  void changeTab(String tab) {
    emit(state.copyWith(activeTab: tab));
  }
}
