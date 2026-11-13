'use client';
import {useEffect,useRef,useState} from 'react';
import {Mic,ArrowRight,RotateCcw,Square} from 'lucide-react';
import {Button} from '@/components/ui/button';
import {Input} from '@/components/ui/input';
import {recognitionConstructor,dictationError,type Recognition} from '@/lib/dictation';
import {parseBirthDate,parseAppointmentTime} from '@/lib/agenda';

export interface GuidedBooking {firstName:string;lastName:string;birthDate:string;date:string;time:string;}
const steps=[{key:'firstName',title:'Nombres',question:'Dime los nombres del paciente.'},{key:'lastName',title:'Apellidos',question:'Ahora dime los apellidos del paciente.'},{key:'birthDate',title:'Fecha de nacimiento',question:'¿Cuál es su fecha de nacimiento? Por ejemplo, doce de mayo de mil novecientos noventa y dos.'},{key:'schedule',title:'Horario de cita',question:'¿Para qué día y hora será la cita? Por ejemplo, mañana a las diez y media de la mañana.'}] as const;
export function AgendaVoice({date,today,onComplete,onCancel}:{date:string;today:string;onComplete:(draft:GuidedBooking)=>void;onCancel:()=>void}){
 const [step,setStep]=useState(0),[draft,setDraft]=useState<GuidedBooking>({firstName:'',lastName:'',birthDate:'',date,time:'09:00'}),[answer,setAnswer]=useState(''),[listening,setListening]=useState(false),[message,setMessage]=useState(''),[started,setStarted]=useState(false);
 const recognition=useRef<Recognition|null>(null),generation=useRef(0),complete=useRef(onComplete),acceptRef=useRef<(text:string)=>void>(()=>{});complete.current=onComplete;
 const stop=()=>{generation.current++;const current=recognition.current;recognition.current=null;if(current){current.onresult=null;current.onerror=null;current.onend=null;try{current.abort();}catch{/* Manual capture remains available. */}}if(typeof speechSynthesis!=='undefined')speechSynthesis.cancel();setListening(false);};
 useEffect(()=>()=>{generation.current++;const current=recognition.current;recognition.current=null;if(current){current.onresult=null;current.onerror=null;current.onend=null;try{current.abort();}catch{}}if(typeof speechSynthesis!=='undefined')speechSynthesis.cancel();},[]);
 function accept(text:string){
  try{const next={...draft},value=text.trim();if(step<2){if(!value||value.length>80)throw Error('Indica el nombre o apellido, hasta 80 caracteres.');next[step===0?'firstName':'lastName']=value;}else if(step===2)next.birthDate=parseBirthDate(value,today);else Object.assign(next,parseAppointmentTime(value,date,today));
   stop();setDraft(next);setMessage('');setAnswer('');if(step===3){complete.current(next);return;}setStep(v=>v+1);
  }catch(e){stop();setAnswer(text);setMessage(e instanceof Error?e.message:'Revisa el dato antes de continuar.');}
 }
 acceptRef.current=accept;
 function ask(){
  stop();setMessage('');setStarted(true);const revision=generation.current;
  let opened=false;const listen=()=>{if(revision!==generation.current||opened)return;opened=true;const Constructor=recognitionConstructor();if(!Constructor){setMessage('Este navegador no admite reconocimiento de voz. Puedes escribir y continuar.');return;}
   try{const active=new Constructor();recognition.current=active;active.lang='es-PE';active.continuous=false;active.interimResults=false;
    active.onresult=e=>{if(recognition.current!==active||revision!==generation.current)return;for(let i=e.resultIndex;i<e.results.length;i++)if(e.results[i].isFinal){const text=e.results[i][0].transcript;acceptRef.current(text);break;}};
    active.onerror=e=>{if(recognition.current===active){recognition.current=null;setListening(false);setMessage(dictationError(e.error));}};
    active.onend=()=>{if(recognition.current===active){recognition.current=null;setListening(false);}};
    active.start();setListening(true);
   }catch{setListening(false);setMessage('No se pudo abrir el micrófono. Puedes escribir el dato y continuar.');}
  };
  if(typeof speechSynthesis!=='undefined'&&typeof SpeechSynthesisUtterance!=='undefined'){try{const utterance=new SpeechSynthesisUtterance(steps[step].question);utterance.lang='es-PE';utterance.onend=listen;utterance.onerror=listen;speechSynthesis.speak(utterance);}catch{listen();}}else listen();
 }
 useEffect(()=>{if(started)ask();/* Each accepted answer starts the next spoken question. */},[step]);
 return <section className="agenda-voice"><p className="eyebrow">ASISTENTE DE AGENDAMIENTO</p><h2>Agendar por voz</h2><ol className="voice-steps">{steps.map((item,i)=><li key={item.key} className={step===i?'current':i<step?'done':''}><span>{i+1}</span>{item.title}</li>)}</ol><div className="voice-question"><Mic size={30}/><p>Paso {step+1} de 4</p><h3>{steps[step].question}</h3><p>Los datos reconocidos se revisan antes de confirmar la cita. El servicio de voz depende del navegador.</p></div><div className="detail-actions"><Button type="button" onClick={ask}><Mic size={16}/>{started?'Repetir pregunta':'Iniciar asistente'}</Button>{listening&&<Button type="button" variant="outline" onClick={stop}><Square size={15}/>Detener micrófono</Button>}</div>{listening&&<p role="status" className="voice-listening">Escuchando {steps[step].title.toLowerCase()}…</p>}{message&&<p role="status" className="auth-feedback error">{message}</p>}<form onSubmit={e=>{e.preventDefault();setStarted(false);accept(answer);}}><div className="form-field"><label htmlFor="voice-answer">Respuesta: {steps[step].title}</label><Input id="voice-answer" value={answer} onChange={e=>setAnswer(e.target.value)} maxLength={200} placeholder={step===2?'12 de mayo de 1992':step===3?'Mañana a las 10:30':''} required/></div><div className="detail-actions"><Button type="submit">{step===3?'Revisar los datos':'Continuar escribiendo'}<ArrowRight size={15}/></Button>{step>0&&<Button type="button" variant="outline" onClick={()=>{stop();setStarted(false);setStep(v=>v-1);setAnswer('');}}><RotateCcw size={15}/>Volver</Button>}<Button type="button" variant="outline" onClick={()=>{stop();onCancel();}}>Volver al formulario</Button></div></form><dl className="voice-captured"><div><dt>Nombres</dt><dd>{draft.firstName||'Por capturar'}</dd></div><div><dt>Apellidos</dt><dd>{draft.lastName||'Por capturar'}</dd></div><div><dt>Nacimiento</dt><dd>{draft.birthDate||'Por capturar'}</dd></div></dl></section>;
}
