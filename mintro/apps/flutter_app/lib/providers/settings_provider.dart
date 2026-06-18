import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds lightweight client-side preferences that don't need server
/// round-trips. `animationsEnabled` gates the heavier celebratory effects
/// (confetti, level-up overlay) — progress bars and basic fades always run
/// since they're core to legibility, not just decoration.
class SettingsState {
  final bool animationsEnabled;
  final bool notificationsEnabled;

  const SettingsState({this.animationsEnabled = true, this.notificationsEnabled = true});

  SettingsState copyWith({bool? animationsEnabled, bool? notificationsEnabled}) {
    return SettingsState(
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  void setAnimationsEnabled(bool value) {
    state = state.copyWith(animationsEnabled: value);
  }

  void setNotificationsEnabled(bool value) {
    state = state.copyWith(notificationsEnabled: value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
