<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Clase;
use Illuminate\Support\Facades\DB;

class ClaseController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'nombre' => 'required|string|max:100',
            'descripcion' => 'nullable|string',
            'maestro_id' => 'required|exists:usuarios,id'
        ]);

        $codigo = strtoupper(substr(md5(uniqid()), 0, 6));

        $clase = Clase::create([
            'nombre' => $request->nombre,
            'descripcion' => $request->descripcion,
            'codigo_clase' => $codigo,
            'maestro_id' => $request->maestro_id
        ]);

        return response()->json([
            'message' => 'Clase creada correctamente',
            'clase' => $clase
        ], 201);
    }

    public function clasesMaestro($id)
    {
        $clases = Clase::where('maestro_id', $id)->get();

        return response()->json([
            'clases' => $clases
        ]);
    }

    public function index()
    {
        $clases = Clase::all();

        return response()->json([
            'clases' => $clases
        ]);
    }
    public function show($id)
    {   
        $clase = Clase::find($id);

        if (!$clase) {
            return response()->json([
                'message' => 'Clase no encontrada'
            ], 404);
        }

        return response()->json([
            'clase' => $clase
        ]);
    }

    public function update(Request $request, $id)
    {
        $clase = Clase::findOrFail($id);

        $clase->update($request->all());

        return $clase;
    }
    public function destroy($id)
    {
        $clase = Clase::findOrFail($id);
        $clase->delete();

        return response()->json(['mensaje' => 'Clase eliminada']);
    }

    public function unirse(Request $request)
{
    $request->validate([
        'codigo_clase' => 'required',
        'alumno_id' => 'required|exists:usuarios,id'
    ]);

    // Buscar la clase por código
    $clase = Clase::where('codigo_clase', $request->codigo_clase)->first();

    if (!$clase) {
        return response()->json([
            'message' => 'Código de clase inválido'
        ], 404);
    }

    // Verificar si ya está inscrito
    $existe = \DB::table('alumnos_clases')
        ->where('alumno_id', $request->alumno_id)
        ->where('clase_id', $clase->id)
        ->exists();

    if ($existe) {
        return response()->json([
            'message' => 'Ya estás inscrito en esta clase'
        ], 400);
    }

    // Insertar relación
    \DB::table('alumnos_clases')->insert([
        'alumno_id' => $request->alumno_id,
        'clase_id' => $clase->id,
        'created_at' => now(),
        'updated_at' => now()
    ]);

    return response()->json([
        'message' => 'Te uniste a la clase correctamente',
        'clase' => $clase
    ]);
}
    public function clasesAlumno($id)
{
    $clases = \DB::table('alumnos_clases')
        ->join('clases', 'alumnos_clases.clase_id', '=', 'clases.id')
        ->where('alumnos_clases.alumno_id', $id)
        ->select(
            'clases.id',
            'clases.nombre',
            'clases.descripcion',
            'clases.codigo_clase',
            'clases.maestro_id',
            'alumnos_clases.created_at as fecha_union'
        )
        ->get();

    return response()->json([
        'clases' => $clases
    ]);
}

public function actualizar(Request $request, $id)
{
    $request->validate([
        'nombre' => 'required|string',
        'descripcion' => 'nullable|string',
    ]);

    DB::table('clases')
        ->where('id', $id)
        ->update([
            'nombre' => $request->nombre,
            'descripcion' => $request->descripcion,
            'updated_at' => now(),
        ]);

    return response()->json([
        'message' => 'Clase actualizada correctamente'
    ]);
}

public function eliminar($id)
{
    DB::table('clases')
        ->where('id', $id)
        ->delete();

    return response()->json([
        'message' => 'Clase eliminada correctamente'
    ]);
}
    
}
