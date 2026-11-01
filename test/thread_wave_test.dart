import 'package:flutter_test/flutter_test.dart';
import 'package:reticence/utils/thread_wave.dart';

void main() {
  group('ThreadWave', () {
    test('starts settled and becomes active after a pluck', () {
      final wave = ThreadWave();
      expect(wave.isSettled, isTrue);

      wave.pluck(0.5, amplitude: 10);

      expect(wave.isSettled, isFalse);
      expect(wave.displacements.length, wave.segments + 1);
      expect(wave.displacements.first, 0);
      expect(wave.displacements.last, 0);
      expect(wave.maxAbsDisplacement, greaterThan(5));
    });

    test('is localized around the pluck position', () {
      final wave = ThreadWave();
      wave.pluck(0.5, amplitude: 10);

      final center = wave.segments ~/ 2;
      final nearEdge = wave.segments ~/ 8;

      expect(wave.displacements[center].abs(), greaterThan(5));
      expect(wave.displacements[nearEdge].abs(), lessThan(0.1));
    });

    test('propagates away from the pluck point', () {
      final wave = ThreadWave();
      const probe = 5;
      wave.pluck(0.5, amplitude: 10);
      expect(wave.displacements[probe].abs(), lessThan(0.05));

      for (var i = 0; i < 36; i++) {
        wave.step(1 / 120);
      }

      expect(wave.displacements[probe].abs(), greaterThan(0.05));
    });

    test('keeps both endpoints fixed while stepping', () {
      final wave = ThreadWave();
      wave.pluck(0.02, amplitude: 12);

      for (var i = 0; i < 120; i++) {
        wave.step(1 / 120);
        expect(wave.displacements.first, 0);
        expect(wave.displacements.last, 0);
      }
    });

    test('damping settles the wave', () {
      final wave = ThreadWave();
      wave.pluck(0.5, amplitude: 10);

      var steps = 0;
      while (!wave.isSettled && steps < 1200) {
        wave.step(1 / 120);
        steps++;
      }

      expect(wave.isSettled, isTrue);
      expect(steps, lessThan(1000));
    });

    test('repeated plucks are clamped to the displacement limit', () {
      final wave = ThreadWave(maxDisplacement: 24);
      for (var i = 0; i < 30; i++) {
        wave.pluck(0.5, amplitude: 20);
      }

      expect(wave.maxAbsDisplacement, lessThanOrEqualTo(24));
    });

    test('clear resets the wave', () {
      final wave = ThreadWave();
      wave.pluck(0.5, amplitude: 10);
      for (var i = 0; i < 20; i++) {
        wave.step(1 / 120);
      }

      wave.clear();

      expect(wave.isSettled, isTrue);
      expect(wave.maxAbsDisplacement, 0);
    });
  });
}
