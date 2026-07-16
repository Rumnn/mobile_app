import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Controller for the sliding puzzle game logic.
///
/// Manages the puzzle board state, validates moves, tracks the move counter
/// and timer, detects the win condition, and ensures shuffles always produce
/// solvable states via the inversion-parity algorithm.
class PuzzleController extends ChangeNotifier {
  int _gridSize;
  late List<int> _tiles; // 0 = empty slot; 1..n² - 1 = numbered tiles
  int _moves = 0;
  int _elapsed = 0; // seconds
  Timer? _timer;
  bool _won = false;
  bool _started = false;

  // ── Public getters ──────────────────────────────────────────────────────

  int get gridSize => _gridSize;
  List<int> get tiles => List.unmodifiable(_tiles);
  int get moves => _moves;
  int get elapsed => _elapsed;
  bool get won => _won;
  bool get started => _started;

  String get formattedTime {
    final m = (_elapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Constructor ─────────────────────────────────────────────────────────

  PuzzleController({int gridSize = 3}) : _gridSize = gridSize {
    _initSolved();
    shuffle();
  }

  // ── Grid size switching ─────────────────────────────────────────────────

  void setGridSize(int size) {
    if (size == _gridSize) return;
    _gridSize = size;
    _stopTimer();
    _initSolved();
    shuffle();
  }

  /// Load a specific board configuration (e.g. from multiplayer server).
  /// Resets moves, timer and win-state without shuffling.
  void loadBoard(List<int> board) {
    _stopTimer();
    _tiles = List<int>.from(board);
    _moves = 0;
    _elapsed = 0;
    _won = false;
    _started = false;
    notifyListeners();
  }

  // ── Board initialisation ────────────────────────────────────────────────

  void _initSolved() {
    final n = _gridSize * _gridSize;
    _tiles = List.generate(n, (i) => (i + 1) % n); // [1,2,...,n-1,0]
  }

  // ── Shuffle with solvability guarantee ──────────────────────────────────

  void shuffle() {
    _stopTimer();
    _moves = 0;
    _elapsed = 0;
    _won = false;
    _started = false;

    final rng = Random();
    do {
      _tiles.shuffle(rng);
    } while (!_isSolvable() || _isSolved());

    notifyListeners();
  }

  /// Inversion-parity algorithm.
  ///
  /// An inversion is a pair (a, b) where a appears before b in the list but
  /// a > b, ignoring the blank (0).
  ///
  /// For odd-sized grids: solvable iff inversions is even.
  /// For even-sized grids: solvable iff (inversions + row of blank from
  /// bottom) is even.
  bool _isSolvable() {
    final n = _gridSize * _gridSize;
    int inversions = 0;
    for (int i = 0; i < n; i++) {
      if (_tiles[i] == 0) continue;
      for (int j = i + 1; j < n; j++) {
        if (_tiles[j] == 0) continue;
        if (_tiles[i] > _tiles[j]) inversions++;
      }
    }

    if (_gridSize.isOdd) {
      return inversions.isEven;
    } else {
      final blankIndex = _tiles.indexOf(0);
      final blankRowFromBottom = _gridSize - (blankIndex ~/ _gridSize);
      return (inversions + blankRowFromBottom).isEven;
    }
  }

  bool _isSolved() {
    final n = _gridSize * _gridSize;
    for (int i = 0; i < n; i++) {
      if (_tiles[i] != (i + 1) % n) return false;
    }
    return true;
  }

  // ── Tile movement ───────────────────────────────────────────────────────

  /// Returns true if the tile at [index] can slide into the empty slot
  /// (i.e. it is horizontally or vertically adjacent).
  bool canMove(int index) {
    final emptyIndex = _tiles.indexOf(0);
    final row = index ~/ _gridSize;
    final col = index % _gridSize;
    final emptyRow = emptyIndex ~/ _gridSize;
    final emptyCol = emptyIndex % _gridSize;

    return (row == emptyRow && (col - emptyCol).abs() == 1) ||
        (col == emptyCol && (row - emptyRow).abs() == 1);
  }

  /// Attempt to move the tile at [index]. Returns true if successful.
  bool moveTile(int index) {
    if (_won) return false;
    if (!canMove(index)) return false;

    final emptyIndex = _tiles.indexOf(0);

    // Swap tile with empty slot
    _tiles[emptyIndex] = _tiles[index];
    _tiles[index] = 0;
    _moves++;

    // Start timer on first move
    if (!_started) {
      _started = true;
      _startTimer();
    }

    // Check win
    if (_isSolved()) {
      _won = true;
      _stopTimer();
    }

    notifyListeners();
    return true;
  }

  // ── Timer management ────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed++;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ── Helper: compute the solved (row, col) for a given tile value ───────

  /// Returns the (row, col) where tile [value] should appear on a solved board.
  (int row, int col) solvedPosition(int value) {
    // Solved order: [1, 2, ..., n²-1, 0]
    final idx = value == 0 ? _gridSize * _gridSize - 1 : value - 1;
    return (idx ~/ _gridSize, idx % _gridSize);
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
