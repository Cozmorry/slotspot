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
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.05),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.feedback_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Feedback',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Help us improve SlotSpot',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Form Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    Theme.of(context).colorScheme.surfaceContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Share Your Thoughts',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Feedback Type
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _type,
                        decoration: InputDecoration(
                          labelText: 'Feedback Type',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Icon(
                            _type == 'bug' 
                              ? Icons.bug_report_rounded
                              : _type == 'suggestion'
                                ? Icons.lightbulb_rounded
                                : Icons.chat_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'suggestion',
                            child: Row(
                              children: [
                                Icon(Icons.lightbulb_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Suggestion'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'bug',
                            child: Row(
                              children: [
                                Icon(Icons.bug_report_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Bug Report'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Row(
                              children: [
                                Icon(Icons.chat_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Other'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _type = v ?? _type),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Message Field
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: TextFormField(
                        minLines: 4,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: 'Your Message',
                          hintText: 'Tell us what you think or describe the issue...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(top: 12, left: 16, right: 8),
                            child: Icon(
                              Icons.message_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) 
                          ? 'Please enter your message' 
                          : null,
                        onSaved: (v) => _message = v!.trim(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Rating Field
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: DropdownButtonFormField<int>(
                        value: _rating,
                        decoration: InputDecoration(
                          labelText: 'Rating (Optional)',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Icon(
                            Icons.star_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        items: [
                          for (int i = 1; i <= 5; i++)
                            DropdownMenuItem(
                              value: i,
                              child: Row(
                                children: [
                                  ...List.generate(i, (index) => const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 16,
                                  )),
                                  ...List.generate(5 - i, (index) => Icon(
                                    Icons.star_border_rounded,
                                    color: Colors.grey.shade400,
                                    size: 16,
                                  )),
                                  const SizedBox(width: 8),
                                  Text('$i star${i > 1 ? 's' : ''}'),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _rating = v),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: user == null
                            ? [Colors.grey, Colors.grey.shade600]
                            : [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: user == null ? null : [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FilledButton.icon(
                        onPressed: user == null ? null : () async {
                          if (!_formKey.currentState!.validate()) return;
                          _formKey.currentState!.save();
                          final messenger = ScaffoldMessenger.of(context);
                          
                          try {
                            await repo.submit(FeedbackEntry(
                              id: 'tmp',
                              userId: user.uid,
                              type: _type,
                              message: _message,
                              rating: _rating,
                              createdAt: DateTime.now(),
                            ));
                            
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text('Thank you! Your feedback has been sent successfully.'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            
                            _formKey.currentState!.reset();
                            setState(() {
                              _type = 'suggestion';
                              _rating = null;
                            });
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text('Failed to send feedback. Please try again.'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 24),
                        label: Text(
                          user == null ? 'Sign in to send feedback' : 'Send Feedback',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


