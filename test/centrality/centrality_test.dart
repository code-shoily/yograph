import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('DegreeCentrality', () {
    test('undirected star graph', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(0, 2);
      g.addEdge(0, 3);

      final scores = Centrality.degree(g);
      expect(scores[0], closeTo(1.0, 1e-9)); // 3/3
      expect(scores[1], closeTo(1 / 3, 1e-9));
      expect(scores[2], closeTo(1 / 3, 1e-9));
      expect(scores[3], closeTo(1 / 3, 1e-9));
    });

    test('directed with modes', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(0, 2);
      g.addEdge(2, 0);

      final inDeg = Centrality.degree(g, mode: DegreeMode.inDegree);
      expect(inDeg[0], closeTo(1 / 2, 1e-9)); // in-degree 1
      expect(inDeg[1], closeTo(1 / 2, 1e-9)); // in-degree 1
      expect(inDeg[2], closeTo(1 / 2, 1e-9)); // in-degree 1

      final outDeg = Centrality.degree(g, mode: DegreeMode.outDegree);
      expect(outDeg[0], closeTo(2 / 2, 1e-9)); // out-degree 2
      expect(outDeg[1], closeTo(0.0, 1e-9));
      expect(outDeg[2], closeTo(1 / 2, 1e-9));

      final total = Centrality.degree(g, mode: DegreeMode.totalDegree);
      expect(total[0], closeTo(3 / 2, 1e-9)); // in+out = 3
      expect(total[1], closeTo(1 / 2, 1e-9));
      expect(total[2], closeTo(2 / 2, 1e-9));
    });

    test('single node', () {
      final g = SimpleGraph.undirected()..addNode(0);
      final scores = Centrality.degree(g);
      expect(scores[0], 0.0);
    });

    test('empty graph', () {
      final g = SimpleGraph.undirected();
      final scores = Centrality.degree(g);
      expect(scores, isEmpty);
    });
  });

  group('ClosenessCentrality', () {
    test('path graph 0-1-2-3', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      g.addEdge(2, 3);

      final scores = Centrality.closeness(g);
      // Node 0: dists = 1,2,3 => sum = 6 => 3/6 = 0.5
      expect(scores[0], closeTo(0.5, 1e-9));
      // Node 1: dists = 1,1,2 => sum = 4 => 3/4 = 0.75
      expect(scores[1], closeTo(0.75, 1e-9));
      // Node 2: same as 1
      expect(scores[2], closeTo(0.75, 1e-9));
      // Node 3: same as 0
      expect(scores[3], closeTo(0.5, 1e-9));
    });

    test('disconnected graph', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(2, 3);

      final scores = Centrality.closeness(g);
      // Node 0 can only reach 1, sum=1, n=4, score=3/1=3
      expect(scores[0], closeTo(3.0, 1e-9));
      expect(scores[1], closeTo(3.0, 1e-9));
      expect(scores[2], closeTo(3.0, 1e-9));
      expect(scores[3], closeTo(3.0, 1e-9));
    });

    test('single node', () {
      final g = SimpleGraph.undirected()..addNode(0);
      final scores = Centrality.closeness(g);
      expect(scores[0], 0.0);
    });
  });

  group('HarmonicCentrality', () {
    test('path graph 0-1-2-3', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      g.addEdge(2, 3);

      final scores = Centrality.harmonic(g);
      // Node 0: 1/1 + 1/2 + 1/3 = 11/6 => /3 = 11/18
      expect(scores[0], closeTo(11 / 18, 1e-9));
      // Node 1: 1/1 + 1/1 + 1/2 = 5/2 => /3 = 5/6
      expect(scores[1], closeTo(5 / 6, 1e-9));
      expect(scores[2], closeTo(5 / 6, 1e-9));
      expect(scores[3], closeTo(11 / 18, 1e-9));
    });

    test('disconnected graph', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(2, 3);

      final scores = Centrality.harmonic(g);
      // Node 0: only node 1 reachable, 1/1 = 1 => /3 = 1/3
      expect(scores[0], closeTo(1 / 3, 1e-9));
      expect(scores[1], closeTo(1 / 3, 1e-9));
      expect(scores[2], closeTo(1 / 3, 1e-9));
      expect(scores[3], closeTo(1 / 3, 1e-9));
    });
  });

  group('BetweennessCentrality', () {
    test('path graph 0-1-2-3', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      g.addEdge(2, 3);

      final scores = Centrality.betweenness(g);
      // Raw directed-style betweenness / 2 for undirected
      // Node 1: from s=0:2, s=2:1, s=3:1 => total 4 => /2 = 2
      expect(scores[1], closeTo(2.0, 1e-9));
      // Node 2: from s=0:1, s=1:1, s=3:2 => total 4 => /2 = 2
      expect(scores[2], closeTo(2.0, 1e-9));
      expect(scores[0], closeTo(0.0, 1e-9));
      expect(scores[3], closeTo(0.0, 1e-9));
    });

    test('star graph', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(0, 2);
      g.addEdge(0, 3);

      final scores = Centrality.betweenness(g);
      // Center: 3 leaf-leaf pairs * 2 directions = 6 => /2 = 3
      expect(scores[0], closeTo(3.0, 1e-9));
      expect(scores[1], closeTo(0.0, 1e-9));
      expect(scores[2], closeTo(0.0, 1e-9));
      expect(scores[3], closeTo(0.0, 1e-9));
    });

    test('directed cycle', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      g.addEdge(2, 0);

      final scores = Centrality.betweenness(g);
      // In a directed cycle, each node lies on one shortest path:
      // 0->2 passes through 1, 1->0 passes through 2, 2->1 passes through 0
      expect(scores[0], closeTo(1.0, 1e-9));
      expect(scores[1], closeTo(1.0, 1e-9));
      expect(scores[2], closeTo(1.0, 1e-9));
    });

    test('directed path', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      g.addEdge(2, 3);

      final scores = Centrality.betweenness(g);
      // No /2 for directed
      // Node 1: paths (0,2), (0,3) = 2
      expect(scores[1], closeTo(2.0, 1e-9));
      // Node 2: paths (0,3), (1,3) = 2
      expect(scores[2], closeTo(2.0, 1e-9));
      expect(scores[0], closeTo(0.0, 1e-9));
      expect(scores[3], closeTo(0.0, 1e-9));
    });

    test('single node', () {
      final g = SimpleGraph.undirected()..addNode(0);
      final scores = Centrality.betweenness(g);
      expect(scores[0], 0.0);
    });

    test('empty graph', () {
      final g = SimpleGraph.undirected();
      final scores = Centrality.betweenness(g);
      expect(scores, isEmpty);
    });
  });

  group('PageRank', () {
    test('symmetric 2-node cycle', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(1, 0);

      final scores = Centrality.pageRank(g);
      expect(scores[0]! + scores[1]!, closeTo(1.0, 1e-9));
      expect(scores[0], closeTo(scores[1]!, 1e-9));
    });

    test('3-node cycle', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      g.addEdge(2, 0);

      final scores = Centrality.pageRank(g);
      expect(scores[0]! + scores[1]! + scores[2]!, closeTo(1.0, 1e-9));
      expect(scores[0], closeTo(scores[1]!, 1e-9));
      expect(scores[1], closeTo(scores[2]!, 1e-9));
    });

    test('sink redistribution', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(0, 2);
      // Node 0 points to 1 and 2, but 1 and 2 have no outgoing edges

      final scores = Centrality.pageRank(g);
      expect(scores[0]! + scores[1]! + scores[2]!, closeTo(1.0, 1e-9));
      // Node 0 distributes its rank to 1 and 2, but also gets some back
      // from the sink redistribution
      expect(scores[1]! > 0, isTrue);
      expect(scores[2]! > 0, isTrue);
    });

    test('single node', () {
      final g = SimpleGraph.directed()..addNode(0);
      final scores = Centrality.pageRank(g);
      expect(scores[0], 1.0);
    });

    test('empty graph', () {
      final g = SimpleGraph.directed();
      final scores = Centrality.pageRank(g);
      expect(scores, isEmpty);
    });
  });

  group('EigenvectorCentrality', () {
    test('undirected star', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(0, 2);
      g.addEdge(0, 3);

      final scores = Centrality.eigenvector(g);
      // Center should have highest score
      expect(scores[0]! > scores[1]!, isTrue);
      expect(scores[1], closeTo(scores[2]!, 1e-9));
      expect(scores[2], closeTo(scores[3]!, 1e-9));
    });

    test('single node', () {
      final g = SimpleGraph.undirected()..addNode(0);
      final scores = Centrality.eigenvector(g);
      expect(scores[0], 1.0);
    });
  });

  group('KatzCentrality', () {
    test('simple directed line', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(1, 2);

      final scores = Centrality.katz(g, alpha: 0.1, beta: 1.0);
      // All nodes have at least beta
      expect(scores[0]! >= 1.0, isTrue);
      expect(scores[1]! >= 1.0, isTrue);
      expect(scores[2]! >= 1.0, isTrue);
    });

    test('single node', () {
      final g = SimpleGraph.directed()..addNode(0);
      final scores = Centrality.katz(g);
      expect(scores[0], 1.0);
    });
  });

  group('AlphaCentrality', () {
    test('simple directed line', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(1, 2);

      final scores = Centrality.alpha(g, alpha: 0.1, initial: 1.0);
      expect(scores[0]! >= 1.0, isTrue);
      expect(scores[1]! >= 1.0, isTrue);
      expect(scores[2]! >= 1.0, isTrue);
    });

    test('single node', () {
      final g = SimpleGraph.directed()..addNode(0);
      final scores = Centrality.alpha(g);
      expect(scores[0], 1.0);
    });
  });

  group('HITS', () {
    test('simple authority/hub structure', () {
      final g = SimpleGraph.directed();
      // Node 1 and 2 point to node 0 (authority)
      // Node 0 points to node 3 (hub)
      g.addEdge(1, 0);
      g.addEdge(2, 0);
      g.addEdge(0, 3);

      final result = Centrality.hits(g);
      // Node 0 has high authority (pointed to by 1 and 2)
      // Nodes 1 and 2 have high hub scores (point to high-authority node 0)
      expect(result.authorities[0]! > result.authorities[3]!, isTrue);
      expect(result.hubs[1]! > result.hubs[0]!, isTrue);
      expect(result.hubs[2]! > result.hubs[0]!, isTrue);
    });

    test('single node', () {
      final g = SimpleGraph.directed()..addNode(0);
      final result = Centrality.hits(g);
      expect(result.authorities[0], 1.0);
      expect(result.hubs[0], 1.0);
    });

    test('empty graph', () {
      final g = SimpleGraph.directed();
      final result = Centrality.hits(g);
      expect(result.authorities, isEmpty);
      expect(result.hubs, isEmpty);
    });
  });

  group('BrandesExt', () {
    test('diamond graph alternative shortest paths', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(0, 2);
      g.addEdge(1, 3);
      g.addEdge(2, 3);

      final scores = Centrality.betweenness(g);
      // From 0 to 3: two shortest paths of length 2, passing through 1 and 2.
      // Unscaled score for 1 is 1.0 (0.5 from 0->3, 0.5 from 3->0).
      // Halved for undirected scaling -> 0.5.
      expect(scores[1], closeTo(0.5, 1e-9));
      expect(scores[2], closeTo(0.5, 1e-9));
    });

    test('Brandes.accumulateEdgeDependencies', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(1, 2);

      final discovery = Brandes.runDiscovery(g, 0);
      final edgeDeltas = Brandes.accumulateEdgeDependencies(discovery);

      // Shortest path: 0 -> 1 -> 2
      // Edge (1, 2): delta is 1.0
      // Edge (0, 1): delta is 2.0 (1.0 from node 1 + 1.0 from edge (1,2))
      expect(edgeDeltas[(1, 2)], closeTo(1.0, 1e-9));
      expect(edgeDeltas[(0, 1)], closeTo(2.0, 1e-9));
    });
  });
}
