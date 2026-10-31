"""Consolida medicina humana, odontología humana y veterinaria de Health Project.

No ejecuta migraciones ni habilita funciones. Produce documentos de diseño y
una referencia de catálogo; los identificadores de capacidades son propuestas.
"""
import json
import re
import sys
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path

BASE = Path(__file__).resolve().parent
DOCS = BASE.parent
VIS_DIR = Path(r'C:\Users\maxmo\.codex\visualizations\2026\10\13\01a133e5-78cf-7462-ae45-f175e87523bd')
DOMAINS = [
    ('human_draft.json', 'HUMAN_MEDICINE', 'Medicina humana'),
    ('dental_draft.json', 'HUMAN_DENTISTRY', 'Odontología humana'),
    ('veterinary_draft.json', 'VETERINARY', 'Veterinaria'),
]
SOURCES = {
    'PRODUCT': {'title': 'Propuesta funcional de Health Project', 'url': None, 'scope': 'Diseño original: campos, componentes, flujos, dependencias y prioridades; no reconocimiento profesional.'},
    'CONAREME': {'title': 'CONAREME: estándares de formación y listado referencial 2025', 'url': 'https://www.conareme.org.pe/web/Documentos/Actas/2025/CADM/ACTA%20N%C2%B006%20-%20SUBCOMITE%20DE%20ADMISION%2021.02.25%20-%20Publicar.pdf', 'scope': 'Nomenclatura peruana referencial; no registro exhaustivo vigente 2026.'},
    'CMP': {'title': 'CMP: registro de especialidad y subespecialidad', 'url': 'https://cmp.org.pe/registro-de-especialidad-o-sub-especialidad/', 'scope': 'Contexto de registro profesional, separado del catálogo de software.'},
    'ABMS': {'title': 'ABMS: Specialty and Subspecialty Certificates', 'url': 'https://abms.org/member-boards/specialty-subspecialty-certificates/', 'scope': 'Taxonomía internacional de referencia, sin equivalencia automática con Perú.'},
    'ABMS_IM': {'title': 'ABMS: Internal Medicine', 'url': 'https://abms.org/member-board/american-board-of-internal-medicine/'},
    'ABMS_PED': {'title': 'ABMS: Pediatrics', 'url': 'https://abms.org/member-board/american-board-of-pediatrics/'},
    'ABPN': {'title': 'ABPN: certificación', 'url': 'https://abpn.org/become-certified-2/'},
    'ABMS_PATH': {'title': 'ABMS: Pathology', 'url': 'https://abms.org/member-board/american-board-of-pathology/'},
    'ABMS_SURG': {'title': 'ABMS: Surgery', 'url': 'https://abms.org/member-board/american-board-of-surgery/'},
    'ABMS_PREV': {'title': 'ABMS: Preventive Medicine', 'url': 'https://abms.org/member-board/american-board-of-preventive-medicine/'},
    'ABMS_OBG': {'title': 'ABMS: Obstetrics and Gynecology', 'url': 'https://abms.org/member-board/american-board-of-obstetrics-and-gynecology/'},
    'ABMS_ANES': {'title': 'ABMS: Anesthesiology', 'url': 'https://abms.org/member-board/american-board-of-anesthesiology/'},
    'ABMS_RAD': {'title': 'ABMS: Radiology', 'url': 'https://abms.org/member-board/american-board-of-radiology/'},
    'ABMS_REHAB': {'title': 'ABMS: Physical Medicine and Rehabilitation', 'url': 'https://abms.org/member-board/american-board-of-physical-medicine-and-rehabilitation/'},
    'ABMS_GEN': {'title': 'ABMS: Medical Genetics and Genomics', 'url': 'https://abms.org/member-board/american-board-of-medical-genetics-and-genomics/'},
    'ABMS_ENT': {'title': 'ABMS: Otolaryngology, Head and Neck Surgery', 'url': 'https://abms.org/member-board/american-board-of-otolaryngology-head-and-neck-surgery/'},
    'ABMS_DERM': {'title': 'ABMS: Dermatology', 'url': 'https://abms.org/member-board/american-board-of-dermatology/'},
    'ADA_NC': {'title': 'National Commission / ADA: especialidades dentales', 'url': 'https://ncrdscb.ada.org/recognized-dental-specialties', 'scope': 'Nombres de especialidades en este sistema internacional.'},
    'COP_LIMA': {'title': 'Colegio profesional de Lima: denominaciones odontológicas del RNE', 'url': 'https://col.org.pe/especialidades-odontologicas-y-rol-de-cirujanas-dentistas/', 'scope': 'Referencia peruana con datos al 11 de febrero de 2026; los alias son correspondencias funcionales, no homologación.'},
    'WV_AVMA': {'title': 'WV Board: listado referencial AVMA del 2 de mayo de 2025', 'url': 'https://wvbvm.org/Portals/WVBVM/docs/Forms/AVMA%20List%20of%20Specialties.pdf', 'scope': 'Dominios veterinarios; no acredita reconocimiento en Perú ni es actualización directa de AVMA.'},
    'ABVP': {'title': 'American Board of Veterinary Practitioners', 'url': 'https://abvp.com/become-a-specialist/', 'scope': 'Prácticas veterinarias por especies y entornos.'},
    'AVDC': {'title': 'American Veterinary Dental College: nomenclatura', 'url': 'https://avdc.org/avdc-nomenclature/', 'scope': 'Nomenclatura dental veterinaria; Triadan modificado por especie y dentición.'},
    'APA': {'title': 'APA: áreas de psicología', 'url': 'https://www.apa.org/education-career/guide/careers', 'scope': 'Áreas de trabajo; no rutas de habilitación peruana.'},
    'APTA': {'title': 'APTA: áreas de terapia física', 'url': 'https://www.apta.org/your-career/career-advancement/specialist-certification', 'scope': 'Nomenclatura de ámbitos de rehabilitación.'},
    'AOTA': {'title': 'AOTA: práctica de terapia ocupacional y salud mental', 'url': 'https://www.aota.org/practice/clinical-topics/mental-health'},
    'ASHA': {'title': 'ASHA: ámbito de comunicación y deglución', 'url': 'https://www.asha.org/policy/sp2016-00343/'},
    'MINSA_PROFESSIONS': {'title': 'INMP/MINSA: profesiones y formación en servicios', 'url': 'https://cdn.www.gob.pe/uploads/document/file/9925187/8098285-rd-n-104-2026-dg-inmp-minsa.pdf', 'scope': 'Contexto profesional; entradas funcionales diseñadas para el producto.'},
    'MINSA_NURSING': {'title': 'MINSA: residentado y áreas de enfermería', 'url': 'https://www.gob.pe/institucion/minsa/noticias/1365655-mas-enfermeras-especialistas-para-el-peru-minsa-fortalece-el-residentado-en-enfermeria-para-mejorar-la-atencion-a-los-pacientes', 'scope': 'Contexto de especialización; no justifica clasificar todas las áreas como títulos oficiales.'},
    'MINSA_NUTRITION': {'title': 'MINSA: consejería nutricional materna', 'url': 'https://www.gob.pe/institucion/minsa/informes-publicaciones/284840-consejeria-nutricional-en-el-marco-de-la-atencion-integral-de-salud-de-la-gestante-y-puerpera-guia-tecnica'},
}

