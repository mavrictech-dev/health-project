# Health Project: guion para la reunión de pruebas

La modalidad principal es la **demo conectada en Docker**: frontend runtime,
API Java y SQL Server local. Se utilizan exclusivamente datos ficticios.
Instalación: [README principal](../README.md#instalar-y-abrir-la-demo-conectada-con-docker).
Ensayo conectado del 16 de noviembre aprobado: acceso, paciente, antecedente,
consulta persistida, cita/cobro, administración y reinicios. Consulta la
[revisión y evidencia](../docs/produccion/DEMO_DOCKER_LAPTOP_REVISION_20261116.md).

## Preparación antes de la reunión

1. Descarga la rama `main` y sigue la instalación Docker del README. Haz la
   primera descarga/build con anticipación: el setup crea la base SQL Server,
   sus procedimientos y las cuentas con las contraseñas de `.env.demo`.
2. Comprueba `ps -a`: SQL/backend saludables, gateway levantado y setup terminado
   con código 0. No instales Node/Java/SQL en la laptop para esta modalidad.
3. Abre `http://reunion.health.localhost:18090/acceso/` en Chrome o Edge. Si
   cambiaste DEMO_PORT, usa el mismo puerto en las URLs.
4. Entra con RUC `20000000001`, correo `profesional@example.test` y la contraseña
   `Meeting_App_2026_Only!` de la plantilla. Si cambiaste DEMO_APP_PASSWORD antes
   de inicializar, utiliza tu valor. Selecciona Sede principal · ejemplo.
5. Comprueba el paciente `DEMO-001` y ensaya el recorrido por escritura. La voz
   depende del navegador y sus servicios; no es necesaria para presentar.

Puedes comenzar así: «Esta instalación de pruebas conecta la interfaz con Java
y SQL Server. Vamos a probar acceso, pacientes, agenda e historia con datos
ficticios. El uso con pacientes reales requiere su aceptación productiva y clínica».

## Recorrido conectado de diez minutos

| Tiempo | Recorrido | Resultado que puedes comprobar |
| --- | --- | --- |
| 1 min | Acceso y sucursal | RUC/correo/contraseña y selección de sede desde el servidor |
| 2 min | Pacientes | Buscar DEMO-001; ficha e historial de antecedentes con autor/fecha |
| 3 min | Agenda y cobro | Día/semana, cita futura, revisión, pago manual y arqueo |
| 2 min | Consulta escrita | Registrar ejemplo, recuperar la consulta tras recargar |
| 2 min | Administración y cierre | Clínica/SaaS con su cuenta; resumen de lo probado y próximos pasos |

### Paciente y antecedentes

En **Pacientes**, busca `DEMO-001` o el nombre del paciente ficticio preparado.
Muestra la ficha. Si registras un antecedente, escribe «Ejemplo para la reunión;
sin uso asistencial» y enseña la versión, autor y fecha. No uses nombres,
documentos, historias o archivos de personas reales.

### Agenda, reserva y cobro

1. Abre **Agenda**. Alterna **Día** y **Semana** y comprueba la sucursal.
2. Pulsa **Nueva cita**, selecciona el paciente preparado y el profesional.
   Elige mañana y un horario que esté libre. Enseña la pantalla de revisión
   antes de **Confirmar cita**.
3. Recarga la página: la cita debe recuperarse desde la API y SQL Server.
4. Abre la cita y registra **Pagado**, un importe de ejemplo y el medio de pago.
   Se trata de un registro manual de prueba: no realiza un cargo ni envía dinero.
5. Vuelve a **Hoy** para mostrar el arqueo. Se agrupa por el día de registro del
   cobro, aunque la cita esté programada para mañana.

Como opción adicional, muestra **Agendar por voz** y la alternativa manual.
Ensaya el micrófono antes de la reunión. La evidencia de voz previa utilizó
eventos simulados y no acredita el micrófono físico de esta laptop.

### Consulta e historia

Abre la consulta del paciente preparado y escribe ejemplos en anamnesis,
examen físico, diagnóstico y tratamiento. Revisa antes de guardar. Si vinculas
una cita, muestra el resultado de atención seleccionado. Recarga y recupera
la consulta para comprobar persistencia. No presentes estos textos como una
evaluación médica, firma certificada o documento clínico emitido.

### Administración

Para administración de la clínica utiliza `admin@example.test` en el mismo
tenant/RUC. Para plataforma entra en `http://health.localhost:18090/acceso/`
con `plataforma@example.test`. Ambas cuentas usan la contraseña de aplicación
de la plantilla. Mantén separadas las funciones de profesional, administración
de clínica y plataforma: los permisos proceden del servidor.

Muestra la clínica, sedes y plan preparados. La creación de clientes no contrata
infraestructura externa, envía correo real ni procesa pagos de suscripción.
La demo estática secundaria ofrece vistas de diseño de especialidades; no las
confundas con módulos clínicos habilitados en esta instalación conectada.

## Repetir y cerrar

Los datos de esta modalidad están en el volumen SQL del proyecto Docker. Una
ventana privada o borrar datos del navegador NO restaura el escenario. No borres
el volumen ni reapliques migraciones entre reuniones. Conserva `.env.demo`,
especialmente las contraseñas y la clave JWT estable de esta instalación.

Para detener conservando los datos, desde la raíz:

```powershell
docker compose -p health-meeting-demo --env-file .env.demo -f compose.demo.yaml stop
```

Para reabrir:

```powershell
docker compose -p health-meeting-demo --env-file .env.demo -f compose.demo.yaml up -d
```

El README incluye diagnóstico y actualización. No utilices `down -v`, limpiezas
globales de Docker ni comandos de otros stacks de Health Project.

## Alternativa: presentación estática

Si eliges la [alternativa Node.js](../README.md#alternativa-demo-estática-con-nodejs),
ejecuta `npm ci`, `npm run build:demo` y `npm run preview:demo` desde frontend.
Abre `http://127.0.0.1:3002`. Esa presentación usa API simulada y almacenamiento
del navegador; no demuestra persistencia SQL, login real ni permisos del servidor.

En esa modalidad puedes seleccionar rol Recepción mediante **Espacio de
demostración**, recorrer SaaS/Humana/Odontología/Veterinaria y los tres temas.
Para limpiar todos sus almacenes abre una sesión privada nueva tras cerrar
las anteriores, o borra solo los datos del origen de esa demo. Los adjuntos de
ejemplo permanecen en memoria. Para detener el preview pulsa Ctrl+C.
