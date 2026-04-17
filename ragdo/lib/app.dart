import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/screens/phone_entry_screen.dart';
import 'features/auth/screens/profile_setup_screen.dart';
import 'features/feed/screens/citizen_shell.dart';
import 'features/authority/dashboard/authority_shell.dart';

class Jawab DoApp extends StatelessWidget {
  const Jawab DoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(AuthService())..add(AuthStarted()),
      child: MaterialApp(
        title: 'Jawab Do',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthInitial || state is AuthLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFCC3300),
                  ),
                ),
              );
            }
            if (state is AuthCitizenAuthenticated) {
              return CitizenShell(user: state.user);
            }
            if (state is AuthAuthorityAuthenticated) {
              return AuthorityShell(user: state.user);
            }
            if (state is AuthNeedsProfileSetup) {
              return BlocProvider.value(
                value: context.read<AuthBloc>(),
                child: ProfileSetupScreen(uid: state.uid, phone: state.phone),
              );
            }
            if (state is AuthError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<AuthBloc>().add(AuthStarted()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            // Default: login screen
            return BlocProvider.value(
              value: context.read<AuthBloc>(),
              child: const PhoneEntryScreen(),
            );
          },
        ),
      ),
    );
  }
}
