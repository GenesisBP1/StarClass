<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Exports\AsistenciasExport;
use Maatwebsite\Excel\Facades\Excel;
use App\Exports\EntregasExport;
use App\Exports\TareasExport;

class ExportController extends Controller
{
    public function exportarAsistencias($claseId)
    {
        $fechaInicio = request()->query('fecha_inicio');
        $fechaFin = request()->query('fecha_fin');
        $estado = request()->query('estado', 'Todos');
        $busqueda = request()->query('busqueda');

        return Excel::download(
            new AsistenciasExport($claseId, $fechaInicio, $fechaFin, $estado, $busqueda),
            'reporte_asistencias.xlsx'
        );
    }
    
    public function exportarEntregas($tareaId)
    {
        $fechaInicio = request()->query('fecha_inicio');
        $fechaFin = request()->query('fecha_fin');
        $estado = request()->query('estado', 'Todos');
        $busqueda = request()->query('busqueda');

        return Excel::download(
            new EntregasExport($tareaId, $fechaInicio, $fechaFin, $estado, $busqueda),
            'reporte_entregas.xlsx'
        );
    }

    public function exportarTareas($claseId)
    {
        $fechaInicio = request()->query('fecha_inicio');
        $fechaFin = request()->query('fecha_fin');
        $estado = request()->query('estado', 'Todos');
        $busqueda = request()->query('busqueda');

        return Excel::download(
            new TareasExport($claseId, $fechaInicio, $fechaFin, $estado, $busqueda),
            'reporte_tareas.xlsx'
        );
    }
}