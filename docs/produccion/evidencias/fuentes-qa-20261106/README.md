# Fuentes de QA local — 6 de noviembre de 2026

Copias exactas de los harnesses ejecutados por el supervisor, sin valores de
credenciales. Los SHA256 y resultados están en `../CIERRE_LOCAL_20261106.json`.
Son evidencia reproducible de esta base aislada; no son un instalador productivo.

Las contraseñas se descifran con DPAPI CurrentUser en memoria y viajan al proceso
Java/Node por stdin. Los checkpoints de negocio también están cifrados y quedan
en `tmp`, excluidos de Git. No se distribuyen esos archivos ni se regeneran claves.

`business_qa.py` ejecuta los pasos de `backend/scripts/verify-api.py` con backend
real. Excluye el último probe MySQL/Docker y reanuda solo los fixtures sintéticos
del mismo run. Hubo correcciones V10–V12 y recuperación de selectores del harness;
el informe no presenta esta ejecución como una pasada ininterrumpida desde vacío.

Comandos ejecutados en la raíz: `python tmp/health-continuation-20261106/business_qa.py`,
`run_transaction_regression.py`, `run_visual.py`, `run_visual.py --writes`,
`run_visual.py --security` y `post_restart.py` bajo ese mismo directorio.
Classpath/JDK y credenciales son material local ignorado. Para repetir pruebas,
revisar el estado de los fixtures antes de enviar escrituras; no repetir setup.

El proxy usa la lógica de archivos/RSC de `frontend/scripts/preview-static.cjs`,
escucha solo en 127.0.0.1:18300 y reenvía `/api` al backend real en 18080. Conserva
el Host de health.localhost. Playwright reutiliza Edge y el mapeo DNS ya usado
por los scripts del proyecto. No intercepta respuestas de la API real.

SQL usó cifrado con excepción de confianza local explícita; TLS estricto sigue
pendiente. La demo se compiló/pruebo aparte en 18302 y produjo 0 llamadas API.
