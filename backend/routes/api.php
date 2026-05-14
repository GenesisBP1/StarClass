<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ClaseController;
use App\Http\Controllers\Api\TareaController;
use App\Http\Controllers\Api\EntregaController;
use App\Http\Controllers\Api\AsistenciaController;
use App\Http\Controllers\Api\QrController;
use App\Http\Controllers\Api\ExportController;

/*
|--------------------------------------------------------------------------
| Rutas públicas
|--------------------------------------------------------------------------
*/
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

/*
|--------------------------------------------------------------------------
| Rutas protegidas
|--------------------------------------------------------------------------
*/
Route::middleware('auth:sanctum')->group(function () {

    /*
    |--------------------------------------------------------------------------
    | Rutas compartidas (maestro y alumno)
    |--------------------------------------------------------------------------
    */
    Route::get('/clases', [ClaseController::class, 'index']);
    Route::get('/clases/{id}', [ClaseController::class, 'show']);
    Route::get('/clases/{id}/tareas', [TareaController::class, 'tareasPorClase']);

    // QR
    Route::post('/qr/validar', [QrController::class, 'validar']);
    Route::post('/qr/generar', [QrController::class, 'generar']);

    // Entrega (usada por alumno al generar QR y por maestro al escanear)
    Route::post('/tareas/entregar', [EntregaController::class, 'entregar']);

    /*
    |--------------------------------------------------------------------------
    | Rutas solo maestro
    |--------------------------------------------------------------------------
    */
    Route::middleware('role:maestro')->group(function () {
        // Clases
        Route::post('/clases', [ClaseController::class, 'store']);
        Route::get('/clases/maestro/{id}', [ClaseController::class, 'clasesMaestro']);
        Route::put('/clases/{id}', [ClaseController::class, 'actualizar']);
        Route::delete('/clases/{id}', [ClaseController::class, 'eliminar']);
        Route::get('/clases/{id}/alumnos', [ClaseController::class, 'alumnosClase']);

        // Tareas
        Route::post('/tareas', [TareaController::class, 'store']);
        Route::put('/tareas/{id}', [TareaController::class, 'actualizar']);
        Route::delete('/tareas/{id}', [TareaController::class, 'eliminar']);
        Route::get('/clases/{id}/reporte-tareas', [TareaController::class, 'reporteTareasClase']);

        // Reportes y asistencias
        Route::get('/tareas/{id}/entregas', [EntregaController::class, 'entregasPorTarea']);
        Route::get('/tareas/{id}/reporte', [EntregaController::class, 'reporteTarea']);
        Route::get('/clases/{id}/asistencias', [AsistenciaController::class, 'asistenciasPorClase']);

        // Exportaciones
        Route::get('/export/asistencias/{id}', [ExportController::class, 'exportarAsistencias']);
        Route::get('/export/entregas/{id}', [ExportController::class, 'exportarEntregas']);
        Route::get('/export/tareas/{id}', [ExportController::class, 'exportarTareas']);
    });

    /*
    |--------------------------------------------------------------------------
    | Rutas solo alumno
    |--------------------------------------------------------------------------
    */
    Route::middleware('role:alumno')->group(function () {
        Route::get('/clases/alumno/{id}', [ClaseController::class, 'clasesAlumno']);
        Route::post('/clases/unirse', [ClaseController::class, 'unirse']);
        Route::post('/asistencias/registrar', [AsistenciaController::class, 'registrar']);
    });
});