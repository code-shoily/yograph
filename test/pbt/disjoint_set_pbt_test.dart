import 'package:glados/glados.dart';
import 'package:yograph/yograph.dart';

void main() {
  Glados<List<int>>().test(
    'Reflexivity: Every element is connected to itself',
    (elements) {
      final uniqueElements = elements.toSet().toList();
      if (uniqueElements.isEmpty) return;

      final dsu = DisjointSet<int>();
      for (final x in uniqueElements) {
        dsu.add(x);
      }

      for (final x in uniqueElements) {
        expect(dsu.connected(x, x), isTrue);
      }
    },
  );

  Glados2<List<int>, List<List<int>>>(
    any.list(any.int),
    any.list(any.list(any.int)),
  ).test('Symmetry: connectedness is bidirectional', (
    elements,
    pairsIndexList,
  ) {
    final uniqueElements = elements.toSet().toList();
    if (uniqueElements.length < 2) return;

    final pairs = <(int, int)>[];
    for (final indices in pairsIndexList) {
      if (indices.length >= 2) {
        final x = uniqueElements[indices[0].abs() % uniqueElements.length];
        final y = uniqueElements[indices[1].abs() % uniqueElements.length];
        pairs.add((x, y));
      }
    }

    final dsu = DisjointSet<int>.fromPairs(pairs);
    for (final x in uniqueElements) {
      dsu.add(x);
    }

    for (final x in uniqueElements) {
      for (final y in uniqueElements) {
        expect(dsu.connected(x, y), equals(dsu.connected(y, x)));
      }
    }
  });

  Glados2<List<int>, List<List<int>>>(
    any.list(any.int),
    any.list(any.list(any.int)),
  ).test('Transitivity: If x-y and y-z, then x-z', (elements, pairsIndexList) {
    final uniqueElements = elements.toSet().toList();
    if (uniqueElements.length < 3) return;

    final pairs = <(int, int)>[];
    for (final indices in pairsIndexList) {
      if (indices.length >= 2) {
        final x = uniqueElements[indices[0].abs() % uniqueElements.length];
        final y = uniqueElements[indices[1].abs() % uniqueElements.length];
        pairs.add((x, y));
      }
    }

    final dsu = DisjointSet<int>.fromPairs(pairs);
    for (final x in uniqueElements) {
      dsu.add(x);
    }

    for (final x in uniqueElements) {
      for (final y in uniqueElements) {
        for (final z in uniqueElements) {
          final xy = dsu.connected(x, y);
          final yz = dsu.connected(y, z);
          final xz = dsu.connected(x, z);

          if (xy && yz) {
            expect(xz, isTrue, reason: 'Expected $x to connect to $z via $y');
          }
        }
      }
    }
  });

  Glados2<List<int>, List<List<int>>>(
    any.list(any.int),
    any.list(any.list(any.int)),
  ).test('Union set count reduces by 1 for distinct, 0 for same set', (
    elements,
    pairsIndexList,
  ) {
    final uniqueElements = elements.toSet().toList();
    if (uniqueElements.length < 2) return;

    final dsu = DisjointSet<int>();
    for (final x in uniqueElements) {
      dsu.add(x);
    }

    var expectedSetCount = uniqueElements.length;
    expect(dsu.setCount, expectedSetCount);

    for (final indices in pairsIndexList) {
      if (indices.length >= 2) {
        final x = uniqueElements[indices[0].abs() % uniqueElements.length];
        final y = uniqueElements[indices[1].abs() % uniqueElements.length];

        final alreadyConnected = dsu.connected(x, y);
        dsu.union(x, y);

        if (alreadyConnected) {
          expect(dsu.setCount, expectedSetCount);
        } else {
          expectedSetCount--;
          expect(dsu.setCount, expectedSetCount);
        }
      }
    }
  });

  Glados<List<int>>().test(
    'Partitioning coverage: toLists produces disjoint sets covering all elements',
    (elements) {
      final uniqueElements = elements.toSet().toList();
      if (uniqueElements.isEmpty) return;

      final dsu = DisjointSet<int>();
      for (final x in uniqueElements) {
        dsu.add(x);
      }

      // randomly union some elements
      for (var i = 0; i < uniqueElements.length - 1; i += 2) {
        dsu.union(uniqueElements[i], uniqueElements[i + 1]);
      }

      final lists = dsu.toLists();
      final allInLists = <int>{};

      for (var i = 0; i < lists.length; i++) {
        for (var j = i + 1; j < lists.length; j++) {
          // Disjointness check
          final intersection = lists[i].toSet().intersection(lists[j].toSet());
          expect(intersection, isEmpty);
        }
        allInLists.addAll(lists[i]);
      }

      // Coverage check
      expect(allInLists, equals(uniqueElements.toSet()));
    },
  );
}
