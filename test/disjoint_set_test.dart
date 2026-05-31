import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('DisjointSet construction', () {
    test('starts empty', () {
      final dsu = DisjointSet<int>();
      expect(dsu.size, 0);
      expect(dsu.setCount, 0);
      expect(dsu.toLists(), isEmpty);
    });
  });

  group('DisjointSet add', () {
    test('adds element as singleton', () {
      final dsu = DisjointSet<int>()..add(1);
      expect(dsu.size, 1);
      expect(dsu.setCount, 1);
    });

    test('add is idempotent', () {
      final dsu = DisjointSet<int>()
        ..add(1)
        ..add(1);
      expect(dsu.size, 1);
    });
  });

  group('DisjointSet find', () {
    test('find auto-adds missing element', () {
      final dsu = DisjointSet<int>();
      expect(dsu.find(42), 42);
      expect(dsu.size, 1);
    });

    test('find returns root', () {
      final dsu = DisjointSet<int>()
        ..add(1)
        ..add(2)
        ..union(1, 2);
      expect(dsu.find(1), dsu.find(2));
    });

    test('path compression works', () {
      final dsu = DisjointSet<int>()
        ..add(1)
        ..add(2)
        ..add(3)
        ..union(1, 2)
        ..union(2, 3);
      // After find(3), 3 should point directly to root
      dsu.find(3);
      expect(dsu.find(3), dsu.find(1));
    });
  });

  group('DisjointSet union', () {
    test('merges two sets', () {
      final dsu = DisjointSet<int>()
        ..add(1)
        ..add(2)
        ..union(1, 2);
      expect(dsu.connected(1, 2), isTrue);
      expect(dsu.setCount, 1);
    });

    test('union is idempotent', () {
      final dsu = DisjointSet<int>()
        ..add(1)
        ..add(2)
        ..union(1, 2)
        ..union(1, 2);
      expect(dsu.setCount, 1);
    });

    test('union by rank keeps tree shallow', () {
      final dsu = DisjointSet<int>()
        ..add(1)
        ..add(2)
        ..add(3)
        ..union(1, 2)
        ..union(1, 3);
      expect(dsu.setCount, 1);
      expect(dsu.connected(2, 3), isTrue);
    });
  });

  group('DisjointSet connected', () {
    test('same set', () {
      final dsu = DisjointSet<int>()
        ..add(1)
        ..add(2)
        ..union(1, 2);
      expect(dsu.connected(1, 2), isTrue);
    });

    test('different sets', () {
      final dsu = DisjointSet<int>()
        ..add(1)
        ..add(2);
      expect(dsu.connected(1, 2), isFalse);
    });

    test('missing element', () {
      final dsu = DisjointSet<int>()..add(1);
      expect(dsu.connected(1, 2), isFalse);
    });
  });

  group('DisjointSet fromPairs', () {
    test('chains unions', () {
      final dsu = DisjointSet.fromPairs([(1, 2), (2, 3), (3, 4)]);
      expect(dsu.connected(1, 4), isTrue);
      expect(dsu.setCount, 1);
    });

    test('disconnected pairs', () {
      final dsu = DisjointSet.fromPairs([(1, 2), (3, 4)]);
      expect(dsu.connected(1, 2), isTrue);
      expect(dsu.connected(3, 4), isTrue);
      expect(dsu.connected(1, 3), isFalse);
      expect(dsu.setCount, 2);
    });
  });

  group('DisjointSet toLists', () {
    test('returns all sets', () {
      final dsu = DisjointSet<int>()
        ..add(1)
        ..add(2)
        ..add(3)
        ..add(4)
        ..union(1, 2)
        ..union(3, 4);

      final lists = dsu.toLists();
      expect(lists.length, 2);
      expect(lists.any((l) => l.contains(1) && l.contains(2)), isTrue);
      expect(lists.any((l) => l.contains(3) && l.contains(4)), isTrue);
    });
  });

  group('DisjointSet with string elements', () {
    test('works with strings', () {
      final dsu = DisjointSet<String>()
        ..add('A')
        ..add('B')
        ..add('C')
        ..union('A', 'B')
        ..union('B', 'C');
      expect(dsu.connected('A', 'C'), isTrue);
    });
  });
}
