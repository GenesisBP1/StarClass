<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tareas_entregadas', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tarea_id')->constrained('tareas')->cascadeOnDelete();
            $table->foreignId('alumno_id')->constrained('usuarios')->cascadeOnDelete();
            $table->date('fecha_revision');
            $table->time('hora_revision');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tareas_entregadas');
    }
};