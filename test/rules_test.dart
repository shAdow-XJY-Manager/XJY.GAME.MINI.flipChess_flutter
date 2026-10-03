import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flip_chess/dark_chess.dart';

Map<String, dynamic> snapshot(DarkChess game) =>
    jsonDecode(jsonEncode(game.toJson())) as Map<String, dynamic>;

void main() {
  test('initial deck has 32 hidden pieces; first flip assigns colors', () {
    final game = DarkChess(random: Random(4));
    expect(game.board, hasLength(32));
    expect(game.board.every((p) => p != null && !p.revealed), isTrue);
    expect(game.legal, hasLength(32));
    expect(game.legal.every((m) => m.flip), isTrue);
    final color = game.board[0]!.color;
    final before = snapshot(game);
    expect(game.apply(const DarkMove(0, 1)), isFalse);
    expect(snapshot(game), before);
    expect(game.apply(const DarkMove(0, 0)), isTrue);
    expect(game.board[0]!.revealed, isTrue);
    expect(game.firstColor, color);
    expect(game.player, 1);
    expect(game.color, 1 - color);
    expect(game.history, hasLength(1));
    expect(game.quiet, 0);
  });

  test(
    'capture ranks include soldier/general exception and no friendly capture',
    () {
      DarkPiece piece(int color, int kind) =>
          DarkPiece(0, color, kind, revealed: true);
      expect(DarkChess.canCapture(piece(0, 0), piece(1, 6)), isFalse);
      expect(DarkChess.canCapture(piece(0, 6), piece(1, 0)), isTrue);
      expect(DarkChess.canCapture(piece(0, 3), piece(1, 3)), isTrue);
      expect(DarkChess.canCapture(piece(0, 4), piece(1, 3)), isFalse);
      expect(DarkChess.canCapture(piece(0, 3), piece(0, 6)), isFalse);
      expect(DarkChess.canCapture(piece(0, 5), piece(1, 6)), isFalse);
      expect(DarkChess.canCapture(piece(0, 0), DarkPiece(1, 1, 1)), isFalse);
    },
  );

  test('cannon needs exactly one screen and a revealed enemy target', () {
    final board = List<DarkPiece?>.filled(32, null);
    board[0] = DarkPiece(0, 0, 5, revealed: true);
    board[4] = DarkPiece(1, 0, 6); // A hidden screen is allowed.
    board[12] = DarkPiece(2, 1, 0, revealed: true);
    expect(DarkChess.moves(board, 0), contains(const DarkMove(0, 12)));
    board[8] = DarkPiece(3, 0, 6, revealed: true);
    expect(DarkChess.moves(board, 0), isNot(contains(const DarkMove(0, 12))));
    board[8] = null;
    board[4] = null;
    expect(DarkChess.moves(board, 0), isNot(contains(const DarkMove(0, 12))));
    board[4] = DarkPiece(1, 0, 6);
    board[12]!.revealed = false;
    expect(DarkChess.moves(board, 0), isNot(contains(const DarkMove(0, 12))));
    expect(DarkChess.adjacent(3, 4), isFalse);
  });

  test(
    'all AI levels produce legal moves without inspecting hidden identities',
    () {
      final game = DarkChess(random: Random(11));
      expect(game.apply(const DarkMove(0, 0)), isTrue);
      final altered = DarkChess.fromJson(snapshot(game))!;
      final hidden = [
        for (var i = 0; i < 32; i++)
          if (!altered.board[i]!.revealed) i,
      ];
      final first = altered.board[hidden.first];
      altered.board[hidden.first] = altered.board[hidden.last];
      altered.board[hidden.last] = first;
      for (var difficulty = 0; difficulty < 3; difficulty++) {
        final before = snapshot(game);
        final move = game.choose(difficulty, Random(23));
        expect(game.legal, contains(move));
        expect(altered.choose(difficulty, Random(23)), move);
        expect(snapshot(game), before);
      }
      for (var i = 0; i < 40 && game.result == null; i++) {
        expect(game.apply(game.choose(i % 3, Random(i))), isTrue);
        expect(DarkChess.fromJson(snapshot(game))!.toJson(), game.toJson());
      }
    },
  );

  test('save validation rejects malformed decks, identities and ranks', () {
    final game = DarkChess(random: Random(1));
    expect(DarkChess.fromJson(snapshot(game))!.toJson(), game.toJson());
    final duplicate = snapshot(game);
    (duplicate['board'] as List)[1] = (duplicate['board'] as List)[0];
    final badRank = snapshot(game);
    ((badRank['board'] as List)[0] as List)[2] = 7;
    final missing = snapshot(game);
    (missing['board'] as List)[0] = null;
    for (final bad in [
      duplicate,
      badRank,
      missing,
      {...snapshot(game), 'version': 2},
      {...snapshot(game), 'player': 2},
      {...snapshot(game), 'quiet': -1},
    ]) {
      expect(DarkChess.fromJson(bad), isNull);
    }
  });

  test('a revealed save must have an assigned first color', () {
    final game = DarkChess(random: Random(1))..apply(const DarkMove(0, 0));
    expect(DarkChess.fromJson({...snapshot(game), 'firstColor': null}), isNull);
  });

  test('repetition counts in a save must be positive', () {
    final game = DarkChess(random: Random(1));
    expect(
      DarkChess.fromJson({
        ...snapshot(game),
        'repetitions': {game.key: -1},
      }),
      isNull,
    );
  });
}
