import '../builder/grid_graph.dart';
import '../simple_graph.dart';

/// ASCII and Unicode art visualization for grid graphs.
///
/// This provides quick, dependency-free terminal/console rendering of grid
/// graphs, which is incredibly useful for:
/// - Quick debugging and exploration of grid layouts
/// - Visualizing maze structures or obstacles
/// - Animating/displaying pathfinding search results (e.g. A* paths)
abstract final class AsciiRenderer {
  /// Converts a grid graph to an ASCII art string using simple characters (+, -, |).
  ///
  /// Optionally takes [occupants], a map of node IDs to short strings (e.g. single chars
  /// like 'S', 'E', '*') to place inside the cells.
  static String gridToString(
    GridGraph<dynamic, dynamic> grid, {
    Map<int, String> occupants = const {},
  }) {
    if (grid.rows == 0 || grid.cols == 0) return '';

    final graph = grid.graph;
    final rows = grid.rows;
    final cols = grid.cols;

    final buffer = StringBuffer();

    // Draw top border
    buffer.write('+');
    for (int c = 0; c < cols; c++) {
      buffer.write('---+');
    }
    buffer.write('\n');

    // Draw rows and their bottom borders
    for (int r = 0; r < rows; r++) {
      // 1. Draw cell row contents & vertical right walls
      buffer.write('|');
      for (int c = 0; c < cols; c++) {
        final cellId = grid.coordToId(r, c);
        final rightId = grid.coordToId(r, c + 1);

        final occupant = occupants[cellId] ?? ' ';
        // Format occupant as a single char in the middle of 3 spaces
        final formattedOccupant = occupant.length > 1
            ? occupant.substring(0, 1)
            : occupant;
        buffer.write(' $formattedOccupant ');

        final hasRightPassage =
            c < cols - 1 &&
            (graph.hasEdge(cellId, rightId) || graph.hasEdge(rightId, cellId));

        if (hasRightPassage) {
          buffer.write(' ');
        } else {
          buffer.write('|');
        }
      }
      buffer.write('\n');

      // 2. Draw horizontal walls below this row
      buffer.write('+');
      for (int c = 0; c < cols; c++) {
        final cellId = grid.coordToId(r, c);
        final belowId = grid.coordToId(r + 1, c);

        final hasBelowPassage =
            r < rows - 1 &&
            (graph.hasEdge(cellId, belowId) || graph.hasEdge(belowId, cellId));

        if (hasBelowPassage) {
          buffer.write('   +');
        } else {
          buffer.write('---+');
        }
      }
      if (r < rows - 1) {
        buffer.write('\n');
      }
    }

    return buffer.toString();
  }

  /// Converts a grid graph to a premium ASCII art string using Unicode box-drawing characters.
  ///
  /// Provides a more visual and high-fidelity rendering using characters like
  /// ┌, ─, ┬, ┼, │, etc., to render corners, walls, and intersections beautifully.
  ///
  /// Optionally takes [occupants] mapping node IDs to short occupant characters.
  static String gridToStringUnicode(
    GridGraph<dynamic, dynamic> grid, {
    Map<int, String> occupants = const {},
  }) {
    if (grid.rows == 0 || grid.cols == 0) return '';

    final graph = grid.graph;
    final rows = grid.rows;
    final cols = grid.cols;

    final buffer = StringBuffer();

    for (int r = 0; r <= rows; r++) {
      // 1. Draw intersection row (corners & horizontal walls)
      for (int c = 0; c <= cols; c++) {
        final intersection = _getUnicodeIntersection(graph, rows, cols, r, c);
        buffer.write(intersection);

        if (c < cols) {
          if (_hasHorizontalWall(graph, rows, cols, r, c)) {
            buffer.write('───');
          } else {
            buffer.write('   ');
          }
        }
      }
      buffer.write('\n');

      // 2. Draw cell row contents & vertical walls (only if r < rows)
      if (r < rows) {
        for (int c = 0; c <= cols; c++) {
          final hasWall = _hasVerticalWall(graph, rows, cols, r, c);
          buffer.write(hasWall ? '│' : ' ');

          if (c < cols) {
            final cellId = r * cols + c;
            final occupant = occupants[cellId] ?? ' ';
            final formatted = occupant.length > 1
                ? occupant.substring(0, 1)
                : occupant;
            buffer.write(' $formatted ');
          }
        }
        buffer.write('\n');
      }
    }

    // Strip trailing newline
    var result = buffer.toString();
    if (result.endsWith('\n')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  static bool _hasVerticalWall(
    SimpleGraph<dynamic, dynamic> graph,
    int rows,
    int cols,
    int r,
    int c,
  ) {
    if (c == 0 || c == cols) return true;
    final leftId = r * cols + (c - 1);
    final rightId = r * cols + c;
    final hasPassage =
        graph.hasEdge(leftId, rightId) || graph.hasEdge(rightId, leftId);
    return !hasPassage;
  }

  static bool _hasHorizontalWall(
    SimpleGraph<dynamic, dynamic> graph,
    int rows,
    int cols,
    int r,
    int c,
  ) {
    if (r == 0 || r == rows) return true;
    final aboveId = (r - 1) * cols + c;
    final belowId = r * cols + c;
    final hasPassage =
        graph.hasEdge(aboveId, belowId) || graph.hasEdge(belowId, aboveId);
    return !hasPassage;
  }

  static String _getUnicodeIntersection(
    SimpleGraph<dynamic, dynamic> graph,
    int rows,
    int cols,
    int r,
    int c,
  ) {
    final up = r > 0 && _hasVerticalWall(graph, rows, cols, r - 1, c);
    final down = r < rows && _hasVerticalWall(graph, rows, cols, r, c);
    final left = c > 0 && _hasHorizontalWall(graph, rows, cols, r, c - 1);
    final right = c < cols && _hasHorizontalWall(graph, rows, cols, r, c);

    if (up && down && left && right) return '┼';
    if (up && down && left) return '┤';
    if (up && down && right) return '├';
    if (up && left && right) return '┴';
    if (down && left && right) return '┬';
    if (up && left) return '┘';
    if (up && right) return '└';
    if (down && left) return '┐';
    if (down && right) return '┌';
    if (up && down) return '│';
    if (left && right) return '─';
    if (up) return '│';
    if (down) return '│';
    if (left) return '─';
    if (right) return '─';

    return ' ';
  }
}
