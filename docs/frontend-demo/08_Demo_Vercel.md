# Presentación independiente en Vercel

La presentación utiliza `NEXT_PUBLIC_APP_MODE=mock`, se compila como archivos estáticos y no necesita Spring Boot, Docker, MySQL ni las APIs locales. Se puede compartir la URL raíz con un revisor sin entregarle credenciales reales.

## Recorridos

La entrada permite elegir administración SaaS, medicina humana, odontología, veterinaria, portal del paciente o estado y trazabilidad. El aviso **Presentación · datos ficticios** permite volver al selector. Los cambios se conservan solo en el navegador del visitante; no se comparten entre revisores.

Se reutilizan los comandos clínicos y SaaS existentes. El acceso, registro, recuperación, verificación, sesiones, soporte, trazabilidad y monitor usan un adaptador local de API. El registro crea un tenant ficticio; el buzón simulado permite completar verificación y recuperación sin enviar correos. El monitor muestra métricas preparadas y permite simular estados. Los subdominios se representan dentro del mismo sitio de presentación; no se crean dominios reales.

Las solicitudes de soporte y los cobros son simulados. El enlace corporativo de soporte dirige a [Mavric Technologies](https://mavrictec.com).

## Ejecutar y comprobar

Desde `frontend`:

```powershell
npm ci
npm run dev:demo
```

Para revisar exactamente la exportación que se publica:

```powershell
npm run build:demo
npm run preview:demo
```

Abre `http://127.0.0.1:3002`. La salida está en `frontend/out-demo`; la compilación normal de Docker conserva `frontend/out` y su acceso real. No ejecutes dos compilaciones Next simultáneamente en la misma carpeta: comparten la caché de compilación.

```powershell
npm run check
npm test
npm run qa:demo
```

`qa:demo` usa Edge mediante Playwright. Bloquea y contabiliza `/api/**`: la prueba falla si el modo de presentación intenta usar una API de red. También comprueba creación y persistencia de planes, trazabilidad, exportación CSV, monitor, soporte, sesiones, acceso, registro, verificación, recuperación y las vistas clínicas y móvil.

## Publicar desde GitHub

1. Importa `mavrictech-dev/health-project` en Vercel.
2. Selecciona **Root Directory: `frontend`**. El directorio raíz del repositorio contiene también el backend.
3. La configuración `frontend/vercel.json` selecciona **Other**, `npm ci`, `npm run build:demo` y **Output Directory: `out-demo`**.
4. No agregues credenciales de MySQL, el administrador local ni direcciones del backend. El comando de compilación selecciona explícitamente el modo mock.
5. Publica y comparte el dominio de producción que devuelva Vercel. Si tu cuenta protege los enlaces de vista previa, utiliza el dominio de producción o configura el acceso del revisor en Vercel.

Desde una terminal con sesión Vercel iniciada, también puedes publicar desde `frontend`:

```powershell
vercel --prod
```

La configuración pública de Next se fija durante la compilación. Cambiar una variable después del despliegue requiere recompilar.

## APIs reales después de la presentación

El modo normal (`npm run build`, o `NEXT_PUBLIC_APP_MODE=live`) conserva el acceso real por `/api` en el mismo dominio. Para una instalación remota se publica Spring Boot y MySQL por separado, y se coloca un gateway HTTPS que sirva el frontend y dirija `/api` a Spring Boot conservando el dominio original del tenant. El sitio de demostración no actúa como ese gateway ni aloja el monolito Java.

Usar el frontend real desde otro dominio exige resolver primero cookies, origen, protección CSRF y el dominio de cada tenant. No basta con apuntar a `localhost` desde Vercel: ese nombre se refiere a la computadora del visitante. El modo mock evita esa dependencia durante la presentación.

## Restauración y límites

**Restaurar demo**, en la entrada, permite confirmar la reposición de los datos iniciales. Se restauran las claves locales `health-project-demo-v1` y `health-project-review-v1`; no se toca el servidor real.

Los roles y estados son herramientas de presentación, no mecanismos de seguridad. Las cifras del monitor, las señales, los gráficos y los documentos son ejemplos. Las contraseñas ficticias no se guardan y no habilitan accesos a Docker ni a producción.

Referencias de configuración: [Vercel: configuración de builds](https://vercel.com/docs/builds/configure-a-build), [Next.js: exportación estática](https://nextjs.org/docs/app/guides/static-exports), [Next.js: variables de entorno](https://nextjs.org/docs/app/guides/environment-variables).
