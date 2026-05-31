import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('Structure.isConnected', () {
    test('empty', () {
      expect(Structure.isConnected(SimpleGraph.undirected()), isTrue);
    });

    test('single node', () {
      expect(
        Structure.isConnected(SimpleGraph.undirected()..addNode(0)),
        isTrue,
      );
    });

    test('two connected', () {
      final g = SimpleGraph.undirected()..addEdge(0, 1);
      expect(Structure.isConnected(g), isTrue);
    });

    test('two disconnected', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addNode(2);
      expect(Structure.isConnected(g), isFalse);
    });
  });

  group('Structure.isStronglyConnected', () {
    test('directed cycle', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      g.addEdge(2, 0);
      expect(Structure.isStronglyConnected(g), isTrue);
    });

    test('directed path', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      expect(Structure.isStronglyConnected(g), isFalse);
    });
  });

  group('Structure.isWeaklyConnected', () {
    test('directed path', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      expect(Structure.isWeaklyConnected(g), isTrue);
    });

    test('directed disconnected', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(2, 3);
      expect(Structure.isWeaklyConnected(g), isFalse);
    });
  });

  group('Structure.isTree', () {
    test('path', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      expect(Structure.isTree(g), isTrue);
    });

    test('cycle', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      g.addEdge(2, 0);
      expect(Structure.isTree(g), isFalse);
    });

    test('disconnected', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addNode(2);
      expect(Structure.isTree(g), isFalse);
    });

    test('directed', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      expect(Structure.isTree(g), isFalse);
    });
  });

  group('Structure.isForest', () {
    test('two trees', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(2, 3);
      expect(Structure.isForest(g), isTrue);
    });

    test('with cycle', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      g.addEdge(2, 0);
      expect(Structure.isForest(g), isFalse);
    });
  });

  group('Structure.isArborescence', () {
    test('simple arborescence', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(0, 2);
      expect(Structure.isArborescence(g), isTrue);
      expect(Structure.arborescenceRoot(g), 0);
    });

    test('not arborescence — multiple roots', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(2, 3);
      expect(Structure.isArborescence(g), isFalse);
    });

    test('not arborescence — in-degree > 1', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(2, 1);
      expect(Structure.isArborescence(g), isFalse);
    });
  });

  group('Structure.isComplete', () {
    test('K3', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      g.addEdge(2, 0);
      expect(Structure.isComplete(g), isTrue);
    });

    test('missing edge', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addNode(2);
      expect(Structure.isComplete(g), isFalse);
    });

    test('directed K2', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(1, 0);
      expect(Structure.isComplete(g), isTrue);
    });
  });

  group('Structure.isRegular', () {
    test('3-regular', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(0, 2);
      g.addEdge(0, 3);
      g.addEdge(1, 2);
      g.addEdge(1, 3);
      g.addEdge(2, 3);
      expect(Structure.isRegular(g, 3), isTrue);
    });

    test('not regular', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      expect(Structure.isRegular(g, 1), isFalse);
    });
  });

  group('Structure.minimumDegree', () {
    test('star', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(0, 2);
      g.addEdge(0, 3);
      expect(Structure.minimumDegree(g), 1);
    });
  });

  group('Structure.isChordal', () {
    test('complete graph', () {
      final g = SimpleGraph.undirected();
      for (var i = 0; i < 4; i++) {
        for (var j = i + 1; j < 4; j++) {
          g.addEdge(i, j);
        }
      }
      expect(Structure.isChordal(g), isTrue);
    });

    test('tree', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      g.addEdge(1, 3);
      expect(Structure.isChordal(g), isTrue);
    });

    test('cycle C4', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      g.addEdge(2, 3);
      g.addEdge(3, 0);
      expect(Structure.isChordal(g), isFalse);
    });

    test('cycle C4 with chord', () {
      final g = SimpleGraph.undirected();
      g.addEdge(0, 1);
      g.addEdge(1, 2);
      g.addEdge(2, 3);
      g.addEdge(3, 0);
      g.addEdge(0, 2); // chord
      expect(Structure.isChordal(g), isTrue);
    });

    test('directed or empty boundary cases', () {
      final empty = SimpleGraph.undirected();
      expect(Structure.isChordal(empty), isTrue);

      final single = SimpleGraph.undirected()..addNode(0);
      expect(Structure.isChordal(single), isTrue);

      final dir = SimpleGraph.directed()..addEdge(0, 1);
      expect(Structure.isChordal(dir), isFalse);
    });
  });

  group('Structure.isBranching', () {
    test('valid branching', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(0, 2);
      g.addEdge(3, 4);
      expect(Structure.isBranching(g), isTrue);
    });

    test('invalid branching — cycle', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(1, 0);
      expect(Structure.isBranching(g), isFalse);
    });

    test('invalid branching — in-degree > 1', () {
      final g = SimpleGraph.directed();
      g.addEdge(0, 1);
      g.addEdge(2, 1);
      expect(Structure.isBranching(g), isFalse);
    });

    test('undirected is not branching', () {
      final g = SimpleGraph.undirected()..addEdge(0, 1);
      expect(Structure.isBranching(g), isFalse);
    });
  });

  group('Structure forest and arborescence boundary checks', () {
    test('directed forest check fails', () {
      final g = SimpleGraph.directed()..addEdge(0, 1);
      expect(Structure.isForest(g), isFalse);
    });

    test('undirected arborescence check fails', () {
      final g = SimpleGraph.undirected()..addEdge(0, 1);
      expect(Structure.isArborescence(g), isFalse);
      expect(Structure.arborescenceRoot(g), isNull);
    });

    test('empty arborescence is false', () {
      final g = SimpleGraph.directed();
      expect(Structure.isArborescence(g), isFalse);
    });

    test('directed arborescence with multiple roots', () {
      final g = SimpleGraph.directed()
        ..addNode(0)
        ..addNode(1);
      expect(Structure.arborescenceRoot(g), isNull);
    });
  });

  group('Structure regular and degree boundaries', () {
    test('directed regular', () {
      final g = SimpleGraph.directed()
        ..addEdge(0, 1)
        ..addEdge(1, 0);
      expect(Structure.isRegular(g, 2), isTrue);
    });

    test('minimumDegree directed and empty', () {
      final empty = SimpleGraph.directed();
      expect(Structure.minimumDegree(empty), 0);

      final g = SimpleGraph.directed()
        ..addEdge(0, 1)
        ..addEdge(1, 2);
      expect(
        Structure.minimumDegree(g),
        1,
      ); // node 0 has out-deg 1, node 2 has in-deg 1
    });
  });
}
