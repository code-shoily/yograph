import 'dart:math' as math;
import '../builder/grid_graph.dart';

import '../simple_graph.dart';

/// Maze generation algorithms for creating perfect mazes.
abstract final class MazeGenerator {
  MazeGenerator._();

  static GridGraph<void, double> _createEmptyGrid(int rows, int cols) {
    final graph = SimpleGraph<void, double>.undirected();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final id = r * cols + c;
        graph.addNode(id);
      }
    }
    return GridGraph<void, double>(
      graph: graph,
      rows: rows,
      cols: cols,
      topologyName: 'rook',
    );
  }

  static void _addPassage(
    GridGraph<void, double> grid,
    int r1,
    int c1,
    int r2,
    int c2,
  ) {
    final fromId = r1 * grid.cols + c1;
    final toId = r2 * grid.cols + c2;
    grid.graph.addEdge(fromId, toId, data: 1.0);
  }

  /// Generates a maze using the Binary Tree algorithm.
  static GridGraph<void, double> binaryTree(int rows, int cols, {int? seed}) {
    if (rows <= 0 || cols <= 0) {
      return GridGraph(graph: SimpleGraph.undirected(), rows: 0, cols: 0);
    }

    final grid = _createEmptyGrid(rows, cols);
    final rng = seed != null ? math.Random(seed) : math.Random();

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final neighbors = <(int, int)>[];
        // NE bias: north (r-1) and east (c+1)
        if (r > 0) neighbors.add((r - 1, c));
        if (c < cols - 1) neighbors.add((r, c + 1));

        if (neighbors.isNotEmpty) {
          final (nr, nc) = neighbors[rng.nextInt(neighbors.length)];
          _addPassage(grid, r, c, nr, nc);
        }
      }
    }

    return grid;
  }

  /// Generates a maze using the Sidewinder algorithm.
  static GridGraph<void, double> sidewinder(int rows, int cols, {int? seed}) {
    if (rows <= 0 || cols <= 0) {
      return GridGraph(graph: SimpleGraph.undirected(), rows: 0, cols: 0);
    }

    final grid = _createEmptyGrid(rows, cols);
    final rng = seed != null ? math.Random(seed) : math.Random();

    for (var r = 0; r < rows; r++) {
      var runStartCol = 0;
      final isLastRow = r == rows - 1;

      for (var c = 0; c < cols; c++) {
        final atEastEnd = c == cols - 1;
        final atNorthEdge = r == 0;

        var shouldCloseRun = false;
        if (!atNorthEdge) {
          shouldCloseRun = atEastEnd || rng.nextBool();
        }

        if (isLastRow && !atEastEnd) {
          _addPassage(grid, r, c, r, c + 1);
        } else if (isLastRow && atEastEnd) {
          final runCol = runStartCol == c
              ? c
              : runStartCol + rng.nextInt(c - runStartCol + 1);
          _addPassage(grid, r, runCol, r - 1, runCol);
          runStartCol = 0;
        } else if (atNorthEdge && !atEastEnd) {
          _addPassage(grid, r, c, r, c + 1);
        } else if (atNorthEdge && atEastEnd) {
          runStartCol = 0;
        } else if (shouldCloseRun) {
          final runCol = runStartCol == c
              ? c
              : runStartCol + rng.nextInt(c - runStartCol + 1);
          _addPassage(grid, r, runCol, r - 1, runCol);
          runStartCol = c + 1;
        } else {
          _addPassage(grid, r, c, r, c + 1);
        }
      }
    }

    return grid;
  }

  /// Generates a maze using the Recursive Backtracker algorithm.
  static GridGraph<void, double> recursiveBacktracker(
    int rows,
    int cols, {
    int? seed,
  }) {
    if (rows <= 0 || cols <= 0) {
      return GridGraph(graph: SimpleGraph.undirected(), rows: 0, cols: 0);
    }

    final grid = _createEmptyGrid(rows, cols);
    final rng = seed != null ? math.Random(seed) : math.Random();

    final visited = <(int, int)>{};
    final stack = <(int, int)>[];

    final startRow = rng.nextInt(rows);
    final startCol = rng.nextInt(cols);
    final start = (startRow, startCol);

    visited.add(start);
    stack.add(start);

    while (stack.isNotEmpty) {
      final (r, c) = stack.last;

      // Find unvisited neighbors
      final unvisited = <(int, int)>[];
      final candidates = [(r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)];

      for (final (nr, nc) in candidates) {
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
          if (!visited.contains((nr, nc))) {
            unvisited.add((nr, nc));
          }
        }
      }

      if (unvisited.isEmpty) {
        stack.removeLast();
      } else {
        final (nr, nc) = unvisited[rng.nextInt(unvisited.length)];
        _addPassage(grid, r, c, nr, nc);
        visited.add((nr, nc));
        stack.add((nr, nc));
      }
    }

    return grid;
  }
}
