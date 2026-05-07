<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AsistenciaController extends Controller
{
    public function registrar(Request $request)
    {
        $request->validate([
            'clase_id' => 'required|exists:clases,id',
            'alumno_id' => 'required|exists:usuarios,id',
        ]);

        $fecha = now()->toDateString();

        $existe = DB::table('asistencias')
            ->where('clase_id', $request->clase_id)
            ->where('alumno_id', $request->alumno_id)
            ->where('fecha', $fecha)
            ->exists();

        if ($existe) {
            return response()->json([
                'message' => 'La asistencia ya fue registrada hoy'
            ], 400);
        }

        DB::table('asistencias')->insert([
            'clase_id' => $request->clase_id,
            'alumno_id' => $request->alumno_id,
            'fecha' => $fecha,
            'hora' => now()->toTimeString(),
            'estado' => 'presente',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'message' => 'Asistencia registrada correctamente'
        ]);
    }

    public function asistenciasPorClase($id)
    {
        $asistencias = DB::table('asistencias')
            ->join('usuarios', 'asistencias.alumno_id', '=', 'usuarios.id')
            ->where('asistencias.clase_id', $id)
            ->select(
                'asistencias.id',
                'usuarios.nombre',
                'usuarios.correo',
                'asistencias.fecha',
                'asistencias.hora',
                'asistencias.estado'
            )
            ->get();

        return response()->json([
            'asistencias' => $asistencias
        ]);
    }
}