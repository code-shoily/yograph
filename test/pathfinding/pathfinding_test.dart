import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

// =============================================================================
// Test graphs
// =============================================================================

/// Classic Dijkstra graph (directed).
///
///     A --4--> B --5--> D --2--> E --2--> F
///     |        ↑         |         |         |
///     2        1         8         6         |
///     |        |         |         |         |
///     └---> C ─┘         └────┬────┘         |
///                             10              |
///                             └───────────────┘
///
/// Shortest A→F: A→C→B→D→E→F = 2+1+5+2+2 = 12
SimpleGraph<String, int> _classicDijkstra() {
  return SimpleGraph.fromEdgesWithData([
    (0, 1, 4), // A -> B
    (0, 2, 2), // A -> C
    (2, 1, 1), // C -> B
    (1, 3, 5), // B -> D
    (2, 3, 8), // C -> D
    (2, 4, 10), // C -> E
    (3, 4, 2), // D -> E
    (3, 5, 6), // D -> F
    (4, 5, 2), // E -> F
  ]);
}

/// A* textbook graph (directed).
///
///     A --2--> B --2--> D --2--> E --2--> G
///     |                 |                 ↑
///     2                 2                 |
///     |                 |                 |
///     └---> C --3------┘                 4
///           └────┬────────────────────────┘
///                F
///
/// Shortest A→G: A→B→D→E→G = 2+2+2+2 = 8
SimpleGraph<String, int> _aStarGraph() {
  return SimpleGraph.fromEdgesWithData([
    (0, 1, 2), // A -> B
    (0, 2, 2), // A -> C
    (1, 3, 2), // B -> D
    (2, 3, 3), // C -> D
    (1, 4, 5), // B -> E
    (3, 4, 2), // D -> E
    (3, 5, 2), // D -> F
    (4, 6, 2), // E -> G
    (5, 6, 4), // F -> G
  ]);
}

/// Widest-path graph (directed).
///
///     A --100--> B --80--> D
///     |                      |
///     50                     200
///     |                      |
///     └---> C --------------┘
///
/// Widest A→D: A→B→D = min(100,80) = 80
SimpleGraph<String, int> _widestGraph() {
  return SimpleGraph.fromEdgesWithData([
    (0, 1, 100), // A -> B
    (0, 2, 50), // A -> C
    (1, 3, 80), // B -> D
    (2, 3, 200), // C -> D
  ]);
}

// =============================================================================
// Dijkstra.shortestPath
// =============================================================================

