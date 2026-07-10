import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('GraphIO', () {
    test('edgelist roundtrip', () {
      final input = '''
A B 1.5
B C 2.0
C A 0.5
''';
      final graph = GraphIO.read(input, 'edgelist', directed: true);

      expect(graph.nodeCount, equals(3));
      expect(graph.edgeCount, equals(3));

      // Retrieve labels stored in node data
      final labels = graph.nodeIds.map((u) => graph.nodeData(u)).toSet();
      expect(labels, equals({'A', 'B', 'C'}));

      final output = GraphIO.write(graph, 'edgelist');
      final lines = output.trim().split('\n');
      expect(lines.length, equals(3));
      expect(lines, contains('A B 1.5'));
      expect(lines, contains('B C 2.0'));
      expect(lines, contains('C A 0.5'));
    });

    test('csv roundtrip', () {
      final input = '''
Source,Target,Weight
A,B,1.5
B,C,2.0
C,A,0.5
''';
      final graph = GraphIO.read(input, 'csv', directed: true);

      expect(graph.nodeCount, equals(3));
      expect(graph.edgeCount, equals(3));

      final output = GraphIO.write(graph, 'csv');
      final lines = output.trim().split('\n');
      expect(lines.length, equals(4)); // Header + 3 lines
      expect(lines[0], equals('Source,Target,Weight'));
      expect(lines.sublist(1), contains('A,B,1.5'));
      expect(lines.sublist(1), contains('B,C,2.0'));
      expect(lines.sublist(1), contains('C,A,0.5'));
    });

    test('adjlist roundtrip', () {
      final input = '''
A: B,1.5 C,2.5
B: C,2.0
C:
''';
      final graph = GraphIO.read(input, 'adjlist', directed: true);

      expect(graph.nodeCount, equals(3));
      expect(graph.edgeCount, equals(3));

      final output = GraphIO.write(graph, 'adjlist');
      final lines = output.trim().split('\n');
      expect(lines.length, equals(3));
      expect(lines, contains('A: B,1.5 C,2.5'));
      expect(lines, contains('B: C,2.0'));
      expect(lines, contains('C:'));
    });

    test('tgf roundtrip', () {
      final input = '''
A
B
C
#
A B 1.5
B C 2.0
C A 0.5
''';
      final graph = GraphIO.read(input, 'tgf', directed: true);

      expect(graph.nodeCount, equals(3));
      expect(graph.edgeCount, equals(3));

      final output = GraphIO.write(graph, 'tgf');
      final lines = output.trim().split('\n');
      expect(lines, contains('A'));
      expect(lines, contains('B'));
      expect(lines, contains('C'));
      expect(lines, contains('#'));
      expect(lines, contains('A B 1.5'));
      expect(lines, contains('B C 2.0'));
      expect(lines, contains('C A 0.5'));
    });

    test('pajek serialization', () {
      final builder = LabeledBuilder<String, double>.directed()
        ..addEdge('A', 'B', data: 1.5)
        ..addEdge('B', 'C', data: 2.0)
        ..addEdge('C', 'A', data: 0.5);

      final graph = builder.toGraph() as SimpleGraph<String, double>;
      final output = GraphIO.write(graph, 'pajek');

      expect(output, contains('*Vertices 3'));
      expect(output, contains('1 "A"'));
      expect(output, contains('2 "B"'));
      expect(output, contains('3 "C"'));
      expect(output, contains('*Arcs'));
      expect(output, contains('1 2 1.5'));
      expect(output, contains('2 3 2.0'));
      expect(output, contains('3 1 0.5'));
    });
  });
}
