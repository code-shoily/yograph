import '../builder/labeled_builder.dart';
import '../model/graph_kind.dart';
import '../simple_graph.dart';

/// I/O utilities for loading and dumping graphs in common formats.
abstract final class GraphIO {
  GraphIO._();

  /// Loads a graph from [content] in the specified [format].
  ///
  /// Supported formats: `edgelist`, `csv`, `adjlist`, `tgf`.
  static SimpleGraph<String, double> read(
    String content,
    String format, {
    bool directed = true,
  }) {
    switch (format.toLowerCase()) {
      case 'edgelist':
        return readEdgelist(content, directed: directed);
      case 'csv':
        return readCsv(content, directed: directed);
      case 'adjlist':
        return readAdjlist(content, directed: directed);
      case 'tgf':
        return readTgf(content, directed: directed);
      default:
        throw ArgumentError('Unsupported format: $format');
    }
  }

  /// Dumps [graph] to a string in the specified [format].
  ///
  /// Supported formats: `edgelist`, `csv`, `adjlist`, `tgf`, `pajek`.
  static String write(SimpleGraph<String, double> graph, String format) {
    switch (format.toLowerCase()) {
      case 'edgelist':
        return writeEdgelist(graph);
      case 'csv':
        return writeCsv(graph);
      case 'adjlist':
        return writeAdjlist(graph);
      case 'tgf':
        return writeTgf(graph);
      case 'pajek':
        return writePajek(graph);
      default:
        throw ArgumentError('Unsupported format: $format');
    }
  }

