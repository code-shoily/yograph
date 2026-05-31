import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
47|53
97|13
97|61
97|47
75|29
61|13
75|53
29|13
97|29
53|29
61|53
97|53
75|47
97|75
47|61
75|61
47|29
75|13
53|13

75,47,61,53,29
97,61,53,29,13
75,29,13
75,97,47,61,53
61,13,29
97,13,75,29,47
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2024,
    day: 5,
    sampleInput: sampleInput,
  );
  final stopwatch = Stopwatch()..start();
  final (p1, p2) = solve(input, isSample);
  stopwatch.stop();
  print('($p1, $p2)');
  print('Solved in ${stopwatch.elapsedMilliseconds}ms');
}

(int, int) solve(String rawInput, bool isSample) {
  final sections = rawInput.trim().split('\n\n');
  if (sections.length < 2) return (0, 0);

  final rulesLines = getLines(sections[0]);
  final updatesLines = getLines(sections[1]);

  final rules = <(int, int)>[];
  for (final line in rulesLines) {
    final parts = line.split('|');
    if (parts.length == 2) {
      rules.add((int.parse(parts[0].trim()), int.parse(parts[1].trim())));
    }
  }

  final updates = <List<int>>[];
  for (final line in updatesLines) {
    updates.add(line.split(',').map((s) => int.parse(s.trim())).toList());
  }

  var p1 = 0;
  var p2 = 0;

  for (final update in updates) {
    final reordered = _reorder(update, rules);
    final isCorrect = _listsEqual(update, reordered);

    final mid = reordered[reordered.length ~/ 2];
    if (isCorrect) {
      p1 += mid;
    } else {
      p2 += mid;
    }
  }

  return (p1, p2);
}

List<int> _reorder(List<int> update, List<(int, int)> rules) {
  final updateSet = update.toSet();

  final activeRules = rules.where(
    (rule) => updateSet.contains(rule.$1) && updateSet.contains(rule.$2),
  );

  final graph = SimpleGraph<int, Null>.directed();
  for (final page in update) {
    graph.addNode(page, data: page);
  }

  for (final (a, b) in activeRules) {
    graph.addEdge(a, b);
  }

  final sorted = topologicalSort(graph);
  return sorted ?? update;
}

bool _listsEqual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
