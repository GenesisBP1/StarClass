<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('codigos_qr', function (Blueprint $table) {
            $table->dropForeign('codigos_qr_ibfk_1');
        });

        DB::statement('ALTER TABLE codigos_qr MODIFY alumno_id BIGINT UNSIGNED NULL');

        Schema::table('codigos_qr', function (Blueprint $table) {
            $table->foreign('alumno_id')
                ->references('id')
                ->on('usuarios')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('codigos_qr', function (Blueprint $table) {
            $table->dropForeign(['alumno_id']);
        });

        DB::statement('ALTER TABLE codigos_qr MODIFY alumno_id BIGINT UNSIGNED NOT NULL');

        Schema::table('codigos_qr', function (Blueprint $table) {
            $table->foreign('alumno_id')
                ->references('id')
                ->on('usuarios');
        });
    }
};