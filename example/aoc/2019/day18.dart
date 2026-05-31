import 'dart:collection';
import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
#########
#b.A.@.a#
#########
''';

class State1 {
  final String at;
  final int collected;

  State1(this.at, this.collected);

  @override
  bool operator ==(Object other) =>
      other is State1 && other.at == at && other.collected == collected;

  @override
  int get hashCode => Object.hash(at, collected);
}

class State2 {
  final String robots;
  final int collected;

  State2(this.robots, this.collected);

  @override
  bool operator ==(Object other) =>
      other is State2 && other.robots == robots && other.collected == collected;

  @override
  int get hashCode => Object.hash(robots, collected);
}

class PoiEdge {
  final String to;
  final int dist;
  final int required;

  PoiEdge(this.to, this.dist, this.required);
}

void main() async {
  final (input, isSample) = await loadInput(
    year: 2019,
    day: 18,
    sampleInput: sampleInput,
  );
  final stopwatch = Stopwatch()..start();
  final (p1, p2) = solve(input, isSample);
  stopwatch.stop();
  print('($p1, $p2)');
  print('Solved in ${stopwatch.elapsedMilliseconds}ms');
}

(int, int) solve(String rawInput, bool isSample) {
  final lines = getLines(rawInput);
  final p1 = solvePart1(lines);
  final p2 = isSample ? 0 : solvePart2(lines);
  return (p1, p2);
}

int solvePart1(List<String> lines) {
  final grid = _parseGrid(lines);
  final pois = _findPois(grid, ['@']);
  final allKeysMask = _calculateKeysMask(pois);
  final adj = _buildPoiGraph(grid, pois);

  final initial = State1('@', 0);

  Iterable<(State1, double)> successors(State1 state) {
    final edges = adj[state.at] ?? const [];
    final next = <(State1, double)>[];

    for (final edge in edges) {
      if ((state.collected & edge.required) == edge.required &&
          (state.collected & _keyBit(edge.to)) == 0) {
        final newCollected = state.collected | _keyBit(edge.to);
        next.add((State1(edge.to, newCollected), edge.dist.toDouble()));
      }
    }

    return next;
  }

  bool isGoal(State1 state) => state.collected == allKeysMask;

  final result = AStar.implicitAStar<State1>(
    from: initial,
    successors: successors,
    isGoal: isGoal,
    heuristic: (_) => 0.0,
  );

  return result?.$2.toInt() ?? -1;
}

int solvePart2(List<String> lines) {
  var grid = _parseGrid(lines);
  grid = _modifyForPart2(grid);

  final starts = ['1', '2', '3', '4'];
  final pois = _findPois(grid, starts);
  final allKeysMask = _calculateKeysMask(pois);
  final adj = _buildPoiGraph(grid, pois);

  final initial = State2('1234', 0);

  Iterable<(State2, double)> successors(State2 state) {
    final next = <(State2, double)>[];

    for (var idx = 0; idx < 4; idx++) {
      final at = state.robots[idx];
      final edges = adj[at] ?? const [];

      for (final edge in edges) {
        if ((state.collected & edge.required) == edge.required &&
            (state.collected & _keyBit(edge.to)) == 0) {
          final newCollected = state.collected | _keyBit(edge.to);
          final newRobots =
              state.robots.substring(0, idx) +
              edge.to +
              state.robots.substring(idx + 1);
          next.add((State2(newRobots, newCollected), edge.dist.toDouble()));
        }
      }
    }

    return next;
  }

  bool isGoal(State2 state) => state.collected == allKeysMask;

  final result = AStar.implicitAStar<State2>(
    from: initial,
    successors: successors,
    isGoal: isGoal,
    heuristic: (_) => 0.0,
  );

  return result?.$2.toInt() ?? -1;
}

Map<(int, int), String> _parseGrid(List<String> lines) {
  final grid = <(int, int), String>{};
  for (var y = 0; y < lines.length; y++) {
    final line = lines[y];
    for (var x = 0; x < line.length; x++) {
      grid[(x, y)] = line[x];
    }
  }
  return grid;
}

Map<String, (int, int)> _findPois(
  Map<(int, int), String> grid,
  List<String> startChars,
) {
  final pois = <String, (int, int)>{};
  for (final entry in grid.entries) {
    final label = entry.value;
    if (startChars.contains(label) || _isKey(label)) {
      pois[label] = entry.key;
    }
  }
  return pois;
}

int _calculateKeysMask(Map<String, (int, int)> pois) {
  var mask = 0;
  for (final label in pois.keys) {
    if (_isKey(label)) {
      mask |= _keyBit(label);
    }
  }
  return mask;
}

Map<String, List<PoiEdge>> _buildPoiGraph(
  Map<(int, int), String> grid,
  Map<String, (int, int)> pois,
) {
  final adj = <String, List<PoiEdge>>{};
  for (final entry in pois.entries) {
    adj[entry.key] = _findReachableFrom(grid, entry.value);
  }
  return adj;
}

List<PoiEdge> _findReachableFrom(
  Map<(int, int), String> grid,
  (int, int) startPos,
) {
  final q = Queue<((int, int) pos, int dist, int mask)>();
  q.add((startPos, 0, 0));

  final visited = <(int, int)>{startPos};
  final acc = <PoiEdge>[];

  while (q.isNotEmpty) {
    final (pos, dist, mask) = q.removeFirst();
    final char = grid[pos]!;

    if (dist > 0 && _isKey(char)) {
      acc.add(PoiEdge(char, dist, mask));
    }

    var newMask = mask;
    if (_isDoor(char)) {
      newMask |= _doorBit(char);
    } else if (_isKey(char)) {
      newMask |= _keyBit(char);
    }

    final (x, y) = pos;
    final neighbors = [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)];
    for (final nb in neighbors) {
      final nbChar = grid[nb];
      if (nbChar != null && nbChar != '#' && !visited.contains(nb)) {
        visited.add(nb);
        q.add((nb, dist + 1, newMask));
      }
    }
  }

  return acc;
}

bool _isKey(String char) =>
    char.compareTo('a') >= 0 && char.compareTo('z') <= 0;
bool _isDoor(String char) =>
    char.compareTo('A') >= 0 && char.compareTo('Z') <= 0;

int _keyBit(String char) => 1 << (char.codeUnitAt(0) - 'a'.codeUnitAt(0));
int _doorBit(String char) => 1 << (char.codeUnitAt(0) - 'A'.codeUnitAt(0));

Map<(int, int), String> _modifyForPart2(Map<(int, int), String> grid) {
  final nextGrid = Map<(int, int), String>.from(grid);
  (int, int)? startPos;
  for (final entry in grid.entries) {
    if (entry.value == '@') {
      startPos = entry.key;
      break;
    }
  }

  if (startPos != null) {
    final (cx, cy) = startPos;
    nextGrid[(cx, cy)] = '#';
    nextGrid[(cx + 1, cy)] = '#';
    nextGrid[(cx - 1, cy)] = '#';
    nextGrid[(cx, cy + 1)] = '#';
    nextGrid[(cx, cy - 1)] = '#';
    nextGrid[(cx - 1, cy - 1)] = '1';
    nextGrid[(cx + 1, cy - 1)] = '2';
    nextGrid[(cx - 1, cy + 1)] = '3';
    nextGrid[(cx + 1, cy + 1)] = '4';
  }

  return nextGrid;
}
