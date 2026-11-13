'use client';
import {useEffect,useRef,useState} from 'react';
import {Mic,Square} from 'lucide-react';
import {Button} from '@/components/ui/button';
import {Textarea} from '@/components/ui/textarea';
import {appendDictation,dictationError,recognitionConstructor,type Recognition} from '@/lib/dictation';

export function DictationField({id,label,value,onChange,required=false}:{id:string;label:string;value:string;onChange:(value:string)=>void;required?:boolean}){
  const [listening,setListening]=useState(false),[message,setMessage]=useState('');
  const recognition=useRef<Recognition|null>(null),latest=useRef(value),change=useRef(onChange);
  latest.current=value;change.current=onChange;
  useEffect(()=>()=>{const current=recognition.current;recognition.current=null;if(current){current.onresult=null;current.onerror=null;current.onend=null;current.abort();}},[]);
  function toggle(){
    if(recognition.current){recognition.current.stop();return;}
    const Constructor=recognitionConstructor();
    if(!Constructor){setMessage('Este navegador no admite dictado. Puedes escribir en el campo.');return;}
    try{
      // Stop another field before starting: only the selected target receives results.
      window.dispatchEvent(new CustomEvent('health:dictation-stop',{detail:id}));
      const active=new Constructor();recognition.current=active;active.lang='es-PE';active.continuous=true;active.interimResults=false;
      let consumed=0;
      active.onresult=event=>{if(recognition.current!==active)return;for(let i=Math.max(event.resultIndex,consumed);i<event.results.length;i++){const result=event.results[i];if(!result.isFinal)continue;const next=appendDictation(latest.current,result[0].transcript);if(next.length>20000){setMessage('El campo llegó a su límite. El texto anterior se conserva.');active.stop();return;}latest.current=next;change.current(next);consumed=i+1;}};
      active.onerror=event=>{if(recognition.current===active){setMessage(dictationError(event.error));recognition.current=null;setListening(false);}};
      active.onend=()=>{if(recognition.current===active){recognition.current=null;setListening(false);}};
      setMessage('');active.start();setListening(true);
    }catch{recognition.current=null;setListening(false);setMessage('No se pudo iniciar el dictado. Puedes seguir escribiendo.');}
  }
  useEffect(()=>{const stop=(event:Event)=>{if((event as CustomEvent<string>).detail!==id){const active=recognition.current;recognition.current=null;if(active){active.onresult=null;active.abort();setListening(false);}}};window.addEventListener('health:dictation-stop',stop);return()=>window.removeEventListener('health:dictation-stop',stop);},[id]);
  return <div className="form-field dictation-field"><div className="dictation-label"><label htmlFor={id}>{label}</label><Button type="button" variant={listening?'default':'outline'} onClick={toggle} aria-label={(listening?'Detener dictado de ':'Dictar en ')+label} aria-pressed={listening}>{listening?<Square size={15}/>:<Mic size={15}/>}<span>{listening?'Detener':'Dictar'}</span></Button></div><Textarea id={id} value={value} onChange={e=>{latest.current=e.target.value;onChange(e.target.value);}} required={required} maxLength={20000} rows={4}/>{listening&&<small role="status">Escuchando para {label}. El dictado se añade al texto existente.</small>}{message&&<small role="status">{message}</small>}</div>;
}
