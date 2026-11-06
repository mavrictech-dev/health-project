# Entorno local para validar JDBC de Health Project

Contrato autorizado por el usuario el 5 de noviembre de 2026. Instancia nueva
HEALTHPROJECTQA instalada (Summary Passed/0); configuracion y verificacion del
endpoint JDBC siguen pendientes. Los apartados siguientes conservan el diseno
y distinguen las comprobaciones que faltan.

## Estado contrastado

La instancia local disponible es MSSQLSERVER, SQL Server 2022 16.0.1000.6.
TCP y named pipes estan deshabilitados y la autenticacion es solo Windows.
La base sintetica health_project_sqlserver_qa_20261103 conserva sus 37 tablas,
133 procedimientos, dos roles dbo y 562 permisos instalados. A63 valida veinte
operaciones bajo usuarios DB WITHOUT LOGIN temporales; no autentica un login
SQL ni prueba JDBC, pool, TLS o los recorridos HTTP de negocio.

El runtime SQL usa SQLServerDataSource con usuario y password propios. Usar
la identidad Windows administrativa como runtime no cumpliria el aislamiento
aceptado. Las tareas A61-A64 no habilitan transporte ni cambian autenticacion
de la instancia compartida.

La sesion actual no tiene elevacion de administrador. Se encontro el ejecutable
cacheado C:/Program Files/Microsoft SQL Server/160/Setup Bootstrap/SQL2022/setup.exe,
version16.0.1000.6, firma Microsoft valida. Esto no confirma que esten disponibles
todos los archivos de instalacion. El puerto loopback14335 estaba libre al
comprobarlo; debe comprobarse otra vez antes de configurarlo.

## Destino recomendado

Crear una instancia nombrada exclusiva de Health Project, en este equipo, con
el siguiente contrato. Si ya hay un entorno QA equivalente disponible, primero
se acuerdan su endpoint y aislamiento en vez de instalar otro.

| Elemento | Valor propuesto |
| --- | --- |
| Instancia | HEALTHPROJECTQA |
| Servicio nuevo | MSSQL$HEALTHPROJECTQA |
| Uso | Desarrollo y QA con datos sinteticos |
| Endpoint JDBC | 127.0.0.1:14335, puerto fijo, solo loopback |
| Autenticacion runtime | Login SQL exclusivo, sin sysadmin ni CONTROL |
| Principales | Migracion, bootstrap y runtime separados |
| Base nueva | health_project_sqlserver_qa_isolated_20261105 |
| Marcador nuevo | Health Project isolated JDBC QA; provisioned 2026-11-05; no real data |
| Datos y logs | Directorio nuevo dedicado D:/HealthProject-QA/SqlServer |
| Arranque | Manual para la instancia QA |
| Exposicion | Sin listener en interfaces externas ni apertura de firewall |
| Azure/proveedores | Sin recursos, extensiones o servicios contratados |

La instancia y la base QA existentes se conservan. No se cambia su modo de
login, protocolo ni servicio. El instalador puede necesitar componentes comunes;
sus acciones y cualquier solicitud de reinicio del equipo deben revisarse antes
de continuar. No se ejecuta un reinicio general como parte de esta propuesta.

## Preparacion y comprobaciones de entrada

1. Elegir instancia nueva o proporcionar un endpoint QA autorizado. Instalar una
   instancia nueva requiere elevacion de Windows, disponibilidad del medio y
   confirmar la edicion/licencia de desarrollo; no se compra ninguna licencia.
2. Comprobar que HEALTHPROJECTQA, su servicio y el directorio de datos no existen.
   Ante colision se detiene el procedimiento, sin reutilizar ni borrar recursos.
3. Presentar los parametros de instalacion de la instancia nueva antes de
   ejecutarlos. Configurar solo Database Engine, arranque manual y TCP/NP
   inicialmente apagados; introducir credenciales nuevas mediante interfaz
   protegida, nunca en Git, chat, argv o registros de comandos.
4. Configurar exclusivamente el protocolo de HEALTHPROJECTQA: Listen All=No,
   loopback habilitado, puerto14335 fijo y puertos dinamicos desactivados. Arrancar
   o reiniciar solo ese servicio y verificar su PID/listeners y salud.
5. Mantener encrypt=true en el driver. Preparar y verificar el certificado local;
   cualquier excepcion de confianza exclusiva de QA debe quedar explicitamente
   identificada y no contara como validacion de la cadena TLS.

Microsoft documenta la instalacion desde una consola administrativa y la opcion
SQLEngine para instalar solo el motor. Tambien especifica que SECURITYMODE=SQL
requiere una contrase?a SA. [Referencia de instalacion](https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt?view=sql-server-ver16).

La configuracion de puertos distingue Listen All de las direcciones individuales
y requiere reiniciar el servicio afectado. [Referencia de puertos](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-a-server-to-listen-on-a-specific-tcp-port?view=sql-server-ver16).

## Trabajo posterior sobre el destino elegido

Las herramientas A61/A62 estan cerradas al destino MSSQLSERVER/base QA anterior.
No deben validarlo y despues iniciar el runtime contra otro endpoint. Antes de
usar la instancia nueva, delegar un paquete que enlace explicitamente endpoint,
base, marcador y credenciales por proceso y falle ante cualquier discrepancia.

En la base nueva vacia, aplicar el esquema y SP revisados con el principal de
migracion. No copiar ni adjuntar archivos de la instancia anterior, ni utilizar
baseline de Flyway para fingir migraciones ejecutadas. V8 solo se aplica cuando
sus precondiciones se cumplen. Provisionar usuarios/logins exclusivos con grants
por SP, y ejecutar bootstrap fuera del runtime con su principal separado.

La aceptacion requiere login JDBC real del principal restringido; SP permitidos y
negativos de tablas/DDL; transacciones, rollback, contexto y reciclaje del pool;
TLS con su alcance exacto; despues HTTP de identidad/tenant/negocio y Playwright
en escritorio/movil con capturas, consola y solicitudes de red inspeccionadas.
La demo permanece independiente. No se publican cambios en produccion ni en main.

## Estado de aprobacion y orquestacion

Esta propuesta permite elegir el recurso necesario para desbloquear JDBC; no es
una orden de instalacion ya ejecutada. La cuenta programadora mantiene su sesion
y esta limitada por cuota hasta20:45. Los artefactos A64 fueron revisados e
integrados8d70803 con65tests,17checksreadonly y20fasesA63 independientes; falta
su informe final/worker_done. No iniciar otra Task con ese trabajador antes de
cerrar A64. No repetir apply ni pruebas exitosas para cerrar administrativamente.


Actualizacion de ejecucion: instancia creada con WindowsAuth, servicio manual
detenido y TCP/NP apagados; A65 prepara configuracion del nuevo namespace y
Verify. Instancia compartida sin cambios verificados. Usuario autorizo creacion,
no volver a pedir eleccion de destino. A64 ya completed enOrca; no bloqueo de
cuota en este paso.
