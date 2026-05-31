import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('Bipartite', () {
    test('isBipartite on empty graph', () {
      final g = SimpleGraph<String, void>.undirected();
      expect(Bipartite.isBipartite(g), isTrue);
      final p = Bipartite.partition(g);
      expect(p!.left, isEmpty);
      expect(p.right, isEmpty);
    });

    test('isBipartite on a tree (bipartite)', () {
      final g = SimpleGraph<String, void>.fromEdges([
        (0, 1),
        (0, 2),
        (1, 3),
      ], kind: GraphKind.undirected);
      expect(Bipartite.isBipartite(g), isTrue);

      final p = Bipartite.partition(g)!;
      expect(p.left.length + p.right.length, equals(4));

      // 0 and 3 are on one side, 1 and 2 are on the other side
      if (p.left.contains(0)) {
        expect(p.left, containsAll([0, 3]));
        expect(p.right, containsAll([1, 2]));
      } else {
        expect(p.right, containsAll([0, 3]));
        expect(p.left, containsAll([1, 2]));
      }

      final colors = Bipartite.coloring(g)!;
      expect(colors[0], isNot(colors[1]));
      expect(colors[0], isNot(colors[2]));
      expect(colors[1], isNot(colors[3]));
    });

    test('isBipartite on a triangle (odd cycle, not bipartite)', () {
      final g = SimpleGraph<String, void>.fromEdges([
        (0, 1),
        (1, 2),
        (2, 0),
      ], kind: GraphKind.undirected);
      expect(Bipartite.isBipartite(g), isFalse);
      expect(Bipartite.partition(g), isNull);
      expect(Bipartite.coloring(g), isNull);
    });

    test('maximumMatching on complete bipartite K_{2,2}', () {
      final g = SimpleGraph<String, void>.fromEdges([
        (0, 2),
        (0, 3),
        (1, 2),
        (1, 3),
      ], kind: GraphKind.undirected);
      final p = Bipartite.partition(g)!;
      final matching = Bipartite.maximumMatching(g, p);
      expect(matching.length, equals(2));
      final leftMatched = matching.map((pair) => pair.$1).toSet();
      final rightMatched = matching.map((pair) => pair.$2).toSet();
      expect(leftMatched, containsAll([0, 1]));
      expect(rightMatched, containsAll([2, 3]));
    });

    test('stableMarriage residency matching', () {
      final residents = {
        1: [101, 102],
        2: [102, 101],
      };
      final hospitals = {
        101: [1, 2],
        102: [2, 1],
      };
      final matches = Bipartite.stableMarriage(residents, hospitals);

      expect(matches[1], equals(101));
      expect(matches[101], equals(1));
      expect(matches[2], equals(102));
      expect(matches[102], equals(2));
    });

    test('stableMarriage with unmatched preferences and ranking mismatches', () {
      final residents = {
        1: [101],
        2: [101],
      };
      final hospitals = {
        101: [1], // 2 is not even listed in 101's preferences!
      };
      final matches = Bipartite.stableMarriage(residents, hospitals);
      // Resident 2 proposes first (since freeLeft is a stack/list, freeLeft.removeLast() pops 2).
      // Hospital 101 is unmatched, so it matches with 2.
      // Then resident 1 proposes to 101.
      // Hospital 101 is matched to 2 (unlisted, currentRank = null).
      // Proposer 1 is listed (newRank = 0).
      // Hospital 101 dumps 2 for 1.
      expect(matches[1], equals(101));
      expect(matches[2], isNull);
    });

    test('maximumMatching with unmatched nodes', () {
      final g = SimpleGraph<String, void>.fromEdges([
        (0, 1), // Only 0 is connected to 1
        (2, 3), // 2 is only connected to 3
      ], kind: GraphKind.undirected);
      // Let's force an unbalanced partition: left has {0, 2, 4}, right has {1, 3}
      final p = (left: {0, 2, 4}, right: {1, 3});
      final matching = Bipartite.maximumMatching(g, p);
      expect(matching.length, equals(2)); // node 4 remains unmatched
    });
  });

  group('Clique', () {
    test('maxClique and allMaximalCliques on empty graph', () {
      final g = SimpleGraph<String, void>.undirected();
      expect(Clique.maxClique(g), isEmpty);
      expect(Clique.allMaximalCliques(g), isEmpty);
    });

    test(
      'Bron-Kerbosch maximal cliques and maxClique on a house-shaped graph',
      () {
        // House:
        //     0
        //    / \
        //   1---2
        //   |   |
        //   3---4
        final g = SimpleGraph<String, void>.fromEdges([
          (0, 1),
          (0, 2),
          (1, 2),
          (1, 3),
          (2, 4),
          (3, 4),
        ], kind: GraphKind.undirected);

        final maxC = Clique.maxClique(g);
        expect(maxC, containsAll([0, 1, 2]));
        expect(maxC.length, equals(3));

        final allC = Clique.allMaximalCliques(g);
        // Maximal cliques: {0,1,2}, {1,3}, {2,4}, {3,4}
        expect(allC.length, equals(4));
      },
    );

    test('kCliques on a complete graph K4', () {
      final g = SimpleGraph<String, void>.fromEdges([
        (0, 1),
        (0, 2),
        (0, 3),
        (1, 2),
        (1, 3),
        (2, 3),
      ], kind: GraphKind.undirected);

      final size3 = Clique.kCliques(g, 3);
      expect(size3.length, equals(4)); // 4 triangles

      final size2 = Clique.kCliques(g, 2);
      expect(size2.length, equals(6)); // 6 edges

      final size4 = Clique.kCliques(g, 4);
      expect(size4.length, equals(1)); // 1 K4 clique
    });
  });

  group('Cyclicity', () {
    test('isCyclic and isAcyclic on directed graphs', () {
      final dag = SimpleGraph<String, void>.fromEdges([(0, 1), (1, 2), (0, 2)]);
      expect(Cyclicity.isCyclic(dag), isFalse);
      expect(Cyclicity.isAcyclic(dag), isTrue);

      final cycle = SimpleGraph<String, void>.fromEdges([
        (0, 1),
        (1, 2),
        (2, 0),
      ]);
      expect(Cyclicity.isCyclic(cycle), isTrue);
      expect(Cyclicity.isAcyclic(cycle), isFalse);
    });

    test('isCyclic and isAcyclic on undirected graphs', () {
      final tree = SimpleGraph<String, void>.fromEdges([
        (0, 1),
        (1, 2),
      ], kind: GraphKind.undirected);
      expect(Cyclicity.isCyclic(tree), isFalse);
      expect(Cyclicity.isAcyclic(tree), isTrue);

      final cycle = SimpleGraph<String, void>.fromEdges([
        (0, 1),
        (1, 2),
        (2, 0),
      ], kind: GraphKind.undirected);
      expect(Cyclicity.isCyclic(cycle), isTrue);
      expect(Cyclicity.isAcyclic(cycle), isFalse);
    });
  });

  group('Eulerian', () {
    test('hasEulerianCircuit and eulerianCircuit on square graph', () {
      final g = SimpleGraph<String, void>.fromEdges([
        (0, 1),
        (1, 2),
        (2, 3),
        (3, 0),
      ], kind: GraphKind.undirected);
      expect(Eulerian.hasEulerianCircuit(g), isTrue);
      expect(Eulerian.hasEulerianPath(g), isTrue);

      final circuit = Eulerian.eulerianCircuit(g)!;
      expect(circuit.first, equals(circuit.last));
      expect(circuit.length, equals(5));
    });

    test('hasEulerianPath and eulerianPath on path graph', () {
      final g = SimpleGraph<String, void>.fromEdges([
        (0, 1),
        (1, 2),
      ], kind: GraphKind.undirected);
      expect(Eulerian.hasEulerianCircuit(g), isFalse);
      expect(Eulerian.hasEulerianPath(g), isTrue);

      final path = Eulerian.eulerianPath(g)!;
      expect(path.length, equals(3));
      expect(path, anyOf(equals([0, 1, 2]), equals([2, 1, 0])));
    });

    test('Eulerian on a disconnected graph with non-isolated components', () {
      // Two separate triangles:
      final g = SimpleGraph<String, void>.fromEdges([
        (0, 1),
        (1, 2),
        (2, 0),
        (3, 4),
        (4, 5),
        (5, 3),
      ], kind: GraphKind.undirected);
      // Connectedness check must fail because we have two non-isolated components
      expect(Eulerian.hasEulerianCircuit(g), isFalse);
      expect(Eulerian.hasEulerianPath(g), isFalse);
    });

    test('Eulerian on directed graphs', () {
      // Directed Eulerian Circuit: 0 -> 1 -> 2 -> 0
      final gCirc = SimpleGraph<String, void>.fromEdges([
        (0, 1),
        (1, 2),
        (2, 0),
      ], kind: GraphKind.directed);
      expect(Eulerian.hasEulerianCircuit(gCirc), isTrue);
      expect(Eulerian.hasEulerianPath(gCirc), isTrue);
      expect(Eulerian.eulerianCircuit(gCirc), equals([0, 1, 2, 0]));

      // Directed Eulerian Path (no circuit): 0 -> 1 -> 2
      final gPath = SimpleGraph<String, void>.fromEdges([
        (0, 1),
        (1, 2),
      ], kind: GraphKind.directed);
      expect(Eulerian.hasEulerianCircuit(gPath), isFalse);
      expect(Eulerian.hasEulerianPath(gPath), isTrue);
      expect(Eulerian.eulerianPath(gPath), equals([0, 1, 2]));

      // Non-Eulerian directed graph: unbalanced in/out degrees
      final gUnbal = SimpleGraph<String, void>.fromEdges([
        (0, 1),
        (0, 2),
      ], kind: GraphKind.directed);
      expect(Eulerian.hasEulerianCircuit(gUnbal), isFalse);
      expect(Eulerian.hasEulerianPath(gUnbal), isFalse);
    });
  });
}
