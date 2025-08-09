import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../../ui/widgets.dart';
import 'models.dart';
import 'repository.dart';

class FeedbackScreenView extends ConsumerStatefulWidget {
  const FeedbackScreenView({super.key});

  @override
  ConsumerState<FeedbackScreenView> createState() => _FeedbackScreenViewState();
}

class _FeedbackScreenViewState extends ConsumerState<FeedbackScreenView> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'suggestion';
  String _message = '';
  int? _rating;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final repo = ref.watch(feedbackRepositoryProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Send feedback'),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'suggestion', child: Text('Suggestion')),
                    DropdownMenuItem(value: 'bug', child: Text('Bug')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? _type),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Message'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a message' : null,
                  onSaved: (v) => _message = v!.trim(),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _rating,
                  decoration: const InputDecoration(labelText: 'Rating (optional)'),
                  items: [for (int i = 1; i <= 5; i++) DropdownMenuItem(value: i, child: Text('$i'))],
                  onChanged: (v) => setState(() => _rating = v),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: user == null
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          _formKey.currentState!.save();
                          final messenger = ScaffoldMessenger.of(context);
                          await repo.submit(FeedbackEntry(
                            id: 'tmp',
                            userId: user.uid,
                            type: _type,
                            message: _message,
                            rating: _rating,
                            createdAt: DateTime.now(),
                          ));
                          messenger.showSnackBar(const SnackBar(content: Text('Feedback sent')));
                          _formKey.currentState!.reset();
                          setState(() {
                            _type = 'suggestion';
                            _rating = null;
                          });
                        },
                  icon: const Icon(Icons.send),
                  label: const Text('Submit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


