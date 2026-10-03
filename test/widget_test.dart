import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flip_chess/main.dart';
import 'package:flutter_flip_chess/dark_chess.dart';
import 'package:flutter_flip_chess/frequency/game_support.dart';

Finder cells() => find.descendant(
  of: find.byType(KeyboardBoard),
  matching: find.byType(OutlinedButton),
);

void main() {
  setUp(() {
    saveMap('flip-chess.save', {});
    saveMap('results', {});
  });
  testWidgets(
    'Ready disables all 32 squares until explicit start; first flip is saved',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.pumpWidget(const MyApp());
      await tester.pump();
      expect(find.text('暗棋'), findsOneWidget);
      expect(find.text('开始翻棋'), findsOneWidget);
      expect(cells(), findsNWidgets(32));
      expect(
        tester
            .widgetList<OutlinedButton>(cells())
            .every((b) => b.onPressed == null),
        isTrue,
      );
      await tester.pump(const Duration(seconds: 2));
      expect(readMap('flip-chess.save'), isEmpty);
      await tester.tap(find.text('同屏双人'));
      await tester.pump();
      await tester.tap(find.text('开始翻棋'));
      await tester.pump();
      expect(find.text('开始翻棋'), findsNothing);
      expect(
        tester
            .widgetList<OutlinedButton>(cells())
            .every((b) => b.onPressed != null),
        isTrue,
      );
      await tester.tap(cells().first);
      await tester.pump();
      final game = DarkChess.fromJson(
        objectMap(readMap('flip-chess.save')!['game']),
      )!;
      expect(game.board.where((p) => p != null && p.revealed), hasLength(1));
      expect(game.firstColor, game.board[0]!.color);
      expect(game.player, 1);
      expect(game.history, hasLength(1));
      expect(localRecords(), isEmpty);
    },
  );
}
