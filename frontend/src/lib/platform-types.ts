export const tenantKinds = ['DOCTOR','CLINIC','HOSPITAL','VETERINARY','DENTAL','SPECIALTY_CENTER'] as const;
export type TenantKind = typeof tenantKinds[number];
export type PatientDomain = 'HUMAN' | 'ANIMAL';
export type BillingCycle = 'MONTHLY' | 'YEARLY';
export const kindLabels: Record<TenantKind,string> = {DOCTOR:'Profesional independiente',CLINIC:'Clínica',HOSPITAL:'Hospital',VETERINARY:'Centro veterinario',DENTAL:'Centro odontológico',SPECIALTY_CENTER:'Centro de especialidad'};
export interface PlatformPlan {
  planId:string; name:string; description:string; status:string; version:number;
  kinds:TenantKind[]; domains:PatientDomain[]; modules:string[];
  includedBranches:number; includedProfessionals:number; includedSpecialties:number;
  maxBranches:number; maxProfessionals:number; maxSpecialties:number;
  baseMinor:number; branchMinor:number; professionalMinor:number; annualDiscount:number;
}
export interface PlatformSpecialty {code:string;name:string;domain:PatientDomain;dental:boolean;}
export interface OwnerInput {name:string;email:string;password:string;domain:PatientDomain|null;credential:string|null;}
/** Requests.Tenant, new-owner variant: ownerUserId is deliberately absent. */
export interface TenantRequest {
  name:string;ruc:string;slug:string;kind:TenantKind;domain:PatientDomain;owner:OwnerInput;
  timezone:string;branchName:string;address:string;specialties:string[];
  subscription:{planId:string;cycle:BillingCycle;branchQuota:number;professionalQuota:number;specialtyQuota:number;};
}
export interface TenantDraft {
  name:string;ruc:string;slug:string;kind:TenantKind;domain:PatientDomain;ownerName:string;ownerEmail:string;password:string;credential:string;
  timezone:string;branchName:string;address:string;specialties:string[];planId:string;cycle:BillingCycle;
  branchQuota:string;professionalQuota:string;specialtyQuota:string;
}
export interface PlatformTenant {
  id:string;name:string;ruc:string;revision:number;slug:string;kind:TenantKind;domain:PatientDomain;status:string;hostname:string;url:string;
  ownerName:string;ownerEmail:string;timezone:string;planName:string;planVersion:number;cycle:BillingCycle;
  branchQuota:number;professionalQuota:number;specialtyQuota:number;branchesUsed:number;professionalsUsed:number;specialtiesUsed:number;
}
export interface TenantConfiguration {
  planName:string;planVersion:number;cycle:BillingCycle;branchQuota:number;professionalQuota:number;specialtyQuota:number;
  baseMinor:number;branchMinor:number;professionalMinor:number;includedBranches:number;includedProfessionals:number;annualDiscount:number;modules:string[];
  branches:{id:string;name:string;address:string;active:boolean;external:boolean}[];
  specialties:PlatformSpecialty[];members:{id:string;name:string}[];
  invoices:{id:string;number:string;status:string;amountMinor:number;period:string}[];
}
export type TenantReview = Omit<TenantRequest,'owner'> & {owner:Omit<OwnerInput,'password'>};
