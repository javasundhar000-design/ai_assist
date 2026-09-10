import 'package:aura_stylist_ai/features/voice/domain/entities/voice_command.dart';
import 'package:aura_stylist_ai/features/voice/domain/services/voice_command_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = VoiceCommandParser();

  group('fixed commands', () {
    final cases = <String, VoiceCommandType>{
      'dark mode': VoiceCommandType.darkMode,
      'switch to dark mode': VoiceCommandType.darkMode,
      'light mode': VoiceCommandType.lightMode,
      'open wardrobe': VoiceCommandType.openWardrobe,
      'close wardrobe': VoiceCommandType.closeWardrobe,
      'capture': VoiceCommandType.capture,
      'take a photo': VoiceCommandType.capture,
      'save': VoiceCommandType.save,
      'share': VoiceCommandType.share,
      'next': VoiceCommandType.next,
      'previous': VoiceCommandType.previous,
      'go back': VoiceCommandType.previous,
      'reset': VoiceCommandType.reset,
      'exit': VoiceCommandType.exit,
      'quit': VoiceCommandType.exit,
    };

    cases.forEach((input, expectedType) {
      test('"$input" -> $expectedType', () {
        expect(parser.parse(input).type, expectedType);
      });
    });
  });

  group('show items', () {
    test('"show blue shirts" extracts color and category', () {
      final command = parser.parse('show blue shirts');
      expect(command.type, VoiceCommandType.showItems);
      expect(command.color, 'blue');
      expect(command.category, 'shirts');
    });

    test('"show black jackets" extracts color and category', () {
      final command = parser.parse('show black jackets');
      expect(command.color, 'black');
      expect(command.category, 'jackets');
    });

    test('"show casual" (occasion-style category, no color)', () {
      final command = parser.parse('show casual');
      expect(command.type, VoiceCommandType.showItems);
      expect(command.color, isNull);
      expect(command.category, 'casual');
    });

    test('"show sarees" extracts a category', () {
      final command = parser.parse('show sarees');
      expect(command.color, isNull);
      expect(command.category, 'sarees');
    });

    test('unrecognized-but-present category still gets captured', () {
      final command = parser.parse('show cyberpunk neon jacket');
      expect(command.type, VoiceCommandType.showItems);
      expect(command.category, isNotNull);
    });

    test('totally unrecognized remainder falls back to raw text', () {
      final command = parser.parse('show something completely unlisted');
      expect(command.type, VoiceCommandType.showItems);
      expect(command.category, 'something completely unlisted');
    });
  });

  group('recommend outfit', () {
    test('"recommend interview outfit" extracts occasion', () {
      final command = parser.parse('recommend interview outfit');
      expect(command.type, VoiceCommandType.recommendOutfit);
      expect(command.occasion, 'interview');
    });

    test('"recommend wedding outfit" extracts occasion', () {
      final command = parser.parse('recommend wedding outfit');
      expect(command.occasion, 'wedding');
    });

    test('"recommend college outfit" extracts occasion', () {
      final command = parser.parse('recommend college outfit');
      expect(command.occasion, 'college');
    });

    test('unrecognized occasion falls back to the regex-extracted word', () {
      final command = parser.parse('recommend brunch outfit');
      expect(command.type, VoiceCommandType.recommendOutfit);
      expect(command.occasion, 'brunch');
    });
  });

  group('unknown / edge cases', () {
    test('empty string -> unknown', () {
      expect(parser.parse('').type, VoiceCommandType.unknown);
    });

    test('unrelated sentence -> unknown', () {
      expect(parser.parse('what is the weather today').type, VoiceCommandType.unknown);
    });

    test('is case-insensitive and trims whitespace', () {
      expect(parser.parse('  DARK MODE  ').type, VoiceCommandType.darkMode);
    });

    test('rawText is preserved verbatim regardless of parsing', () {
      final command = parser.parse('  Show Blue Shirts  ');
      expect(command.rawText, '  Show Blue Shirts  ');
    });
  });
}
