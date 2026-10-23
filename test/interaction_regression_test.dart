import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flip_chess/main.dart';
import 'package:flutter_flip_chess/dark_chess.dart';
import 'package:flutter_flip_chess/frequency/game_support.dart';

void seedProgress() {
  final game = DarkChess()..apply(const DarkMove(0, 0));
  saveMap('flip-chess.save', {
    'game': game.toJson(),
    'session': 'retained-session',
    'two': true,
    'difficulty': 1,
    'finished': false,
  });
}

Future<void> mount(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(const MyApp());
  await tester.pump();
}

void main() {
  setUp(() {
    saveMap('flip-chess.save', {});
    saveMap('results', {});
  });
  for (final height in [568.0, 844.0]) {
    for (final restored in [false, true]) {
      testWidgets(
        '390x$height keeps start/resume visible and board stable; restored=$restored',
        (tester) async {
          if (restored) seedProgress();
          await mount(tester, Size(390, height));
          final action = find.text(restored ? '继续对局' : '开始翻棋');
          expect(action.hitTestable(), findsOneWidget);
          expect(tester.getRect(action).bottom, lessThanOrEqualTo(height));
          final before = tester.getRect(find.byType(KeyboardBoard));
          await tester.tap(action);
          await tester.pump();
          expect(tester.getRect(find.byType(KeyboardBoard)), before);
          await tester.tap(find.byTooltip('暂停'));
          await tester.pump();
          expect(tester.getRect(find.byType(KeyboardBoard)), before);
          await tester.tap(find.text('继续游戏'));
          await tester.pump();
          expect(tester.getRect(find.byType(KeyboardBoard)), before);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('restored unstarted game can cancel or confirm a mode change', (
    tester,
  ) async {
    seedProgress();
    final saved = readMap('flip-chess.save')!;
    saved['two'] = false;
    saveMap('flip-chess.save', saved);
    await mount(tester, const Size(1280, 1000));
    expect(find.text('继续对局'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '同屏双人'))
          .onSelected,
      isNull,
    );
    final mode = find.text('切换模式');
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('保留进度'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(readMap('flip-chess.save'), saved);
    expect(find.text('继续对局'), findsOneWidget);
    expect(find.text('已暂停'), findsNothing);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == '开始对局后可暂停',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('确认切换模式'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(readMap('flip-chess.save')!['session'], isNot('retained-session'));
    expect(find.text('继续对局'), findsNothing);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '同屏双人'))
          .onSelected,
      isNotNull,
    );
    expect(find.text('已暂停'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel discard keeps the saved session and resumes play', (
    tester,
  ) async {
    seedProgress();
    await mount(tester, const Size(1440, 1400));
    await tester.tap(find.text('继续对局'));
    await tester.pump();
    final action = find.text('切换模式');
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(readMap('flip-chess.save')!['session'], 'retained-session');
    await tester.tap(find.text('保留进度'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('已暂停'), findsNothing);
    expect(readMap('flip-chess.save')!['session'], 'retained-session');
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate((w) => w is IconButton && w.tooltip == '暂停'),
          )
          .onPressed,
      isNotNull,
    );
    final restart = find.text('重新开始');
    await tester.ensureVisible(restart);
    await tester.tap(restart);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('保留进度'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(readMap('flip-chess.save')!['session'], 'retained-session');
    expect(find.text('已暂停'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'visible arrow focus does not scroll; clipped cell moves only enough',
    (tester) async {
      tester.view.physicalSize = const Size(500, 600);
      tester.view.devicePixelRatio = 1;
      final scroll = ScrollController();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        scroll.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: scroll,
              child: Column(
                children: [
                  const SizedBox(height: 120),
                  SizedBox(
                    width: 300,
                    child: KeyboardBoard(
                      columns: 3,
                      count: 18,
                      cell: (i, node) => OutlinedButton(
                        focusNode: node,
                        onPressed: () {},
                        child: Text('$i'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 800),
                ],
              ),
            ),
          ),
        ),
      );
      final cells = find.descendant(
        of: find.byType(KeyboardBoard),
        matching: find.byType(OutlinedButton),
      );
      tester.widget<OutlinedButton>(cells.first).focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(scroll.offset, 0);
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
      }
      expect(scroll.offset, 0, reason: 'the fourth row remains fully visible');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(scroll.offset, greaterThan(0));
      expect(
        scroll.offset,
        lessThan(100),
        reason: 'reveal only the clipped portion',
      );
      expect(tester.getRect(cells.at(13)).bottom, lessThanOrEqualTo(600.5));
      expect(tester.takeException(), isNull);
    },
  );
}
