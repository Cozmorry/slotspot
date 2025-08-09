import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'auth_providers.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final gradient = LinearGradient(colors: [scheme.primaryContainer, scheme.primary.withValues(alpha: 0.6)]);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Header content
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset('assets/brand/slotspot_logo.svg', height: 84),
                          const SizedBox(height: 16),
                          Text('SlotSpot', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 10),
                          Text(
                            'Reserve parking, crowdsource empty slots at Sarit Mall, and view demand predictions.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom anchored Google button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 72),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                    child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: SizedBox(
                      height: 64,
                      width: double.infinity,
                      child: SignInButton(
                        Buttons.google,
                        text: 'Continue with Google',
                        onPressed: () async {
                          await ref.read(authControllerProvider).signInWithGoogle();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


