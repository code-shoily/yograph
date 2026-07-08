import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('CommunityResult', () {
    test('empty result', () {
      final result = CommunityResult({});
      expect(result.numCommunities, 0);
      expect(result.assignments, isEmpty);
    });

    test('basic result', () {
      final result = CommunityResult({0: 0, 1: 0, 2: 1});
      expect(result.numCommunities, 2);
      expect(result.assignments, {0: 0, 1: 0, 2: 1});
    });

    test('metadata', () {
      final result = CommunityResult({0: 0}, metadata: {'algo': 'lpa'});
      expect(result.metadata['algo'], 'lpa');
    });

    test('equality', () {
      final a = CommunityResult({0: 0, 1: 1});
      final b = CommunityResult({0: 0, 1: 1});
      final c = CommunityResult({0: 0, 1: 0});
      expect(a == b, isTrue);
      expect(a == c, isFalse);
    });
  });

  group('CommunityDendrogram', () {
    test('empty dendrogram', () {
      final dend = CommunityDendrogram([]);
      expect(dend.numLevels, 0);
      expect(dend.finest.numCommunities, 0);
      expect(dend.coarsest.numCommunities, 0);
      expect(dend.atLevel(1), isNull);
    });

    test('basic dendrogram', () {
      final l1 = CommunityResult({0: 0, 1: 0, 2: 1, 3: 1});
      final l2 = CommunityResult({0: 0, 1: 0, 2: 0, 3: 0});
      final dend = CommunityDendrogram([l1, l2]);
      expect(dend.numLevels, 2);
      expect(dend.finest.numCommunities, 2);
      expect(dend.coarsest.numCommunities, 1);
      expect(dend.atLevel(1), l2);
      expect(dend.getLevel(0), l1);
    });

    test('flattenToOriginal composes levels', () {
      final l1 = CommunityResult({0: 0, 1: 1});
      final l2 = CommunityResult({0: 5, 1: 5});
      final dend = CommunityDendrogram([l1, l2]);
      final flat = dend.flattenToOriginal();
      expect(flat.assignments, {0: 5, 1: 5});
    });
  });

  group('CommunityMetrics.modularity', () {
    test('single edge in one community', () {
      final graph = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1, data: 1);
      final result = CommunityResult({0: 0, 1: 0});
      final q = CommunityMetrics.modularity(graph, result);
      expect(q, isZero);
    });

    test('two isolated edges', () {
      final graph = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1, data: 1)
        ..addEdge(2, 3, data: 1);
      final result = CommunityResult({0: 0, 1: 0, 2: 1, 3: 1});
      final q = CommunityMetrics.modularity(graph, result);
      expect(q, greaterThan(0.3));
    });

    test('two cliques with bridge', () {
      final graph = _twoCliquesWithBridge();
      final result = CommunityResult({0: 0, 1: 0, 2: 0, 3: 1, 4: 1, 5: 1});
      final q = CommunityMetrics.modularity(graph, result);
      expect(q, greaterThan(0.3));
    });

    test('empty graph', () {
      final graph = SimpleGraph<String, int>.undirected();
      final result = CommunityResult({});
      expect(CommunityMetrics.modularity(graph, result), 0.0);
    });

    test('resolution parameter changes value', () {
      final graph = _twoCliquesWithBridge();
      final result = CommunityResult({0: 0, 1: 0, 2: 0, 3: 1, 4: 1, 5: 1});
      final q1 = CommunityMetrics.modularity(graph, result, resolution: 1.0);
      final q2 = CommunityMetrics.modularity(graph, result, resolution: 0.5);
      expect(q2, greaterThan(q1));
    });
  });

  group('CommunityMetrics triangles', () {
    test('single triangle', () {
      final graph = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1)
        ..addEdge(1, 2)
        ..addEdge(2, 0);
      expect(CommunityMetrics.countTriangles(graph), 1);
      expect(CommunityMetrics.trianglesPerNode(graph), {0: 1, 1: 1, 2: 1});
    });

    test('square has no triangles', () {
      final graph = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1)
        ..addEdge(1, 2)
        ..addEdge(2, 3)
        ..addEdge(3, 0);
      expect(CommunityMetrics.countTriangles(graph), 0);
    });

    test('kite graph', () {
      final graph = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1)
        ..addEdge(0, 2)
        ..addEdge(1, 2)
        ..addEdge(1, 3)
        ..addEdge(2, 3);
      expect(CommunityMetrics.countTriangles(graph), 2);
    });

    test('empty graph', () {
      final graph = SimpleGraph<String, int>.undirected();
      expect(CommunityMetrics.countTriangles(graph), 0);
      expect(CommunityMetrics.trianglesPerNode(graph), isEmpty);
    });
  });

  group('CommunityMetrics clustering coefficient', () {
    test('triangle node', () {
      final graph = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1)
        ..addEdge(1, 2)
        ..addEdge(2, 0);
      expect(CommunityMetrics.clusteringCoefficient(graph, 0), 1.0);
    });

    test('star center', () {
      final graph = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1)
        ..addEdge(0, 2)
        ..addEdge(0, 3);
      expect(CommunityMetrics.clusteringCoefficient(graph, 0), 0.0);
    });

    test('node with single neighbor', () {
      final graph = SimpleGraph<String, int>.undirected()..addEdge(0, 1);
      expect(CommunityMetrics.clusteringCoefficient(graph, 0), 0.0);
    });

    test('average clustering coefficient', () {
      final graph = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1)
        ..addEdge(1, 2)
        ..addEdge(2, 0);
      expect(CommunityMetrics.averageClusteringCoefficient(graph), 1.0);
    });

    test('empty graph average', () {
      final graph = SimpleGraph<String, int>.undirected();
      expect(CommunityMetrics.averageClusteringCoefficient(graph), 0.0);
    });
  });

  group('CommunityMetrics transitivity', () {
    test('triangle', () {
      final graph = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1)
        ..addEdge(1, 2)
        ..addEdge(2, 0);
      expect(CommunityMetrics.transitivity(graph), 1.0);
    });

    test('square', () {
      final graph = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1)
        ..addEdge(1, 2)
        ..addEdge(2, 3)
        ..addEdge(3, 0);
      expect(CommunityMetrics.transitivity(graph), 0.0);
    });

    test('star', () {
      final graph = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1)
        ..addEdge(0, 2)
        ..addEdge(0, 3);
      expect(CommunityMetrics.transitivity(graph), 0.0);
    });
  });

  group('CommunityMetrics density', () {
    test('complete graph K4', () {
      final graph = _completeGraph(4);
      expect(CommunityMetrics.density(graph), 1.0);
    });

    test('empty graph', () {
      final graph = SimpleGraph<String, int>.undirected();
      expect(CommunityMetrics.density(graph), 0.0);
    });

    test('single node', () {
      final graph = SimpleGraph<String, int>.undirected()..addNode(0);
      expect(CommunityMetrics.density(graph), 0.0);
    });

    test('community density', () {
      final graph = _twoCliquesWithBridge();
      final result = CommunityResult({0: 0, 1: 0, 2: 0, 3: 1, 4: 1, 5: 1});
      expect(CommunityMetrics.communityDensity(graph, {0, 1, 2}), 1.0);
      expect(
        CommunityMetrics.averageCommunityDensity(graph, result),
        closeTo(1.0, 1e-9),
      );
    });
  });

  group('CommunityMetrics.nmi', () {
    test('identical partitions', () {
      final a = {0: 0, 1: 0, 2: 1};
      final b = {0: 0, 1: 0, 2: 1};
      expect(CommunityMetrics.nmi(a, b), 1.0);
    });

    test('completely different partitions', () {
      final a = {0: 0, 1: 0, 2: 0};
      final b = {0: 0, 1: 1, 2: 2};
      expect(CommunityMetrics.nmi(a, b), lessThan(1.0));
    });

    test('empty truth', () {
      expect(CommunityMetrics.nmi({}, {}), 0.0);
    });
  });

  group('Community utilities', () {
    test('toMap', () {
      final result = CommunityResult({0: 0, 1: 0, 2: 1});
      final map = Community.toMap(result);
      expect(map, {
        0: {0, 1},
        1: {2},
      });
    });

    test('sizes', () {
      final result = CommunityResult({0: 0, 1: 0, 2: 1, 3: 1, 4: 1});
      expect(Community.sizes(result), {0: 2, 1: 3});
    });

    test('largest', () {
      final result = CommunityResult({0: 0, 1: 0, 2: 1});
      expect(Community.largest(result), 0);
    });

    test('largest empty', () {
      expect(Community.largest(CommunityResult({})), isNull);
    });

    test('nodesIn', () {
      final result = CommunityResult({0: 0, 1: 0, 2: 1});
      expect(Community.nodesIn(result, 0), {0, 1});
    });

    test('forNode', () {
      final result = CommunityResult({0: 0, 1: 1});
      expect(Community.forNode(result, 1), 1);
      expect(Community.forNode(result, 99), isNull);
    });

    test('merge', () {
      final result = CommunityResult({0: 0, 1: 1, 2: 1});
      final merged = Community.merge(result, 1, 0);
      expect(merged.numCommunities, 1);
      expect(merged.assignments, {0: 0, 1: 0, 2: 0});
    });

    test('merge same source and target', () {
      final result = CommunityResult({0: 0, 1: 1});
      expect(Community.merge(result, 0, 0).assignments, result.assignments);
    });

    test('merge nonexistent source', () {
      final result = CommunityResult({0: 0, 1: 1});
      expect(Community.merge(result, 5, 0).assignments, result.assignments);
    });
  });

  group('LabelPropagation', () {
    test('empty graph', () {
      final graph = SimpleGraph<String, int>.undirected();
      final result = LabelPropagation.detect(graph);
      expect(result.numCommunities, 0);
    });

    test('single node', () {
      final graph = SimpleGraph<String, int>.undirected()..addNode(0);
      final result = LabelPropagation.detect(graph);
      expect(result.numCommunities, 1);
    });

    test('two cliques with bridge converges to two communities', () {
      final graph = _twoCliquesWithBridge();
      final result = LabelPropagation.detect(graph, seed: 42);
      expect(result.numCommunities, greaterThanOrEqualTo(2));
    });

    test('path graph', () {
      final graph = SimpleGraph<String, int>.undirected()
        ..addEdge(0, 1)
        ..addEdge(1, 2);
      final result = LabelPropagation.detect(graph, seed: 42);
      expect(result.numCommunities, greaterThanOrEqualTo(1));
    });
  });

  group('Louvain', () {
    test('empty graph', () {
      final graph = SimpleGraph<String, int>.undirected();
      final result = Louvain.detect(graph);
      expect(result.numCommunities, 0);
    });

    test('single node', () {
      final graph = SimpleGraph<String, int>.undirected()..addNode(0);
      final result = Louvain.detect(graph);
      expect(result.numCommunities, 1);
    });

    test('two cliques with bridge', () {
      final graph = _twoCliquesWithBridge();
      final result = Louvain.detect(graph, seed: 42);
      expect(result.numCommunities, greaterThanOrEqualTo(2));

      final q = CommunityMetrics.modularity(graph, result);
      expect(q, greaterThan(0.3));
    });

    test('hierarchical returns multiple levels', () {
      final graph = _twoCliquesWithBridge();
      final dend = Louvain.detectHierarchical(graph, seed: 42);
      expect(dend.numLevels, greaterThanOrEqualTo(1));
      expect(dend.coarsest.numCommunities, greaterThanOrEqualTo(1));
    });

    test('deterministic with seed', () {
      final graph = _twoCliquesWithBridge();
      final a = Louvain.detect(graph, seed: 123);
      final b = Louvain.detect(graph, seed: 123);
      expect(a.assignments, b.assignments);
    });
  });

  group('Leiden', () {
    test('empty graph', () {
      final graph = SimpleGraph<String, int>.undirected();
      final result = Leiden.detect(graph);
      expect(result.numCommunities, 0);
    });

    test('single node', () {
      final graph = SimpleGraph<String, int>.undirected()..addNode(0);
      final result = Leiden.detect(graph);
      expect(result.numCommunities, 1);
    });

    test('two cliques with bridge', () {
      final graph = _twoCliquesWithBridge();
      final result = Leiden.detect(graph, seed: 42);
      expect(result.numCommunities, greaterThanOrEqualTo(2));

      final q = CommunityMetrics.modularity(graph, result);
      expect(q, greaterThan(0.3));
    });

    test('hierarchical', () {
      final graph = _twoCliquesWithBridge();
      final dend = Leiden.detectHierarchical(graph, seed: 42);
      expect(dend.numLevels, greaterThanOrEqualTo(1));
    });

    test('deterministic with seed', () {
      final graph = _twoCliquesWithBridge();
      final a = Leiden.detect(graph, seed: 123);
      final b = Leiden.detect(graph, seed: 123);
      expect(a.assignments, b.assignments);
    });
  });

  group('Walktrap', () {
    test('empty graph', () {
      final graph = SimpleGraph<String, int>.undirected();
      final result = Walktrap.detect(graph);
      expect(result.numCommunities, 0);
    });

    test('single node', () {
      final graph = SimpleGraph<String, int>.undirected()..addNode(0);
      final result = Walktrap.detect(graph);
      expect(result.numCommunities, 1);
    });

    test('two cliques with bridge', () {
      final graph = _twoCliquesWithBridge();
      final result = Walktrap.detect(graph);
      expect(result.numCommunities, greaterThanOrEqualTo(2));
    });

    test('target communities', () {
      final graph = _twoCliquesWithBridge();
      final result = Walktrap.detect(graph, targetCommunities: 2);
      expect(result.numCommunities, lessThanOrEqualTo(2));
    });

    test('hierarchical', () {
      final graph = _twoCliquesWithBridge();
      final dend = Walktrap.detectHierarchical(graph);
      expect(dend.numLevels, greaterThanOrEqualTo(1));
      expect(dend.coarsest.numCommunities, 1);
    });
  });

  group('Community facade delegations', () {
    test('Community.modularity', () {
      final graph = _twoCliquesWithBridge();
      final result = CommunityResult({0: 0, 1: 0, 2: 0, 3: 1, 4: 1, 5: 1});
      expect(Community.modularity(graph, result), greaterThan(0.3));
    });

    test('Community.louvain', () {
      final graph = _twoCliquesWithBridge();
      final result = Community.louvain(graph, seed: 42);
      expect(result.numCommunities, greaterThanOrEqualTo(2));
    });

    test('Community.leiden', () {
      final graph = _twoCliquesWithBridge();
      final result = Community.leiden(graph, seed: 42);
      expect(result.numCommunities, greaterThanOrEqualTo(2));
    });

    test('Community.labelPropagation', () {
      final graph = _twoCliquesWithBridge();
      final result = Community.labelPropagation(graph, seed: 42);
      expect(result.numCommunities, greaterThanOrEqualTo(2));
    });

    test('Community.walktrap', () {
      final graph = _twoCliquesWithBridge();
      final result = Community.walktrap(graph);
      expect(result.numCommunities, greaterThanOrEqualTo(1));
    });
  });
}

SimpleGraph<String, int> _twoCliquesWithBridge() {
  return SimpleGraph<String, int>.undirected()
    ..addEdge(0, 1, data: 1)
    ..addEdge(1, 2, data: 1)
    ..addEdge(2, 0, data: 1)
    ..addEdge(3, 4, data: 1)
    ..addEdge(4, 5, data: 1)
    ..addEdge(5, 3, data: 1)
    ..addEdge(2, 3, data: 1);
}

SimpleGraph<String, int> _completeGraph(int n) {
  final graph = SimpleGraph<String, int>.undirected();
  for (var i = 0; i < n; i++) {
    graph.addNode(i);
    for (var j = 0; j < i; j++) {
      graph.addEdge(i, j, data: 1);
    }
  }
  return graph;
}
