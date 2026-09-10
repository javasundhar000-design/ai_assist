import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../models/quick_phrase.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/openrouter_service.dart';
import '../../services/storage_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/emergency_button.dart';
import '../auth/profile_select_screen.dart';

class NotepadScreen extends StatefulWidget {
  const NotepadScreen({super.key});

  @override
  State<NotepadScreen> createState() => _NotepadScreenState();
}

class _NotepadScreenState extends State<NotepadScreen> {
  final TextEditingController _controller = TextEditingController();
  final OpenRouterService _openRouter = OpenRouterService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  List<QuickPhrase> _phrases = [];
  bool _listening = false;
  bool _suggesting = false;
  String _suggestion = '';
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.instance.getCurrentProfile();
    setState(() => _profile = profile);
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ProfileSelectScreen()),
      (route) => false,
    );
  }

  Future<void> _loadState() async {
    final text = await StorageService.instance.loadNotepad();
    final phrases = await StorageService.instance.loadPhrases();
    setState(() {
      _controller.text = text;
      _phrases = phrases;
    });
  }

  Future<void> _persistText() async {
    await StorageService.instance.saveNotepad(_controller.text);
  }

  Future<void> _speakNote() async {
    await TtsService.instance.speak(_controller.text);
  }

  Future<void> _speakPhrase(QuickPhrase phrase) async {
    await TtsService.instance.speak(phrase.text);
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _listening = false);
        }
      },
      onError: (error) {
        setState(() => _listening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition error: ${error.errorMsg}')),
        );
      },
    );

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not available on this device.')),
      );
      return;
    }

    setState(() => _listening = true);
    _speech.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection =
              TextSelection.collapsed(offset: _controller.text.length);
        });
      },
    );
  }

  Future<void> _getSuggestion() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _suggesting = true;
      _suggestion = '';
    });
    try {
      final result = await _openRouter.generateText(
        prompt:
            'Complete or improve this sentence so it reads naturally and '
            'politely. Only return the improved sentence, nothing else.\n\n'
            'Sentence: "${_controller.text}"',
        maxTokens: 100,
      );
      setState(() => _suggestion = result);
    } catch (e) {
      setState(() => _suggestion = 'Suggestion failed: $e');
    } finally {
      setState(() => _suggesting = false);
    }
  }

  Future<void> _addCustomPhrase() async {
    final labelController = TextEditingController();
    final textController = TextEditingController();

    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add quick phrase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Button label'),
            ),
            TextField(
              controller: textController,
              decoration: const InputDecoration(labelText: 'Spoken text'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add')),
        ],
      ),
    );

    if (added == true &&
        labelController.text.trim().isNotEmpty &&
        textController.text.trim().isNotEmpty) {
      setState(() {
        _phrases.add(QuickPhrase(
          label: labelController.text.trim(),
          text: textController.text.trim(),
        ));
      });
      await StorageService.instance.savePhrases(_phrases);
    }
  }

  @override
  void dispose() {
    _persistText();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_profile == null ? 'Non-Speaking Mode' : 'Non-Speaking — ${_profile!.name}'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Log out'),
        ],
      ),
      floatingActionButton: _profile == null ? null : EmergencyButton(profile: _profile!),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Quick Phrases',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _phrases.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    if (i == _phrases.length) {
                      return OutlinedButton.icon(
                        onPressed: _addCustomPhrase,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      );
                    }
                    final phrase = _phrases[i];
                    return ElevatedButton(
                      onPressed: () => _speakPhrase(phrase),
                      child: Text(phrase.label),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              const Text('Notepad',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    hintText: 'Type here, or tap the microphone to speak...',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: (_) => _persistText(),
                ),
              ),

              if (_suggestion.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_suggestion)),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _controller.text = _suggestion;
                            _suggestion = '';
                          });
                          _persistText();
                        },
                        child: const Text('Use'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _toggleListening,
                      icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                      label: Text(_listening ? 'Listening...' : 'Speak'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _listening ? Colors.red.shade50 : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _suggesting ? null : _getSuggestion,
                      icon: _suggesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_fix_high),
                      label: const Text('Improve'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _speakNote,
                icon: const Icon(Icons.volume_up),
                label: const Text('Speak Note'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
