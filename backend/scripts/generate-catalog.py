"""Generate the initial, versioned specialty catalog from the existing design."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[2]
source = json.loads((root / 'frontend/src/data/specialty-profiles.json').read_text(encoding='utf-8'))
def literal(value):
    encoded = json.dumps(value, ensure_ascii=False, separators=(',', ':')).encode('utf-8').hex()
    return f'CONVERT(0x{encoded} USING utf8mb4)'
def text(value):
    return "'" + value.replace("'", "''") + "'"
statements = ['-- Generated catalog snapshot v1. Regenerate only before this migration is applied.']
for profile in source['profiles']:
    profile['profileVersion'] = 1
    dental = profile['code'].startswith('D_') or profile['code'] in ['V_DENTAL', 'V_DENTAL_EQUINE']
    statements.append(f"INSERT INTO specialties(code,name,domain,dental,profile) VALUES({text(profile['code'])},{text(profile['name'])},{text(profile['patientDomain'])},{int(dental)},{literal(profile)});")
modules = ['CORE','PORTAL','DENTAL','DIAGNOSTICS','PHARMACY','FINANCE','INVENTORY','HOSPITAL','SURGERY','ADVANCED','VET_POPULATION','REPORTS']
plans = [
    ('Profesional','Un profesional humano o veterinario independiente.',8900,3500,4500,1,1,5,3,1,10,['DOCTOR'],['CORE','PORTAL','DENTAL','FINANCE','REPORTS']),
    ('Centro','Equipos, centros odontológicos y de especialidad.',29900,9900,4500,1,5,10,30,200,182,['CLINIC','DENTAL','SPECIALTY_CENTER'],modules),
    ('Hospital','Instituciones con sedes y áreas clínicas.',89900,9900,4500,3,20,30,100,1000,241,['HOSPITAL','CLINIC','VETERINARY'],modules),
    ('Veterinaria','Clínicas y redes de atención veterinaria.',24900,9900,3900,1,3,10,40,300,59,['VETERINARY'],modules),
]
for index, p in enumerate(plans, 1):
    name,description,base,branch,pro,ib,ip,isp,mb,mp,msp,kinds,mods = p
    key = f'00000000-0000-0000-0000-{index:012d}'
    statements.append(f"INSERT INTO plans VALUES('{key}',{text(name)},{text(description)},'PUBLISHED',1);")
    statements.append(f"INSERT INTO plan_versions(plan_id,version,base_minor,branch_minor,professional_minor,included_branches,included_professionals,included_specialties,max_branches,max_professionals,max_specialties,annual_discount,kinds,domains,modules) VALUES('{key}',1,{base},{branch},{pro},{ib},{ip},{isp},{mb},{mp},{msp},15,{literal(kinds)},{literal(['HUMAN','ANIMAL'])},{literal(mods)});")
standard = {'DRAFT':['SUBMITTED','CANCELLED'],'SUBMITTED':['IN_PROGRESS','CANCELLED'],'IN_PROGRESS':['REVIEW','CANCELLED'],'REVIEW':['COMPLETED','IN_PROGRESS','CANCELLED']}
definitions = [
    ('LAB_ORDER','DIAGNOSTICS',True,False,['PRO'],['DIA'],['PRO','DIA','ASI','AUD'],{'DRAFT':['SUBMITTED','CANCELLED'],'SUBMITTED':['COLLECTED','CANCELLED'],'COLLECTED':['PROCESSING','CANCELLED'],'PROCESSING':['PRELIMINARY','CANCELLED'],'PRELIMINARY':['COMPLETED','PROCESSING']}),
    ('IMAGING_ORDER','DIAGNOSTICS',True,False,['PRO'],['DIA'],['PRO','DIA','ASI','AUD'],standard),
    ('SURGERY','SURGERY',True,False,['PRO'],['PRO','ASI'],['PRO','ASI','AUD'],standard),
    ('ANESTHESIA','SURGERY',True,False,['PRO'],['PRO','ASI'],['PRO','ASI','AUD'],standard),
    ('URGENCY','HOSPITAL',True,False,['REC','PRO','ASI'],['PRO','ASI'],['REC','PRO','ASI','AUD'],standard),
    ('SPECIALTY_SESSION','ADVANCED',True,False,['PRO'],['PRO','ASI'],['PRO','ASI','AUD'],standard),
    ('TRANSFUSION','ADVANCED',True,False,['PRO'],['PRO','ASI'],['PRO','ASI','AUD'],standard),
    ('TRANSPLANT','ADVANCED',True,False,['PRO'],['PRO'],['PRO','ASI','AUD'],standard),
    ('REPRODUCTION','ADVANCED',True,False,['PRO'],['PRO'],['PRO','ASI','AUD'],standard),
    ('VET_POPULATION','VET_POPULATION',False,True,['PRO'],['PRO','ASI'],['PRO','ASI','AUD'],standard),
    ('FOLLOW_UP','CORE',True,False,['PRO','REC'],['PRO','REC'],['PRO','REC','ASI','AUD'],standard),
    ('BUDGET','FINANCE',True,False,['PRO','CAJ'],['CAJ'],['PRO','CAJ','AUD'],standard),
    ('PURCHASE','INVENTORY',False,False,['ALM'],['ALM'],['ALM','ADM','AUD'],standard),
    ('INTEGRATION','CORE',False,False,['ADM'],['ADM'],['ADM','AUD'],standard),
    ('SUPPORT','CORE',False,False,['ADM','PRO','REC'],['ADM'],['ADM','PRO','REC'],standard),
]
for name,module,patient,animal,creators,operators,readers,transitions in definitions:
    statements.append(f"INSERT INTO workflow_definitions VALUES('{name}','{module}',{int(patient)},{int(animal)},{literal(creators)},{literal(operators)},{literal(readers)},{literal(transitions)});")
output = root / 'backend/src/main/resources/db/migration/V5__catalog_and_plans.sql'
output.write_text('\n'.join(statements) + '\n', encoding='utf-8')
print(f'Catalog: {len(source["profiles"])} profiles; {len(plans)} plans; {len(definitions)} workflows.')
