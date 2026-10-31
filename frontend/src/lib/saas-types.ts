import type { PatientDomain, Role } from './types';

export type TenantKind = 'DOCTOR' | 'CLINIC' | 'HOSPITAL' | 'VETERINARY' | 'DENTAL' | 'SPECIALTY_CENTER';
export type TenantStatus = 'Prueba' | 'Activo' | 'Suspendido' | 'Cancelado';
export type ModuleId = 'CORE' | 'PORTAL' | 'DENTAL' | 'DIAGNOSTICS' | 'PHARMACY' | 'FINANCE' | 'INVENTORY' | 'HOSPITAL' | 'SURGERY' | 'ADVANCED' | 'VET_POPULATION' | 'REPORTS';
export interface PlanRate { version: number; base: number; perBranch: number; perProfessional: number; includedBranches: number; includedProfessionals: number; annualDiscount: number; }
export interface SaasPlan {
  id: string; name: string; description: string; version: number; status: 'Publicado' | 'Borrador' | 'Archivado';
  kinds: TenantKind[]; domains: PatientDomain[]; rate: PlanRate; maxBranches: number; maxProfessionals: number; maxSpecialties: number; includedSpecialties: number; modules: ModuleId[];
}
export interface Subscription {
  planId: string; cycle: 'Mensual' | 'Anual'; branchQuota: number; professionalQuota: number; specialtyQuota: number;
  rate: PlanRate; modules: ModuleId[]; nextRenewal: string;
}
export interface Tenant {
  id: string; kind: TenantKind; domain: PatientDomain; status: TenantStatus; slug: string; ownerName: string; ownerEmail: string;
  created: string; specialties: string[]; subscription: Subscription;
}
export interface ProfessionalIdentity { id: string; name: string; email: string; domain: PatientDomain; credential: string; color: string; avatar: string; }
export interface ProfessionalMembership { id: string; tenantId: string; professionalId: string; specialties: string[]; branchIds: string[]; status: 'Activo' | 'Invitado' | 'Inactivo'; owner: boolean; }
export interface SpecialtyArea { id: string; tenantId: string; branchId: string; name: string; specialties: string[]; }
export interface SaasInvoice { id: string; tenantId: string; number: string; period: string; amount: number; date: string; status: 'Pendiente' | 'Pagado'; }
export interface SaasEvent { id: string; actor: Role; tenantId?: string; label: string; target: string; date: string; }
export interface SaasState { plans: SaasPlan[]; tenants: Tenant[]; professionals: ProfessionalIdentity[]; memberships: ProfessionalMembership[]; areas: SpecialtyArea[]; invoices: SaasInvoice[]; events: SaasEvent[]; }
export type SaasCommand = 'tenant.create' | 'tenant.edit' | 'tenant.status' | 'plan.create' | 'plan.edit' | 'subscription.configure' | 'branch.create' | 'branch.edit' | 'branch.archive' | 'member.create' | 'member.edit' | 'member.status' | 'specialties.configure' | 'area.create' | 'area.edit' | 'invoice.pay';
export interface SaasTarget { tenantId?: string; planId?: string; branchId?: string; memberId?: string; areaId?: string; invoiceId?: string; }
export type SaasValues = Record<string, string | number | boolean | string[]>;
