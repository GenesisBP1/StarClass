<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasFactory;
    use HasApiTokens;

    // 🔹 IMPORTANTE: tabla correcta
    protected $table = 'usuarios';

    // 🔹 Campos que puedes insertar
    protected $fillable = [
        'nombre',
        'correo',
        'password',
        'rol'
    ];

    // 🔹 Ocultar password en respuestas
    protected $hidden = [
        'password',
    ];
}