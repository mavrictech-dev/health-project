# Tablero de ejecucion

Registro inicial del 2 de noviembre de 2026: todos los IDs del plan se crearon
POR_VERIFICAR. Los cambios siguientes requieren evidencia y revision del
supervisor. Estados: POR_VERIFICAR → LISTA → EN_CURSO → EN_REVISION → INTEGRADA →
VALIDADA; BLOQUEADA registra causa, responsable y trabajo independiente.

Supervisor unico escritor. Run run_624b9269b491; programador retenido en su
worktree. No commits, push, integracion en main o publicacion.

| ID | Responsable | Dependencias | Estado | Archivos/evidencia | Hallazgo / siguiente accion |
| --- | --- | --- | --- | --- | --- |
| ARQ-01 | Arquitecto | Ninguna | VALIDADA | ESTADO.md; fuentes y HP-ORCH-01 | Matriz revisada; brechas runtime conservadas |
| ARQ-02 | Arquitecto + programador | ARQ-01 | VALIDADA | DECISIONES.md D-02/04/05; msg_393227f665f1 acuerdo | Primer corte acordado; revisiones SaaS pendientes explicitas |
| QA-01 | Programador como calidad; revision arquitecto | ARQ-01 | BLOQUEADA (ejecucion real) | QA-01.A + R1 VALIDADA e integrada localmente;23/23 supervisor/config OK | Daemon local ausente, responsable entorno; INT/SAAS independientes continuan |
| INT-01 | Programador frontend | ARQ-02 | INTEGRADA (A validada offline) | INT-01.A+R1,46 tests/check/probe/live16 supervisor;14 archivos en health/production-wave0 | Validacion real de backend pendiente; no habilitacion productiva |
| SAAS-01 | Programador frontend/backend | INT-01 | EN_CURSO | SAAS-01.A task_c8012881a8b2 / ctx_883d9a5e2c94 | Alta/listado/detalle API; parent aun sin validar |
| ORG-01 | Programador | SAAS-01 | POR_VERIFICAR | — | Sedes/equipo y cuotas servidor |
| IAM-01 | Programador/operacion | ARQ-02, ORG-01 circuito | POR_VERIFICAR | — | Invitaciones/correo publico |
| PAC-01 | Programador | INT-01, ORG-01 | POR_VERIFICAR | — | Pacientes/responsables y revisiones |
| AGE-01 | Programador | PAC-01, ORG-01 | POR_VERIFICAR | — | Agenda concurrente |
| CLI-01 | Programador | PAC-01, AGE-01 | POR_VERIFICAR | — | Historia entre sedes |
| ESP-01 | Programador | CLI-01 | POR_VERIFICAR | — | Graficos persistentes |
| ESP-02 | Arquitecto/calidad/profesional | ARQ-01, ESP-01 por perfil | POR_VERIFICAR | — | No habilitar sin revision profesional |
| DOC-01 | Programador | CLI-01, contrato almacenamiento | POR_VERIFICAR | — | PDF y adjuntos privados |
| POR-01 | Programador | PAC-01, AGE-01, DOC-01 | POR_VERIFICAR | — | Portal con vinculos |
| AUD-01 | Programador/calidad | ARQ-02, cada entrega | POR_VERIFICAR | — | Correlacion/auditoria sin secretos |
| SEG-01 | Arquitecto/programador calidad | ARQ-02 | POR_VERIFICAR | — | Amenazas/permisos/2FA |
| DAT-01 | Arquitecto/producto | ARQ-01 | POR_VERIFICAR | — | Politicas con revision legal/profesional |
| OPS-01 | Programador operacion | ARQ-02 | POR_VERIFICAR | — | Entornos y despliegue |
| OPS-02 | Programador calidad | OPS-01, DOC-01 | POR_VERIFICAR | — | Restauracion de copia |
| OPS-03 | Programador | OPS-01, AUD-01 | POR_VERIFICAR | — | Sonda/alertas/incidentes |
| REL-01 | Arquitecto/programador | QA-01, OPS-01 | POR_VERIFICAR | — | Entrega/reversion |
| QA-02 | Programador calidad | Recorridos, OPS-01 | POR_VERIFICAR | — | Carga/fallos con objetivos definidos |
| COM-01 | Producto/programador | SAAS-01 | POR_VERIFICAR | — | Ciclo comercial y caja del piloto |
| EXT-01 | Producto/programador | COM-01, proveedor | POR_VERIFICAR | — | Sin costos/proveedores inventados |
| PIL-01 | Producto/clinica/calidad/arquitecto | Alcance + SEG/DAT/OPS/REL/QA | POR_VERIFICAR | — | Autorizacion explicita de datos reales/salida |

Etapa posterior conservada: hospital/camas/jaulas/medicacion, cirugia/anestesia,
urgencias, diagnostico/laboratorio/imagenes, farmacia/inventario, terapias,
especialidades avanzadas, transfusion, trasplante, reproduccion y poblacion
veterinaria. Cada paquete requiere especificacion, permisos, pruebas y aprobacion
clinica; aun POR_VERIFICAR, sin IDs originales adicionales en el plan.
