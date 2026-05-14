<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('alumnos_clases', function (Blueprint $table) {
            $table->id();
            $table->foreignId('alumno_id')->constrained('usuarios')->cascadeOnDelete();
            $table->foreignId('clase_id')->constrained('clases')->cascadeOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('alumnos_clases');
    }
};