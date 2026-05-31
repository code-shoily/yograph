import 'dart:math';
import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
[#.#..#] (1,3) (3,4) (0,3,5) (1,2,3,4) (0,2,5) (0,1) (2,5) {44,35,48,43,24,44}
[#######..] (1,5,6,7,8) (2,5) (0,1,2,3,5,8) (0,1,2,5,7) (1,2,3,4,7) (3,4,6,7) (1,3,4) (1,2,3,4,6,8) (8) (0,1,2,3,4,5,6) {36,103,79,85,68,62,43,60,168}
[#..#.#..##] (0,3,4,5,6,9) (1,5,8,9) (0,5,8,9) (2,4) (0,1,3,5,6,7,8,9) (1,3,4,7,8) (1,2,4,6,7,8,9) (2,3,4,5,6,7,8,9) (1,2,3,4,6,8,9) {30,56,58,75,79,52,77,53,76,81}
[#.#.] (0,1,2,3) (0,2) {25,9,25,9}
[..##] (1,3) (0,2) (1,2,3) (0,3) (3) {22,169,31,198}
''';

class Machine {
  final int numLights;
  final int indicator;
  final List<List<int>> buttonsLists;
  final List<int> buttonsMask;
  final List<int> joltage;

  Machine({
    required this.numLights,
    required this.indicator,
    required this.buttonsLists,
    required this.buttonsMask,
    required this.joltage,
  });
}

void main() async {
  final (input, isSample) = await loadInput(
    year: 2025,
    day: 10,
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
  final machines = parse(lines);

  final p1 = machines.map(solveMachine1).reduce((a, b) => a + b);
  final p2 = machines.map(solveMachine2).reduce((a, b) => a + b);

  return (p1, p2);
}

int countSetBits(int v) {
  var count = 0;
  var temp = v;
  while (temp > 0) {
    temp &= temp - 1;
    count++;
  }
  return count;
}

int solveMachine1(Machine m) {
  // Precompute single-button states
  final states = getButtonStates(m.buttonsLists);
  final targetMask = m.indicator;

  final directPresses = states[targetMask];
  if (directPresses != null && directPresses.isNotEmpty) {
    return directPresses.map((p) => p.presses).reduce(min);
  }

  return searchMachine1Yog(m);
}

int searchMachine1Yog(Machine m) {
  final targetMask = m.indicator;
  final buttonsMask = m.buttonsMask;

  final result = AStar.implicitAStar<int>(
    from: 0,
    successors: (mask) {
      return buttonsMask.map((btn) => (mask ^ btn, 1.0));
    },
    isGoal: (mask) => mask == targetMask,
    heuristic: (mask) {
      final diff = mask ^ targetMask;
      return countSetBits(diff).toDouble();
    },
  );

  return result != null ? result.$2.toInt() : 0;
}

class ButtonComboState {
  final List<int> incV;
  final int presses;

  ButtonComboState(this.incV, this.presses);
}

int solveMachine2(Machine m) {
  final states = getButtonStates(m.buttonsLists);
  final memo = <String, int>{};
  return solveRecursive(m.joltage, states, memo);
}

int solveRecursive(
  List<int> v,
  Map<int, List<ButtonComboState>> states,
  Map<String, int> memo,
) {
  var allZero = true;
  for (final val in v) {
    if (val != 0) {
      allZero = false;
      break;
    }
  }
  if (allZero) return 0;

  final key = v.join(',');
  final cached = memo[key];
  if (cached != null) return cached;

  final res = computeRecursive(v, states, memo);
  memo[key] = res;
  return res;
}

int computeRecursive(
  List<int> v,
  Map<int, List<ButtonComboState>> states,
  Map<String, int> memo,
) {
  var targetParity = 0;
  for (var i = 0; i < v.length; i++) {
    if (v[i] % 2 == 1) {
      targetParity += (1 << i);
    }
  }

  final subsets = states[targetParity] ?? const [];
  if (subsets.isEmpty) return 1000000000;

  var minCost = 1000000000;
  for (final subset in subsets) {
    final nextV = List<int>.filled(v.length, 0);
    var valid = true;
    for (var i = 0; i < v.length; i++) {
      final diff = v[i] - subset.incV[i];
      if (diff < 0) {
        valid = false;
        break;
      }
      nextV[i] = diff ~/ 2;
    }

    if (valid) {
      final cost = subset.presses + 2 * solveRecursive(nextV, states, memo);
      if (cost < minCost) {
        minCost = cost;
      }
    }
  }

  return minCost;
}

Map<int, List<ButtonComboState>> getButtonStates(List<List<int>> buttonsLists) {
  final m = buttonsLists.length;
  final numCounters = buttonsLists.isEmpty
      ? 0
      : buttonsLists.expand((x) => x).reduce(max) + 1;

  final result = <int, List<ButtonComboState>>{};

  final limit = 1 << m;
  for (var i = 0; i < limit; i++) {
    var parity = 0;
    final incV = List<int>.filled(numCounters, 0);
    var presses = 0;

    for (var j = 0; j < m; j++) {
      if ((i & (1 << j)) != 0) {
        final btn = buttonsLists[j];
        for (final bit in btn) {
          parity ^= (1 << bit);
          incV[bit]++;
        }
        presses++;
      }
    }

    result.putIfAbsent(parity, () => []).add(ButtonComboState(incV, presses));
  }

  return result;
}

List<Machine> parse(List<String> lines) {
  final indicatorRegex = RegExp(r'\[([.#]+)\]');
  final buttonsRegex = RegExp(r'\(([\d,]+)\)');
  final joltageRegex = RegExp(r'\{([\d,]+)\}');

  final result = <Machine>[];

  for (final line in lines) {
    final clean = line.trim();
    if (clean.isEmpty) continue;

    final indicatorMatch = indicatorRegex.firstMatch(clean);
    final buttonsMatches = buttonsRegex.allMatches(clean);
    final joltageMatch = joltageRegex.firstMatch(clean);

    if (indicatorMatch != null && joltageMatch != null) {
      final indicatorStr = indicatorMatch.group(1)!;
      final numLights = indicatorStr.length;

      var indicator = 0;
      for (var i = 0; i < numLights; i++) {
        if (indicatorStr[i] == '#') {
          indicator += (1 << i);
        }
      }

      final buttonsLists = <List<int>>[];
      final buttonsMask = <int>[];

      for (final match in buttonsMatches) {
        final btnStr = match.group(1)!;
        final list = btnStr.split(',').map(int.parse).toList();
        buttonsLists.add(list);

        var mask = 0;
        for (final bit in list) {
          mask += (1 << bit);
        }
        buttonsMask.add(mask);
      }

      final joltageStr = joltageMatch.group(1)!;
      final joltage = joltageStr.split(',').map(int.parse).toList();

      result.add(
        Machine(
          numLights: numLights,
          indicator: indicator,
          buttonsLists: buttonsLists,
          buttonsMask: buttonsMask,
          joltage: joltage,
        ),
      );
    }
  }

  return result;
}
