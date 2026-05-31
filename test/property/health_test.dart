import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('Health - Distance Metrics', () {
    test('path graph 0-1-2-3 eccentricity, diameter, and radius', () {
      final g = SimpleGraph<String, double>.undirected();
      g.addEdge(0, 1, data: 1.0);
      g.addEdge(1, 2, data: 1.0);
      g.addEdge(2, 3, data: 1.0);

      // Eccentricity
      expect(Health.eccentricity(g, 0), closeTo(3.0, 1e-9));
      expect(Health.eccentricity(g, 1), closeTo(2.0, 1e-9));
      expect(Health.eccentricity(g, 2), closeTo(2.0, 1e-9));
      expect(Health.eccentricity(g, 3), closeTo(3.0, 1e-9));

      // Diameter and Radius
      expect(Health.diameter(g), closeTo(3.0, 1e-9));
      expect(Health.radius(g), closeTo(2.0, 1e-9));
    });

    test('star graph eccentricity, diameter, and radius', () {
      final g = SimpleGraph<String, double>.undirected();
      g.addEdge(0, 1, data: 1.0);
      g.addEdge(0, 2, data: 1.0);
      g.addEdge(0, 3, data: 1.0);

      // Eccentricity
      expect(Health.eccentricity(g, 0), closeTo(1.0, 1e-9));
      expect(Health.eccentricity(g, 1), closeTo(2.0, 1e-9));

      // Diameter and Radius
      expect(Health.diameter(g), closeTo(2.0, 1e-9));
      expect(Health.radius(g), closeTo(1.0, 1e-9));
    });

    test('disconnected graph eccentricity, diameter, and radius', () {
      final g = SimpleGraph<String, double>.undirected();
      g.addEdge(0, 1, data: 1.0);
      g.addEdge(2, 3, data: 1.0);

      // Should return null for disconnected parts
      expect(Health.eccentricity(g, 0), isNull);
      expect(Health.diameter(g), isNull);
      expect(Health.radius(g), isNull);
    });

    test('empty and single-node boundary cases', () {
      final empty = SimpleGraph<String, double>.undirected();
      expect(Health.diameter(empty), isNull);
      expect(Health.radius(empty), isNull);

      final single = SimpleGraph<String, double>.undirected()..addNode(0);
      expect(Health.eccentricity(single, 0), 0.0);
      expect(Health.diameter(single), 0.0);
      expect(Health.radius(single), 0.0);
    });
  });

  group('Health - Assortativity', () {
    test('star graph is disassortative (negative)', () {
      final g = SimpleGraph<String, double>.undirected();
      g.addEdge(0, 1);
      g.addEdge(0, 2);
      g.addEdge(0, 3);

      final coeff = Health.assortativity(g);
      expect(coeff, lessThan(0.0));
    });

    test('complete graph complete K3 is zero / regular graph boundary', () {
      final g = SimpleGraph<String, double>.undirected();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      g.addEdge(2, 0);

      final coeff = Health.assortativity(g);
      expect(coeff, closeTo(0.0, 1e-9));
    });

    test('empty graph assortativity', () {
      final g = SimpleGraph<String, double>.undirected();
      expect(Health.assortativity(g), 0.0);
    });
  });

  group('Health - Average Path Length', () {
    test('triangle graph average path length', () {
      final g = SimpleGraph<String, double>.undirected();
      g.addEdge(0, 1, data: 1.0);
      g.addEdge(1, 2, data: 1.0);
      g.addEdge(2, 0, data: 1.0);

      expect(Health.averagePathLength(g), closeTo(1.0, 1e-9));
    });

    test('line graph average path length', () {
      final g = SimpleGraph<String, double>.undirected();
      g.addEdge(0, 1, data: 1.0);
      g.addEdge(1, 2, data: 1.0);

      // Node pairs distinct (3 * 2 = 6 ordered pairs)
      // 0->1: 1, 0->2: 2
      // 1->0: 1, 1->2: 1
      // 2->0: 2, 2->1: 1
      // Sum = 8 => 8 / 6 = 1.3333333333333333
      expect(Health.averagePathLength(g), closeTo(4 / 3, 1e-9));
    });

    test('disconnected and empty boundary checks', () {
      final empty = SimpleGraph<String, double>.undirected();
      expect(Health.averagePathLength(empty), isNull);

      final single = SimpleGraph<String, double>.undirected()..addNode(0);
      expect(Health.averagePathLength(single), isNull);

      final g = SimpleGraph<String, double>.undirected();
      g.addEdge(0, 1, data: 1.0);
      g.addEdge(2, 3, data: 1.0);
      expect(Health.averagePathLength(g), isNull);
    });
  });

  group('Health - Efficiency Metrics', () {
    test('node-to-node efficiency', () {
      final g = SimpleGraph<String, double>.undirected();
      g.addEdge(0, 1, data: 1.0);
      g.addEdge(1, 2, data: 1.0);

      expect(Health.efficiency(g, 0, 2), closeTo(0.5, 1e-9));
      expect(Health.efficiency(g, 0, 0), 0.0); // same node
      expect(Health.efficiency(g, 0, 3), 0.0); // unreachable
    });

    test('global efficiency', () {
      final g = SimpleGraph<String, double>.undirected();
      g.addEdge(0, 1, data: 1.0);
      g.addEdge(1, 2, data: 1.0);
      g.addEdge(2, 0, data: 1.0);

      expect(Health.globalEfficiency(g), closeTo(1.0, 1e-9));

      final line = SimpleGraph<String, double>.undirected();
      line.addEdge(0, 1, data: 1.0);
      line.addEdge(1, 2, data: 1.0);
      // pairs: (0,1)->1.0, (0,2)->0.5, (1,0)->1.0, (1,2)->1.0, (2,0)->0.5, (2,1)->1.0
      // Sum = 5.0 => 5.0 / 6 = 0.8333333333333333
      expect(Health.globalEfficiency(line), closeTo(5 / 6, 1e-9));
    });

    test('local and average local efficiency', () {
      final g = SimpleGraph<String, double>.undirected();
      g.addEdge(0, 1, data: 1.0);
      g.addEdge(0, 2, data: 1.0);
      g.addEdge(1, 2, data: 1.0); // neighbors 1 and 2 are connected

      // Neighbors of 0: {1, 2}. Subgraph induced by {1, 2} has edge 1-2.
      // Global efficiency of clique K2 is 1.0.
      expect(Health.localEfficiency(g, 0), closeTo(1.0, 1e-9));

      // Neighbors of 1: {0, 2}. Subgraph induced by {0, 2} has edge 0-2.
      // Global efficiency of clique K2 is 1.0.
      expect(Health.localEfficiency(g, 1), closeTo(1.0, 1e-9));

      expect(Health.averageLocalEfficiency(g), closeTo(1.0, 1e-9));
    });

    test('local efficiency under-degree nodes', () {
      final g = SimpleGraph<String, double>.undirected();
      g.addEdge(0, 1, data: 1.0); // node 1 has degree 1

      expect(Health.localEfficiency(g, 1), 0.0);
    });

    test('local efficiency on directed graph', () {
      final g = SimpleGraph<String, double>.directed();
      g.addEdge(0, 1, data: 1.0);
      g.addEdge(2, 0, data: 1.0); // predecessor
      g.addEdge(1, 2, data: 1.0); // connects neighbors 1 and 2

      // Neighbors of 0: successors {1} + predecessors {2} = {1, 2}.
      // Subgraph induced by {1, 2} has edge 1->2.
      // Distinct pairs: (1,2)->1.0, (2,1)->unreachable
      // Global efficiency = (1.0 / 1.0 + 0.0) / 2 = 0.5
      expect(Health.localEfficiency(g, 0), closeTo(0.5, 1e-9));
      expect(Health.averageLocalEfficiency(g), greaterThan(0.0));
    });
  });
}
