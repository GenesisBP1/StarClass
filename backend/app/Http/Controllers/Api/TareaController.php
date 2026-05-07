<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Tarea;

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
}