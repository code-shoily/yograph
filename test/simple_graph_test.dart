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
      g.addNode(0, data: 'hello');
      expect(g.hasNode(0), isTrue);
      expect(g.nodeData(0), 'hello');
      expect(g.nodeCount, 1);
    });

    test('addNode without data uses null', () {
      final g = SimpleGraph<String, int>.directed();
      g.addNode(0);
      expect(g.nodeData(0), isNull);
    });

    test('addNode overwrites existing data', () {
      final g = SimpleGraph<String, int>.directed();
      g.addNode(0, data: 'first');
      g.addNode(0, data: 'second');
      expect(g.nodeData(0), 'second');
    });

    test('removeNode removes node and incident edges', () {
      final g = SimpleGraph<String, int>.directed()
        ..addNode(0)
        ..addNode(1)
        ..addNode(2)
        ..addEdge(0, 1)
        ..addEdge(1, 2)
        ..addEdge(2, 0);

      g.removeNode(1);
      expect(g.hasNode(1), isFalse);
      expect(g.hasEdge(0, 1), isFalse);
      expect(g.hasEdge(1, 2), isFalse);
      expect(g.nodeCount, 2);
      expect(g.edgeCount, 1); // only 2->0 remains
    });

    test('removeNode throws for missing node', () {
      final g = SimpleGraph<String, int>.directed();
      expect(() => g.removeNode(0), throwsArgumentError);
    });

    test('removeNode on isolated node', () {
      final g = SimpleGraph<String, int>.directed()
        ..addNode(0)
        ..addNode(1);
      g.removeNode(0);
      expect(g.hasNode(0), isFalse);
      expect(g.hasNode(1), isTrue);
      expect(g.nodeCount, 1);
    });

    test('removeNode on last node leaves empty graph', () {
      final g = SimpleGraph<String, int>.directed()..addNode(0);
      g.removeNode(0);
      expect(g.isEmpty, isTrue);
      expect(g.nodeCount, 0);
    });

    test('removeNode with self-loop only', () {
      final g = SimpleGraph<String, int>.directed()
        ..addNode(0)
        ..addEdge(0, 0);
      g.removeNode(0);
      expect(g.edgeCount, 0);
      expect(g.isEmpty, isTrue);
    });
  });

  group('SimpleGraph edge operations — directed', () {
    test('addEdge creates edge and auto-creates nodes', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 42);
      expect(g.hasNode(0), isTrue);
      expect(g.hasNode(1), isTrue);
      expect(g.hasEdge(0, 1), isTrue);
      expect(g.edgeData(0, 1), 42);
      expect(g.edgeCount, 1);
    });

    test('addEdge without data', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1);
      expect(g.hasEdge(0, 1), isTrue);
      expect(g.edgeData(0, 1), isNull);
    });

    test('addEdge is idempotent for data overwrite', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1, data: 1);
      g.addEdge(0, 1, data: 2);
      expect(g.edgeCount, 1);
      expect(g.edgeData(0, 1), 2);
    });

    test('addEdge overwrites with null data', () {
      final g = SimpleGraph<String, int>.directed()..addEdge(0, 1, data: 5);
      g.addEdge(0, 1);
      expect(g.edgeData(0, 1), isNull);
    });

    test('removeEdge removes directed edge', () {
      final g = SimpleGraph<String, int>.directed()..addEdge(0, 1);
      g.removeEdge(0, 1);
      expect(g.hasEdge(0, 1), isFalse);
      expect(g.edgeCount, 0);
    });

    test('removeEdge is idempotent', () {
      final g = SimpleGraph<String, int>.directed();
      g.removeEdge(0, 1); // no crash
      expect(g.edgeCount, 0);
    });

    test('successors and predecessors for directed', () {
      final g = SimpleGraph<String, int>.directed()
        ..addEdge(0, 1)
        ..addEdge(0, 2)
        ..addEdge(2, 0);

      expect(g.successors(0), unorderedEquals([1, 2]));
      expect(g.predecessors(0), unorderedEquals([2]));
      expect(g.successors(1), isEmpty);
      expect(g.predecessors(1), unorderedEquals([0]));
    });

    test('outDegree and inDegree', () {
      final g = SimpleGraph<String, int>.directed()
        ..addEdge(0, 1)
        ..addEdge(0, 2)
        ..addEdge(2, 0);

      expect(g.outDegree(0), 2);
      expect(g.inDegree(0), 1);
      expect(g.outDegree(1), 0);
      expect(g.inDegree(1), 1);
    });

    test('edgeWeight extracts numeric weight (int)', () {
      final g = SimpleGraph<String, int>.directed()..addEdge(0, 1, data: 42);
      expect(g.edgeWeight(0, 1), 42.0);
    });

    test('edgeWeight extracts numeric weight (double)', () {
      final g = SimpleGraph<String, double>.directed()
        ..addEdge(0, 1, data: 3.14);
      expect(g.edgeWeight(0, 1), 3.14);
    });

    test('edgeWeight defaults to 1.0 for non-numeric edge data', () {
      final g = SimpleGraph<String, String>.directed()
        ..addEdge(0, 1, data: 'heavy');
      expect(g.edgeWeight(0, 1), 1.0);
    });

    test('edgeWeight throws for missing edge', () {
      final g = SimpleGraph<String, int>.directed()
        ..addNode(0)
        ..addNode(1);
      expect(() => g.edgeWeight(0, 1), throwsStateError);
    });

    test('multiple edges from same source', () {
      final g = SimpleGraph<String, int>.directed()
        ..addEdge(0, 1)
        ..addEdge(0, 2)
        ..addEdge(0, 3);
      expect(g.outDegree(0), 3);
      expect(g.edgeCount, 3);
      expect(g.successors(0), unorderedEquals([1, 2, 3]));
    });

    test('queries on non-existent node return empty', () {
      final g = SimpleGraph<String, int>.directed();
      expect(g.successors(99), isEmpty);
      expect(g.predecessors(99), isEmpty);
      expect(g.outDegree(99), 0);
      expect(g.inDegree(99), 0);
      expect(g.hasNode(99), isFalse);
      expect(g.nodeData(99), isNull);
    });

    test('degree equals outDegree for directed', () {
      final g = SimpleGraph<String, int>.directed()
        ..addEdge(0, 1)
        ..addEdge(0, 2);
      expect(g.degree(0), g.outDegree(0));
    });

    test('neighbors equals successors for directed', () {
      final g = SimpleGraph<String, int>.directed()
        ..addEdge(0, 1)
        ..addEdge(0, 2);
      expect(g.neighbors(0), unorderedEquals(g.successors(0).toList()));
    });
  });

  group('SimpleGraph edge operations — undirected', () {
    test('addEdge stores symmetric edges', () {
      final g = SimpleGraph<String, int>.undirected();
      g.addEdge(0, 1, data: 10);
      expect(g.hasEdge(0, 1), isTrue);
      expect(g.hasEdge(1, 0), isTrue);
      expect(g.edgeCount, 1);
    });

    test('addEdge is idempotent for undirected', () {
      final g = SimpleGraph<String, int>.undirected();
      g.addEdge(0, 1, data: 1);
      g.addEdge(0, 1, data: 2);
      expect(g.edgeCount, 1);
      expect(g.edgeData(0, 1), 2);
      expect(g.edgeData(1, 0), 2);
    });

    test('successors equals predecessors in undirected graph', () {
      final g = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1)
        ..addEdge(0, 2);

      expect(g.successors(0), unorderedEquals([1, 2]));
      expect(g.predecessors(0), unorderedEquals([1, 2]));
    });

    test('outDegree equals inDegree in undirected graph', () {
      final g = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1)
        ..addEdge(0, 2);

      expect(g.outDegree(0), 2);
      expect(g.inDegree(0), 2);
    });

    test('removeEdge removes both directions', () {
      final g = SimpleGraph<String, int>.undirected()..addEdge(0, 1);
      g.removeEdge(0, 1);
      expect(g.hasEdge(0, 1), isFalse);
      expect(g.hasEdge(1, 0), isFalse);
      expect(g.edgeCount, 0);
    });

    test('removeNode cascades correctly in undirected graph', () {
      final g = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1)
        ..addEdge(1, 2)
        ..addEdge(2, 0);
      g.removeNode(1);
      expect(g.edgeCount, 1); // only 0-2 remains
      expect(g.hasEdge(0, 2), isTrue);
      expect(g.hasEdge(2, 0), isTrue);
    });

    test('degree equals outDegree for undirected', () {
      final g = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1)
        ..addEdge(0, 2);
      expect(g.degree(0), g.outDegree(0));
    });
  });

  group('SimpleGraph self-loops', () {
    test('directed self-loop', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 0);
      expect(g.hasEdge(0, 0), isTrue);
      expect(g.edgeCount, 1);
      expect(g.outDegree(0), 1);
      expect(g.inDegree(0), 1);
    });

    test('undirected self-loop counted once', () {
      final g = SimpleGraph<String, int>.undirected();
      g.addEdge(0, 0);
      expect(g.hasEdge(0, 0), isTrue);
      expect(g.edgeCount, 1);
      expect(g.outDegree(0), 1);
      expect(g.inDegree(0), 1);
    });

    test('remove undirected self-loop', () {
      final g = SimpleGraph<String, int>.undirected()..addEdge(0, 0);
      g.removeEdge(0, 0);
      expect(g.hasEdge(0, 0), isFalse);
      expect(g.edgeCount, 0);
    });

    test('directed self-loop removeNode cleans up', () {
      final g = SimpleGraph<String, int>.directed()
        ..addEdge(0, 0)
        ..addEdge(0, 1);
      g.removeNode(0);
      expect(g.edgeCount, 0);
      expect(g.hasNode(1), isTrue);
      expect(g.hasNode(0), isFalse);
    });
  });

  group('SimpleGraph invariants', () {
    test('sum of out-degrees equals edgeCount for directed', () {
      final g = SimpleGraph<String, int>.directed()
        ..addEdge(0, 1)
        ..addEdge(0, 2)
        ..addEdge(1, 2)
        ..addEdge(2, 0);

      var sum = 0;
      for (final id in g.nodeIds) {
        sum += g.outDegree(id);
      }
      expect(sum, g.edgeCount);
    });

    test(
      'sum of out-degrees equals 2*edgeCount for undirected (no self-loops)',
      () {
        final g = SimpleGraph<String, int>.undirected()
          ..addEdge(0, 1)
          ..addEdge(1, 2)
          ..addEdge(2, 0);

        var sum = 0;
        for (final id in g.nodeIds) {
          sum += g.outDegree(id);
        }
        expect(sum, g.edgeCount * 2);
      },
    );

    test('edgeCount is consistent after add/remove sequence', () {
      final g = SimpleGraph<String, int>.directed();
      g.addEdge(0, 1);
      expect(g.edgeCount, 1);
      g.addEdge(1, 2);
      expect(g.edgeCount, 2);
      g.removeEdge(0, 1);
      expect(g.edgeCount, 1);
      g.removeEdge(0, 1); // idempotent
      expect(g.edgeCount, 1);
      g.removeNode(1);
      expect(g.edgeCount, 0);
    });

    test('nodeCount is consistent after add/remove sequence', () {
      final g = SimpleGraph<String, int>.directed();
      expect(g.nodeCount, 0);
      g.addNode(0);
      expect(g.nodeCount, 1);
      g.addNode(1);
      expect(g.nodeCount, 2);
      g.removeNode(0);
      expect(g.nodeCount, 1);
      g.removeNode(1);
      expect(g.nodeCount, 0);
    });
  });

  group('SimpleGraph complex structures', () {
    test('star graph', () {
      final g = SimpleGraph<String, int>.undirected();
      const center = 0;
      for (var i = 1; i <= 5; i++) {
        g.addEdge(center, i);
      }
      expect(g.nodeCount, 6);
      expect(g.edgeCount, 5);
      expect(g.degree(center), 5);
      for (var i = 1; i <= 5; i++) {
        expect(g.degree(i), 1);
      }
    });

    test('complete graph K4', () {
      final g = SimpleGraph<String, int>.undirected();
      const nodes = [0, 1, 2, 3];
      for (var i = 0; i < nodes.length; i++) {
        for (var j = i + 1; j < nodes.length; j++) {
          g.addEdge(nodes[i], nodes[j]);
        }
      }
      expect(g.nodeCount, 4);
      expect(g.edgeCount, 6); // C(4,2)
      for (final n in nodes) {
        expect(g.degree(n), 3);
      }
    });

    test('directed cycle', () {
      final g = SimpleGraph<String, int>.directed();
      const nodes = [0, 1, 2, 3, 4];
      for (var i = 0; i < nodes.length; i++) {
        final from = nodes[i];
        final to = nodes[(i + 1) % nodes.length];
        g.addEdge(from, to);
      }
      expect(g.nodeCount, 5);
      expect(g.edgeCount, 5);
      for (final n in nodes) {
        expect(g.outDegree(n), 1);
        expect(g.inDegree(n), 1);
      }
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
        ..addNode(0)
        ..addNode(1)
        ..addEdge(0, 1);
      expect(g.toString(), 'Directed SimpleGraph(2 nodes, 1 edges)');
    });

    test('undirected graph toString', () {
      final g = SimpleGraph<String, int>.undirected()
        ..addNode(0)
        ..addNode(1)
        ..addEdge(0, 1);
      expect(g.toString(), 'Undirected SimpleGraph(2 nodes, 1 edges)');
    });

    test('empty graph toString', () {
      final g = SimpleGraph<String, int>.directed();
      expect(g.toString(), 'Directed SimpleGraph(0 nodes, 0 edges)');
    });
  });

  group('GraphKind enum', () {
    test('values', () {
      expect(GraphKind.values, [GraphKind.directed, GraphKind.undirected]);
    });

    test('directed kind on graph', () {
      final g = SimpleGraph<String, int>.directed();
      expect(g.kind, GraphKind.directed);
    });

    test('undirected kind on graph', () {
      final g = SimpleGraph<String, int>.undirected();
      expect(g.kind, GraphKind.undirected);
    });
  });
}
