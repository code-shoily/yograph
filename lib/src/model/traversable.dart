import 'graph_kind.dart';

/// Minimal contract for any structure that can be walked as a graph.
///
/// Implementations promise only the ability to enumerate node IDs and
/// discover outgoing neighbors.  No query or mutation methods are required.
/// This is the smallest interface that BFS/DFS traversal needs.
///
/// Node IDs are strictly `int` for algorithmic efficiency (flat arrays,
/// indexed lookups, primitive-speed iteration). Use [LabeledBuilder] to
/// bridge ergonomic label-based construction to integer IDs.
abstract interface class Traversable {
  /// Whether edges are treated as directed or undirected.
  GraphKind get kind;

  /// All node identifiers currently in the graph.
  Iterable<int> get nodeIds;

  /// Identifiers reachable directly from [id] via outgoing edges.
  ///
  /// Returns an empty iterable if [id] has no outgoing edges or is not
  /// present in the graph.
  Iterable<int> successors(int id);

  /// Number of nodes in the graph.
  int get nodeCount;

  /// `true` when the graph contains no nodes.
  bool get isEmpty;
}
