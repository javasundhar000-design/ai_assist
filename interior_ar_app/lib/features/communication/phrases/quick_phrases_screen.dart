import 'package:flutter/material.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/text_to_speech_service.dart';

/// Section 20: categorized quick phrases (Basic / Needs / Medical /
/// Emergency) plus the ability to save custom phrases locally.
class QuickPhrasesScreen extends StatefulWidget {
  const QuickPhrasesScreen({super.key});

  @override
  State<QuickPhrasesScreen> createState() => _QuickPhrasesScreenState();
}

class _QuickPhrasesScreenState extends State<QuickPhrasesScreen> with SingleTickerProviderStateMixin {
  static const _categories = {
    'Basic': ['Yes', 'No', 'Thank you', 'Please wait'],
    'Needs': ['I need water', 'I am hungry', 'I am tired', 'I need help'],
    'Medical': ['I need medicine', 'I am in pain', 'Call my doctor'],
    'Emergency': ['Call my family', 'Call my caregiver'],
  };

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  Future<void> _addCustomPhrase(String category) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Phrase'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('ADD')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await LocalStorageService.instance.addPhrase(category, {'text': result});
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryNames = _categories.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Phrases'),
        bottom: TabBar(controller: _tabController, tabs: categoryNames.map((c) => Tab(text: c)).toList()),
      ),
      body: TabBarView(
        controller: _tabController,
        children: categoryNames.map((category) {
          final builtIn = _categories[category]!;
          final custom = LocalStorageService.instance
              .getPhrases(category)
              .map((m) => m['text'] as String)
              .toList();
          final all = [...builtIn, ...custom];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: GridView.builder(
                    itemCount: all.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.2,
                    ),
                    itemBuilder: (context, i) => _PhraseChip(text: all[i]),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _addCustomPhrase(category),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('ADD PHRASE'),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PhraseChip extends StatelessWidget {
  final String text;
  const _PhraseChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => TextToSpeechService.instance.speak(text),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSecondaryContainer),
            ),
          ),
        ),
      ),
    );
  }
}
