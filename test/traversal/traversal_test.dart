import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

/// Helper: linear chain 0 -> 1 -> 2 -> 3 -> 4
SimpleGraph<String, int> _chain() {
  final g = SimpleGraph<String, int>.directed();
  for (var i = 0; i < 4; i++) {
    g.addEdge(i, i + 1);
  }
  return g;
}

/// Helper: binary tree
///       0
///      / \
///     1   2
///    / \   \
///   3   4   5
SimpleGraph<String, int> _tree() {
  final g = SimpleGraph<String, int>.directed();
  g.addEdge(0, 1);
  g.addEdge(0, 2);
  g.addEdge(1, 3);
  g.addEdge(1, 4);
  g.addEdge(2, 5);
  return g;
}

/// Helper: small cyclic graph
///   0 -> 1 -> 2
///   ^         |
///   +---------+
SimpleGraph<String, int> _cycle() {
  final g = SimpleGraph<String, int>.directed();
  g.addEdge(0, 1);
  g.addEdge(1, 2);
  g.addEdge(2, 0);
  return g;
}

/// Helper: DAG for topological sort
///   0 -> 1 -> 3
///   |         ^
///   v         |
///   2 -> 4 ---+
SimpleGraph<String, int> _dag() {
  final g = SimpleGraph<String, int>.directed();
  g.addEdge(0, 1);
  g.addEdge(0, 2);
  g.addEdge(1, 3);
  g.addEdge(2, 4);
  g.addEdge(4, 3);
  return g;
}

/// Helper: cyclic graph (has back edge)
///   0 -> 1 -> 2
///        ^    |
///        +----+
SimpleGraph<String, int> _cyclic() {
  final g = SimpleGraph<String, int>.directed();
  g.addEdge(0, 1);
  g.addEdge(1, 2);
  g.addEdge(2, 1);
  return g;
}