MODULES = {
    'clinical': 'Núcleo clínico', 'patients': 'Pacientes y responsables',
    'identity': 'Identidad y acceso', 'organizations': 'Organizaciones y membresías',
    'scheduling': 'Agenda', 'specialties': 'Plantillas y paquetes de especialidad',
    'documents': 'Documentos y archivos privados', 'audit': 'Auditoría',
    'consent': 'Consentimientos', 'observations': 'Mediciones estructuradas',
    'procedures': 'Procedimientos', 'orders': 'Órdenes y derivaciones',
    'laboratory': 'Laboratorio', 'imaging': 'Estudios e informes de imágenes',
    'pacs': 'PACS/DICOM y visores', 'surgery': 'Cirugía y perioperatorio',
    'anesthesia': 'Registro anestésico', 'inpatient': 'Hospitalización',
    'nursing': 'Enfermería', 'emergency': 'Urgencias y triaje',
    'pharmacy': 'Prescripción y farmacia', 'medication_administration': 'Administración de medicamentos',
    'inventory': 'Inventario y lotes', 'integrations': 'Adaptadores externos',
    'device_integration': 'Conexión con equipos', 'reporting': 'Reportes',
    'rehabilitation': 'Rehabilitación y sesiones', 'oncology': 'Episodios y sesiones oncológicas',
    'obstetrics': 'Gestación, parto y puerperio', 'reproduction': 'Reproducción y fertilidad',
    'population': 'Programas, grupos y poblaciones', 'animal_populations': 'Rebaños, lotes y colonias',
    'dental_lab': 'Trabajos de laboratorio dental', 'cashier': 'Caja y pagos',
    'quality': 'Calidad y auditoría asistencial', 'chain_of_custody': 'Trazabilidad de evidencias',
    'restricted_notes': 'Notas con permisos específicos', 'validated_calculations': 'Cálculos y referencias validados',
    'staff': 'Personal y equipos', 'suppliers': 'Proveedores',
    'genetics':'Datos e informes genéticos','infection_control':'Control de infecciones',
    'radiopharmaceuticals':'Materiales radiofarmacéuticos','radiotherapy':'Cursos de radioterapia',
    'transfusion':'Banco de sangre y transfusión','transplant':'Episodios de trasplante',
    'immunization':'Vacunación','clinical_signing':'Cierre, firma y adendas',
    'external_access':'Acceso externo acotado','device_registry':'Registro y trazabilidad de dispositivos',
}
MODULE_ALIASES = {
    'clinical_core':'clinical','historia_clinica':'clinical','encuentros':'clinical','diagnosticos':'clinical',
    'structured_forms':'specialties','formularios':'specialties','specialty_forms':'specialties',
    'document_store':'documents','documentos':'documents','imagenes_clinicas':'documents','informes':'documents',
    'pacientes':'patients','responsables':'patients','identidad':'identity','permisos':'identity',
    'agenda':'scheduling','auditoria':'audit','consentimientos':'consent','mediciones':'observations',
    'procedimientos':'procedures','laboratorio':'laboratory','labs':'laboratory','ordenes_clinicas':'orders',
    'referencias':'orders','cirugia':'surgery','anestesia':'anesthesia','hospitalizacion':'inpatient',
    'enfermeria':'nursing','urgencias':'emergency','medicamentos':'pharmacy','administraciones':'medication_administration',
    'inventario':'inventory','reportes':'reporting','campanas':'population','public_health_reporting':'population',
    'laboratorio_dental':'dental_lab','caja':'cashier','calidad':'quality','cadena_custodia':'chain_of_custody',
    'personal':'staff','proveedores':'suppliers','anatomia_patologica':'laboratory',
    'analytics':'reporting','appointments':'scheduling','care_plans':'clinical',
    'certificates':'documents','clinical_configuration':'specialties','device_tracking':'device_registry',
    'dispatch':'emergency','employer_access':'external_access','genetic_data':'genetics',
    'growth_reference':'validated_calculations','lab_integration':'integrations','media_store':'documents',
    'mobile_capture':'clinical','nuclear_material_tracking':'radiopharmaceuticals','pacs_integration':'pacs',
    'pathology':'laboratory','population_registry':'population','pregnancy_registry':'obstetrics',
    'radiotherapy_integration':'radiotherapy','resource_management':'scheduling','scales':'validated_calculations',
    'sensitive_access':'restricted_notes','signal_store':'documents','signatures':'clinical_signing',
    'specimen_tracking':'laboratory','transplant_registry':'transplant','vaccination':'immunization',
}
FAMILIES = {
    'FORM':'Formularios clínicos versionados', 'ANATOMY':'Mapas anatómicos versionados',
    'HUMAN_DENTAL':'Odontograma humano por pieza y cara', 'VET_DENTAL':'Odontograma veterinario por especie',
    'PERIODONTAL':'Periodontograma y tejidos de soporte', 'ENDO':'Raíces y conductos dentales',
    'ORTHODONTIC':'Ortodoncia, oclusión y cefalometría', 'PROSTHETIC':'Prótesis, implantes y trabajos de laboratorio',
    'GROWTH':'Desarrollo, antropometría y crecimiento', 'TRENDS':'Mediciones y series temporales',
    'TIMELINE':'Evolución y seguimiento por eventos', 'SCALES':'Escalas e instrumentos versionados',
    'PHOTO':'Fotografías y lesiones seriadas', 'IMAGING':'Estudios, imágenes e informes',
    'SIGNAL':'Señales, audio y videos', 'SURGERY':'Registros quirúrgicos y anestésicos',
    'HOSPITAL':'Hojas de cuidados y monitorización', 'MEDICATION':'Medicaciones y administración',
    'REPRODUCTION':'Gestación, reproducción y vínculos de descendencia',
    'LAB':'Muestras, resultados y trazabilidad', 'POPULATION':'Poblaciones, programas y ambiente',
    'FUNCTION':'Función, movilidad y rehabilitación', 'RELATIONSHIP':'Responsables y relaciones',
    'REPORT':'Informes y documentos', 'DEVICE':'Dispositivos, materiales y lotes',
    'TRIAGE':'Triaje y secuencia de urgencia', 'VISION':'Registro visual y refracción',
    'HEARING':'Audición y comunicación', 'GENETICS':'Pedigrí y datos genéticos',
    'QUALITY':'Indicadores y revisión de calidad', 'CONSENT':'Consentimiento y alcance de acceso',
}
FAMILY_RULES = [
    ('GENETICS',r'pedig|genealog|genetic|genomic|cariotyp|variant'),
    ('VET_DENTAL',r'veterinary_odont|equine_odont|species_dental'),
    ('PERIODONTAL',r'periodont|periimplant|furcac|movilidad_dental'),
    ('HUMAN_DENTAL',r'odontogram|superficies_dentales|dental_chart|tooth_chart'),
    ('ENDO',r'endodon|conductos|raices|pulpares'),
    ('ORTHODONTIC',r'cefal|orthodont|ortodon|oclusion|occlusion|mandibular|aparatos'),
    ('PROSTHETIC',r'protes|prosthe|implant|rehabilitacion_oral|laboratorio_dental|trabajos_dentales'),
    ('VISION',r'visual_acuity|refraction|refraccion|retina|visual_field|campim|ocular_exam|eye_exam'),
    ('HEARING',r'audiogram|communication_profile|swallowing|tympan|hearing|degluc|comunicacion'),
    ('ANATOMY',r'map|atlas|anatom|body|skelet|esquema|surface|dermatom'),
    ('GROWTH',r'growth|anthropom|antropom|erupcion|desarrollo|development|body_condition'),
    ('REPRODUCTION',r'gestation|pregnan|maternal|reproduct|offspring|lactation|postpartum|partogram|fertil'),
    ('TRIAGE',r'triage|emergency|urgencia'),
    ('SURGERY',r'operative|quirurg|surgical|anesthe|anestesi|perioperat|posoperator|recuperacion'),
    ('HOSPITAL',r'flowsheet|fluid_balance|icu_|critical_|handoff|nursing|enfermer|care_plan|hospital|dialysis|neonatal|bed_|balance_hidr'),
    ('MEDICATION',r'medication|dispensing|farmac|pharmacy|administration|medicamento'),
    ('LAB',r'lab_|laborator|sample|specimen|muestra|microb|susceptibility|microscopy|patholog|patolog|cito'),
    ('PHOTO',r'photo|foto|galeria|gallery|lesion_series'),
    ('SIGNAL',r'signal|ecg|eeg|audio|video|monitoring_chart'),
    ('IMAGING',r'imaging|image_view|image_links|radiograf|radiologia|cbct|dicom|study_|studies|estudio|echo|endoscop|scan|pacs'),
    ('SCALES',r'scale|score|escala|indice|cognitive|quality_of_life'),
    ('FUNCTION',r'functional|funcion|range_of_motion|activity_profile|goal_|gait|balance_profile|rehabilitation|rehabilitacion|activity|movement'),
    ('POPULATION',r'population|herd|flock|colony|cohort|program|community|environment|habitat|taxon|biosecurity|shelter|production|quarantine|risk_form|preventive_calendar'),
    ('RELATIONSHIP',r'relationship|linked_patient|responsable|cuidadores|apoyos|care_team|population_link'),
    ('DEVICE',r'device|implant_record|batch|stock_|trazabilidad|material|dispositivo|equipment'),
    ('QUALITY',r'audit|auditoria|quality|indicador|gestion|plan_operativo|capacidad_servicios'),
    ('CONSENT',r'consent'),
    ('REPORT',r'report|informe|evidence|custodia|pericial|document'),
    ('TRENDS',r'trend|observation_series|measurement|monitorizacion|series|series|medicion|wound_measurement'),
    ('TIMELINE',r'timeline|cronologia|seguimiento|diary|diario|session|sesion|comparison|comparador|event'),
]
WORKFLOW_RULES = [
    ('evaluacion', 'Evaluación inicial y controles', r'assess|evaluation|evaluacion|consult|visit|valoracion|history|historia|examen'),
    ('seguimiento', 'Seguimiento y evolución', r'follow|seguimiento|control|surveillance|surveil|evolucion|monitor|prevent'),
    ('estudios', 'Orden, ejecución e informe de estudios', r'diagnostic|study|test|estudio|image|imagen|radiol|lab|muestra|sample|patholog|patolog|specimen|analisis|prueba'),
    ('procedimientos', 'Procedimientos y cierre de registros', r'procedure|procedimiento|intervention|intervencion|quirurg|surg|operative|operator|anest|recovery|recuperacion|endodon|restaur|implant'),
    ('sesiones', 'Sesiones y objetivos', r'therap|sesion|session|rehab|training|entrenamiento|plan_dental|orthodont|ortodon|protes'),
    ('hospital', 'Episodio hospitalario y turnos', r'inpatient|hospital|critical|intensive|nursing|enfermer|handover|handoff|shift|turno|admission|admis|alta|discharge|dialysis|dialisis|icu'),
    ('urgencias', 'Triaje, atención y destino', r'triage|triaje|emergency|urgencia|resusc'),
    ('reproduccion', 'Reproducción y atención materna', r'fertil|reproduct|gestac|pregnan|antenatal|prenatal|postpartum|lactation|birth|parto'),
    ('derivacion', 'Derivaciones y coordinación', r'referral|referencia|deriv|interconsult|multidisciplin|coordina'),
    ('poblacion', 'Programas y población', r'community|comunit|program|population|poblac|herd|flock|colony|shelter|outbreak|brote'),
    ('informes', 'Revisión y emisión de informes', r'report|informe|review|revision|forensic|pericial|audit|auditor|custody|evidence'),
    ('medicacion', 'Revisión, dispensación y administración', r'medic|pharma|farmac|dispens|drug|adverse|stock|vaccin|vacun'),
    ('dispositivos', 'Dispositivos y trabajos técnicos', r'device|disposit|lab_dental|trabajo|prosthe|aparato|equipment'),
    ('consentimiento', 'Consentimiento y participantes', r'consent|family_interview|multi_participant|interview'),
]

