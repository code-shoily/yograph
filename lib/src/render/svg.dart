import 'dart:math' as math;
import '../model/graph_kind.dart';
import '../model/roles.dart';

/// Styling options for the SVG renderer.
class SvgOptions {
  final double width;
  final double height;
  final double padding;
  final double nodeRadius;
  final String nodeColor;
  final String nodeStroke;
  final double nodeStrokeWidth;
  final String edgeColor;
  final double edgeWidth;
  final bool showLabels;
  final String textColor;
  final double textSize;
  final double edgeSpacing;

  const SvgOptions({
    this.width = 600.0,
    this.height = 400.0,
    this.padding = 40.0,
    this.nodeRadius = 12.0,
    this.nodeColor = '#3b82f6',
    this.nodeStroke = '#1e3a8a',
    this.nodeStrokeWidth = 2.0,
    this.edgeColor = '#9ca3af',
    this.edgeWidth = 2.0,
    this.showLabels = true,
    this.textColor = 'white',
    this.textSize = 10.0,
    this.edgeSpacing = 20.0,
  });
}

/// Pure Dart SVG generator for visualizing graph layouts.
abstract final class SvgRenderer {
  SvgRenderer._();

  /// Scales node positions to fit within [width] and [height] margins.
  static Map<int, (double, double)> _scaleToPixels(
    Map<int, (double, double)> positions,
    double w,
    double h,
    double padding,
  ) {
    if (positions.isEmpty) return {};

    var minX = double.infinity;
    var maxX = double.negativeInfinity;
    var minY = double.infinity;
    var maxY = double.negativeInfinity;

    for (final pos in positions.values) {
      final (x, y) = pos;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    final wSpan = maxX - minX;
    final hSpan = maxY - minY;

    final scaled = <int, (double, double)>{};
    for (final entry in positions.entries) {
      final id = entry.key;
      final (x, y) = entry.value;

      final px = wSpan > 0
          ? padding + (x - minX) * (w - 2 * padding) / wSpan
          : w / 2.0;
      final py = hSpan > 0
          ? padding + (y - minY) * (h - 2 * padding) / hSpan
          : h / 2.0;

      scaled[id] = (px, py);
    }
    return scaled;
  }

  /// Renders a [graph] using layout [positions] to a raw SVG string.
  static String toSvg<N, E>(
    Walkable<N, E> graph,
    Map<int, (double, double)> positions, {
    SvgOptions options = const SvgOptions(),
  }) {
    final scaled = _scaleToPixels(
      positions,
      options.width,
      options.height,
      options.padding,
    );
    final directed = graph.kind == GraphKind.directed;
    final markerAttr = directed ? 'marker-end="url(#arrow)"' : '';

    final edgesSvg = <String>[];

    // Build lists of unique edges {src, dst} and group multi-edges to apply spacing
    final edgeGroups = <(int, int), List<(int, int, double)>>{};
    for (final u in graph.nodeIds) {
      for (final v in graph.successors(u)) {
        final pair = u <= v ? (u, v) : (v, u);
        edgeGroups.putIfAbsent(pair, () => []).add((
          u,
          v,
          graph.edgeWeight(u, v),
        ));
      }
    }

    for (final group in edgeGroups.values) {
      final m = group.length;
      for (var k = 0; k < m; k++) {
        final (src, dst, _) = group[k];
        final posSrc = scaled[src];
        final posDst = scaled[dst];
        if (posSrc == null || posDst == null) continue;

        final (x1, y1) = posSrc;
        final (x2, y2) = posDst;

        if (src == dst) {
          // Self-loop path using bezier curves
          final c1x = x1 - 2 * options.nodeRadius;
          final c1y = y1 - 3 * options.nodeRadius;
          final c2x = x1 + 2 * options.nodeRadius;
          final c2y = y1 - 3 * options.nodeRadius;

          var xDst = x1;
          var yDst = y1;

          if (directed) {
            final tx = -2 * options.nodeRadius;
            final ty = 3 * options.nodeRadius;
            final tLen = math.sqrt(tx * tx + ty * ty);
            if (tLen > 0) {
              xDst = x1 - tx / tLen * options.nodeRadius;
              yDst = y1 - ty / tLen * options.nodeRadius;
            }
          }

          edgesSvg.add(
            '<path d="M $x1 $y1 C $c1x $c1y, $c2x $c2y, $xDst $yDst" stroke="${options.edgeColor}" stroke-width="${options.edgeWidth}" fill="none" $markerAttr />',
          );
        } else {
          final uNode = math.min(src, dst);
          final vNode = math.max(src, dst);
          final posU = scaled[uNode]!;
          final posV = scaled[vNode]!;
          final (xU, yU) = posU;
          final (xV, yV) = posV;

          final mx = (xU + xV) / 2.0;
          final my = (yU + yV) / 2.0;
          final dx = xV - xU;
          final dy = yV - yU;
          final len = math.sqrt(dx * dx + dy * dy);

          final hk = options.edgeSpacing * (k - (m - 1) / 2.0);
          final cx = len > 0 ? mx + hk * (-dy / len) : mx;
          final cy = len > 0 ? my + hk * (dx / len) : my;

          var tx = 0.0;
          var ty = 0.0;
          if (directed) {
            if (hk.abs() < 1e-5) {
              tx = x2 - x1;
              ty = y2 - y1;
            } else {
              tx = x2 - cx;
              ty = y2 - cy;
            }
          }

          var x2New = x2;
          var y2New = y2;
          if (directed) {
            final tLen = math.sqrt(tx * tx + ty * ty);
            if (tLen > 0) {
              x2New = x2 - tx / tLen * options.nodeRadius;
              y2New = y2 - ty / tLen * options.nodeRadius;
            }
          }

          if (hk.abs() < 1e-5) {
            edgesSvg.add(
              '<path d="M $x1 $y1 L $x2New $y2New" stroke="${options.edgeColor}" stroke-width="${options.edgeWidth}" fill="none" $markerAttr />',
            );
          } else {
            edgesSvg.add(
              '<path d="M $x1 $y1 Q $cx $cy $x2New $y2New" stroke="${options.edgeColor}" stroke-width="${options.edgeWidth}" fill="none" $markerAttr />',
            );
          }
        }
      }
    }

    final nodesSvg = <String>[];
    for (final entry in scaled.entries) {
      final nodeId = entry.key;
      final (x, y) = entry.value;

      final label = options.showLabels
          ? '<text x="$x" y="${y + 4}" font-family="sans-serif" font-size="${options.textSize}" fill="${options.textColor}" font-weight="bold" text-anchor="middle">$nodeId</text>'
          : '';

      nodesSvg.add(
        '<g><circle cx="$x" cy="$y" r="${options.nodeRadius}" fill="${options.nodeColor}" stroke="${options.nodeStroke}" stroke-width="${options.nodeStrokeWidth}" />$label</g>',
      );
    }

    final defsSvg = directed
        ? '<defs><marker id="arrow" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="${options.edgeColor}" /></marker></defs>\n  '
        : '';

    return '''
<svg width="${options.width.toInt()}" height="${options.height.toInt()}" viewBox="0 0 ${options.width.toInt()} ${options.height.toInt()}" style="background-color: #f8fafc; border: 1px solid #cbd5e1; border-radius: 8px;">
  $defsSvg${edgesSvg.join('\n  ')}
  ${nodesSvg.join('\n  ')}
</svg>
'''
        .trim();
  }
}