  /// Reads a graph from an edge list format.
  ///
  /// Each line represents an edge: `from_node to_node [weight]`.
  static SimpleGraph<String, double> readEdgelist(
    String content, {
    bool directed = true,
  }) {
    final builder = directed
        ? LabeledBuilder<String, double>.directed()
        : LabeledBuilder<String, double>.undirected();

    final lines = content.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith('//')) {
        continue;
      }
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final from = parts[0];
        final to = parts[1];
        var weight = 1.0;
        if (parts.length >= 3) {
          weight = double.tryParse(parts[2]) ?? 1.0;
        }
        builder.addEdge(from, to, data: weight);
      }
    }
    return builder.toGraph() as SimpleGraph<String, double>;
  }

  /// Reads a graph from a CSV format.
  ///
  /// Each line represents an edge: `source,target,[weight]`.
  static SimpleGraph<String, double> readCsv(
    String content, {
    bool directed = true,
  }) {
    final builder = directed
        ? LabeledBuilder<String, double>.directed()
        : LabeledBuilder<String, double>.undirected();

    final lines = content.split('\n');
    var isFirst = true;
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      final parts = line.split(',');
      if (isFirst) {
        isFirst = false;
        // Check for headers (Source, Target, Weight / from, to, weight)
        if (parts.isNotEmpty &&
            (parts[0].toLowerCase() == 'source' ||
                parts[0].toLowerCase() == 'from')) {
          continue;
        }
      }
      if (parts.length >= 2) {
        final from = parts[0].trim();
        final to = parts[1].trim();
        var weight = 1.0;
        if (parts.length >= 3) {
          weight = double.tryParse(parts[2].trim()) ?? 1.0;
        }
        builder.addEdge(from, to, data: weight);
      }
    }
    return builder.toGraph() as SimpleGraph<String, double>;
  }

  /// Reads a graph from an adjacency list format.
  ///
  /// E.g.: `A: B,1.5 C,2.0`
  static SimpleGraph<String, double> readAdjlist(
    String content, {
    bool directed = true,
  }) {
    final builder = directed
        ? LabeledBuilder<String, double>.directed()
        : LabeledBuilder<String, double>.undirected();

    final lines = content.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith('//')) {
        continue;
      }

      final colonIdx = line.indexOf(':');
      if (colonIdx == -1) {
        final node = line.trim();
        if (node.isNotEmpty) {
          builder.ensureNode(node);
        }
        continue;
      }

      final from = line.substring(0, colonIdx).trim();
      builder.ensureNode(from);

      final neighborsPart = line.substring(colonIdx + 1).trim();
      if (neighborsPart.isEmpty) continue;

      final neighbors = neighborsPart.split(RegExp(r'\s+'));
      for (final neighbor in neighbors) {
        final parts = neighbor.split(',');
        final to = parts[0].trim();
        if (to.isEmpty) continue;
        var weight = 1.0;
        if (parts.length >= 2) {
          weight = double.tryParse(parts[1].trim()) ?? 1.0;
        }
        builder.addEdge(from, to, data: weight);
      }
    }
    return builder.toGraph() as SimpleGraph<String, double>;
  }

  /// Reads a graph from a Trivial Graph Format (TGF).
  ///
  /// E.g.:
  /// ```
  /// Node1
  /// Node2
  /// #
  /// Node1 Node2 1.5
  /// ```
  static SimpleGraph<String, double> readTgf(
    String content, {
    bool directed = true,
  }) {
    final builder = directed
        ? LabeledBuilder<String, double>.directed()
        : LabeledBuilder<String, double>.undirected();

    final lines = content.split('\n');
    var inEdges = false;
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (line == '#') {
        inEdges = true;
        continue;
      }
      if (!inEdges) {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.isNotEmpty) {
          builder.ensureNode(parts[0]);
        }
      } else {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final from = parts[0];
          final to = parts[1];
          var weight = 1.0;
          if (parts.length >= 3) {
            weight = double.tryParse(parts[2]) ?? 1.0;
          }
          builder.addEdge(from, to, data: weight);
        }
      }
    }
    return builder.toGraph() as SimpleGraph<String, double>;
  }

  /// Serializes [graph] in edgelist format.
  static String writeEdgelist(SimpleGraph<String, double> graph) {
    final sb = StringBuffer();
    for (final u in graph.nodeIds) {
      final fromLabel = graph.nodeData(u) ?? u.toString();
      for (final v in graph.successors(u)) {
        final toLabel = graph.nodeData(v) ?? v.toString();
        final weight = graph.edgeWeight(u, v);
        sb.writeln('$fromLabel $toLabel $weight');
      }
    }
    return sb.toString();
  }

  /// Serializes [graph] in CSV format.
  static String writeCsv(SimpleGraph<String, double> graph) {
    final sb = StringBuffer();
    sb.writeln('Source,Target,Weight');
    for (final u in graph.nodeIds) {
      final fromLabel = graph.nodeData(u) ?? u.toString();
      for (final v in graph.successors(u)) {
        final toLabel = graph.nodeData(v) ?? v.toString();
        final weight = graph.edgeWeight(u, v);
        sb.writeln('$fromLabel,$toLabel,$weight');
      }
    }
    return sb.toString();
  }

  /// Serializes [graph] in adjacency list format.
  static String writeAdjlist(SimpleGraph<String, double> graph) {
    final sb = StringBuffer();
    for (final u in graph.nodeIds) {
      final fromLabel = graph.nodeData(u) ?? u.toString();
      sb.write('$fromLabel:');
      final successors = graph.successors(u).toList();
      if (successors.isNotEmpty) {
        final neighbors = successors
            .map((v) {
              final toLabel = graph.nodeData(v) ?? v.toString();
              final weight = graph.edgeWeight(u, v);
              return '$toLabel,$weight';
            })
            .join(' ');
        sb.write(' $neighbors');
      }
      sb.writeln();
    }
    return sb.toString();
  }

  /// Serializes [graph] in Trivial Graph Format (TGF).
  static String writeTgf(SimpleGraph<String, double> graph) {
    final sb = StringBuffer();
    for (final u in graph.nodeIds) {
      final label = graph.nodeData(u) ?? u.toString();
      sb.writeln(label);
    }
    sb.writeln('#');
    for (final u in graph.nodeIds) {
      final fromLabel = graph.nodeData(u) ?? u.toString();
      for (final v in graph.successors(u)) {
        final toLabel = graph.nodeData(v) ?? v.toString();
        final weight = graph.edgeWeight(u, v);
        sb.writeln('$fromLabel $toLabel $weight');
      }
    }
    return sb.toString();
  }

  /// Serializes [graph] in Pajek format.
  static String writePajek(SimpleGraph<String, double> graph) {
    final sb = StringBuffer();
    final nodeCount = graph.nodeCount;
    sb.writeln('*Vertices $nodeCount');

    final idMap = <int, int>{};
    var nextPajekId = 1;
    for (final u in graph.nodeIds) {
      idMap[u] = nextPajekId;
      final label = graph.nodeData(u) ?? u.toString();
      sb.writeln('$nextPajekId "$label"');
      nextPajekId++;
    }

    if (graph.kind == GraphKind.directed) {
      sb.writeln('*Arcs');
    } else {
      sb.writeln('*Edges');
    }

    for (final u in graph.nodeIds) {
      final fromPajekId = idMap[u]!;
      for (final v in graph.successors(u)) {
        final toPajekId = idMap[v]!;
        if (graph.kind == GraphKind.directed || u < v) {
          final weight = graph.edgeWeight(u, v);
          sb.writeln('$fromPajekId $toPajekId $weight');
        }
      }
    }
    return sb.toString();
  }
}