def normalize(value):
    return ''.join(c for c in unicodedata.normalize('NFKD',value.lower()) if not unicodedata.combining(c))

def component_family(value):
    for code, pattern in FAMILY_RULES:
        if re.search(pattern, normalize(value)):
            return code
    return 'FORM'

def workflow_groups(values):
    found = [code for code, label, pattern in WORKFLOW_RULES if any(re.search(pattern,normalize(x)) for x in values)]
    return found or ['evaluacion']

def extra_dependencies(entry):
    corpus = normalize(' '.join(entry['components']+entry['workflows']+[entry['name']]))
    mapping = [
        ('inpatient',r'flowsheet|icu_|critical|intensiv|hospitaliz|inpatient|internamiento|hospital_medicine|bed_|handoff'),
        ('surgery',r'operative_report|surgical|quirurgic|cirugia|perioperat|neurosurg|surgery'),
        ('anesthesia',r'anesthes|anestesi|anesthesia_record'),
        ('nursing',r'nursing|enfermer|shift_handover|handoff'),
        ('rehabilitation',r'rehabilit|therapy_sessions|terapia|functional_scale'),
        ('emergency',r'emergency|triaje|triage|urgencia'),
        ('animal_populations',r'herd_registry|flock_registry|colony_registry|shelter_population|sanidad_de_produccion'),
        ('reproduction',r'theriogen|teriogen|reproductive_timeline|offspring_links|fertil'),
        ('pacs',r'dicom|pacs'),
        ('device_integration',r'device_integration'),
    ]
    return [code for code,pattern in mapping if re.search(pattern,corpus)]

