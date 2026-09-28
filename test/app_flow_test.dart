import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamicquiz/data/models.dart';
import 'package:islamicquiz/data/question_repository.dart';
import 'package:islamicquiz/screens/home_screen.dart';
import 'package:islamicquiz/services/ad_service.dart';
import 'package:islamicquiz/services/audio_service.dart';
import 'package:islamicquiz/services/iap_service.dart';
import 'package:islamicquiz/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Smoke test: home → category → first stage → answer a question.
/// Ads are never initialised here (no consent/SDK), so no ad widgets appear.
void main() {
  testWidgets('home, stages and a question render and respond', (tester) async {
    SharedPreferences.setMockInitialValues({'muted': true, 'vibration': false});
    final storage = StorageService();
    await storage.init();
    final repo = QuestionRepository();
    await tester.runAsync(repo.preloadAll);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: storage),
          ChangeNotifierProvider(create: (_) => AdService(storage)),
          Provider.value(value: IapService(storage)),
          Provider.value(value: AudioService(storage)),
          Provider.value(value: repo),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: HomeScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مسابقة إسلامية'), findsOneWidget);
    expect(find.text('تحدي الوقت'), findsOneWidget);

    await tester.tap(find.text(categories.first.title));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    final first = (await tester.runAsync(
      () => repo.stage(categories.first.id, 0),
    ))!.first;
    expect(find.text(first.text), findsOneWidget);

    await tester.tap(find.text(first.correct));
    await tester.pumpAndSettle();
    expect(find.text('إجابة صحيحة'), findsOneWidget);
    expect(find.text(first.explanation), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
  });
}
