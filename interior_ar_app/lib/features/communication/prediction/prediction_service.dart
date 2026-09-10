/// Section 19/24: lightweight, fully offline word- and sentence-level
/// prediction. Shared by the Smart Notepad and the Eye Keyboard (Section
/// 24 — "select an entire sentence using gaze"), so both typing paths
/// benefit from the same suggestion logic.
///
/// This ships with a small curated dictionary/phrase bank so the app
/// works with zero network calls and zero bundled ML model. The
/// interface is intentionally narrow so a statistical/on-device-LLM
/// predictor could replace it later without touching UI code.
class PredictionService {
  PredictionService._();
  static final PredictionService instance = PredictionService._();

  static const _commonWords = [
    'water', 'wait', 'work', 'want', 'walk', 'watch',
    'help', 'hungry', 'home', 'hurt', 'hello',
    'yes', 'no', 'please', 'thanks', 'tired', 'toilet', 'today',
    'medicine', 'mother', 'more', 'me',
    'need', 'now',
  ];

  static const _sentenceBank = <String, List<String>>{
    'i need': [
      'I need water.',
      'I need help.',
      'I need to go home.',
      'I need medicine.',
      'I need to use the toilet.',
    ],
    'i am': [
      'I am hungry.',
      'I am tired.',
      'I am in pain.',
      'I am fine.',
      'I am thirsty.',
    ],
    'call': [
      'Call my family.',
      'Call my caregiver.',
      'Call the doctor.',
    ],
    'i want': [
      'I want to go home.',
      'I want water.',
      'I want to rest.',
    ],
  };

  /// Word-level: called while the user is mid-word (e.g. "I need w").
  List<String> suggestWords(String partialWord) {
    final p = partialWord.toLowerCase();
    if (p.isEmpty) return const [];
    return _commonWords.where((w) => w.startsWith(p)).take(5).toList();
  }

  /// Sentence-level: called when the last "word" is complete and the app
  /// looks at the trailing phrase to suggest whole sentences.
  List<String> suggestSentences(String currentText) {
    final normalized = currentText.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    for (final entry in _sentenceBank.entries) {
      if (normalized.endsWith(entry.key) || normalized == entry.key) {
        return entry.value;
      }
    }
    // Fallback: match on the first word only (e.g. just "I").
    final firstWord = normalized.split(' ').first;
    final matches = _sentenceBank.entries
        .where((e) => e.key.startsWith(firstWord))
        .expand((e) => e.value)
        .toSet()
        .take(5)
        .toList();
    return matches;
  }

  /// Given "I need w" returns suggestions for completing "w" AND, if the
  /// stem before it ("I need") matches a known sentence starter, whole
  /// sentence completions too.
  ({List<String> words, List<String> sentences}) suggest(String text) {
    if (text.isEmpty) return (words: const [], sentences: const []);
    final trailingSpace = text.endsWith(' ');
    final parts = text.trim().split(' ');
    final lastToken = trailingSpace ? '' : (parts.isNotEmpty ? parts.last : '');
    final stem = trailingSpace ? text.trim() : parts.sublist(0, parts.length - 1).join(' ');

    final words = lastToken.isNotEmpty ? suggestWords(lastToken) : const <String>[];
    final sentences = suggestSentences(stem.isNotEmpty ? stem : text);
    return (words: words, sentences: sentences);
  }
}
