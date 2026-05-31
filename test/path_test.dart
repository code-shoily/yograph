import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('Path construction', () {
    test('basic path', () {
      final path = Path([0, 1, 2], 15.0);
      expect(path.nodes, [0, 1, 2]);
      expect(path.weight, 15.0);
      expect(path.source, 0);
      expect(path.target, 2);
      expect(path.length, 2);
      expect(path.isTrivial, isFalse);
    });

    test('trivial path (single node)', () {
      final path = Path([5], 0.0);
      expect(path.nodes, [5]);
      expect(path.weight, 0.0);
      expect(path.source, 5);
      expect(path.target, 5);
      expect(path.length, 0);
      expect(path.isTrivial, isTrue);
    });

    test('two-node path', () {
      final path = Path([10, 20], 3.5);
      expect(path.length, 1);
      expect(path.isTrivial, isFalse);
    });
  });

  group('Path toString', () {
    test('formats correctly', () {
      final path = Path([0, 1, 2], 15.0);
      expect(path.toString(), 'Path(0 -> 1 -> 2, weight: 15.0)');
    });

    test('trivial path toString', () {
      final path = Path([5], 0.0);
      expect(path.toString(), 'Path(5, weight: 0.0)');
    });
  });
}
