import 'package:shared_preferences/shared_preferences.dart';

class PrivacySettingsService {
  // Singleton
  static final PrivacySettingsService _instance = PrivacySettingsService._internal();
  factory PrivacySettingsService() => _instance;
  PrivacySettingsService._internal();

  // Configurações básicas de privacidade (em memória)
  bool anonymizeStudentNames = true; // Exibir nomes públicos (apelido / primeiro nome + inicial)
  bool showSchoolInStudentRanking = false; // Mostrar escola no ranking de alunos
  bool studentDefaultToOwnSchool = true; // Ranking para aluno abre filtrado por própria escola
  bool enableConfetti = true; // Mostrar confete em conquistas
  bool enableSounds = false; // Tocar sons ao celebrar
  bool enableBackgroundMusic = true; // Música de fundo no jogo

  static const _kAnonymize = 'privacy.anonymizeStudentNames';
  static const _kShowSchool = 'privacy.showSchoolInStudentRanking';
  static const _kStudentDefaultSchool = 'privacy.studentDefaultToOwnSchool';
  static const _kEnableConfetti = 'privacy.enableConfetti';
  static const _kEnableSounds = 'privacy.enableSounds';
  static const _kEnableBgMusic = 'privacy.enableBackgroundMusic';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    anonymizeStudentNames = prefs.getBool(_kAnonymize) ?? anonymizeStudentNames;
    showSchoolInStudentRanking = prefs.getBool(_kShowSchool) ?? showSchoolInStudentRanking;
    studentDefaultToOwnSchool = prefs.getBool(_kStudentDefaultSchool) ?? studentDefaultToOwnSchool;
    enableConfetti = prefs.getBool(_kEnableConfetti) ?? enableConfetti;
    enableSounds = prefs.getBool(_kEnableSounds) ?? enableSounds;
    enableBackgroundMusic = prefs.getBool(_kEnableBgMusic) ?? enableBackgroundMusic;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAnonymize, anonymizeStudentNames);
    await prefs.setBool(_kShowSchool, showSchoolInStudentRanking);
    await prefs.setBool(_kStudentDefaultSchool, studentDefaultToOwnSchool);
    await prefs.setBool(_kEnableConfetti, enableConfetti);
    await prefs.setBool(_kEnableSounds, enableSounds);
    await prefs.setBool(_kEnableBgMusic, enableBackgroundMusic);
  }
}
