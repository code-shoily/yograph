import 'package:yograph/yograph.dart';

void main() {
  print('=== LOGISTICS NETWORK FLOW & MIN-CUT BOTTLENECK ANALYSIS ===\n');

  // Let's model a logistics shipping network from a Factory (source) to a Retailer (sink)
  // Nodes:
  // 0: Factory (Source)
  // 1: Transit Hub A
  // 2: Transit Hub B
  // 3: Transit Hub C
  // 4: Retail Center (Sink)

  final source = 0;
  final sink = 4;

  final network = SimpleGraph<String, double>.directed();

  // Add transit hub node names
  network.addNode(0, data: 'Factory');
  network.addNode(1, data: 'Transit Hub A');
  network.addNode(2, data: 'Transit Hub B');
  network.addNode(3, data: 'Transit Hub C');
  network.addNode(4, data: 'Retail Center');

  // Add capacities (in metric tons / day)
  network.addEdge(0, 1, data: 10.0); // Factory -> Hub A (cap 10)
  network.addEdge(0, 2, data: 15.0); // Factory -> Hub B (cap 15)
  network.addEdge(1, 3, data: 9.0); // Hub A -> Hub C (cap 9)
  network.addEdge(2, 1, data: 4.0); // Hub B -> Hub A (cap 4)
  network.addEdge(2, 3, data: 12.0); // Hub B -> Hub C (cap 12)
  network.addEdge(1, 4, data: 3.0); // Hub A -> Retail (cap 3)
  network.addEdge(3, 4, data: 17.0); // Hub C -> Retail (cap 17)

  print('Capacity Network:');
  for (final u in network.nodeIds) {
    for (final v in network.successors(u)) {
      final capacity = network.edgeData(u, v) ?? 0.0;
      final fromLabel = network.nodeData(u);
      final toLabel = network.nodeData(v);
      print('  $fromLabel -> $toLabel (Capacity: $capacity tons/day)');
    }
  }
  print('');

  // 1. Calculate Maximum Flow using Dinic's algorithm
  final maxFlowResult = MaxFlow.dinic(network, source, sink);
  print('--- Maximum Shipping Flow ---');
  print('Max Flow Volume: ${maxFlowResult.maxFlow} tons/day\n');

  print('Shipping Schedule (Optimized Flow):');
  for (final u in network.nodeIds) {
    for (final v in network.successors(u)) {
      final capacity = network.edgeData(u, v) ?? 0.0;
      // Flow sent u -> v is stored in residualGraph v -> u
      final flow = maxFlowResult.residualGraph.edgeData(v, u) ?? 0.0;
      if (flow > 0) {
        final fromLabel = network.nodeData(u);
        final toLabel = network.nodeData(v);
        print('  $fromLabel -> $toLabel: $flow / $capacity tons/day');
      }
    }
  }
  print('');

  // 2. Extract s-t Min-Cut to find the network bottleneck
  final minCutResult = MinCut.stMinCut(
    network,
    source,
    sink,
    algorithm: 'dinic',
  );
  print('--- Bottleneck Analysis (s-t Min-Cut) ---');
  print('Min-Cut Capacity Weight: ${minCutResult.cutValue} tons/day');

  final sourceSideNames = minCutResult.sourceSide
      .map((id) => network.nodeData(id))
      .toList();
  final sinkSideNames = minCutResult.sinkSide
      .map((id) => network.nodeData(id))
      .toList();

  print('Source Partition (Factory Side): $sourceSideNames');
  print('Sink Partition (Retailer Side): $sinkSideNames\n');

  // Highlight bottleneck edges crossing the cut
  print('Critical Bottleneck Connections to Expand:');
  for (final u in network.nodeIds) {
    for (final v in network.successors(u)) {
      final capacity = network.edgeData(u, v) ?? 0.0;
      if (minCutResult.sourceSide.contains(u) &&
          minCutResult.sinkSide.contains(v)) {
        final fromLabel = network.nodeData(u);
        final toLabel = network.nodeData(v);
        print(
          '  ⚠️  $fromLabel -> $toLabel (Capacity: $capacity tons/day is FULLY saturated!)',
        );
      }
    }
  }
}
