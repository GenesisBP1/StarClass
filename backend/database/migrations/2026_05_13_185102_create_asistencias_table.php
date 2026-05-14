<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('asistencias', function (Blueprint $table) {
            $table->id();
            $table->foreignId('clase_id')->constrained('clases')->cascadeOnDelete();
            $table->foreignId('alumno_id')->constrained('usuarios')->cascadeOnDelete();
            $table->date('fecha');
            $table->time('hora');
            $table->string('estado')->default('presente');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('asistencias');
    }
};