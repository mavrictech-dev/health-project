# Fuentes de la verificaci?n independiente del 5 de noviembre de 2026

Estas son copias exactas de los tres harnesses ejecutados por el supervisor.
Sus SHA256 coinciden con `../SQLSERVER_QA_20261105.json`. Se conservan como
fuente de evidencia, con extensi?n `.txt`; no son nuevos comandos del producto.

Las rutas relativas describen el snapshot local original
`tmp/sqlserver-a67-review`, el JDK 21, el driver JDBC local y el JAR construido.
Para reproducirlas hay que preparar ese entorno y revisar los puertos libres;
no basta con ejecutar las copias desde esta carpeta.

Las contrase?as se recuperaban del almac?n DPAPI local y viajaban por stdin.
No se incluyen contrase?as, archivos DPAPI, datos de SQL Server, binarios ni logs.
El launcher HTTP de prueba se detuvo. El probe JDBC no cre? fixtures persistentes;
las peticiones HTTP dejaron tres trazas sint?ticas, conservadas en la base QA.

Alcance: 17 controles JDBC y 7 HTTP reales. No acreditan recorridos de negocio
autenticados, ciclo completo del pool, revisi?n visual ni cadena TLS v?lida.
La confianza del certificado se relaj? exclusivamente para QA local.
