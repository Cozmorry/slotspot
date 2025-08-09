import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../settings/theme_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateChangesProvider);
    final localPhotoAsync = ref.watch(localProfilePhotoPathProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            userAsync.when(
              data: (user) => _UserHeader(user: user, localPhotoAsync: localPhotoAsync),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),
            _ThemeModeToggle(),
            const SizedBox(height: 24),
            Wrap(spacing: 12, runSpacing: 12, children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider).signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(profilePhotoControllerProvider).pickAndSaveLocalProfilePhoto();
                  ref.invalidate(localProfilePhotoPathProvider);
                },
                icon: const Icon(Icons.photo),
                label: const Text('Update profile photo (local)'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user, required this.localPhotoAsync});
  final User? user;
  final AsyncValue<String?> localPhotoAsync;

  @override
  Widget build(BuildContext context) {
    final String title = user?.displayName ?? 'Guest';
    final String? photoUrl = user?.photoURL;

    return Row(
      children: [
        localPhotoAsync.when(
          data: (localPath) {
            Widget avatar;
            if (localPath != null && File(localPath).existsSync()) {
              avatar = CircleAvatar(radius: 36, backgroundImage: FileImage(File(localPath)));
            } else if (photoUrl != null) {
              avatar = CircleAvatar(radius: 36, backgroundImage: NetworkImage(photoUrl));
            } else {
              avatar = CircleAvatar(radius: 36, child: const Icon(Icons.person));
            }
            return avatar;
          },
          loading: () => const CircleAvatar(radius: 36, child: CircularProgressIndicator()),
          error: (e, st) => CircleAvatar(radius: 36, child: Text('!')),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(user?.email ?? 'Not signed in', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeModeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
            ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.brightness_auto)),
          ],
          selected: {mode},
          onSelectionChanged: (set) {
            final selected = set.first;
            ref.read(themeModeControllerProvider.notifier).setThemeMode(selected);
          },
        ),
      ],
    );
  }
}


