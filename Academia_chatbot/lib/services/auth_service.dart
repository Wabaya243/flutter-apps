import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class AuthService {
  final String baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _token;

  AuthService(this.baseUrl);

  String? get token => _token;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  Future<void> loadToken() async {
    _token = await _storage.read(key: 'access_token');
  }

  // Aligne le client Flutter avec le backend FastAPI existant.
  // Backend attendu:
  //   POST /login  → payload { email, mdp } → { ok: true, user: {...} }
  // Si un access_token est un jour renvoyé, on le stocke; sinon on garde un jeton factice 'ok'.
  Future<void> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'mdp': password}),
    );
    if (res.statusCode != 200) {
      throw Exception('Login failed: ${res.body}');
    }
    final Map<String, dynamic> data = jsonDecode(res.body) as Map<String, dynamic>;
    final tok = (data['access_token'] as String?) ?? (data['ok'] == true ? 'ok' : null);
    if (tok == null || tok.isEmpty) {
      throw Exception('Authentification refusée');
    }
    _token = tok;
    await _storage.write(key: 'access_token', value: tok);
    if (data['user'] != null) {
      await _storage.write(key: 'user', value: jsonEncode(data['user']));
    }
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'user');
  }
}

// Singleton léger pour tout le projet
final AuthService authService = AuthService(kAuthBaseUrl);

