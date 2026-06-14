import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/navigation/app_navigator.dart';
import 'core/navigation/provider_scope_reset.dart';
import 'core/services/push_notification_service.dart';
import 'features/auth/view/login_screen.dart';
import 'features/home/view/main_shell.dart';
import 'features/admin/view/admin_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.initialize();
  runApp(const _AppRoot());
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  int _scopeKey = 0;

  @override
  void initState() {
    super.initState();
    registerProviderScopeReset(() {
      if (mounted) setState(() => _scopeKey++);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: ValueKey(_scopeKey),
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Thông tin NLUers',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('vi', 'VN'),
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      ),
      home: const _AppEntryGate(),
    );
  }
}

class _AppEntryGate extends StatelessWidget {
  const _AppEntryGate();

  Future<Widget> _resolveHome() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final role = (prefs.getString('role') ?? '').toUpperCase();

    if (token.isEmpty) return const LoginScreen();
    if (role == 'ADMIN') return const AdminShell();
    if (role == 'STUDENT') return const MainShell(role: 'STUDENT');
    await prefs.clear();
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolveHome(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!;
      },
    );
  }
}
