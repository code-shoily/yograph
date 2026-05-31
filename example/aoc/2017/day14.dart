import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = 'flqrwskx';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2017,
    day: 14,
    sampleInput: sampleInput,
  );
  final stopwatch = Stopwatch()..start();
  final (p1, p2) = solve(input.trim());
  stopwatch.stop();
  print('($p1, $p2)');
  print('Solved in ${stopwatch.elapsedMilliseconds}ms');
}

(int, int) solve(String passcode) {
  final onSet = <int>{};

  for (var r = 0; r < 128; r++) {
    final hash = _computeKnotHash('$passcode-$r');
    for (var c = 0; c < 128; c++) {
      final charIdx = c ~/ 4;
      final val = int.parse(hash[charIdx], radix: 16);
      final shift = 3 - (c % 4);
      final isSet = ((val >> shift) & 1) == 1;

      if (isSet) {
        onSet.add((r << 16) | c);
      }
    }
  }

  final p1 = onSet.length;
  final p2 = _countRegions(onSet);

  return (p1, p2);
}

int _countRegions(Set<int> onSet) {
  final graph = SimpleGraph<Null, Null>.undirected();

  for (final id in onSet) {
    graph.addNode(id);
  }

  for (final id in onSet) {
    final r = id >> 16;
    final c = id & 0xFFFF;

    final downNeighbor = ((r + 1) << 16) | c;
    final rightNeighbor = (r << 16) | (c + 1);

    if (onSet.contains(downNeighbor)) {
      graph.addEdge(id, downNeighbor);
    }
    if (onSet.contains(rightNeighbor)) {
      graph.addEdge(id, rightNeighbor);
    }
  }

  return Components.connectedComponents(graph).length;
}

String _computeKnotHash(String key) {
  final lengths = key.codeUnits.toList()..addAll(const [17, 31, 73, 47, 23]);
  final list = List<int>.generate(256, (i) => i);
  var pos = 0;
  var skip = 0;

  for (var round = 0; round < 64; round++) {
    for (final len in lengths) {
      for (var i = 0; i < len ~/ 2; i++) {
        final a = (pos + i) % 256;
        final b = (pos + len - 1 - i) % 256;
        final temp = list[a];
        list[a] = list[b];
        list[b] = temp;
      }
      pos = (pos + len + skip) % 256;
      skip++;
    }
  }

  final hash = <int>[];
  for (var i = 0; i < 16; i++) {
    var xorVal = list[i * 16];
    for (var j = 1; j < 16; j++) {
      xorVal ^= list[i * 16 + j];
    }
    hash.add(xorVal);
  }

  return hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
