import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static const _serverUrlKey = 'serverUrl';
  static const _usernameKey = 'username';
  static const _passwordKey = 'password';
  static const _daysRetrievalKey = 'daysRetrieval';

  String get serverUrl => _prefs.getString(_serverUrlKey) ?? '';
  Future<void> setServerUrl(String value) => _prefs.setString(_serverUrlKey, value);

  String get username => _prefs.getString(_usernameKey) ?? '';
  Future<void> setUsername(String value) => _prefs.setString(_usernameKey, value);

  String get password => _prefs.getString(_passwordKey) ?? '';
  Future<void> setPassword(String value) => _prefs.setString(_passwordKey, value);

  int get daysRetrieval => _prefs.getInt(_daysRetrievalKey) ?? 7;
  Future<void> setDaysRetrieval(int value) => _prefs.setInt(_daysRetrievalKey, value);
}
