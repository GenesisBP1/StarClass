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

  Future<dynamic> register(Map<String, dynamic> data) async {
    return await _api.register(data);
  }

  Future<dynamic> obtenerClasesAlumno(int id) async {
    return await _api.clasesAlumno(id);
  }

  Future<dynamic> obtenerClasesMaestro(int id) async {
    return await _api.clasesMaestro(id);
  }

  Future<dynamic> crearClase(Map<String, dynamic> data) async {
    return await _api.crearClase(data);
  }

  Future<dynamic> unirseClase(Map<String, dynamic> data) async {
    return await _api.unirseClase(data);
  }

  Future<dynamic> obtenerTareasPorClase(int id) async {
    return await _api.tareasPorClase(id);
  }

  Future<dynamic> crearTarea(Map<String, dynamic> data) async {
    return await _api.crearTarea(data);
  }

  Future<dynamic> entregarTarea(Map<String, dynamic> data) async {
    return await _api.entregarTarea(data);
  }

  Future<dynamic> obtenerEntregasPorTarea(int id) async {
    return await _api.entregasPorTarea(id);
  }

  Future<dynamic> registrarAsistencia(Map<String, dynamic> data) async {
  return await _api.registrarAsistencia(data);
  }
  
  Future<dynamic> obtenerAsistenciasPorClase(int id) async {
    return await _api.asistenciasPorClase(id);
  }
}