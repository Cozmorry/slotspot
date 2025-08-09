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
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: userAsync.when(
                data: (user) => _ProfileHeaderCard(user: user, localPhotoAsync: localPhotoAsync),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error: $e'),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: _AppearanceCard(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverToBoxAdapter(
              child: _ActionsRow(),
            ),
          ),
        ],
      ),
    );
  }
}

// Old header replaced by modern card layout

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

class _ProfileHeaderCard extends ConsumerWidget {
  const _ProfileHeaderCard({required this.user, required this.localPhotoAsync});
  final User? user;
  final AsyncValue<String?> localPhotoAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [
          scheme.primaryContainer,
          scheme.primary.withValues(alpha: 0.55),
        ]),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          _AvatarWithEdit(localPhotoAsync: localPhotoAsync, user: user),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.displayName ?? 'Guest', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onPrimaryContainer)),
                const SizedBox(height: 4),
                Text(user?.email ?? 'Not signed in', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer.withValues(alpha: 0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarWithEdit extends ConsumerWidget {
  const _AvatarWithEdit({required this.localPhotoAsync, required this.user});
  final AsyncValue<String?> localPhotoAsync;
  final User? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? photoUrl = user?.photoURL;
    return Stack(
      children: [
        localPhotoAsync.when(
          data: (localPath) {
            ImageProvider? provider;
            if (localPath != null && File(localPath).existsSync()) {
              provider = FileImage(File(localPath));
            } else if (photoUrl != null) {
              provider = NetworkImage(photoUrl);
            }
            return CircleAvatar(
              radius: 36,
              backgroundImage: provider,
              child: provider == null ? const Icon(Icons.person, size: 36) : null,
            );
          },
          loading: () => const CircleAvatar(radius: 36, child: CircularProgressIndicator()),
          error: (e, st) => const CircleAvatar(radius: 36, child: Icon(Icons.person)),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Material(
            color: Theme.of(context).colorScheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () async {
                await ref.read(profilePhotoControllerProvider).pickAndSaveLocalProfilePhoto();
                ref.invalidate(localProfilePhotoPathProvider);
              },
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _ThemeModeToggle(),
      ),
    );
  }
}

class _ActionsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider).signOut();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () async {
              await ref.read(profilePhotoControllerProvider).pickAndSaveLocalProfilePhoto();
              ref.invalidate(localProfilePhotoPathProvider);
            },
            icon: const Icon(Icons.photo),
            label: const Text('Update profile photo (local)'),
            style: FilledButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
      ],
    );
  }
}


