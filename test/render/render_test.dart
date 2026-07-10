import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('DOT Renderer', () {
    test('renders simple directed graph to DOT', () {
      final g = SimpleGraph<void, double>.directed();
      g.addNode(0);
      g.addNode(1);
      g.addEdge(0, 1, data: 1.5);

      final dot = DotRenderer.toDot(
        g,
        options: const DotOptions(graphName: 'TestGraph'),
      );
      expect(dot, contains('digraph TestGraph {'));
      expect(dot, contains('0 [label="0"];'));
      expect(dot, contains('1 [label="1"];'));
      expect(dot, contains('0 -> 1 [label="1.5"];'));
    });

    test('renders with highlighted path', () {
      final g = SimpleGraph<void, double>.undirected();
      g.addEdge(0, 1, data: 2.0);

      final dot = DotRenderer.toDot(
        g,
        options: const DotOptions(
          highlightedNodes: {0},
          highlightedEdges: {(0, 1)},
        ),
      );
      expect(
        dot,
        contains(
          '0 [label="0", color="red", style="filled", fillcolor="yellow"];',
        ),
      );
      expect(
        dot,
        contains('0 -- 1 [label="2.0", color="red", penwidth="2.0"];'),
      );
    });

    test('renders subgraphs, rank constraints, and defaults', () {
      final g = SimpleGraph<void, double>.directed();
      g.addEdge(0, 1);
      g.addEdge(1, 2);

      final dot = DotRenderer.toDot(
        g,
        options: const DotOptions(
          nodeDefaults: {'shape': 'box'},
          edgeDefaults: {'color': 'gray'},
          subgraphs: [
            GraphSubgraph(
              name: 'cluster_0',
              label: 'Cluster A',
              nodeIds: {0, 1},
              attributes: {'bgcolor': 'lightgrey'},
            ),
          ],
          ranks: [
            [1, 2],
          ],
        ),
      );

      expect(dot, contains('node [shape="box"];'));
      expect(dot, contains('edge [color="gray"];'));
      expect(dot, contains('subgraph cluster_0 {'));
      expect(dot, contains('bgcolor="lightgrey";'));
      expect(dot, contains('0;'));
      expect(dot, contains('{ rank=same; 1; 2; }'));
    });
  });

  group('Mermaid Renderer', () {
    test('renders simple directed graph to Mermaid', () {
      final g = SimpleGraph<void, double>.directed();
      g.addNode(0);
      g.addNode(1);
      g.addEdge(0, 1, data: 1.5);

      final mermaid = MermaidRenderer.toMermaid(
        g,
        options: const MermaidOptions(direction: 'LR'),
      );
      expect(mermaid, contains('graph LR'));
      expect(mermaid, contains('0["0"]'));
      expect(mermaid, contains('1["1"]'));
      expect(mermaid, contains('0 -->|"1.5"| 1'));
    });

    test('renders with highlighted nodes and edges', () {
      final g = SimpleGraph<void, double>.undirected();
      g.addEdge(0, 1, data: 2.0);

      final mermaid = MermaidRenderer.toMermaid(
        g,
        options: const MermaidOptions(
          highlightedNodes: {0},
          highlightedEdges: {(0, 1)},
        ),
      );
      expect(
        mermaid,
        contains('style 0 fill:#fff9c4,stroke:#f57f17,stroke-width:2px'),
      );
      expect(mermaid, contains('linkStyle 0 stroke:#d32f2f,stroke-width:3px'));
    });

    test('renders subgraphs in Mermaid', () {
      final g = SimpleGraph<void, double>.directed();
      g.addEdge(0, 1);

      final mermaid = MermaidRenderer.toMermaid(
        g,
        options: const MermaidOptions(
          subgraphs: [
            GraphSubgraph(name: 'group_a', label: 'Group A', nodeIds: {0, 1}),
          ],
        ),
      );

      expect(mermaid, contains('subgraph group_a ["Group A"]'));
      expect(mermaid, contains('0'));
      expect(mermaid, contains('1'));
      expect(mermaid, contains('end'));
    });
  });

  group('SVG Renderer', () {
    test('renders simple graph layout to SVG XML', () {
      final g = SimpleGraph<void, double>.undirected();
      g.addEdge(0, 1, data: 1.0);

      final positions = {0: (0.1, 0.2), 1: (0.9, 0.8)};

      final svg = SvgRenderer.toSvg(
        g,
        positions,
        options: const SvgOptions(width: 800, height: 600),
      );
      expect(
        svg,
        contains('<svg width="800" height="600" viewBox="0 0 800 600"'),
      );
      expect(svg, contains('<circle cx="'));
      expect(svg, contains('<path d="M '));
    });
  });
}
