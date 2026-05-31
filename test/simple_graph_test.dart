import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('SimpleGraph construction', () {
    test('directed graph starts empty', () {
      final g = SimpleGraph<String, int>.directed();
      expect(g.isEmpty, isTrue);
      expect(g.nodeCount, 0);
      expect(g.edgeCount, 0);
      expect(g.hasNoEdges, isTrue);
      expect(g.kind, GraphKind.directed);
    });

    test('undirected graph starts empty', () {
      final g = SimpleGraph<String, int>.undirected();
      expect(g.isEmpty, isTrue);
      expect(g.nodeCount, 0);
      expect(g.edgeCount, 0);
      expect(g.kind, GraphKind.undirected);
    });
  });

  group('SimpleGraph node operations', () {
    test('addNode creates a node', () {
      final g = SimpleGraph<String, int>.directed();
      g.addNode('A', data: 'hello');
      expect(g.hasNode('A'), isTrue);
      expect(g.nodeData('A'), 'hello');
      expect(g.nodeCount, 1);
    });

    test('addNode without data uses null', () {
      final g = SimpleGraph<String, int>.directed();
      g.addNode('A');
      expect(g.nodeData('A'), isNull);
    });

    test('addNode overwrites existing data', () {
      final g = SimpleGraph<String, int>.directed();
      g.addNode('A', data: 'first');
      g.addNode('A', data: 'second');
      expect(g.nodeData('A'), 'second');
    });

    test('removeNode removes node and incident edges', () {
      final g = SimpleGraph<String, int>.directed()
        ..addNode('A')
        ..addNode('B')
        ..addNode('C')
        ..addEdge('A', 'B')
        ..addEdge('B', 'C')
        ..addEdge('C', 'A');

      g.removeNode('B');
      expect(g.hasNode('B'), isFalse);
      expect(g.hasEdge('A', 'B'), isFalse);
      expect(g.hasEdge('B', 'C'), isFalse);
      expect(g.nodeCount, 2);
      expect(g.edgeCount, 1); // only C->A remains
    });

    test('removeNode throws for missing node', () {
      final g = SimpleGraph<String, int>.directed();
      expect(() => g.removeNode('A'), throwsArgumentError);
    });
  });

  group('SimpleGraph edge operations — directed', () {
    test('addEdge creates edge and auto-creates nodes', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge('A', 'B', data: 42);
      expect(g.hasNode('A'), isTrue);
      expect(g.hasNode('B'), isTrue);
      expect(g.hasEdge('A', 'B'), isTrue);
      expect(g.edgeData('A', 'B'), 42);
      expect(g.edgeCount, 1);
    });

    test('addEdge without data', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge('A', 'B');
      expect(g.hasEdge('A', 'B'), isTrue);
      expect(g.edgeData('A', 'B'), isNull);
    });

    test('addEdge is idempotent for data overwrite', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge('A', 'B', data: 1);
      g.addEdge('A', 'B', data: 2);
      expect(g.edgeCount, 1);
      expect(g.edgeData('A', 'B'), 2);
    });

    test('removeEdge removes directed edge', () {
      final g = SimpleGraph<String, int>.directed()
        ..addEdge('A', 'B');
      g.removeEdge('A', 'B');
      expect(g.hasEdge('A', 'B'), isFalse);
      expect(g.edgeCount, 0);
    });

    test('removeEdge is idempotent', () {
      final g = SimpleGraph<String, int>.directed();
      g.removeEdge('A', 'B'); // no crash
      expect(g.edgeCount, 0);
    });

    test('successors and predecessors for directed', () {
      final g = SimpleGraph<String, int>.directed()
        ..addEdge('A', 'B')
        ..addEdge('A', 'C')
        ..addEdge('C', 'A');

      expect(g.successors('A'), unorderedEquals(['B', 'C']));
      expect(g.predecessors('A'), unorderedEquals(['C']));
      expect(g.successors('B'), isEmpty);
      expect(g.predecessors('B'), unorderedEquals(['A']));
    });

    test('outDegree and inDegree', () {
      final g = SimpleGraph<String, int>.directed()
        ..addEdge('A', 'B')
        ..addEdge('A', 'C')
        ..addEdge('C', 'A');

      expect(g.outDegree('A'), 2);
      expect(g.inDegree('A'), 1);
      expect(g.outDegree('B'), 0);
      expect(g.inDegree('B'), 1);
    });

    test('edgeWeight extracts numeric weight', () {
      final g = SimpleGraph<String, int>.directed()
        ..addEdge('A', 'B', data: 42);
      expect(g.edgeWeight('A', 'B'), 42.0);
    });

    test('edgeWeight defaults to 1.0 for non-numeric edge data', () {
      final g = SimpleGraph<String, String>.directed()
        ..addEdge('A', 'B', data: 'heavy');
      expect(g.edgeWeight('A', 'B'), 1.0);
    });

    test('edgeWeight throws for missing edge', () {
      final g = SimpleGraph<String, int>.directed()
        ..addNode('A')
        ..addNode('B');
      expect(() => g.edgeWeight('A', 'B'), throwsStateError);
    });
  });

  group('SimpleGraph edge operations — undirected', () {
    test('addEdge stores symmetric edges', () {
      final g = SimpleGraph<String, int>.undirected();
      g.addEdge('A', 'B', data: 10);
      expect(g.hasEdge('A', 'B'), isTrue);
      expect(g.hasEdge('B', 'A'), isTrue);
      expect(g.edgeCount, 1);
    });

    test('successors equals predecessors in undirected graph', () {
      final g = SimpleGraph<String, int>.undirected()
        ..addEdge('A', 'B')
        ..addEdge('A', 'C');

      expect(g.successors('A'), unorderedEquals(['B', 'C']));
      expect(g.predecessors('A'), unorderedEquals(['B', 'C']));
    });

    test('outDegree equals inDegree in undirected graph', () {
      final g = SimpleGraph<String, int>.undirected()
        ..addEdge('A', 'B')
        ..addEdge('A', 'C');

      expect(g.outDegree('A'), 2);
      expect(g.inDegree('A'), 2);
    });

    test('removeEdge removes both directions', () {
      final g = SimpleGraph<String, int>.undirected()
        ..addEdge('A', 'B');
      g.removeEdge('A', 'B');
      expect(g.hasEdge('A', 'B'), isFalse);
      expect(g.hasEdge('B', 'A'), isFalse);
      expect(g.edgeCount, 0);
    });
  });

  group('SimpleGraph self-loops', () {
    test('directed self-loop', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge('A', 'A');
      expect(g.hasEdge('A', 'A'), isTrue);
      expect(g.edgeCount, 1);
      expect(g.outDegree('A'), 1);
      expect(g.inDegree('A'), 1);
    });

    test('undirected self-loop counted once', () {
      final g = SimpleGraph<String, int>.undirected();
      g.addEdge('A', 'A');
      expect(g.hasEdge('A', 'A'), isTrue);
      expect(g.edgeCount, 1);
      expect(g.outDegree('A'), 1);
      expect(g.inDegree('A'), 1);
    });

    test('remove undirected self-loop', () {
      final g = SimpleGraph<String, int>.undirected()
        ..addEdge('A', 'A');
      g.removeEdge('A', 'A');
      expect(g.hasEdge('A', 'A'), isFalse);
      expect(g.edgeCount, 0);
    });
  });

  group('Interface compliance', () {
    test('SimpleGraph is Walkable', () {
      final g = SimpleGraph<String, int>.directed();
      expect(g, isA<Walkable<String, int>>());
    });

    test('SimpleGraph is WeightedWalkable', () {
      final g = SimpleGraph<String, int>.directed();
      expect(g, isA<WeightedWalkable<String, int>>());
    });

    test('SimpleGraph is Bidirectional', () {
      final g = SimpleGraph<String, int>.directed();
      expect(g, isA<Bidirectional<String, int>>());
    });

    test('SimpleGraph is Mutable', () {
      final g = SimpleGraph<String, int>.directed();
      expect(g, isA<Mutable<String, int>>());
    });

    test('SimpleGraph is Traversable', () {
      final g = SimpleGraph<String, int>.directed();
      expect(g, isA<Traversable>());
    });
  });

  group('toString', () {
    test('directed graph toString', () {
      final g = SimpleGraph<String, int>.directed()
        ..addNode('A')
        ..addNode('B')
        ..addEdge('A', 'B');
      expect(g.toString(), 'Directed SimpleGraph(2 nodes, 1 edges)');
    });

    test('undirected graph toString', () {
      final g = SimpleGraph<String, int>.undirected()
        ..addNode('A')
        ..addNode('B')
        ..addEdge('A', 'B');
      expect(g.toString(), 'Undirected SimpleGraph(2 nodes, 1 edges)');
    });
  });
}
