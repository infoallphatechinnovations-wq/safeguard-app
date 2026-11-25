import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api.dart';
import 'models.dart';

class AuthState extends ChangeNotifier {
  final api = Api();
  final _storage = const FlutterSecureStorage();
  AppUser? user;
  bool ready = false;

  bool get isLoggedIn => user != null;
  bool get isCorporate => user?.accountType == 'corporate_admin';

  Future<void> init() async {
    try {
      final t = await _storage.read(key: 'token');
      if (t != null) {
        api.token = t;
        final d = await api.get('/auth/me');
        user = AppUser.fromJson(d['user']);
      }
    } on ApiException catch (e) {
      if (e.status == 401) {
        api.token = null;
        await _storage.delete(key: 'token');
      }
    } catch (_) {}
    ready = true;
    notifyListeners();
  }

  Future<void> _startSession(Map<String, dynamic> d) async {
    api.token = d['token'];
    await _storage.write(key: 'token', value: d['token']);
    user = AppUser.fromJson(d['user']);
    notifyListeners();
  }

  Future<void> login(String email, String password) async =>
      _startSession(await api.post('/auth/login', {'email': email, 'password': password}));

  Future<void> register(Map<String, dynamic> body) async =>
      _startSession(await api.post('/auth/register', body));

  /// Returns the company's staff join code.
  Future<String> registerCompany(Map<String, dynamic> body) async {
    final d = await api.post('/auth/register-company', body);
    await _startSession(d);
    return d['joinCode'] as String;
  }

  Future<void> logout() async {
    api.token = null;
    user = null;
    await _storage.delete(key: 'token');
    notifyListeners();
  }
}
