# Gráficos de especialidad: flujos e interacción

Estado: requisitos de diseño; los gráficos clínicos todavía no están implementados.

## Contrato común de un gráfico

Entrada: atención, paciente/perfil, especialidad, componente y versión autorizados. Interacción: selección de estructura, captura semántica y revisión junto a tabla. Salida: datos y revisión vinculados a la historia. Firmar sigue F27; corregir una revisión firmada sigue F28.

| Familia | Selección e información | Acción y salida | Flujo |
| --- | --- | --- | --- |
| Odontograma humano/veterinario | Pieza, cara, dentición y nomenclatura apropiadas al perfil | Hallazgo/procedimiento fechado y evolución por pieza; leyenda y tabla | F24 |
| Periodontograma | Pieza/sitio, medida/unidad, fecha y método aplicables | Medidas estructuradas y comparación; atlas y sitios específicos se validan | F72 + F25 |
| Raíces y conductos | Pieza/raíz/conducto, datos y etapa registrada | Registro semántico ligado a atención y actuación; vistas del componente | F72 |
| Ortodoncia/oclusión/cefalometría | Estructuras, relaciones, estudio y puntos/medidas implementados | Mediciones y evolución; no se presume análisis automático | F72 + F25 |
| Prótesis/implantes | Pieza/región, dispositivo/trabajo, etapas e identificadores | Plan y procedimiento separado; trazabilidad de dispositivo/laboratorio | F72 + F42 |
| Mapa anatómico corporal, cardíaco, neurológico u órgano | Región, lado, vista y versión de atlas | Hallazgo/medición/procedimiento vinculado; coordenadas solo visuales | F23 |
| Función/movilidad/rehabilitación | Región, función, medida o instrumento y sesión | Observaciones/objetivos y comparación temporal | F72 + F25 |
| Visual/ocular y audición | Ojo/oído, lateralidad, eje o parámetro del estudio | Datos estructurados y gráfico con escala/tabla apropiada | F72 + F25 |
| Crecimiento/antropometría | Edad/perfil, valores originales y referencia válida | Curva con referencia/versión; explicar indicador no calculable | F25 |
| Tendencias y escalas | Medición/instrumento, unidad, momento y versión | Series, tabla y cálculo validado cuando corresponda | F25 |
| Fotografía y lesión seriada | Región, fecha, consentimiento y procedencia | Comparación enlazada al mismo hallazgo sin alterar originales | F26 + F23 |
| Estudio, señal, audio o video | Identidad, orden, adquisición, documento y capacidad del visor | Visualización e informe; interpretación profesional separada | F26 + F33 |
| Genética y relaciones | Sujetos distintos, vínculo, evidencia y resultado | Representación y documento con acceso específico; sin unión de historiales | F72 + F29 |
| Gestación, reproducción y descendencia | Ciclo, sujetos, fecha y etapas autorizadas | Evolución del ciclo y relaciones separadas | F25 + F59 |
| Hojas hospitalarias/quirúrgicas | Tiempos, paciente, caso, recurso y eventos | Actuaciones reales, excepciones, responsables y evolución | F50 + F53 + F54 |
| Poblaciones y programas | Grupo, periodo, denominador y unidad | Indicadores con contexto; enlace a individuos autorizados | F14 + F60 |

Las familias comparten infraestructura de captura pero no sus reglas clínicas. Cada componente del catálogo requiere una ficha con anatomía/dimensiones, gestos o selección, campos, estados, validaciones, leyenda, comparación, salida documental y casos de aceptación. El mapa siguiente conecta las 241 entradas con las familias ya previstas.

## Relación completa por especialidad

