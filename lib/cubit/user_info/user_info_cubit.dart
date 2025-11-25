import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/helpers/water_consumption_data_helper.dart';

part 'user_info_state.dart';

class UserInfoCubit extends Cubit<UserInfoState> {
  final DatabaseHelper dbHelper;

  UserInfoCubit(this.dbHelper)
      : super(const UserInfoState(
          gender: Gender.male,
          activityLevel: ActivityLevel.lightActivity,
          dietType: DietType.balanced,
        ));

  void setGender(Gender gender) {
    emit(state.copyWith(gender: gender));
  }

  void setHeight(double height, String unit, {int? inches}) {
    double heightInCm;

    if (unit == "cm") {
      heightInCm = height;
    } else if (unit == "ft") {
      final totalInches = (height * 12).toInt() + (inches ?? 0);
      heightInCm = totalInches * 2.54;
    } else {
      throw ArgumentError("Unsupported height unit: $unit");
    }

    emit(state.copyWith(height: heightInCm, heightUnit: unit));
  }

  void updateHeight({double? height, String? unit}) {
    emit(state.copyWith(
      height: height ?? state.height,
      heightUnit: unit ?? state.heightUnit,
    ));
  }

  void setWeight(double weight, String unit) {
    double weightInKg;

    if (unit == "kg") {
      weightInKg = weight;
    } else if (unit == "lbs") {
      weightInKg = weight * 0.453592;
    } else {
      throw ArgumentError("Unsupported weight unit: $unit");
    }

    emit(state.copyWith(weight: weightInKg, weightUnit: unit));
  }

  void updateWeight({double? weight, String? unit}) {
    emit(state.copyWith(
      weight: weight ?? state.weight,
      weightUnit: unit ?? state.weightUnit,
    ));
  }

  void setAge(int age) {
    emit(state.copyWith(age: age));
  }

  void updateWakeupTime({int? hour, int? minute, String? period}) {
    emit(state.copyWith(
      wakeupHour: hour,
      wakeupMinute: minute,
      wakeupPeriod: period,
    ));
  }

  void setBedtime(int hour, int minute, String period) {
    emit(state.copyWith(
      bedtimeHour: hour,
      bedtimeMinute: minute,
      bedtimePeriod: period,
    ));
  }

  void updateBedTime({int? hour, int? minute, String? period}) {
    emit(state.copyWith(
      bedtimeHour: hour,
      bedtimeMinute: minute,
      bedtimePeriod: period,
    ));
  }

  void setActivityLevel(ActivityLevel level) {
    emit(state.copyWith(activityLevel: level));
  }

  void setDietType(DietType type) {
    emit(state.copyWith(dietType: type));
  }

  Future<void> saveUser(UserInfoState state) async {
    await dbHelper.saveUserInfo(state);
  }

  Future<void> loadUser() async {
    final saved = await dbHelper.getUserInfo();
    if (saved != null) emit(saved);
  }
}

extension UserInfoCubitExtension on UserInfoCubit {
  double getWaterIntakeGoal({double? currentTemperature}) {
    return WaterConsumptionCalculator.calculateWaterIntakeGoal(state,
        currentTemperature: currentTemperature);
  }

  Map<String, double> getWaterIntakeBreakdown({double? currentTemperature}) {
    return WaterConsumptionCalculator.getCalculationBreakdown(state,
        currentTemperature: currentTemperature);
  }
}
