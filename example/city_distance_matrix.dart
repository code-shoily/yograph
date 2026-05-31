/// All-pairs shortest paths with Floyd-Warshall.
///
/// Computes the shortest driving distance between every pair of cities
/// in a small road network. Run with:
///   dart run example/city_distance_matrix.dart
library;

import 'dart:io';

import 'package:yograph/yograph.dart';

void main() {
  // City IDs
  const aurora = 0;
  const bluffton = 1;
  const canton = 2;
  const dayton = 3;

  final cities = ['Aurora', 'Bluffton', 'Canton', 'Dayton'];

  // Build an undirected road network with distances in miles
  final graph = SimpleGraph<String, int>.fromEdgesWithData(
    [
      (aurora, bluffton, 4),
      (aurora, canton, 2),
      (bluffton, canton, 1),
      (bluffton, dayton, 5),
      (canton, dayton, 8),
    ],
    kind: GraphKind.undirected,
  );

  // Compute all-pairs shortest paths
  final fw = FloydWarshall.allPairs(graph);

  // Print the distance matrix
  print('Distance matrix (miles):');
  print('');

  // Header
  stdout.write('          ');
  for (final name in cities) {
    stdout.write('${name.padLeft(8)}  ');
  }
  print('');

  // Rows
  for (var i = 0; i < cities.length; i++) {
    stdout.write('${cities[i].padRight(8)}  ');
    for (var j = 0; j < cities.length; j++) {
      final d = fw.distance(i, j);
      stdout.write('${(d?.toStringAsFixed(1) ?? '∞').padLeft(8)}  ');
    }
    print('');
  }

  print('');
  print(
    'Shortest distance from Aurora to Dayton: ${fw.distance(aurora, dayton)} miles',
  );
}
