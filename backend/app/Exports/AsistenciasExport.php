<?php

namespace App\Exports;

use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Carbon\Carbon;
use Carbon\CarbonPeriod;

class AsistenciasExport implements FromCollection, WithHeadings
{
    protected $claseId;
    protected $fechaInicio;
    protected $fechaFin;
    protected $estado;
    protected $busqueda;

    public function __construct($claseId, $fechaInicio = null, $fechaFin = null, $estado = 'Todos', $busqueda = null)
    {
        $this->claseId = $claseId;
        $this->fechaInicio = $fechaInicio;
        $this->fechaFin = $fechaFin;
        $this->estado = $estado;
        $this->busqueda = $busqueda;
    }

    public function collection()
    {
        $inicio = $this->fechaInicio ? Carbon::parse($this->fechaInicio)->startOfDay() : null;
        $fin = $this->fechaFin ? Carbon::parse($this->fechaFin)->startOfDay() : null;

        // If no range provided, fallback to latest date (backwards compatible)
        if (!$inicio && !$fin) {
            $ultima = DB::table('asistencias')
                ->where('clase_id', $this->claseId)
                ->max('fecha');

            if ($ultima) {
                $inicio = Carbon::parse($ultima);
                $fin = Carbon::parse($ultima);
            }
        }

        // Build date period
        $fechas = [];
        if ($inicio && $fin) {
            $period = CarbonPeriod::create($inicio->toDateString(), $fin->toDateString());
            foreach ($period as $d) {
                $fechas[] = $d->toDateString();
            }
        }

        $alumnosQuery = DB::table('alumnos_clases')
            ->join('usuarios', 'alumnos_clases.alumno_id', '=', 'usuarios.id')
            ->where('alumnos_clases.clase_id', $this->claseId)
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

        // If we have no specific dates, return alumnos with a placeholder
        if (empty($fechas)) {
            return $alumnos->map(function ($alumno) {
                return [
                    'fecha_asistencia' => 'Sin registros',
                    'dia_asistencia' => 'Sin día',
                    'nombre' => $alumno->nombre,
                    'correo' => $alumno->correo,
                    'hora' => 'Sin registro',
                    'estado' => 'Falta',
                ];
            });
        }

        // Fetch asistencias within range
        $asistenciasQuery = DB::table('asistencias')
            ->where('clase_id', $this->claseId)
            ->whereBetween('fecha', [$inicio->toDateString(), $fin->toDateString()]);

        $asistencias = $asistenciasQuery->get();

        $rows = collect();

        foreach ($fechas as $fecha) {
            foreach ($alumnos as $alumno) {
                $asistencia = $asistencias->firstWhere('alumno_id', $alumno->id);
                // ensure it's the record for this fecha
                if ($asistencia && $asistencia->fecha !== $fecha) {
                    $asistencia = $asistencias->first(function ($a) use ($alumno, $fecha) {
                        return $a->alumno_id == $alumno->id && $a->fecha == $fecha;
                    });
                }

                $present = (bool) $asistencia;

                // Apply estado filter
                if ($this->estado && $this->estado !== 'Todos') {
                    if ($this->estado === 'Presente' && !$present) {
                        continue;
                    }
                    if ($this->estado === 'Falta' && $present) {
                        continue;
                    }
                }

                $rows->push([
                    'fecha_asistencia' => $fecha,
                    'dia_asistencia' => $fecha ? Carbon::parse($fecha)->locale('es')->translatedFormat('l') : 'Sin día',
                    'nombre' => $alumno->nombre,
                    'correo' => $alumno->correo,
                    'hora' => $asistencia->hora ?? 'Sin registro',
                    'estado' => $present ? 'Presente' : 'Falta',
                ]);
            }
        }

        return $rows;
    }

    public function headings(): array
    {
        return [
            'Fecha de asistencia',
            'Día de asistencia',
            'Nombre del alumno',
            'Correo',
            'Hora',
            'Estado',
        ];
    }
}