/// Contract for querying node and edge properties.
///
/// [N] is the type of data attached to nodes; [E] is the type of data
/// attached to edges.  Either may be omitted by using `Null` or `void`.
///
/// Node IDs are strictly `int`. See [LabeledBuilder] for label-based
/// construction that auto-assigns sequential integer IDs.
abstract interface class Queryable<N, E> {
  /// Returns `true` iff [id] is a node in the graph.
  bool hasNode(int id);

  /// Data attached to node [id], or `null` if the node does not exist.
  ///
  /// Callers that need to distinguish "missing node" from "node with no
  /// data" should check [hasNode] first.
  N? nodeData(int id);

  /// Returns `true` iff a directed edge `from -> to` exists.
  bool hasEdge(int from, int to);

  /// Data attached to edge `from -> to`, or `null` if the edge does not exist.
  E? edgeData(int from, int to);

  /// Numeric weight of edge `from -> to`.
  ///
  /// Throws [StateError] if the edge does not exist.
  ///
  /// For graphs where [E] implements [num], the weight is extracted from the
  /// edge data.  Otherwise the default weight is `1.0` (unweighted).
  double edgeWeight(int from, int to);
}
