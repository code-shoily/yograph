import 'dart:io';
import 'package:yograph/yograph.dart';

// Sample input from AoC 2015 Day 7 problem description
const sampleInput = '''
123 -> x
456 -> y
x AND y -> d
x OR y -> e
x LSHIFT 2 -> f
y RSHIFT 2 -> g
NOT x -> h
NOT y -> i
''';

class GateInstruction {
  final String op; // 'ASSIGN', 'AND', 'OR', 'LSHIFT', 'RSHIFT', 'NOT'
  final List<String> args;

  GateInstruction(this.op, this.args);

  @override
  String toString() => '$op(${args.join(', ')})';
}

void main() async {
  print('=== ADVENT OF CODE 2015 - DAY 7: SOME ASSEMBLY REQUIRED ===\n');

  // 1. Load the puzzle input (fall back to sample if file doesn't exist)
  String? rawInput;
  final envSrc = Platform.environment['AOC_INPUT_SRC'];
  if (envSrc != null && envSrc.isNotEmpty) {
    final envFile = File('$envSrc/2015_7.txt');
    if (await envFile.exists()) {
      print('Reading puzzle input from environment source: ${envFile.path}');
      rawInput = await envFile.readAsString();
    }
  }

  if (rawInput == null) {
    final localFile = File('example/aoc/2015/inputs/day07.txt');
    if (await localFile.exists()) {
      print('Reading puzzle input from local source: ${localFile.path}');
      rawInput = await localFile.readAsString();
    }
  }

  final input = rawInput ?? sampleInput;
  final isSample = rawInput == null;
  if (isSample) {
    print('No input file found. Using sample input instead...');
  }

  // 2. Parse the instructions and build the dependency graph
  // We use LabeledBuilder to map wire labels (e.g. "x", "a") to integer node IDs.
  final builder = LabeledBuilder<String, double>.directed();
  final instructions = <String, GateInstruction>{};

  final lines = input.trim().split('\n');
  for (final line in lines) {
    if (line.trim().isEmpty) continue;

    final parts = line.split(' -> ');
    final expr = parts[0].trim();
    final dest = parts[1].trim();

    GateInstruction instruction;
    if (expr.startsWith('NOT ')) {
      final arg = expr.substring(4).trim();
      instruction = GateInstruction('NOT', [arg]);
      _addDependencyEdge(builder, arg, dest);
    } else if (expr.contains(' AND ')) {
      final subParts = expr.split(' AND ');
      final arg1 = subParts[0].trim();
      final arg2 = subParts[1].trim();
      instruction = GateInstruction('AND', [arg1, arg2]);
      _addDependencyEdge(builder, arg1, dest);
      _addDependencyEdge(builder, arg2, dest);
    } else if (expr.contains(' OR ')) {
      final subParts = expr.split(' OR ');
      final arg1 = subParts[0].trim();
      final arg2 = subParts[1].trim();
      instruction = GateInstruction('OR', [arg1, arg2]);
      _addDependencyEdge(builder, arg1, dest);
      _addDependencyEdge(builder, arg2, dest);
    } else if (expr.contains(' LSHIFT ')) {
      final subParts = expr.split(' LSHIFT ');
      final arg = subParts[0].trim();
      final shift = subParts[1].trim();
      instruction = GateInstruction('LSHIFT', [arg, shift]);
      _addDependencyEdge(builder, arg, dest);
    } else if (expr.contains(' RSHIFT ')) {
      final subParts = expr.split(' RSHIFT ');
      final arg = subParts[0].trim();
      final shift = subParts[1].trim();
      instruction = GateInstruction('RSHIFT', [arg, shift]);
      _addDependencyEdge(builder, arg, dest);
    } else {
      // Direct assignment of integer or wire
      instruction = GateInstruction('ASSIGN', [expr]);
      _addDependencyEdge(builder, expr, dest);
    }

    instructions[dest] = instruction;
    builder.addNode(dest);
  }

  final graph = builder.toGraph() as SimpleGraph<String, double>;
  print(
    'Constructed Graph: ${graph.nodeCount} wires, ${graph.edgeCount} dependency edges.',
  );

  // 3. Verify that the dependency circuit contains NO cycles (Directed Acyclic Graph)
  final isDag = Cyclicity.isAcyclic(graph);
  print('Circuit is a valid DAG (No circular loops): $isDag\n');

  if (isSample) {
    // For sample input, let's output all wires
    final memo = <String, int>{};
    print('--- Evaluating Sample Wires ---');
    final wiresToEvaluate = ['d', 'e', 'f', 'g', 'h', 'i', 'x', 'y'];
    for (final wire in wiresToEvaluate) {
      if (instructions.containsKey(wire)) {
        final val = _evaluate(wire, instructions, memo);
        print('  Wire $wire: $val');
      }
    }
  } else {
    // For personal input, evaluate wire "a"
    final memoPart1 = <String, int>{};
    final signalA = _evaluate('a', instructions, memoPart1);
    print('🎯 Part 1 Result:');
    print('  Signal on wire "a": $signalA\n');

    // Part 2: Override wire "b" to have Part 1's signal, reset memo, evaluate again
    if (instructions.containsKey('b')) {
      // Override wire "b"'s instruction with a direct assignment of signalA
      instructions['b'] = GateInstruction('ASSIGN', [signalA.toString()]);

      final memoPart2 = <String, int>{};
      final newSignalA = _evaluate('a', instructions, memoPart2);
      print('🎯 Part 2 Result:');
      print('  Signal on wire "a" (after overriding b): $newSignalA');
    } else {
      print('⚠️ Wire "b" was not found in the circuit. Skipping Part 2.');
    }
  }
}

void _addDependencyEdge(
  LabeledBuilder<String, double> builder,
  String dependency,
  String dependent,
) {
  // Only add edges between wires (ignore integers)
  if (int.tryParse(dependency) == null) {
    builder.addEdge(dependency, dependent);
  }
}

int _evaluate(
  String label,
  Map<String, GateInstruction> instructions,
  Map<String, int> memo,
) {
  // 1. Raw integer check
  final parsed = int.tryParse(label);
  if (parsed != null) return parsed;

  // 2. Memoized lookup
  if (memo.containsKey(label)) return memo[label]!;

  final instruction = instructions[label];
  if (instruction == null) {
    throw StateError('Wire $label not defined in circuit');
  }

  int result;
  switch (instruction.op) {
    case 'ASSIGN':
      result = _evaluate(instruction.args[0], instructions, memo);
      break;
    case 'NOT':
      final val = _evaluate(instruction.args[0], instructions, memo);
      result = ~val;
      break;
    case 'AND':
      final val1 = _evaluate(instruction.args[0], instructions, memo);
      final val2 = _evaluate(instruction.args[1], instructions, memo);
      result = val1 & val2;
      break;
    case 'OR':
      final val1 = _evaluate(instruction.args[0], instructions, memo);
      final val2 = _evaluate(instruction.args[1], instructions, memo);
      result = val1 | val2;
      break;
    case 'LSHIFT':
      final val = _evaluate(instruction.args[0], instructions, memo);
      final shift = int.parse(instruction.args[1]);
      result = val << shift;
      break;
    case 'RSHIFT':
      final val = _evaluate(instruction.args[0], instructions, memo);
      final shift = int.parse(instruction.args[1]);
      result = val >> shift;
      break;
    default:
      throw StateError('Unknown instruction op: ${instruction.op}');
  }

  // Enforce 16-bit unsigned integer limits (0 to 65535)
  result &= 0xFFFF;
  memo[label] = result;
  return result;
}
