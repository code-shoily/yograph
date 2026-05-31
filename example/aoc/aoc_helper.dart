import 'dart:io';

/// Helper to load Advent of Code puzzle inputs.
///
/// Returns a record: `(String input, bool isSample)`.
///
/// It checks:
/// 1. The environment variable `AOC_INPUT_SRC` for a file `<year>_<day>.txt`.
/// 2. A local file fallback at `example/aoc/<year>/inputs/day<paddedDay>.txt`.
/// 3. The provided [sampleInput] string as a final fallback.
Future<(String input, bool isSample)> loadInput({
  required int year,
  required int day,
  required String sampleInput,
}) async {
  final dayStr = day.toString().padLeft(2, '0');

  // 1. Try environment variable source
  final envSrc = Platform.environment['AOC_INPUT_SRC'];
  if (envSrc != null && envSrc.isNotEmpty) {
    final envFile = File('$envSrc/${year}_$day.txt');
    if (await envFile.exists()) {
      print('Reading puzzle input from environment source: ${envFile.path}');
      return (await envFile.readAsString(), false);
    }
  }

  // 2. Try local file path fallback
  final localFile = File('example/aoc/$year/inputs/day$dayStr.txt');
  if (await localFile.exists()) {
    print('Reading puzzle input from local source: ${localFile.path}');
    return (await localFile.readAsString(), false);
  }

  // 3. Fall back to sample
  print('No input file found. Using sample input instead...');
  return (sampleInput, true);
}

/// Utility to split an input block into a list of non-empty, trimmed lines.
List<String> getLines(String input) {
  return input
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}
