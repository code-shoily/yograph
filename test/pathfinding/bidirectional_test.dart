import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('BidirectionalDijkstra.shortestPath', () {
    test('matches Dijkstra on classic graph', () {
      final g = _classicDijkstra();
      final bd = BidirectionalDijkstra.shortestPath(g, 0, 5);
      final dj = Dijkstra.shortestPath(g, 0, 5);
      expect(bd, isNotNull);
      expect(dj, isNotNull);
      expect(bd!.nodes, dj!.nodes);
      expect(bd.weight, dj.weight);
    });

    test('same source and target', () {
      final g = _classicDijkstra();
      final path = BidirectionalDijkstra.shortestPath(g, 0, 0);
      expect(path!.nodes, [0]);
      expect(path.weight, 0.0);
    });

    test('no path exists', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addNode(2);
      expect(BidirectionalDijkstra.shortestPath(g, 0, 2), isNull);
    });

    test('missing from node', () {
      final g = _classicDijkstra();
      expect(BidirectionalDijkstra.shortestPath(g, 99, 0), isNull);
    });

    test('missing to node', () {
      final g = _classicDijkstra();
      expect(BidirectionalDijkstra.shortestPath(g, 0, 99), isNull);
    });

    test('undirected graph', () {
      final g = SimpleGraph<String, int>.undirected();
      g.addEdge(0, 1, data: 3);
      g.addEdge(1, 2, data: 4);
      final path = BidirectionalDijkstra.shortestPath(g, 0, 2);
      expect(path!.nodes, [0, 1, 2]);
      expect(path.weight, 7.0);
    });

    test('directed graph needs backward traversal', () {
      // 0 -> 1 -> 2 -> 3, plus a longer bypass 0 -> 4 -> 3.
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addEdge(1, 2, data: 1);
      g.addEdge(2, 3, data: 1);
      g.addEdge(0, 4, data: 5);
      g.addEdge(4, 3, data: 5);
      final path = BidirectionalDijkstra.shortestPath(g, 0, 3);
      expect(path!.nodes, [0, 1, 2, 3]);
      expect(path.weight, 3.0);
    });

    test('custom semiring — max-sum path', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addEdge(0, 2, data: 5);
      g.addEdge(2, 1, data: 5);
      final path = BidirectionalDijkstra.shortestPath(
        g,
        0,
        1,
        zero: 0.0,
        add: (a, b) => a + b,
        compare: (a, b) => b.compareTo(a),
      );
      expect(path!.nodes, [0, 2, 1]);
      expect(path.weight, 10.0);
    });
  });

  group('BidirectionalBfs.shortestPath', () {
    test('finds fewest-edge path', () {
      final g = _unweightedGraph();
      final path = BidirectionalBfs.shortestPath(g, 0, 5);
      expect(path, isNotNull);
      expect(path!.length, 2); // 0 -> 2 -> 5
      expect(path.nodes, [0, 2, 5]);
      expect(path.weight, 2.0);
    });

    test('same source and target', () {
      final g = _unweightedGraph();
      final path = BidirectionalBfs.shortestPath(g, 0, 0);
      expect(path!.nodes, [0]);
      expect(path.weight, 0.0);
    });

    test('no path exists', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1);
      g.addNode(2);
      expect(BidirectionalBfs.shortestPath(g, 0, 2), isNull);
    });

    test('undirected graph', () {
      final g = SimpleGraph<String, int>.undirected();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      g.addEdge(0, 2);
      final path = BidirectionalBfs.shortestPath(g, 0, 2);
      expect(path!.nodes, [0, 2]);
      expect(path.weight, 1.0);
    });

    test('directed graph backward traversal', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      g.addEdge(2, 3);
      g.addEdge(0, 4);
      g.addEdge(4, 5);
      g.addEdge(5, 3);
      final path = BidirectionalBfs.shortestPath(g, 0, 3);
      expect(path!.nodes, [0, 1, 2, 3]);
      expect(path.weight, 3.0);
    });
  });
}

/// Classic Dijkstra graph (directed).
///
///     A --4--> B --5--> D --2--> E --2--> F
///     |        ↑         |         |         |
///     2        1         8         6         |
///     |        |         |         |         |
///     └---> C ─┘         └────┬────┘         |
///                             10              |
///                             └───────────────┘
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

/// Unweighted directed graph with multiple routes.
///
///     0 --> 1 --> 3 --> 5
///     |     |     ↑     |
///     └--> 2 --> 4 ─┘    |
///          └─────────────┘
SimpleGraph<String, Null> _unweightedGraph() {
  return SimpleGraph<String, Null>.directed()
    ..addEdge(0, 1)
    ..addEdge(0, 2)
    ..addEdge(1, 3)
    ..addEdge(2, 4)
    ..addEdge(4, 3)
    ..addEdge(3, 5)
    ..addEdge(2, 5);
}
