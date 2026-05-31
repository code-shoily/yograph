import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('MinCut Algorithms', () {
    test('stMinCut calculates correct s-t min cut with Dinic', () {
      final graph = SimpleGraph<String, double>.directed();
      graph.addEdge(1, 2, data: 10.0); // S -> A
      graph.addEdge(1, 3, data: 10.0); // S -> B
      graph.addEdge(2, 3, data: 2.0); // A -> B
      graph.addEdge(2, 4, data: 4.0); // A -> T
      graph.addEdge(3, 4, data: 10.0); // B -> T

      final cut = MinCut.stMinCut(graph, 1, 4, algorithm: 'Dinic');
      expect(cut.cutValue, equals(14.0));
      expect(cut.sourceSide, containsAll([1, 2, 3]));
      expect(cut.sinkSide, contains(4));
    });

    test('stMinCut normalizes algorithm strings correctly', () {
      final graph = SimpleGraph<String, double>.directed();
      graph.addEdge(1, 2, data: 10.0);
      graph.addEdge(2, 3, data: 10.0);

      // Edmonds-Karp variations
      final cutEK1 = MinCut.stMinCut(graph, 1, 3, algorithm: 'Edmonds-Karp');
      final cutEK2 = MinCut.stMinCut(graph, 1, 3, algorithm: 'edmonds_karp');
      final cutEK3 = MinCut.stMinCut(graph, 1, 3, algorithm: 'edmondskarp');
      expect(cutEK1.cutValue, equals(10.0));
      expect(cutEK2.cutValue, equals(10.0));
      expect(cutEK3.cutValue, equals(10.0));

      // Push-Relabel variations
      final cutPR1 = MinCut.stMinCut(graph, 1, 3, algorithm: 'Push-Relabel');
      final cutPR2 = MinCut.stMinCut(graph, 1, 3, algorithm: 'push_relabel');
      final cutPR3 = MinCut.stMinCut(graph, 1, 3, algorithm: 'pushrelabel');
      expect(cutPR1.cutValue, equals(10.0));
      expect(cutPR2.cutValue, equals(10.0));
      expect(cutPR3.cutValue, equals(10.0));
    });

    test('globalMinCut on a simple triangle', () {
      // 1 -- 2 (5)
      // |  /
      // 3 (2 on 1-3, 3 on 2-3)
      final graph = SimpleGraph<String, double>.undirected();
      graph.addEdge(1, 2, data: 5.0);
      graph.addEdge(1, 3, data: 2.0);
      graph.addEdge(2, 3, data: 3.0);

      final cut = MinCut.globalMinCut(graph);
      expect(cut.cutValue, equals(5.0)); // separating {3} from {1, 2}
      expect(
        (cut.sourceSide.contains(3) && cut.sinkSide.containsAll([1, 2])) ||
            (cut.sinkSide.contains(3) && cut.sourceSide.containsAll([1, 2])),
        isTrue,
      );
    });

    test('globalMinCut on a barbell graph with a bridge', () {
      // Triangle 1: 1-2 (10), 2-3 (10), 3-1 (10)
      // Triangle 2: 4-5 (10), 5-6 (10), 6-4 (10)
      // Bridge: 3-4 (1)
      final graph = SimpleGraph<String, double>.undirected();
      graph.addEdge(1, 2, data: 10.0);
      graph.addEdge(2, 3, data: 10.0);
      graph.addEdge(3, 1, data: 10.0);

      graph.addEdge(4, 5, data: 10.0);
      graph.addEdge(5, 6, data: 10.0);
      graph.addEdge(6, 4, data: 10.0);

      graph.addEdge(3, 4, data: 1.0); // Bridge edge

      final cut = MinCut.globalMinCut(graph);
      expect(cut.cutValue, equals(1.0)); // bridge is the global min cut

      // One side should be {1, 2, 3}, the other should be {4, 5, 6}
      final sSide = cut.sourceSide;
      final tSide = cut.sinkSide;

      expect(cut.sourceSideSize, equals(3));
      expect(cut.sinkSideSize, equals(3));

      expect(
        (sSide.containsAll([1, 2, 3]) && tSide.containsAll([4, 5, 6])) ||
            (tSide.containsAll([1, 2, 3]) && sSide.containsAll([4, 5, 6])),
        isTrue,
      );
    });

    test('globalMinCut on single node graph boundary case', () {
      final graph = SimpleGraph<String, double>.undirected();
      graph.addNode(1);

      final cut = MinCut.globalMinCut(graph);
      expect(cut.cutValue, equals(0.0));
      expect(cut.sourceSideSize, equals(1));
      expect(cut.sinkSideSize, equals(0));
    });

    test('globalMinCut throws ArgumentError for directed graph', () {
      final graph = SimpleGraph<String, double>.directed();
      graph.addEdge(1, 2, data: 5.0);

      expect(() => MinCut.globalMinCut(graph), throwsArgumentError);
    });

    test('globalMinCut throws ArgumentError for negative edge weights', () {
      final graph = SimpleGraph<String, double>.undirected();
      graph.addEdge(1, 2, data: -5.0);
      graph.addEdge(2, 3, data: 10.0);

      expect(() => MinCut.globalMinCut(graph), throwsArgumentError);
    });
  });
}
