import type { SaasState } from './saas-types';
export type Role = 'ADM' | 'REC' | 'PRO' | 'ASI' | 'DIA' | 'FAR' | 'CAJ' | 'ALM' | 'PAC' | 'RES' | 'AUD' | 'SOP' | 'SAD';
export type Theme = 'light' | 'dark' | 'navy';
export type PatientDomain = 'HUMAN' | 'ANIMAL';
export interface Branch { id: string; name: string; address?: string; external?: boolean; status?: 'Activa' | 'Inactiva'; }
export interface Organization { id: string; name: string; initials: string; type: string; branches: Branch[]; }
export interface Patient { id: string; org: string; name: string; domain: PatientDomain; species?: string; age: string; identifier: string; phone: string; email: string; responsible?: string; avatar: string; color: string; specialty: string; allergies: string[]; created: string; mergedInto?: string; }
export interface Appointment { id: string; org: string; branch: string; patient: string; professional: string; service: string; specialty: string; date: string; time: string; duration: number; status: string; note: string; }
export interface Encounter { id: string; org: string; branch: string; patient: string; professional: string; date: string; specialty: string; status: string; note: string; revision: number; }
export interface RecordItem { id: string; org: string; resource: string; flow: string; patient?: string; parent?: string; title: string; status: string; date: string; revision: number; data: Record<string, string | number | boolean>; history?: { revision: number; status: string; data: Record<string, string | number | boolean> }[]; }
export interface DocumentItem { id: string; org: string; patient: string; title: string; type: string; status: string; version: number; content: string; signed?: string; published: boolean; withdrawn?: boolean; date: string; original?: string; }
export interface Observation { id: string; org: string; patient: string; parameter: string; value: number; unit: string; date: string; }
export interface Annotation { id: string; org: string; patient: string; encounter: string; component: string; structure: string; surface?: string; condition: string; procedure?: string; value?: number; unit?: string; date: string; }
export interface Movement { id: string; org: string; patient: string; kind: 'charge' | 'payment' | 'refund' | 'reversal'; amount: number; title: string; date: string; parent?: string; }
export interface StockItem { id: string; org: string; name: string; lot: string; expiry: string; quantity: number; unit: string; category: string; warehouse?: string; }
export interface Bed { id: string; org: string; name: string; type: 'Cama' | 'Jaula'; area: string; patient?: string; status: string; }
export interface DemoEvent { id: string; org: string; branch: string; actor: Role; operation: string; label: string; date: string; target?: string; operationId?: string; }
export interface DemoJob { id: string; org: string; type: string; label: string; status: string; attempts: number; operationId: string; date: string; }
export interface Context { org: string; branch: string; role: Role; patient: string; encounter: string; specialty: string; professional?: string; }
export interface DemoData { organizations: Organization[]; saas?: SaasState; patients: Patient[]; appointments: Appointment[]; encounters: Encounter[]; records: RecordItem[]; documents: DocumentItem[]; observations: Observation[]; annotations: Annotation[]; movements: Movement[]; stock: StockItem[]; beds: Bed[]; events: DemoEvent[]; jobs: DemoJob[]; }
export interface ActionSpec { id: string; label: string; flow: string; screens: string[]; roles: string[]; pattern: string; operation: string; resource: string; effect: string; }
export interface ScreenSpec { id: string; name: string; area: string; roles: string[]; routes: string[]; feature: string; contents: string[]; flows: string[]; }
export interface FormField { key: string; label: string; type: 'text' | 'textarea' | 'number' | 'date' | 'time' | 'select' | 'file' | 'checkbox'; required: boolean; options?: string[]; min?: number; }
export interface ActionForm { fields: FormField[]; reviewRequired: boolean; targetStatus?: string; }
export type FormValues = Record<string, string | number | boolean>;
