# Gestion de vinculos: arquitectura preliminar tras lectura validada

Supervisor 2026-11-10. Diseno preparatorio, NO contrato de implementacion ni
permiso para editar/aplicar SQL. C0 task_cbe1631fad10/ctx_3853dfb7a02e sigue abierto,
detenido por limite de uso del programador; analisis parcial congelado y revisado
con limites en VINCULOS_GESTION_ANALISIS_PARCIAL_20261110.json. E5 readonly real
continua aceptada. Misma pareja de cuentas, Run y worktree; sin sustituciones.

## Brechas confirmadas por fuentes

Requests.Link tiene userId/relationship/active/scopes, sin expectedRevision.
patient_links V1 tiene PK tenant/patient/user y no revision propia. El escritor
de V5 usa UPDLOCK/HOLDLOCK pero no compara una version del formulario. Ninguna
revision del paciente demuestra que un vinculo no cambio. Estas observaciones
son de codigo; no son otra inspeccion de SQL instalado ni prueba de concurrencia.

El escritor tambien valida datos y elegibilidad de concesion al desactivar,
por lo que no sirve como revocacion general de historicos vacios/desconocidos
o cuentas que perdieron membresia/rol. Gestionar requiere un flujo de retirada
que preserve historia y no convierta un historico en una nueva concesion.

## Condiciones que arquitectura exige para el siguiente contrato

- Una revision propia del vinculo y comparacion atomica SQL. Crear con version
  de ausencia no se convierte en actualizar; editar/reactivar/desactivar exige
  version vigente y responde conflicto sin escritura parcial. Lock por si solo
  no acredita ese comportamiento. Definir no-op/overflow antes de implementar.
- Cerrar el bypass del PUT heredado sin version. La opcion preferida a estudiar
  es endurecer el recurso existente mediante migracion nueva y DTO estricto;
  si se elige otro recurso, el escritor viejo tambien debe quedar protegido.
  Decidir compatibilidad/consumidores con evidencia final C0, no aplicar aun.
- Retirada explicita de una fila existente que conserve relacion/alcances
  historicos sin exigir de nuevo elegibilidad de concesion al destinatario.
  Siempre revalidar administrador actual y guardas de escritura acordadas.
- Autoridad SQL actual de sesion/host/tenant/membresia/rol, contexto REQUEST e IDs
  canonicos; denegar plataforma y PAC/RES mixtos de actor como en lectura B.
  Transaccion externa committable, SP parametrizados, runtime EXECUTE sin tablas
  o DDL y principal migrador separado. Nunca confiar en roles enviados por UI.
- GET B conserva sus siete campos, historicos y paginacion/orden. La version de
  edicion se obtiene de un recurso especifico. Candidatos por SP paginado del
  mismo tenant y paciente, proyeccion minima y elegibilidad revalidada al commit;
  no lookup global por correo ni capacidades internas IDENTITY para el cliente.
- Seleccion inequívoca de destinatario: nombres duplicados no habilitan una
  eleccion automatica. Minimizar datos y acordar desambiguacion antes de UI;
  no resolverlo mostrando UUID o exponiendo correos globales por defecto.
- Permiso de gestionar ADM/REC con guardas PORTAL/estado/modo separado de lectura
  B sin PORTAL obligatorio. Cambios de elegibilidad de destinatario, verificacion
  y BILLING/FINANCE se fijan explicitamente; no reinterpretar scopes historicos.
- Auditoria semantica y triggers de cambio con cuotas distintas de los GET.
  Rollback atomico, request/actor/tenant/target exactos y sin secretos; probar
  revision/no-op, dos editores y frontera de revocacion con consumidores portal.
- Una vista dentro de la misma ficha, confirmacion previa y foco/teclado/movil/
  tres temas. Conservar borrador ante409, resultado desconocido sin reenvio
  automatico, respuesta tardia descartada y comprobacion explicita. No prometer
  idempotencia o confirmacion del propio intento por comparar solo valores.
- Responsable administrativo sin cuenta es un modelo separado de identidad y
  autorizacion portal. Crear contacto no crea usuario/membresia/invitacion o
  acceso a historia. Cardinalidad y datos funcionales pendientes deben quedar
  acotados; no inventar facultades legales, consentimientos o retenciones.

## Reanudacion y gates

C0 debe cerrar su anexo de referencias (R55 falta), informe final y conservacion
posterior, siempre en el mismo Task/Dispatch. La cuota anunciada por el proveedor
es disponibilidad a las21:15; no es autorizacion para cambiar cuenta, modelo,
comprar creditos, crear otro Run o simular worker_done.

Supervisor termina contrato C1 tras revisar C0 completo. Secuencia prevista:
preparacion SQL/SP/CAS y verificador offline; QA SQL e instalacion por encargo
revisado; API/contratos; UI sintetica/regresion; herramienta separada y QA real
de gestion. No editar V1-V13 instaladas ni relajar el runner readonly E5. Los
paquetes compartidos son secuenciales con ownership explicito. Sin TLS/UAC/
servicios/Docker/produccion/FactuEz/datos reales o cambios de producto en este diseno.
