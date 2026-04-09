import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Synthesizes and plays all game sounds using raw PCM WAV bytes.
/// No audio asset files required.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  // Dedicated players per sound role to allow overlap
  final AudioPlayer _spinPlayer   = AudioPlayer();
  final AudioPlayer _resultPlayer = AudioPlayer();
  final AudioPlayer _uiPlayer     = AudioPlayer();

  bool _enabled = true;
  bool get enabled => _enabled;
  set enabled(bool v) { _enabled = v; }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Wheel spinning tick — looping ratchet clicks that speed up then slow down
  Future<void> playSpin() async {
    if (!_enabled) return;
    await _spinPlayer.stop();
    final wav = _buildWav(_spinSound());
    await _spinPlayer.play(BytesSource(wav), volume: 0.7);
  }

  Future<void> stopSpin() async => _spinPlayer.stop();

  /// Win fanfare — ascending arpeggio + sparkle
  Future<void> playWin() async {
    if (!_enabled) return;
    await _resultPlayer.stop();
    final wav = _buildWav(_winSound());
    await _resultPlayer.play(BytesSource(wav), volume: 0.9);
  }

  /// Lose sound — descending wah-wah
  Future<void> playLose() async {
    if (!_enabled) return;
    await _resultPlayer.stop();
    final wav = _buildWav(_loseSound());
    await _resultPlayer.play(BytesSource(wav), volume: 0.8);
  }

  /// Points earned — coin chime
  Future<void> playPoints() async {
    if (!_enabled) return;
    await _uiPlayer.stop();
    final wav = _buildWav(_pointsSound());
    await _uiPlayer.play(BytesSource(wav), volume: 0.75);
  }

  /// Truth reveal — mysterious rising tone
  Future<void> playTruth() async {
    if (!_enabled) return;
    await _resultPlayer.stop();
    final wav = _buildWav(_truthSound());
    await _resultPlayer.play(BytesSource(wav), volume: 0.8);
  }

  /// Dare reveal — dramatic impact hit
  Future<void> playDare() async {
    if (!_enabled) return;
    await _resultPlayer.stop();
    final wav = _buildWav(_dareSound());
    await _resultPlayer.play(BytesSource(wav), volume: 0.85);
  }

  /// Button tap click
  Future<void> playTap() async {
    if (!_enabled) return;
    await _uiPlayer.stop();
    final wav = _buildWav(_tapSound());
    await _uiPlayer.play(BytesSource(wav), volume: 0.5);
  }

  void dispose() {
    _spinPlayer.dispose();
    _resultPlayer.dispose();
    _uiPlayer.dispose();
  }

  // ── Sound Synthesis ───────────────────────────────────────────────────────

  static const int _sampleRate = 22050;

  /// Wheel spin: rapid ticking clicks that simulate a ratchet wheel
  static List<double> _spinSound() {
    const duration = 5.0; // seconds — matches wheel animation
    final n = (duration * _sampleRate).round();
    final samples = List<double>.filled(n, 0.0);

    // Tick density: starts fast, slows down (easeOutCubic)
    // Place ~80 ticks total, spaced by eased intervals
    const totalTicks = 80;
    for (int t = 0; t < totalTicks; t++) {
      // easeOutCubic: fast at start, slow at end
      final progress = t / totalTicks;
      final eased = 1.0 - pow(1.0 - progress, 3).toDouble();
      final timePos = eased * duration;
      final samplePos = (timePos * _sampleRate).round();
      if (samplePos >= n) break;

      // Each tick: short sharp click (5ms)
      final tickLen = (0.005 * _sampleRate).round();
      for (int s = 0; s < tickLen && samplePos + s < n; s++) {
        final env = 1.0 - (s / tickLen);
        // Mix of noise + tone for a mechanical click
        final noise = (Random().nextDouble() * 2 - 1) * 0.4;
        final tone  = sin(2 * pi * 800 * s / _sampleRate) * 0.6;
        samples[samplePos + s] += (noise + tone) * env;
      }
    }
    return _normalize(samples);
  }

  /// Win: bright ascending arpeggio C-E-G-C with sparkle tail
  static List<double> _winSound() {
    const freqs = [523.25, 659.25, 783.99, 1046.50]; // C5 E5 G5 C6
    const noteDur = 0.12;
    const totalDur = 1.4;
    final n = (totalDur * _sampleRate).round();
    final samples = List<double>.filled(n, 0.0);

    for (int i = 0; i < freqs.length; i++) {
      final start = (i * noteDur * _sampleRate).round();
      final len   = (noteDur * 2.5 * _sampleRate).round();
      for (int s = 0; s < len && start + s < n; s++) {
        final t   = s / _sampleRate;
        final env = exp(-t * 4.0);
        // Bright tone with harmonics
        final v = (sin(2 * pi * freqs[i] * t) * 0.6
                 + sin(2 * pi * freqs[i] * 2 * t) * 0.25
                 + sin(2 * pi * freqs[i] * 3 * t) * 0.1) * env;
        samples[start + s] += v;
      }
    }

    // Sparkle: high-freq shimmer after arpeggio
    final sparkleStart = (freqs.length * noteDur * _sampleRate).round();
    for (int s = sparkleStart; s < n; s++) {
      final t   = (s - sparkleStart) / _sampleRate;
      final env = exp(-t * 6.0);
      samples[s] += sin(2 * pi * 2093 * t) * 0.3 * env; // C7
    }

    return _normalize(samples);
  }

  /// Lose: descending wah-wah trombone
  static List<double> _loseSound() {
    const totalDur = 1.2;
    final n = (totalDur * _sampleRate).round();
    final samples = List<double>.filled(n, 0.0);

    for (int s = 0; s < n; s++) {
      final t    = s / _sampleRate;
      final env  = exp(-t * 1.8);
      // Frequency sweeps down from 400 → 150 Hz
      final freq = 400.0 - (250.0 * t / totalDur);
      // Wah modulation
      final wah  = 0.5 + 0.5 * sin(2 * pi * 4 * t);
      samples[s] = sin(2 * pi * freq * t) * env * wah * 0.8;
    }
    return _normalize(samples);
  }

  /// Points: bright coin chime — two quick high pings
  static List<double> _pointsSound() {
    const pings = [1318.51, 1567.98]; // E6, G6
    const totalDur = 0.6;
    final n = (totalDur * _sampleRate).round();
    final samples = List<double>.filled(n, 0.0);

    for (int i = 0; i < pings.length; i++) {
      final start = (i * 0.12 * _sampleRate).round();
      final len   = ((totalDur - i * 0.12) * _sampleRate).round();
      for (int s = 0; s < len && start + s < n; s++) {
        final t   = s / _sampleRate;
        final env = exp(-t * 7.0);
        samples[start + s] += sin(2 * pi * pings[i] * t) * env * 0.7;
      }
    }
    return _normalize(samples);
  }

  /// Truth: mysterious rising sine sweep with reverb tail
  static List<double> _truthSound() {
    const totalDur = 1.0;
    final n = (totalDur * _sampleRate).round();
    final samples = List<double>.filled(n, 0.0);

    double phase = 0.0;
    for (int s = 0; s < n; s++) {
      final t    = s / _sampleRate;
      final env  = sin(pi * t / totalDur); // bell envelope
      // Frequency rises 300 → 700 Hz
      final freq = 300.0 + 400.0 * (t / totalDur);
      phase += 2 * pi * freq / _sampleRate;
      samples[s] = sin(phase) * env * 0.75;
    }
    return _normalize(samples);
  }

  /// Dare: dramatic low impact + rising growl
  static List<double> _dareSound() {
    const totalDur = 1.1;
    final n = (totalDur * _sampleRate).round();
    final samples = List<double>.filled(n, 0.0);

    // Impact thud at start
    final impactLen = (0.08 * _sampleRate).round();
    for (int s = 0; s < impactLen; s++) {
      final t   = s / _sampleRate;
      final env = exp(-t * 40.0);
      samples[s] = (sin(2 * pi * 80 * t) + (Random().nextDouble() * 2 - 1) * 0.3) * env;
    }

    // Rising growl after impact
    double phase = 0.0;
    for (int s = impactLen; s < n; s++) {
      final t    = (s - impactLen) / _sampleRate;
      final env  = exp(-t * 2.5);
      final freq = 120.0 + 180.0 * (t / (totalDur - 0.08));
      phase += 2 * pi * freq / _sampleRate;
      // Distorted sawtooth-ish
      final saw = (phase % (2 * pi)) / pi - 1.0;
      samples[s] += saw * env * 0.6;
    }
    return _normalize(samples);
  }

  /// UI tap: short soft click
  static List<double> _tapSound() {
    const totalDur = 0.04;
    final n = (totalDur * _sampleRate).round();
    final samples = List<double>.filled(n, 0.0);
    for (int s = 0; s < n; s++) {
      final env = 1.0 - (s / n);
      samples[s] = (Random().nextDouble() * 2 - 1) * env * 0.5
                 + sin(2 * pi * 1200 * s / _sampleRate) * env * 0.5;
    }
    return _normalize(samples);
  }

  // ── WAV helpers ───────────────────────────────────────────────────────────

  static List<double> _normalize(List<double> samples) {
    double peak = 0;
    for (final s in samples) { if (s.abs() > peak) peak = s.abs(); }
    if (peak == 0) return samples;
    return samples.map((s) => s / peak * 0.9).toList();
  }

  /// Encode PCM samples as a 16-bit mono WAV byte array
  static Uint8List _buildWav(List<double> samples) {
    const channels    = 1;
    const bitsPerSamp = 16;
    const bytePerSamp = bitsPerSamp ~/ 8;
    final dataSize    = samples.length * bytePerSamp;
    final fileSize    = 44 + dataSize;

    final buf = ByteData(fileSize);
    int o = 0;

    // RIFF header
    buf.setUint8(o++, 0x52); buf.setUint8(o++, 0x49);
    buf.setUint8(o++, 0x46); buf.setUint8(o++, 0x46); // "RIFF"
    buf.setUint32(o, fileSize - 8, Endian.little); o += 4;
    buf.setUint8(o++, 0x57); buf.setUint8(o++, 0x41);
    buf.setUint8(o++, 0x56); buf.setUint8(o++, 0x45); // "WAVE"

    // fmt chunk
    buf.setUint8(o++, 0x66); buf.setUint8(o++, 0x6D);
    buf.setUint8(o++, 0x74); buf.setUint8(o++, 0x20); // "fmt "
    buf.setUint32(o, 16, Endian.little); o += 4;       // chunk size
    buf.setUint16(o, 1,  Endian.little); o += 2;       // PCM
    buf.setUint16(o, channels, Endian.little); o += 2;
    buf.setUint32(o, _sampleRate, Endian.little); o += 4;
    buf.setUint32(o, _sampleRate * channels * bytePerSamp, Endian.little); o += 4;
    buf.setUint16(o, channels * bytePerSamp, Endian.little); o += 2;
    buf.setUint16(o, bitsPerSamp, Endian.little); o += 2;

    // data chunk
    buf.setUint8(o++, 0x64); buf.setUint8(o++, 0x61);
    buf.setUint8(o++, 0x74); buf.setUint8(o++, 0x61); // "data"
    buf.setUint32(o, dataSize, Endian.little); o += 4;

    for (final s in samples) {
      final pcm = (s * 32767).round().clamp(-32768, 32767);
      buf.setInt16(o, pcm, Endian.little);
      o += 2;
    }

    return buf.buffer.asUint8List();
  }
}
