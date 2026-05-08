<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class QrController extends Controller
{
    public function generar(Request $request)
    {
        $request->validate([
            'alumno_id' => 'nullable|exists:usuarios,id',
            'tipo_uso' => 'required|in:asistencia,tarea',
            'referencia_id' => 'required|integer',
        ]);

        $codigo = Str::random(40);

        DB::table('codigos_qr')->insert([
            'alumno_id' => $request->alumno_id ?? null,
            'codigo' => $codigo,
            'tipo_uso' => $request->tipo_uso,
            'referencia_id' => $request->referencia_id,
            'fecha_generacion' => now(),
            'fecha_expiracion' => now()->addMinutes(5),
            'estado' => 'activo',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'message' => 'QR generado correctamente',
            'codigo' => $codigo,
            'tipo_uso' => $request->tipo_uso,
            'referencia_id' => $request->referencia_id,
            'alumno_id' => $request->alumno_id ?? null,
        ]);
    }

    public function validar(Request $request)
    {
        $request->validate([
            'codigo' => 'required|string',
        ]);

        $qr = DB::table('codigos_qr')
            ->where('codigo', $request->codigo)
            ->first();

        if (!$qr) {
            return response()->json([
                'message' => 'QR no encontrado'
            ], 404);
        }

        if ($qr->estado !== 'activo') {
            return response()->json([
                'message' => 'QR ya fue usado o expirado'
            ], 400);
        }

        if (now()->greaterThan($qr->fecha_expiracion)) {
            DB::table('codigos_qr')
                ->where('id', $qr->id)
                ->update([
                    'estado' => 'expirado',
                    'updated_at' => now(),
                ]);

            return response()->json([
                'message' => 'QR expirado'
            ], 400);
        }

        DB::table('codigos_qr')
            ->where('id', $qr->id)
            ->update([
                'estado' => 'usado',
                'updated_at' => now(),
            ]);

        return response()->json([
            'message' => 'QR válido',
            'qr' => $qr,
        ]);
    }
}