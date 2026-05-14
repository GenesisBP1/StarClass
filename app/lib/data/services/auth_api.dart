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
  Future<dynamic> asistenciasPorClase(
    @Path("id") int id,
    @Query("fecha") String? fecha,
  );
  
  @POST("/qr/generar")
  Future<dynamic> generarQr(@Body() Map<String, dynamic> data);
  
  @POST("/qr/validar")
  Future<dynamic> validarQr(@Body() Map<String, dynamic> data);
  
  @PUT("/clases/{id}")
  Future<dynamic> actualizarClase(
    @Path("id") int id,
    @Body() Map<String, dynamic> data,
  );
  
  @DELETE("/clases/{id}")
  Future<dynamic> eliminarClase(@Path("id") int id);
  
  @PUT("/tareas/{id}")
  Future<dynamic> actualizarTarea(
    @Path("id") int id,
    @Body() Map<String, dynamic> data,
  );
  
  @DELETE("/tareas/{id}")
  Future<dynamic> eliminarTarea(@Path("id") int id);
  
  @GET("/clases/{id}/alumnos")
  Future<dynamic> alumnosClase(@Path("id") int id);
  
  @GET("/tareas/{id}/reporte")
  Future<dynamic> reporteTarea(
    @Path("id") int id,
    @Query("fecha") String? fecha,
  );

    @GET("/clases/{id}/reporte-tareas")
  Future<dynamic> reporteTareasClase(
    @Path("id") int id,
    @Query("fecha") String? fecha,
    @Query("estado") String? estado,
  );

}