export interface AgendaProfessional {id:string;name:string;specialtyCode:string;specialtyName:string;}
export interface AgendaContext {timezone:string;domain:'HUMAN'|'ANIMAL';professionals:AgendaProfessional[];}
export interface AgendaAppointment {id:string;patientId:string;patientName:string;identifier:string;branchId:string;professionalId:string;professionalName:string;specialtyCode:string;startsAt:string;endsAt:string;status:string;service:string;note:string;revision:number;collectionStatus:'PENDING'|'PAID';amountMinor:number;paymentMethod:string|null;collectionRevision:number;}
export const paymentMethods={CASH:'Efectivo',CARD:'Tarjeta',TRANSFER:'Transferencia',YAPE:'Yape',PLIN:'Plin',OTHER:'Otro'};
export const appointmentLabels:Record<string,string>={REQUESTED:'Solicitada',RESERVED:'Reservada',CONFIRMED:'Confirmada',WAITING:'En espera',CALLED:'Llamada',IN_CARE:'En atención',COMPLETED:'Atendido',CANCELLED:'Cancelada',WITHDRAWN:'Retirada',NO_SHOW:'No asistió'};
export const money=(minor:number)=>new Intl.NumberFormat('es-PE',{style:'currency',currency:'PEN'}).format(minor/100);
export function addCalendarDays(date:string,days:number){const d=new Date(date+'T12:00:00Z');d.setUTCDate(d.getUTCDate()+days);return d.toISOString().slice(0,10);}
export function validCalendarDate(value:string){if(!/^\d{4}-\d{2}-\d{2}$/.test(value))return false;const d=new Date(value+'T12:00:00Z');return Number.isFinite(d.getTime())&&d.toISOString().slice(0,10)===value;}
export function zonedParts(instant:string|Date,timezone:string){
 const values=Object.fromEntries(new Intl.DateTimeFormat('en-CA',{timeZone:timezone,year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',hourCycle:'h23'}).formatToParts(new Date(instant)).map(p=>[p.type,p.value]));
 return {date:values.year+'-'+values.month+'-'+values.day,time:values.hour+':'+values.minute};
}
export function zonedInstant(date:string,time:string,timezone:string){
 if(!validCalendarDate(date)||!/^([01]\d|2[0-3]):[0-5]\d$/.test(time))throw Error('Revisa la fecha y la hora.');
 const target=Date.parse(date+'T'+time+':00Z');let value=target;
 for(let i=0;i<4;i++){const p=zonedParts(new Date(value),timezone),difference=target-Date.parse(p.date+'T'+p.time+':00Z');value+=difference;if(difference===0)break;}
 const p=zonedParts(new Date(value),timezone);if(p.date!==date||p.time!==time)throw Error('Ese horario no existe en la zona horaria del negocio.');
 for(const shift of [-3600000,3600000]){const other=zonedParts(new Date(value+shift),timezone);if(other.date===date&&other.time===time)throw Error('Ese horario es ambiguo por un cambio de hora. Elige otro horario.');}
 return new Date(value).toISOString();
}
export function calendarWindow(anchor:string,mode:'day'|'week',timezone:string){const weekday=(new Date(anchor+'T12:00:00Z').getUTCDay()+6)%7,start=mode==='week'?addCalendarDays(anchor,-weekday):anchor,days=mode==='week'?7:1;return {dates:Array.from({length:days},(_,i)=>addCalendarDays(start,i)),from:zonedInstant(start,'00:00',timezone),to:zonedInstant(addCalendarDays(start,days),'00:00',timezone)};}
export function overlaps(aStart:string,aEnd:string,bStart:string,bEnd:string){return Date.parse(aStart)<Date.parse(bEnd)&&Date.parse(aEnd)>Date.parse(bStart);}
export function appointmentLayout(rows:AgendaAppointment[],day:string,timezone:string){
 const from=zonedInstant(day,'00:00',timezone),to=zonedInstant(addCalendarDays(day,1),'00:00',timezone);
 const items=rows.filter(a=>overlaps(a.startsAt,a.endsAt,from,to)).map(a=>{const s=zonedParts(a.startsAt,timezone),e=zonedParts(a.endsAt,timezone),minutes=(time:string)=>Number(time.slice(0,2))*60+Number(time.slice(3));const start=s.date<day?0:minutes(s.time),end=e.date>day?1440:minutes(e.time);return {appointment:a,start,end,lane:0,lanes:1};}).sort((a,b)=>a.start-b.start||b.end-a.end||a.appointment.id.localeCompare(b.appointment.id));
 let group:typeof items=[],groupEnd=-1;
 const finish=()=>{const ends:number[]=[];for(const item of group){let lane=ends.findIndex(end=>end<=item.start);if(lane<0)lane=ends.length;ends[lane]=item.end;item.lane=lane;}for(const item of group)item.lanes=ends.length;};
 for(const item of items){if(item.start>=groupEnd){finish();group=[];groupEnd=-1;}group.push(item);groupEnd=Math.max(groupEnd,item.end);}finish();return items;
}
const normalize=(text:string)=>text.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[.,]$/g,'').trim();
const numbers:Record<string,number>={cero:0,un:1,uno:1,una:1,dos:2,tres:3,cuatro:4,cinco:5,seis:6,siete:7,ocho:8,nueve:9,diez:10,once:11,doce:12,trece:13,catorce:14,quince:15,dieciseis:16,diecisiete:17,dieciocho:18,diecinueve:19,veinte:20,veintiuno:21,veintidos:22,veintitres:23,veinticuatro:24,veinticinco:25,veintiseis:26,veintisiete:27,veintiocho:28,veintinueve:29,treinta:30,cuarenta:40,cincuenta:50,sesenta:60,setenta:70,ochenta:80,noventa:90,cien:100,ciento:100,doscientos:200,trescientos:300,cuatrocientos:400,quinientos:500,seiscientos:600,setecientos:700,ochocientos:800,novecientos:900};
export function spokenNumber(text:string):number|null {text=normalize(text);if(/^\d+$/.test(text))return Number(text);let value=0,part=0,seen=false;for(const word of text.split(/\s+/)){if(word==='y')continue;if(word==='mil'){value+=(part||1)*1000;part=0;seen=true;}else if(word in numbers){part+=numbers[word];seen=true;}else return null;}return seen?value+part:null;}
const months=['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
export function parseSpokenDate(text:string,defaultYear?:number){
 text=normalize(text);let date='';
 if(/^\d{4}-\d{2}-\d{2}$/.test(text))date=text;
 const numeric=/^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$/.exec(text);if(numeric)date=numeric[3]+'-'+numeric[2].padStart(2,'0')+'-'+numeric[1].padStart(2,'0');
 if(!date){const words=/^(.+?)\s+(?:de\s+)?([a-z]+)(?:\s+(?:de[l]?\s+)?(.+))?$/.exec(text);if(words){const day=spokenNumber(words[1]),month=months.indexOf(words[2].replace('setiembre','septiembre'))+1,year=words[3]?spokenNumber(words[3]):defaultYear;if(day&&month&&year)date=String(year).padStart(4,'0')+'-'+String(month).padStart(2,'0')+'-'+String(day).padStart(2,'0');}}
 return validCalendarDate(date)?date:null;
}
export function parseBirthDate(text:string,today:string){const date=parseSpokenDate(text);if(!date||date<'1900-01-01'||date>today)throw Error('Indica una fecha de nacimiento válida, por ejemplo 12 de mayo de 1992.');return date;}
export function parseAppointmentTime(text:string,selectedDate:string,today:string){
 text=normalize(text).replace(/\bhoras?\b/g,'').trim();let date=selectedDate;
 if(text.includes('pasado manana')){date=addCalendarDays(today,2);text=text.replace('pasado manana','');}
 else if(/^(?:para\s+)?manana\b/.test(text)){date=addCalendarDays(today,1);text=text.replace(/^(?:para\s+)?manana\b/,'');}
 else if(/\bhoy\b/.test(text)){date=today;text=text.replace('hoy','');}
 const explicit=/^(.+?)\s+a las?\s+(.+)$/.exec(text.trim());if(explicit){const parsed=parseSpokenDate(explicit[1],Number(today.slice(0,4)));if(parsed){date=parsed;text=explicit[2];}}
 const afternoon=/de la tarde|de la noche|p\.?\s?m\.?/.test(text),morning=/de la manana|a\.?\s?m\.?/.test(text);
 text=text.replace(/de la (tarde|noche|manana)|[ap]\.?\s?m\.?/g,'').trim().replace(/^(?:a las?|las?)\s+/,'').trim();
 let hour:number|null=null,minute:number|null=0;const digital=/^(\d{1,2})(?::(\d{2}))?$/.exec(text);
 if(digital){hour=Number(digital[1]);minute=Number(digital[2]||0);}else{const parts=text.split(/\s+y\s+/);hour=spokenNumber(parts[0]);minute=parts[1]==='media'?30:parts[1]==='cuarto'?15:parts[1]?spokenNumber(parts.slice(1).join(' y ')):0;}
 if(hour===null||minute===null||hour<0||hour>23||minute<0||minute>59||(afternoon||morning)&&hour>12)throw Error('Indica el horario con hora y minutos, por ejemplo mañana a las 10:30.');
 if(afternoon&&hour<12)hour+=12;if(morning&&hour===12)hour=0;
 return {date,time:String(hour).padStart(2,'0')+':'+String(minute).padStart(2,'0')};
}
