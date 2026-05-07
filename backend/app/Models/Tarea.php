<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Tarea extends Model
{
    protected $table = 'tareas';

    protected $fillable = [
        'clase_id',
        'titulo',
        'descripcion',
        'fecha_entrega',
    ];
}