import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_api.g.dart';

@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String baseUrl}) = _AuthApi;

  @POST("/login")
  Future<dynamic> login(@Body() Map<String, dynamic> data);

  @POST("/register")
  Future<dynamic> register(@Body() Map<String, dynamic> data);

  @GET("/clases/alumno/{id}")
  Future<dynamic> clasesAlumno(@Path("id") int id);

  @GET("/clases/maestro/{id}")
  Future<dynamic> clasesMaestro(@Path("id") int id);

  @POST("/clases")
  Future<dynamic> crearClase(@Body() Map<String, dynamic> data);

  @POST("/clases/unirse")
  Future<dynamic> unirseClase(@Body() Map<String, dynamic> data);

  @GET("/clases/{id}/tareas")
  Future<dynamic> tareasPorClase(@Path("id") int id);

  @POST("/tareas")
  Future<dynamic> crearTarea(@Body() Map<String, dynamic> data);

  @POST("/tareas/entregar")
  Future<dynamic> entregarTarea(@Body() Map<String, dynamic> data);
  
  @GET("/tareas/{id}/entregas")
  Future<dynamic> entregasPorTarea(@Path("id") int id);

  @POST("/asistencias/registrar")
  Future<dynamic> registrarAsistencia(@Body() Map<String, dynamic> data);

  @GET("/clases/{id}/asistencias")
  Future<dynamic> asistenciasPorClase(@Path("id") int id);

}