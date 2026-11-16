# Health Project

Aplicación clínica SaaS para organizaciones humanas, odontológicas y veterinarias:
pacientes, historia clínica, agenda, catálogo y administración por organización y
sucursal. Esta entrega está en la rama **`health/production-wave0`**.

**Para enseñar la aplicación:** usa la demo independiente de esta guía. Funciona
con datos ficticios, sin cuentas, contraseñas, backend ni base de datos.
Puedes instalarla desde el código o [descargar el ZIP portátil](https://github.com/mavrictech-dev/health-project/raw/refs/heads/health/production-wave0/entregables/demo/health-project-demo-20261116.zip)
ya compilado; ambos requieren Node.js 24.

**Sistema conectado:** los recorridos RUC y HP4–HP8 están validados localmente.
El cierre del 14 de noviembre pasó 1.162 pruebas backend y 126 frontend. La puesta
en producción con pacientes reales aún requiere validar el destino, seguridad,
recuperación y aceptación del piloto. Las demás pantallas de diseño de la demo
no representan módulos clínicos aprobados.

## Instalar y abrir la demo

### 1. Requisitos

- **Git** para descargar el código. Si el repositorio es privado, tu cuenta GitHub
  debe tener acceso.
- **Node.js 24**, con npm incluido. Es la versión usada para verificar esta guía.
- Chrome o Edge actualizado. La entrada manual funciona aunque no haya voz.
- Internet para descargar el código y dependencias la primera vez.

Para esta demo **no necesitas Java, Maven, Docker, SQL Server ni un archivo `.env`**.
Después de compilar, los recursos se sirven desde tu equipo. La voz del navegador
puede requerir Internet y los servicios de su proveedor.

Comprueba los requisitos en una terminal:

```text
git --version
node --version
npm --version
```

Si PowerShell bloquea `npm.ps 1`, usa `npm.cmd` en los comandos siguientes.
No necesitas cambiar la política de ejecución de Windows.

### 2. Descargar la entrega

Abre una terminal en la carpeta donde quieras guardar el proyecto:

```text
git clone --branch health/production-wave0 --single-branch https://github.com/mavrictech-dev/health-project.git
cd health-project
cd frontend
```

Si ya tienes una copia con cambios locales, consérvala. Puedes clonar en otra
carpeta para presentar sin sobrescribir tu trabajo.

### 3. Instalar, compilar y presentar

Desde `frontend`:

```text
npm ci
npm run build:demo
npm run preview:demo
```

Abre **[http://127.0.0.1:3002](http://127.0.0.1:3002)** y mantén la terminal
abierta durante la reunión. Para detener la demo pulsa **Ctrl+C** en esa terminal.

La portada ofrece seis recorridos, entre ellos **Medicina humana**,
**Administración SaaS**, **Odontología** y **Veterinaria**. No exige iniciar sesión
para entrar en esas vistas. Los formularios de acceso también son simulados.

`build:demo` genera `frontend/out-demo`; `preview:demo` sirve esa carpeta solo
en tu equipo. Abre la dirección HTTP anterior: hacer doble clic en `index.html`
no sustituye al servidor local.

### 4. Abrirla nuevamente

Si conservas el código y la carpeta compilada, solo ejecuta:

```text
cd health-project/frontend
npm run preview:demo
```

Adapta la ruta a la carpeta donde la descargaste. Solo necesitas recompilar si
actualizas el código. No vuelvas a instalar dependencias antes de cada reunión.

## Guion para enseñarla en diez minutos

| Tiempo | Recorrido | Qué mostrar |
| --- | --- | --- |
| 1 min | Medicina humana | Espacio, sucursal, navegación y temas blanco/negro/navy |
| 3 min | Agenda con rol Recepción | Día/semana, cita para mañana, revisión, cobro y arqueo |
| 2 min | Pacientes e historia | DNI, antecedentes con autor/fecha y consulta escrita |
| 2 min | Administración SaaS | Clientes, sedes, planes y capacidades simulados |
| 2 min | Odontología o Veterinaria | Alcance visual y adaptación por especialidad |

Abre **Espacio de demostración** y elige el rol **Recepción** para reservar y
registrar cobros. Selecciona la sucursal si aparece el selector. Usa un paciente
existente y un horario futuro libre; enseña la revisión antes de confirmar.
El arqueo se agrupa por el día en que registras el cobro: vuelve a **Hoy** después
de cobrar una cita de mañana.

Guion detallado: [frontend/GUIA_PRESENTACION.md](frontend/GUIA_PRESENTACION.md).
Ensaya la voz antes de la reunión y conserva escritura manual como alternativa.
Las pruebas anteriores de voz usaron eventos simulados, no un micrófono físico.

![Agenda semanal con datos ficticios](docs/produccion/evidencias/demo-jefe-20261116/HP8-02-calendario-semanal.png)

## Reiniciar los datos de presentación

Los cambios se guardan en el navegador y origen de la demo (`127.0.0.1:3002`).
No se comparten entre equipos ni se envían al backend.

Para empezar desde cero, abre una **ventana privada nueva**, después de cerrar
todas las ventanas privadas anteriores. También puedes borrar los datos de sitio
de ese origen desde el navegador y recargar. No borres datos de otros sitios.

**Restaurar escenario** reinicia el escenario clínico principal; agenda, catálogo
y otras simulaciones mantienen almacenes separados. Para reiniciar todo, utiliza
una nueva sesión privada o borra los datos del sitio. Los adjuntos permanecen en
memoria durante la sesión y deben volver a seleccionarse después de recargar.

Usa únicamente datos ficticios. Cobros, correos, firmas y documentos de la demo
son simulaciones: no procesan dinero ni certifican o envían documentos reales.

## Compartir con otro equipo

Comparte este README para que el destinatario siga la instalación rápida.
GitHub aloja el código; abrir el repositorio no ejecuta la aplicación.

También puedes [descargar el ZIP portátil](https://github.com/mavrictech-dev/health-project/raw/refs/heads/health/production-wave0/entregables/demo/health-project-demo-20261116.zip)
y descomprimirlo completamente. Con Node.js 24 instalado, abre una terminal en la
carpeta donde está `LEEME.md` y ejecuta:

```text
node frontend/scripts/preview-static.cjs --demo
```

Abre `http://127.0.0.1:3002`. No necesitas npm, Git, descargar dependencias ni
Java/SQL para esta opción. Las instrucciones también van dentro del ZIP y en
[entregables/demo/LEEME.md](entregables/demo/LEEME.md); su huella está en
[SHA256.json](entregables/demo/SHA256.json).

Este paquete es distinto del candidato productivo del 14 de noviembre. El
preview escucha en loopback; cada equipo ejecuta su propia copia.

## Desarrollo y comprobaciones

Desde `frontend`:

```text
npm run check
npm test
npm run build:demo
```

Para desarrollar con recarga: `npm run dev:demo`. Abre la dirección que indique
Next.js, normalmente `http://localhost:3000`. Para una reunión utiliza el build
compilado con `preview:demo`. `localhost`, `127.0.0.1` y puertos distintos tienen
almacenamiento independiente porque son orígenes diferentes.

## Instalar el sistema conectado a SQL Server

Es una instalación diferente de la demo. El backend usa **Java 21/Spring Boot y
SQL Server 2022**, con acceso runtime exclusivamente por SP parametrizados. El
usuario runtime no debe tener acceso directo a tablas ni DDL. Migración y
bootstrap utilizan principales y procesos separados.

### Compilar los componentes

Además de Git y Node 24, instala **JDK 21**. Se incluye Maven Wrapper; no necesitas
Maven global. Desde la raíz del repositorio:

```powershell
cd backend
.\mvnw.cmd verify
cd ../frontend
npm ci
npm run check
npm test
npm run build
```

En Linux/macOS usa `./mvnw verify`. Se generan
`backend/target/health-project-0.1.0.jar` y `frontend/out`. El build conectado
debe ejecutarse sin `NEXT_PUBLIC_APP_MODE=mock`; ese valor compila el simulador.
El comando `build:demo` selecciona deliberadamente la presentación.

### Preparar y configurar el destino

1. Preparar alojamiento Java 21/contenedores, dominio base y subdominios HTTPS y
   una base SQL Server 2022 exclusiva de Health Project. Si se usa Somee para SQL,
   comprobarlo por separado del alojamiento Java.
2. Instalar o actualizar las migraciones mediante un proceso revisado y principal
   separado. Fuentes: `backend/src/main/resources/db/sqlserver`, V1–V19. No
   reaplicarlas sobre una base existente ni usar un script histórico como instalador
   universal. V15 exige un mapeo autorizado para tenants anteriores sin RUC.
3. Crear runtime con EXECUTE solo sobre SP aprobados, preparar el administrador
   mediante bootstrap separado y comprobar catálogo, versión y permisos efectivos.
   La aplicación web no migra ni crea administradores al iniciar.
4. Preparar archivos protegidos externos para contraseña runtime y una clave JWT
   aleatoria estable de al menos 32 bytes, sin saltos de línea. No añadir secretos
   a Git, imágenes, README ni argumentos de procesos.
5. Copiar [production.env.example](deploy/production/production.env.example) a una
   ubicación protegida fuera del repositorio y completar sus campos.
6. Preparar imágenes revisadas, terminador HTTPS y red; ensayar en preproducción.
   El Compose productivo no crea SQL ni descarga imágenes automáticamente.

| Variable | Qué debes configurar |
| --- | --- |
| `HEALTH_BACKEND_IMAGE` | Referencia inmutable de la imagen backend revisada |
| `HEALTH_GATEWAY_IMAGE` | Imagen nginx revisada compatible con UID 101 y la plantilla |
| `HEALTH_SQLSERVER_SERVER` / `HEALTH_SQLSERVER_PORT` | Hostname TLS y puerto del SQL externo; puerto predeterminado 1433 |
| `HEALTH_SQLSERVER_DATABASE` | Base exclusiva de Health Project |
| `HEALTH_SQLSERVER_RUNTIME_USER` | Principal runtime EXECUTE-only |
| `HEALTH_BASE_DOMAIN` | Dominio base, sin esquema ni ruta |
| `HEALTH_PUBLIC_ORIGIN` | Origen HTTPS exacto del dominio |
| `HEALTH_GATEWAY_PORT` | Puerto loopback detrás del terminador HTTPS; predeterminado 18080 |
| `HEALTH_SQL_PASSWORD_FILE` | Ruta al archivo externo de contraseña; no su valor |
| `HEALTH_JWT_SECRET_FILE` | Ruta al archivo externo de clave JWT; no su valor |

El perfil `production` importa secretos desde `/run/secrets/` y rechaza
configuración insegura antes de crear el datasource. SQL requiere validación de
CA y hostname; no usar `trustServerCertificate=true` como solución productiva.
El gateway monta `frontend/out`, necesita un terminador HTTPS dedicado y publica
solo loopback; no sirve `out-demo` ni expone el puerto Java.

Instrucciones técnicas y validación de configuración:
[deploy/production/README.md](deploy/production/README.md).
Secuencia operativa, aceptación y reversión:
[SALIDA_PRODUCCION_20261114.md](docs/produccion/SALIDA_PRODUCCION_20261114.md).
El destino final y estas condiciones aún requieren validación; no se ha
desplegado una instalación productiva habilitada para pacientes reales.

**No uses `docker compose up` sin indicar archivo:** `compose.yaml`,
`compose.qa.yaml` y los scripts antiguos de setup pertenecen al entorno MySQL
heredado. No son la instalación SQL Server vigente. El archivo separado es
`compose.production.yaml`; ejecutarlo requiere completar y validar el destino.

## Solución de problemas de la demo

| Problema | Solución |
| --- | --- |
| `node` o `npm` no se encuentra | Instala Node 24 y abre una terminal nueva |
| PowerShell bloquea `npm.ps 1` | Usa `npm.cmd ci`, `npm.cmd run build:demo` y `npm.cmd run preview:demo` |
| Puerto 3002 ocupado | Detén tu otra demo con Ctrl+C o utiliza otro puerto, como se indica abajo |
| Falta `out-demo/index.html` | Desde `frontend`, ejecuta `npm run build:demo` y espera el resultado correcto |
| Aparece login/API sin datos | Comprueba que usaste `build:demo`, `preview:demo` y la dirección 3002 |
| Citas preparadas de otra fecha | Usa una sesión privada nueva; la agenda inicial toma la fecha de Lima |
| No permite reservar/cobrar | Selecciona rol Recepción, sucursal y un horario futuro libre |
| Falla el micrófono | Continúa escribiendo; ensaya voz antes de la reunión |
| Otro equipo no abre el preview | Es local; instala o copia la demo en el otro equipo |
| Falla `npm ci` | Revisa Node 24, registro npm y error concreto; conserva el lockfile y no uses `--force` indiscriminadamente |

Puerto alternativo en PowerShell, desde `frontend`:

```powershell
$env:PORT = '3012'
npm.cmd run preview:demo
```

Abre `http://127.0.0.1:3012`. Al terminar pulsa Ctrl+C y ejecuta
`Remove-Item Env:PORT` en esa terminal. En Linux/macOS:
`PORT=3012 npm run preview:demo`.

## Documentación y evidencia

- [Guion para la reunión](frontend/GUIA_PRESENTACION.md).
- [Frontend y estructura](frontend/README.md).
- [Cierre revisado de HP8](docs/produccion/HP8-CIERRE-REVISION-20261114.md).
- [Capturas de los recorridos](docs/produccion/evidencias/hp8-cierre-20261114/screenshots.json).
- [Preparación y reversión productiva](docs/produccion/SALIDA_PRODUCCION_20261114.md).
- [Plan completo y pendientes](docs/PLAN_EJECUCION_PRODUCCION.md).

Las capturas contienen datos ficticios. Disponer de pantallas para 241 perfiles
no acredita su validación clínica ni el cierre de los módulos avanzados.
