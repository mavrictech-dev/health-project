'use client';
import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { createFixtures, getOrganizations } from '@/mocks/fixtures';
import { portalLinked, runCommand, uid, type CommandTarget } from '@/mocks/engine';
import { clearFiles } from '@/lib/files';
import { normalizeSaasData, runSaasCommand, tenantProfessionals, tenantSpecialties } from '@/lib/saas';
import type { SaasCommand, SaasTarget, SaasValues } from '@/lib/saas-types';
import type { Context, DemoData, FormValues, Role, Theme } from '@/lib/types';

export interface Overlay {
  kind: 'action' | 'context' | 'demo' | 'search' | 'notifications' | 'record' | 'mobile-menu' | 'saas';
  command?: SaasCommand;
  saasTarget?: SaasTarget;
  actionId?: string;
  target?: CommandTarget;
  recordId?: string;
}
interface DemoStore {
  data: DemoData; context: Context; theme: Theme; sidebarCollapsed: boolean; scenario: string;
  overlay: Overlay | null; busy: boolean; failure: string; message: string; dirty: boolean;
  draftNotes: Record<string, string>;
  filters: Record<string, FormValues>;
  setFilters: (flow: string, values: FormValues) => void;
  density: 'comfortable' | 'compact';
  setDensity: (density: 'comfortable' | 'compact') => void;
  readNotifications: string[];
  markNotificationRead: (id: string) => void;
  setTheme: (theme: Theme) => void;
  setCollapsed: (value: boolean) => void;
  setPatient: (patient: string) => void;
  setSpecialty: (specialty: string) => void;
  setRole: (role: Role) => void;
  switchContext: (org: string, branch: string) => void;
  setProfessional: (id: string) => void;
  executeSaas: (command: SaasCommand, values: SaasValues, target?: SaasTarget) => Promise<string>;
  open: (overlay: Overlay) => void;
  close: () => void;
  setDirty: (dirty: boolean) => void;
  setFailure: (failure: string) => void;
  notify: (message: string) => void;
  reset: (scenario?: string) => void;
  execute: (id: string, values?: FormValues, target?: CommandTarget) => Promise<string | undefined>;
  updateNote: (note: string) => void;
}
const initialContext: Context = { org: 'org-human', branch: 'miraflores', role: 'PRO', patient: 'p-lucia', encounter: 'e-1', specialty: 'H_GENERAL_MEDICINE' };

