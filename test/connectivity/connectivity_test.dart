import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('Components.connectedComponents', () {
    test('empty graph', () {
      final g = SimpleGraph.undirected();
      expect(Components.connectedComponents(g), isEmpty);
    });

    test('single node', () {
      final g = SimpleGraph.undirected()..addNode(0);
      expect(Components.connectedComponents(g), [
        [0],
      ]);
    });

    test('two connected', () {
      final g = SimpleGraph.undirected()..addEdge(0, 1);
      final cc = Components.connectedComponents(g);
      expect(cc.length, 1);
      expect(cc.first.toSet(), {0, 1});
    });

    test('two disconnected', () {
      final g = SimpleGraph.undirected()..addEdgesFrom([(0, 1), (2, 3)]);
      final cc = Components.connectedComponents(g);
      expect(cc.length, 2);
    });

    test('path graph', () {
      final g = SimpleGraph.fromEdges([
        (0, 1),
        (1, 2),
        (2, 3),
      ], kind: GraphKind.undirected);
      final cc = Components.connectedComponents(g);
      expect(cc.length, 1);
      expect(cc.first.length, 4);
    });
  });

  group('Components.weaklyConnectedComponents', () {
    test('directed two components', () {
      final g = SimpleGraph.fromEdges([(0, 1), (2, 3)]);
      final wcc = Components.weaklyConnectedComponents(g);
      expect(wcc.length, 2);
    });

    test('directed one weak component', () {
      final g = SimpleGraph.fromEdges([(0, 1), (1, 2)]);
      // 2 has no edge back, but weakly it's one component
      final wcc = Components.weaklyConnectedComponents(g);
      expect(wcc.length, 1);
    });
  });

  group('SCC.tarjan', () {
    test('empty graph', () {
      final g = SimpleGraph.directed();
      expect(SCC.tarjan(g), isEmpty);
    });

    test('single node', () {
      final g = SimpleGraph.directed()..addNode(0);
      expect(SCC.tarjan(g), [
        [0],
      ]);
    });

    test('simple cycle', () {
      final g = SimpleGraph.fromEdges([(0, 1), (1, 2), (2, 0)]);
      final sccs = SCC.tarjan(g);
      expect(sccs.length, 1);
      expect(sccs.first.toSet(), {0, 1, 2});
    });

    test('two separate cycles', () {
      final g = SimpleGraph.fromEdges([(0, 1), (1, 0), (2, 3), (3, 2)]);
      final sccs = SCC.tarjan(g);
      expect(sccs.length, 2);
    });

    test('DAG', () {
      final g = SimpleGraph.fromEdges([(0, 1), (1, 2)]);
      final sccs = SCC.tarjan(g);
      expect(sccs.length, 3);
      for (final scc in sccs) {
        expect(scc.length, 1);
      }
    });

    test('diamond graph', () {
      final g = SimpleGraph.fromEdges([(0, 1), (0, 2), (1, 3), (2, 3)]);
      final sccs = SCC.tarjan(g);
      expect(sccs.length, 4);
    });
  });

  group('SCC.kosaraju', () {
    test('simple cycle', () {
      final g = SimpleGraph.fromEdges([(0, 1), (1, 2), (2, 0)]);
      final sccs = SCC.kosaraju(g);
      expect(sccs.length, 1);
      expect(sccs.first.toSet(), {0, 1, 2});
    });

    test('DAG', () {
      final g = SimpleGraph.fromEdges([(0, 1), (1, 2)]);
      final sccs = SCC.kosaraju(g);
      expect(sccs.length, 3);
    });

    test('two separate cycles', () {
      final g = SimpleGraph.fromEdges([(0, 1), (1, 0), (2, 3), (3, 2)]);
      final sccs = SCC.kosaraju(g);
      expect(sccs.length, 2);
    });
  });

  group('Analysis.analyze', () {
    test('empty graph', () {
      final g = SimpleGraph.undirected();
      final result = Analysis.analyze(g);
      expect(result.bridges, isEmpty);
      expect(result.articulationPoints, isEmpty);
    });

    test('single edge', () {
      final g = SimpleGraph.fromEdges([(0, 1)], kind: GraphKind.undirected);
      final result = Analysis.analyze(g);
      expect(result.bridges, [(0, 1)]);
      expect(result.articulationPoints, isEmpty);
    });

    test('triangle', () {
      final g = SimpleGraph.fromEdges([
        (0, 1),
        (1, 2),
        (2, 0),
      ], kind: GraphKind.undirected);
      final result = Analysis.analyze(g);
      expect(result.bridges, isEmpty);
      expect(result.articulationPoints, isEmpty);
    });

    test('path graph', () {
      final g = SimpleGraph.fromEdges([
        (0, 1),
        (1, 2),
        (2, 3),
      ], kind: GraphKind.undirected);
      final result = Analysis.analyze(g);
      expect(result.bridges, [(0, 1), (1, 2), (2, 3)]);
      expect(result.articulationPoints, {1, 2});
    });

    test('star graph', () {
      final g = SimpleGraph.fromEdges([
        (0, 1),
        (0, 2),
        (0, 3),
      ], kind: GraphKind.undirected);
      final result = Analysis.analyze(g);
      // All edges are bridges in a star
      expect(result.bridges.length, 3);
      expect(result.articulationPoints, {0});
    });

    test('bridge with cycle on one side', () {
      final g = SimpleGraph.fromEdges([
        (0, 1),
        (1, 2),
        (2, 0),
        (0, 3),
      ], kind: GraphKind.undirected);
      final result = Analysis.analyze(g);
      expect(result.bridges, [(0, 3)]);
      expect(result.articulationPoints, {0});
    });
  });

  group('KCore', () {
    test('detect k=2 on path', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      g.addEdge(2, 3);
      final k2 = KCore.detect(g, 2);
      // Path has no 2-core; all nodes eventually pruned
      expect(k2.nodeCount, 0);
    });

    test('coreNumbers on path', () {
      final g = SimpleGraph.fromEdges([
        (0, 1),
        (1, 2),
        (2, 3),
      ], kind: GraphKind.undirected);
      final cores = KCore.coreNumbers(g);
      // End nodes: 1, middle nodes: 1 (after pruning ends, the remaining path has degree 1)
      expect(cores[0], 1);
      expect(cores[1], 1);
      expect(cores[2], 1);
      expect(cores[3], 1);
    });

    test('coreNumbers on complete graph', () {
      final g = SimpleGraph.fromEdges([
        (0, 1),
        (0, 2),
        (0, 3),
        (1, 2),
        (1, 3),
        (2, 3),
      ], kind: GraphKind.undirected);
      final cores = KCore.coreNumbers(g);
      for (var i = 0; i < 4; i++) {
        expect(cores[i], 3);
      }
    });

    test('degeneracy of complete graph K4', () {
      final g = SimpleGraph.fromEdges([
        (0, 1),
        (0, 2),
        (0, 3),
        (1, 2),
        (1, 3),
        (2, 3),
      ], kind: GraphKind.undirected);
      expect(KCore.degeneracy(g), 3);
    });

    test('shellDecomposition', () {
      final g = SimpleGraph.fromEdges([
        (0, 1),
        (0, 2),
        (0, 3),
        (1, 2),
        (1, 3),
        (2, 3),
      ], kind: GraphKind.undirected);
      final shells = KCore.shellDecomposition(g);
      expect(shells[3]!.length, 4);
    });
  });

  group('Reachability', () {
    test('DAG descendants', () {
      final g = SimpleGraph.fromEdges([(0, 1), (0, 2), (1, 3), (2, 3)]);
      final counts = Reachability.counts(
        g,
        direction: ReachabilityDirection.descendants,
      );
      expect(counts[0], 3); // 1, 2, 3
      expect(counts[1], 1); // 3
      expect(counts[2], 1); // 3
      expect(counts[3], 0);
    });

    test('DAG ancestors', () {
      final g = SimpleGraph.fromEdges([(0, 1), (0, 2), (1, 3), (2, 3)]);
      final counts = Reachability.counts(
        g,
        direction: ReachabilityDirection.ancestors,
      );
      expect(counts[0], 0);
      expect(counts[1], 1); // 0
      expect(counts[2], 1); // 0
      expect(counts[3], 3); // 0, 1, 2
    });

    test('cyclic graph descendants', () {
      final g = SimpleGraph.fromEdges([(0, 1), (1, 2), (2, 0), (2, 3)]);
      final counts = Reachability.counts(
        g,
        direction: ReachabilityDirection.descendants,
      );
      // SCC {0,1,2}: each can reach the other 2 + node 3
      expect(counts[0], 3);
      expect(counts[1], 3);
      expect(counts[2], 3);
      expect(counts[3], 0);
    });

    test('empty graph', () {
      final g = SimpleGraph.directed();
      expect(
        Reachability.counts(g, direction: ReachabilityDirection.descendants),
        isEmpty,
      );
    });
  });
}
