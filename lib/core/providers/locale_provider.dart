import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    return const Locale('en'); // Default to English
  }

  void toggleLocale() {
    state = state.languageCode == 'en'
        ? const Locale('bn')
        : const Locale('en');
  }

  void setLocale(Locale locale) {
    if (!['en', 'bn'].contains(locale.languageCode)) return;
    state = locale;
  }
}
