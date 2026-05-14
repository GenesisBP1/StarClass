<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EntregaController extends Controller
{
    public function entregar(Request $request)
    {
        $request->validate([
            'tarea_id' => 'required|exists:tareas,id',
            'alumno_id' => 'required|exists:usuarios,id',
        ]);

        $existe = DB::table('tareas_entregadas')
            ->where('tarea_id', $request->tarea_id)
            ->where('alumno_id', $request->alumno_id)
            ->exists();

        if ($existe) {
            return response()->json([
                'message' => 'Esta tarea ya fue entregada'
            ], 400);
        }

        DB::table('tareas_entregadas')->insert([
            'tarea_id' => $request->tarea_id,
            'alumno_id' => $request->alumno_id,
            'fecha_revision' => now()->toDateString(),
            'hora_revision' => now()->toTimeString(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'message' => 'Tarea entregada correctamente'
        ]);
    }

    public function entregasPorTarea($id)
    {
        $entregas = DB::table('tareas_entregadas')
            ->join('usuarios', 'tareas_entregadas.alumno_id', '=', 'usuarios.id')
            ->where('tareas_entregadas.tarea_id', $id)
            ->select(
                'tareas_entregadas.id',
                'usuarios.nombre',
                'usuarios.correo',
                'tareas_entregadas.fecha_revision',
                'tareas_entregadas.hora_revision'
            )
            ->get();

        return response()->json([
            'entregas' => $entregas
        ]);
    }

    public function reporteTarea($id)
    {
        $tarea = DB::table('tareas')->where('id', $id)->first();

        if (!$tarea) {
            return response()->json([
                'message' => 'Tarea no encontrada'
            ], 404);
        }

        $alumnos = DB::table('alumnos_clases')
            ->join('usuarios', 'alumnos_clases.alumno_id', '=', 'usuarios.id')
            ->where('alumnos_clases.clase_id', $tarea->clase_id)
            ->select(
                'usuarios.id',
                'usuarios.nombre',
                'usuarios.correo'
            )
            ->get();

        if ($alumnos->isEmpty()) {
            return response()->json([
                'total_alumnos' => 0,
                'total_entregadas' => 0,
                'total_pendientes' => 0,
                'reporte' => []
            ]);
        }

        $entregasQuery = DB::table('tareas_entregadas')
            ->where('tarea_id', $id);

        if (request()->filled('fecha')) {
            $entregasQuery->where('fecha_revision', request()->fecha);
        }

        $entregas = $entregasQuery->get()->keyBy('alumno_id');

        $reporte = $alumnos->map(function ($alumno) use ($entregas) {
            $entrega = $entregas->get($alumno->id);
            return [
                'alumno_id' => $alumno->id,
                'nombre' => $alumno->nombre,
                'correo' => $alumno->correo,
                'estado' => $entrega ? 'Entregada' : 'Pendiente',
                'fecha_revision' => $entrega->fecha_revision ?? null,
                'hora_revision' => $entrega->hora_revision ?? null,
            ];
        });

        return response()->json([
            'total_alumnos' => $alumnos->count(),
            'total_entregadas' => $reporte->where('estado', 'Entregada')->count(),
            'total_pendientes' => $reporte->where('estado', 'Pendiente')->count(),
            'reporte' => $reporte->values()
        ]);
    }
}