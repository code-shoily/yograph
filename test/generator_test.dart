import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('Classic Generators', () {
    test('complete graph', () {
      final g = ClassicGenerator.complete(5);
      expect(g.nodeCount, equals(5));
      expect(g.edgeCount, equals(10));
      for (final u in g.nodeIds) {
        expect(g.degree(u), equals(4));
      }
    });

    test('directed complete graph', () {
      final g = ClassicGenerator.complete(5, kind: GraphKind.directed);
      expect(g.nodeCount, equals(5));
      expect(g.edgeCount, equals(20));
    });

    test('cycle graph', () {
      final g = ClassicGenerator.cycle(5);
      expect(g.nodeCount, equals(5));
      expect(g.edgeCount, equals(5));
      for (final u in g.nodeIds) {
        expect(g.degree(u), equals(2));
      }
    });

    test('path graph', () {
      final g = ClassicGenerator.path(5);
      expect(g.nodeCount, equals(5));
      expect(g.edgeCount, equals(4));
      expect(g.degree(0), equals(1));
      expect(g.degree(4), equals(1));
      expect(g.degree(2), equals(2));
    });

    test('star graph', () {
      final g = ClassicGenerator.star(5);
      expect(g.nodeCount, equals(5));
      expect(g.edgeCount, equals(4));
      expect(g.degree(0), equals(4));
      expect(g.degree(1), equals(1));
    });

    test('wheel graph', () {
      final g = ClassicGenerator.wheel(6);
      expect(g.nodeCount, equals(6));
      expect(g.edgeCount, equals(10)); // 5 spokes + 5 rim edges
      expect(g.degree(0), equals(5));
      expect(g.degree(1), equals(3));
    });

    test('grid 2D graph', () {
      final g = ClassicGenerator.grid2d(3, 4);
      expect(g.nodeCount, equals(12));
      expect(g.edgeCount, equals(17)); // (3-1)*4 + 3*(4-1) = 8 + 9 = 17
    });

    test('complete bipartite graph', () {
      final g = ClassicGenerator.completeBipartite(3, 4);
      expect(g.nodeCount, equals(7));
      expect(g.edgeCount, equals(12));
      expect(g.degree(0), equals(4));
      expect(g.degree(3), equals(3));
    });

    test('binary tree graph', () {
      final g = ClassicGenerator.binaryTree(3);
      expect(g.nodeCount, equals(15));
      expect(g.edgeCount, equals(14));
      expect(g.degree(0), equals(2)); // root has 2 children
    });

    test('Petersen graph', () {
      final g = ClassicGenerator.petersen();
      expect(g.nodeCount, equals(10));
      expect(g.edgeCount, equals(15));
      for (final u in g.nodeIds) {
        expect(g.degree(u), equals(3));
      }
    });

    test('empty graph', () {
      final g = ClassicGenerator.empty(5);
      expect(g.nodeCount, equals(5));
      expect(g.edgeCount, equals(0));
    });

    test('hypercube graph', () {
      final g = ClassicGenerator.hypercube(3);
      expect(g.nodeCount, equals(8));
      expect(g.edgeCount, equals(12)); // 3 * 8 / 2 = 12
      for (final u in g.nodeIds) {
        expect(g.degree(u), equals(3));
      }
    });

    test('ladder graph', () {
      final g = ClassicGenerator.ladder(5);
      expect(g.nodeCount, equals(10));
      expect(g.edgeCount, equals(13)); // 2*4 rails + 5 rungs = 13
    });
  });

  group('Random Generators', () {
    test('Erdos-Renyi G(n, p)', () {
      final g = RandomGenerator.erdosRenyiGnp(50, 0.2, seed: 42);
      expect(g.nodeCount, equals(50));
      // Expected edge count is roughly 0.2 * 50 * 49 / 2 = 245
      expect(g.edgeCount, greaterThan(150));
      expect(g.edgeCount, lessThan(300));
    });

    test('Erdos-Renyi G(n, m)', () {
      final g = RandomGenerator.erdosRenyiGnm(50, 100, seed: 42);
      expect(g.nodeCount, equals(50));
      expect(g.edgeCount, equals(100));
    });

    test('Barabasi-Albert', () {
      final g = RandomGenerator.barabasiAlbert(50, 3, seed: 42);
      expect(g.nodeCount, equals(50));
      expect(
        g.edgeCount,
        equals(3 * (3 - 1) ~/ 2 + 3 * (50 - 3)),
      ); // Initial complete graph edges + m edges per new node
    });

    test('Watts-Strogatz', () {
      final g = RandomGenerator.wattsStrogatz(50, 4, 0.1, seed: 42);
      expect(g.nodeCount, equals(50));
      expect(g.edgeCount, equals(100)); // k * n / 2 = 2 * 50 = 100
    });

    test('Random Tree', () {
      final g = RandomGenerator.randomTree(50, seed: 42);
      expect(g.nodeCount, equals(50));
      expect(g.edgeCount, equals(49));
      expect(Components.connectedComponents(g).length, equals(1));
    });

    test('Random Regular', () {
      final g = RandomGenerator.randomRegular(20, 3, seed: 42);
      expect(g.nodeCount, equals(20));
      expect(g.edgeCount, equals(30)); // 20 * 3 / 2 = 30
      for (final u in g.nodeIds) {
        expect(g.degree(u), equals(3));
      }
    });
  });

  group('Maze Generators', () {
    test('Binary Tree Maze', () {
      final maze = MazeGenerator.binaryTree(10, 10, seed: 42);
      expect(maze.rows, equals(10));
      expect(maze.cols, equals(10));
      expect(maze.graph.nodeCount, equals(100));
      expect(maze.graph.edgeCount, equals(99)); // Perfect maze has V - 1 edges
      expect(Components.connectedComponents(maze.graph).length, equals(1));
    });

    test('Sidewinder Maze', () {
      final maze = MazeGenerator.sidewinder(10, 10, seed: 42);
      expect(maze.rows, equals(10));
      expect(maze.cols, equals(10));
      expect(maze.graph.nodeCount, equals(100));
      expect(maze.graph.edgeCount, equals(99));
      expect(Components.connectedComponents(maze.graph).length, equals(1));
    });

    test('Recursive Backtracker Maze', () {
      final maze = MazeGenerator.recursiveBacktracker(10, 10, seed: 42);
      expect(maze.rows, equals(10));
      expect(maze.cols, equals(10));
      expect(maze.graph.nodeCount, equals(100));
      expect(maze.graph.edgeCount, equals(99));
      expect(Components.connectedComponents(maze.graph).length, equals(1));
    });
  });
}
