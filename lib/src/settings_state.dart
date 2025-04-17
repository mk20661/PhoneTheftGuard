import 'package:flutter/foundation.dart';

class SettingsState with ChangeNotifier {
  bool _notificationsEnabled = true;
  bool _locationAlertEnabled = true;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get locationAlertEnabled => _locationAlertEnabled;

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void toggleLocationAlert(bool value) {
    _locationAlertEnabled = value;
    notifyListeners();
  }
}