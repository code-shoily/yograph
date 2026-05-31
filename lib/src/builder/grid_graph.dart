import '../simple_graph.dart';

/// Preset movement topologies represented as row/col offsets.
typedef GridTopology = List<(int rowDelta, int colDelta)>;

/// Preset movement topologies.
abstract final class GridTopologies {
  /// 4-way cardinal movement (up, down, left, right).
  static const GridTopology rook = [(-1, 0), (1, 0), (0, -1), (0, 1)];

  /// 4-way diagonal movement.
  static const GridTopology bishop = [(-1, -1), (-1, 1), (1, -1), (1, 1)];

  /// 8-way movement (cardinal + diagonal).
  static const GridTopology queen = [
    (-1, -1),
    (-1, 0),
    (-1, 1),
    (0, -1),
    (0, 1),
    (1, -1),
    (1, 0),
    (1, 1),
  ];

  /// 8 L-shaped knight jumps in chess.
  static const GridTopology knight = [
    (-2, -1),
    (-2, 1),
    (-1, -2),
    (-1, 2),
    (1, -2),
    (1, 2),
    (2, -1),
    (2, 1),
  ];
}

/// Represents a structured 2D grid graph.
class GridGraph<N, T> {
  /// The underlying [SimpleGraph] representing the grid topology.
  final SimpleGraph<N, T> graph;

  /// Number of rows in the grid.
  final int rows;

  /// Number of columns in the grid.
  final int cols;

  /// Connection pattern topology name.
  final String topologyName;

  GridGraph({
    required this.graph,
    required this.rows,
    required this.cols,
    this.topologyName = 'rook',
  });

  /// Unwraps and returns the underlying plain [SimpleGraph].
  SimpleGraph<N, T> toGraph() => graph;

  /// Converts `{row, col}` grid coordinates to a unique node ID.
  int coordToId(int row, int col) => row * cols + col;

  /// Converts a node ID back to `{row, col}` grid coordinates.
  (int row, int col) idToCoord(int id) {
    return (id ~/ cols, id % cols);
  }

  /// Checks if `{row, col}` is within the grid bounds.
  bool isValidCoord(int row, int col) {
    return row >= 0 && row < rows && col >= 0 && col < cols;
  }

  /// Gets the cell data at grid coordinates `{row, col}`.
  /// Returns `null` if out of bounds or if node does not exist.
  N? getCell(int row, int col) {
    if (!isValidCoord(row, col)) return null;
    final id = coordToId(row, col);
    return graph.hasNode(id) ? graph.nodeData(id) : null;
  }

  /// Finds a node ID in the grid where the cell data satisfies the predicate.
  /// Returns `null` if no such node is found.
  int? findNode(bool Function(N data) predicate) {
    for (int id = 0; id < rows * cols; id++) {
      if (graph.hasNode(id)) {
        final data = graph.nodeData(id);
        if (data is N && predicate(data)) {
          return id;
        }
      }
    }
    return null;
  }
}
