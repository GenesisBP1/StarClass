import 'api_client.dart';
import 'auth_api.dart';

class AuthService {
  final AuthApi _api = AuthApi(ApiClient.getDio());

  Future<dynamic> login(String correo, String password) async {
    final response = await _api.login({
      "correo": correo,
      "password": password,
    });

    return response;
  }
}