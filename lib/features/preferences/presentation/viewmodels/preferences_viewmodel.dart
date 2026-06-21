import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myhaystack/core/services/preferences_service.dart';
import 'package:myhaystack/shared/presentation/providers/app_providers.dart';

class PreferencesState {
  final String serverUrl;
  final String username;
  final String password;
  final int daysRetrieval;

  PreferencesState({
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.daysRetrieval,
  });

  PreferencesState copyWith({
    String? serverUrl,
    String? username,
    String? password,
    int? daysRetrieval,
  }) {
    return PreferencesState(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      daysRetrieval: daysRetrieval ?? this.daysRetrieval,
    );
  }
}

class PreferencesNotifier extends Notifier<PreferencesState> {
  late final PreferencesService _prefs;

  @override
  PreferencesState build() {
    _prefs = ref.watch(preferencesServiceProvider);
    return PreferencesState(
      serverUrl: _prefs.serverUrl,
      username: _prefs.username,
      password: _prefs.password,
      daysRetrieval: _prefs.daysRetrieval,
    );
  }

  Future<void> updateServerUrl(String value) async {
    await _prefs.setServerUrl(value);
    state = state.copyWith(serverUrl: value);
  }

  Future<void> updateUsername(String value) async {
    await _prefs.setUsername(value);
    state = state.copyWith(username: value);
  }

  Future<void> updatePassword(String value) async {
    await _prefs.setPassword(value);
    state = state.copyWith(password: value);
  }

  Future<void> updateDaysRetrieval(int value) async {
    await _prefs.setDaysRetrieval(value);
    state = state.copyWith(daysRetrieval: value);
  }
}

final preferencesViewModelProvider =
    NotifierProvider<PreferencesNotifier, PreferencesState>(
      () => PreferencesNotifier(),
    );
