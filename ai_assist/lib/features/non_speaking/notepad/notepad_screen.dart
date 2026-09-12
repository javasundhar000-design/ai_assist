import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/permission.dart';
import '../../../widgets/permission_guard.dart';

/// Spec §13-16: Smart Notepad with quick phrases, live word/sentence
/// suggestions from the backend's OpenRouter-backed endpoint, and
/// text-to-speech playback of the finished message.
class NotepadScreen extends ConsumerStatefulWidget {
  const NotepadScreen({super.key});

  @override
  ConsumerState<NotepadScreen> createState() => _NotepadScreenState();
}

const _quickPhrases = [
  'I need help',
  'I am fine',
  'Call my family',
  'Where is the restroom?',
  'Please wait',
  'I need assistance',
];

class _NotepadScreenState extends ConsumerState<NotepadScreen> {
  final _controller = TextEditingController();
  List<String> _wordSuggestions = [];
  List<String> _sentenceSuggestions = [];
  Timer? _debounce;
  bool _loadingSuggestions = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetchSuggestions(text));
  }

  Future<void> _fetchSuggestions(String text) async {
    if (text.trim().isEmpty) {
      setState(() {
        _wordSuggestions = [];
        _sentenceSuggestions = [];
      });
      return;
    }
    setState(() => _loadingSuggestions = true);
    try {
      final ai = ref.read(aiServiceProvider);
      final words = await ai.generateWordSuggestions(text);
      final sentences = await ai.generateSentenceSuggestions(text);
      if (!mounted) return;
      setState(() {
        _wordSuggestions = words;
        _sentenceSuggestions = sentences;
      });
    } catch (_) {
      // Suggestions are a convenience — a failed fetch shouldn't block typing.
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  void _appendWord(String word) {
    final text = _controller.text;
    final needsSpace = text.isNotEmpty && !text.endsWith(' ');
    _controller.text = '$text${needsSpace ? ' ' : ''}$word';
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    _onTextChanged(_controller.text);
  }

  void _useSentence(String sentence) {
    _controller.text = sentence;
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  Future<void> _speak() async {
    if (_controller.text.trim().isEmpty) return;
    await ref.read(ttsServiceProvider).speak(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      required: Permission.smartNotepad,
      child: Scaffold(
        appBar: AppBar(title: const Text('Smart Notepad')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Quick phrases', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final phrase in _quickPhrases)
                      ActionChip(
                        label: Text(phrase),
                        onPressed: () => _useSentence(phrase),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(fontSize: 20),
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      alignLabelWithHint: true,
                    ),
                    onChanged: _onTextChanged,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_loadingSuggestions)
                  const LinearProgressIndicator(minHeight: 2)
                else if (_wordSuggestions.isNotEmpty) ...[
                  Text('Word suggestions', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final word in _wordSuggestions)
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: Text(word),
                          onPressed: () => _appendWord(word),
                        ),
                    ],
                  ),
                ],
                if (_sentenceSuggestions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('Sentence suggestions', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Column(
                    children: [
                      for (final sentence in _sentenceSuggestions)
                        Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: ListTile(
                            title: Text(sentence),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _useSentence(sentence),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          _controller.clear();
                          _wordSuggestions = [];
                          _sentenceSuggestions = [];
                        }),
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.communication,
                        ),
                        onPressed: _speak,
                        icon: const Icon(Icons.volume_up_rounded),
                        label: const Text('Speak'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
