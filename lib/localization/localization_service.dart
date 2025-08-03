import 'package:get/get.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class LocalizationService extends Translations {
  static final fallbackLocale = const Locale('en', 'US');
  static final locales = [
    const Locale('en', 'US'),
    const Locale('bn', 'BD'),
  ];

  static Locale getCurrentLocale() {
    final locale = Get.deviceLocale;
    return locales.contains(locale) ? locale! : fallbackLocale;
  }

  static Locale get locale => Get.deviceLocale ?? fallbackLocale;

  static Future<void> init() async {
    final en = await rootBundle.loadString('lib/localization/en.json');
    final bn = await rootBundle.loadString('lib/localization/bn.json');
    _localizedValues['en_US'] = Map<String, String>.from(json.decode(en));
    _localizedValues['bn_BD'] = Map<String, String>.from(json.decode(bn));
  }

  static final Map<String, Map<String, String>> _localizedValues = {};

  @override
  Map<String, Map<String, String>> get keys => _localizedValues;
}
