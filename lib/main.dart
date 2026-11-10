import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'device.dart';
import 'startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const C1App());
}

String tr(BuildContext context, String portuguese, String english) =>
    Localizations.localeOf(context).languageCode == 'en' ? english : portuguese;

class C1App extends StatefulWidget {
  const C1App({super.key});

  @override
  State<C1App> createState() => C1AppState();
}

class C1AppState extends State<C1App> {
  bool dark = false;
  bool contrast = false;
  bool notifications = false;
  double fontScale = 1;
  String? avatar;
  Locale? selectedLocale;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final values = await Future.wait([
        Device.getBool('dark'),
        Device.getBool('contrast'),
        Device.getBool('notifications'),
      ]);
      final savedAvatar = await Device.call<String>('getAvatar');
      if (!mounted) return;
      setState(() {
        dark = values[0];
        contrast = values[1];
        notifications = values[2];
        avatar = savedAvatar;
      });
    } on PlatformException catch (_) {
      // A interface permanece utilizável se o recurso nativo não estiver disponível.
    }
  }

  void updateBool(String key, bool value) {
    setState(() {
      if (key == 'dark') dark = value;
      if (key == 'contrast') contrast = value;
      if (key == 'notifications') notifications = value;
    });
    Device.setBool(key, value);
  }

  void updateAvatar(String? path) => setState(() => avatar = path);
  void updateFontScale(double value) => setState(() => fontScale = value);
  void updateLocale(Locale? value) => setState(() => selectedLocale = value);

  @override
  Widget build(BuildContext context) {
    final brightness = dark ? Brightness.dark : Brightness.light;
    final seed = contrast ? const Color(0xff3c00a7) : const Color(0xff5a00fb);
    final colorScheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return AppScope(
      state: this,
      child: MaterialApp(
        title: 'Aprender+',
        debugShowCheckedModeBanner: false,
        locale: selectedLocale,
        supportedLocales: const [Locale('pt'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: colorScheme,
          useMaterial3: true,
          fontFamily: 'Montserrat',
          textTheme: ThemeData(brightness: brightness).textTheme.apply(
            fontFamily: 'Montserrat',
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(fontScale)),
          child: child ?? const SizedBox.shrink(),
        ),
        home: const SplashPage(),
      ),
    );
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.state, required super.child});
  final C1AppState state;

  static C1AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.state;

  @override
  bool updateShouldNotify(AppScope oldWidget) => true;
}
