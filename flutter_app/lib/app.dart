import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/constants/app_constants.dart';
import 'core/storage/preferences_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/context/presentation/bloc/active_context_cubit.dart';
import 'features/context/presentation/bloc/active_context_state.dart';
import 'features/context/presentation/screens/setup_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/learn/data/repositories/learn_repository.dart';

import 'features/settings/presentation/bloc/language_cubit.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shiksha_saathi/l10n/app_localizations.dart';

/// Main Application Widget for Shiksha Saathi
class ShikshaSaathiApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const ShikshaSaathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Initialize Notification Service with navigator key
    NotificationService().setNavigatorKey(navigatorKey);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (_) => AuthRepository(),
        ),
        RepositoryProvider<PreferencesRepository>(
          create: (_) => PreferencesRepository(),
        ),
        RepositoryProvider<LearnRepository>(
          create: (_) => LearnRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(const AuthCheckRequested()),
          ),
          BlocProvider<ActiveContextCubit>(
            create: (context) => ActiveContextCubit(
              preferencesRepository: context.read<PreferencesRepository>(),
            )..loadContext(),
          ),
          BlocProvider<LanguageCubit>(
            create: (context) => LanguageCubit(),
            // TODO: Load saved language in LanguageCubit or here
          ),
        ],
        child: BlocBuilder<LanguageCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,

              // Localization
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'), // English
                Locale('hi'), // Hindi
              ],

              // Theme
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.light, // Start with light mode

              // Auth wrapper
              home: const AuthWrapper(),
            );
          },
        ),
      ),
    );
  }
}

/// Wrapper widget that shows login or home based on auth state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated && state.profile != null) {
          // If we have a stored preference, it might override the profile preference
          // But for now, let's respect profile preference if not set locally?
          // Actually, let's checking PreferenceRepository in LanguageCubit is better.
          // For now, keeping existing logic but maybe we should rely on SetupScreen for language too.

          final languageCode = state.profile?['preferred_language'] ?? 'en';
          // Only change if not already set by user manually?
          // Keep simple: Profile language is default.
          context.read<LanguageCubit>().changeLanguage(Locale(languageCode));
        }
      },
      builder: (context, authState) {
        if (authState is AuthInitial || authState is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authState is AuthAuthenticated) {
          return BlocBuilder<ActiveContextCubit, ActiveContextState>(
            builder: (context, contextState) {
              // Show loading while context is being loaded
              if (contextState.isLoading) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Once loaded, show home if initialized, otherwise setup
              if (contextState.isInitialized) {
                return const HomeScreen();
              } else {
                return const SetupScreen();
              }
            },
          );
        }

        // AuthUnauthenticated or AuthFailure
        return const LoginScreen();
      },
    );
  }
}
