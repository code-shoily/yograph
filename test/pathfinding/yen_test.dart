import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('Yen.kShortestPaths', () {
    test('returns k shortest loopless paths', () {
      final g = _yenGraph();
      final paths = Yen.kShortestPaths(g, 0, 5, 3);
      expect(paths, hasLength(3));
      expect(paths[0].weight, 5.0); // 0->1->3->5
      expect(paths[1].weight, 7.0); // 0->1->2->5
      expect(paths[2].weight, 9.0); // 0->4->3->5
    });

    test('paths are ordered by non-decreasing weight', () {
      final g = _yenGraph();
      final paths = Yen.kShortestPaths(g, 0, 5, 10);
      for (var i = 1; i < paths.length; i++) {
        expect(paths[i].weight, greaterThanOrEqualTo(paths[i - 1].weight));
      }
    });

    test('all returned paths are loopless', () {
      final g = _yenGraph();
      final paths = Yen.kShortestPaths(g, 0, 5, 10);
      for (final path in paths) {
        expect(path.nodes.toSet(), hasLength(path.nodes.length));
      }
    });

    test('k=1 returns only the shortest path', () {
      final g = _yenGraph();
      final paths = Yen.kShortestPaths(g, 0, 5, 1);
      expect(paths, hasLength(1));
      expect(paths[0].weight, 5.0);
    });

    test('k larger than path count returns all distinct paths', () {
      final g = _yenGraph();
      final paths = Yen.kShortestPaths(g, 0, 5, 100);
      expect(paths, hasLength(4)); // only 4 loopless s-t paths exist
    });

    test('no path returns empty list', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addNode(2);
      expect(Yen.kShortestPaths(g, 0, 2, 5), isEmpty);
    });

    test('missing node returns empty list', () {
      final g = _yenGraph();
      expect(Yen.kShortestPaths(g, 0, 99, 5), isEmpty);
    });

    test('same source and target returns trivial path', () {
      final g = _yenGraph();
      final paths = Yen.kShortestPaths(g, 0, 0, 3);
      expect(paths, hasLength(1));
      expect(paths[0].nodes, [0]);
      expect(paths[0].weight, 0.0);
    });

    test('k <= 0 returns empty list', () {
      final g = _yenGraph();
      expect(Yen.kShortestPaths(g, 0, 5, 0), isEmpty);
      expect(Yen.kShortestPaths(g, 0, 5, -1), isEmpty);
    });

    test('handles undirected graph', () {
      final g = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1, data: 1)
        ..addEdge(1, 2, data: 1)
        ..addEdge(0, 2, data: 5);
      final paths = Yen.kShortestPaths(g, 0, 2, 2);
      expect(paths, hasLength(2));
      expect(paths[0].weight, 2.0); // 0->1->2
      expect(paths[1].weight, 5.0); // 0->2 direct
    });
  });
}

/// Graph with four loopless paths from 0 to 5.
///
///     0 --1--> 1 --2--> 2 --4--> 5
///     |        |                 ↑
///     |        └--3--> 3 --1-----┘
///     |                       |
///     └---6--> 4 --2----------┘
SimpleGraph<String, int> _yenGraph() {
  return SimpleGraph<String, int>.directed()
    ..addEdge(0, 1, data: 1)
    ..addEdge(1, 2, data: 2)
    ..addEdge(2, 5, data: 4)
    ..addEdge(1, 3, data: 3)
    ..addEdge(3, 5, data: 1)
    ..addEdge(0, 4, data: 6)
    ..addEdge(4, 3, data: 2)
    ..addEdge(4, 5, data: 8);
}
