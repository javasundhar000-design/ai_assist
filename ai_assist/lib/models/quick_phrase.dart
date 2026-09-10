class QuickPhrase {
  final String label;
  final String text;

  const QuickPhrase({required this.label, required this.text});

  factory QuickPhrase.fromJson(Map<String, dynamic> json) => QuickPhrase(
        label: json['label'] as String,
        text: json['text'] as String,
      );

  Map<String, dynamic> toJson() => {'label': label, 'text': text};

  /// Sensible starter set covering common urgent/social needs.
  static List<QuickPhrase> defaults() => const [
        QuickPhrase(label: 'Yes', text: 'Yes.'),
        QuickPhrase(label: 'No', text: 'No.'),
        QuickPhrase(label: 'Help', text: 'I need help, please.'),
        QuickPhrase(label: 'Water', text: 'Could I have some water, please?'),
        QuickPhrase(label: 'Bathroom', text: 'I need to use the bathroom.'),
        QuickPhrase(label: 'Pain', text: 'I am in pain.'),
        QuickPhrase(
            label: 'Wait', text: 'Please wait a moment, I am typing.'),
        QuickPhrase(label: 'Thank you', text: 'Thank you very much.'),
      ];
}
