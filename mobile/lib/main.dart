import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_pallette.dart';
import 'core/navigation/main_navigator.dart';
import 'core/widgets/state_widgets.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'init_dependencies.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuthBloc>()..add(CheckAuthStatusEvent()),
      child: MaterialApp(
        title: 'Volt',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: AppColorScheme.lightColorScheme,
          scaffoldBackgroundColor: ColorPalette.backgroundLight,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: AppColorScheme.darkColorScheme,
          scaffoldBackgroundColor: ColorPalette.backgroundDark,
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Handle navigation on state changes
        if (state is AuthUnauthenticated) {
          // Ensure we're showing login page - navigation handled by builder
        }
      },
      buildWhen: (previous, current) {
        // Rebuild on any state change
        return true;
      },
      builder: (context, state) {
        // Handle loading and initial states
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: LoadingState(message: 'Checking your account...'),
          );
        }
        
        // Handle authenticated state - show main app
        if (state is AuthAuthenticated) {
          return const MainNavigator();
        }
        
        // Handle registration success - show login page
        if (state is AuthRegistrationSuccess) {
          return const LoginPage();
        }
        
        // Handle unauthenticated, error, or any other state - show login page
        // This includes AuthUnauthenticated and AuthError states
        // This ensures that after logout, the login page is shown
        return const LoginPage();
      },
    );
  }
}
