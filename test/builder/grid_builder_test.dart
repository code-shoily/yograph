import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('GridBuilder & GridGraph Tests', () {
    test('Builds basic cardinal (rook) grid graph correctly', () {
      final maze = [
        ['.', '.', '#'],
        ['.', '#', '.'],
        ['.', '.', '.'],
      ];

      final gridGraph = GridBuilder.from2DList(
        maze,
        directed: false,
        canMove: GridBuilder.walkable('.'),
      );

      expect(gridGraph.rows, equals(3));
      expect(gridGraph.cols, equals(3));
      expect(gridGraph.topologyName, equals('rook'));

      // Coordinate mapping checks
      expect(gridGraph.coordToId(0, 0), equals(0));
      expect(gridGraph.coordToId(1, 2), equals(5));
      expect(gridGraph.idToCoord(5), equals((1, 2)));

      // Out of bounds validation
      expect(gridGraph.isValidCoord(0, 0), isTrue);
      expect(gridGraph.isValidCoord(3, 1), isFalse);
      expect(gridGraph.isValidCoord(1, -1), isFalse);

      // Cell access
      expect(gridGraph.getCell(0, 0), equals('.'));
      expect(gridGraph.getCell(0, 2), equals('#'));
      expect(gridGraph.getCell(3, 3), isNull);

      // Node searching
      final wallId = gridGraph.findNode((val) => val == '#');
      expect(wallId, isNotNull);
      expect(
        gridGraph.idToCoord(wallId!),
        equals((0, 2)),
      ); // first '#' at {0, 2}

      // Check graph connectivity
      final graph = gridGraph.toGraph();
      // (0,0) is '.', (0,1) is '.', so they should be connected
      expect(graph.hasEdge(0, 1), isTrue);

      // (0,1) is '.', (0,2) is '#', they should NOT be connected due to walkable predicate
      expect(graph.hasEdge(1, 2), isFalse);
    });

    test('Custom topologies (queen, bishop, knight)', () {
      final data = [
        [1, 2],
        [3, 4],
      ];

      // Queen topology: 8-way cardinal + diagonal
      final queenGrid = GridBuilder.from2DListWithTopology(
        data,
        GridTopologies.queen,
        topologyName: 'queen',
        directed: true,
      );

      final queenGraph = queenGrid.toGraph();
      // (0,0) = ID 0, (1,1) = ID 3. Diagnol edge should exist!
      expect(queenGraph.hasEdge(0, 3), isTrue);

      // Bishop topology: diagonal only
      final bishopGrid = GridBuilder.from2DListWithTopology(
        data,
        GridTopologies.bishop,
        topologyName: 'bishop',
        directed: true,
      );

      final bishopGraph = bishopGrid.toGraph();
      expect(bishopGraph.hasEdge(0, 1), isFalse); // horizontal - no
      expect(bishopGraph.hasEdge(0, 3), isTrue); // diagonal - yes

      // Knight topology
      final knightData = [
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9],
      ];
      final knightGrid = GridBuilder.from2DListWithTopology(
        knightData,
        GridTopologies.knight,
        topologyName: 'knight',
        directed: false,
      );

      final knightGraph = knightGrid.toGraph();
      // from 0 {0,0} to 5 {1,2} is a knight jump!
      expect(knightGraph.hasEdge(0, 5), isTrue);
    });

    test('Movement predicates (walkable, avoiding, including, always)', () {
      final maze = [
        ['S', '.', '#'],
        ['.', 'E', '.'],
      ];

      // avoiding wall
      final gridAvoiding = GridBuilder.from2DList(
        maze,
        canMove: GridBuilder.avoiding('#'),
      );
      expect(gridAvoiding.toGraph().hasEdge(0, 1), isTrue); // S -> .
      expect(gridAvoiding.toGraph().hasEdge(1, 2), isFalse); // . -> #

      // including only S, E, and .
      final gridIncluding = GridBuilder.from2DList(
        maze,
        canMove: GridBuilder.including(['S', 'E', '.']),
      );
      expect(gridIncluding.toGraph().hasEdge(0, 1), isTrue); // S -> .
      expect(gridIncluding.toGraph().hasEdge(1, 2), isFalse); // . -> #
      expect(gridIncluding.toGraph().hasEdge(1, 4), isTrue); // . -> E

      // always connects everything
      final gridAlways = GridBuilder.from2DList(
        maze,
        canMove: GridBuilder.always(),
      );
      expect(
        gridAlways.toGraph().hasEdge(1, 2),
        isTrue,
      ); // connects wall as well
    });

    test('Distance heuristics', () {
      // 3 cols grid
      // ID 0 = {0,0}, ID 8 = {2,2}
      const cols = 3;
      final from = 0;
      final to = 8;

      expect(
        GridBuilder.manhattanDistance(from, to, cols),
        equals(4),
      ); // |2-0| + |2-0|
      expect(
        GridBuilder.chebyshevDistance(from, to, cols),
        equals(2),
      ); // max(|2-0|, |2-0|)
      expect(
        GridBuilder.octileDistance(from, to, cols),
        closeTo(2.8284, 0.0001), // 2 * 1.4142...
      );
    });

    // =========================================================================
    // GRID_REVIEW.md Coverage Gaps Resolution Tests
    // =========================================================================

    test('Throws ArgumentError for jagged 2D lists', () {
      expect(
        () => GridBuilder.from2DList([
          [1, 2],
          [3],
        ]),
        throwsArgumentError,
      );
    });

    test('Handles empty grids gracefully', () {
      final emptyGrid = GridBuilder.from2DList(<List<int>>[]);
      expect(emptyGrid.rows, equals(0));
      expect(emptyGrid.cols, equals(0));
      expect(emptyGrid.toGraph().nodeCount, equals(0));
    });

    test('Handles single-row and single-column grids correctly', () {
      final singleRow = GridBuilder.from2DList([
        [10, 20, 30],
      ]);
      expect(singleRow.rows, equals(1));
      expect(singleRow.cols, equals(3));
      expect(singleRow.getCell(0, 1), equals(20));

      final singleCol = GridBuilder.from2DList([
        [10],
        [20],
        [30],
      ]);
      expect(singleCol.rows, equals(3));
      expect(singleCol.cols, equals(1));
      expect(singleCol.getCell(1, 0), equals(20));
    });

    test('findNode handles nullable cells and matches null data', () {
      final grid = GridBuilder.from2DList<String?>([
        ['S', null, 'E'],
      ]);
      expect(grid.findNode((val) => val == null), equals(1));
      expect(grid.findNode((val) => val == 'E'), equals(2));
      expect(grid.findNode((val) => val == 'S'), equals(0));
    });

    test('Directed grid with canMove filtering matches directed flow', () {
      final grid = GridBuilder.from2DList(
        [
          [1, 2],
          [3, 4],
        ],
        directed: true,
        canMove: (from, to) => from < to,
      );

      final graph = grid.toGraph();
      expect(graph.hasEdge(0, 1), isTrue); // 1 -> 2
      expect(
        graph.hasEdge(1, 0),
        isFalse,
      ); // 2 -> 1 (not allowed/not directed back)
      expect(graph.hasEdge(0, 2), isTrue); // 1 -> 3
      expect(graph.hasEdge(2, 3), isTrue); // 3 -> 4
    });

    test(
      'Supports customizable edge weights based on cell values or diagonal movement',
      () {
        final grid = GridBuilder.from2DListWithTopology(
          [
            [1, 2],
            [3, 4],
          ],
          GridTopologies.queen,
          topologyName: 'queen',
          directed: true,
          edgeWeight: (from, to, fromId, toId) {
            final fr = fromId ~/ 2;
            final fc = fromId % 2;
            final tr = toId ~/ 2;
            final tc = toId % 2;
            // Diagonal moves have both row and col changes
            if (fr != tr && fc != tc) {
              return 1.414;
            }
            return 1.0;
          },
        );

        final graph = grid.toGraph();
        expect(graph.edgeData(0, 1), equals(1.0)); // cardinal (0,0) -> (0,1)
        expect(graph.edgeData(0, 3), equals(1.414)); // diagonal (0,0) -> (1,1)
      },
    );

    test('toGraph() returns identical underlying graph instance', () {
      final grid = GridBuilder.from2DList([
        [1],
      ]);
      expect(identical(grid.toGraph(), grid.graph), isTrue);
    });

    test('getCell matches manual graph changes', () {
      final grid = GridBuilder.from2DList([
        [1, 2],
      ]);
      expect(grid.getCell(0, 1), equals(2));

      // Mutate manually
      grid.toGraph().addNode(1, data: 99);
      expect(grid.getCell(0, 1), equals(99));
    });

    test(
      'LabeledBuilder.labels ignores null/invalid nodes gracefully during manual mutation',
      () {
        final baseGraph = SimpleGraph<String, int>.undirected();
        final builder = LabeledBuilder<String, int>.on(baseGraph)
          ..addEdge('A', 'B')
          ..addEdge('B', 'C');

        expect(builder.labels, containsAll(['A', 'B', 'C']));

        // Manually inject a node with a non-string or null data
        baseGraph.addNode(99, data: null);

        // Verify LabeledBuilder.labels handles nulls safely
        expect(builder.labels, isNot(contains(null)));
        expect(builder.labels, containsAll(['A', 'B', 'C']));
      },
    );
  });
}
