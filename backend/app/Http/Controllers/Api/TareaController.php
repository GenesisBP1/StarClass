<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Tarea;
use Illuminate\Support\Facades\DB;


class TareaController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'clase_id' => 'required|exists:clases,id',
            'titulo' => 'required|string|max:150',
            'descripcion' => 'nullable|string',
            'fecha_entrega' => 'nullable|date',
        ]);

        $tarea = Tarea::create([
            'clase_id' => $request->clase_id,
            'titulo' => $request->titulo,
            'descripcion' => $request->descripcion,
            'fecha_entrega' => $request->fecha_entrega,
        ]);

        return response()->json([
            'message' => 'Tarea creada correctamente',
            'tarea' => $tarea
        ], 201);
    }

    public function tareasPorClase($id)
    {
        $tareas = Tarea::where('clase_id', $id)->get();

        return response()->json([
            'tareas' => $tareas
        ]);
    }


    public function actualizar(Request $request, $id)
{
    $request->validate([
        'titulo' => 'required|string|max:150',
        'descripcion' => 'nullable|string',
        'fecha_entrega' => 'nullable|date',
    ]);

    DB::table('tareas')
        ->where('id', $id)
        ->update([
            'titulo' => $request->titulo,
            'descripcion' => $request->descripcion,
            'fecha_entrega' => $request->fecha_entrega,
            'updated_at' => now(),
        ]);

    return response()->json([
        'message' => 'Tarea actualizada correctamente'
    ]);
}

public function eliminar($id)
{
    DB::table('tareas')
        ->where('id', $id)
        ->delete();

    return response()->json([
        'message' => 'Tarea eliminada correctamente'
    ]);
}

public function entregasTarea($id)
{
    $entregas = DB::table('entregas_tareas')
        ->join('usuarios', 'entregas_tareas.alumno_id', '=', 'usuarios.id')
        ->where('entregas_tareas.tarea_id', $id)
        ->select(
            'usuarios.id',
            'usuarios.nombre',
            'usuarios.correo',
            'entregas_tareas.fecha_entrega',
            'entregas_tareas.estado'
        )
        ->get();

    return response()->json([
        'entregas' => $entregas
    ]);
}

public function reporteTareasClase($id)
{
    $fecha = request()->query('fecha');
    $estado = request()->query('estado');

    $query = DB::table('tareas')
        ->where('clase_id', $id);

    if ($fecha) {
        $query->where('fecha_entrega', $fecha);
    }

    $tareas = $query->get();

    $reporte = $tareas->map(function ($tarea) {
        if ($tarea->fecha_entrega < now()->toDateString()) {
            $estado = 'Vencida';
        } else {
            $estado = 'Próxima';
        }

        return [
            'id' => $tarea->id,
            'titulo' => $tarea->titulo,
            'descripcion' => $tarea->descripcion,
            'fecha_entrega' => $tarea->fecha_entrega,
            'estado' => $estado,
        ];
    });

    if ($estado && $estado !== 'Todos') {
        $reporte = $reporte->where('estado', $estado);
    }

    return response()->json([
        'total_tareas' => $reporte->count(),
        'tareas_vencidas' => $reporte->where('estado', 'Vencida')->count(),
        'tareas_proximas' => $reporte->where('estado', 'Próxima')->count(),
        'reporte' => $reporte->values()
    ]);
}

}