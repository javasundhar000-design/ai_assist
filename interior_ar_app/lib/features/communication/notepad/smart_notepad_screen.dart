import 'package:flutter/material.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../prediction/prediction_service.dart';

/// Section 19: text input with live word + sentence prediction, plus
/// saved/recent phrases. Selecting a suggestion completes the current
/// word (word suggestions) or replaces the whole draft (sentence
/// suggestions) — mirroring how predictive keyboards behave elsewhere.
class SmartNotepadScreen extends StatefulWidget {
  const SmartNotepadScreen({super.key});

  @override
  State<SmartNotepadScreen> createState() => _SmartNotepadScreenState();
}

class _SmartNotepadScreenState extends State<SmartNotepadScreen> {
  final _controller = TextEditingController();
  List<String> _wordSuggestions = [];
  List<String> _sentenceSuggestions = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final result = PredictionService.instance.suggest(_controller.text);
    setState(() {
      _wordSuggestions = result.words;
      _sentenceSuggestions = result.sentences;
    });
  }

  void _applyWord(String word) {
    final text = _controller.text;
    final parts = text.split(' ');
    parts[parts.length - 1] = word;
    final newText = '${parts.join(' ')} ';
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  void _applySentence(String sentence) {
    _controller.value = TextEditingValue(
      text: sentence,
      selection: TextSelection.collapsed(offset: sentence.length),
    );
  }

  Future<void> _speakAndSave() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await TextToSpeechService.instance.speak(text);
    await LocalStorageService.instance.addRecentMessage(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recent = LocalStorageService.instance.getRecentMessages();

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Notepad')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                maxLines: 3,
                style: const TextStyle(fontSize: 22),
                decoration: const InputDecoration(
                  hintText: 'Type what you want to say…',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_sentenceSuggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                _suggestionRow('Sentences', _sentenceSuggestions, _applySentence, filled: true),
              ],
              if (_wordSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                _suggestionRow('Words', _wordSuggestions, _applyWord),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 64,
                child: ElevatedButton.icon(
                  onPressed: _speakAndSave,
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('SPEAK'),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Recent Messages', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              Expanded(
                child: recent.isEmpty
                    ? const Center(child: Text('No messages yet.'))
                    : ListView.builder(
                        itemCount: recent.length,
                        itemBuilder: (context, i) => Card(
                          child: ListTile(
                            title: Text(recent[i]),
                            trailing: IconButton(
                              icon: const Icon(Icons.volume_up_rounded),
                              onPressed: () => TextToSpeechService.instance.speak(recent[i]),
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

  Widget _suggestionRow(String label, List<String> items, void Function(String) onTap, {bool filled = false}) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => filled
            ? FilledButton(onPressed: () => onTap(items[i]), child: Text(items[i]))
            : OutlinedButton(onPressed: () => onTap(items[i]), child: Text(items[i])),
      ),
    );
  }
}