void main() {
  group('walk — BFS', () {
    test('linear chain', () {
      final g = _chain();
      expect(walk(g, from: 0, order: Order.breadthFirst), [0, 1, 2, 3, 4]);
    });

    test('binary tree — level order', () {
      final g = _tree();
      expect(walk(g, from: 0, order: Order.breadthFirst), [0, 1, 2, 3, 4, 5]);
    });

    test('cycle — starts at 0', () {
      final g = _cycle();
      final result = walk(g, from: 0, order: Order.breadthFirst);
      expect(result.first, 0);
      expect(result.toSet(), {0, 1, 2});
    });

    test('from isolated node', () {
      final g = SimpleGraph<String, int>.directed()..addNode(0);
      expect(walk(g, from: 0, order: Order.breadthFirst), [0]);
    });
  });

  group('walk — DFS', () {
    test('linear chain', () {
      final g = _chain();
      expect(walk(g, from: 0, order: Order.depthFirst), [0, 1, 2, 3, 4]);
    });

    test('binary tree — deep first', () {
      final g = _tree();
      // DFS explores left subtree fully before right
      final result = walk(g, from: 0, order: Order.depthFirst);
      expect(result.first, 0);
      // 0's successors are [1, 2]; DFS pushes in reverse so 1 is explored first
      expect(result.indexOf(3), lessThan(result.indexOf(2)));
      expect(result.indexOf(4), lessThan(result.indexOf(2)));
      expect(result.indexOf(5), greaterThan(result.indexOf(2)));
    });

    test('cycle — visits all nodes', () {
      final g = _cycle();
      final result = walk(g, from: 0, order: Order.depthFirst);
      expect(result.toSet(), {0, 1, 2});
    });
  });

  group('walkUntil', () {
    test('BFS stops at target', () {
      final g = _chain();
      final result = walkUntil(
        g,
        from: 0,
        order: Order.breadthFirst,
        until: (id) => id == 2,
      );
      expect(result, [0, 1, 2]);
    });

    test('DFS stops at target', () {
      final g = _tree();
      final result = walkUntil(
        g,
        from: 0,
        order: Order.depthFirst,
        until: (id) => id == 4,
      );
      expect(result.last, 4);
      // Should NOT have visited 2 or 5 (they come after 4 in DFS order)
      expect(result.contains(2), isFalse);
      expect(result.contains(5), isFalse);
    });

    test('never found — visits all reachable', () {
      final g = _chain();
      final result = walkUntil(
        g,
        from: 0,
        order: Order.breadthFirst,
        until: (id) => id == 99,
      );
      expect(result, [0, 1, 2, 3, 4]);
    });
  });

  group('foldWalk — WalkControl', () {
    test('Continue visits all', () {
      final g = _chain();
      final visited = foldWalk(
        g,
        from: 0,
        order: Order.breadthFirst,
        initial: <int>[],
        folder: (acc, id, _) => (WalkControl.continueWalk, [...acc, id]),
      );
      expect(visited, [0, 1, 2, 3, 4]);
    });

    test('Stop skips successors but continues queue', () {
      final g = _tree();
      // Stop at node 1 — don't explore 3, 4, but still visit 2, 5
      final visited = foldWalk(
        g,
        from: 0,
        order: Order.breadthFirst,
        initial: <int>[],
        folder: (acc, id, _) {
          return (
            id == 1 ? WalkControl.stopBranch : WalkControl.continueWalk,
            [...acc, id],
          );
        },
      );
      expect(visited.contains(1), isTrue);
      expect(visited.contains(3), isFalse);
      expect(visited.contains(4), isFalse);
      expect(visited.contains(2), isTrue);
      expect(visited.contains(5), isTrue);
    });

    test('Halt stops immediately', () {
      final g = _chain();
      final visited = foldWalk(
        g,
        from: 0,
        order: Order.breadthFirst,
        initial: <int>[],
        folder: (acc, id, _) {
          return (
            id == 2 ? WalkControl.halt : WalkControl.continueWalk,
            [...acc, id],
          );
        },
      );
      expect(visited, [0, 1, 2]);
    });
  });

  group('foldWalk — metadata', () {
    test('depth increases correctly in BFS', () {
      final g = _tree();
      final depths = foldWalk(
        g,
        from: 0,
        order: Order.breadthFirst,
        initial: <int, int>{},
        folder: (acc, id, meta) =>
            (WalkControl.continueWalk, {...acc, id: meta.depth}),
      );
      expect(depths[0], 0);
      expect(depths[1], 1);
      expect(depths[2], 1);
      expect(depths[3], 2);
      expect(depths[4], 2);
      expect(depths[5], 2);
    });

    test('parent chain in BFS', () {
      final g = _tree();
      final parents = foldWalk(
        g,
        from: 0,
        order: Order.breadthFirst,
        initial: <int, int?>{},
        folder: (acc, id, meta) =>
            (WalkControl.continueWalk, {...acc, id: meta.parent}),
      );
      expect(parents[0], isNull);
      expect(parents[1], 0);
      expect(parents[2], 0);
      expect(parents[3], 1);
      expect(parents[4], 1);
      expect(parents[5], 2);
    });
  });

  group('implicitFold', () {
    test('BFS on implicit grid', () {
      // 1D line: each position has neighbors pos-1 and pos+1 (bounded)
      Iterable<int> neighbors(int pos) sync* {
        if (pos > 0) yield pos - 1;
        if (pos < 4) yield pos + 1;
      }

      final result = implicitFold(
        0,
        order: Order.breadthFirst,
        initial: <int>[],
        successorsOf: neighbors,
        folder: (acc, id, _) => (WalkControl.continueWalk, [...acc, id]),
      );
      expect(result, [0, 1, 2, 3, 4]);
    });

    test('DFS on implicit tree', () {
      // Binary tree: node n has children 2n+1 and 2n+2
      Iterable<int> children(int n) sync* {
        yield 2 * n + 1;
        yield 2 * n + 2;
      }

      final result = implicitFold(
        0,
        order: Order.depthFirst,
        initial: <int>[],
        successorsOf: children,
        folder: (acc, id, meta) {
          if (meta.depth > 2) return (WalkControl.stopBranch, acc);
          return (WalkControl.continueWalk, [...acc, id]);
        },
      );
      expect(result.contains(0), isTrue);
      expect(result.contains(6), isTrue); // depth 2
      expect(result.contains(14), isFalse); // depth 3, skipped
    });
  });

  group('implicitFoldBy', () {
    test('state-space search with deduplication', () {
      // Node = (position, steps). We only want to visit each position once.
      final result = implicitFoldBy<(int, int), int, int>(
        (0, 0),
        order: Order.breadthFirst,
        initial: -1,
        successorsOf: (state) {
          final (pos, steps) = state;
          return [(pos + 1, steps + 1), (pos + 2, steps + 1)];
        },
        visitedBy: (state) => state.$1,
        folder: (acc, state, _) {
          if (state.$1 == 5) return (WalkControl.halt, state.$2);
          return (WalkControl.continueWalk, acc);
        },
      );
      expect(result, 3); // 0 -> 2 -> 4 -> 5 (or 0 -> 1 -> 3 -> 5)
    });
  });

  group('bestFirstWalk', () {
    test('visits nodes by score', () {
      // Star: 0 -> 1, 0 -> 2, 0 -> 3
      // Scores: 1=10, 2=5, 3=1
      final g = SimpleGraph<String, int>.directed()
        ..addEdge(0, 1)
        ..addEdge(0, 2)
        ..addEdge(0, 3);

      final result = bestFirstWalk(
        g,
        from: 0,
        scoredBy: (id) => switch (id) {
          1 => 10,
          2 => 5,
          3 => 1,
          _ => 0,
        },
      );
      expect(result.first, 0); // start
      expect(result[1], 3); // lowest score first
      expect(result[2], 2);
      expect(result[3], 1);
    });
  });

  group('bestFirstFold', () {
    test('halts early', () {
      final g = SimpleGraph<String, int>.directed()
        ..addEdge(0, 1)
        ..addEdge(0, 2)
        ..addEdge(0, 3);

      final result = bestFirstFold(
        g,
        from: 0,
        initial: <int>[],
        scoredBy: (id) => id,
        folder: (acc, id) {
          if (id == 2) return (WalkControl.halt, [...acc, id]);
          return (WalkControl.continueWalk, [...acc, id]);
        },
      );
      expect(result.contains(2), isTrue);
      // Depending on tie-breaking, may or may not contain 3
    });
  });

  group('randomWalk', () {
    test('with seed is reproducible', () {
      final g = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1)
        ..addEdge(0, 2)
        ..addEdge(1, 2);

      final r1 = randomWalk(g, from: 0, steps: 10, seed: 42);
      final r2 = randomWalk(g, from: 0, steps: 10, seed: 42);
      expect(r1, r2);
      expect(r1.first, 0);
      expect(r1.length, lessThanOrEqualTo(11));
    });

    test('stops at dead end', () {
      final g = SimpleGraph<String, int>.directed()..addEdge(0, 1);
      final result = randomWalk(g, from: 0, steps: 10);
      expect(result, [0, 1]);
    });
  });

  group('topologicalSort', () {
    test('DAG returns valid ordering', () {
      final g = _dag();
      final result = topologicalSort(g);
      expect(result, isNotNull);
      // Every edge goes from earlier to later in the result
      final pos = {for (var i = 0; i < result!.length; i++) result[i]: i};
      expect(pos[0]! < pos[1]!, isTrue);
      expect(pos[0]! < pos[2]!, isTrue);
      expect(pos[1]! < pos[3]!, isTrue);
      expect(pos[2]! < pos[4]!, isTrue);
      expect(pos[4]! < pos[3]!, isTrue);
    });

    test('cyclic graph returns null', () {
      final g = _cyclic();
      expect(topologicalSort(g), isNull);
    });

    test('empty graph', () {
      final g = SimpleGraph<String, int>.directed();
      expect(topologicalSort(g), []);
    });

    test('single node', () {
      final g = SimpleGraph<String, int>.directed()..addNode(0);
      expect(topologicalSort(g), [0]);
    });
  });

  group('lexicographicalTopologicalSort', () {
    test('orders by node data', () {
      // 0 -> 2, 1 -> 2
      // Node data: 0='B', 1='A', 2='C'
      final g = SimpleGraph<String, int>.directed()
        ..addNode(0, data: 'B')
        ..addNode(1, data: 'A')
        ..addNode(2, data: 'C')
        ..addEdge(0, 2)
        ..addEdge(1, 2);

      final result = lexicographicalTopologicalSort(
        g,
        (a, b) => a.compareTo(b),
      );
      expect(result, [1, 0, 2]); // 'A', 'B', 'C'
    });

    test('cyclic graph returns null', () {
      final g = _cyclic();
      expect(
        lexicographicalTopologicalSort(g, (a, b) => a.compareTo(b)),
        isNull,
      );
    });

    test('nodes without data fall back to ID comparison', () {
      final g = SimpleGraph<String, int>.directed()
        ..addEdge(2, 0)
        ..addEdge(1, 0);

      final result = lexicographicalTopologicalSort(
        g,
        (a, b) => a.compareTo(b),
      );
      expect(result, isNotNull);
      expect(result!.last, 0);
    });
  });
}
