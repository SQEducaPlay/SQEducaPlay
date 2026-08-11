import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

class BackgroundAudioService {
  BackgroundAudioService._privateConstructor();
  static final BackgroundAudioService instance = BackgroundAudioService._privateConstructor();

  AudioPlayer? _player;
  AudioPool? _acertoPool;
  AudioPool? _erroPool;
  bool _poolsInitialized = false;
  bool _initialized = false;
  bool _isPlaying = false;
  bool _muted = false;
  bool _bgSourceSet = false;

  Future<void> init() async {
    if (_initialized) return;
  _player = AudioPlayer();
  await _player!.setReleaseMode(ReleaseMode.loop);
    // restore mute pref
    try {
      final prefs = await SharedPreferences.getInstance();
      _muted = prefs.getBool('bg_music_muted') ?? false;
    } catch (_) {
      _muted = false;
    }
    _initialized = true;
    Logger.d('BackgroundAudioService initialized (muted=$_muted)');
    // initialize effect pools in background to reduce races
    _initPools();
  }

  bool get isPlaying => _isPlaying;
  bool get isMuted => _muted;

  Future<void> playLooped({bool force = false}) async {
    if (!kIsWeb && _player == null) await init();
    if (_muted && !force) return;
    try {
      // Try to set the source once to avoid reloading interruptions on Android.
      if (!_bgSourceSet) {
        try {
          await _player?.setSource(AssetSource('sounds/fundo.mp3'));
          _bgSourceSet = true;
        } catch (_) {
          // Fallback to play if setSource isn't available in this version.
          await _player?.play(AssetSource('sounds/fundo.mp3'));
          _bgSourceSet = true;
        }
        await _player?.setReleaseMode(ReleaseMode.loop);
      }

      if (!_isPlaying) {
        await _player?.resume();
      }
      _isPlaying = true;
      Logger.d('BackgroundAudioService.playLooped -> playing (muted=$_muted)');
    } catch (e) {
      Logger.d('BackgroundAudioService.playLooped error: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player?.pause();
      _isPlaying = false;
      Logger.d('BackgroundAudioService.pause -> paused');
    } catch (_) {}
  }

  Future<void> resume() async {
    if (_muted) return;
    try {
      await _player?.resume();
      _isPlaying = true;
      Logger.d('BackgroundAudioService.resume -> resumed');
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _player?.pause();
      _isPlaying = false;
      Logger.d('BackgroundAudioService.stop -> paused');
    } catch (_) {}
  }

  /// Stop music because user left the topic or finished quiz.
  Future<void> stopForTopic() async => stop();

  Future<void> toggleMute() async {
    _muted = !_muted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('bg_music_muted', _muted);
    } catch (_) {}
    if (_muted) {
      await pause();
      Logger.d('BackgroundAudioService.toggleMute -> muted');
    } else {
      await resume();
      Logger.d('BackgroundAudioService.toggleMute -> unmuted');
    }
  }

  Future<void> dispose() async {
    try {
      await _acertoPool?.dispose();
      await _erroPool?.dispose();
      await _player?.dispose();
    } catch (_) {}
    _player = null;
    _initialized = false;
    _isPlaying = false;
  }

  Future<void> _initPools() async {
    if (_poolsInitialized) return;
    try {
      try {
        final p = await AudioPool.create(source: AssetSource('sounds/acerto.mp3'), maxPlayers: 3);
        _acertoPool = p;
      } catch (e) {
        Logger.d('BackgroundAudioService: não foi possível criar acerto pool: $e');
      }
      try {
        final p = await AudioPool.create(source: AssetSource('sounds/erro.mp3'), maxPlayers: 3);
        _erroPool = p;
      } catch (e) {
        Logger.d('BackgroundAudioService: não foi possível criar erro pool: $e');
      }
    } finally {
      _poolsInitialized = true;
    }
  }

  Future<void> playEffect(String effect) async {
    if (effect == 'acerto') {
      if (_acertoPool != null) {
        try { _acertoPool!.start(); } catch (e) { Logger.d('playEffect acerto: $e'); }
      }
      return;
    }
    if (effect == 'erro') {
      if (_erroPool != null) {
        try { _erroPool!.start(); } catch (e) { Logger.d('playEffect erro: $e'); }
      }
      return;
    }
    if (effect == 'vitoria') {
      try {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        player.onPlayerComplete.listen((_) async { try { await player.dispose(); } catch (_) {} });
        await player.play(AssetSource('sounds/vitoria.mp3'));
      } catch (e) { Logger.d('playEffect vitoria: $e'); }
      return;
    }
  }
}