export const useDemo = create<DemoStore>()(persist((set, get) => ({
  data: createFixtures(), context: initialContext, theme: 'light', sidebarCollapsed: false, scenario: 'consulta',
  overlay: null, busy: false, failure: '', message: '', dirty: false, draftNotes: {}, filters: {}, density: 'comfortable', readNotifications: [],
  setFilters: (flow, values) => set(state => ({ filters: { ...state.filters, [flow]: values } })),
  setDensity: density => set({ density }),
  markNotificationRead: id => set(state => ({ readNotifications: [...new Set([...state.readNotifications, id])] })),
  setTheme: theme => set({ theme }),
  setCollapsed: sidebarCollapsed => set({ sidebarCollapsed }),
  setPatient: id => {
    const { data, context } = get(); const patient = data.patients.find(p => p.id === id && p.org === context.org);
    if (!patient) return;
    if (['PAC', 'RES'].includes(context.role) && !portalLinked(data, context, id)) return;
    const encounter = data.encounters.find(e => e.patient === id && e.org === context.org && e.status !== 'Finalizada');
    set({ context: { ...context, patient: id, encounter: ['PAC', 'RES'].includes(context.role) ? '' : encounter?.id || '', specialty: patient.specialty, professional: encounter?.professional || context.professional } });
  },
  setSpecialty: specialty => set(state => ({ context: { ...state.context, specialty } })),
  setRole: role => set(state => {
    const portal = ['PAC', 'RES'].includes(role); const context = { ...state.context, role };
    const linked = ['SOP', 'SAD'].includes(role) ? [] : portal ? state.data.patients.filter(p => p.org === context.org && !p.mergedInto && portalLinked(state.data, context, p.id)) : state.data.patients.filter(p => p.org === context.org && !p.mergedInto);
    const patient = linked.find(p => p.id === context.patient) || linked[0];
    const encounter = state.data.encounters.find(e => e.org === context.org && e.patient === patient?.id && e.status !== 'Finalizada');
    return { context: { ...context, patient: patient?.id || '', specialty: patient?.specialty || context.specialty, encounter: portal ? '' : encounter?.id || '' }, dirty: false, overlay: null };
  }),
  switchContext: (orgId, branchId) => {
    const org = getOrganizations(get().data).find(o => o.id === orgId); if (!org || !org.branches.some(b => b.id === branchId)) return;
    const data = get().data; const patient = data.patients.find(p => p.org === orgId);
    const professional = tenantProfessionals(data, orgId).find(p => p.id === get().context.professional) || tenantProfessionals(data, orgId)[0];
    const encounter = data.encounters.find(e => e.org === orgId && e.patient === patient?.id && e.status !== 'Finalizada');
    set(state => ({ context: { ...state.context, org: orgId, branch: branchId, patient: patient?.id || '', encounter: encounter?.id || '', specialty: patient?.specialty || tenantSpecialties(data, orgId)[0]?.code || 'H_GENERAL_MEDICINE', professional: professional?.id }, dirty: false, overlay: null }));
  },
  setProfessional: id => set(state => { const professional = tenantProfessionals(state.data, state.context.org).find(p => p.id === id); return professional ? { context: { ...state.context, professional: id, specialty: professional.membership.specialties[0] || state.context.specialty } } : {}; }),
  executeSaas: async (command, values, target = {}) => {
    if (get().busy) throw new Error('Hay una operación en curso.');
    set({ busy: true });
    try { await new Promise(resolve => setTimeout(resolve, 180)); const result = runSaasCommand(get().data, get().context, command, values, target); const context = get().context; const org = result.data.organizations.find(o => o.id === context.org); const branch = org?.branches.find(b => b.id === context.branch && b.status !== 'Inactiva') || org?.branches.find(b => b.status !== 'Inactiva'); set({ data: result.data, context: { ...context, branch: branch?.id || context.branch }, busy: false, dirty: false, message: result.message }); return result.targetId; } catch (error) { set({ busy: false }); throw error; }
  },
  open: overlay => set(state => {
    const appointment = state.data.appointments.find(a => a.id === overlay.target?.appointmentId && a.org === state.context.org);
    const document = state.data.documents.find(d => d.id === overlay.target?.documentId && d.org === state.context.org);
    const record = state.data.records.find(r => r.id === (overlay.recordId || overlay.target?.recordId) && r.org === state.context.org);
    const patient = state.data.patients.find(p => p.id === (appointment?.patient || document?.patient || record?.patient) && p.org === state.context.org);
    const encounter = patient ? state.data.encounters.find(e => e.patient === patient.id && e.org === state.context.org && e.status !== 'Finalizada') : undefined;
    const nextOverlay = overlay.kind === 'action' ? { ...overlay, target: { ...overlay.target, operationId: uid('command') } } : overlay;
    return { overlay: nextOverlay, dirty: false, message: '', context: patient ? { ...state.context, patient: patient.id, specialty: patient.specialty, encounter: encounter?.id || '' } : state.context };
  }),
  close: () => set({ overlay: null, dirty: false }),
  setDirty: dirty => set({ dirty }),
  setFailure: failure => set({ failure }),
  notify: message => set({ message }),
  reset: (scenario = 'consulta') => {
    clearFiles();
    const context = { ...initialContext };
    if (scenario === 'veterinaria') { context.org = 'org-vet'; context.branch = 'vet-centro'; context.patient = 'p-luna'; context.encounter = 'e-vet'; context.specialty = 'V_GENERAL'; }
    if (scenario === 'odontologia') { context.patient = 'p-diego'; context.encounter = 'e-dental'; context.specialty = 'D_ODONTOLOGIA_GENERAL'; }
    set({ data: createFixtures(scenario), context, scenario, overlay: null, dirty: false, busy: false, failure: '', draftNotes: {}, filters: {}, message: 'Escenario restaurado. Todo listo para presentar.' });
  },
  execute: async (id, values = {}, target = {}) => {
    if (get().busy) throw new Error('Ya se está procesando esta operación.');
    set({ busy: true });
    try {
      await new Promise(resolve => setTimeout(resolve, 230));
      if (get().failure) { const failure = get().failure; set({ failure: '' }); throw new Error(failure === 'agenda' ? 'El horario acaba de ocuparse en la simulación. Elige una alternativa.' : failure === 'version' ? 'Hay otra revisión preparada. Compara versiones antes de guardar.' : 'El servicio simulado no respondió. Tus datos siguen en el formulario.'); }
      const { draftNotes, context } = get();
      if (id === 'F21_A04' && draftNotes[context.encounter] !== undefined) throw new Error('Guarda el borrador de la nota antes de finalizar esta visita.');
      const capture = id === 'F21_A02' && values.resumen === undefined && draftNotes[context.encounter] !== undefined ? { ...values, resumen: draftNotes[context.encounter] } : values;
      const result = runCommand(get().data, context, id, capture, { ...target, operationId: target.operationId || get().overlay?.target?.operationId || uid('command') });
      const remaining = { ...draftNotes }; if (id === 'F21_A02') delete remaining[context.encounter];
      if (id === 'F79_A03') for (const encounter of result.data.encounters.filter(e => e.org === context.org)) delete remaining[encounter.id];
      set({ data: normalizeSaasData(result.data), context: result.context, message: result.message, busy: false, dirty: false, draftNotes: remaining });
      return result.targetId;
    } catch (error) { set({ busy: false }); throw error; }
  },
  updateNote: note => set(state => ({ draftNotes: { ...state.draftNotes, [state.context.encounter]: note } })),
}), {
  name: 'health-project-demo-v1', version: 2, skipHydration: true,
  migrate: saved => { const state = saved as Partial<DemoStore>; return { data: state.data ? normalizeSaasData({ ...state.data, organizations: getOrganizations(state.data) }) : createFixtures(), context: state.context || initialContext, theme: state.theme || 'light', sidebarCollapsed: state.sidebarCollapsed || false, scenario: state.scenario || 'consulta', draftNotes: state.draftNotes || {}, density: state.density || 'comfortable', readNotifications: state.readNotifications || [] }; },
  partialize: state => ({ data: state.data, context: state.context, theme: state.theme, sidebarCollapsed: state.sidebarCollapsed, scenario: state.scenario, draftNotes: state.draftNotes, density: state.density, readNotifications: state.readNotifications }),
}));