| Código | Área | Componentes funcionales previstos | Flujos base de captura |
| --- | --- | --- | --- |
| H_FAMILY | Medicina familiar y comunitaria | Formularios clínicos versionados; Evolución y seguimiento por eventos; Mediciones y series temporales | F22, F72, F25 |
| H_INTERNAL | Medicina interna | Formularios clínicos versionados; Muestras, resultados y trazabilidad; Mediciones y series temporales | F22, F72, F25 |
| H_GERIATRICS | Geriatría | Formularios clínicos versionados; Escalas e instrumentos versionados; Evolución y seguimiento por eventos | F22, F25, F72 |
| H_ADOLESCENT | Adolescentología | Formularios clínicos versionados; Desarrollo, antropometría y crecimiento | F22, F25 |
| H_PREVENTIVE | Medicina preventiva y salud pública | Poblaciones, programas y ambiente; Evolución y seguimiento por eventos | F22, F72 |
| H_OCCUPATIONAL | Medicina ocupacional y del medio ambiente | Formularios clínicos versionados; Evolución y seguimiento por eventos | F22, F72 |
| H_SPORTS | Medicina del deporte | Mapas anatómicos versionados; Función, movilidad y rehabilitación; Informes y documentos | F22, F23, F72 |
| H_AEROSPACE | Medicina aeroespacial | Formularios clínicos versionados; Evolución y seguimiento por eventos | F22, F72 |
| H_FORENSIC | Medicina legal | Mapas anatómicos versionados; Fotografías y lesiones seriadas; Evolución y seguimiento por eventos | F22, F23, F26, F72 |
| H_GENETICS | Genética médica y genómica clínica | Formularios clínicos versionados; Pedigrí y datos genéticos | F22, F72 |
| H_BIOCHEM_GENETICS | Genética bioquímica médica | Pedigrí y datos genéticos; Evolución y seguimiento por eventos; Mediciones y series temporales | F22, F72, F25 |
| H_LAB_GENETICS | Genética y genómica de laboratorio | Formularios clínicos versionados; Pedigrí y datos genéticos; Muestras, resultados y trazabilidad | F22, F72 |
| H_ADMIN_HEALTH | Administración y gestión en salud | Formularios clínicos versionados; Indicadores y revisión de calidad | F22, F72 |
| H_CARDIOLOGY | Cardiología | Mapas anatómicos versionados; Estudios, imágenes e informes; Señales, audio y videos; Mediciones y series temporales | F22, F23, F26, F25 |
| H_INTERV_CARDIO | Cardiología intervencionista | Mapas anatómicos versionados; Dispositivos, materiales y lotes; Informes y documentos | F22, F23, F72 |
| H_ELECTROPHYS | Electrofisiología cardíaca | Mapas anatómicos versionados; Dispositivos, materiales y lotes; Señales, audio y videos; Evolución y seguimiento por eventos | F22, F23, F72, F26 |
| H_HEART_FAILURE | Insuficiencia cardíaca avanzada y cardiología de trasplante | Función, movilidad y rehabilitación; Estudios, imágenes e informes; Evolución y seguimiento por eventos | F22, F72, F26 |
| H_ADULT_CONGENITAL | Cardiopatías congénitas del adulto | Mapas anatómicos versionados; Estudios, imágenes e informes; Evolución y seguimiento por eventos | F22, F23, F26, F72 |
| H_ENDOCRINOLOGY | Endocrinología, diabetes y metabolismo | Mapas anatómicos versionados; Desarrollo, antropometría y crecimiento; Mediciones y series temporales | F22, F23, F25 |
| H_GASTRO | Gastroenterología | Mapas anatómicos versionados; Estudios, imágenes e informes; Muestras, resultados y trazabilidad | F22, F23, F26, F72 |
| H_HEPATOLOGY | Hepatología y hepatología de trasplante | Mapas anatómicos versionados; Muestras, resultados y trazabilidad; Evolución y seguimiento por eventos | F22, F23, F72 |
| H_ENDOSCOPY | Endoscopia digestiva | Mapas anatómicos versionados; Estudios, imágenes e informes; Informes y documentos | F22, F23, F26, F72 |
| H_NEPHROLOGY | Nefrología | Mapas anatómicos versionados; Hojas de cuidados y monitorización; Mediciones y series temporales | F22, F23, F72, F25 |
| H_DIALYSIS | Unidad de diálisis | Mapas anatómicos versionados; Hojas de cuidados y monitorización | F22, F23, F72 |
| H_RHEUMATOLOGY | Reumatología | Mapas anatómicos versionados; Muestras, resultados y trazabilidad; Escalas e instrumentos versionados | F22, F23, F72, F25 |
| H_PULMONOLOGY | Neumología | Mapas anatómicos versionados; Informes y documentos; Mediciones y series temporales | F22, F23, F72, F25 |
| H_PULMONARY_ONCO | Neumología oncológica | Mapas anatómicos versionados; Informes y documentos; Evolución y seguimiento por eventos | F22, F23, F72 |
| H_HEMATOLOGY | Hematología | Informes y documentos; Mediciones y series temporales | F22, F72, F25 |
| H_ONCOLOGY | Oncología médica (medicina oncológica) | Mapas anatómicos versionados; Formularios clínicos versionados; Evolución y seguimiento por eventos | F22, F23, F72 |
| H_INFECTIOUS | Infectología y enfermedades tropicales | Mapas anatómicos versionados; Muestras, resultados y trazabilidad; Evolución y seguimiento por eventos | F22, F23, F72 |
| H_ALLERGY | Inmunología y alergia | Mapas anatómicos versionados; Formularios clínicos versionados; Evolución y seguimiento por eventos | F22, F23, F72 |
| H_DERMATOLOGY | Dermatología | Mapas anatómicos versionados; Formularios clínicos versionados; Fotografías y lesiones seriadas | F22, F23, F26 |
| H_MICROGRAPHIC_DERM | Cirugía dermatológica micrográfica | Mapas anatómicos versionados; Muestras, resultados y trazabilidad; Informes y documentos | F22, F23, F72 |
| H_SLEEP | Medicina del sueño | Dispositivos, materiales y lotes; Informes y documentos; Evolución y seguimiento por eventos | F22, F72 |
| H_PALLIATIVE | Medicina paliativa | Formularios clínicos versionados; Mediciones y series temporales | F22, F25 |
| H_PAIN | Medicina del dolor | Mapas anatómicos versionados; Escalas e instrumentos versionados; Mediciones y series temporales | F22, F23, F25 |
| H_TOXICOLOGY | Toxicología médica | Mapas anatómicos versionados; Evolución y seguimiento por eventos; Mediciones y series temporales | F22, F23, F72, F25 |
| H_HYPERBARIC | Medicina hiperbárica y subacuática | Formularios clínicos versionados; Fotografías y lesiones seriadas; Evolución y seguimiento por eventos | F22, F26, F72 |
| H_NEUROLOGY | Neurología | Mapas anatómicos versionados; Formularios clínicos versionados; Función, movilidad y rehabilitación; Señales, audio y videos | F22, F23, F72, F26 |
| H_NEUROPHYS | Neurofisiología clínica | Mapas anatómicos versionados; Informes y documentos; Señales, audio y videos | F22, F23, F72, F26 |
| H_EPILEPSY | Epileptología | Señales, audio y videos; Evolución y seguimiento por eventos | F22, F26, F72 |
| H_VASCULAR_NEURO | Neurología vascular | Mapas anatómicos versionados; Escalas e instrumentos versionados; Evolución y seguimiento por eventos | F22, F23, F25, F72 |
| H_NEUROMUSCULAR | Medicina neuromuscular | Mapas anatómicos versionados; Formularios clínicos versionados; Informes y documentos | F22, F23, F72 |
| H_NEURODEVELOPMENT | Discapacidades del neurodesarrollo | Formularios clínicos versionados; Función, movilidad y rehabilitación; Desarrollo, antropometría y crecimiento | F22, F72, F25 |
| H_PSYCHIATRY | Psiquiatría | Formularios clínicos versionados; Mediciones y series temporales | F22, F25 |
| H_CHILD_PSYCHIATRY | Psiquiatría del niño y del adolescente | Formularios clínicos versionados; Desarrollo, antropometría y crecimiento | F22, F25 |
| H_ADDICTION_PSYCHIATRY | Psiquiatría de adicciones | Formularios clínicos versionados; Evolución y seguimiento por eventos; Mediciones y series temporales | F22, F72, F25 |
| H_LIAISON_PSYCHIATRY | Psiquiatría de enlace | Formularios clínicos versionados; Medicaciones y administración | F22, F72 |
| H_FORENSIC_PSYCHIATRY | Psiquiatría forense | Formularios clínicos versionados; Informes y documentos | F22, F72 |
| H_GERIATRIC_PSYCHIATRY | Psiquiatría geriátrica | Formularios clínicos versionados; Escalas e instrumentos versionados | F22, F25 |
| H_ADDICTION_MED | Medicina de adicciones | Formularios clínicos versionados; Muestras, resultados y trazabilidad; Evolución y seguimiento por eventos | F22, F72 |
| H_OBGYN | Ginecología y obstetricia | Mapas anatómicos versionados; Formularios clínicos versionados; Gestación, reproducción y vínculos de descendencia | F22, F23, F72 |
| H_MATERNAL_FETAL | Medicina materno fetal | Mapas anatómicos versionados; Desarrollo, antropometría y crecimiento; Gestación, reproducción y vínculos de descendencia | F22, F23, F25, F72 |
| H_GYNE_ONCO | Ginecología oncológica | Mapas anatómicos versionados; Formularios clínicos versionados | F22, F23 |
| H_REPRODUCTIVE_ENDO | Endocrinología reproductiva e infertilidad | Informes y documentos; Evolución y seguimiento por eventos; Mediciones y series temporales | F22, F72, F25 |
| H_UROGYNE | Uroginecología y cirugía reconstructiva pélvica | Mapas anatómicos versionados; Informes y documentos; Evolución y seguimiento por eventos | F22, F23, F72 |
| H_FAMILY_PLANNING | Planificación familiar compleja | Dispositivos, materiales y lotes; Formularios clínicos versionados; Gestación, reproducción y vínculos de descendencia | F22, F72 |
| H_PED_GYNE | Ginecología de la niña y adolescente | Mapas anatómicos versionados; Formularios clínicos versionados | F22, F23 |
| H_PEDIATRICS | Pediatría | Formularios clínicos versionados; Desarrollo, antropometría y crecimiento | F22, F25 |
| H_NEONATAL | Neonatología | Formularios clínicos versionados; Desarrollo, antropometría y crecimiento; Hojas de cuidados y monitorización | F22, F25, F72 |
| H_PED_CARDIO | Cardiología pediátrica | Mapas anatómicos versionados; Desarrollo, antropometría y crecimiento; Estudios, imágenes e informes | F22, F23, F25, F26 |
| H_PED_ENDO | Endocrinología pediátrica | Formularios clínicos versionados; Desarrollo, antropometría y crecimiento; Mediciones y series temporales | F22, F25 |
| H_PED_GASTRO | Gastroenterología pediátrica | Mapas anatómicos versionados; Desarrollo, antropometría y crecimiento; Estudios, imágenes e informes | F22, F23, F25, F26 |
| H_PED_HEMATOLOGY | Hematología pediátrica | Desarrollo, antropometría y crecimiento; Mediciones y series temporales | F22, F25 |
| H_PED_ONCOLOGY | Oncología pediátrica | Mapas anatómicos versionados; Formularios clínicos versionados; Desarrollo, antropometría y crecimiento | F22, F23, F25 |
| H_PED_INFECTIOUS | Infectología pediátrica | Mapas anatómicos versionados; Formularios clínicos versionados; Muestras, resultados y trazabilidad | F22, F23, F72 |
| H_PED_NEPHRO | Nefrología pediátrica | Mapas anatómicos versionados; Desarrollo, antropometría y crecimiento; Hojas de cuidados y monitorización; Mediciones y series temporales | F22, F23, F25, F72 |
| H_PED_PULMONARY | Neumología pediátrica | Mapas anatómicos versionados; Desarrollo, antropometría y crecimiento; Informes y documentos; Mediciones y series temporales | F22, F23, F25, F72 |
| H_PED_RHEUMATOLOGY | Reumatología pediátrica | Mapas anatómicos versionados; Desarrollo, antropometría y crecimiento; Escalas e instrumentos versionados | F22, F23, F25 |
| H_PED_CRITICAL | Medicina intensiva pediátrica | Dispositivos, materiales y lotes; Formularios clínicos versionados; Hojas de cuidados y monitorización | F22, F72 |
| H_PED_EMERGENCY | Emergencias pediátricas y desastres | Evolución y seguimiento por eventos; Mediciones y series temporales; Triaje y secuencia de urgencia | F22, F72, F25 |
| H_PED_HOSPITAL | Medicina hospitalaria pediátrica | Formularios clínicos versionados; Desarrollo, antropometría y crecimiento; Hojas de cuidados y monitorización | F22, F25, F72 |
| H_PED_DEVELOPMENT | Pediatría del desarrollo y conducta | Formularios clínicos versionados; Función, movilidad y rehabilitación; Desarrollo, antropometría y crecimiento | F22, F72, F25 |
| H_PED_PROTECTION | Pediatría de protección infantil | Mapas anatómicos versionados; Formularios clínicos versionados; Fotografías y lesiones seriadas | F22, F23, F26 |
| H_PED_HEPATOLOGY | Hepatología pediátrica de trasplante | Desarrollo, antropometría y crecimiento; Muestras, resultados y trazabilidad; Evolución y seguimiento por eventos | F22, F25, F72 |
| H_PED_NEUROLOGY | Neurología pediátrica | Mapas anatómicos versionados; Desarrollo, antropometría y crecimiento; Señales, audio y videos | F22, F23, F25, F26 |
| H_PED_DERM | Dermatología pediátrica | Mapas anatómicos versionados; Formularios clínicos versionados; Fotografías y lesiones seriadas | F22, F23, F26 |
| H_PED_REHAB | Medicina de rehabilitación pediátrica | Formularios clínicos versionados; Función, movilidad y rehabilitación; Desarrollo, antropometría y crecimiento | F22, F72, F25 |
| H_PED_ANESTHESIA | Anestesiología pediátrica | Formularios clínicos versionados; Registros quirúrgicos y anestésicos; Mediciones y series temporales | F22, F72, F25 |
| H_PED_RADIOLOGY | Radiología pediátrica | Mapas anatómicos versionados; Estudios, imágenes e informes; Informes y documentos | F22, F23, F26, F72 |
| H_PED_SURGERY | Cirugía pediátrica | Mapas anatómicos versionados; Desarrollo, antropometría y crecimiento; Registros quirúrgicos y anestésicos | F22, F23, F25, F72 |
| H_PED_UROLOGY | Urología pediátrica | Mapas anatómicos versionados; Registros quirúrgicos y anestésicos; Evolución y seguimiento por eventos | F22, F23, F72 |
| H_PED_NEUROSURGERY | Neurocirugía pediátrica | Mapas anatómicos versionados; Dispositivos, materiales y lotes; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| H_PED_OPHTH | Oftalmología pediátrica y estrabismo | Mapas anatómicos versionados; Formularios clínicos versionados; Mediciones y series temporales | F22, F23, F25 |
| H_PED_ENT | Otorrinolaringología pediátrica compleja | Mapas anatómicos versionados; Formularios clínicos versionados; Audición y comunicación | F22, F23, F72 |
| H_PED_CARDIAC_SURG | Cirugía cardiovascular pediátrica y congénita | Mapas anatómicos versionados; Dispositivos, materiales y lotes; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| H_GENERAL_SURGERY | Cirugía general | Mapas anatómicos versionados; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| H_COLORECTAL | Cirugía de colon, recto y ano | Mapas anatómicos versionados; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| H_VASCULAR_SURGERY | Cirugía vascular | Mapas anatómicos versionados; Estudios, imágenes e informes; Fotografías y lesiones seriadas | F22, F23, F26 |
| H_THORACIC_CARDIAC | Cirugía de tórax y cardiovascular | Mapas anatómicos versionados; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| H_THORACIC_ONCO_SURG | Cirugía de tórax oncológica | Mapas anatómicos versionados; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| H_SURG_ONCOLOGY | Cirugía oncológica | Mapas anatómicos versionados; Muestras, resultados y trazabilidad; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| H_SURG_ONCO_ABD | Cirugía oncológica abdominal | Mapas anatómicos versionados; Muestras, resultados y trazabilidad; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| H_SURG_ONCO_HEAD | Cirugía oncológica de cabeza y cuello | Mapas anatómicos versionados; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| H_SURG_ONCO_BREAST | Cirugía oncológica de mamas, tejidos blandos y piel | Mapas anatómicos versionados; Muestras, resultados y trazabilidad | F22, F23, F72 |
| H_HPB_SURGERY | Cirugía hepatopancreatobiliar y trasplante | Mapas anatómicos versionados; Registros quirúrgicos y anestésicos; Evolución y seguimiento por eventos | F22, F23, F72 |
| H_NEUROSURGERY | Neurocirugía | Mapas anatómicos versionados; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| H_ORTHOPEDICS | Ortopedia y traumatología | Mapas anatómicos versionados; Función, movilidad y rehabilitación; Prótesis, implantes y trabajos de laboratorio | F22, F23, F72 |
| H_HAND_SURGERY | Cirugía de mano | Mapas anatómicos versionados; Función, movilidad y rehabilitación | F22, F23, F72 |
| H_ORTHO_SPORTS | Medicina deportiva ortopédica | Mapas anatómicos versionados; Función, movilidad y rehabilitación; Escalas e instrumentos versionados | F22, F23, F72, F25 |
| H_PED_ORTHOPEDICS | Ortopedia pediátrica | Mapas anatómicos versionados; Función, movilidad y rehabilitación; Desarrollo, antropometría y crecimiento | F22, F23, F72, F25 |
| H_PLASTIC_SURGERY | Cirugía plástica y reconstructiva | Mapas anatómicos versionados; Fotografías y lesiones seriadas; Registros quirúrgicos y anestésicos | F22, F23, F26, F72 |
| H_FACIAL_PLASTIC | Cirugía plástica de cabeza y cuello | Mapas anatómicos versionados; Fotografías y lesiones seriadas; Registros quirúrgicos y anestésicos | F22, F23, F26, F72 |
| H_BURNS | Cirugía y atención de quemaduras | Mapas anatómicos versionados; Fotografías y lesiones seriadas | F22, F23, F26 |
| H_HEAD_NECK_MAXILLO | Cirugía de cabeza, cuello y maxilofacial | Mapas anatómicos versionados; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| H_TRAUMA_SURGERY | Cirugía de trauma | Mapas anatómicos versionados; Registros quirúrgicos y anestésicos; Evolución y seguimiento por eventos | F22, F23, F72 |
| H_OPHTHALMOLOGY | Oftalmología | Mapas anatómicos versionados; Formularios clínicos versionados; Mediciones y series temporales | F22, F23, F25 |
| H_RETINA | Cirugía de retina y vítreo | Formularios clínicos versionados; Registro visual y refracción | F22, F72 |
| H_OCULAR_ONCOLOGY | Oftalmología oncológica | Mapas anatómicos versionados; Formularios clínicos versionados; Evolución y seguimiento por eventos | F22, F23, F72 |
| H_CORNEA | Córnea y superficie ocular | Mapas anatómicos versionados; Formularios clínicos versionados; Mediciones y series temporales | F22, F23, F25 |
| H_GLAUCOMA | Glaucoma | Formularios clínicos versionados; Mediciones y series temporales; Registro visual y refracción | F22, F25, F72 |
| H_ENT | Otorrinolaringología | Mapas anatómicos versionados; Audición y comunicación; Estudios, imágenes e informes; Informes y documentos | F22, F23, F72, F26 |
| H_NEUROTOLOGY | Neurotología | Mapas anatómicos versionados; Audición y comunicación; Informes y documentos | F22, F23, F72 |
| H_RHINOLOGY | Rinología y cirugía nasosinusal | Mapas anatómicos versionados; Estudios, imágenes e informes; Registros quirúrgicos y anestésicos | F22, F23, F26, F72 |
| H_LARYNGOLOGY | Laringología y patología de la voz | Mapas anatómicos versionados; Estudios, imágenes e informes; Informes y documentos | F22, F23, F26, F72 |
| H_UROLOGY | Urología | Mapas anatómicos versionados; Informes y documentos; Evolución y seguimiento por eventos | F22, F23, F72 |
| H_URO_ONCOLOGY | Urología oncológica | Mapas anatómicos versionados; Registros quirúrgicos y anestésicos; Evolución y seguimiento por eventos | F22, F23, F72 |
| H_ENDOUROLOGY | Endourología y litiasis | Mapas anatómicos versionados; Dispositivos, materiales y lotes | F22, F23, F72 |
| H_ANESTHESIA | Anestesiología | Formularios clínicos versionados; Registros quirúrgicos y anestésicos; Mediciones y series temporales | F22, F72, F25 |
| H_OBST_ANESTHESIA | Anestesiología obstétrica | Gestación, reproducción y vínculos de descendencia; Registros quirúrgicos y anestésicos; Mediciones y series temporales | F22, F72, F25 |
| H_CARDIAC_ANESTHESIA | Anestesiología cardiovascular | Hojas de cuidados y monitorización; Registros quirúrgicos y anestésicos; Mediciones y series temporales | F22, F72, F25 |
| H_CRITICAL_CARE | Medicina intensiva | Dispositivos, materiales y lotes; Hojas de cuidados y monitorización | F22, F72 |
| H_SURG_CRITICAL | Cuidados intensivos quirúrgicos | Mapas anatómicos versionados; Hojas de cuidados y monitorización; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| H_NEURO_CRITICAL | Cuidados neurocríticos | Formularios clínicos versionados; Señales, audio y videos | F22, F26 |
| H_EMERGENCY | Medicina de emergencias y desastres | Mapas anatómicos versionados; Evolución y seguimiento por eventos; Mediciones y series temporales; Triaje y secuencia de urgencia | F22, F23, F72, F25 |
| H_EMS | Medicina prehospitalaria y servicios de emergencia | Mapas anatómicos versionados; Hojas de cuidados y monitorización | F22, F23, F72 |
| H_RADIOLOGY | Radiología diagnóstica | Mapas anatómicos versionados; Estudios, imágenes e informes; Informes y documentos | F22, F23, F26, F72 |
| H_INTERV_RADIOLOGY | Radiología intervencionista | Mapas anatómicos versionados; Estudios, imágenes e informes; Informes y documentos | F22, F23, F26, F72 |
| H_NEURORADIOLOGY | Neurorradiología | Mapas anatómicos versionados; Estudios, imágenes e informes; Evolución y seguimiento por eventos | F22, F23, F26, F72 |
| H_NUCLEAR_RADIOLOGY | Radiología nuclear | Mapas anatómicos versionados; Formularios clínicos versionados; Estudios, imágenes e informes | F22, F23, F26 |
| H_NUCLEAR_MED | Medicina nuclear | Mapas anatómicos versionados; Formularios clínicos versionados; Función, movilidad y rehabilitación | F22, F23, F72 |
| H_RADIOTHERAPY | Radioterapia y oncología radioterápica | Formularios clínicos versionados | F22 |
| H_ANATOMIC_PATH | Anatomía patológica | Formularios clínicos versionados; Muestras, resultados y trazabilidad | F22, F72 |
| H_CLINICAL_PATH | Patología clínica | Muestras, resultados y trazabilidad; Indicadores y revisión de calidad | F22, F72 |
| H_CYTOPATH | Citopatología | Formularios clínicos versionados; Muestras, resultados y trazabilidad; Informes y documentos | F22, F72 |
| H_DERMATOPATH | Dermatopatología | Mapas anatómicos versionados; Formularios clínicos versionados; Muestras, resultados y trazabilidad | F22, F23, F72 |
| H_HEMATOPATH | Hematopatología | Formularios clínicos versionados; Informes y documentos | F22, F72 |
| H_NEUROPATH | Neuropatología | Mapas anatómicos versionados; Formularios clínicos versionados; Muestras, resultados y trazabilidad | F22, F23, F72 |
| H_ONCO_PATH | Patología oncológica | Muestras, resultados y trazabilidad; Informes y documentos | F22, F72 |
| H_FORENSIC_PATH | Patología forense | Mapas anatómicos versionados; Informes y documentos; Evolución y seguimiento por eventos | F22, F23, F72 |
| H_MICROBIOLOGY | Microbiología médica | Muestras, resultados y trazabilidad | F22, F72 |
| H_CHEMICAL_PATH | Patología química | Formularios clínicos versionados; Muestras, resultados y trazabilidad; Indicadores y revisión de calidad | F22, F72 |
| H_MOLECULAR_PATH | Patología genética molecular | Pedigrí y datos genéticos; Muestras, resultados y trazabilidad; Informes y documentos | F22, F72 |
| H_PED_PATH | Patología pediátrica | Formularios clínicos versionados; Muestras, resultados y trazabilidad | F22, F72 |
| H_TRANSFUSION_MED | Medicina transfusional y banco de sangre | Formularios clínicos versionados; Informes y documentos; Evolución y seguimiento por eventos | F22, F72 |
| H_CLINICAL_INFORMATICS | Informática clínica | Mapas anatómicos versionados; Formularios clínicos versionados; Indicadores y revisión de calidad | F22, F23, F72 |
| H_PHYSICAL_MED | Medicina física y rehabilitación | Mapas anatómicos versionados; Formularios clínicos versionados; Función, movilidad y rehabilitación | F22, F23, F72 |
| H_BRAIN_INJURY | Medicina de lesión cerebral | Formularios clínicos versionados; Función, movilidad y rehabilitación; Escalas e instrumentos versionados | F22, F72, F25 |
| H_SPINAL_INJURY | Medicina de lesión medular | Mapas anatómicos versionados; Formularios clínicos versionados; Función, movilidad y rehabilitación | F22, F23, F72 |
| H_HOSPITAL_MED | Medicina hospitalaria del adulto | Formularios clínicos versionados; Evolución y seguimiento por eventos | F22, F72 |
| H_GENERAL_MEDICINE | Medicina general | Mapas anatómicos versionados; Formularios clínicos versionados; Evolución y seguimiento por eventos; Mediciones y series temporales | F22, F23, F72, F25 |
| H_AESTHETIC_MEDICINE | Medicina estética | Mapas anatómicos versionados; Consentimiento y alcance de acceso; Dispositivos, materiales y lotes; Formularios clínicos versionados; Fotografías y lesiones seriadas | F22, F23, F72, F26 |
| D_ODONTOLOGIA_GENERAL | Odontología general | Odontograma humano por pieza y cara; Ortodoncia, oclusión y cefalometría; Fotografías y lesiones seriadas | F22, F24, F72, F26 |
| D_ANESTESIOLOGIA_DENTAL | Anestesiología dental | Registros quirúrgicos y anestésicos; Mediciones y series temporales | F22, F72, F25 |
| D_SALUD_PUBLICA_DENTAL | Salud pública dental | Formularios clínicos versionados; Poblaciones, programas y ambiente; Indicadores y revisión de calidad | F22, F72 |
| D_ENDODONCIA | Endodoncia | Raíces y conductos dentales; Estudios, imágenes e informes | F22, F72, F26 |
| D_PATOLOGIA_ORAL_MAXILOFACIAL | Patología oral y maxilofacial | Mapas anatómicos versionados; Muestras, resultados y trazabilidad; Fotografías y lesiones seriadas | F22, F23, F72, F26 |
| D_RADIOLOGIA_ORAL_MAXILOFACIAL | Radiología oral y maxilofacial | Formularios clínicos versionados; Estudios, imágenes e informes | F22, F26 |
| D_CIRUGIA_ORAL_MAXILOFACIAL | Cirugía oral y maxilofacial | Mapas anatómicos versionados; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| D_MEDICINA_ORAL | Medicina oral | Mapas anatómicos versionados; Formularios clínicos versionados; Fotografías y lesiones seriadas; Evolución y seguimiento por eventos | F22, F23, F26, F72 |
| D_DOLOR_OROFACIAL | Dolor orofacial | Mapas anatómicos versionados; Formularios clínicos versionados; Ortodoncia, oclusión y cefalometría; Escalas e instrumentos versionados; Evolución y seguimiento por eventos | F22, F23, F72, F25 |
| D_ORTODONCIA_ORTOPEDIA_DENTOFACIAL | Ortodoncia y ortopedia dentofacial | Formularios clínicos versionados; Ortodoncia, oclusión y cefalometría; Fotografías y lesiones seriadas | F22, F72, F26 |
| D_ODONTOPEDIATRIA | Odontopediatría | Formularios clínicos versionados; Desarrollo, antropometría y crecimiento; Odontograma humano por pieza y cara; Responsables y relaciones | F22, F25, F24, F72 |
| D_PERIODONCIA | Periodoncia | Periodontograma y tejidos de soporte | F22, F72 |
| D_PROSTODONCIA | Prostodoncia | Ortodoncia, oclusión y cefalometría; Prótesis, implantes y trabajos de laboratorio | F22, F72 |
| D_IMPLANTOLOGIA | Implantología oral integral | Periodontograma y tejidos de soporte; Prótesis, implantes y trabajos de laboratorio | F22, F72 |
| D_ODONTOLOGIA_RESTAURADORA | Odontología restauradora y estética | Mapas anatómicos versionados; Odontograma humano por pieza y cara; Fotografías y lesiones seriadas | F22, F23, F24, F26 |
| D_ODONTOLOGIA_ESTETICA | Odontología estética | Formularios clínicos versionados; Fotografías y lesiones seriadas; Informes y documentos | F22, F26, F72 |
| D_GERODONTOLOGIA | Odontogeriatría | Formularios clínicos versionados; Función, movilidad y rehabilitación; Prótesis, implantes y trabajos de laboratorio; Responsables y relaciones | F22, F72 |
| D_CUIDADOS_ESPECIALES | Estomatología de pacientes especiales | Formularios clínicos versionados; Audición y comunicación; Responsables y relaciones | F22, F72 |
| D_ODONTOLOGIA_HOSPITALARIA | Odontología hospitalaria | Formularios clínicos versionados; Hojas de cuidados y monitorización | F22, F72 |
| D_ODONTOLOGIA_SUENO | Odontología del sueño | Dispositivos, materiales y lotes; Formularios clínicos versionados; Ortodoncia, oclusión y cefalometría | F22, F72 |
| D_ODONTOLOGIA_FORENSE | Odontología forense | Odontograma humano por pieza y cara; Informes y documentos; Evolución y seguimiento por eventos | F22, F24, F72 |
| D_TRAUMATOLOGIA_DENTOALVEOLAR | Traumatología dentoalveolar | Mapas anatómicos versionados; Raíces y conductos dentales; Ortodoncia, oclusión y cefalometría; Evolución y seguimiento por eventos | F22, F23, F72 |
| D_PREVENCION_HIGIENE_ORAL | Prevención e higiene oral | Formularios clínicos versionados; Escalas e instrumentos versionados | F22, F25 |
| D_LABORATORIO_DENTAL | Laboratorio dental | Formularios clínicos versionados; Prótesis, implantes y trabajos de laboratorio | F22, F72 |
| D_PROTESIS_FIJA | Prótesis fija | Formularios clínicos versionados; Prótesis, implantes y trabajos de laboratorio | F22, F72 |
| D_PROTESIS_REMOVIBLE | Prótesis removible | Ortodoncia, oclusión y cefalometría; Prótesis, implantes y trabajos de laboratorio | F22, F72 |
| D_PROTESIS_MAXILOFACIAL | Prótesis maxilofacial | Mapas anatómicos versionados; Prótesis, implantes y trabajos de laboratorio | F22, F23, F72 |
| D_SALUD_FAMILIAR_COMUNITARIA | Salud familiar y comunitaria en odontología | Mapas anatómicos versionados; Formularios clínicos versionados; Poblaciones, programas y ambiente | F22, F23, F72 |
| D_ADMINISTRACION_GESTION | Administración y gestión en estomatología | Indicadores y revisión de calidad | F22, F72 |
| D_AUDITORIA_ODONTOLOGICA | Auditoría odontológica | Formularios clínicos versionados; Indicadores y revisión de calidad | F22, F72 |
| V_GENERAL | Medicina veterinaria general | Mapas anatómicos versionados; Formularios clínicos versionados; Evolución y seguimiento por eventos | F22, F23, F72 |
| V_PREVENTIVE | Medicina preventiva veterinaria | Poblaciones, programas y ambiente; Evolución y seguimiento por eventos | F22, F72 |
| V_INTERNAL | Medicina interna veterinaria | Mapas anatómicos versionados; Formularios clínicos versionados; Mediciones y series temporales | F22, F23, F25 |
| V_INTERNAL_SMALL | Medicina interna de pequeños animales | Formularios clínicos versionados; Mediciones y series temporales | F22, F25 |
| V_INTERNAL_LARGE | Medicina interna de grandes animales | Formularios clínicos versionados; Poblaciones, programas y ambiente | F22, F72 |
| V_CARDIO | Cardiología veterinaria | Mapas anatómicos versionados; Estudios, imágenes e informes; Señales, audio y videos; Mediciones y series temporales | F22, F23, F26, F25 |
| V_NEURO | Neurología veterinaria | Mapas anatómicos versionados; Formularios clínicos versionados; Evolución y seguimiento por eventos | F22, F23, F72 |
| V_GASTRO | Gastroenterología y hepatología veterinaria | Mapas anatómicos versionados; Estudios, imágenes e informes; Evolución y seguimiento por eventos | F22, F23, F26, F72 |
| V_ENDO | Endocrinología veterinaria | Mapas anatómicos versionados; Evolución y seguimiento por eventos; Mediciones y series temporales | F22, F23, F72, F25 |
| V_RENAL | Nefrología y urología veterinaria | Mapas anatómicos versionados; Hojas de cuidados y monitorización; Mediciones y series temporales | F22, F23, F72, F25 |
| V_RESP | Medicina respiratoria veterinaria | Mapas anatómicos versionados; Estudios, imágenes e informes; Mediciones y series temporales | F22, F23, F26, F25 |
| V_ONCO | Oncología veterinaria | Mapas anatómicos versionados; Fotografías y lesiones seriadas; Evolución y seguimiento por eventos | F22, F23, F26, F72 |
| V_DERM | Dermatología veterinaria | Mapas anatómicos versionados; Fotografías y lesiones seriadas | F22, F23, F26 |
| V_OPHTH | Oftalmología veterinaria | Mapas anatómicos versionados; Fotografías y lesiones seriadas; Registro visual y refracción | F22, F23, F26, F72 |
| V_DENTAL | Odontología y cirugía oral veterinaria | Estudios, imágenes e informes; Periodontograma y tejidos de soporte; Odontograma veterinario por especie | F22, F26, F72, F24 |
| V_DENTAL_EQUINE | Odontología equina | Ortodoncia, oclusión y cefalometría; Odontograma veterinario por especie | F22, F72, F24 |
| V_EMERGENCY | Urgencias veterinarias | Mediciones y series temporales; Triaje y secuencia de urgencia | F22, F25, F72 |
| V_CRITICAL | Cuidados intensivos veterinarios | Dispositivos, materiales y lotes; Hojas de cuidados y monitorización | F22, F72 |
| V_ANESTH | Anestesiología veterinaria | Formularios clínicos versionados; Señales, audio y videos; Registros quirúrgicos y anestésicos | F22, F26, F72 |
| V_PAIN | Evaluación del dolor y cuidados paliativos veterinarios | Escalas e instrumentos versionados; Evolución y seguimiento por eventos | F22, F25, F72 |
| V_SURGERY | Cirugía veterinaria | Mapas anatómicos versionados; Prótesis, implantes y trabajos de laboratorio; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| V_SURG_SMALL | Cirugía de pequeños animales | Mapas anatómicos versionados; Prótesis, implantes y trabajos de laboratorio; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| V_SURG_LARGE | Cirugía de grandes animales | Mapas anatómicos versionados; Formularios clínicos versionados; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| V_ORTHO | Ortopedia y traumatología veterinaria | Mapas anatómicos versionados; Función, movilidad y rehabilitación; Prótesis, implantes y trabajos de laboratorio | F22, F23, F72 |
| V_SOFT | Cirugía de tejidos blandos veterinaria | Mapas anatómicos versionados; Dispositivos, materiales y lotes; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| V_NEUROSURG | Neurocirugía veterinaria | Mapas anatómicos versionados; Formularios clínicos versionados; Registros quirúrgicos y anestésicos | F22, F23, F72 |
| V_REHAB | Medicina deportiva y rehabilitación veterinaria | Función, movilidad y rehabilitación; Escalas e instrumentos versionados | F22, F72, F25 |
| V_BEHAV | Medicina del comportamiento y etología clínica | Poblaciones, programas y ambiente; Señales, audio y videos; Evolución y seguimiento por eventos | F22, F72, F26 |
| V_REPRO | Reproducción y teriogenología veterinaria | Gestación, reproducción y vínculos de descendencia | F22, F72 |
| V_NUTR | Nutrición clínica veterinaria | Mapas anatómicos versionados; Formularios clínicos versionados; Mediciones y series temporales | F22, F23, F25 |
| V_TOXIC | Toxicología veterinaria | Formularios clínicos versionados; Muestras, resultados y trazabilidad; Evolución y seguimiento por eventos | F22, F72 |
| V_PHARMA | Farmacología clínica veterinaria | Formularios clínicos versionados; Medicaciones y administración; Evolución y seguimiento por eventos | F22, F72 |
| V_IMAGING | Diagnóstico por imágenes veterinario | Mapas anatómicos versionados; Estudios, imágenes e informes | F22, F23, F26 |
| V_RAD_ONCO | Oncología radioterápica veterinaria | Mapas anatómicos versionados; Formularios clínicos versionados; Evolución y seguimiento por eventos | F22, F23, F72 |
| V_CLINPATH | Patología clínica veterinaria | Muestras, resultados y trazabilidad | F22, F72 |
| V_ANATPATH | Anatomía patológica veterinaria | Mapas anatómicos versionados; Muestras, resultados y trazabilidad | F22, F23, F72 |
| V_MICRO | Microbiología, inmunología y parasitología veterinarias | Muestras, resultados y trazabilidad | F22, F72 |
| V_EPI | Epidemiología, zoonosis y salud pública veterinaria | Formularios clínicos versionados; Poblaciones, programas y ambiente; Evolución y seguimiento por eventos | F22, F72 |
| V_WELFARE | Bienestar animal | Formularios clínicos versionados; Fotografías y lesiones seriadas; Poblaciones, programas y ambiente | F22, F26, F72 |
| V_FORENSICS | Medicina veterinaria forense | Mapas anatómicos versionados; Informes y documentos | F22, F23, F72 |
| V_LAB_ANIMALS | Medicina de animales de laboratorio | Formularios clínicos versionados; Poblaciones, programas y ambiente | F22, F72 |
| V_ZOO | Medicina zoológica y de fauna silvestre | Poblaciones, programas y ambiente; Evolución y seguimiento por eventos | F22, F72 |
| V_AVIAN | Práctica clínica de aves | Mapas anatómicos versionados; Formularios clínicos versionados; Poblaciones, programas y ambiente | F22, F23, F72 |
| V_BEEF | Práctica de bovinos de carne | Poblaciones, programas y ambiente | F22, F72 |
| V_CANINE_FELINE | Práctica clínica canina y felina | Mapas anatómicos versionados; Formularios clínicos versionados | F22, F23 |
| V_DAIRY | Práctica de bovinos lecheros | Mapas anatómicos versionados; Poblaciones, programas y ambiente; Gestación, reproducción y vínculos de descendencia | F22, F23, F72 |
| V_EQUINE | Práctica clínica equina | Mapas anatómicos versionados; Función, movilidad y rehabilitación | F22, F23, F72 |
| V_EXOTIC_MAMMAL | Práctica de mamíferos exóticos de compañía | Mapas anatómicos versionados; Poblaciones, programas y ambiente | F22, F23, F72 |
| V_FELINE | Práctica clínica felina | Mapas anatómicos versionados; Formularios clínicos versionados; Poblaciones, programas y ambiente | F22, F23, F72 |
| V_FISH | Práctica clínica de peces y salud de poblaciones de peces | Mapas anatómicos versionados; Poblaciones, programas y ambiente | F22, F23, F72 |
| V_FOOD | Práctica de animales de producción alimentaria | Formularios clínicos versionados; Poblaciones, programas y ambiente | F22, F72 |
| V_REPTILE_AMPH | Práctica clínica de reptiles y anfibios | Mapas anatómicos versionados; Poblaciones, programas y ambiente | F22, F23, F72 |
| V_SHELTER | Medicina de refugios y albergues | Formularios clínicos versionados; Poblaciones, programas y ambiente | F22, F72 |
| V_SWINE | Gestión sanitaria porcina | Poblaciones, programas y ambiente | F22, F72 |
| V_POULTRY | Medicina avícola y sanidad de producción | Poblaciones, programas y ambiente | F22, F72 |
| V_BACTERIO_MYC | Bacteriología y micología veterinarias | Estudios, imágenes e informes; Muestras, resultados y trazabilidad | F22, F26, F72 |
| V_VIROLOGY | Virología veterinaria | Estudios, imágenes e informes; Muestras, resultados y trazabilidad | F22, F26, F72 |
| V_IMMUNOLOGY | Inmunología veterinaria | Estudios, imágenes e informes; Muestras, resultados y trazabilidad; Mediciones y series temporales | F22, F26, F72, F25 |
| V_PARASITOLOGY | Parasitología veterinaria | Estudios, imágenes e informes; Muestras, resultados y trazabilidad | F22, F26, F72 |

Los flujos base no sustituyen las actividades especializadas del paquete. Una imagen adjunta no acredita un visor/algoritmo; una plantilla publicada no habilita una capacidad aún pendiente. Las fases avanzadas conservan sus recorridos clínicos correspondientes.
