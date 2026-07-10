import 'dart:math' as math;
import '../model/graph_kind.dart';
import '../simple_graph.dart';

/// Deterministic graph generators for common graph structures.
abstract final class ClassicGenerator {
  ClassicGenerator._();

  /// Generates a complete graph K_n where every node connects to every other.
  static SimpleGraph<void, int> complete(
    int n, {
    GraphKind kind = GraphKind.undirected,
  }) {
    final graph = kind == GraphKind.directed
        ? SimpleGraph<void, int>.directed()
        : SimpleGraph<void, int>.undirected();

    if (n <= 0) return graph;

    for (var i = 0; i < n; i++) {
      graph.addNode(i);
    }

    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        graph.addEdge(i, j, data: 1);
        if (kind == GraphKind.directed) {
          graph.addEdge(j, i, data: 1);
        }
      }
    }
    return graph;
  }

  /// Generates a cycle graph C_n where nodes form a circular ring.
  static SimpleGraph<void, int> cycle(
    int n, {
    GraphKind kind = GraphKind.undirected,
  }) {
    final graph = kind == GraphKind.directed
        ? SimpleGraph<void, int>.directed()
        : SimpleGraph<void, int>.undirected();

    if (n < 3) return graph;

    for (var i = 0; i < n; i++) {
      graph.addNode(i);
    }

    for (var i = 0; i < n; i++) {
      graph.addEdge(i, (i + 1) % n, data: 1);
    }
    return graph;
  }

  /// Generates a path graph P_n where nodes form a linear chain.
  static SimpleGraph<void, int> path(
    int n, {
    GraphKind kind = GraphKind.undirected,
  }) {
    final graph = kind == GraphKind.directed
        ? SimpleGraph<void, int>.directed()
        : SimpleGraph<void, int>.undirected();

    if (n <= 0) return graph;

    for (var i = 0; i < n; i++) {
      graph.addNode(i);
    }

    for (var i = 0; i < n - 1; i++) {
      graph.addEdge(i, i + 1, data: 1);
    }
    return graph;
  }

  /// Generates a star graph S_n with one central hub (node 0) connected to all other nodes.
  static SimpleGraph<void, int> star(
    int n, {
    GraphKind kind = GraphKind.undirected,
  }) {
    final graph = kind == GraphKind.directed
        ? SimpleGraph<void, int>.directed()
        : SimpleGraph<void, int>.undirected();

    if (n <= 0) return graph;

    for (var i = 0; i < n; i++) {
      graph.addNode(i);
    }

    for (var i = 1; i < n; i++) {
      graph.addEdge(0, i, data: 1);
    }
    return graph;
  }

  /// Generates a wheel graph W_n: a cycle of rim nodes connected to a central hub (node 0).
  static SimpleGraph<void, int> wheel(
    int n, {
    GraphKind kind = GraphKind.undirected,
  }) {
    final graph = kind == GraphKind.directed
        ? SimpleGraph<void, int>.directed()
        : SimpleGraph<void, int>.undirected();

    if (n < 4) return graph;

    for (var i = 0; i < n; i++) {
      graph.addNode(i);
    }

    // Spokes: center 0 to all rim nodes 1..n-1
    for (var i = 1; i < n; i++) {
      graph.addEdge(0, i, data: 1);
    }

    // Rim cycle: 1 -> 2 -> ... -> n-1 -> 1
    for (var i = 1; i < n; i++) {
      final next = i == n - 1 ? 1 : i + 1;
      graph.addEdge(i, next, data: 1);
    }
    return graph;
  }

  /// Generates a 2D grid graph with [rows] and [cols].
  static SimpleGraph<void, int> grid2d(
    int rows,
    int cols, {
    GraphKind kind = GraphKind.undirected,
  }) {
    final graph = kind == GraphKind.directed
        ? SimpleGraph<void, int>.directed()
        : SimpleGraph<void, int>.undirected();

    if (rows <= 0 || cols <= 0) return graph;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final u = r * cols + c;
        graph.addNode(u);
      }
    }

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final u = r * cols + c;
        if (c < cols - 1) {
          graph.addEdge(u, u + 1, data: 1);
        }
        if (r < rows - 1) {
          graph.addEdge(u, u + cols, data: 1);
        }
      }
    }
    return graph;
  }

  /// Generates a complete bipartite graph K_{m,n}.
  static SimpleGraph<void, int> completeBipartite(
    int m,
    int n, {
    GraphKind kind = GraphKind.undirected,
  }) {
    final graph = kind == GraphKind.directed
        ? SimpleGraph<void, int>.directed()
        : SimpleGraph<void, int>.undirected();

    if (m < 0 || n < 0) return graph;

    final total = m + n;
    for (var i = 0; i < total; i++) {
      graph.addNode(i);
    }

    for (var i = 0; i < m; i++) {
      for (var j = m; j < total; j++) {
        graph.addEdge(i, j, data: 1);
      }
    }
    return graph;
  }

  /// Generates a complete binary tree of a given [depth].
  static SimpleGraph<void, int> binaryTree(
    int depth, {
    GraphKind kind = GraphKind.undirected,
  }) {
    final graph = kind == GraphKind.directed
        ? SimpleGraph<void, int>.directed()
        : SimpleGraph<void, int>.undirected();

    if (depth < 0) return graph;

    final totalNodes = (math.pow(2, depth + 1) - 1).toInt();
    for (var i = 0; i < totalNodes; i++) {
      graph.addNode(i);
    }

    // Node i has children at 2*i + 1 and 2*i + 2
    final limit = (math.pow(2, depth) - 1).toInt();
    for (var i = 0; i < limit; i++) {
      final left = 2 * i + 1;
      final right = 2 * i + 2;
      if (left < totalNodes) {
        graph.addEdge(i, left, data: 1);
      }
      if (right < totalNodes) {
        graph.addEdge(i, right, data: 1);
      }
    }
    return graph;
  }

  /// Generates the classic Petersen graph (10 nodes, 15 edges).
  static SimpleGraph<void, int> petersen() {
    final graph = SimpleGraph<void, int>.undirected();

    for (var i = 0; i < 10; i++) {
      graph.addNode(i);
    }

    // Outer cycle: 0-1-2-3-4-0
    for (var i = 0; i < 5; i++) {
      graph.addEdge(i, (i + 1) % 5, data: 1);
    }

    // Inner star: 5-7-9-6-8-5
    graph.addEdge(5, 7, data: 1);
    graph.addEdge(7, 9, data: 1);
    graph.addEdge(9, 6, data: 1);
    graph.addEdge(6, 8, data: 1);
    graph.addEdge(8, 5, data: 1);

    // Outer-to-inner spokes: i to i+5
    for (var i = 0; i < 5; i++) {
      graph.addEdge(i, i + 5, data: 1);
    }

    return graph;
  }

  /// Generates an empty/isolated graph with [n] nodes and 0 edges.
  static SimpleGraph<void, int> empty(
    int n, {
    GraphKind kind = GraphKind.undirected,
  }) {
    final graph = kind == GraphKind.directed
        ? SimpleGraph<void, int>.directed()
        : SimpleGraph<void, int>.undirected();

    for (var i = 0; i < n; i++) {
      graph.addNode(i);
    }
    return graph;
  }

  /// Generates a hypercube graph Q_n of dimension [n].
  static SimpleGraph<void, int> hypercube(
    int n, {
    GraphKind kind = GraphKind.undirected,
  }) {
    final graph = kind == GraphKind.directed
        ? SimpleGraph<void, int>.directed()
        : SimpleGraph<void, int>.undirected();

    if (n < 0) return graph;

    final totalNodes = 1 << n;
    for (var i = 0; i < totalNodes; i++) {
      graph.addNode(i);
    }

    for (var i = 0; i < totalNodes; i++) {
      for (var d = 0; d < n; d++) {
        final neighbor = i ^ (1 << d);
        if (kind == GraphKind.directed || i < neighbor) {
          graph.addEdge(i, neighbor, data: 1);
        }
      }
    }
    return graph;
  }

  /// Generates a ladder graph of size [n].
  static SimpleGraph<void, int> ladder(
    int n, {
    GraphKind kind = GraphKind.undirected,
  }) {
    final graph = kind == GraphKind.directed
        ? SimpleGraph<void, int>.directed()
        : SimpleGraph<void, int>.undirected();

    if (n <= 0) return graph;

    final total = 2 * n;
    for (var i = 0; i < total; i++) {
      graph.addNode(i);
    }

    // Rails: 0-1-...-(n-1) and n-(n+1)-...-(2n-1)
    for (var i = 0; i < n - 1; i++) {
      graph.addEdge(i, i + 1, data: 1);
      graph.addEdge(n + i, n + i + 1, data: 1);
    }

    // Rungs: connect i to n + i
    for (var i = 0; i < n; i++) {
      graph.addEdge(i, n + i, data: 1);
    }
    return graph;
  }
}
