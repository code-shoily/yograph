import 'dart:collection';
import '../aoc_helper.dart';

const sampleInput = '''
The first floor contains a hydrogen-compatible microchip and a lithium-compatible microchip.
The second floor contains a hydrogen generator.
The third floor contains a lithium generator.
The fourth floor contains nothing relevant.
''';

class State {
  final int elevator;
  final List<(int, int)> pairs;

  State(this.elevator, this.pairs);

  @override
  bool operator ==(Object other) {
    if (other is! State) return false;
    if (other.elevator != elevator) return false;
    for (var i = 0; i < pairs.length; i++) {
      if (other.pairs[i] != pairs[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(elevator, Object.hashAll(pairs));
}

void main() async {
  final (input, isSample) = await loadInput(
    year: 2016,
    day: 11,
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
  final p1Pairs = parse(lines);

  final p1 = solveSearch(State(1, p1Pairs));

  final p2Pairs = List<(int, int)>.from(p1Pairs)
    ..addAll(const [(1, 1), (1, 1)]);
  p2Pairs.sort((a, b) {
    if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
    return a.$2.compareTo(b.$2);
  });

  final p2 = solveSearch(State(1, p2Pairs));

  return (p1, p2);
}

List<(int, int)> parse(List<String> lines) {
  final generators = <String, int>{};
  final microchips = <String, int>{};

  final genRegex = RegExp(r'(\w+) generator');
  final chipRegex = RegExp(r'(\w+)-compatible microchip');

  for (var i = 0; i < lines.length; i++) {
    final floor = i + 1;
    final line = lines[i];

    for (final match in genRegex.allMatches(line)) {
      final name = match.group(1)!;
      generators[name] = floor;
    }
    for (final match in chipRegex.allMatches(line)) {
      final name = match.group(1)!;
      microchips[name] = floor;
    }
  }

  final pairs = <(int, int)>[];
  for (final name in generators.keys) {
    final mFloor = microchips[name] ?? -1;
    final gFloor = generators[name]!;
    pairs.add((mFloor, gFloor));
  }

  pairs.sort((a, b) {
    if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
    return a.$2.compareTo(b.$2);
  });

  return pairs;
}

int solveSearch(State initial) {
  final q = Queue<(State, int)>();
  q.add((initial, 0));

  final visited = <State>{};
  visited.add(initial);

  while (q.isNotEmpty) {
    final (state, dist) = q.removeFirst();

    var isGoal = true;
    for (final pair in state.pairs) {
      if (pair.$1 != 4 || pair.$2 != 4) {
        isGoal = false;
        break;
      }
    }
    if (isGoal) return dist;

    for (final succ in generateSuccessors(state)) {
      if (!visited.contains(succ)) {
        visited.add(succ);
        q.add((succ, dist + 1));
      }
    }
  }

  return -1;
}

List<State> generateSuccessors(State state) {
  final floor = state.elevator;
  final pairs = state.pairs;

  var lowestOccupied = 4;
  for (var f = 1; f <= 4; f++) {
    var occupied = false;
    for (final pair in pairs) {
      if (pair.$1 == f || pair.$2 == f) {
        occupied = true;
        break;
      }
    }
    if (occupied) {
      lowestOccupied = f;
      break;
    }
  }

  final nextFloors = <int>[];
  if (floor - 1 >= lowestOccupied) nextFloors.add(floor - 1);
  if (floor + 1 <= 4) nextFloors.add(floor + 1);

  final items = <(int, int)>[];
  for (var i = 0; i < pairs.length; i++) {
    final pair = pairs[i];
    if (pair.$1 == floor) items.add((i, 0));
    if (pair.$2 == floor) items.add((i, 1));
  }

  final moves = <List<(int, int)>>[];
  for (var i = 0; i < items.length; i++) {
    moves.add([items[i]]);
    for (var j = i + 1; j < items.length; j++) {
      moves.add([items[i], items[j]]);
    }
  }

  final successors = <State>[];
  for (final nf in nextFloors) {
    for (final move in moves) {
      final nextPairs = List<(int, int)>.from(pairs);
      for (final (idx, type) in move) {
        final pair = nextPairs[idx];
        if (type == 0) {
          nextPairs[idx] = (nf, pair.$2);
        } else {
          nextPairs[idx] = (pair.$1, nf);
        }
      }

      nextPairs.sort((a, b) {
        if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
        return a.$2.compareTo(b.$2);
      });

      if (isValid(nextPairs)) {
        successors.add(State(nf, nextPairs));
      }
    }
  }

  return successors;
}

bool isValid(List<(int, int)> pairs) {
  for (var floor = 1; floor <= 4; floor++) {
    var hasGenerator = false;
    for (final pair in pairs) {
      if (pair.$2 == floor) {
        hasGenerator = true;
        break;
      }
    }

    if (hasGenerator) {
      for (final pair in pairs) {
        if (pair.$1 == floor) {
          if (pair.$2 != floor) {
            return false;
          }
        }
      }
    }
  }
  return true;
}
