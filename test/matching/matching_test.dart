import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

/// Validates that a matching map is bidirectional and has no shared endpoints.
void _assertValidMatching(Map<int, int> matching) {
  final seen = <int>{};
  for (final entry in matching.entries) {
    expect(matching[entry.value], entry.key);
    if (seen.add(entry.key)) {
      expect(seen.contains(entry.value), isFalse);
      seen.add(entry.value);
    }
  }
}

/// Number of unique matched pairs in a bidirectional matching map.
int _pairCount(Map<int, int> matching) => matching.length ~/ 2;

void main() {
  group('Matching.hopcroftKarp', () {
    test('empty graph', () {
      final g = SimpleGraph<String, int>.undirected();
      expect(Matching.hopcroftKarp(g), isEmpty);
    });

    test('path P4', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (1, 2, 1),
        (2, 3, 1),
      ], kind: GraphKind.undirected);
      final m = Matching.hopcroftKarp(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 2);
    });

    test('star K1,3', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (0, 2, 1),
        (0, 3, 1),
      ], kind: GraphKind.undirected);
      final m = Matching.hopcroftKarp(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 1);
    });

    test('complete bipartite K2,2', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 2, 1),
        (0, 3, 1),
        (1, 2, 1),
        (1, 3, 1),
      ], kind: GraphKind.undirected);
      final m = Matching.hopcroftKarp(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 2);
    });

    test('non-bipartite graph throws', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (1, 2, 1),
        (2, 0, 1),
      ], kind: GraphKind.undirected);
      expect(() => Matching.hopcroftKarp(g), throwsArgumentError);
    });

    test('disconnected components', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (2, 3, 1),
        (4, 5, 1),
      ], kind: GraphKind.undirected);
      final m = Matching.hopcroftKarp(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 3);
    });

    test('directed bipartite treated as undirected', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 2, 1),
        (1, 3, 1),
      ], kind: GraphKind.directed);
      final m = Matching.hopcroftKarp(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 2);
    });

    test('unbalanced partitions', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 3, 1),
        (1, 3, 1),
        (1, 4, 1),
        (2, 4, 1),
      ], kind: GraphKind.undirected);
      final m = Matching.hopcroftKarp(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 2);
    });
  });

  group('Matching.hungarian', () {
    test('3x3 minimum assignment', () {
      // Optimal: 0-5 (1), 1-3 (3), 2-4 (4) = 8
      final g = SimpleGraph<String, int>.undirected();
      final edges = [
        (0, 3, 4),
        (0, 4, 2),
        (0, 5, 1),
        (1, 3, 3),
        (1, 4, 6),
        (1, 5, 5),
        (2, 3, 2),
        (2, 4, 4),
        (2, 5, 6),
      ];
      for (final (u, v, w) in edges) {
        g.addEdge(u, v, data: w);
      }

      final result = Matching.hungarian(g);
      expect(result.cost, closeTo(8.0, 1e-9));
      expect(result.matching.length, 6); // 3 bidirectional pairs
    });

    test('2x2 maximum assignment', () {
      // Optimal max: 0-3 (10), 1-2 (6) = 16
      final g = SimpleGraph<String, int>.undirected();
      g.addEdge(0, 2, data: 3);
      g.addEdge(0, 3, data: 10);
      g.addEdge(1, 2, data: 6);
      g.addEdge(1, 3, data: 4);

      final result = Matching.hungarian(
        g,
        optimization: HungarianOptimization.max,
      );
      expect(result.cost, closeTo(16.0, 1e-9));
    });

    test('3x2 rectangular minimum', () {
      // 3 workers, 2 tasks, pad with dummy task.
      final g = SimpleGraph<String, int>.undirected();
      g.addEdge(0, 3, data: 5);
      g.addEdge(0, 4, data: 9);
      g.addEdge(1, 3, data: 8);
      g.addEdge(1, 4, data: 3);
      g.addEdge(2, 3, data: 6);
      g.addEdge(2, 4, data: 7);

      final result = Matching.hungarian(g);
      // Best is 0-3 (5), 1-4 (3), 2 dummy (0) = 8
      expect(result.cost, closeTo(8.0, 1e-9));
    });

    test('2x3 rectangular maximum', () {
      // 2 workers, 3 tasks, pad with dummy worker.
      final g = SimpleGraph<String, int>.undirected();
      g.addEdge(0, 2, data: 5);
      g.addEdge(0, 3, data: 8);
      g.addEdge(0, 4, data: 1);
      g.addEdge(1, 2, data: 7);
      g.addEdge(1, 3, data: 2);
      g.addEdge(1, 4, data: 9);

      final result = Matching.hungarian(
        g,
        optimization: HungarianOptimization.max,
      );
      // Best is 0-3 (8), 1-4 (9), task 2 dummy (0) = 17
      expect(result.cost, closeTo(17.0, 1e-9));
    });

    test('non-complete bipartite throws', () {
      final g = SimpleGraph<String, int>.undirected();
      g.addEdge(0, 2, data: 1);
      g.addEdge(1, 3, data: 1);
      // Missing 0-3 and 1-2
      expect(() => Matching.hungarian(g), throwsArgumentError);
    });

    test('non-bipartite graph throws', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (1, 2, 1),
        (2, 0, 1),
      ], kind: GraphKind.undirected);
      expect(() => Matching.hungarian(g), throwsArgumentError);
    });

    test('empty graph', () {
      final g = SimpleGraph<String, int>.undirected();
      final result = Matching.hungarian(g);
      expect(result.cost, 0.0);
      expect(result.matching, isEmpty);
    });
  });

  group('Matching.blossomMaximumMatching', () {
    test('empty graph', () {
      final g = SimpleGraph<String, int>.undirected();
      expect(Matching.blossomMaximumMatching(g), isEmpty);
    });

    test('isolated nodes', () {
      final g = SimpleGraph<String, int>.undirected();
      g.addNode(0);
      g.addNode(1);
      expect(Matching.blossomMaximumMatching(g), isEmpty);
    });

    test('single edge', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
      ], kind: GraphKind.undirected);
      final m = Matching.blossomMaximumMatching(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 1);
    });

    test('triangle', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (1, 2, 1),
        (2, 0, 1),
      ], kind: GraphKind.undirected);
      final m = Matching.blossomMaximumMatching(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 1);
    });

    test('square', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (1, 2, 1),
        (2, 3, 1),
        (3, 0, 1),
      ], kind: GraphKind.undirected);
      final m = Matching.blossomMaximumMatching(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 2);
    });

    test('pentagon', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (1, 2, 1),
        (2, 3, 1),
        (3, 4, 1),
        (4, 0, 1),
      ], kind: GraphKind.undirected);
      final m = Matching.blossomMaximumMatching(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 2);
    });

    test('K4', () {
      final g = SimpleGraph<String, int>.undirected();
      for (var i = 0; i < 4; i++) {
        for (var j = i + 1; j < 4; j++) {
          g.addEdge(i, j, data: 1);
        }
      }
      final m = Matching.blossomMaximumMatching(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 2);
    });

    test('K5', () {
      final g = SimpleGraph<String, int>.undirected();
      for (var i = 0; i < 5; i++) {
        for (var j = i + 1; j < 5; j++) {
          g.addEdge(i, j, data: 1);
        }
      }
      final m = Matching.blossomMaximumMatching(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 2);
    });

    test('K6', () {
      final g = SimpleGraph<String, int>.undirected();
      for (var i = 0; i < 6; i++) {
        for (var j = i + 1; j < 6; j++) {
          g.addEdge(i, j, data: 1);
        }
      }
      final m = Matching.blossomMaximumMatching(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 3);
    });

    test('star', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (0, 2, 1),
        (0, 3, 1),
        (0, 4, 1),
      ], kind: GraphKind.undirected);
      final m = Matching.blossomMaximumMatching(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 1);
    });

    test('path P5', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (1, 2, 1),
        (2, 3, 1),
        (3, 4, 1),
      ], kind: GraphKind.undirected);
      final m = Matching.blossomMaximumMatching(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 2);
    });

    test('two disjoint triangles', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (1, 2, 1),
        (2, 0, 1),
        (3, 4, 1),
        (4, 5, 1),
        (5, 3, 1),
      ], kind: GraphKind.undirected);
      final m = Matching.blossomMaximumMatching(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 2);
    });

    test('bowtie', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1), (1, 2, 1), (2, 0, 1), // triangle left
        (2, 3, 1), (3, 4, 1), (4, 2, 1), // triangle right (share node 2)
      ], kind: GraphKind.undirected);
      final m = Matching.blossomMaximumMatching(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 2);
    });

    test('agrees with Hopcroft-Karp on bipartite graph', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 4, 1),
        (0, 5, 1),
        (1, 4, 1),
        (1, 5, 1),
        (2, 6, 1),
        (3, 6, 1),
      ], kind: GraphKind.undirected);
      final blossom = Matching.blossomMaximumMatching(g);
      final hopcroft = Matching.hopcroftKarp(g);
      _assertValidMatching(blossom);
      _assertValidMatching(hopcroft);
      expect(_pairCount(blossom), _pairCount(hopcroft));
    });

    test('directed graph treated as undirected', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (2, 1, 1),
      ], kind: GraphKind.directed);
      final m = Matching.blossomMaximumMatching(g);
      _assertValidMatching(m);
      expect(_pairCount(m), 1);
    });
  });
}
