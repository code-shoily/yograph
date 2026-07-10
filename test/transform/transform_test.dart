import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('Transform.transitiveClosure', () {
    test('empty graph', () {
      final g = SimpleGraph<String, int>.directed();
      expect(Transform.transitiveClosure(g), isEmpty);
    });

    test('linear chain DAG', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (1, 2, 1),
        (2, 3, 1),
      ]);
      final closure = Transform.transitiveClosure(g);
      expect(closure[0], containsAll([0, 1, 2, 3]));
      expect(closure[1], containsAll([1, 2, 3]));
      expect(closure[2], containsAll([2, 3]));
      expect(closure[3], containsAll([3]));
    });

    test('diamond DAG', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (0, 2, 1),
        (1, 3, 1),
        (2, 3, 1),
      ]);
      final closure = Transform.transitiveClosure(g);
      expect(closure[0], containsAll([0, 1, 2, 3]));
      expect(closure[1], containsAll([1, 3]));
      expect(closure[2], containsAll([2, 3]));
      expect(closure[3], containsAll([3]));
    });

    test('DAG with shortcut edge', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (1, 2, 1),
        (0, 2, 1),
      ]);
      final closure = Transform.transitiveClosure(g);
      expect(closure[0], containsAll([0, 1, 2]));
    });

    test('cyclic graph falls back to BFS', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (1, 2, 1),
        (2, 0, 1),
        (2, 3, 1),
      ]);
      final closure = Transform.transitiveClosure(g);
      expect(closure[0], containsAll([0, 1, 2, 3]));
      expect(closure[3], containsAll([3]));
    });

    test('undirected graph treated as general', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (1, 2, 1),
      ], kind: GraphKind.undirected);
      final closure = Transform.transitiveClosure(g);
      expect(closure[0], containsAll([0, 1, 2]));
      expect(closure[2], containsAll([0, 1, 2]));
    });
  });

  group('Transform.transitiveReduction', () {
    test('returns null for cyclic graph', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (1, 2, 1),
        (2, 0, 1),
      ]);
      expect(Transform.transitiveReduction(g), isNull);
    });

    test('returns null for undirected graph', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (1, 2, 1),
      ], kind: GraphKind.undirected);
      expect(Transform.transitiveReduction(g), isNull);
    });

    test('linear chain is unchanged', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 10),
        (1, 2, 20),
        (2, 3, 30),
      ]);
      final reduced = Transform.transitiveReduction(g)!;
      expect(reduced.edgeCount, 3);
      expect(reduced.hasEdge(0, 1), isTrue);
      expect(reduced.hasEdge(1, 2), isTrue);
      expect(reduced.hasEdge(2, 3), isTrue);
      expect(reduced.edgeData(0, 1), 10);
      expect(reduced.edgeData(1, 2), 20);
      expect(reduced.edgeData(2, 3), 30);
    });

    test('diamond keeps both incoming edges to sink', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (0, 2, 1),
        (1, 3, 1),
        (2, 3, 1),
      ]);
      final reduced = Transform.transitiveReduction(g)!;
      expect(reduced.edgeCount, 4);
    });

    test('removes shortcut edge', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (1, 2, 1),
        (0, 2, 1),
      ]);
      final reduced = Transform.transitiveReduction(g)!;
      expect(reduced.edgeCount, 2);
      expect(reduced.hasEdge(0, 1), isTrue);
      expect(reduced.hasEdge(1, 2), isTrue);
      expect(reduced.hasEdge(0, 2), isFalse);
    });

    test('removes redundant edge in multi-hop graph', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (1, 2, 1),
        (2, 3, 1),
        (0, 3, 1),
      ]);
      final reduced = Transform.transitiveReduction(g)!;
      expect(reduced.edgeCount, 3);
      expect(reduced.hasEdge(0, 3), isFalse);
    });

    test('empty graph', () {
      final g = SimpleGraph<String, int>.directed();
      final reduced = Transform.transitiveReduction(g)!;
      expect(reduced.nodeCount, 0);
      expect(reduced.edgeCount, 0);
    });

    test('reduction preserves reachability', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
        (1, 2, 1),
        (2, 3, 1),
        (0, 2, 1),
        (0, 3, 1),
        (1, 3, 1),
      ]);
      final originalClosure = Transform.transitiveClosure(g);
      final reduced = Transform.transitiveReduction(g)!;
      final reducedClosure = Transform.transitiveClosure(
        reduced as Bidirectional,
      );

      for (final u in g.nodeIds) {
        expect(reducedClosure[u], equals(originalClosure[u]));
      }
    });
  });
}
