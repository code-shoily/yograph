import 'dart:math' as math;
import '../simple_graph.dart';
import 'grid_graph.dart';

/// Helper class to build [GridGraph] from 2D structures.
abstract final class GridBuilder {
  /// Creates a grid graph from a 2D list of cell data.
  ///
  /// By default, uses rook (4-way) topology.
  /// The parameter [canMove] determines if movement from cell `A` to cell `B` is allowed.
  /// The parameter [edgeWeight] determines the weight of the edge between adjacent cells.
  static GridGraph<N, double> from2DList<N>(
    List<List<N>> gridData, {
    bool directed = false,
    bool Function(N fromCell, N toCell)? canMove,
    double Function(N fromCell, N toCell, int fromId, int toId)? edgeWeight,
  }) {
    return from2DListWithTopology(
      gridData,
      GridTopologies.rook,
      topologyName: 'rook',
      directed: directed,
      canMove: canMove,
      edgeWeight: edgeWeight,
    );
  }

  /// Creates a grid graph from a 2D list using a custom movement topology.
  static GridGraph<N, double> from2DListWithTopology<N>(
    List<List<N>> gridData,
    GridTopology topology, {
    String topologyName = 'custom',
    bool directed = false,
    bool Function(N fromCell, N toCell)? canMove,
    double Function(N fromCell, N toCell, int fromId, int toId)? edgeWeight,
  }) {
    final rows = gridData.length;
    final cols = rows > 0 ? gridData[0].length : 0;

    // Validate rectangularity of the 2D grid list
    for (int r = 0; r < rows; r++) {
      if (gridData[r].length != cols) {
        throw ArgumentError(
          'Row $r has ${gridData[r].length} cells, expected $cols',
        );
      }
    }

    final graph = directed
        ? SimpleGraph<N, double>.directed()
        : SimpleGraph<N, double>.undirected();

    // Add all nodes
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final id = r * cols + c;
        graph.addNode(id, data: gridData[r][c]);
      }
    }

    final allowed = canMove ?? (from, to) => true;

    // Add edges based on topology
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final fromId = r * cols + c;
        final fromData = gridData[r][c];

        for (final (dr, dc) in topology) {
          final nr = r + dr;
          final nc = c + dc;

          if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
            final toId = nr * cols + nc;
            final toData = gridData[nr][nc];

            if (allowed(fromData, toData)) {
              if (directed || fromId < toId) {
                final weight = edgeWeight != null
                    ? edgeWeight(fromData, toData, fromId, toId)
                    : 1.0;
                graph.addEdge(fromId, toId, data: weight);
              }
            }
          }
        }
      }
    }

    return GridGraph(
      graph: graph,
      rows: rows,
      cols: cols,
      topologyName: topologyName,
    );
  }

  // ===========================================================================
  // Distance Heuristics (extremely useful for A* pathfinding on grids)
  // ===========================================================================

  /// Calculates the Manhattan distance between two grid node IDs.
  /// Useful for 4-way (rook) movement.
  static int manhattanDistance(int fromId, int toId, int cols) {
    final fromRow = fromId ~/ cols;
    final fromCol = fromId % cols;
    final toRow = toId ~/ cols;
    final toCol = toId % cols;
    return (fromRow - toRow).abs() + (fromCol - toCol).abs();
  }

  /// Calculates the Chebyshev distance between two grid node IDs.
  /// Useful for 8-way (queen/king) movement where diagonal step cost matches cardinal.
  static int chebyshevDistance(int fromId, int toId, int cols) {
    final fromRow = fromId ~/ cols;
    final fromCol = fromId % cols;
    final toRow = toId ~/ cols;
    final toCol = toId % cols;
    final dRow = (fromRow - toRow).abs();
    final dCol = (fromCol - toCol).abs();
    return math.max(dRow, dCol);
  }

  /// Calculates the Octile distance between two grid node IDs.
  /// Useful for 8-way movement where diagonals cost sqrt(2) * cardinal.
  static double octileDistance(int fromId, int toId, int cols) {
    final fromRow = fromId ~/ cols;
    final fromCol = fromId % cols;
    final toRow = toId ~/ cols;
    final toCol = toId % cols;
    final dRow = (fromRow - toRow).abs();
    final dCol = (fromCol - toCol).abs();
    final minD = math.min(dRow, dCol);
    final maxD = math.max(dRow, dCol);
    return minD * 1.414213562373095 + (maxD - minD);
  }

  // ===========================================================================
  // Movement Predicate Factories
  // ===========================================================================

  /// Creates a predicate that only allows movement into cells matching `validValue`.
  static bool Function(T from, T to) walkable<T>(T validValue) {
    return (from, to) => from == validValue && to == validValue;
  }

  /// Creates a predicate that allows movement into any cell except `wallValue`.
  static bool Function(T from, T to) avoiding<T>(T wallValue) {
    return (from, to) => from != wallValue && to != wallValue;
  }

  /// Creates a predicate that allows movement into any of the specified values.
  static bool Function(T from, T to) including<T>(Iterable<T> validValues) {
    final valuesSet = validValues.toSet();
    return (from, to) => valuesSet.contains(from) && valuesSet.contains(to);
  }

  /// Always allows movement between adjacent cells.
  static bool Function(T from, T to) always<T>() {
    return (from, to) => true;
  }
}
