import 'package:test/test.dart';
import 'package:yograph/yograph.dart';
import 'package:yograph/src/internal/priority_queue.dart';

/// Classic MST test graph (undirected)
///
///     0 --4-- 1 --2-- 3
///     |       |       |
///     1       3       5
///     |       |       |
///     2 --1-- 4 --1-- 5
///
/// Optimal MST weight: 1+1+1+2+3 = 8
SimpleGraph<String, int> _classicGraph() {
  final g = SimpleGraph<String, int>.undirected();
  g.addEdge(0, 1, data: 4);
  g.addEdge(0, 2, data: 1);
  g.addEdge(1, 3, data: 2);
  g.addEdge(1, 4, data: 3);
  g.addEdge(2, 4, data: 1);
  g.addEdge(3, 5, data: 5);
  g.addEdge(4, 5, data: 1);
  return g;
}

/// Triangle graph
///   0 --1-- 1
///    \     /
///     2   3
///      \ /
///       2
SimpleGraph<String, int> _triangle() {
  final g = SimpleGraph<String, int>.undirected();
  g.addEdge(0, 1, data: 1);
  g.addEdge(0, 2, data: 2);
  g.addEdge(1, 2, data: 3);
  return g;
}

/// Disconnected graph (two components)
SimpleGraph<String, int> _disconnected() {
  final g = SimpleGraph<String, int>.undirected();
  g.addEdge(0, 1, data: 1);
  g.addEdge(2, 3, data: 2);
  return g;
}

