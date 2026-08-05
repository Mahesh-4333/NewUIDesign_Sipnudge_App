import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(const Locale('en')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final lang = await SharedPrefsHelper.getSelectedLanguage();
    if (lang != null && lang.isNotEmpty) {
      emit(Locale(lang));
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    await SharedPrefsHelper.setSelectedLanguage(languageCode);
    emit(Locale(languageCode));
  }
}
