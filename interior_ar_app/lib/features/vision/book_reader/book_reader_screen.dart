import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/accessibility/accessibility_settings.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../core/utilities/temp_file_cleaner.dart';
import '../camera/camera_capture_view.dart';
import '../ocr/ocr_service.dart';

/// Section 12: continuous page-by-page reading with sentence-level
/// controls (previous/next/repeat), unlike the plain Vision Reader which
/// just reads a whole block once. This is the module the spec calls out
/// as a key demonstration feature for Blind users.
class BookReaderScreen extends ConsumerStatefulWidget {
  const BookReaderScreen({super.key});

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen> {
  List<String> _sentences = [];
  int _currentIndex = 0;
  bool _processing = false;
  bool _continuousReading = false;

  final _sentenceSplitter = RegExp(r'(?<=[.!?])\s+');

  Future<void> _onCaptured(String imagePath) async {
    setState(() => _processing = true);
    final text = await OcrService.instance.extractTextSmart(imagePath);
    await TempFileCleaner.deleteQuietly(imagePath);
    if (!mounted) return;
    setState(() {
      _processing = false;
      _sentences = text == null
          ? []
          : text.split(_sentenceSplitter).where((s) => s.trim().isNotEmpty).toList();
      _currentIndex = 0;
    });
    if (_sentences.isEmpty) {
      await TextToSpeechService.instance.speak(AppStrings.errOcrGeneric);
    } else {
      await _readCurrent();
    }
  }

  Future<void> _readCurrent() async {
    if (_currentIndex >= _sentences.length) return;
    await TextToSpeechService.instance.speak(_sentences[_currentIndex]);
    if (_continuousReading && _currentIndex < _sentences.length - 1) {
      _next();
    }
  }

  void _next() {
    if (_currentIndex < _sentences.length - 1) {
      setState(() => _currentIndex++);
      _readCurrent();
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _readCurrent();
    }
  }

  @override
  void dispose() {
    TextToSpeechService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(accessibilitySettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Book Reader')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _sentences.isEmpty && !_processing
              ? CameraCaptureView(
                  instructionText: 'Position the book page in frame and capture.',
                  onCaptured: _onCaptured,
                )
              : _processing
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Sentence ${_currentIndex + 1} of ${_sentences.length}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _sentences[_currentIndex],
                              style: const TextStyle(fontSize: 22, height: 1.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Text('Speed'),
                            Expanded(
                              child: Slider(
                                value: settings.speechRate,
                                min: 0.1,
                                max: 1.0,
                                onChanged: (v) =>
                                    ref.read(accessibilitySettingsProvider.notifier).setSpeechRate(v),
                              ),
                            ),
                          ],
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Continuous reading'),
                          value: _continuousReading,
                          onChanged: (v) => setState(() => _continuousReading = v),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton.filledTonal(
                                onPressed: _previous, icon: const Icon(Icons.skip_previous_rounded)),
                            IconButton.filled(
                                onPressed: _readCurrent, icon: const Icon(Icons.play_arrow_rounded)),
                            IconButton.filledTonal(
                                onPressed: () => TextToSpeechService.instance.pause(),
                                icon: const Icon(Icons.pause_rounded)),
                            IconButton.filledTonal(
                                onPressed: _readCurrent, icon: const Icon(Icons.replay_rounded)),
                            IconButton.filledTonal(
                                onPressed: _next, icon: const Icon(Icons.skip_next_rounded)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => setState(() => _sentences = []),
                          child: const Text('SCAN NEXT PAGE'),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
