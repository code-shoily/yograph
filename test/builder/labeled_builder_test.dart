import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('LabeledBuilder construction', () {
    test('directed builder starts empty', () {
      final builder = LabeledBuilder<String, int>.directed();
      expect(builder.nodeCount, 0);
      expect(builder.kind, GraphKind.directed);
      expect(builder.toGraph().isEmpty, isTrue);
    });

    test('undirected builder starts empty', () {
      final builder = LabeledBuilder<String, int>.undirected();
      expect(builder.nodeCount, 0);
      expect(builder.kind, GraphKind.undirected);
    });

    test('.on() wraps an existing Mutable graph', () {
      final graph = SimpleGraph<String, int>.directed();
      final builder = LabeledBuilder<String, int>.on(graph)..addEdge('A', 'B');

      expect(builder.nodeCount, 2);
      expect(identical(builder.toGraph(), graph), isTrue);
      expect(graph.edgeCount, 1);
    });
  });

  group('LabeledBuilder addNode', () {
    test('addNode assigns sequential IDs', () {
      final builder = LabeledBuilder<String, int>.directed()
        ..addNode('A')
        ..addNode('B')
        ..addNode('C');

      expect(builder.getId('A'), 0);
      expect(builder.getId('B'), 1);
      expect(builder.getId('C'), 2);
    });

    test('addNode stores label as node data', () {
      final builder = LabeledBuilder<String, int>.directed()..addNode('A');
      final graph = builder.toGraph();
      expect(graph.nodeData(0), 'A');
    });

    test('addNode is idempotent', () {
      final builder = LabeledBuilder<String, int>.directed()
        ..addNode('A')
        ..addNode('A');

      expect(builder.nodeCount, 1);
      expect(builder.getId('A'), 0);
    });
  });

  group('LabeledBuilder addEdge', () {
    test('addEdge auto-creates nodes', () {
      final builder = LabeledBuilder<String, int>.directed()
        ..addEdge('A', 'B', data: 10);

      expect(builder.nodeCount, 2);
      expect(builder.getId('A'), 0);
      expect(builder.getId('B'), 1);
    });

    test('addEdge stores edge data', () {
      final builder = LabeledBuilder<String, int>.directed()
        ..addEdge('A', 'B', data: 42);

      final graph = builder.toGraph() as SimpleGraph<String, int>;
      expect(graph.edgeData(0, 1), 42);
      expect(graph.edgeWeight(0, 1), 42.0);
    });

    test('addEdge chaining', () {
      final builder = LabeledBuilder<String, int>.directed()
        ..addEdge('A', 'B')
        ..addEdge('B', 'C')
        ..addEdge('C', 'A');

      expect(builder.nodeCount, 3);
      expect((builder.toGraph() as SimpleGraph<String, int>).edgeCount, 3);
    });

    test('addEdge without data', () {
      final builder = LabeledBuilder<String, int>.directed()..addEdge('A', 'B');

      final graph = builder.toGraph();
      expect(graph.hasEdge(0, 1), isTrue);
      expect(graph.edgeData(0, 1), isNull);
    });

    test('undirected addEdge stores symmetric edges', () {
      final builder = LabeledBuilder<String, int>.undirected()
        ..addEdge('A', 'B', data: 5);

      final graph = builder.toGraph() as SimpleGraph<String, int>;
      expect(graph.hasEdge(0, 1), isTrue);
      expect(graph.hasEdge(1, 0), isTrue);
      expect(graph.edgeCount, 1);
    });
  });

  group('LabeledBuilder ensureNode', () {
    test('returns existing ID for known label', () {
      final builder = LabeledBuilder<String, int>.directed()..addNode('A');
      expect(builder.ensureNode('A'), 0);
    });

    test('creates new ID for unknown label', () {
      final builder = LabeledBuilder<String, int>.directed();
      expect(builder.ensureNode('A'), 0);
      expect(builder.ensureNode('B'), 1);
    });
  });

  group('LabeledBuilder getId', () {
    test('returns null for unknown label', () {
      final builder = LabeledBuilder<String, int>.directed();
      expect(builder.getId('X'), isNull);
    });

    test('returns correct ID after addEdge', () {
      final builder = LabeledBuilder<String, int>.directed()
        ..addEdge('home', 'work');
      expect(builder.getId('home'), 0);
      expect(builder.getId('work'), 1);
    });
  });

  group('LabeledBuilder labels', () {
    test('iterates labels in ID order', () {
      final builder = LabeledBuilder<String, int>.directed()
        ..addNode('C')
        ..addNode('A')
        ..addNode('B');

      expect(builder.labels, ['C', 'A', 'B']);
    });
  });

  group('LabeledBuilder toGraph sharing', () {
    test('multiple calls return same mutable graph', () {
      final builder = LabeledBuilder<String, int>.directed()..addEdge('A', 'B');

      final g1 = builder.toGraph();
      final g2 = builder.toGraph();
      expect(identical(g1, g2), isTrue);
    });

    test('.on() shares the provided graph instance', () {
      final graph = SimpleGraph<String, int>.directed();
      final builder = LabeledBuilder<String, int>.on(graph);
      expect(identical(builder.toGraph(), graph), isTrue);
    });
  });

  group('LabeledBuilder round-trip workflow', () {
    test('full pathfinding workflow', () {
      final builder = LabeledBuilder<String, double>.directed()
        ..addEdge('home', 'work', data: 10.0)
        ..addEdge('work', 'gym', data: 5.0)
        ..addEdge('home', 'gym', data: 12.0);

      final graph = builder.toGraph();
      final homeId = builder.getId('home')!;
      final gymId = builder.getId('gym')!;

      // Verify we can resolve IDs
      expect(homeId, 0);
      expect(builder.getId('work'), 1);
      expect(gymId, 2);

      // Verify edge weights are correct
      expect(graph.edgeWeight(homeId, gymId), 12.0);

      // Verify we can map back to labels
      expect(graph.nodeData(homeId), 'home');
      expect(graph.nodeData(gymId), 'gym');
    });
  });

  group('LabeledBuilder with non-string labels', () {
    test('enum labels', () {
      final builder = LabeledBuilder<Color, int>.directed()
        ..addEdge(Color.red, Color.green)
        ..addEdge(Color.green, Color.blue);

      expect(builder.nodeCount, 3);
      expect(builder.getId(Color.red), 0);
      expect(builder.getId(Color.green), 1);
      expect(builder.getId(Color.blue), 2);
    });

    test('integer labels', () {
      final builder = LabeledBuilder<int, int>.directed()
        ..addEdge(100, 200)
        ..addEdge(200, 300);

      expect(builder.nodeCount, 3);
      expect(builder.getId(100), 0);
      expect(builder.getId(200), 1);
      expect(builder.getId(300), 2);
    });
  });
}

enum Color { red, green, blue }
