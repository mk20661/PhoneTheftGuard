import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providers: [
        EmailAuthProvider(),
      ],
      actions: [
        ForgotPasswordAction((context, email) {
          final uri = Uri(
            path: '/login/forgot-password',
            queryParameters: {'email': email},
          );
          context.push(uri.toString());
        }),
        AuthStateChangeAction((context, state) {
          final user = switch (state) {
            SignedIn s => s.user,
            UserCreated s => s.credential.user,
            _ => null,
          };

          if (user == null) return;

          if (state is UserCreated) {
            user.updateDisplayName(user.email!.split('@')[0]);
          }

          if (!user.emailVerified) {
            user.sendEmailVerification();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please verify your email')),
            );
          }
          context.go('/community');
        }),
      ],
    );
  }
}