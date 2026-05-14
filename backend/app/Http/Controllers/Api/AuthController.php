<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    // 🔹 REGISTRO
    public function register(Request $request)
    {
        $request->validate([
            'nombre' => 'required|string',
            'correo' => 'required|email|unique:usuarios,correo',
            'password' => 'required|min:6',
            'rol' => 'required|in:alumno,maestro'
        ]);

        $user = User::create([
            'nombre' => $request->nombre,
            'correo' => $request->correo,
            'password' => Hash::make($request->password),
            'rol' => $request->rol
        ]);

        return response()->json([
            'message' => 'Usuario registrado',
            'user' => $user
        ]);
    }

    // 🔹 LOGIN
    public function login(Request $request)
    {
        $request->validate([
            'correo' => 'required|email',
            'password' => 'required',
        ]);

        $usuario = User::where('correo', $request->correo)->first();

        if (!$usuario || !Hash::check($request->password, $usuario->password)) {
            return response()->json([
                'message' => 'Credenciales incorrectas'
            ], 401);
        }

        $token = $usuario->createToken('app_token')->plainTextToken;

        return response()->json([
            'message' => 'Login exitoso',
            'token' => $token,
            'user' => $usuario
        ]);
    }
}