void main() {
  group('MST.kruskal', () {
    test('classic graph', () {
      final g = _classicGraph();
      final result = MST.kruskal(g);
      expect(result.totalWeight, 8.0);
      expect(result.edgeCount, 5); // 6 nodes -> 5 edges
      expect(result.algorithm, 'kruskal');
    });

    test('triangle — picks two cheapest edges', () {
      final g = _triangle();
      final result = MST.kruskal(g);
      expect(result.totalWeight, 3.0); // 1 + 2
      expect(result.edgeCount, 2);
    });

    test('single edge', () {
      final g = SimpleGraph<String, int>.undirected()..addEdge(0, 1, data: 5);
      final result = MST.kruskal(g);
      expect(result.totalWeight, 5.0);
      expect(result.edgeCount, 1);
    });

    test('single node', () {
      final g = SimpleGraph<String, int>.undirected()..addNode(0);
      final result = MST.kruskal(g);
      expect(result.totalWeight, 0.0);
      expect(result.edgeCount, 0);
    });

    test('empty graph', () {
      final g = SimpleGraph<String, int>.undirected();
      final result = MST.kruskal(g);
      expect(result.totalWeight, 0.0);
      expect(result.edgeCount, 0);
    });

    test('disconnected graph — minimum spanning forest', () {
      final g = _disconnected();
      final result = MST.kruskal(g);
      expect(result.totalWeight, 3.0); // 1 + 2
      expect(result.edgeCount, 2);
    });

    test('throws on directed graph', () {
      final g = SimpleGraph<String, int>.directed()..addEdge(0, 1, data: 1);
      expect(() => MST.kruskal(g), throwsArgumentError);
    });
  });

  group('MST.kruskalMax', () {
    test('triangle — picks two heaviest edges', () {
      final g = _triangle();
      final result = MST.kruskalMax(g);
      expect(result.totalWeight, 5.0); // 2 + 3
      expect(result.edgeCount, 2);
      expect(result.algorithm, 'kruskal_max');
    });

    test('throws on directed graph', () {
      final g = SimpleGraph<String, int>.directed()..addEdge(0, 1, data: 1);
      expect(() => MST.kruskalMax(g), throwsArgumentError);
    });
  });

  group('MST.prim', () {
    test('classic graph', () {
      final g = _classicGraph();
      final result = MST.prim(g);
      expect(result.totalWeight, 8.0);
      expect(result.edgeCount, 5);
      expect(result.algorithm, 'prim');
    });

    test('triangle', () {
      final g = _triangle();
      final result = MST.prim(g);
      expect(result.totalWeight, 3.0);
      expect(result.edgeCount, 2);
    });

    test('from specific start node', () {
      final g = _triangle();
      final result = MST.prim(g, from: 2);
      expect(result.totalWeight, 3.0);
    });

    test('single node', () {
      final g = SimpleGraph<String, int>.undirected()..addNode(0);
      final result = MST.prim(g);
      expect(result.totalWeight, 0.0);
      expect(result.edgeCount, 0);
    });

    test('empty graph', () {
      final g = SimpleGraph<String, int>.undirected();
      final result = MST.prim(g);
      expect(result.totalWeight, 0.0);
      expect(result.edgeCount, 0);
    });

    test('invalid start node returns empty', () {
      final g = SimpleGraph<String, int>.undirected()..addNode(0);
      final result = MST.prim(g, from: 99);
      expect(result.totalWeight, 0.0);
      expect(result.edgeCount, 0);
    });

    test('throws on directed graph', () {
      final g = SimpleGraph<String, int>.directed()..addEdge(0, 1, data: 1);
      expect(() => MST.prim(g), throwsArgumentError);
    });
  });

  group('MST.primMax', () {
    test('triangle — maximum', () {
      final g = _triangle();
      final result = MST.primMax(g);
      expect(result.totalWeight, 5.0);
      expect(result.edgeCount, 2);
      expect(result.algorithm, 'prim_max');
    });

    test('empty graph', () {
      final g = SimpleGraph<String, int>.undirected();
      final result = MST.primMax(g);
      expect(result.totalWeight, 0.0);
      expect(result.edgeCount, 0);
    });

    test('invalid start node returns empty', () {
      final g = SimpleGraph<String, int>.undirected()..addNode(0);
      final result = MST.primMax(g, from: 99);
      expect(result.totalWeight, 0.0);
      expect(result.edgeCount, 0);
    });

    test('throws on directed graph', () {
      final g = SimpleGraph<String, int>.directed()..addEdge(0, 1, data: 1);
      expect(() => MST.primMax(g), throwsArgumentError);
    });
  });

  group('MST consistency — Kruskal vs Prim', () {
    test('same total weight on classic graph', () {
      final g = _classicGraph();
      final kruskalResult = MST.kruskal(g);
      final primResult = MST.prim(g);
      expect(kruskalResult.totalWeight, primResult.totalWeight);
    });

    test('same total weight on random graph', () {
      final g = SimpleGraph<String, int>.undirected();
      // Create a random-ish connected graph
      g.addEdge(0, 1, data: 3);
      g.addEdge(0, 2, data: 1);
      g.addEdge(1, 2, data: 7);
      g.addEdge(1, 3, data: 5);
      g.addEdge(2, 3, data: 2);
      g.addEdge(2, 4, data: 8);
      g.addEdge(3, 4, data: 4);

      final kruskalResult = MST.kruskal(g);
      final primResult = MST.prim(g);
      expect(kruskalResult.totalWeight, primResult.totalWeight);
    });
  });

  group('MstResult', () {
    test('edge count and total weight', () {
      final g = _triangle();
      final result = MST.kruskal(g);
      expect(result.edges.length, result.edgeCount);
      expect(
        result.totalWeight,
        result.edges.fold(0.0, (sum, e) => sum + e.weight),
      );
    });

    test('node count matches graph', () {
      final g = _classicGraph();
      final result = MST.kruskal(g);
      expect(result.nodeCount, g.nodeCount);
    });

    test('MstEdge toString', () {
      const edge = MstEdge(0, 1, 5.0);
      expect(edge.toString(), 'MstEdge(0 -> 1, weight: 5.0)');
    });
  });

  group('PriorityQueue internal', () {
    test('isEmpty, isNotEmpty, and length properties', () {
      final pq = PriorityQueue<int>((a, b) => a.compareTo(b));
      expect(pq.isEmpty, isTrue);
      expect(pq.isNotEmpty, isFalse);
      expect(pq.length, 0);

      pq.push(10);
      expect(pq.isEmpty, isFalse);
      expect(pq.isNotEmpty, isTrue);
      expect(pq.length, 1);

      pq.pop();
      expect(pq.isEmpty, isTrue);
      expect(pq.length, 0);
    });
  });
}
