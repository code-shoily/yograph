import 'roles.dart';

/// Helper to extract the edge value or return [alg.zero] if null.
E edgeValue<N, E>(
  Walkable<N, E> graph,
  int from,
  int to,
  WeightAlgebra<E> alg,
) {
  final data = graph.edgeData(from, to);
  if (data != null) return data;
  if (alg is WeightAlgebra<double>) {
    return 1.0 as E;
  }
  if (alg is WeightAlgebra<int>) {
    return 1 as E;
  }
  return alg.zero;
}

/// A ring-inspired algebra over edge weights.
///
/// Encapsulates the operations an algorithm needs to interpret edge data:
/// identity elements, weight accumulation, and ordering. This mirrors the
/// Elixir `with_zero` / `with_compare` / `with_add` protocol pattern.
///
/// Pass a [WeightAlgebra] to any weight-sensitive algorithm to use custom
/// edge data types instead of raw `double` values.
///
/// ## Example
///
/// ```dart
/// // A road segment with both distance and toll.
/// class Road {
///   final double km;
///   final double toll;
///   const Road(this.km, this.toll);
/// }
///
/// class RoadByKm implements WeightAlgebra<Road> {
///   static const instance = RoadByKm._();
///   const RoadByKm._();
///   @override Road get zero => const Road(0, 0);
///   @override Road get infinity => const Road(double.infinity, double.infinity);
///   @override Road add(Road a, Road b) => Road(a.km + b.km, a.toll + b.toll);
///   @override Road subtract(Road a, Road b) => Road(a.km - b.km, a.toll - b.toll);
///   @override int compare(Road a, Road b) => a.km.compareTo(b.km);
///   @override double toDouble(Road v) => v.km;
/// }
///
/// final path = Dijkstra.shortestPath(
///   roadGraph, 0, 5,
///   algebra: RoadByKm.instance,
/// );
/// print(path!.weight.km); // total km on shortest route
/// ```
abstract interface class WeightAlgebra<E> {
  /// The additive identity — the weight of a zero-length path.
  ///
  /// Equivalent to Elixir's `with_zero`.
  E get zero;

  /// A sentinel representing unreachable distance.
  ///
  /// Must satisfy `compare(x, infinity) < 0` for all finite [x].
  E get infinity;

  /// Combines two weights — typically addition for distances.
  ///
  /// Equivalent to Elixir's `with_add`.
  E add(E a, E b);

  /// Reverses [add] — used by Johnson's reweighting formula.
  ///
  /// Equivalent to Elixir's `with_subtract`.
  E subtract(E a, E b);

  /// Total order on weights — negative means [a] < [b].
  ///
  /// Equivalent to Elixir's `with_compare`.
  int compare(E a, E b);

  /// Converts a weight to a scalar, used by heuristic functions in A*.
  double toDouble(E value);
}

// ---------------------------------------------------------------------------
// Built-in algebras
// ---------------------------------------------------------------------------

/// Default algebra over [double].
///
/// This is the algebra used by all algorithms when no explicit [WeightAlgebra]
/// is supplied, making it a transparent drop-in for the existing API.
class DoubleAlgebra implements WeightAlgebra<double> {
  const DoubleAlgebra._();

  /// Canonical singleton — use this instead of creating new instances.
  static const DoubleAlgebra instance = DoubleAlgebra._();

  @override
  double get zero => 0.0;

  @override
  double get infinity => double.infinity;

  @override
  double add(double a, double b) => a + b;

  @override
  double subtract(double a, double b) => a - b;

  @override
  int compare(double a, double b) => a.compareTo(b);

  @override
  double toDouble(double value) => value;
}

/// Algebra over [int] weights.
class IntAlgebra implements WeightAlgebra<int> {
  const IntAlgebra._();

  /// Canonical singleton.
  static const IntAlgebra instance = IntAlgebra._();

  @override
  int get zero => 0;

  @override
  int get infinity => (1 << 62); // largest safe int

  @override
  int add(int a, int b) => a + b;

  @override
  int subtract(int a, int b) => a - b;

  @override
  int compare(int a, int b) => a.compareTo(b);

  @override
  double toDouble(int value) => value.toDouble();
}

/// Max-plus (tropical) algebra — useful for critical-path / scheduling.
///
/// Under max-plus: `add(a, b) = max(a, b)`, `zero = -∞`.
class MaxPlusAlgebra implements WeightAlgebra<double> {
  const MaxPlusAlgebra._();

  /// Canonical singleton.
  static const MaxPlusAlgebra instance = MaxPlusAlgebra._();

  @override
  double get zero => double.negativeInfinity;

  @override
  double get infinity => double.infinity;

  @override
  double add(double a, double b) => a > b ? a : b;

  @override
  double subtract(double a, double b) => a - b;

  @override
  int compare(double a, double b) => a.compareTo(b);

  @override
  double toDouble(double value) => value;
}

/// Min-plus algebra — same as [DoubleAlgebra] but explicit for clarity.
///
/// The standard shortest-path algebra: `add = +`, `zero = 0`, `compare = <`.
typedef MinPlusAlgebra = DoubleAlgebra;
