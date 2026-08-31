import 'package:shared_preferences/shared_preferences.dart';

class PrivacySettingsService {
  // Singleton
  static final PrivacySettingsService _instance = PrivacySettingsService._internal();
  factory PrivacySettingsService() => _instance;
  PrivacySettingsService._internal();

  // Configurações básicas de privacidade (em memória)
  bool anonymizeStudentNames = true;
  bool showSchoolInStudentRanking = false;
  bool studentDefaultToOwnSchool = true;
  bool enableConfetti = true;
  bool enableSounds = false;
  bool enableBackgroundMusic = true;
  bool reduceMotion = false;

  static const _kAnonymize = 'privacy.anonymizeStudentNames';
  static const _kShowSchool = 'privacy.showSchoolInStudentRanking';
  static const _kStudentDefaultSchool = 'privacy.studentDefaultToOwnSchool';
  static const _kEnableConfetti = 'privacy.enableConfetti';
  static const _kEnableSounds = 'privacy.enableSounds';
  static const _kEnableBgMusic = 'privacy.enableBackgroundMusic';
  static const _kReduceMotion = 'privacy.reduceMotion';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    anonymizeStudentNames = prefs.getBool(_kAnonymize) ?? anonymizeStudentNames;
    showSchoolInStudentRanking = prefs.getBool(_kShowSchool) ?? showSchoolInStudentRanking;
    studentDefaultToOwnSchool = prefs.getBool(_kStudentDefaultSchool) ?? studentDefaultToOwnSchool;
    enableConfetti = prefs.getBool(_kEnableConfetti) ?? enableConfetti;
    enableSounds = prefs.getBool(_kEnableSounds) ?? enableSounds;
    enableBackgroundMusic = prefs.getBool(_kEnableBgMusic) ?? enableBackgroundMusic;
    reduceMotion = prefs.getBool(_kReduceMotion) ?? reduceMotion;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAnonymize, anonymizeStudentNames);
    await prefs.setBool(_kShowSchool, showSchoolInStudentRanking);
    await prefs.setBool(_kStudentDefaultSchool, studentDefaultToOwnSchool);
    await prefs.setBool(_kEnableConfetti, enableConfetti);
    await prefs.setBool(_kEnableSounds, enableSounds);
    await prefs.setBool(_kEnableBgMusic, enableBackgroundMusic);
    await prefs.setBool(_kReduceMotion, reduceMotion);
  }
}
