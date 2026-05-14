<?php

namespace App\Exports;

use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Carbon\Carbon;

class EntregasExport implements FromCollection, WithHeadings
{
    protected $tareaId;
    protected $fechaInicio;
    protected $fechaFin;
    protected $estado;
    protected $busqueda;

    public function __construct($tareaId, $fechaInicio = null, $fechaFin = null, $estado = 'Todos', $busqueda = null)
    {
        $this->tareaId = $tareaId;
        $this->fechaInicio = $fechaInicio;
        $this->fechaFin = $fechaFin;
        $this->estado = $estado;
        $this->busqueda = $busqueda;
    }

    public function collection()
    {
        $tarea = DB::table('tareas')->where('id', $this->tareaId)->first();

        if (!$tarea) {
            return collect([]);
        }

        $alumnosQuery = DB::table('alumnos_clases')
            ->join('usuarios', 'alumnos_clases.alumno_id', '=', 'usuarios.id')
            ->where('alumnos_clases.clase_id', $tarea->clase_id)
            ->select(
                'usuarios.id',
                'usuarios.nombre',
                'usuarios.correo'
            );

        if ($this->busqueda) {
            $busq = '%' . $this->busqueda . '%';
            $alumnosQuery->where(function ($q) use ($busq) {
                $q->where('usuarios.nombre', 'like', $busq)
                    ->orWhere('usuarios.correo', 'like', $busq);
            });
        }

        $alumnos = $alumnosQuery->get();

        $entregasQuery = DB::table('tareas_entregadas')
            ->where('tarea_id', $this->tareaId);

        if ($this->fechaInicio && $this->fechaFin) {
            $inicio = Carbon::parse($this->fechaInicio)->toDateString();
            $fin = Carbon::parse($this->fechaFin)->toDateString();
            $entregasQuery->whereBetween('fecha_revision', [$inicio, $fin]);
        } elseif ($this->fechaInicio) {
            $entregasQuery->where('fecha_revision', Carbon::parse($this->fechaInicio)->toDateString());
        }

        $entregas = $entregasQuery->get();

        $rows = $alumnos->map(function ($alumno) use ($entregas, $tarea) {
            $entrega = $entregas->firstWhere('alumno_id', $alumno->id);

            return [
                'tarea' => $tarea->titulo,
                'fecha_entrega_programada' => $tarea->fecha_entrega,
                'nombre' => $alumno->nombre,
                'correo' => $alumno->correo,
                'fecha_revision' => $entrega->fecha_revision ?? 'Sin entrega',
                'hora_revision' => $entrega->hora_revision ?? 'Sin entrega',
                'estado' => $entrega ? 'Entregada' : 'Pendiente',
            ];
        });

        // Apply estado filter
        if ($this->estado && $this->estado !== 'Todos') {
            $rows = $rows->filter(function ($r) {
                return $r['estado'] === $this->estado;
            })->values();
        }

        return $rows;
    }

    public function headings(): array
    {
        return [
            'Tarea',
            'Fecha de entrega',
            'Nombre del alumno',
            'Correo',
            'Fecha de revisión',
            'Hora de revisión',
            'Estado',
        ];
    }
}