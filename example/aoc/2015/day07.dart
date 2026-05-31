import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

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
  final String op;
  final List<String> args;

  GateInstruction(this.op, this.args);

  @override
  String toString() => '$op(${args.join(', ')})';
}

void main() async {
  final (input, isSample) = await loadInput(
    year: 2015,
    day: 7,
    sampleInput: sampleInput,
  );
  final (p1, p2) = solve(input, isSample);
  print('($p1, $p2)');
}

(int, int) solve(String rawInput, bool isSample) {
  final parsed = parse(rawInput);
  return (solvePart1(parsed, isSample), solvePart2(parsed, isSample));
}

Map<String, GateInstruction> parse(String input) {
  final builder = LabeledBuilder<String, double>.directed();
  final instructions = <String, GateInstruction>{};
  for (final line in getLines(input)) {
    final parts = line.split(' -> ');
    final expr = parts[0];
    final dest = parts[1];
    final GateInstruction instruction;
    final exprParts = expr.split(' ');
    switch (exprParts) {
      case ['NOT', final arg]:
        instruction = GateInstruction('NOT', [arg]);
        _addDependencyEdge(builder, arg, dest);
      case [final arg1, 'AND', final arg2]:
        instruction = GateInstruction('AND', [arg1, arg2]);
        _addDependencyEdge(builder, arg1, dest);
        _addDependencyEdge(builder, arg2, dest);
      case [final arg1, 'OR', final arg2]:
        instruction = GateInstruction('OR', [arg1, arg2]);
        _addDependencyEdge(builder, arg1, dest);
        _addDependencyEdge(builder, arg2, dest);
      case [final arg, 'LSHIFT', final shift]:
        instruction = GateInstruction('LSHIFT', [arg, shift]);
        _addDependencyEdge(builder, arg, dest);
      case [final arg, 'RSHIFT', final shift]:
        instruction = GateInstruction('RSHIFT', [arg, shift]);
        _addDependencyEdge(builder, arg, dest);
      case [final value]:
        instruction = GateInstruction('ASSIGN', [value]);
        _addDependencyEdge(builder, value, dest);
      default:
        throw FormatException('Unknown gate expression: $expr');
    }
    instructions[dest] = instruction;
    builder.addNode(dest);
  }
  return instructions;
}

int solvePart1(Map<String, GateInstruction> instructions, bool isSample) {
  final targetWire = isSample ? 'd' : 'a';
  return _evaluate(targetWire, instructions, {});
}

int solvePart2(Map<String, GateInstruction> instructions, bool isSample) {
  if (isSample) {
    return _evaluate('e', instructions, {});
  }
  final signalA = _evaluate('a', instructions, {});
  final instructionsCopy = Map<String, GateInstruction>.from(instructions);
  instructionsCopy['b'] = GateInstruction('ASSIGN', [signalA.toString()]);
  return _evaluate('a', instructionsCopy, {});
}

void _addDependencyEdge(
  LabeledBuilder<String, double> builder,
  String dependency,
  String dependent,
) {
  if (int.tryParse(dependency) == null) {
    builder.addEdge(dependency, dependent);
  }
}

int _evaluate(
  String label,
  Map<String, GateInstruction> instructions,
  Map<String, int> memo,
) {
  final parsed = int.tryParse(label);
  if (parsed != null) return parsed;
  if (memo.containsKey(label)) return memo[label]!;
  final instruction = instructions[label];
  if (instruction == null) {
    throw StateError('Wire $label not defined in circuit');
  }
  int result;
  switch (instruction.op) {
    case 'ASSIGN':
      result = _evaluate(instruction.args[0], instructions, memo);
    case 'NOT':
      final val = _evaluate(instruction.args[0], instructions, memo);
      result = ~val;
    case 'AND':
      final val1 = _evaluate(instruction.args[0], instructions, memo);
      final val2 = _evaluate(instruction.args[1], instructions, memo);
      result = val1 & val2;
    case 'OR':
      final val1 = _evaluate(instruction.args[0], instructions, memo);
      final val2 = _evaluate(instruction.args[1], instructions, memo);
      result = val1 | val2;
    case 'LSHIFT':
      final val = _evaluate(instruction.args[0], instructions, memo);
      final shift = int.parse(instruction.args[1]);
      result = val << shift;
    case 'RSHIFT':
      final val = _evaluate(instruction.args[0], instructions, memo);
      final shift = int.parse(instruction.args[1]);
      result = val >> shift;
    default:
      throw StateError('Unknown instruction op: ${instruction.op}');
  }
  result &= 0xFFFF;
  memo[label] = result;
  return result;
}
