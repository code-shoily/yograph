import '../model/graph_kind.dart';
import '../model/roles.dart';
import 'dot.dart'; // For GraphSubgraph

/// Options for customizing the Mermaid output.
class MermaidOptions {
  final String direction; // e.g., 'TD', 'LR', 'BT', 'RL'
  final Set<int> highlightedNodes;
  final Set<(int, int)> highlightedEdges;
  final String Function(int node, Object? data)? nodeShape;
  final String Function(int node, Object? data)? nodeStyle;
  final String Function(int from, int to, double weight)? edgeStyle;
  final List<GraphSubgraph> subgraphs;

  const MermaidOptions({
    this.direction = 'TD',
    this.highlightedNodes = const {},
    this.highlightedEdges = const {},
    this.nodeShape,
    this.nodeStyle,
    this.edgeStyle,
    this.subgraphs = const [],
  });
}

/// Mermaid.js flowchart rendering for embedding diagrams in Markdown.
abstract final class MermaidRenderer {
  MermaidRenderer._();

  /// Converts [graph] to a Mermaid flowchart.
  static String toMermaid<N, E>(
    Walkable<N, E> graph, {
    MermaidOptions options = const MermaidOptions(),
  }) {
    final sb = StringBuffer();
    final isDirected = graph.kind == GraphKind.directed;

    sb.writeln('graph ${options.direction}');

    // Write subgraphs
    for (final subgraph in options.subgraphs) {
      sb.writeln('  subgraph ${subgraph.name} ["${subgraph.label}"]');
      for (final nodeId in subgraph.nodeIds) {
        sb.writeln('      $nodeId');
      }
      sb.writeln('  end');
    }

    // Write nodes
    final nodeStyles = <String>[];
    for (final u in graph.nodeIds) {
      final label = graph.nodeData(u)?.toString() ?? u.toString();

      // Custom shape logic:
      // default: [Label]
      var shapeOpen = '[';
      var shapeClose = ']';
      if (options.nodeShape != null) {
        final shapeName = options.nodeShape!(u, graph.nodeData(u));
        switch (shapeName) {
          case 'round':
            shapeOpen = '(';
            shapeClose = ')';
            break;
          case 'stadium':
            shapeOpen = '([';
            shapeClose = '])';
            break;
          case 'rhombus':
            shapeOpen = '{';
            shapeClose = '}';
            break;
          case 'hexagon':
            shapeOpen = '{{';
            shapeClose = '}}';
            break;
          case 'circle':
            shapeOpen = '((';
            shapeClose = '))';
            break;
        }
      }

      sb.writeln('    $u$shapeOpen"$label"$shapeClose');

      if (options.highlightedNodes.contains(u)) {
        nodeStyles.add(
          '    style $u fill:#fff9c4,stroke:#f57f17,stroke-width:2px',
        );
      } else if (options.nodeStyle != null) {
        final style = options.nodeStyle!(u, graph.nodeData(u));
        if (style.isNotEmpty) {
          nodeStyles.add('    style $u $style');
        }
      }
    }

    // Write edges
    final writtenEdges = <(int, int)>{};
    var edgeIndex = 0;

    for (final u in graph.nodeIds) {
      for (final v in graph.successors(u)) {
        if (!isDirected) {
          final edgeKey = u < v ? (u, v) : (v, u);
          if (writtenEdges.contains(edgeKey)) continue;
          writtenEdges.add(edgeKey);
        }

        final weight = graph.edgeWeight(u, v);
        // Connectors: --> (directed) or --- (undirected)
        final connector = isDirected ? '-->' : '---';

        sb.writeln('    $u $connector|"$weight"| $v');

        final isHighlighted =
            options.highlightedEdges.contains((u, v)) ||
            (!isDirected && options.highlightedEdges.contains((v, u)));

        if (isHighlighted) {
          nodeStyles.add(
            '    linkStyle $edgeIndex stroke:#d32f2f,stroke-width:3px',
          );
        } else if (options.edgeStyle != null) {
          final style = options.edgeStyle!(u, v, weight);
          if (style.isNotEmpty) {
            nodeStyles.add('    linkStyle $edgeIndex $style');
          }
        }

        edgeIndex++;
      }
    }

    for (final styleLine in nodeStyles) {
      sb.writeln(styleLine);
    }

    return sb.toString();
  }
}
