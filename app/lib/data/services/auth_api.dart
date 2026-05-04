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
}