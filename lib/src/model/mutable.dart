import 'graph_kind.dart';
import 'roles.dart';

/// Contract for graphs that can be modified in-place.
///
/// [addEdge] auto-creates missing endpoint nodes by default (YogEx-style
/// `add_edge_ensure`).  If you need strict behaviour, check [hasNode] first.
///
/// Node IDs are strictly `int`.
abstract interface class Mutable<N, E> implements WeightedWalkable<N, E> {
  /// Add a node with identifier [id] and optional [data].
  ///
  /// If [id] already exists its data is overwritten.
  void addNode(int id, {N? data});

  /// Remove [id] and all incident edges.
  ///
  /// Throws [ArgumentError] if [id] is not a node in the graph.
  void removeNode(int id);

  /// Add a directed edge `from -> to` with optional [data].
  ///
  /// Missing endpoint nodes are created automatically with `null` data.
  void addEdge(int from, int to, {E? data});

  /// Remove the directed edge `from -> to`.
  ///
  /// Does nothing if the edge does not exist.
  void removeEdge(int from, int to);
}

/// Function signature for creating custom mutable graph instances.
typedef GraphCreator<N, E> = Mutable<N, E> Function(GraphKind kind);

/// Helper methods for bulk creation and insertion of nodes and edges.
extension MutableBulkCreationX<N, E> on Mutable<N, E> {
  /// Adds a collection of node IDs in bulk.
  void addNodesFrom(Iterable<int> ids) {
    for (final id in ids) {
      addNode(id);
    }
  }

  /// Adds a collection of unlabelled/unweighted edges in bulk.
  ///
  /// Missing endpoint nodes are automatically created.
  void addEdgesFrom(Iterable<(int, int)> edges) {
    for (final (from, to) in edges) {
      addEdge(from, to);
    }
  }

  /// Adds a collection of edges with associated weights or data in bulk.
  ///
  /// Missing endpoint nodes are automatically created.
  void addEdgesWithDataFrom(Iterable<(int, int, E?)> edges) {
    for (final (from, to, data) in edges) {
      addEdge(from, to, data: data);
    }
  }
}
