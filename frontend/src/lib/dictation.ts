export interface RecognitionResult {isFinal:boolean;[index:number]:{transcript:string};}
export interface RecognitionEvent {resultIndex:number;results:{length:number;[index:number]:RecognitionResult};}
export interface Recognition {
  lang:string;continuous:boolean;interimResults:boolean;
  onresult:((event:RecognitionEvent)=>void)|null;onerror:((event:{error:string})=>void)|null;onend:(()=>void)|null;
  start:()=>void;stop:()=>void;abort:()=>void;
}
export type RecognitionConstructor=new()=>Recognition;
export function recognitionConstructor():RecognitionConstructor|undefined {
  if(typeof window==='undefined')return undefined;
  const browser=window as unknown as {SpeechRecognition?:RecognitionConstructor;webkitSpeechRecognition?:RecognitionConstructor};
  return browser.SpeechRecognition||browser.webkitSpeechRecognition;
}
export function appendDictation(current:string,transcript:string){const text=transcript.trim();return text?current+(current&&!/\s$/.test(current)?' ':'')+text:current;}
export function dictationError(code:string){return code==='not-allowed'||code==='service-not-allowed'?'No se autorizó el micrófono. Puedes seguir escribiendo.':code==='audio-capture'?'No se encontró un micrófono disponible. Puedes seguir escribiendo.':code==='no-speech'?'No se detectó voz. Puedes volver a dictar o escribir.':'El dictado se interrumpió. Tu texto se conserva y puedes seguir escribiendo.';}
