import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExportService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://starclass-backend.onrender.com/api",
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  Future<void> descargarArchivo(
    String endpoint,
    String nombreArchivo,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final dir = await getApplicationDocumentsDirectory();
      final path = "${dir.path}/$nombreArchivo";

      final headers = <String, String>{
        'Accept': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      await dio.download(
        endpoint,
        path,
        options: Options(
          headers: headers,
        ),
      );

      await OpenFilex.open(path);
    } catch (e) {
      print("Error descargando archivo: $e");
      rethrow;
    }
  }

  Future<void> exportarAsistencias(int claseId, {String? fecha}) async {
    // For backward compatibility: keep single fecha param support
    await exportarAsistenciasAvanzado(
      claseId,
      fechaInicio: fecha,
    );
  }

  Future<void> exportarEntregas(int tareaId, {String? fecha}) async {
    // Backwards compatible wrapper
    await exportarEntregasAvanzado(
      tareaId,
      fechaInicio: fecha,
    );
  }

  Future<void> exportarTareas(
    int claseId, {
    String? fecha,
    String? estado,
  }) async {
    // Backwards compatible wrapper
    await exportarTareasAvanzado(
      claseId,
      fechaInicio: fecha,
      estado: estado,
    );
  }

  // New advanced-export methods with optional filters
  Future<void> exportarAsistenciasAvanzado(
    int claseId, {
    String? fechaInicio,
    String? fechaFin,
    String? estado,
    String? busqueda,
  }) async {
    String endpoint = "/export/asistencias/$claseId";

    final params = <String, String>{};

    if (fechaInicio != null && fechaInicio.isNotEmpty) {
      params['fecha_inicio'] = fechaInicio;
    }
    if (fechaFin != null && fechaFin.isNotEmpty) {
      params['fecha_fin'] = fechaFin;
    }
    if (estado != null && estado.isNotEmpty && estado != 'Todos') {
      params['estado'] = estado;
    }
    if (busqueda != null && busqueda.isNotEmpty) {
      params['busqueda'] = busqueda;
    }

    if (params.isNotEmpty) {
      final q = Uri(queryParameters: params).query;
      endpoint += '?$q';
    }

    await descargarArchivo(endpoint, "reporte_asistencias.xlsx");
  }

  Future<void> exportarEntregasAvanzado(
    int tareaId, {
    String? fechaInicio,
    String? fechaFin,
    String? estado,
    String? busqueda,
  }) async {
    String endpoint = "/export/entregas/$tareaId";

    final params = <String, String>{};

    if (fechaInicio != null && fechaInicio.isNotEmpty) {
      params['fecha_inicio'] = fechaInicio;
    }
    if (fechaFin != null && fechaFin.isNotEmpty) {
      params['fecha_fin'] = fechaFin;
    }
    if (estado != null && estado.isNotEmpty && estado != 'Todos') {
      params['estado'] = estado;
    }
    if (busqueda != null && busqueda.isNotEmpty) {
      params['busqueda'] = busqueda;
    }

    if (params.isNotEmpty) {
      final q = Uri(queryParameters: params).query;
      endpoint += '?$q';
    }

    await descargarArchivo(endpoint, "reporte_entregas.xlsx");
  }

  Future<void> exportarTareasAvanzado(
    int claseId, {
    String? fechaInicio,
    String? fechaFin,
    String? estado,
    String? busqueda,
  }) async {
    String endpoint = "/export/tareas/$claseId";

    final params = <String, String>{};

    if (fechaInicio != null && fechaInicio.isNotEmpty) {
      params['fecha_inicio'] = fechaInicio;
    }
    if (fechaFin != null && fechaFin.isNotEmpty) {
      params['fecha_fin'] = fechaFin;
    }
    if (estado != null && estado.isNotEmpty && estado != 'Todos') {
      params['estado'] = estado;
    }
    if (busqueda != null && busqueda.isNotEmpty) {
      params['busqueda'] = busqueda;
    }

    if (params.isNotEmpty) {
      final q = Uri(queryParameters: params).query;
      endpoint += '?$q';
    }

    await descargarArchivo(endpoint, "reporte_tareas.xlsx");
  }
}