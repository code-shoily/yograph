import '../model/graph_kind.dart';
import '../model/mutable.dart';
import '../simple_graph.dart';

/// Ergonomic bridge between human-readable labels and integer node IDs.
///
/// Graph algorithms are fastest with `int` IDs (flat arrays, indexed lookups,
/// primitive-speed iteration).  This builder lets you construct a graph using
/// any label type `L` (String, enum, custom object) while the underlying
/// graph implementation uses sequential integer IDs `0, 1, 2, ...`.
///
/// The original label is stored as the node's data, so you can map results
/// back to labels at any time via [Mutable.nodeData].
///
/// By default [LabeledBuilder] wraps a [SimpleGraph], but it can target
/// **any** graph implementation that implements [Mutable] via the [on]
/// factory.  This lets you use [LabeledBuilder] with custom mutable wrappers,
/// or future graph variants without modification.
///
/// ```dart
/// // Default: build on a SimpleGraph
/// final builder = LabeledBuilder<String, double>.directed()
///   ..addEdge('home', 'work', data: 10.0)
///   ..addEdge('work', 'gym', data: 5.0);
///
/// final graph = builder.toGraph(); // returns Mutable<String, double>
///
/// // Custom: build on any Mutable implementation
/// final custom = SimpleGraph<String, int>.directed();
/// final customBuilder = LabeledBuilder<String, int>.on(custom)
///   ..addEdge('A', 'B');
/// ```
class LabeledBuilder<L, E> {
  final Mutable<L, E> _graph;
  final Map<L, int> _labelToId = {};
  int _nextId = 0;

  LabeledBuilder._(this._graph);

  /// Build on a new directed [SimpleGraph].
  factory LabeledBuilder.directed() =>
      LabeledBuilder._(SimpleGraph<L, E>.directed());

  /// Build on a new undirected [SimpleGraph].
  factory LabeledBuilder.undirected() =>
      LabeledBuilder._(SimpleGraph<L, E>.undirected());

  /// Build on an existing [Mutable] graph implementation.
  ///
  /// This allows you to use [LabeledBuilder] with copy-on-write wrappers,
  /// or any future mutable variant.
  factory LabeledBuilder.on(Mutable<L, E> graph) => LabeledBuilder._(graph);

  /// Gets or creates a node ID for the given [label].
  ///
  /// IDs are assigned sequentially `0, 1, 2, ...` based on first discovery.
  /// The label is stored as the node's data.
  int ensureNode(L label) {
    final existing = _labelToId[label];
    if (existing != null) {
      return existing;
    }
    final id = _nextId++;
    _labelToId[label] = id;
    _graph.addNode(id, data: label);
    return id;
  }

  /// Explicitly adds a node with the given [label].
  ///
  /// Returns `this` for chaining.
  LabeledBuilder<L, E> addNode(L label) {
    ensureNode(label);
    return this;
  }

  /// Adds an edge between two labeled nodes, auto-creating them if needed.
  ///
  /// Returns `this` for chaining.
  LabeledBuilder<L, E> addEdge(L from, L to, {E? data}) {
    final fromId = ensureNode(from);
    final toId = ensureNode(to);
    _graph.addEdge(fromId, toId, data: data);
    return this;
  }

  /// Resolves the internal integer ID for a [label].
  ///
  /// Returns `null` if the label was never added.
  int? getId(L label) => _labelToId[label];

  /// All labels currently known to the builder, in ID order.
  Iterable<L> get labels =>
      _graph.nodeIds.map((id) => _graph.nodeData(id)).whereType<L>();

  /// Number of nodes created so far.
  int get nodeCount => _graph.nodeCount;

  /// The underlying graph being built.
  ///
  /// Safe to call multiple times — the graph is mutable and shared.
  Mutable<L, E> toGraph() => _graph;

  /// The [GraphKind] of the graph being built.
  GraphKind get kind => _graph.kind;
}
