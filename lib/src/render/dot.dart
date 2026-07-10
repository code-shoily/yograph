import '../model/graph_kind.dart';
import '../model/roles.dart';

/// Represents a visual subgraph/cluster grouping in graph rendering.
class GraphSubgraph {
  final String name;
  final String label;
  final Set<int> nodeIds;
  final Map<String, String> attributes;

  const GraphSubgraph({
    required this.name,
    required this.label,
    required this.nodeIds,
    this.attributes = const {},
  });
}

/// Options for customizing the DOT output.
class DotOptions {
  final String graphName;
  final String? rankdir; // e.g., 'TB', 'LR', 'BT', 'RL'
  final Set<int> highlightedNodes;
  final Set<(int, int)> highlightedEdges;
  final Map<String, String> Function(int node, Object? data)? nodeAttributes;
  final Map<String, String> Function(int from, int to, double weight)?
  edgeAttributes;
  final List<GraphSubgraph> subgraphs;
  final List<List<int>> ranks;
  final Map<String, String> graphAttributes;
  final Map<String, String> nodeDefaults;
  final Map<String, String> edgeDefaults;

  const DotOptions({
    this.graphName = 'G',
    this.rankdir,
    this.highlightedNodes = const {},
    this.highlightedEdges = const {},
    this.nodeAttributes,
    this.edgeAttributes,
    this.subgraphs = const [],
    this.ranks = const [],
    this.graphAttributes = const {},
    this.nodeDefaults = const {},
    this.edgeDefaults = const {},
  });
}

/// DOT (Graphviz) format export for visualizing graphs.
abstract final class DotRenderer {
  DotRenderer._();

  /// Converts [graph] to a DOT language representation.
  static String toDot<N, E>(
    Walkable<N, E> graph, {
    DotOptions options = const DotOptions(),
  }) {
    final sb = StringBuffer();
    final isDirected = graph.kind == GraphKind.directed;

    if (isDirected) {
      sb.writeln('digraph ${options.graphName} {');
    } else {
      sb.writeln('graph ${options.graphName} {');
    }

    if (options.rankdir != null) {
      sb.writeln('  rankdir=${options.rankdir};');
    }

    // Write global graph attributes
    for (final entry in options.graphAttributes.entries) {
      sb.writeln('  ${entry.key}="${entry.value}";');
    }

    // Write node defaults
    if (options.nodeDefaults.isNotEmpty) {
      final defaultNodeAttrs = options.nodeDefaults.entries
          .map((e) => '${e.key}="${e.value}"')
          .join(', ');
      sb.writeln('  node [$defaultNodeAttrs];');
    }

    // Write edge defaults
    if (options.edgeDefaults.isNotEmpty) {
      final defaultEdgeAttrs = options.edgeDefaults.entries
          .map((e) => '${e.key}="${e.value}"')
          .join(', ');
      sb.writeln('  edge [$defaultEdgeAttrs];');
    }

    // Write subgraphs
    for (final subgraph in options.subgraphs) {
      sb.writeln('  subgraph ${subgraph.name} {');
      sb.writeln('    label="${subgraph.label}";');
      for (final attr in subgraph.attributes.entries) {
        sb.writeln('    ${attr.key}="${attr.value}";');
      }
      for (final nodeId in subgraph.nodeIds) {
        sb.writeln('    $nodeId;');
      }
      sb.writeln('  }');
    }

    // Write rank constraints
    for (final rankList in options.ranks) {
      if (rankList.isNotEmpty) {
        sb.writeln('  { rank=same; ${rankList.join('; ')}; }');
      }
    }

    // Write nodes
    for (final u in graph.nodeIds) {
      final label = graph.nodeData(u)?.toString() ?? u.toString();
      final attrs = <String, String>{'label': label};

      if (options.highlightedNodes.contains(u)) {
        attrs['color'] = 'red';
        attrs['style'] = 'filled';
        attrs['fillcolor'] = 'yellow';
      }

      if (options.nodeAttributes != null) {
        final custom = options.nodeAttributes!(u, graph.nodeData(u));
        attrs.addAll(custom);
      }

      final attrStr = attrs.entries
          .map((e) => '${e.key}="${e.value}"')
          .join(', ');
      sb.writeln('  $u [$attrStr];');
    }

    // Write edges
    final edgeOp = isDirected ? '->' : '--';
    final writtenEdges = <(int, int)>{};

    for (final u in graph.nodeIds) {
      for (final v in graph.successors(u)) {
        if (!isDirected) {
          final edgeKey = u < v ? (u, v) : (v, u);
          if (writtenEdges.contains(edgeKey)) continue;
          writtenEdges.add(edgeKey);
        }

        final weight = graph.edgeWeight(u, v);
        final attrs = <String, String>{'label': '$weight'};

        final isHighlighted =
            options.highlightedEdges.contains((u, v)) ||
            (!isDirected && options.highlightedEdges.contains((v, u)));

        if (isHighlighted) {
          attrs['color'] = 'red';
          attrs['penwidth'] = '2.0';
        }

        if (options.edgeAttributes != null) {
          final custom = options.edgeAttributes!(u, v, weight);
          attrs.addAll(custom);
        }

        final attrStr = attrs.entries
            .map((e) => '${e.key}="${e.value}"')
            .join(', ');
        sb.writeln('  $u $edgeOp $v [$attrStr];');
      }
    }

    sb.writeln('}');
    return sb.toString();
  }
}
