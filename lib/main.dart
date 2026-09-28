import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/question_repository.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/audio_service.dart';
import 'services/iap_service.dart';
import 'services/storage_service.dart';
import 'widgets/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final storage = StorageService();
  await storage.init();
  final ads = AdService(storage);
  final iap = IapService(storage);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: storage),
        ChangeNotifierProvider.value(value: ads),
        Provider.value(value: iap),
        Provider.value(value: AudioService(storage)),
        Provider.value(value: QuestionRepository()),
      ],
      child: const IslamicQuizApp(),
    ),
  );
  // Consent + SDK init run in the background so the splash is not blocked.
  ads.init();
  iap.init();
}

class IslamicQuizApp extends StatelessWidget {
  const IslamicQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مسابقة إسلامية',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const SplashScreen(),
    );
  }
}
