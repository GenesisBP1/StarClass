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
}