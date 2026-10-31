import data from '@/data/specialty-profiles.json';
export interface SpecialtyField { id: string; label: string; type: string; required?: boolean; unit?: string; options?: string[]; }
export interface SpecialtyProfile { code: string; name: string; patientDomain: string; anatomicalArea: { code: string; label: string }; anatomicalAreas: { code: string; label: string }[]; anatomyRegions: string[]; atlasVariant: string; speciesOptions: { id: string; label: string }[]; dentitionOptions: { id: string; label: string }[]; fields: SpecialtyField[]; captureLabels: string[]; components: string[]; componentFamilies: string[]; }
export interface FamilyContract { code: string; name: string; fields: SpecialtyField[]; interactions: string[]; output: string; renderer: string; }
export const profiles = data.profiles as unknown as SpecialtyProfile[];
export const familyContracts = data.familyContracts as unknown as FamilyContract[];
export function rendererFamilies(profile: SpecialtyProfile) {
  const supplement = profile.components.flatMap(id => /genogram|pedigree/.test(id) ? ['GENETICS'] : /cephal|occlus/.test(id) ? ['ORTHODONTIC'] : /root|canal/.test(id) ? ['ENDO'] : /periodont/.test(id) ? ['PERIODONTAL'] : []);
  return [...new Set([...profile.componentFamilies, ...supplement])];
}
