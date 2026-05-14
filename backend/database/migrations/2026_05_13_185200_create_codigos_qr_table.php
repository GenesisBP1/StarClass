<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('codigos_qr', function (Blueprint $table) {
            $table->id();
            $table->foreignId('alumno_id')->nullable()->constrained('usuarios')->nullOnDelete();
            $table->string('codigo', 100)->unique();
            $table->string('tipo_uso');
            $table->unsignedBigInteger('referencia_id');
            $table->timestamp('fecha_generacion')->nullable();
            $table->timestamp('fecha_expiracion')->nullable();
            $table->string('estado')->default('activo');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('codigos_qr');
    }
};
