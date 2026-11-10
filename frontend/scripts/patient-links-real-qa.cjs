'use strict';
/* Prepared real readonly QA. Import is inert. No response substitution or SQL access.
 * EOF and manifest validation precede loading Playwright or starting any browser. */
const RUN='pacqa-20261109-a1',DB='health_project_sqlserver_qa_isolated_20261105',BASE='http://health.localhost:18300';
const HUMAN='c692af54-6391-4e8a-9b95-7bcbdd930bcc',ANIMAL_IDENTIFIER='PACQA-'+RUN+'-ANIMAL-UI';
const HOSTS={human:'qa-3fe6475a3f-a.health.localhost',otherHuman:'qa-3fe6475a3f-b.health.localhost',animal:'qa-3fe6475a3f-v.health.localhost'};
// Exact 444 relative names from manifest SHA256 6BF5A98784DC300D3062449BDDEC7E66D05814FF3BD6EB29E2CDC1B911E35FA6.
// The canonical wrapper and unchanged environment verify public file hashes/reparse guards before execution.
const STATIC_FILES=Object.freeze([
 "404.html",
 "404/index.html",
 "__next.__PAGE__.txt",
 "__next._full.txt",
 "__next._tree.txt",
 "_next/static/chunks/0cz1d0mv5g_q7.js",
 "_next/static/chunks/0d24s--f99i9c.css",
 "_next/static/chunks/0d5hc66z7ywma.js",
 "_next/static/chunks/0om590q-tq0l9.js",
 "_next/static/chunks/0umf92h1sb77c.js",
 "_next/static/chunks/12l2xcc5k9-xv.css",
 "_next/static/chunks/1lx0rkkwi7u4a.js",
 "_next/static/chunks/1ucqvp-z0zyum.css",
 "_next/static/chunks/2iqmlr7_t9_qp.js",
 "_next/static/chunks/2r75-6s5pf-yw.js",
 "_next/static/chunks/2y065cp4cb-z8.js",
 "_next/static/chunks/35hfx128lyhfk.js",
 "_next/static/chunks/3m9imiea6behm.css",
 "_next/static/chunks/3srfjz42u14tx.js",
 "_next/static/chunks/3vdzbc-ryc4qt.js",
 "_next/static/chunks/turbopack-3-ry682tkyiqk.js",
 "_next/static/media/Geist_Variable-s.p.0mrjj4bg00-he.woff2",
 "_next/static/media/favicon.117ezoe8m31dk.ico",
 "_next/static/oHC2BTdt-Lxqklh3eEy7E/_buildManifest.js",
 "_next/static/oHC2BTdt-Lxqklh3eEy7E/_clientMiddlewareManifest.js",
 "_next/static/oHC2BTdt-Lxqklh3eEy7E/_ssgManifest.js",
 "_not-found/__next._full.txt",
 "_not-found/__next._not-found/__PAGE__.txt",
 "_not-found/__next._tree.txt",
 "_not-found/index.html",
 "_not-found/index.txt",
 "acceso/__next.$c$path/__PAGE__.txt",
 "acceso/__next._full.txt",
 "acceso/__next._tree.txt",
 "acceso/index.html",
 "acceso/index.txt",
 "app/agenda/__next.$c$path/__PAGE__.txt",
 "app/agenda/__next._full.txt",
 "app/agenda/__next._tree.txt",
 "app/agenda/index.html",
 "app/agenda/index.txt",
 "app/agenda/solicitudes/__next.$c$path/__PAGE__.txt",
 "app/agenda/solicitudes/__next._full.txt",
 "app/agenda/solicitudes/__next._tree.txt",
 "app/agenda/solicitudes/index.html",
 "app/agenda/solicitudes/index.txt",
 "app/anestesia/__next.$c$path/__PAGE__.txt",
 "app/anestesia/__next._full.txt",
 "app/anestesia/__next._tree.txt",
 "app/anestesia/index.html",
 "app/anestesia/index.txt",
 "app/atencion/__next.$c$path/__PAGE__.txt",
 "app/atencion/__next._full.txt",
 "app/atencion/__next._tree.txt",
 "app/atencion/index.html",
 "app/atencion/index.txt",
 "app/auditoria/__next.$c$path/__PAGE__.txt",
 "app/auditoria/__next._full.txt",
 "app/auditoria/__next._tree.txt",
 "app/auditoria/index.html",
 "app/auditoria/index.txt",
 "app/cirugia/__next.$c$path/__PAGE__.txt",
 "app/cirugia/__next._full.txt",
 "app/cirugia/__next._tree.txt",
 "app/cirugia/index.html",
 "app/cirugia/index.txt",
 "app/compras/__next.$c$path/__PAGE__.txt",
 "app/compras/__next._full.txt",
 "app/compras/__next._tree.txt",
 "app/compras/index.html",
 "app/compras/index.txt",
 "app/configuracion/agenda/__next.$c$path/__PAGE__.txt",
 "app/configuracion/agenda/__next._full.txt",
 "app/configuracion/agenda/__next._tree.txt",
 "app/configuracion/agenda/index.html",
 "app/configuracion/agenda/index.txt",
 "app/configuracion/datos/__next.$c$path/__PAGE__.txt",
 "app/configuracion/datos/__next._full.txt",
 "app/configuracion/datos/__next._tree.txt",
 "app/configuracion/datos/index.html",
 "app/configuracion/datos/index.txt",
 "app/configuracion/equipo/__next.$c$path/__PAGE__.txt",
 "app/configuracion/equipo/__next._full.txt",
 "app/configuracion/equipo/__next._tree.txt",
 "app/configuracion/equipo/index.html",
 "app/configuracion/equipo/index.txt",
 "app/configuracion/especialidades/__next.$c$path/__PAGE__.txt",
 "app/configuracion/especialidades/__next._full.txt",
 "app/configuracion/especialidades/__next._tree.txt",
 "app/configuracion/especialidades/index.html",
 "app/configuracion/especialidades/index.txt",
 "app/configuracion/integraciones/__next.$c$path/__PAGE__.txt",
 "app/configuracion/integraciones/__next._full.txt",
 "app/configuracion/integraciones/__next._tree.txt",
 "app/configuracion/integraciones/index.html",
 "app/configuracion/integraciones/index.txt",
 "app/configuracion/organizacion/__next.$c$path/__PAGE__.txt",
 "app/configuracion/organizacion/__next._full.txt",
 "app/configuracion/organizacion/__next._tree.txt",
 "app/configuracion/organizacion/index.html",
 "app/configuracion/organizacion/index.txt",
 "app/configuracion/sedes/__next.$c$path/__PAGE__.txt",
 "app/configuracion/sedes/__next._full.txt",
 "app/configuracion/sedes/__next._tree.txt",
 "app/configuracion/sedes/index.html",
 "app/configuracion/sedes/index.txt",
 "app/configuracion/servicios/__next.$c$path/__PAGE__.txt",
 "app/configuracion/servicios/__next._full.txt",
 "app/configuracion/servicios/__next._tree.txt",
 "app/configuracion/servicios/index.html",
 "app/configuracion/servicios/index.txt",
 "app/cuenta/__next.$c$path/__PAGE__.txt",
 "app/cuenta/__next._full.txt",
 "app/cuenta/__next._tree.txt",
 "app/cuenta/index.html",
 "app/cuenta/index.txt",
 "app/diagnostico/imagenes/__next.$c$path/__PAGE__.txt",
 "app/diagnostico/imagenes/__next._full.txt",
 "app/diagnostico/imagenes/__next._tree.txt",
 "app/diagnostico/imagenes/index.html",
 "app/diagnostico/imagenes/index.txt",
 "app/diagnostico/laboratorio/__next.$c$path/__PAGE__.txt",
 "app/diagnostico/laboratorio/__next._full.txt",
 "app/diagnostico/laboratorio/__next._tree.txt",
 "app/diagnostico/laboratorio/index.html",
 "app/diagnostico/laboratorio/index.txt",
 "app/diagnostico/muestras/__next.$c$path/__PAGE__.txt",
 "app/diagnostico/muestras/__next._full.txt",
 "app/diagnostico/muestras/__next._tree.txt",
 "app/diagnostico/muestras/index.html",
 "app/diagnostico/muestras/index.txt",
 "app/diagnostico/trabajo/__next.$c$path/__PAGE__.txt",
 "app/diagnostico/trabajo/__next._full.txt",
 "app/diagnostico/trabajo/__next._tree.txt",
 "app/diagnostico/trabajo/index.html",
 "app/diagnostico/trabajo/index.txt",
 "app/documentos/__next.$c$path/__PAGE__.txt",
 "app/documentos/__next._full.txt",
 "app/documentos/__next._tree.txt",
 "app/documentos/index.html",
 "app/documentos/index.txt",
 "app/especialidades/__next.$c$path/__PAGE__.txt",
 "app/especialidades/__next._full.txt",
 "app/especialidades/__next._tree.txt",
 "app/especialidades/index.html",
 "app/especialidades/index.txt",
 "app/farmacia/__next.$c$path/__PAGE__.txt",
 "app/farmacia/__next._full.txt",
 "app/farmacia/__next._tree.txt",
 "app/farmacia/index.html",
 "app/farmacia/index.txt",
 "app/finanzas/caja/__next.$c$path/__PAGE__.txt",
 "app/finanzas/caja/__next._full.txt",
 "app/finanzas/caja/__next._tree.txt",
 "app/finanzas/caja/index.html",
 "app/finanzas/caja/index.txt",
 "app/finanzas/comprobantes/__next.$c$path/__PAGE__.txt",
 "app/finanzas/comprobantes/__next._full.txt",
 "app/finanzas/comprobantes/__next._tree.txt",
 "app/finanzas/comprobantes/index.html",
 "app/finanzas/comprobantes/index.txt",
 "app/finanzas/honorarios/__next.$c$path/__PAGE__.txt",
 "app/finanzas/honorarios/__next._full.txt",
 "app/finanzas/honorarios/__next._tree.txt",
 "app/finanzas/honorarios/index.html",
 "app/finanzas/honorarios/index.txt",
 "app/finanzas/presupuestos/__next.$c$path/__PAGE__.txt",
 "app/finanzas/presupuestos/__next._full.txt",
 "app/finanzas/presupuestos/__next._tree.txt",
 "app/finanzas/presupuestos/index.html",
 "app/finanzas/presupuestos/index.txt",
 "app/hospital/admisiones/__next.$c$path/__PAGE__.txt",
 "app/hospital/admisiones/__next._full.txt",
 "app/hospital/admisiones/__next._tree.txt",
 "app/hospital/admisiones/index.html",
 "app/hospital/admisiones/index.txt",
 "app/hospital/estancias/__next.$c$path/__PAGE__.txt",
 "app/hospital/estancias/__next._full.txt",
 "app/hospital/estancias/__next._tree.txt",
 "app/hospital/estancias/index.html",
 "app/hospital/estancias/index.txt",
 "app/hospital/medicacion/__next.$c$path/__PAGE__.txt",
 "app/hospital/medicacion/__next._full.txt",
 "app/hospital/medicacion/__next._tree.txt",
 "app/hospital/medicacion/index.html",
 "app/hospital/medicacion/index.txt",
 "app/hospital/recursos/__next.$c$path/__PAGE__.txt",
 "app/hospital/recursos/__next._full.txt",
 "app/hospital/recursos/__next._tree.txt",
 "app/hospital/recursos/index.html",
 "app/hospital/recursos/index.txt",
 "app/inicio/__next.$c$path/__PAGE__.txt",
 "app/inicio/__next._full.txt",
 "app/inicio/__next._tree.txt",
 "app/inicio/index.html",
 "app/inicio/index.txt",
 "app/inventario/__next.$c$path/__PAGE__.txt",
 "app/inventario/__next._full.txt",
 "app/inventario/__next._tree.txt",
 "app/inventario/index.html",
 "app/inventario/index.txt",
 "app/monitor/__next.$c$path/__PAGE__.txt",
 "app/monitor/__next._full.txt",
 "app/monitor/__next._tree.txt",
 "app/monitor/index.html",
 "app/monitor/index.txt",
 "app/ordenes/__next.$c$path/__PAGE__.txt",
 "app/ordenes/__next._full.txt",
 "app/ordenes/__next._tree.txt",
 "app/ordenes/index.html",
 "app/ordenes/index.txt",
 "app/pacientes/__next.$c$path/__PAGE__.txt",
 "app/pacientes/__next._full.txt",
 "app/pacientes/__next._tree.txt",
 "app/pacientes/duplicados/__next.$c$path/__PAGE__.txt",
 "app/pacientes/duplicados/__next._full.txt",
 "app/pacientes/duplicados/__next._tree.txt",
 "app/pacientes/duplicados/index.html",
 "app/pacientes/duplicados/index.txt",
 "app/pacientes/index.html",
 "app/pacientes/index.txt",
 "app/plataforma/__next.$c$path/__PAGE__.txt",
 "app/plataforma/__next._full.txt",
 "app/plataforma/__next._tree.txt",
 "app/plataforma/index.html",
 "app/plataforma/index.txt",
 "app/recepcion/__next.$c$path/__PAGE__.txt",
 "app/recepcion/__next._full.txt",
 "app/recepcion/__next._tree.txt",
 "app/recepcion/index.html",
 "app/recepcion/index.txt",
 "app/reportes/__next.$c$path/__PAGE__.txt",
 "app/reportes/__next._full.txt",
 "app/reportes/__next._tree.txt",
 "app/reportes/index.html",
 "app/reportes/index.txt",
 "app/seguimiento/__next.$c$path/__PAGE__.txt",
 "app/seguimiento/__next._full.txt",
 "app/seguimiento/__next._tree.txt",
 "app/seguimiento/index.html",
 "app/seguimiento/index.txt",
 "app/soporte/__next.$c$path/__PAGE__.txt",
 "app/soporte/__next._full.txt",
 "app/soporte/__next._tree.txt",
 "app/soporte/index.html",
 "app/soporte/index.txt",
 "app/trazabilidad/__next.$c$path/__PAGE__.txt",
 "app/trazabilidad/__next._full.txt",
 "app/trazabilidad/__next._tree.txt",
 "app/trazabilidad/index.html",
 "app/trazabilidad/index.txt",
 "app/urgencias/__next.$c$path/__PAGE__.txt",
 "app/urgencias/__next._full.txt",
 "app/urgencias/__next._tree.txt",
 "app/urgencias/index.html",
 "app/urgencias/index.txt",
 "app/veterinaria/poblaciones/__next.$c$path/__PAGE__.txt",
 "app/veterinaria/poblaciones/__next._full.txt",
 "app/veterinaria/poblaciones/__next._tree.txt",
 "app/veterinaria/poblaciones/index.html",
 "app/veterinaria/poblaciones/index.txt",
 "app/veterinaria/programas/__next.$c$path/__PAGE__.txt",
 "app/veterinaria/programas/__next._full.txt",
 "app/veterinaria/programas/__next._tree.txt",
 "app/veterinaria/programas/index.html",
 "app/veterinaria/programas/index.txt",
 "demo/__next.$c$path/__PAGE__.txt",
 "demo/__next._full.txt",
 "demo/__next._tree.txt",
 "demo/index.html",
 "demo/index.txt",
 "favicon.ico",
 "file.svg",
 "globe.svg",
 "index.html",
 "index.txt",
 "invitacion/__next.$c$path/__PAGE__.txt",
 "invitacion/__next._full.txt",
 "invitacion/__next._tree.txt",
 "invitacion/index.html",
 "invitacion/index.txt",
 "next.svg",
 "operacion/acceso/__next.$c$path/__PAGE__.txt",
 "operacion/acceso/__next._full.txt",
 "operacion/acceso/__next._tree.txt",
 "operacion/acceso/index.html",
 "operacion/acceso/index.txt",
 "operacion/cuenta/__next.$c$path/__PAGE__.txt",
 "operacion/cuenta/__next._full.txt",
 "operacion/cuenta/__next._tree.txt",
 "operacion/cuenta/index.html",
 "operacion/cuenta/index.txt",
 "operacion/inicio/__next.$c$path/__PAGE__.txt",
 "operacion/inicio/__next._full.txt",
 "operacion/inicio/__next._tree.txt",
 "operacion/inicio/index.html",
 "operacion/inicio/index.txt",
 "operacion/monitor/__next.$c$path/__PAGE__.txt",
 "operacion/monitor/__next._full.txt",
 "operacion/monitor/__next._tree.txt",
 "operacion/monitor/index.html",
 "operacion/monitor/index.txt",
 "operacion/soporte/__next.$c$path/__PAGE__.txt",
 "operacion/soporte/__next._full.txt",
 "operacion/soporte/__next._tree.txt",
 "operacion/soporte/index.html",
 "operacion/soporte/index.txt",
 "operacion/trazabilidad/__next.$c$path/__PAGE__.txt",
 "operacion/trazabilidad/__next._full.txt",
 "operacion/trazabilidad/__next._tree.txt",
 "operacion/trazabilidad/index.html",
 "operacion/trazabilidad/index.txt",
 "portal/acceso/__next.$c$path/__PAGE__.txt",
 "portal/acceso/__next._full.txt",
 "portal/acceso/__next._tree.txt",
 "portal/acceso/index.html",
 "portal/acceso/index.txt",
 "portal/citas/__next.$c$path/__PAGE__.txt",
 "portal/citas/__next._full.txt",
 "portal/citas/__next._tree.txt",
 "portal/citas/index.html",
 "portal/citas/index.txt",
 "portal/cuenta/__next.$c$path/__PAGE__.txt",
 "portal/cuenta/__next._full.txt",
 "portal/cuenta/__next._tree.txt",
 "portal/cuenta/index.html",
 "portal/cuenta/index.txt",
 "portal/documentos/__next.$c$path/__PAGE__.txt",
 "portal/documentos/__next._full.txt",
 "portal/documentos/__next._tree.txt",
 "portal/documentos/index.html",
 "portal/documentos/index.txt",
 "portal/inicio/__next.$c$path/__PAGE__.txt",
 "portal/inicio/__next._full.txt",
 "portal/inicio/__next._tree.txt",
 "portal/inicio/index.html",
 "portal/inicio/index.txt",
 "portal/monitor/__next.$c$path/__PAGE__.txt",
 "portal/monitor/__next._full.txt",
 "portal/monitor/__next._tree.txt",
 "portal/monitor/index.html",
 "portal/monitor/index.txt",
 "portal/pagos/__next.$c$path/__PAGE__.txt",
 "portal/pagos/__next._full.txt",
 "portal/pagos/__next._tree.txt",
 "portal/pagos/index.html",
 "portal/pagos/index.txt",
 "portal/seguimiento/__next.$c$path/__PAGE__.txt",
 "portal/seguimiento/__next._full.txt",
 "portal/seguimiento/__next._tree.txt",
 "portal/seguimiento/index.html",
 "portal/seguimiento/index.txt",
 "portal/soporte/__next.$c$path/__PAGE__.txt",
 "portal/soporte/__next._full.txt",
 "portal/soporte/__next._tree.txt",
 "portal/soporte/index.html",
 "portal/soporte/index.txt",
 "portal/trazabilidad/__next.$c$path/__PAGE__.txt",
 "portal/trazabilidad/__next._full.txt",
 "portal/trazabilidad/__next._tree.txt",
 "portal/trazabilidad/index.html",
 "portal/trazabilidad/index.txt",
 "portal/vinculos/__next.$c$path/__PAGE__.txt",
 "portal/vinculos/__next._full.txt",
 "portal/vinculos/__next._tree.txt",
 "portal/vinculos/index.html",
 "portal/vinculos/index.txt",
 "recuperar/__next.$c$path/__PAGE__.txt",
 "recuperar/__next._full.txt",
 "recuperar/__next._tree.txt",
 "recuperar/index.html",
 "recuperar/index.txt",
 "registro/__next.$c$path/__PAGE__.txt",
 "registro/__next._full.txt",
 "registro/__next._tree.txt",
 "registro/index.html",
 "registro/index.txt",
 "restablecer/__next.$c$path/__PAGE__.txt",
 "restablecer/__next._full.txt",
 "restablecer/__next._tree.txt",
 "restablecer/index.html",
 "restablecer/index.txt",
 "saas/acceso/__next.$c$path/__PAGE__.txt",
 "saas/acceso/__next._full.txt",
 "saas/acceso/__next._tree.txt",
 "saas/acceso/index.html",
 "saas/acceso/index.txt",
 "saas/auditoria/__next.$c$path/__PAGE__.txt",
 "saas/auditoria/__next._full.txt",
 "saas/auditoria/__next._tree.txt",
 "saas/auditoria/index.html",
 "saas/auditoria/index.txt",
 "saas/clientes/__next.$c$path/__PAGE__.txt",
 "saas/clientes/__next._full.txt",
 "saas/clientes/__next._tree.txt",
 "saas/clientes/index.html",
 "saas/clientes/index.txt",
 "saas/cuenta/__next.$c$path/__PAGE__.txt",
 "saas/cuenta/__next._full.txt",
 "saas/cuenta/__next._tree.txt",
 "saas/cuenta/index.html",
 "saas/cuenta/index.txt",
 "saas/especialidades/__next.$c$path/__PAGE__.txt",
 "saas/especialidades/__next._full.txt",
 "saas/especialidades/__next._tree.txt",
 "saas/especialidades/index.html",
 "saas/especialidades/index.txt",
 "saas/inicio/__next.$c$path/__PAGE__.txt",
 "saas/inicio/__next._full.txt",
 "saas/inicio/__next._tree.txt",
 "saas/inicio/index.html",
 "saas/inicio/index.txt",
 "saas/monitor/__next.$c$path/__PAGE__.txt",
 "saas/monitor/__next._full.txt",
 "saas/monitor/__next._tree.txt",
 "saas/monitor/index.html",
 "saas/monitor/index.txt",
 "saas/planes/__next.$c$path/__PAGE__.txt",
 "saas/planes/__next._full.txt",
 "saas/planes/__next._tree.txt",
 "saas/planes/index.html",
 "saas/planes/index.txt",
 "saas/soporte/__next.$c$path/__PAGE__.txt",
 "saas/soporte/__next._full.txt",
 "saas/soporte/__next._tree.txt",
 "saas/soporte/index.html",
 "saas/soporte/index.txt",
 "saas/suscripciones/__next.$c$path/__PAGE__.txt",
 "saas/suscripciones/__next._full.txt",
 "saas/suscripciones/__next._tree.txt",
 "saas/suscripciones/index.html",
 "saas/suscripciones/index.txt",
 "saas/trazabilidad/__next.$c$path/__PAGE__.txt",
 "saas/trazabilidad/__next._full.txt",
 "saas/trazabilidad/__next._tree.txt",
 "saas/trazabilidad/index.html",
 "saas/trazabilidad/index.txt",
 "vercel.svg",
 "verificar/__next.$c$path/__PAGE__.txt",
 "verificar/__next._full.txt",
 "verificar/__next._tree.txt",
 "verificar/index.html",
 "verificar/index.txt",
 "window.svg"
]);
const BROWSER_FLAGS=Object.freeze(['--host-resolver-rules=MAP health.localhost 127.0.0.1, MAP *.health.localhost 127.0.0.1','--no-proxy-server']);
const STEPS=new Set(['setup','browser-launch','context-create','page-create','navigation-access','public-context','login-form','login-submit','login-navigation','session-validation','cookie-validation','api-request','fixture-lookup','ui-ficha','ui-links','ui-assert','capture','logout','cleanup','input','unknown']);
const CATEGORIES=new Set(['DNS','CONNECT','TIMEOUT','JAVASCRIPT','ASSERTION','UNKNOWN']);
const DENIAL_METHODS=new Set(['GET','HEAD','POST','PUT','PATCH','DELETE','OPTIONS','OTHER']);
const DENIAL_CATEGORIES=new Set(['INVALID_URL','FOREIGN_ORIGIN','API_READ','API_WRITE','STATIC_PATH','ROUTE_HANDLER']);
const CODES=new Set(['INVALID_FLAGS','INVALID_MANIFEST','INPUT_FAILED','HOST_MISMATCH','SESSION_MISMATCH','INVALID_RESPONSE','UNSAFE_REQUEST','PREREQUISITE_FAILED','REQUEST_ID_INVALID','REQUEST_ID_COLLISION','ASSERTION_FAILED','BROWSER_ERROR','REPORT_FAILED','UNSAFE_DIAGNOSTICS','UNEXPECTED_FAILURE']);
class QaFailure extends Error{constructor(code){super(CODES.has(code)?code:'UNEXPECTED_FAILURE');this.code=this.message;}}
const demand=(value,code='ASSERTION_FAILED')=>{if(!value)throw new QaFailure(code);};
const object=value=>value!==null&&typeof value==='object'&&!Array.isArray(value);
const canonical=value=>typeof value==='string'&&value.length===36&&/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(value);
const exact=(value,keys)=>object(value)&&Object.keys(value).sort().join('|')===[...keys].sort().join('|');
const equal=(a,b)=>JSON.stringify(a)===JSON.stringify(b);
function diagnostic(error,step){
 let category='UNKNOWN';const text=typeof error?.message==='string'?error.message.slice(0,8192):'',name=typeof error?.name==='string'?error.name:'';
 if(error instanceof QaFailure||name==='AssertionError')category='ASSERTION';
 else if(/ERR_NAME_NOT_RESOLVED|ENOTFOUND|\bDNS\b/i.test(text))category='DNS';
 else if(/ERR_CONNECTION|ECONNREFUSED|ECONNRESET|Failed to fetch/i.test(text))category='CONNECT';
 else if(name==='TimeoutError'||/\btimeout\b|timed out/i.test(text))category='TIMEOUT';
 else if(['TypeError','ReferenceError','SyntaxError'].includes(name)||/\b(?:TypeError|ReferenceError|SyntaxError)\b/.test(text))category='JAVASCRIPT';
 return Object.freeze({step:STEPS.has(step)?step:'unknown',category});
}
function launchOptions(){return {channel:'msedge',headless:true,args:[...BROWSER_FLAGS]};}
function validateManifest(value){
 demand(exact(value,['schema','qaDatabase','baseUrl','runId',...Object.keys(HOSTS)]),'INVALID_MANIFEST');
 demand(value.schema==='health-patients-real-qa-v1'&&value.qaDatabase===DB&&value.baseUrl===BASE&&value.runId===RUN,'INVALID_MANIFEST');
 const tenants=new Set();
 for(const key of Object.keys(HOSTS)){
  const p=value[key];demand(exact(p,['hostname','tenantId','email','password'])&&p.hostname===HOSTS[key]&&canonical(p.tenantId)&&!tenants.has(p.tenantId),'INVALID_MANIFEST');tenants.add(p.tenantId);
  demand(typeof p.email==='string'&&p.email.length<=254&&/^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@(?:[a-z0-9-]+\.)*example\.test$/.test(p.email)&&typeof p.password==='string'&&p.password.trim().length>0&&p.password.length<=1024,'INVALID_MANIFEST');
 }
 return value;
}
function parseFlags(args){demand(Array.isArray(args)&&args.length===1&&args[0]==='--readonly','INVALID_FLAGS');return {readonly:true};}
function checkHost(value,entry,domain){demand(object(value)&&value.platform===false&&value.hostname===entry.hostname&&value.id===entry.tenantId&&canonical(value.id)&&value.domain===domain,'HOST_MISMATCH');}
function checkSession(value,entry){const user=value?.user;demand(object(user)&&canonical(user.id)&&user.tenantId===entry.tenantId&&user.email===entry.email&&Array.isArray(user.roles)&&Array.from(user.roles).every(r=>typeof r==='string')&&!user.roles.some(r=>['SAD','SOP','PAC','RES'].includes(r))&&user.roles.some(r=>r==='ADM'||r==='REC')&&typeof value.csrfToken==='string'&&!!value.csrfToken,'SESSION_MISMATCH');return {id:user.id,csrfToken:value.csrfToken};}
async function checkSessionCookie(context,origin){const cookies=await context.cookies(origin+'/api/');demand(cookies.some(c=>c.name==='health_session'&&c.httpOnly===true),'SESSION_MISMATCH');}
function readLinks(value,tenantId,patientId,limit){
 demand(canonical(tenantId)&&canonical(patientId)&&Number.isInteger(limit)&&limit>=1&&limit<=21&&Array.isArray(value)&&value.length<=limit,'INVALID_RESPONSE');const users=new Set();
 return Object.freeze(Array.from(value,row=>{
  demand(exact(row,['tenantId','patientId','userId','userName','relationship','active','scopes'])&&row.tenantId===tenantId&&row.patientId===patientId&&canonical(row.userId)&&!users.has(row.userId)&&typeof row.userName==='string'&&row.userName.length<=160&&typeof row.relationship==='string'&&row.relationship.length<=80&&typeof row.active==='boolean'&&Array.isArray(row.scopes),'INVALID_RESPONSE');users.add(row.userId);
  const scopes=Object.freeze(Array.from(row.scopes,scope=>{demand(typeof scope==='string','INVALID_RESPONSE');return scope;}));return Object.freeze({tenantId,patientId,userId:row.userId,userName:row.userName,relationship:row.relationship,active:row.active,scopes});
 }));
}
function checkSubpages(full,first,second){demand(equal(first,full.slice(0,1))&&equal(second,full.slice(1,2)),'INVALID_RESPONSE');}
function patient(value,tenant,domain,id){demand(object(value)&&canonical(value.id)&&value.tenantId===tenant&&value.domain===domain&&(!id||value.id===id)&&typeof value.name==='string'&&!!value.name.trim()&&value.name.length<=160&&typeof value.identifier==='string'&&!!value.identifier.trim()&&value.identifier.length<=100,'PREREQUISITE_FAILED');return value;}
function fixtureResponse(status,value,entry,domain,id){if(status===404){problem(value,404,'/api/patients/'+id);throw new QaFailure('PREREQUISITE_FAILED');}demand(status===200,'INVALID_RESPONSE');return patient(value,entry.tenantId,domain,id);}
function findAnimal(rows,entry){demand(Array.isArray(rows)&&rows.length===1,'PREREQUISITE_FAILED');const p=patient(rows[0],entry.tenantId,'ANIMAL');demand(p.identifier===ANIMAL_IDENTIFIER,'PREREQUISITE_FAILED');return p;}
function problem(value,status,path){demand(object(value)&&value.status===status&&value.instance===path&&typeof value.type==='string'&&value.type.startsWith('urn:health-project:error:')&&canonical(value.requestId),'INVALID_RESPONSE');}
function staticExcluded(path){return /^\/(?:api|actuator)(?:\/|$)/i.test(path);}
function buildStaticRoutes(files){
 demand(Array.isArray(files),'INVALID_RESPONSE');const routes=new Set(),names=new Set();
 const add=path=>{if(!staticExcluded(path))routes.add(path);};
 for(const file of files){
  demand(typeof file==='string'&&file.length>0&&file.length<=500&&!names.has(file),'INVALID_RESPONSE');
  const parts=file.split('/');demand(parts.every(p=>/^[A-Za-z0-9_@$+.-]+$/.test(p)&&p!=='.'&&p!=='..'&&!p.endsWith('.')&&!/^(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)/i.test(p)),'INVALID_RESPONSE');names.add(file);
  add('/'+file);
  if(parts.at(-1)==='index.html'){const directory='/'+parts.slice(0,-1).join('/');add(directory);if(directory!=='/')add(directory+'/');}
  // Invert ONLY preview-live.cjs's last-dot -> directory RSC mapping.
  if(parts.length>=2){const directory=parts.at(-2),leaf=parts.at(-1);
   if(directory.startsWith('__next.')&&directory.length>'__next.'.length&&/^[^./]+\.txt$/.test(leaf)){
    const alias=directory+'.'+leaf,stem=alias.slice(0,-4),dot=stem.lastIndexOf('.');
    if(dot>'__next.'.length&&stem.slice(0,dot)===directory&&stem.slice(dot+1)+'.txt'===leaf)add('/'+[...parts.slice(0,-2),alias].join('/'));
   }
  }
 }
 return routes;
}
function requestURL(address){
 try{
  if(typeof address!=='string'||/[\\\x00-\x20\x7f]/.test(address))return null;
  const raw=address.match(/^https?:\/\/[^/?#]+([^?#]*)/);if(!raw)return null;
  const pathname=raw[1]||'/';if(pathname.includes('%')||pathname.includes('//')||pathname.split('/').some(p=>p==='.'||p==='..'))return null;
  const url=new URL(address);if(url.pathname!==pathname||url.hash)return null;return url;
 }catch{return null;}
}
function denialDiagnostic(method,address,policy,handler=false){
 const verb=typeof method==='string'?method.toUpperCase():'OTHER',safeMethod=DENIAL_METHODS.has(verb)?verb:'OTHER',url=requestURL(address);
 const category=handler?'ROUTE_HANDLER':!url?'INVALID_URL':url.origin!==policy.origin||url.username||url.password?'FOREIGN_ORIGIN':/^\/api(?:\/|$)/i.test(url.pathname)?(['GET','HEAD'].includes(safeMethod)?'API_READ':'API_WRITE'):'STATIC_PATH';
 return Object.freeze({method:safeMethod,category});
}
function denialRecorder(){let first=null;return {add(value){demand(exact(value,['method','category'])&&DENIAL_METHODS.has(value.method)&&DENIAL_CATEGORIES.has(value.category),'INVALID_RESPONSE');if(first===null)first=Object.freeze({...value});},value(){return first;},finish(report){if(first){report.status='FAIL';report.code=report.code||'UNSAFE_REQUEST';report.diagnostic=report.diagnostic||diagnostic(null,'cleanup');report.denial=first;}return report;}};}
function allowedRequest(method,address,policy,body){
 const url=requestURL(address);if(!url||typeof method!=='string')return false;
 if(url.origin!==policy.origin||url.username||url.password||url.hash)return false;
 const p=url.pathname;method=method.toUpperCase();
 if(method==='POST')return p==='/api/auth/browser/login'&&!url.search&&policy.loginAllowed===true&&exact(body,['email','password'])&&body.email===policy.loginEmail&&body.password===policy.loginPassword;
 if(method==='DELETE')return p==='/api/auth/browser/session'&&!url.search&&policy.logoutAllowed===true;
 if(!['GET','HEAD'].includes(method))return false;
 if(!p.startsWith('/api/'))return !staticExcluded(p)&&policy.staticRoutes instanceof Set&&policy.staticRoutes.has(p);
 if(method!=='GET')return false;
 if(['/api/public/context','/api/public/status','/api/auth/browser/session'].includes(p))return !url.search;
 if(p==='/api/patients')return [...url.searchParams.keys()].sort().join('|')==='limit|offset|query'&&['2','21'].includes(url.searchParams.get('limit'))&&url.searchParams.get('offset')==='0'&&policy.queries.has(url.searchParams.get('query'));
 const match=p.match(/^\/api\/patients\/([^/]+)(\/links)?$/);if(!match||!canonical(match[1])||!policy.ids.has(match[1]))return false;
 if(!match[2])return !url.search;
 return [...url.searchParams.keys()].sort().join('|')==='limit|offset'&&['1','21'].includes(url.searchParams.get('limit'))&&['0','1','20'].includes(url.searchParams.get('offset'));
}
async function guardedRequest(client,path,method='GET',body){
 const url=client.origin+path;if(!allowedRequest(method,url,client.policy,body)){client.policy.onDenied?.(denialDiagnostic(method,url,client.policy));throw new QaFailure('UNSAFE_REQUEST');}
 const result=await client.page.evaluate(async({origin,resource,method,body,csrfToken})=>{
  if(window.location.origin!==origin||!resource.startsWith('/')||resource.startsWith('//'))throw new Error('QA_ORIGIN_MISMATCH');
  const response=await fetch(resource,{method,credentials:'same-origin',cache:'no-store',redirect:'error',headers:{'Content-Type':'application/json',...(method==='DELETE'?{'X-CSRF-Token':csrfToken}:{})},body:body===undefined?undefined:JSON.stringify(body)});
  let data=null,jsonValid=true;try{data=await response.json();}catch{jsonValid=false;}
  return {status:response.status,requestId:response.headers.get('x-request-id')||'',jsonValid,data};
 },{origin:client.origin,resource:path,method,body,csrfToken:method==='DELETE'?client.identity.csrfToken:''});
 demand(exact(result,['status','requestId','jsonValid','data'])&&Number.isInteger(result.status)&&result.status>=100&&result.status<=599&&typeof result.requestId==='string'&&result.requestId.length<=100&&typeof result.jsonValid==='boolean','INVALID_RESPONSE');
 return {url:()=>url,status:()=>result.status,headers:()=>({'x-request-id':result.requestId}),json:async()=>{demand(result.jsonValid,'INVALID_RESPONSE');return result.data;}};
}
async function installBrowserGuard(context,policy,onUnsafe){await context.route('**/*',async route=>{let method='OTHER',address='';try{const request=route.request();method=request.method();address=request.url();let body;if(method==='POST')body=request.postDataJSON();if(!allowedRequest(method,address,policy,body)){policy.onDenied?.(denialDiagnostic(method,address,policy));onUnsafe();await route.abort();return;}await route.continue();}catch(error){try{policy.onDenied?.(denialDiagnostic(method,address,policy,true));}finally{try{onUnsafe(error);}finally{try{await route.abort();}catch{}}}}});}
function recorder(){const byId=new Map();return {add(value){demand(exact(value,['requestId','status','actorId','tenantId','patientId','phase'])&&canonical(value.requestId)&&canonical(value.tenantId)&&canonical(value.patientId)&&(value.actorId===null||canonical(value.actorId))&&Number.isInteger(value.status)&&value.status>=100&&value.status<=599&&typeof value.phase==='string'&&/^[a-z0-9-]{1,60}$/.test(value.phase),'REQUEST_ID_INVALID');demand(value.status!==401||value.actorId===null,'REQUEST_ID_INVALID');const prior=byId.get(value.requestId);demand(!prior||equal(prior,value),'REQUEST_ID_COLLISION');if(!prior)byId.set(value.requestId,Object.freeze({...value}));},values(){return [...byId.values()];}};}
async function recordResponse(records,client,response,sourcePhase){
 const url=new URL(response.url());if(!url.pathname.endsWith('/links'))return null;
 const requestId=(await response.headers())['x-request-id'],status=response.status(),patientId=url.pathname.split('/')[3];
 records.add({requestId,status,actorId:status===401?null:client.identity?.id||null,tenantId:client.entry.tenantId,patientId,phase:sourcePhase});
 const value=await response.json();if(status===200)return readLinks(value,client.entry.tenantId,patientId,Number(url.searchParams.get('limit')));
 problem(value,status,url.pathname);return null;
}
async function readStdin(stream){const decoder=new TextDecoder('utf-8',{fatal:true});let bytes=0,text='';try{for await(const chunk of stream){const data=Buffer.isBuffer(chunk)?chunk:Buffer.from(chunk);bytes+=data.length;demand(bytes<=65536,'INPUT_FAILED');text+=decoder.decode(data,{stream:true});}text+=decoder.decode();return validateManifest(JSON.parse(text));}catch(error){throw error instanceof QaFailure?error:new QaFailure('INVALID_MANIFEST');}}
function scopeLabel(value){switch(value){case 'APPOINTMENTS':return 'Citas';case 'DOCUMENTS':return 'Documentos';case 'BILLING':return 'Facturación';default:return 'Referencia histórica: '+(value||'(vacía)');}}
async function run(manifest,playwright){
 const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
 const directory=path.resolve('test-results/patient-links-real-qa',RUN,'b5-readonly-e5');
 demand(!fs.existsSync(directory),'REPORT_FAILED');fs.mkdirSync(directory,{recursive:true});
 const staticRoutes=buildStaticRoutes(STATIC_FILES),denials=denialRecorder();
 const records=recorder(),clients=[],checks=[],screenshots=[],pending=new Set();let unsafe=false,responseError=null,pageError=null,fatal=null,failureDiagnostic=null,browser,phase='setup',step='setup';
 const report={schema:'patient-links-real-qa-v1',runId:RUN,mode:'readonly',status:'FAIL',checks,reads:[],screenshots,uiPaging21Exercised:false,inactiveObserved:false,sqlAuditValidated:false};
 const clean=async()=>{await Promise.all([...pending]);demand(!unsafe,'UNSAFE_REQUEST');if(responseError)throw responseError;if(pageError){failureDiagnostic=pageError;throw new QaFailure('BROWSER_ERROR');}};
 const pass=name=>checks.push(name);
 const observe=(client,response,sourcePhase)=>recordResponse(records,client,response,sourcePhase);
 async function api(client,resource,status=200){
  if(!['public-context','session-validation','fixture-lookup'].includes(step))step='api-request';client.phase=phase;const response=await guardedRequest(client,'/api'+resource);
  if(resource.includes('/links?')){const rows=await observe(client,response,phase);demand(response.status()===status,'INVALID_RESPONSE');return rows;}
  demand(response.status()===status,'INVALID_RESPONSE');
  const value=await response.json();if(status!==200)problem(value,status,'/api'+resource);return value;
 }
 async function newClient(key,login=true){
  const entry=manifest[key],origin='http://'+entry.hostname+':18300',domain=key==='animal'?'ANIMAL':'HUMAN';
  step='context-create';const context=await browser.newContext({viewport:{width:1440,height:1000},serviceWorkers:'block',reducedMotion:'reduce'});
  step='page-create';const page=await context.newPage();
  const client={context,page,entry,origin,domain,identity:null,phase:'setup',policy:{origin,staticRoutes,onDenied:denials.add,loginAllowed:login,loginEmail:entry.email,loginPassword:entry.password,logoutAllowed:login,ids:new Set([HUMAN]),queries:new Set(['',ANIMAL_IDENTIFIER])}};clients.push(client);page.setDefaultTimeout(8000);page.on('pageerror',error=>{pageError=diagnostic(error,step);});
  await installBrowserGuard(context,client.policy,error=>{unsafe=true;if(error)failureDiagnostic=diagnostic(error,step);});
  page.on('response',response=>{if(!new URL(response.url()).pathname.endsWith('/links'))return;const p=observe(client,response,client.phase).then(rows=>{client.lastRows=rows;}).catch(error=>{responseError=error instanceof QaFailure?error:new QaFailure('INVALID_RESPONSE');});pending.add(p);p.finally(()=>pending.delete(p));});
  step='navigation-access';await page.goto(origin+'/acceso/',{waitUntil:'networkidle'});step='public-context';checkHost(await api(client,'/public/context'),entry,domain);
  if(login){step='login-form';await page.locator('#auth-email').fill(entry.email);await page.locator('#auth-password').fill(entry.password);step='login-submit';await page.getByRole('button',{name:'Iniciar sesión',exact:true}).click();step='login-navigation';await page.waitForURL(url=>url.pathname.startsWith('/app/'),{waitUntil:'networkidle'});client.policy.loginAllowed=false;step='session-validation';client.identity=checkSession(await api(client,'/auth/browser/session'),entry);step='public-context';checkHost(await api(client,'/public/context'),entry,domain);step='cookie-validation';await checkSessionCookie(context,origin);}
  return client;
 }
 async function open(client,p){
  step='ui-ficha';
  client.phase=phase;const count=records.values().length;client.policy.queries.add(p.identifier);await client.page.goto(client.origin+'/app/pacientes/',{waitUntil:'networkidle'});
  await client.page.getByLabel('Buscar por nombre o identificador',{exact:true}).fill(p.identifier);await client.page.getByRole('button',{name:'Buscar',exact:true}).click();await client.page.getByText('Cargando pacientes…',{exact:true}).waitFor({state:'hidden'});
  const row=client.page.getByRole('row').filter({has:client.page.getByRole('cell',{name:p.identifier,exact:true})});demand(await row.count()===1,'PREREQUISITE_FAILED');await row.getByRole('button',{name:/Ver ficha/}).click();await client.page.getByRole('button',{name:'Ver vínculos',exact:true}).waitFor();await clean();demand(records.values().length===count,'ASSERTION_FAILED');
 }
 async function assertRows(client,rows){
  step='ui-assert';
  await clean();const view=client.page.locator('.patient-links'),items=view.locator('.patient-links-list>li');demand(await items.count()===Math.min(rows.length,20));
  for(let i=0;i<Math.min(rows.length,20);i++){const row=rows[i],item=items.nth(i);demand(await item.locator('h3').textContent()===(row.userName||'Nombre sin registrar'));const values=await item.locator('dd').allTextContents();demand(values[0]===(row.relationship||'Relación sin registrar')&&values[1]===(row.active?'Vínculo activo':'Vínculo inactivo'));if(row.scopes.length)demand(equal(await item.locator('.patient-link-scopes>li').allTextContents(),row.scopes.map(scopeLabel)));else demand(values[2]==='Sin alcances registrados');}
  const displayed=await view.innerText();for(const forbidden of [client.entry.email,client.entry.tenantId,...rows.flatMap(row=>[row.patientId,row.userId])])demand(!displayed.includes(forbidden),'INVALID_RESPONSE');
  if(!rows.length)await view.getByText('Este paciente no tiene vínculos registrados',{exact:true}).waitFor();
  demand(await client.page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));demand(await client.page.getByRole('dialog').evaluate(element=>element.scrollWidth<=element.clientWidth));
 }
 async function show(client){step='ui-links';client.phase=phase;await client.page.getByRole('button',{name:'Ver vínculos',exact:true}).click();await client.page.locator('.patient-links').getByRole('button',{name:'Volver a consultar vínculos',exact:true}).waitFor();await clean();}
 async function capture(client,name){step='capture';await clean();demand(client.identity!==null,'SESSION_MISMATCH');const filename=name+'.png',absolute=path.join(directory,filename);await client.page.screenshot({path:absolute,fullPage:true});screenshots.push({path:path.relative(process.cwd(),absolute).split(path.sep).join('/'),sha256:crypto.createHash('sha256').update(fs.readFileSync(absolute)).digest('hex').toUpperCase()});}
 try{
  step='browser-launch';browser=await playwright.chromium.launch(launchOptions());phase='human-login';const human=await newClient('human');phase='human-prerequisite';step='fixture-lookup';human.phase=phase;const fixture=await guardedRequest(human,'/api/patients/'+HUMAN);const hp=fixtureResponse(fixture.status(),await fixture.json(),human.entry,'HUMAN',HUMAN);
  phase='human-page';step='api-request';const rows=await api(human,'/patients/'+HUMAN+'/links?limit=21&offset=0');demand(rows.length>=1,'PREREQUISITE_FAILED');report.inactiveObserved=rows.some(row=>!row.active);
  phase='human-subpage-first';const first=await api(human,'/patients/'+HUMAN+'/links?limit=1&offset=0');phase='human-subpage-second';const second=await api(human,'/patients/'+HUMAN+'/links?limit=1&offset=1');checkSubpages(rows,first,second);pass('human-api-seven-fields-order-subpages');
  phase='human-ui';await open(human,hp);await show(human);demand(equal(human.lastRows,rows));await assertRows(human,rows);await capture(human,'human-desktop');
  if(rows.length===21){report.uiPaging21Exercised=true;phase='human-ui-next';human.phase=phase;await human.page.getByRole('button',{name:'Siguiente',exact:true}).click();await human.page.locator('.patient-links').getByRole('button',{name:'Volver a consultar vínculos',exact:true}).waitFor();await clean();demand(human.lastRows.length>0&&equal(human.lastRows[0],rows[20]));await assertRows(human,human.lastRows);phase='human-ui-previous';human.phase=phase;await human.page.getByRole('button',{name:'Anterior',exact:true}).click();await human.page.locator('.patient-links').getByRole('button',{name:'Volver a consultar vínculos',exact:true}).waitFor();await clean();}
  else report.pagingLimit='Fixture has fewer than 21 links; real UI lookahead navigation not exercised';
  await human.page.getByRole('button',{name:'Volver a la ficha',exact:true}).click();phase='human-ui-explicit-refresh';const fresh=await api(human,'/patients/'+HUMAN+'/links?limit=21&offset=0');await show(human);demand(equal(human.lastRows,fresh));await assertRows(human,fresh);await human.page.getByRole('button',{name:'Cerrar ficha',exact:true}).click();pass('human-ui-opt-in-return-close-refresh');
  for(const width of [1440,390])for(const theme of ['blanco','negro','navy']){phase='human-ui-themes';await human.page.setViewportSize({width,height:width===390?844:1000});await human.page.getByRole('button',{name:'Tema '+theme,exact:true}).click();await open(human,hp);await human.page.getByRole('button',{name:'Ver vínculos',exact:true}).focus();await human.page.keyboard.press('Enter');await human.page.locator('.patient-links').getByRole('button',{name:'Volver a consultar vínculos',exact:true}).waitFor();await clean();await assertRows(human,human.lastRows);await capture(human,'human-'+width+'-'+theme);await human.page.getByRole('button',{name:'Cerrar ficha',exact:true}).click();}pass('themes-mobile-desktop-keyboard');
  phase='animal-login';const animal=await newClient('animal');phase='animal-prerequisite';const ap=findAnimal(await api(animal,'/patients?'+new URLSearchParams({query:ANIMAL_IDENTIFIER,limit:'2',offset:'0'})),animal.entry);animal.policy.ids.add(ap.id);
  phase='animal-page';demand((await api(animal,'/patients/'+ap.id+'/links?limit=21&offset=0')).length===0,'PREREQUISITE_FAILED');phase='animal-ui';await open(animal,ap);await show(animal);await assertRows(animal,[]);await capture(animal,'animal-empty');await animal.page.getByRole('button',{name:'Cerrar ficha',exact:true}).click();pass('animal-api-ui-empty');
  phase='other-human-login';const other=await newClient('otherHuman');phase='other-human-neutral-404';await api(other,'/patients/'+HUMAN+'/links?limit=21&offset=0',404);pass('other-tenant-neutral-404');
  phase='anonymous-401';const anonymous=await newClient('human',false);await api(anonymous,'/patients/'+HUMAN+'/links?limit=21&offset=0',401);pass('anonymous-401');
  phase='human-ui-before-logout';await open(human,hp);await show(human);phase='human-logout';human.logoutAttempted=true;const logout=await guardedRequest(human,'/api/auth/browser/session','DELETE');demand([200,204].includes(logout.status()),'SESSION_MISMATCH');
  phase='human-ui-expired-401';human.phase=phase;await human.page.getByRole('button',{name:'Volver a consultar vínculos',exact:true}).click();await human.page.getByText(/Tu sesión venció o fue revocada/).waitFor();await clean();demand(await human.page.locator('.patient-links').count()===0);pass('logout-query-expires-removes-rows');
  phase='logout-cleanup';for(const client of [animal,other]){client.logoutAttempted=true;const response=await guardedRequest(client,'/api/auth/browser/session','DELETE');demand([200,204].includes(response.status()),'SESSION_MISMATCH');}await clean();report.status='PASS';
 }catch(error){fatal=error instanceof QaFailure?error.code:'UNEXPECTED_FAILURE';report.code=fatal;failureDiagnostic=failureDiagnostic||diagnostic(error,step);}
 finally{
  for(const client of clients)if(client.identity&&!client.logoutAttempted)try{client.logoutAttempted=true;const response=await guardedRequest(client,'/api/auth/browser/session','DELETE');demand([200,204,401].includes(response.status()),'SESSION_MISMATCH');}catch(error){if(!fatal)failureDiagnostic=diagnostic(error,'cleanup');fatal=fatal||'SESSION_MISMATCH';}
  for(const client of clients)try{await client.context.close();}catch(error){if(!fatal)failureDiagnostic=diagnostic(error,'cleanup');fatal=fatal||'BROWSER_ERROR';}
  if(browser)try{await browser.close();}catch(error){if(!fatal)failureDiagnostic=diagnostic(error,'cleanup');fatal=fatal||'BROWSER_ERROR';}
  if(fatal){report.status='FAIL';report.code=fatal;report.diagnostic=failureDiagnostic||diagnostic(null,'cleanup');}denials.finish(report);report.reads=records.values();report.phase=phase;report.businessWrites=0;report.apiOrSqlAuditCountInferred=false;
  fs.writeFileSync(path.join(directory,'report.json'),JSON.stringify(report,null,2),{flag:'wx'});
 }
 return report;
}
async function cli(args,stream,load=()=>require('playwright')){parseFlags(args);demand(!process.env.DEBUG&&!process.env.PWDEBUG&&!process.env.PLAYWRIGHT_TRACE_DIR,'UNSAFE_DIAGNOSTICS');const manifest=await readStdin(stream);return run(manifest,load());}
module.exports={validateManifest,parseFlags,checkHost,checkSession,checkSessionCookie,readLinks,checkSubpages,patient,fixtureResponse,findAnimal,problem,allowedRequest,guardedRequest,installBrowserGuard,buildStaticRoutes,STATIC_FILES,denialDiagnostic,denialRecorder,recorder,recordResponse,readStdin,scopeLabel,diagnostic,launchOptions,cli,QaFailure,HOSTS,HUMAN,ANIMAL_IDENTIFIER};
if(require.main===module)void cli(process.argv.slice(2),process.stdin).then(report=>{process.exitCode=report.status==='PASS'?0:1;process.stdout.write(JSON.stringify({control:'runner',status:report.status==='PASS'?'passed':'failed'})+'\n');}).catch(error=>{process.exitCode=1;process.stderr.write(JSON.stringify({control:'runner',status:'failed',code:error instanceof QaFailure?error.code:'UNEXPECTED_FAILURE'})+'\n');});
