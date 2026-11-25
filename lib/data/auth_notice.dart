import 'package:flutter/foundation.dart';

class AuthNotice extends ChangeNotifier {
  String? _message;
  String? _route;
  Object? _arguments;
  bool _recoveryInProgress = false;

  String? get message => _message;
  String? get route => _route;
  Object? get arguments => _arguments;
  bool get recoveryInProgress => _recoveryInProgress;

  void show(String message, {String? route, Object? arguments}) {
    _message = message;
    _route = route;
    _arguments = arguments;
    notifyListeners();
  }

  void setRecoveryInProgress(bool value) {
    if (_recoveryInProgress == value) return;
    _recoveryInProgress = value;
    notifyListeners();
  }

  void clear() {
    _message = null;
    _route = null;
    _arguments = null;
    notifyListeners();
  }
}