void main() {
  group('Dijkstra.shortestPath', () {
    test('classic graph — shortest A→F', () {
      final g = _classicDijkstra();
      final path = Dijkstra.shortestPath(g, 0, 5);
      expect(path, isNotNull);
      expect(path!.nodes, [0, 2, 1, 3, 4, 5]);
      expect(path.weight, 12.0);
    });

    test('direct edge is shortest', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 3);
      g.addEdge(0, 2, data: 1);
      g.addEdge(2, 1, data: 1);

      final path = Dijkstra.shortestPath(g, 0, 1);
      expect(path!.nodes, [0, 2, 1]);
      expect(path.weight, 2.0);
    });

    test('same source and target', () {
      final g = _classicDijkstra();
      final path = Dijkstra.shortestPath(g, 0, 0);
      expect(path!.nodes, [0]);
      expect(path.weight, 0.0);
    });

    test('no path exists', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addNode(2);

      expect(Dijkstra.shortestPath(g, 0, 2), isNull);
    });

    test('missing from node', () {
      final g = _classicDijkstra();
      expect(Dijkstra.shortestPath(g, 99, 0), isNull);
    });

    test('missing to node', () {
      final g = _classicDijkstra();
      expect(Dijkstra.shortestPath(g, 0, 99), isNull);
    });

    test('undirected graph', () {
      final g = SimpleGraph<String, int>.undirected();
      g.addEdge(0, 1, data: 3);
      g.addEdge(1, 2, data: 4);

      final path = Dijkstra.shortestPath(g, 0, 2);
      expect(path!.nodes, [0, 1, 2]);
      expect(path.weight, 7.0);
    });

    test('custom semiring — max-sum path', () {
      // Find the path that MAXIMISES the sum of edge weights.
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addEdge(0, 2, data: 5);
      g.addEdge(2, 1, data: 5);

      final path = Dijkstra.shortestPath(
        g,
        0,
        1,
        zero: 0.0,
        add: (a, b) => a + b,
        compare: (a, b) => b.compareTo(a), // reverse → maximise
      );
      expect(path!.nodes, [0, 2, 1]);
      expect(path.weight, 10.0);
    });
  });

  // ===========================================================================
  // AStar.aStar
  // ===========================================================================

  group('AStar.aStar', () {
    test('zero heuristic equals Dijkstra', () {
      final g = _classicDijkstra();
      final dijkstra = Dijkstra.shortestPath(g, 0, 5);
      final astar = AStar.aStar(g, 0, 5, heuristic: (_, _) => 0.0);
      expect(astar!.nodes, dijkstra!.nodes);
      expect(astar.weight, dijkstra.weight);
    });

    test('textbook graph with heuristic', () {
      final g = _aStarGraph();
      // Admissible heuristic: never over-estimates.
      final h = <int, double>{0: 6, 1: 4, 2: 6, 3: 4, 4: 2, 5: 4, 6: 0};

      final path = AStar.aStar(g, 0, 6, heuristic: (n, _) => h[n] ?? 0.0);
      expect(path!.nodes, [0, 1, 3, 4, 6]);
      expect(path.weight, 8.0);
    });

    test('same source and target', () {
      final g = _aStarGraph();
      final path = AStar.aStar(g, 0, 0, heuristic: (_, _) => 0.0);
      expect(path!.nodes, [0]);
      expect(path.weight, 0.0);
    });

    test('no path exists', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addNode(2);

      expect(AStar.aStar(g, 0, 2, heuristic: (_, _) => 0.0), isNull);
    });

    test('grid with Manhattan heuristic', () {
      // 2x2 grid: (0,0) → (1,1)
      //   (0,0) --1--> (1,0)
      //     |              |
      //     1              1
      //     |              |
      //   (0,1) --1--> (1,1)
      final g = SimpleGraph<String, int>.directed();
      // Map 2-D coords to flat IDs: (x,y) → x*2 + y
      // (0,0)=0, (1,0)=1, (0,1)=2, (1,1)=3
      g.addEdge(0, 1, data: 1); // (0,0) → (1,0)
      g.addEdge(0, 2, data: 1); // (0,0) → (0,1)
      g.addEdge(1, 3, data: 1); // (1,0) → (1,1)
      g.addEdge(2, 3, data: 1); // (0,1) → (1,1)

      // Node data stores the coordinate for heuristic lookup.
      // We can just hardcode the heuristic for each flat ID.
      final manhattan = <int, double>{
        0: 2, // (0,0) → (1,1): |0-1|+|0-1| = 2
        1: 1, // (1,0) → (1,1): 1
        2: 1, // (0,1) → (1,1): 1
        3: 0, // goal
      };

      final path = AStar.aStar(g, 0, 3, heuristic: (n, _) => manhattan[n]!);
      expect(path!.weight, 2.0);
      expect(path.length, 2);
    });
  });

  // ===========================================================================
  // Dijkstra.singleSourceDistances
  // ===========================================================================

  group('Dijkstra.singleSourceDistances', () {
    test('classic graph from A', () {
      final g = _classicDijkstra();
      final dists = Dijkstra.singleSourceDistances(g, 0);
      expect(dists, {
        0: 0.0,
        1: 3.0, // A→C→B
        2: 2.0, // A→C
        3: 8.0, // A→C→B→D
        4: 10.0, // A→C→B→D→E
        5: 12.0, // A→C→B→D→E→F
      });
    });

    test('single node', () {
      final g = SimpleGraph<String, int>.directed()..addNode(0);
      final dists = Dijkstra.singleSourceDistances(g, 0);
      expect(dists, {0: 0.0});
    });

    test('missing from node', () {
      final g = SimpleGraph<String, int>.directed()..addNode(0);
      expect(Dijkstra.singleSourceDistances(g, 99), isEmpty);
    });

    test('unreachable nodes omitted', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addNode(2);

      final dists = Dijkstra.singleSourceDistances(g, 0);
      expect(dists.containsKey(2), isFalse);
    });

    test('custom semiring — max distance', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addEdge(0, 2, data: 5);
      g.addEdge(2, 1, data: 5);

      final dists = Dijkstra.singleSourceDistances(
        g,
        0,
        compare: (a, b) => b.compareTo(a),
      );
      // Maximising sum: 0→2→1 = 10
      expect(dists[1], 10.0);
      expect(dists[2], 5.0);
    });
  });

  // ===========================================================================
  // Dijkstra.widestPath
  // ===========================================================================

  group('Dijkstra.widestPath', () {
    test('classic widest path', () {
      final g = _widestGraph();
      final path = Dijkstra.widestPath(g, 0, 3);
      expect(path!.nodes, [0, 1, 3]);
      expect(path.weight, 80.0); // min(100, 80)
    });

    test('same source and target', () {
      final g = _widestGraph();
      final path = Dijkstra.widestPath(g, 0, 0);
      expect(path!.nodes, [0]);
      expect(path.weight, double.infinity);
    });

    test('no path', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 10);
      g.addNode(2);
      expect(Dijkstra.widestPath(g, 0, 2), isNull);
    });

    test('undirected widest path', () {
      final g = SimpleGraph<String, int>.undirected();
      g.addEdge(0, 1, data: 3);
      g.addEdge(1, 2, data: 5);
      g.addEdge(0, 2, data: 2);

      final path = Dijkstra.widestPath(g, 0, 2);
      expect(path!.weight, 3.0); // 0→1→2, min(3,5)=3
    });
  });

  // ===========================================================================
  // AStar.implicitAStar
  // ===========================================================================

  group('AStar.implicitAStar', () {
    test('linear chain', () {
      final result = AStar.implicitAStar(
        from: 1,
        successors: (n) => n < 4 ? [(n + 1, 1.0)] : [],
        isGoal: (n) => n == 4,
        heuristic: (n) => (4 - n).toDouble(),
      );
      expect(result, isNotNull);
      expect(result!.$1, 4);
      expect(result.$2, 3.0); // 1→2→3→4
    });

    test('start is goal', () {
      final result = AStar.implicitAStar(
        from: 10,
        successors: (_) => [],
        isGoal: (n) => n == 10,
        heuristic: (_) => 0.0,
      );
      expect(result!.$1, 10);
      expect(result.$2, 0.0);
    });

    test('no solution', () {
      final result = AStar.implicitAStar(
        from: 1,
        successors: (_) => [],
        isGoal: (_) => false,
        heuristic: (_) => 0.0,
      );
      expect(result, isNull);
    });

    test('branching with heuristic guidance', () {
      //        1
      //      /   \
      //    2(10)  3(1)
      //    |      |
      //    4      4
      // Heuristic: h(2)=0, h(3)=0 (admissible, both underestimate)
      // A* should still find optimal path 1→3→4 = 2, not 1→2→4 = 11
      final result = AStar.implicitAStar(
        from: 1,
        successors: (n) => switch (n) {
          1 => [(2, 10.0), (3, 1.0)],
          2 => [(4, 1.0)],
          3 => [(4, 1.0)],
          _ => <(int, double)>[],
        },
        isGoal: (n) => n == 4,
        heuristic: (_) => 0.0,
      );
      expect(result!.$2, 2.0);
    });
  });

  // ===========================================================================
  // AStar.implicitAStarBy
  // ===========================================================================

  group('AStar.implicitAStarBy', () {
    test('grid with direction — deduplicate by position', () {
      // State is (x, y, dir).  We only care about (x, y) for visited.
      // Can move east or south.  Goal: (2, 2).
      (int, int, String) move(int x, int y, String dir) => (x, y, dir);

      final result = AStar.implicitAStarBy(
        from: move(0, 0, 'start'),
        successors: (s) {
          final (x, y, _) = s;
          final next = <((int, int, String), double)>[];
          if (x < 2) next.add((move(x + 1, y, 'east'), 1.0));
          if (y < 2) next.add((move(x, y + 1, 'south'), 1.0));
          return next;
        },
        visitedBy: (s) {
          final (x, y, _) = s;
          return (x, y);
        },
        isGoal: (s) {
          final (x, y, _) = s;
          return x == 2 && y == 2;
        },
        heuristic: (s) {
          final (x, y, _) = s;
          return ((2 - x) + (2 - y)).toDouble();
        },
      );
      expect(result, isNotNull);
      expect(result!.$2, 4.0); // 2 east + 2 south
    });

    test('custom key prevents exponential blow-up', () {
      // States are strings with a counter suffix, but the "real" state
      // is just the prefix character.
      var counter = 0;
      String next(String prefix) => '$prefix${counter++}';

      final result = AStar.implicitAStarBy(
        from: next('A'),
        successors: (s) {
          final prefix = s[0];
          return switch (prefix) {
            'A' => [(next('B'), 1.0)],
            'B' => [(next('C'), 1.0)],
            _ => <(String, double)>[],
          };
        },
        visitedBy: (s) => s[0],
        isGoal: (s) => s[0] == 'C',
        heuristic: (_) => 0.0,
      );
      expect(result!.$2, 2.0);
    });
  });

  // ===========================================================================
  // Dijkstra.implicitDijkstra / implicitDijkstraBy
  // ===========================================================================

  group('Dijkstra.implicitDijkstra', () {
    test('same as implicitAStar with zero heuristic', () {
      final astar = AStar.implicitAStar(
        from: 1,
        successors: (n) => n < 4 ? [(n + 1, 1.0)] : [],
        isGoal: (n) => n == 4,
        heuristic: (_) => 0.0,
      );
      final dijkstra = Dijkstra.implicitDijkstra(
        from: 1,
        successors: (n) => n < 4 ? [(n + 1, 1.0)] : [],
        isGoal: (n) => n == 4,
      );
      expect(dijkstra!.$1, astar!.$1);
      expect(dijkstra.$2, astar.$2);
    });
  });

  group('Dijkstra.implicitDijkstraBy', () {
    test('grid without heuristic', () {
      final result = Dijkstra.implicitDijkstraBy(
        from: (0, 0, 'start'),
        successors: (s) {
          final (x, y, _) = s;
          final next = <((int, int, String), double)>[];
          if (x < 2) next.add(((x + 1, y, 'east'), 1.0));
          if (y < 2) next.add(((x, y + 1, 'south'), 1.0));
          return next;
        },
        visitedBy: (s) {
          final (x, y, _) = s;
          return (x, y);
        },
        isGoal: (s) {
          final (x, y, _) = s;
          return x == 2 && y == 2;
        },
      );
      expect(result!.$2, 4.0);
    });
  });

  // ===========================================================================
  // Bellman-Ford
  // ===========================================================================

  group('BellmanFord.shortestPath', () {
    test('classic graph with negative weights', () {
      // S=0, A=1, B=2, C=3, D=4
      // S→A=4, S→B=3, A→B=-2, A→C=4, B→C=-3, B→D=1, C→D=2
      // Shortest S→D = 4 + (-2) + (-3) + 2 = 1
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 4);
      g.addEdge(0, 2, data: 3);
      g.addEdge(1, 2, data: -2);
      g.addEdge(1, 3, data: 4);
      g.addEdge(2, 3, data: -3);
      g.addEdge(2, 4, data: 1);
      g.addEdge(3, 4, data: 2);

      final result = BellmanFord.shortestPath(g, 0, 4);
      expect(result.isSuccess, isTrue);
      expect(result.path!.nodes, [0, 1, 2, 3, 4]);
      expect(result.path!.weight, 1.0);
    });

    test('matches Dijkstra on positive-weight graph', () {
      final g = _classicDijkstra();
      final bf = BellmanFord.shortestPath(g, 0, 5);
      final dj = Dijkstra.shortestPath(g, 0, 5);
      expect(bf.path!.nodes, dj!.nodes);
      expect(bf.path!.weight, dj.weight);
    });

    test('same source and target', () {
      final g = _classicDijkstra();
      final result = BellmanFord.shortestPath(g, 0, 0);
      expect(result.isSuccess, isTrue);
      expect(result.path!.nodes, [0]);
      expect(result.path!.weight, 0.0);
    });

    test('no path exists', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addNode(2);

      final result = BellmanFord.shortestPath(g, 0, 2);
      expect(result.isSuccess, isFalse);
      expect(result.hasNegativeCycle, isFalse);
      expect(result.path, isNull);
    });

    test('missing from node', () {
      final g = _classicDijkstra();
      final result = BellmanFord.shortestPath(g, 99, 0);
      expect(result.isSuccess, isFalse);
    });

    test('missing to node', () {
      final g = _classicDijkstra();
      final result = BellmanFord.shortestPath(g, 0, 99);
      expect(result.isSuccess, isFalse);
    });

    test('negative cycle detection', () {
      // X→Y=1, Y→Z=1, Z→X=-3  (cycle weight = -1)
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addEdge(1, 2, data: 1);
      g.addEdge(2, 0, data: -3);

      final result = BellmanFord.shortestPath(g, 0, 1);
      expect(result.isSuccess, isFalse);
      expect(result.hasNegativeCycle, isTrue);
      expect(result.path, isNull);
    });

    test('negative cycle not on shortest path still detected', () {
      // 0→1=1, 1→2=1, 2→0=-3 (negative cycle)
      // 0→3=5
      // Even though the "shortest path" to 3 doesn't use the cycle,
      // the cycle is reachable so distances are undefined.
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addEdge(1, 2, data: 1);
      g.addEdge(2, 0, data: -3);
      g.addEdge(0, 3, data: 5);

      final result = BellmanFord.shortestPath(g, 0, 3);
      expect(result.hasNegativeCycle, isTrue);
    });
  });

  group('BellmanFord.singleSourceDistances', () {
    test('classic graph with negative weights', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 4);
      g.addEdge(0, 2, data: 3);
      g.addEdge(1, 2, data: -2);
      g.addEdge(2, 3, data: -3);
      g.addEdge(3, 4, data: 2);

      final dists = BellmanFord.singleSourceDistances(g, 0);
      expect(dists[0], 0.0);
      expect(dists[1], 4.0);
      expect(dists[2], 2.0); // 0→1→2 = 4+(-2) = 2, or 0→2 = 3
      expect(dists[3], -1.0); // 0→1→2→3 = 4+(-2)+(-3) = -1
      expect(dists[4], 1.0); // -1 + 2 = 1
    });

    test('single node', () {
      final g = SimpleGraph<String, int>.directed()..addNode(0);
      final dists = BellmanFord.singleSourceDistances(g, 0);
      expect(dists, {0: 0.0});
    });

    test('missing from node', () {
      final g = SimpleGraph<String, int>.directed()..addNode(0);
      expect(BellmanFord.singleSourceDistances(g, 99), isEmpty);
    });
  });

  group('BellmanFord.hasNegativeCycle', () {
    test('detects negative cycle', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addEdge(1, 2, data: 1);
      g.addEdge(2, 0, data: -3);

      expect(BellmanFord.hasNegativeCycle(g, 0), isTrue);
    });

    test('no negative cycle in positive graph', () {
      final g = _classicDijkstra();
      expect(BellmanFord.hasNegativeCycle(g, 0), isFalse);
    });

    test('no negative cycle with negative edges but no cycle', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: -1);
      g.addEdge(1, 2, data: -2);

      expect(BellmanFord.hasNegativeCycle(g, 0), isFalse);
    });

    test('missing from node', () {
      final g = SimpleGraph<String, int>.directed();
      expect(BellmanFord.hasNegativeCycle(g, 99), isFalse);
    });
  });

  group('BellmanFord as PointToPointStrategy', () {
    test('works when no negative cycle', () {
      final g = _classicDijkstra();
      final path = const BellmanFord().find(g, 0, 5);
      expect(path!.nodes, [0, 2, 1, 3, 4, 5]);
    });

    test('throws on negative cycle', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addEdge(1, 2, data: 1);
      g.addEdge(2, 0, data: -3);

      expect(() => const BellmanFord().find(g, 0, 1), throwsStateError);
    });
  });

  // ===========================================================================
  // Floyd-Warshall
  // ===========================================================================

  group('FloydWarshall.allPairs', () {
    test('triangle graph — shortest path via intermediate', () {
      // 1→2=4, 2→3=1, 1→3=10
      // Shortest 1→3 should be 5 (via 2), not 10 (direct)
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(1, 2, data: 4);
      g.addEdge(2, 3, data: 1);
      g.addEdge(1, 3, data: 10);

      final result = FloydWarshall.allPairs(g);
      expect(result.hasNegativeCycle, isFalse);
      expect(result.distance(1, 3), 5.0);
      expect(result.distance(1, 2), 4.0);
      expect(result.distance(2, 3), 1.0);
      expect(result.distance(1, 1), 0.0);
    });

    test('all-pairs on classic graph', () {
      final g = _classicDijkstra();
      final result = FloydWarshall.allPairs(g);
      expect(result.hasNegativeCycle, isFalse);
      expect(result.distance(0, 5), 12.0);
      expect(result.distance(0, 0), 0.0);
    });

    test('negative cycle detection', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(1, 2, data: 1);
      g.addEdge(2, 1, data: -3);

      final result = FloydWarshall.allPairs(g);
      expect(result.hasNegativeCycle, isTrue);
      expect(result.distances, isNull);
    });

    test('single node', () {
      final g = SimpleGraph<String, int>.directed()..addNode(0);
      final result = FloydWarshall.allPairs(g);
      expect(result.hasNegativeCycle, isFalse);
      expect(result.distance(0, 0), 0.0);
    });

    test('empty graph', () {
      final g = SimpleGraph<String, int>.directed();
      final result = FloydWarshall.allPairs(g);
      expect(result.hasNegativeCycle, isFalse);
      expect(result.distances, isEmpty);
    });

    test('undirected graph has symmetric distances', () {
      final g = SimpleGraph<String, int>.undirected();
      g.addEdge(0, 1, data: 3);
      g.addEdge(1, 2, data: 4);

      final result = FloydWarshall.allPairs(g);
      expect(result.distance(0, 2), 7.0);
      expect(result.distance(2, 0), 7.0);
      expect(result.distance(0, 1), 3.0);
      expect(result.distance(1, 0), 3.0);
    });

    test('no path returns null distance', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addNode(2);

      final result = FloydWarshall.allPairs(g);
      expect(result.distance(0, 2), isNull);
      expect(result.distance(2, 0), isNull);
    });
  });

  // ===========================================================================
  // Johnson
  // ===========================================================================

  group('Johnson.allPairs', () {
    test('triangle graph — shortest path via intermediate', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(1, 2, data: 4);
      g.addEdge(2, 3, data: 1);
      g.addEdge(1, 3, data: 10);

      final result = Johnson.allPairs(g);
      expect(result.hasNegativeCycle, isFalse);
      expect(result.distance(1, 3), 5.0);
      expect(result.distance(1, 2), 4.0);
      expect(result.distance(2, 3), 1.0);
      expect(result.distance(1, 1), 0.0);
    });

    test('all-pairs on classic graph', () {
      final g = _classicDijkstra();
      final result = Johnson.allPairs(g);
      expect(result.hasNegativeCycle, isFalse);
      expect(result.distance(0, 5), 12.0);
      expect(result.distance(0, 0), 0.0);
    });

    test('negative edges without cycle', () {
      // 0→1=4, 0→2=3, 1→2=-2, 2→3=-3, 3→4=2
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 4);
      g.addEdge(0, 2, data: 3);
      g.addEdge(1, 2, data: -2);
      g.addEdge(2, 3, data: -3);
      g.addEdge(3, 4, data: 2);

      final result = Johnson.allPairs(g);
      expect(result.hasNegativeCycle, isFalse);
      expect(result.distance(0, 4), 1.0); // 0→1→2→3→4 = 4-2-3+2 = 1
      expect(result.distance(0, 3), -1.0); // 4-2-3 = -1
      expect(result.distance(1, 3), -5.0); // -2-3 = -5
    });

    test('negative cycle detection', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(1, 2, data: 1);
      g.addEdge(2, 1, data: -3);

      final result = Johnson.allPairs(g);
      expect(result.hasNegativeCycle, isTrue);
      expect(result.distances, isNull);
    });

    test('single node', () {
      final g = SimpleGraph<String, int>.directed()..addNode(0);
      final result = Johnson.allPairs(g);
      expect(result.hasNegativeCycle, isFalse);
      expect(result.distance(0, 0), 0.0);
    });

    test('empty graph', () {
      final g = SimpleGraph<String, int>.directed();
      final result = Johnson.allPairs(g);
      expect(result.hasNegativeCycle, isFalse);
      expect(result.distances, isEmpty);
    });

    test('undirected graph has symmetric distances', () {
      final g = SimpleGraph<String, int>.undirected();
      g.addEdge(0, 1, data: 3);
      g.addEdge(1, 2, data: 4);

      final result = Johnson.allPairs(g);
      expect(result.distance(0, 2), 7.0);
      expect(result.distance(2, 0), 7.0);
      expect(result.distance(0, 1), 3.0);
      expect(result.distance(1, 0), 3.0);
    });

    test('no path returns null distance', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addNode(2);

      final result = Johnson.allPairs(g);
      expect(result.distance(0, 2), isNull);
      expect(result.distance(2, 0), isNull);
    });

    test('matches FloydWarshall on random graph', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 5);
      g.addEdge(0, 2, data: -2);
      g.addEdge(1, 2, data: 1);
      g.addEdge(2, 3, data: 3);
      g.addEdge(1, 3, data: 4);
      g.addEdge(3, 1, data: -1);

      final johnson = Johnson.allPairs(g);
      final floyd = FloydWarshall.allPairs(g);

      expect(johnson.hasNegativeCycle, isFalse);
      expect(floyd.hasNegativeCycle, isFalse);
      expect(johnson.distances, equals(floyd.distances));
    });

    test('unreachable pair is omitted', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addEdge(2, 3, data: 1);

      final result = Johnson.allPairs(g);
      expect(result.hasNegativeCycle, isFalse);
      expect(result.distance(0, 1), 1.0);
      expect(result.distance(2, 3), 1.0);
      expect(result.distance(0, 2), isNull);
      expect(result.distance(1, 2), isNull);
    });

    test('result toString', () {
      final success = JohnsonResult.success({(0, 1): 5.0});
      final cycle = JohnsonResult.negativeCycle();

      expect(success.toString(), 'JohnsonResult(1 entries)');
      expect(cycle.toString(), 'JohnsonResult(negativeCycle)');
    });
  });

  group('Johnson.hasNegativeCycle', () {
    test('detects negative cycle', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(1, 2, data: 1);
      g.addEdge(2, 1, data: -3);

      expect(Johnson.hasNegativeCycle(g), isTrue);
    });

    test('no negative cycle in positive graph', () {
      final g = _classicDijkstra();
      expect(Johnson.hasNegativeCycle(g), isFalse);
    });

    test('no negative cycle with negative edges but no cycle', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: -1);
      g.addEdge(1, 2, data: -2);

      expect(Johnson.hasNegativeCycle(g), isFalse);
    });
  });

  // ===========================================================================
  // FloydWarshall.hasNegativeCycle
  // ===========================================================================

  group('FloydWarshall.hasNegativeCycle', () {
    test('detects negative cycle', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(1, 2, data: 1);
      g.addEdge(2, 1, data: -3);

      expect(FloydWarshall.hasNegativeCycle(g), isTrue);
    });

    test('no negative cycle in positive graph', () {
      final g = _classicDijkstra();
      expect(FloydWarshall.hasNegativeCycle(g), isFalse);
    });

    test('no negative cycle with negative edges but no cycle', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: -1);
      g.addEdge(1, 2, data: -2);

      expect(FloydWarshall.hasNegativeCycle(g), isFalse);
    });
  });

  // ===========================================================================
  // Strategy pattern — Pathfinding.shortestPath
  // ===========================================================================

  group('Pathfinding.shortestPath strategy dispatch', () {
    test('default strategy is Dijkstra', () {
      final g = _classicDijkstra();
      final path = Pathfinding.shortestPath(g, 0, 5);
      expect(path!.nodes, [0, 2, 1, 3, 4, 5]);
      expect(path.weight, 12.0);
    });

    test('explicit Dijkstra strategy', () {
      final g = _classicDijkstra();
      final path = Pathfinding.shortestPath(
        g,
        0,
        5,
        strategy: const Dijkstra(),
      );
      expect(path!.nodes, [0, 2, 1, 3, 4, 5]);
      expect(path.weight, 12.0);
    });

    test('AStar strategy with heuristic', () {
      final g = _aStarGraph();
      final h = <int, double>{0: 6, 1: 4, 2: 6, 3: 4, 4: 2, 5: 4, 6: 0};

      final path = Pathfinding.shortestPath(
        g,
        0,
        6,
        strategy: AStar(heuristic: (n, _) => h[n] ?? 0.0),
      );
      expect(path!.nodes, [0, 1, 3, 4, 6]);
      expect(path.weight, 8.0);
    });

    test('custom strategy implementation', () {
      // A trivial strategy that always returns the direct edge if it exists.
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 5);
      g.addEdge(0, 2, data: 1);
      g.addEdge(2, 1, data: 1);

      final directOnly = _DirectEdgeStrategy();
      final path = Pathfinding.shortestPath(g, 0, 1, strategy: directOnly);
      // Direct edge 0→1 exists with weight 5, so this strategy picks it.
      expect(path!.nodes, [0, 1]);
      expect(path.weight, 5.0);
    });

    test('coverage polish — BellmanFordResult and FloydWarshallResult', () {
      final successResult = BellmanFordResult.success(Path([0, 1], 10.0));
      final noPathResult = BellmanFordResult.noPath();
      final cycleResult = BellmanFordResult.negativeCycle();

      expect(successResult.isSuccess, isTrue);
      expect(noPathResult.isSuccess, isFalse);
      expect(cycleResult.isSuccess, isFalse);

      expect(successResult.toString(), contains('BellmanFordResult'));
      expect(noPathResult.toString(), 'BellmanFordResult(noPath)');
      expect(cycleResult.toString(), 'BellmanFordResult(negativeCycle)');

      final fwSuccess = FloydWarshallResult.success({(0, 1): 5.0});
      final fwCycle = FloydWarshallResult.negativeCycle();

      expect(fwSuccess.toString(), 'FloydWarshallResult(1 entries)');
      expect(fwCycle.toString(), 'FloydWarshallResult(negativeCycle)');
    });

    test('coverage polish — FloydWarshall self-loops and hasNegativeCycle', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 0, data: 5); // self-loop edge weight 5 > 0

      final result = FloydWarshall.allPairs(g);
      expect(result.distance(0, 0), 0.0); // kept the smaller 0.0 weight

      final g2 = SimpleGraph<String, int>.directed();
      g2.addEdge(
        0,
        0,
        data: -2,
      ); // self-loop edge weight -2 < 0 (negative cycle)

      final result2 = FloydWarshall.allPairs(g2);
      expect(result2.hasNegativeCycle, isTrue);

      final cycleExists = FloydWarshall.hasNegativeCycle(g2);
      expect(cycleExists, isTrue);
    });
  });
}

// =============================================================================
// Custom strategy for testing
// =============================================================================

/// A toy strategy that returns the direct edge (0→to) if it exists,
/// otherwise falls back to Dijkstra.
class _DirectEdgeStrategy implements PointToPointStrategy {
  @override
  Path? find<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    if (graph.hasEdge(from, to)) {
      return Path([from, to], graph.edgeWeight(from, to));
    }
    return const Dijkstra().find(
      graph,
      from,
      to,
      zero: zero,
      add: add,
      compare: compare,
    );
  }
}
