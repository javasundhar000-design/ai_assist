import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/constants/app_constants.dart';

class DesignPreferencesState {
  final InteriorStyle? style;
  final double budget;
  final String? colorPreference;

  const DesignPreferencesState({
    this.style,
    this.budget = 2000,
    this.colorPreference,
  });

  DesignPreferencesState copyWith({
    InteriorStyle? style,
    double? budget,
    String? colorPreference,
  }) {
    return DesignPreferencesState(
      style: style ?? this.style,
      budget: budget ?? this.budget,
      colorPreference: colorPreference ?? this.colorPreference,
    );
  }
}

class DesignPreferencesController extends StateNotifier<DesignPreferencesState> {
  DesignPreferencesController() : super(const DesignPreferencesState());

  void setStyle(InteriorStyle style) => state = state.copyWith(style: style);
  void setBudget(double budget) => state = state.copyWith(budget: budget);
  void setColorPreference(String? color) {
    state = DesignPreferencesState(
      style: state.style,
      budget: state.budget,
      colorPreference: (color == null || color.trim().isEmpty) ? null : color.trim(),
    );
  }
}

/// autoDispose: preferences reset once the user leaves the
/// style-selection -> recommendations flow, so a stale style/budget
/// doesn't leak into a different project later.
final designPreferencesProvider = StateNotifierProvider.autoDispose<
    DesignPreferencesController, DesignPreferencesState>(
  (ref) => DesignPreferencesController(),
);
