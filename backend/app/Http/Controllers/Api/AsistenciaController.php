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

        $inscrito = DB::table('alumnos_clases')
            ->where('alumno_id', $request->alumno_id)
            ->where('clase_id', $request->clase_id)
            ->exists();

        if (!$inscrito) {
            return response()->json([
                'message' => 'El alumno no está inscrito en esta clase'
            ], 403);
        }

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
        $fecha = request()->query('fecha');

        if (!$fecha) {
            $fecha = DB::table('asistencias')
                ->where('clase_id', $id)
                ->max('fecha');
        }

        $alumnos = DB::table('alumnos_clases')
            ->join('usuarios', 'alumnos_clases.alumno_id', '=', 'usuarios.id')
            ->where('alumnos_clases.clase_id', $id)
            ->select(
                'usuarios.id',
                'usuarios.nombre',
                'usuarios.correo'
            )
            ->get();

        $asistencias = collect();

        if ($fecha) {
            $asistencias = DB::table('asistencias')
                ->where('clase_id', $id)
                ->where('fecha', $fecha)
                ->get();
        }

        $reporte = $alumnos->map(function ($alumno) use ($asistencias) {
            $asistencia = $asistencias->firstWhere('alumno_id', $alumno->id);

            return [
                'alumno_id' => $alumno->id,
                'nombre' => $alumno->nombre,
                'correo' => $alumno->correo,
                'estado' => $asistencia ? 'Presente' : 'Falta',
                'fecha' => $asistencia->fecha ?? null,
                'hora' => $asistencia->hora ?? null,
            ];
        });

        return response()->json([
            'fecha_consultada' => $fecha,
            'total_alumnos' => $alumnos->count(),
            'total_presentes' => $reporte->where('estado', 'Presente')->count(),
            'total_faltas' => $reporte->where('estado', 'Falta')->count(),
            'reporte' => $reporte->values()
        ]);
    }
}