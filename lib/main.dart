import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/strings.dart';
import 'providers/app_provider.dart';
import 'screens/calendar_view.dart';
import 'screens/onboarding_screen.dart';
import 'screens/recipes_view.dart';
import 'screens/settings_view.dart';
import 'screens/shopping_lists_view.dart';
import 'screens/splash_screen.dart';
import 'screens/today_view.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await S.load();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final appProvider = AppProvider();

  runApp(
    ChangeNotifierProvider.value(
      value: appProvider,
      child: const SmakolistApp(),
    ),
  );

  unawaited(_initAppData(appProvider));
}

Future<void> _initAppData(AppProvider appProvider) async {
  unawaited(_initNotificationPlugin());
  await appProvider.init();
  try {
    final br = appProvider.breakfastReminder;
    final lr = appProvider.lunchReminder;
    final dr = appProvider.dinnerReminder;
    if (br.enabled) {
      await NotificationService.instance.scheduleBreakfast(br.time, enabled: true);
    }
    if (lr.enabled) {
      await NotificationService.instance.scheduleLunch(lr.time, enabled: true);
    }
    if (dr.enabled) {
      await NotificationService.instance.scheduleDinner(dr.time, enabled: true);
    }
  } catch (e) {
    debugPrint('NotificationService: failed to schedule on startup ($e).');
  }
}

Future<void> _initNotificationPlugin() async {
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('NotificationService: init failed on startup ($e).');
  }
}

class SmakolistApp extends StatelessWidget {
  const SmakolistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('uk', 'UA')],
      locale: const Locale('uk', 'UA'),
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'FixelText',
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          secondary: Colors.black,
          onSecondary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontFamily: 'FixelDisplay',
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Colors.black,
            height: 1.2,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'FixelDisplay',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
          titleMedium: TextStyle(
            fontFamily: 'FixelText',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'FixelText',
            fontSize: 16,
            color: Colors.black,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'FixelText',
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        dividerColor: Colors.black,
        dividerTheme: const DividerThemeData(
          color: Colors.black,
          thickness: 2,
          space: 0,
        ),
      ),
      home: Consumer<AppProvider>(
        builder: (_, provider, __) {
          if (!provider.isInitialized) {
            return const SplashScreen();
          }
          if (provider.isFirstLaunch) {
            return const OnboardingScreen();
          }
          return const MainScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 2; // default: Today
  int _calendarKey = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          CalendarView(key: ValueKey(_calendarKey)),
          const RecipesView(),
          const TodayView(),
          const ShoppingListsView(),
          const SettingsView(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 2, color: Colors.black),
          BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() {
              if (i == 0 && _index != 0) _calendarKey++;
              _index = i;
            }),
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: const Color(0xFF999999),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontFamily: 'FixelText',
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'FixelText',
              fontSize: 11,
            ),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_month_outlined),
                activeIcon: const Icon(Icons.calendar_month),
                label: S.tabCalendar,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.menu_book_outlined),
                activeIcon: const Icon(Icons.menu_book),
                label: S.tabRecipes,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.wb_sunny_outlined),
                activeIcon: const Icon(Icons.wb_sunny),
                label: S.tabToday,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.shopping_cart_outlined),
                activeIcon: const Icon(Icons.shopping_cart),
                label: S.tabShopping,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.tune_outlined),
                activeIcon: const Icon(Icons.tune),
                label: S.tabSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
