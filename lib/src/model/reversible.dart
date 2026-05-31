import 'traversable.dart';

/// Contract for graphs that maintain an in-edge (predecessor) index.
///
/// This enables O(1) transpose and O(1) in-degree queries.  Algorithms
/// such as betweenness centrality, Kosaraju SCC, and k-core decomposition
/// require this capability.
abstract interface class Reversible<E> implements Traversable {
  /// Identifiers that have a directed edge pointing **to** [id].
  ///
  /// Returns an empty iterable if [id] has no incoming edges or is not
  /// present in the graph.
  Iterable<Object> predecessors(Object id);

  /// Number of incoming edges to [id].
  int inDegree(Object id);
}