def load_entries():
    entries=[]
    for filename, domain, label in DOMAINS:
        raw=json.loads((BASE/filename).read_text(encoding='utf-8'))
        raw += [x for x in json.loads((BASE/'supplemental_draft.json').read_text(encoding='utf-8')) if x['catalogDomain']==domain]
        for item in raw:
            entry=dict(item)
            entry['catalogDomain']=domain
            entry['catalogDomainLabel']=label
            entry['patientDomain']='ANIMAL' if domain=='VETERINARY' else 'HUMAN'
            entry['implementationStatus']='MAPPED_NOT_IMPLEMENTED'
            entry['clinicalValidationStatus']='PENDING_SPECIALIST_REVIEW'
            entry['professionalRecognitionStatus']='VERIFY_JURISDICTION_AND_CREDENTIAL'
            entry['taxonomyUse']='FUNCTIONAL_PRODUCT_GROUPING'
            entry['componentFamilies']=sorted({component_family(x) for x in entry['components']})
            entry['workflowFamilies']=workflow_groups(entry['workflows'])
            deps=[MODULE_ALIASES.get(x,x) for x in entry['dependencies']]
            entry['rawDependencies']=entry['dependencies']
            entry['dependencies']=sorted(set(deps+extra_dependencies(entry)+['clinical','patients','specialties','documents','audit','identity','organizations']))
            extra_vet={
                'V_INTERNAL_LARGE':['animal_populations'],'V_CARDIO':['imaging'],'V_NEURO':['imaging'],
                'V_GASTRO':['imaging'],'V_RENAL':['imaging'],'V_RESP':['imaging'],'V_ONCO':['imaging'],
                'V_DENTAL':['imaging','surgery','anesthesia'],'V_DENTAL_EQUINE':['imaging','surgery','anesthesia'],
                'V_ORTHO':['surgery','anesthesia','imaging'],'V_NEUROSURG':['surgery','anesthesia','imaging'],
                'V_SURGERY':['surgery','anesthesia'],'V_SURG_SMALL':['surgery','anesthesia'],
                'V_SURG_LARGE':['surgery','anesthesia'],'V_SOFT':['surgery','anesthesia'],
                'V_RAD_ONCO':['imaging','scheduling','radiotherapy','oncology'],
                'V_EPI':['population'],'V_LAB_ANIMALS':['animal_populations'],'V_ZOO':['animal_populations'],
                'V_BEEF':['animal_populations'],'V_DAIRY':['animal_populations','reproduction'],
                'V_FISH':['animal_populations'],'V_FOOD':['animal_populations'],'V_SHELTER':['animal_populations'],
                'V_SWINE':['animal_populations'],'V_POULTRY':['animal_populations'],
            }
            entry['dependencies']=sorted(set(entry['dependencies']+extra_vet.get(entry['code'],[])))
            if entry['code'] in ['V_CRITICAL','V_PAIN']:
                entry['parentCode']=None
                entry['relatedCodes']=['V_EMERGENCY','V_ANESTH'] if entry['code']=='V_CRITICAL' else ['V_ANESTH','V_ONCO']
            if entry['code']=='V_RAD_ONCO':
                entry['parentCode']='V_ONCO'
                entry['relatedCodes']=['V_IMAGING']
            if entry['code'] in ['V_BEEF','V_DAIRY']:
                entry['parentCode']='V_FOOD'
            entry['sourceIds']=list(dict.fromkeys(entry['sourceIds']+['PRODUCT']))
            entries.append(entry)
    codes={x['code'] for x in entries}
    assert len(codes)==len(entries),'Código duplicado'
    for x in entries:
        assert re.fullmatch(r'[HDVA]_[A-Z0-9_]+',x['code']),x['code']
        assert x['entryType'] in ['especialidad','subespecialidad','area_practica','servicio'],x['code']
        assert x['priority'] in ['P1','P2','P3','P4'],x['code']
        assert x['parentCode'] is None or x['parentCode'] in codes,x['code']
        assert all(c in codes for c in x.get('relatedCodes',[])),x['code']
        assert all(x[k] for k in ['name','group','capture','components','workflows','dependencies']),x['code']
        assert all(y in SOURCES for y in x['sourceIds']),(x['code'],x['sourceIds'])
        assert all(y in MODULES for y in x['dependencies']),(x['code'],x['dependencies'])
        if x['patientDomain']=='ANIMAL':
            assert 'HUMAN_DENTAL' not in x['componentFamilies'],x['code']
        chain=set()
        cur=x
        while cur['parentCode']:
            assert cur['parentCode'] not in chain, f'Ciclo: {x["code"]}'
            chain.add(cur['parentCode'])
            cur=next(e for e in entries if e['code']==cur['parentCode'])
    return entries

