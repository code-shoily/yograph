import 'traversable.dart';
import 'queryable.dart';

/// Contract for graphs that can be modified in-place.
///
/// [addEdge] auto-creates missing endpoint nodes by default (YogEx-style
/// `add_edge_ensure`).  If you need strict behaviour, check [hasNode] first.
abstract interface class Mutable<N, E> implements Traversable, Queryable<N, E> {
  /// Add a node with identifier [id] and optional [data].
  ///
  /// If [id] already exists its data is overwritten.
  void addNode(Object id, {N? data});

  /// Remove [id] and all incident edges.
  ///
  /// Throws [ArgumentError] if [id] is not a node in the graph.
  void removeNode(Object id);

  /// Add a directed edge `from -> to` with optional [data].
  ///
  /// Missing endpoint nodes are created automatically with `null` data.
  void addEdge(Object from, Object to, {E? data});

  /// Remove the directed edge `from -> to`.
  ///
  /// Does nothing if the edge does not exist.
  void removeEdge(Object from, Object to);
}
