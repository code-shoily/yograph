import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('MaxFlow Algorithms', () {
    late SimpleGraph<String, double> graph;

    setUp(() {
      // Create a classic flow network:
      // S -> A (10), S -> B (10)
      // A -> B (2), A -> T (4), B -> T (10)
      // Max Flow from S to T is 14.
      graph = SimpleGraph<String, double>.directed();
      graph.addEdge(1, 2, data: 10.0); // S -> A
      graph.addEdge(1, 3, data: 10.0); // S -> B
      graph.addEdge(2, 3, data: 2.0); // A -> B
      graph.addEdge(2, 4, data: 4.0); // A -> T
      graph.addEdge(3, 4, data: 10.0); // B -> T
    });

    test('Edmonds-Karp calculates correct maximum flow', () {
      final result = MaxFlow.edmondsKarp(graph, 1, 4);
      expect(result.maxFlow, equals(14.0));
      expect(result.source, equals(1));
      expect(result.sink, equals(4));
      expect(result.algorithm, equals('Edmonds-Karp'));

      // Check residual graph node preservation
      expect(result.residualGraph.nodeCount, equals(4));
    });

    test('Dinic calculates correct maximum flow', () {
      final result = MaxFlow.dinic(graph, 1, 4);
      expect(result.maxFlow, equals(14.0));
      expect(result.source, equals(1));
      expect(result.sink, equals(4));
      expect(result.algorithm, equals('Dinic'));
    });

    test('Push-Relabel calculates correct maximum flow', () {
      final result = MaxFlow.pushRelabel(graph, 1, 4);
      expect(result.maxFlow, equals(14.0));
      expect(result.source, equals(1));
      expect(result.sink, equals(4));
      expect(result.algorithm, equals('Push-Relabel'));
    });

    test('Extracts minimum s-t cut successfully from Dinic', () {
      final result = MaxFlow.dinic(graph, 1, 4);
      final cut = MaxFlow.extractMinCut(result);

      expect(cut.cutValue, equals(14.0));
      expect(cut.sourceSide, containsAll([1, 2, 3]));
      expect(cut.sinkSide, contains(4));
    });

    test('Extracts minimum s-t cut successfully from Edmonds-Karp', () {
      final result = MaxFlow.edmondsKarp(graph, 1, 4);
      final cut = MaxFlow.extractMinCut(result);

      expect(cut.cutValue, equals(14.0));
      expect(cut.sourceSide, containsAll([1, 2, 3]));
      expect(cut.sinkSide, contains(4));
    });

    test('Extracts minimum s-t cut successfully from Push-Relabel', () {
      final result = MaxFlow.pushRelabel(graph, 1, 4);
      final cut = MaxFlow.extractMinCut(result);

      expect(cut.cutValue, equals(14.0));
      expect(cut.sourceSide, containsAll([1, 2, 3]));
      expect(cut.sinkSide, contains(4));
    });

    test('Source equals sink handles cleanly (returns 0 flow)', () {
      final result = MaxFlow.dinic(graph, 1, 1);
      expect(result.maxFlow, equals(0.0));
      expect(result.source, equals(1));
      expect(result.sink, equals(1));
    });

    test('Unweighted graphs default to unit capacities', () {
      final unweighted = SimpleGraph<String, double>.directed();
      unweighted.addEdge(1, 2);
      unweighted.addEdge(2, 3);

      final result = MaxFlow.dinic(unweighted, 1, 3);
      expect(result.maxFlow, equals(1.0));
    });

    test('Disconnected network returns zero max flow', () {
      final disconnected = SimpleGraph<String, double>.directed();
      disconnected.addEdge(1, 2, data: 5.0);
      disconnected.addEdge(3, 4, data: 5.0); // 1-2 is disconnected from 3-4

      final result = MaxFlow.dinic(disconnected, 1, 4);
      expect(result.maxFlow, equals(0.0));

      final cut = MaxFlow.extractMinCut(result);
      expect(cut.cutValue, equals(0.0));
      expect(cut.sourceSide, containsAll([1, 2]));
      expect(cut.sinkSide, containsAll([3, 4]));
    });

    test('Throws ArgumentError for missing source or sink nodes', () {
      expect(() => MaxFlow.dinic(graph, 99, 4), throwsArgumentError);
      expect(() => MaxFlow.dinic(graph, 1, 99), throwsArgumentError);
      expect(() => MaxFlow.edmondsKarp(graph, 99, 4), throwsArgumentError);
      expect(() => MaxFlow.pushRelabel(graph, 1, 99), throwsArgumentError);
    });

    test('Throws ArgumentError for negative capacities', () {
      final negativeGraph = SimpleGraph<String, double>.directed();
      negativeGraph.addEdge(1, 2, data: -5.0);
      negativeGraph.addEdge(2, 3, data: 10.0);

      expect(() => MaxFlow.dinic(negativeGraph, 1, 3), throwsArgumentError);
      expect(
        () => MaxFlow.edmondsKarp(negativeGraph, 1, 3),
        throwsArgumentError,
      );
      expect(
        () => MaxFlow.pushRelabel(negativeGraph, 1, 3),
        throwsArgumentError,
      );
    });
  });
}
