import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/notifications/fcm_service.dart';
import 'core/offline/sync_manager.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize Firebase + FCM.
  // If google-services.json is missing, Firebase.initializeApp() throws —
  // we catch it so the app launches normally without push notifications.
  try {
    await Firebase.initializeApp();
    await FcmService.initialize();
  } catch (_) {
    // Firebase not configured — push notifications disabled, app works normally
  }

  runApp(const ProviderScope(child: HivTBApp()));
}

class HivTBApp extends ConsumerWidget {
  const HivTBApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(syncManagerProvider); // starts the offline outbox flush loop
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (!next.isAuthenticated && (prev?.isAuthenticated ?? false)) {
        appRouter.go(AppRoutes.login);
      }
    });
    return MaterialApp.router(
      title: 'HIV/TB Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
