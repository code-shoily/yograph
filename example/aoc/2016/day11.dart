import 'package:yograph/yograph.dart';

class Day11State {
  final int floor;
  final List<(int m, int g)> pairs;

  Day11State(this.floor, this.pairs);
}

void main() {
  final stopwatch = Stopwatch()..start();

  // Part 1 Initial configuration (derived from 2016_11.txt details)
  // Floor 1: strontium(S) G,M, plutonium(P) G,M
  // Floor 2: thulium(T) G, ruthenium(R) G,M, curium(C) G,M
  // Floor 3: thulium(T) M
  // Floor 4: -
  // We represent the 5 pairs as (m_floor, g_floor):
  final p1Initial = Day11State(
    1,
    sortPairs([
      (1, 1), // strontium
      (1, 1), // plutonium
      (3, 2), // thulium
      (2, 2), // ruthenium
      (2, 2), // curium
    ]),
  );

  final p1 = solve(p1Initial);

  // Part 2: Add Elerium and Dilithium pairs on floor 1 (m=1, g=1 for both)
  final p2Initial = Day11State(
    1,
    sortPairs([
      (1, 1), // elerium
      (1, 1), // dilithium
      ...p1Initial.pairs,
    ]),
  );

  final p2 = solve(p2Initial);

  stopwatch.stop();
  print('($p1, $p2)');
  print('Solved in ${stopwatch.elapsedMilliseconds}ms');
}

int solve(Day11State initial) {
  final result = AStar.implicitAStarBy<Day11State, String>(
    from: initial,
    successors: (state) {
      // Find lowest occupied floor to prune going back down unnecessarily
      var lowestOccupied = 4;
      for (var f = 1; f <= 4; f++) {
        var occupied = false;
        for (final p in state.pairs) {
          if (p.$1 == f || p.$2 == f) {
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
      for (final f in [state.floor - 1, state.floor + 1]) {
        if (f >= 1 && f <= 4 && f >= lowestOccupied) {
          nextFloors.add(f);
        }
      }

      final items = <(int pairIdx, bool isMicrochip)>[];
      for (var i = 0; i < state.pairs.length; i++) {
        final p = state.pairs[i];
        if (p.$1 == state.floor) {
          items.add((i, true));
        }
        if (p.$2 == state.floor) {
          items.add((i, false));
        }
      }

      final loads = <List<(int pairIdx, bool isMicrochip)>>[];
      for (final item in items) {
        loads.add([item]);
      }
      for (var i = 0; i < items.length; i++) {
        for (var j = i + 1; j < items.length; j++) {
          loads.add([items[i], items[j]]);
        }
      }

      final successorsList = <(Day11State, double)>[];
      for (final nf in nextFloors) {
        for (final load in loads) {
          final newPairs = move(state.pairs, nf, load);
          if (isValid(newPairs)) {
            successorsList.add((Day11State(nf, sortPairs(newPairs)), 1.0));
          }
        }
      }

      return successorsList;
    },
    visitedBy: (state) {
      final buffer = StringBuffer()
        ..write(state.floor)
        ..write(':');
      for (final p in state.pairs) {
        buffer.write('${p.$1},${p.$2};');
      }
      return buffer.toString();
    },
    isGoal: (state) {
      if (state.floor != 4) return false;
      for (final p in state.pairs) {
        if (p.$1 != 4 || p.$2 != 4) return false;
      }
      return true;
    },
    heuristic: (state) {
      var steps = 0;
      for (final p in state.pairs) {
        steps += (4 - p.$1) + (4 - p.$2);
      }
      return (steps / 2).ceilToDouble();
    },
  );

  return result != null ? result.$2.toInt() : 0;
}

List<(int m, int g)> sortPairs(List<(int m, int g)> pairs) {
  final list = List<(int m, int g)>.from(pairs);
  list.sort((a, b) {
    final cmpM = a.$1.compareTo(b.$1);
    if (cmpM != 0) return cmpM;
    return a.$2.compareTo(b.$2);
  });
  return list;
}

bool isValid(List<(int m, int g)> pairs) {
  for (var floor = 1; floor <= 4; floor++) {
    var hasGenerator = false;
    for (final p in pairs) {
      if (p.$2 == floor) {
        hasGenerator = true;
        break;
      }
    }

    if (hasGenerator) {
      for (final p in pairs) {
        if (p.$1 == floor && p.$2 != floor) {
          return false;
        }
      }
    }
  }
  return true;
}

List<(int m, int g)> move(
  List<(int m, int g)> pairs,
  int nextFloor,
  List<(int pairIdx, bool isMicrochip)> itemsToMove,
) {
  final newPairs = List<(int m, int g)>.from(pairs);
  for (final item in itemsToMove) {
    final p = newPairs[item.$1];
    if (item.$2) {
      newPairs[item.$1] = (nextFloor, p.$2);
    } else {
      newPairs[item.$1] = (p.$1, nextFloor);
    }
  }
  return newPairs;
}
