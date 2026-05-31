import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('MutableBulkCreationX Extension Methods', () {
    test('addNodesFrom adds multiple nodes at once', () {
      final graph = SimpleGraph<String, int>.directed();
      graph.addNodesFrom([1, 2, 3, 5]);

      expect(graph.nodeCount, 4);
      expect(graph.hasNode(1), isTrue);
      expect(graph.hasNode(2), isTrue);
      expect(graph.hasNode(3), isTrue);
      expect(graph.hasNode(5), isTrue);
      expect(graph.hasNode(4), isFalse);
    });

    test(
      'addEdgesFrom adds multiple unweighted edges and auto-creates nodes',
      () {
        final graph = SimpleGraph<void, void>.directed();
        graph.addEdgesFrom([(1, 2), (2, 3), (3, 4)]);

        expect(graph.nodeCount, 4);
        expect(graph.edgeCount, 3);
        expect(graph.hasEdge(1, 2), isTrue);
        expect(graph.hasEdge(2, 3), isTrue);
        expect(graph.hasEdge(3, 4), isTrue);
        expect(graph.hasEdge(2, 1), isFalse); // directed
      },
    );

    test('addEdgesWithDataFrom adds multiple weighted edges', () {
      final graph = SimpleGraph<String, double>.directed();
      graph.addEdgesWithDataFrom([
        (1, 2, 10.5),
        (2, 3, 5.0),
        (3, 4, null), // unweighted default
      ]);

      expect(graph.nodeCount, 4);
      expect(graph.edgeCount, 3);
      expect(graph.edgeData(1, 2), 10.5);
      expect(graph.edgeWeight(1, 2), 10.5);
      expect(graph.edgeData(2, 3), 5.0);
      expect(graph.edgeWeight(2, 3), 5.0);
      expect(graph.edgeData(3, 4), isNull);
      expect(graph.edgeWeight(3, 4), 1.0);
    });
  });

  group('SimpleGraph Factory Constructors', () {
    test('SimpleGraph.fromEdges creates a directed graph', () {
      final graph = SimpleGraph<void, void>.fromEdges([(1, 2), (2, 3), (3, 1)]);

      expect(graph.kind, GraphKind.directed);
      expect(graph.nodeCount, 3);
      expect(graph.edgeCount, 3);
      expect(graph.hasEdge(1, 2), isTrue);
      expect(graph.hasEdge(2, 1), isFalse);
    });

    test('SimpleGraph.fromEdges creates an undirected graph', () {
      final graph = SimpleGraph<void, void>.fromEdges([
        (1, 2),
        (2, 3),
      ], kind: GraphKind.undirected);

      expect(graph.kind, GraphKind.undirected);
      expect(graph.nodeCount, 3);
      expect(graph.edgeCount, 2);
      expect(graph.hasEdge(1, 2), isTrue);
      expect(graph.hasEdge(2, 1), isTrue); // undirected symmetry
    });

    test('SimpleGraph.fromEdgesWithData creates a weighted graph', () {
      final graph = SimpleGraph<void, double>.fromEdgesWithData([
        (1, 2, 4.2),
        (2, 3, 1.8),
      ]);

      expect(graph.kind, GraphKind.directed);
      expect(graph.nodeCount, 3);
      expect(graph.edgeCount, 2);
      expect(graph.edgeData(1, 2), 4.2);
      expect(graph.edgeWeight(2, 3), 1.8);
    });
  });
}