def md_cell(value):
    return str(value).replace('|','/').replace('\n',' ')

def make_document(entries):
    codes={x['code']:x for x in entries}
    counts=Counter(x['catalogDomain'] for x in entries)
    lines=[
        '# Health Project: mapa de medicina humana y veterinaria', '',
        'Fecha: 13 de octubre de 2026. Versión de catálogo: 1.0.0. Estado: mapeado; no implementado. Complementa [la arquitectura](Arquitectura_Health_Project.md).', '',
        f'Este catálogo contiene **{len(entries)} entradas** entre especialidades, subespecialidades, áreas de práctica y servicios. Mapea medicina humana y veterinaria para diseñar formularios, componentes, datos y flujos de Health Project. Odontología se conserva como bloque de atención humana por el ejemplo inicial del proyecto; no se incluyen catálogos independientes de otras profesiones de salud.', '',
        'La nomenclatura cambia según país y colegio profesional. Esta es una cobertura amplia y extensible del producto, no una afirmación de que exista una lista mundial cerrada ni un registro legal completo. Las fuentes respaldan nombres y áreas; los campos, componentes, dependencias y prioridades son propuestas de diseño que deben revisarse con profesionales.', '',
        '## Cómo interpretar el mapa', '',
        '- `Especialidad` y `Subespecialidad` describen una agrupación de referencia. `Área de práctica` y `Servicio` evitan presentar cada función de una clínica como un título médico.',
        '- `parentCode` expresa composición funcional; no certifica una vía formativa. Un área transversal puede relacionarse con otras además de su padre principal.',
        '- Todas las entradas comparten pacientes, expediente, atención, autoría, permisos, diagnósticos, observaciones, procedimientos, documentos y auditoría. Las tablas siguientes muestran las diferencias.',
        '- Las mediciones conservan valor original, unidad, fecha, método y origen. Las escalas conservan instrumento, versión y población aplicable; los resultados y cálculos requieren validación específica.',
        '- Una orden, un resultado, una prescripción, una administración y un procedimiento realizado son registros distintos.',
        '- Los gráficos guardan significado clínico y localización, no únicamente coordenadas o colores. Los atlas y plantillas se versionan.',
        '- Todos los paquetes comienzan como `MAPPED_NOT_IMPLEMENTED`; figurar en el catálogo no habilita atención real ni acredita al profesional.', '',
        '| Dominio | Entradas |', '| --- | --- |',
    ]
    lines.extend(f'| {label} | {counts[domain]} |' for filename,domain,label in DOMAINS)
    lines += ['', '## Prioridad de construcción propuesta', '',
        '| Código | Uso para planificar |', '| --- | --- |',
        '| P1 | Paquetes iniciales y recorrido común de consulta. No significa que todo P1 entre en una sola demo. |',
        '| P2 | Ampliaciones frecuentes de consulta y sesiones. |',
        '| P3 | Flujos o componentes especializados y diagnóstico. |',
        '| P4 | Operación hospitalaria, poblacional o integraciones complejas. |', '',
        'Las prioridades son orientativas, no rankings de importancia clínica, fechas comprometidas ni requisitos de reconocimiento profesional.', '',
        '## Matriz completa por dominio y grupo', '',
    ]
    for filename,domain,label in DOMAINS:
        lines += [f'### {label}', '']
        groups=defaultdict(list)
        for entry in entries:
            if entry['catalogDomain']==domain: groups[entry['group']].append(entry)
        for group,items in groups.items():
            lines += [f'#### {group}', '', '| Código y área | Tipo y relación | Qué registrar | Componentes específicos | Flujo funcional | Módulos adicionales | Prioridad |', '| --- | --- | --- | --- | --- | --- | --- |']
            for x in items:
                parent=codes[x['parentCode']]['name'] if x['parentCode'] else 'Sin padre principal'
                dep_names=[MODULES[z] for z in x['dependencies'] if z not in ['clinical','patients','identity','organizations','specialties','documents','audit']]
                comp_names=[FAMILIES[z] for z in x['componentFamilies']]
                flow_names=[next(label for code,label,pattern in WORKFLOW_RULES if code==z) for z in x['workflowFamilies']]
                values=[f'`{x["code"]}`: **{x["name"]}**',f'{x["entryType"].replace("_"," ")}; {parent}', '; '.join(x['capture']),'; '.join(comp_names),'; '.join(flow_names),'; '.join(dep_names) or 'Núcleo común',x['priority']]
                lines.append('| '+' | '.join(md_cell(v) for v in values)+' |')
            lines.append('')
    lines += ['## Ejes que se cruzan con la especialidad', '',
        '| Eje | Valores funcionales | Regla |', '| --- | --- | --- |',
        '| Paciente | Humano o animal | Dominios excluyentes; expediente por tenant, compartido entre sucursales autorizadas. Cada atención conserva sucursal de origen. |',
        '| Población humana | Neonatal, infancia, adolescencia, adulta, persona mayor; embarazo cuando aplica | Seleccionar formularios y referencias apropiados, sin duplicar todo el núcleo. |',
        '| Especie veterinaria | Canina, felina, equina, bovina, ovina/caprina, porcina, aves, reptiles, anfibios, peces, mamíferos exóticos, fauna/colecciones y otras | La especie y etapa de vida son datos del paciente; determinan atlas, vocabulario y medidas aplicables. |',
        '| Entorno | Consultorio, domicilio, urgencia, hospital, quirófano, laboratorio, refugio, granja o colección | Activa flujos, recursos y permisos; no cambia por sí solo la custodia del expediente. |',
        '| Sujeto de registro | Paciente, atención, muestra, estudio, dispositivo o población | Un rebaño, cama o muestra no se representa como una persona. |',
        '| Profesional | Médico, odontólogo o veterinario; equipo asistencial con permisos propios cuando el flujo lo requiere | El paquete y el rol son distintos. Habilitar un paquete no concede atribuciones al usuario. |', '',
        'Cardiología veterinaria × especie canina y cardiología veterinaria × especie equina reutilizan un paquete con perfiles distintos. La práctica por especie puede tener además un área propia en el catálogo por su ámbito profesional. Las equivalencias entre nombres locales e internacionales se conservan como alias con origen y relación, sin homologarlas.', '',
        'La odontología humana usa la nomenclatura que corresponda a su catálogo; veterinaria requiere Triadan modificado y atlas por especie/dentición. El catálogo humano no se aplica automáticamente a un animal. [AVDC](https://avdc.org/avdc-nomenclature/).', '',
        '## Componentes reutilizables', '',
        '| Familia | Componente |', '| --- | --- |',
    ]
    used_families={c for x in entries for c in x['componentFamilies']}
    lines += [f'| `{c}` | {label} |' for c,label in FAMILIES.items() if c in used_families]
    lines += ['', 'Estos son componentes funcionales previstos, no widgets existentes. Los identificadores específicos de cada entrada se conservan en el JSON. Una familia permite compartir infraestructura, pero cada renderer y validador puede tener reglas particulares.', '',
        '## Paquete de implementación por especialidad', '',
        'Cada paquete debe contener los siguientes artefactos antes de declararse operativo:', '',
        '1. Formularios y catálogos versionados, con códigos estables de campo.',
        '2. Datos estructurados y mapeo de captura hacia observaciones, diagnósticos, órdenes y procedimientos.',
        '3. Componente visual y atlas cuando corresponda, con alternativa textual accesible.',
        '4. Validadores de backend, cálculo documentado y reglas de ciclo de vida.',
        '5. Contratos REST/SP, permisos y pruebas de aislamiento.',
        '6. Documentos e informes que conserva el expediente.',
        '7. Criterios de aceptación revisados por profesional del área.', '',
        'El ciclo es `MAPPED_NOT_IMPLEMENTED → IN_DESIGN → IMPLEMENTING → SPECIALIST_REVIEW → READY`. Retirar un paquete bloquea nuevas capturas cuando corresponda, pero conserva lectura de versiones históricas.', '',
        '## Incorporación en Spring Boot, SQL Server y Next.js', '',
        '- SQL Server: catálogo global de paquetes más habilitación por tenant/sucursal. El catálogo no guarda datos clínicos compartidos.',
        '- Entidades de configuración: `SpecialtyCatalog`, `SpecialtyRelation`, `SpecialtyAlias`, `SpecialtyPatientProfile`, `SpecialtyComponentRequirement`, `SpecialtyWorkflowRequirement`, `TenantSpecialtyEnablement`, `ProfessionalCredential`, `ProfessionalSpecialtyAssignment` y `TemplateVersion`.',
        '- SP propuestos: `specialties.usp_ImportCatalogBatch` (administración), `usp_ListCatalog`, `usp_GetPackage`, `usp_SetTenantSpecialtyEnablement` y `usp_AssignProfessionalSpecialty` con ámbito/permisos verificados. Importar catálogo no publica plantillas ni habilita permisos automáticamente.',
        '- Spring: catálogo y registro interno de validadores/renderers; dependencias funcionales permanecen en el monolito modular. No crear un microservicio o una tabla de historia completa por cada especialidad.',
        '- Next.js: resolver paquete + versión + perfil de paciente, renderizar campos y componentes disponibles. Si un componente requerido no está implementado, mostrar alcance disponible y bloquear operaciones que dependan de él.',
        '- El JSON adjunto es una especificación inicial para importación controlada; requiere completar esquema físico, SP y validaciones antes de usarlo como dato productivo.', '',
        '## Cobertura y límites pendientes', '',
        'Se incluyen consulta, cirugía, diagnóstico, especialidades pediátricas, psiquiatría, odontología y veterinaria. Los módulos de enfermería, farmacia o rehabilitación aparecen como dependencias cuando el flujo los exige, no como catálogos adicionales de profesiones. Hospitalización, radioterapia, reproducción asistida, PACS/equipos y registros poblacionales requieren sus flujos completos, aunque ya estén mapeados aquí. No basta habilitar una plantilla.', '',
        'No se añade automáticamente una fila por cada técnica, equipo, especie, enfermedad o método terapéutico. Esos elementos se modelan como catálogos y perfiles del paquete. Nuevas áreas y nombres locales pueden incorporarse sin renumerar códigos existentes.', '',
        'La lista no pretende agotar todas las denominaciones mundiales ni sustituir registros profesionales. Las correspondencias de nombres, el alcance local de cada profesión y el contenido clínico se validarán antes de habilitar una especialidad en producción.', '',
        '## Fuentes y procedencia', '',
        'Se consultaron fuentes primarias para las nomenclaturas. La procedencia de cada entrada figura en `sourceIds`; los requisitos funcionales se atribuyen a `PRODUCT`. Las referencias de 2025 se mantienen fechadas y no se presentan como registro vigente de 2026.', '',
    ]
    used_sources={s for x in entries for s in x['sourceIds']}
    for code,source in SOURCES.items():
        if code not in used_sources or not source['url']: continue
        lines.append(f'- `{code}`: [{source["title"]}]({source["url"]}). '+source.get('scope','Nomenclatura referencial internacional; sin homologación automática en Perú.'))
    lines += ['', '`PRODUCT`: diseño de Health Project. Campos, componentes, flujos, dependencias y prioridad requieren revisión funcional; no son una recomendación de diagnóstico ni de tratamiento.', '']
    return '\n'.join(lines)

