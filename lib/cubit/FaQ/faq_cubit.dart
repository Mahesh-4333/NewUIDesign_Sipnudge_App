import 'package:flutter_bloc/flutter_bloc.dart';

import 'faq_state.dart';

class FaqCubit extends Cubit<FaqState> {
  final Map<String, List<Map<String, String>>> faqData = {
    'General': [
      {
        'question': 'What is Sipnudge?',
        'answer':
            'Sipnudge is a smart hydration bottle designed to help you stay properly hydrated throughout the day. It tracks your water intake and provides gentle nudges (via subtle vibrations and light cues) to remind you to drink.',
      },
      {
        'question': 'What makes Sipnudge different?',
        'answer':
            'Unlike regular bottles, Sipnudge actively encourages you to drink through personalized reminders and integrates with the app for insights.',
      },
    ],
    'Usage': [
      {
        'question': 'How do I start using Sipnudge?',
        'answer':
            'Charge your bottle, pair it with the app via Bluetooth, and set up your daily hydration goal. The reminders will start automatically.',
      },
      {
        'question': 'How do I clean the bottle?',
        'answer':
            'The bottle can be hand-washed with mild soap and water. Avoid submerging the electronic cap unit in water.',
      },
      {
        'question': 'Can children use Sipnudge?',
        'answer':
            'Yes, but adult supervision is recommended. Reminder settings can be customized for different needs.',
      },
    ],
    'App': [
      {
        'question': 'Do I need the app to use Sipnudge?',
        'answer':
            'The bottle will work independently with reminders, but the app provides hydration tracking, goals, and advanced customization.',
      },
      {
        'question': 'Is the app available for iOS and Android?',
        'answer': 'Yes, Sipnudge is available on both iOS and Android devices.',
      },
      {
        'question': 'Does the app work offline?',
        'answer':
            'Yes, the bottle will still log data offline. Once reconnected, it will sync with the app.',
      },
    ],
    'Tracking': [
      {
        'question': 'How does the bottle track water intake?',
        'answer':
            'Sipnudge uses smart sensors to measure the volume of liquid consumed and syncs this data to the app.',
      },
      {
        'question': 'Can I track other beverages?',
        'answer':
            'Yes, you can log beverages manually in the app, though Sipnudge is optimized for water tracking.',
      },
      {
        'question': 'How accurate is the tracking?',
        'answer':
            'The sensors are designed for high accuracy, typically within a 5% margin of actual intake.',
      },
    ],
    'Troubleshooting': [
      {
        'question': 'My bottle is not turning on. What should I do?',
        'answer':
            'Ensure the bottle is fully charged. If it still does not power on, try resetting by holding the power button for 10 seconds.',
      },
      {
        'question': 'The reminders are not working.',
        'answer':
            'Check if reminders are enabled in the app, ensure Bluetooth is connected, and confirm notification permissions.',
      },
      {
        'question': 'Data is not syncing with the app.',
        'answer':
            'Make sure Bluetooth is enabled, and the bottle is within range. Restarting the app may also help.',
      },
    ],
    'Support': [
      {
        'question': 'How can I contact customer support?',
        'answer':
            'You can reach us via the support option in the Sipnudge app or by emailing support@sipnudge.com.',
      },
      {
        'question': 'Is there a warranty?',
        'answer':
            'Yes, Sipnudge bottles come with a 1-year limited warranty covering manufacturing defects.',
      },
      {
        'question': 'Where can I find the user manual?',
        'answer':
            'The digital user manual is available inside the app under the Help section, or on our official website.',
      },
    ],
  };

  final List<String> allFAQs = [
    "How to use Sipnudge?",
    "How to clean the bottle?",
    "Battery life of the device?",
    "How does tracking work?",
    "Why are reminders not working?",
    "How to contact support?",
  ];
  late final List<Map<String, String>> _allFaqItems;

  FaqCubit() : super(const FaqState()) {
    _initializeExpansionState();
    _allFaqItems = _buildAllFaqItems();
    emit(state.copyWith(filteredFaqs: _allFaqItems));
  }

  void _initializeExpansionState() {
    final expansionMap = <String, List<bool>>{};
    for (var key in faqData.keys) {
      expansionMap[key] = List.generate(faqData[key]!.length, (_) => false);
    }
    emit(state.copyWith(isExpandedMap: expansionMap));
  }

  List<Map<String, String>> _buildAllFaqItems() {
    final List<Map<String, String>> list = [];
    faqData.forEach((category, faqs) {
      for (final item in faqs) {
        list.add({
          'category': category,
          'question': item['question']!,
          'answer': item['answer']!,
        });
      }
    });
    return list;
  }

  void selectCategory(String category) {
    emit(state.copyWith(selectedCategory: category));
  }

  void toggleExpansion(int index) {
    final map = {...state.isExpandedMap};
    final list = [...map[state.selectedCategory]!];
    list[index] = !list[index];
    map[state.selectedCategory] = list;
    emit(state.copyWith(isExpandedMap: map));
  }

  void filterSearch(String query) {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      emit(state.copyWith(
        searchQuery: '',
        filteredFaqs: _allFaqItems,
      ));
    } else {
      final q = trimmed.toLowerCase();
      final filtered = _allFaqItems.where((item) {
        final question = item['question']!.toLowerCase();
        final answer = item['answer']!.toLowerCase();
        return question.contains(q) || answer.contains(q);
      }).toList();

      emit(state.copyWith(
        searchQuery: trimmed,
        filteredFaqs: filtered,
      ));
    }
  }
}
