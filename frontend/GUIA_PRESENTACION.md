# Demo de Health Project para la reunión

Esta presentación utiliza datos ficticios y operaciones locales del navegador.
No requiere credenciales ni SQL Server. Instalación:
[README principal](../README.md#instalar-y-abrir-la-demo).

## Preparación

1. Desde `frontend`, ejecuta `npm run build:demo` y espera a que termine.
2. Inicia `npm run preview:demo` y abre `http://127.0.0.1:3002` en una ventana
   privada nueva. Mantén la terminal abierta.
3. Comprueba las seis entradas de la portada, zoom 100% y la resolución del proyector.
4. Ensaya por escritura. La voz depende de navegador, permisos y servicios del
   proveedor; no es necesaria para completar la presentación.

Puedes comenzar así: «Esta demo permite recorrer la experiencia con datos
ficticios. Los flujos principales tienen pruebas locales de frontend y backend;
la habilitación productiva y clínica del destino tiene su propio cierre».

## Recorrido de diez minutos

### Entrada y navegación — un minuto

Entra por **Medicina humana**. Muestra espacio, organización/sucursal y temas
blanco, negro y navy. El acceso conectado usa RUC + correo + contraseña y sede;
las entradas de presentación no exigen autenticarse.

### Agenda y recepción — tres minutos

1. Abre **Espacio de demostración** y cambia al rol **Recepción**.
2. En **Agenda**, selecciona la sucursal si aparece el selector.
3. Alterna **Día** y **Semana** y muestra el filtro de profesional.
4. Pulsa **Nueva cita**, selecciona paciente existente y profesional. Elige mañana
   y un horario libre. Enseña **Revisar cita** antes de **Confirmar cita**.
5. Abre la cita, selecciona **Pagado**, importe y medio. Guarda; es un cobro ficticio.
6. Vuelve a **Hoy** para ver el arqueo: agrupa por fecha de registro del cobro,
   aunque la cita esté programada para mañana.

Como opción adicional: **Agendar por voz**, Nombres → Apellidos → Nacimiento →
Horario. Revisa y corrige antes de reservar. Si falla el micrófono, vuelve al
formulario y continúa escribiendo. Usa solo identificadores ficticios en altas.

### Pacientes e historia — dos minutos

Abre **Pacientes**, busca una ficha preparada por DNI o nombre y muestra sus
antecedentes con autor, fecha e historial. En consulta, muestra anamnesis, examen
físico, diagnóstico y tratamiento, y el estado de cita si se vincula. Usa textos
de ejemplo y no incorpores datos de pacientes reales.

### Administración SaaS — dos minutos

Regresa a la portada y entra por **Administración SaaS**. Muestra clientes,
planes, sedes y capacidades. Puedes abrir el formulario de alta y su revisión.
Estas operaciones locales no aprovisionan infraestructura ni procesan pagos.

### Especialidades y siguiente etapa — dos minutos

Desde la portada entra por **Odontología** o **Veterinaria**. Muestra gráficos,
fichas por especie o responsables como alcance visual del producto. Los perfiles
y procesos avanzados requieren validación profesional antes del uso asistencial.

## Repetir la demo

Cierra todas las ventanas privadas y abre una nueva para una sesión limpia.
También puedes borrar los datos de sitio del origen de esta demo y recargar.
**Restaurar escenario** restaura el escenario principal; agenda/catálogos y otros
simuladores mantienen almacenes separados. Para un reinicio completo utiliza
una nueva sesión privada o borra los datos del sitio.

`localhost`, `127.0.0.1` y puertos distintos tienen almacenes independientes.
Los adjuntos de ejemplo permanecen en memoria y se seleccionan de nuevo tras recargar.

## Qué podemos afirmar

- La demo es navegable sin backend y muestra formularios, roles, estados y vistas
  de escritorio/móvil con datos sintéticos.
- RUC y HP4–HP8 tienen evidencia local SQL/API; la revisión del 14 de noviembre cerró
  con 1.162 pruebas backend y 126 frontend, sin fallos.
- La demo y la instalación productiva son entregas distintas. Esta reunión no
  verifica SQL de un proveedor, certificados, recuperación o carga del destino.
- Los dictados de la evidencia anterior fueron simulados. Ensaya por separado el
  micrófono del portátil. Firmas y cobros de esta presentación son ficticios.

Al terminar pulsa **Ctrl+C** en la terminal del preview. No hay que limpiar
ninguna base de datos: los cambios de presentación pertenecen al navegador.
