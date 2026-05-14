<?php

namespace App\Exports;

use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Carbon\Carbon;

class TareasExport implements FromCollection, WithHeadings
{
    protected $claseId;
    protected $fechaInicio;
    protected $fechaFin;
    protected $estado;
    protected $busqueda;

    public function __construct($claseId, $fechaInicio = null, $fechaFin = null, $estado = 'Todos', $busqueda = null)
    {
        $this->claseId = $claseId;
        $this->fechaInicio = $fechaInicio ?: null;
        $this->fechaFin = $fechaFin ?: null;
        $this->estado = $estado ?: 'Todos';
        $this->busqueda = $busqueda ?: null;
    }

    public function collection()
    {
        $clase = DB::table('clases')->where('id', $this->claseId)->first();

        $query = DB::table('tareas')
            ->where('clase_id', $this->claseId);

        if ($this->fechaInicio && $this->fechaFin) {
            $query->whereBetween('fecha_entrega', [
                Carbon::parse($this->fechaInicio)->toDateString(),
                Carbon::parse($this->fechaFin)->toDateString()
            ]);
        } elseif ($this->fechaInicio) {
            $query->whereDate('fecha_entrega', Carbon::parse($this->fechaInicio)->toDateString());
        }

        if ($this->busqueda) {
            $busq = '%' . $this->busqueda . '%';

            $query->where(function ($q) use ($busq) {
                $q->where('titulo', 'like', $busq)
                  ->orWhere('descripcion', 'like', $busq);
            });
        }

        $tareas = $query->get();

        $reporte = $tareas->map(function ($tarea) use ($clase) {
            $estado = Carbon::parse($tarea->fecha_entrega)->toDateString() < now()->toDateString()
                ? 'Vencida'
                : 'Próxima';

            return [
                'clase' => $clase->nombre ?? 'Sin clase',
                'tarea' => $tarea->titulo,
                'descripcion' => $tarea->descripcion ?? 'Sin descripción',
                'fecha_entrega' => $tarea->fecha_entrega,
                'estado' => $estado,
            ];
        });

        if ($this->estado && $this->estado !== 'Todos') {
            $reporte = $reporte->filter(function ($item) {
                return $item['estado'] === $this->estado;
            })->values();
        }

        return $reporte;
    }

    public function headings(): array
    {
        return [
            'Clase',
            'Tarea',
            'Descripción',
            'Fecha de entrega',
            'Estado',
        ];
    }
}