def main(generate_visual=True):
    entries=load_entries()
    catalog={
        'schemaVersion':'1.0.0','catalogVersion':'1.0.0','createdAt':'2026-10-13',
        'purpose':'FUNCTIONAL_PRODUCT_DESIGN','defaultImplementationStatus':'MAPPED_NOT_IMPLEMENTED',
        'jurisdiction':'PE_REFERENCE_WITH_INTERNATIONAL_TAXONOMY',
        'recognitionDisclaimer':'No es un registro legal exhaustivo ni acredita profesionales. Padres, campos y capacidades son composición funcional.',
        'productDecisions':{'clinicalRecordScope':'TENANT_PATIENT','branchSharing':'AUTHORIZED_AND_AUDITED','crossTenantSharing':'NO_AUTOMATIC_SHARING','initialRelease':'OUTPATIENT_HUMAN_DENTAL_VETERINARY','patientAndResponsiblePortal':True,'fullScope':'ALL_MAPPED_PACKAGES_WITH_REQUIRED_GRAPHICS','hospitalizationStage':'AFTER_OUTPATIENT'},
        'priorities':{'P1':'Inicial y consulta común','P2':'Ampliaciones de consulta','P3':'Flujos especializados','P4':'Operación e integraciones complejas'},
        'modules':[{'code':c,'name':n,'implementationStatus':'PLANNED'} for c,n in MODULES.items()],
        'componentFamilies':[{'code':c,'name':n,'implementationStatus':'PLANNED'} for c,n in FAMILIES.items()],
        'workflowFamilies':[{'code':c,'name':n} for c,n,p in WORKFLOW_RULES],
        'sources':{code:source for code,source in SOURCES.items() if any(code in x['sourceIds'] for x in entries)},'entries':entries,
    }
    target=BASE/'Catalogo_Especialidades_Health_Project.json'
    target.write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    doc=DOCS/'Mapa_Especialidades_Health_Project.md'
    doc.write_text(make_document(entries),encoding='utf-8')
    coverage={
        'createdAt':'2026-10-13','purpose':'DESIGN_AND_DELIVERY_TRACKING',
        'statusExplanation':'Mapeado identifica requisitos. Implementado y validado requieren evidencia; las referencias y la vista exploratoria no constituyen componentes clínicos implementados.',
        'entries':[{'code':e['code'],'name':e['name'],'catalogDomain':e['catalogDomain'],'captureFields':{'status':'MAPPED','evidence':[]},'graphicsAndComponents':{'status':'MAPPED','requirements':e['components'],'evidence':[]},'validationRules':{'status':'TO_SPECIFY','evidence':[]},'operationalWorkflow':{'status':'MAPPED','requirements':e['workflows'],'evidence':[]},'documents':{'status':'TO_SPECIFY','evidence':[]},'permissions':{'status':'TO_SPECIFY','evidence':[]},'integrations':{'status':'TO_ASSESS','evidence':[]},'specialistReview':{'status':'PENDING','reviewer':None,'evidence':[]},'releaseScope':{'status':'TO_ASSIGN_PER_CAPABILITY'},'overallStatus':'MAPPED_NOT_IMPLEMENTED'} for e in entries]
    }
    (BASE/'Control_Cobertura_Health_Project.json').write_text(json.dumps(coverage,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    if not generate_visual:
        print(json.dumps({'entries':len(entries),'document':str(doc),'catalog':str(target),'coverageEntries':len(coverage['entries']),'visualUpdated':False},ensure_ascii=False))
        return
    visual_data={key:catalog[key] for key in ['entries','componentFamilies','workflowFamilies','modules']}
    # La vista solo necesita etiquetas funcionales; el JSON completo conserva contratos y procedencia.
    keep={'code','name','group','catalogDomainLabel','entryType','parentCode','relatedCodes','patientProfiles','capture','componentFamilies','workflowFamilies','dependencies'}
    visual_data['entries']=[{k:v for k,v in x.items() if k in keep} for x in entries]
    data_text=json.dumps(visual_data,ensure_ascii=False,separators=(',',':')).replace('</','<\\/')
    fragment=(BASE/'especialidades-fragment.template.html').read_text(encoding='utf-8').replace('__CATALOG_DATA__',data_text)
    VIS_DIR.mkdir(parents=True,exist_ok=True)
    visual=VIS_DIR/'especialidades-health-project.html'
    visual.write_text(fragment,encoding='utf-8')
    assert visual.stat().st_size<1024*1024
    print(json.dumps({'entries':len(entries),'counts':dict(Counter(x['catalogDomainLabel'] for x in entries)),'types':dict(Counter(x['entryType'] for x in entries)),'modules':len(MODULES),'componentFamilies':len(FAMILIES),'document':str(doc),'catalog':str(target)},ensure_ascii=False))

if __name__=='__main__':
    main(generate_visual='--skip-visual' not in sys.argv)
