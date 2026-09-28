import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'storage_service.dart';

/// Short, soft sound effects (no music) and light haptics, both respecting
/// the user's settings.
class AudioService {
  final StorageService storage;
  final _pool = <String, AudioPlayer>{};

  AudioService(this.storage);

  Future<void> _play(String name) async {
    if (storage.muted) return;
    try {
      final player = _pool.putIfAbsent(
        name,
        () => AudioPlayer()..setPlayerMode(PlayerMode.lowLatency),
      );
      await player.stop();
      await player.play(AssetSource('sounds/$name.wav'), volume: 0.6);
    } catch (_) {
      // Audio is non-critical.
    }
  }

  void tap() {
    _play('tap');
    if (storage.vibration) HapticFeedback.selectionClick();
  }

  void correct() {
    _play('correct');
    if (storage.vibration) HapticFeedback.lightImpact();
  }

  void wrong() {
    _play('wrong');
    if (storage.vibration) HapticFeedback.mediumImpact();
  }

  void win() => _play('win');

  void coin() => _play('coin');
}
