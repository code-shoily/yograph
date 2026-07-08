import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

SimpleGraph<String, int> _linearDag() {
  return SimpleGraph.fromEdgesWithData([(0, 1, 2), (1, 2, 3), (2, 3, 4)]);
}

SimpleGraph<String, int> _diamondDag() {
  return SimpleGraph.fromEdgesWithData([
    (0, 1, 1),
    (0, 2, 2),
    (1, 3, 3),
    (2, 3, 1),
  ]);
}

SimpleGraph<String, int> _disconnectedDag() {
  return SimpleGraph.fromEdgesWithData([(0, 1, 1), (2, 3, 1)]);
}

SimpleGraph<String, int> _cyclicGraph() {
  return SimpleGraph.fromEdgesWithData([(0, 1, 1), (1, 2, 1), (2, 0, 1)]);
}

void main() {
  group('DAG.isDag', () {
    test('returns true for a DAG', () {
      expect(DAG.isDag(_linearDag()), isTrue);
    });

    test('returns false for a cyclic directed graph', () {
      expect(DAG.isDag(_cyclicGraph()), isFalse);
    });

    test('returns false for an undirected graph', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 1),
      ], kind: GraphKind.undirected);
      expect(DAG.isDag(g), isFalse);
    });

    test('returns true for an empty graph', () {
      expect(DAG.isDag(SimpleGraph<String, int>.directed()), isTrue);
    });
  });

  group('DAG.topologicalGenerations', () {
    test('linear chain', () {
      final result = DAG.topologicalGenerations(_linearDag())!;
      expect(result, [
        [0],
        [1],
        [2],
        [3],
      ]);
    });

    test('diamond', () {
      final result = DAG.topologicalGenerations(_diamondDag())!;
      expect(result.first, [0]);
      expect(result.last, [3]);
      expect(result[1], containsAll([1, 2]));
    });

    test('disconnected components', () {
      final result = DAG.topologicalGenerations(_disconnectedDag())!;
      expect(result.first, containsAll([0, 2]));
      expect(result.last, containsAll([1, 3]));
    });

    test('empty graph', () {
      expect(
        DAG.topologicalGenerations(SimpleGraph<String, int>.directed()),
        isEmpty,
      );
    });

    test('single node', () {
      final g = SimpleGraph<String, int>.directed()..addNode(0);
      expect(DAG.topologicalGenerations(g), [
        [0],
      ]);
    });

    test('cyclic graph returns null', () {
      expect(DAG.topologicalGenerations(_cyclicGraph()), isNull);
    });
  });

  group('DAG.longestPath', () {
    test('linear chain', () {
      final path = DAG.longestPath(_linearDag())!;
      expect(path, [0, 1, 2, 3]);
    });

    test('diamond picks the heavier path', () {
      final path = DAG.longestPath(_diamondDag())!;
      expect(path, [0, 1, 3]); // 0→1→3 = 4 vs 0→2→3 = 3
    });

    test('empty graph', () {
      expect(DAG.longestPath(SimpleGraph<String, int>.directed()), isEmpty);
    });

    test('single node', () {
      final g = SimpleGraph<String, int>.directed()..addNode(5);
      expect(DAG.longestPath(g), [5]);
    });

    test('cyclic graph returns null', () {
      expect(DAG.longestPath(_cyclicGraph()), isNull);
    });
  });

  group('DAG.longestPathNodes', () {
    test('point-to-point on diamond', () {
      final path = DAG.longestPathNodes(_diamondDag(), 0, 3)!;
      expect(path.nodes, [0, 1, 3]);
      expect(path.weight, 4.0);
    });

    test('same source and target', () {
      final path = DAG.longestPathNodes(_diamondDag(), 1, 1)!;
      expect(path.nodes, [1]);
      expect(path.weight, 0.0);
    });

    test('unreachable target', () {
      final g = SimpleGraph.fromEdgesWithData([(0, 1, 1)]);
      g.addNode(2);
      expect(DAG.longestPathNodes(g, 0, 2), isNull);
    });

    test('missing endpoint', () {
      expect(DAG.longestPathNodes(_diamondDag(), 0, 99), isNull);
    });

    test('cyclic graph returns null', () {
      expect(DAG.longestPathNodes(_cyclicGraph(), 0, 1), isNull);
    });
  });

  group('DAG.shortestPath', () {
    test('point-to-point on diamond', () {
      final path = DAG.shortestPath(_diamondDag(), 0, 3)!;
      expect(path.nodes, [0, 2, 3]); // 0→2→3 = 3 vs 0→1→3 = 4
      expect(path.weight, 3.0);
    });

    test('same source and target', () {
      final path = DAG.shortestPath(_diamondDag(), 1, 1)!;
      expect(path.nodes, [1]);
      expect(path.weight, 0.0);
    });

    test('negative edges are valid in a DAG', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 1, 4),
        (0, 2, 3),
        (1, 2, -2),
        (2, 3, -3),
        (3, 4, 2),
      ]);
      final path = DAG.shortestPath(g, 0, 4)!;
      expect(path.nodes, [0, 1, 2, 3, 4]);
      expect(path.weight, 1.0);
    });

    test('unreachable target', () {
      final g = SimpleGraph.fromEdgesWithData([(0, 1, 1)]);
      g.addNode(2);
      expect(DAG.shortestPath(g, 0, 2), isNull);
    });

    test('cyclic graph returns null', () {
      expect(DAG.shortestPath(_cyclicGraph(), 0, 1), isNull);
    });
  });

  group('DAG.singleSourceDistances', () {
    test('from source on diamond', () {
      final dists = DAG.singleSourceDistances(_diamondDag(), 0);
      expect(dists[0], 0.0);
      expect(dists[1], 1.0);
      expect(dists[2], 2.0);
      expect(dists[3], 3.0); // 0→2→3
    });

    test('missing source', () {
      expect(DAG.singleSourceDistances(_diamondDag(), 99), isEmpty);
    });

    test('cyclic graph returns empty map', () {
      expect(DAG.singleSourceDistances(_cyclicGraph(), 0), isEmpty);
    });
  });

  group('DAG.sources and DAG.sinks', () {
    test('sources of diamond', () {
      expect(DAG.sources(_diamondDag()), [0]);
    });

    test('sinks of diamond', () {
      expect(DAG.sinks(_diamondDag()), [3]);
    });

    test('sources and sinks of disconnected DAG', () {
      expect(DAG.sources(_disconnectedDag()), [0, 2]);
      expect(DAG.sinks(_disconnectedDag()), [1, 3]);
    });

    test('cyclic graph returns null', () {
      expect(DAG.sources(_cyclicGraph()), isNull);
      expect(DAG.sinks(_cyclicGraph()), isNull);
    });
  });

  group('DAG.ancestors and DAG.descendants', () {
    test('ancestors in diamond', () {
      expect(DAG.ancestors(_diamondDag(), 3), containsAll([0, 1, 2, 3]));
    });

    test('descendants in diamond', () {
      expect(DAG.descendants(_diamondDag(), 0), containsAll([0, 1, 2, 3]));
    });

    test('missing node returns null', () {
      expect(DAG.ancestors(_diamondDag(), 99), isNull);
      expect(DAG.descendants(_diamondDag(), 99), isNull);
    });

    test('cyclic graph returns null', () {
      expect(DAG.ancestors(_cyclicGraph(), 0), isNull);
      expect(DAG.descendants(_cyclicGraph(), 0), isNull);
    });
  });

  group('DAG.lowestCommonAncestors', () {
    test('diamond LCA of two branches', () {
      expect(DAG.lowestCommonAncestors(_diamondDag(), 1, 2), [0]);
    });

    test('same node is its own LCA', () {
      expect(DAG.lowestCommonAncestors(_diamondDag(), 1, 1), [1]);
    });

    test('multiple LCAs', () {
      final g = SimpleGraph.fromEdgesWithData([
        (0, 4, 1),
        (1, 4, 1),
        (0, 5, 1),
        (1, 5, 1),
      ]);
      expect(DAG.lowestCommonAncestors(g, 4, 5), containsAll([0, 1]));
    });

    test('missing node returns null', () {
      expect(DAG.lowestCommonAncestors(_diamondDag(), 1, 99), isNull);
    });

    test('cyclic graph returns null', () {
      expect(DAG.lowestCommonAncestors(_cyclicGraph(), 0, 1), isNull);
    });
  });

  group('DAG.pathCount', () {
    test('single path', () {
      expect(DAG.pathCount(_linearDag(), 0, 3), 1);
    });

    test('two paths in diamond', () {
      expect(DAG.pathCount(_diamondDag(), 0, 3), 2);
    });

    test('same source and target', () {
      expect(DAG.pathCount(_diamondDag(), 1, 1), 1);
    });

    test('unreachable target', () {
      final g = SimpleGraph.fromEdgesWithData([(0, 1, 1)]);
      g.addNode(2);
      expect(DAG.pathCount(g, 0, 2), 0);
    });

    test('missing endpoint', () {
      expect(DAG.pathCount(_diamondDag(), 0, 99), 0);
    });

    test('cyclic graph returns 0', () {
      expect(DAG.pathCount(_cyclicGraph(), 0, 1), 0);
    });
  });
}
