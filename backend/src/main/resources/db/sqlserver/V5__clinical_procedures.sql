-- SQL Server 2022. Tenant clinical persistence; NEVER grant runtime EXECUTE on private helpers.
-- All audited reads and mutations require the caller Spring transaction; no autonomous commits.
-- ClinicalValidation remains in Spring: these SPs validate JSON/ownership/state, not clinical correctness.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
-- PRIVATE role/session/current membership guard: platform SAD/SOP always denied, even for history.
CREATE PROCEDURE dbo.usp_clinical_scope @roles nvarchar(200),@write bit=0,@module nvarchar(40)=N'CORE'
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF @t IS NULL THROW 51001,'HP_FORBIDDEN:Se requiere una sesion tenant',1; IF @write=1 EXEC dbo.usp_write_guard @t,@module;
END;
GO

-- PRIVATE Access.branch via accepted V3: current tenant active branch; ADM or assigned member. No nested INSERT EXEC callers.
CREATE PROCEDURE dbo.usp_clinical_branch_guard @branch_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @ids TABLE(id char(36),branch_id char(36)); INSERT @ids EXEC dbo.usp_access_branch @branch_id; IF NOT EXISTS(SELECT 1 FROM @ids) THROW 51001,'HP_FORBIDDEN:Sede no disponible para esta membresia',1;
END;
GO

-- PRIVATE V3 sp_professional_guard: locks GLOBAL user identity, then validates current tenant assignment. Shared across every tenant reservation.
CREATE PROCEDURE dbo.usp_clinical_professional_guard @professional_id char(36),@branch_id char(36),@specialty_code varchar(100)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_transaction; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@found char(36); SELECT @found=id FROM dbo.users WITH(UPDLOCK,HOLDLOCK) WHERE id=@professional_id AND active=1; IF @t IS NULL OR @found IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.memberships m JOIN dbo.membership_branches mb ON mb.tenant_id=m.tenant_id AND mb.user_id=m.user_id JOIN dbo.membership_specialties ms ON ms.tenant_id=m.tenant_id AND ms.user_id=m.user_id JOIN dbo.branches b ON b.tenant_id=mb.tenant_id AND b.id=mb.branch_id JOIN dbo.tenant_specialties ts ON ts.tenant_id=ms.tenant_id AND ts.specialty_code=ms.specialty_code JOIN dbo.tenants t ON t.id=m.tenant_id JOIN dbo.users u ON u.id=m.user_id WHERE m.tenant_id=@t AND m.user_id=@professional_id AND m.status='ACTIVE' AND mb.branch_id=@branch_id AND ms.specialty_code=@specialty_code AND b.active=1 AND u.clinical_domain=t.domain AND EXISTS(SELECT 1 FROM OPENJSON(m.roles) WHERE value COLLATE Latin1_General_100_BIN2='PRO')) THROW 51001,'HP_FORBIDDEN:Profesional sin asignacion activa de sede y especialidad',1;
END;
GO

-- PRIVATE PortalService.portal/link: current host membership + module and optional active link scope, held until audited read completes.
CREATE PROCEDURE dbo.usp_portal_scope @patient_id char(36)=NULL,@link_scope nvarchar(80)=NULL,@finance bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_clinical_scope N'PAC,RES'; EXEC dbo.usp_require_transaction; IF @link_scope IS NOT NULL AND @patient_id IS NULL THROW 51000,'HP_INVALID:Paciente de portal requerido',1; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')); IF NOT EXISTS(SELECT 1 FROM dbo.subscriptions s JOIN dbo.plan_versions v ON v.plan_id=s.plan_id AND v.version=s.plan_version CROSS APPLY OPENJSON(v.modules) j WHERE s.tenant_id=@t AND j.value COLLATE Latin1_General_100_BIN2='PORTAL') THROW 51001,'HP_FORBIDDEN:Portal no incluido',1; IF @finance=1 AND NOT EXISTS(SELECT 1 FROM dbo.subscriptions s JOIN dbo.plan_versions v ON v.plan_id=s.plan_id AND v.version=s.plan_version CROSS APPLY OPENJSON(v.modules) j WHERE s.tenant_id=@t AND j.value COLLATE Latin1_General_100_BIN2='FINANCE') THROW 51001,'HP_FORBIDDEN:Finanzas no incluidas',1; IF @patient_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.patient_links l WITH(HOLDLOCK) WHERE l.tenant_id=@t AND l.user_id=@u AND l.patient_id=@patient_id AND l.active=1 AND EXISTS(SELECT 1 FROM OPENJSON(l.scopes) WHERE value COLLATE Latin1_General_100_BIN2=@link_scope COLLATE Latin1_General_100_BIN2)) THROW 51002,'HP_NOT_FOUND:Vinculo de portal no disponible',1;
END;
GO

-- PatientService.list: limit1..200, nonnegative offset; complete patient projection, own tenant only.
CREATE PROCEDURE dbo.usp_patients_list @query nvarchar(max)=N'',@limit int=100,@offset int=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_clinical_scope N'ADM,REC,PRO,ASI,AUD'; IF DATALENGTH(@query)>7996 THROW 51000,'HP_INVALID:Consulta demasiado extensa',1; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); SET @limit=CASE WHEN @limit IS NULL THEN 100 WHEN @limit<1 THEN 1 WHEN @limit>200 THEN 200 ELSE @limit END; SET @offset=CASE WHEN @offset IS NULL OR @offset<0 THEN 0 ELSE @offset END; SELECT id,tenant_id,name,domain,identifier,birth_date,species,contact,allergies,revision,created_at FROM dbo.patients WHERE tenant_id=@t AND (name LIKE N'%'+COALESCE(@query,N'')+N'%' OR identifier LIKE N'%'+COALESCE(@query,N'')+N'%') ORDER BY name,id OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY;
END;
GO

-- PatientService.get/save result + patient existence lookup: same tenant, no branch filter.
CREATE PROCEDURE dbo.usp_patient_get @patient_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_clinical_scope N'ADM,REC,PRO,ASI,AUD'; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF NOT EXISTS(SELECT 1 FROM dbo.patients WHERE tenant_id=@t AND id=@patient_id) THROW 51002,'HP_NOT_FOUND:Paciente inexistente',1; SELECT id,tenant_id,name,domain,identifier,birth_date,species,contact,allergies,revision,created_at FROM dbo.patients WHERE tenant_id=@t AND id=@patient_id;
END;
GO

-- PatientService.history: four resultsets encounters/entries/documents/limits+patient_id; longitudinal ALL branches of same tenant, never cross-tenant.
CREATE PROCEDURE dbo.usp_patient_history @patient_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_clinical_scope N'PRO,ASI,AUD'; EXEC dbo.usp_require_transaction; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF NOT EXISTS(SELECT 1 FROM dbo.patients WHERE tenant_id=@t AND id=@patient_id) THROW 51002,'HP_NOT_FOUND:Paciente inexistente',1; EXEC dbo.usp_audit_event @t,N'PATIENT_HISTORY_READ',@patient_id; SELECT TOP(200) id,tenant_id,patient_id,branch_id,professional_id,specialty_code,status,note,revision,profile_snapshot,created_at,finalized_at,active_patient FROM dbo.encounters WHERE tenant_id=@t AND patient_id=@patient_id ORDER BY created_at DESC,id; SELECT TOP(1000) c.id,c.tenant_id,c.encounter_id,c.kind,c.payload,c.profile_snapshot,c.actor_id,c.created_at FROM dbo.clinical_entries c JOIN dbo.encounters e ON e.tenant_id=c.tenant_id AND e.id=c.encounter_id WHERE c.tenant_id=@t AND e.patient_id=@patient_id ORDER BY c.created_at DESC,c.id; SELECT TOP(200) id,tenant_id,patient_id,encounter_id,title,type,content,status,revision,original_id,signer_id,signed_at,content_hash,published,withdrawn,created_at FROM dbo.documents WHERE tenant_id=@t AND patient_id=@patient_id ORDER BY created_at DESC,id; SELECT @patient_id patient_id,CAST(200 AS int) encounters_limit,CAST(1000 AS int) entries_limit,CAST(200 AS int) documents_limit;
END;
GO

-- ClinicalService.get/start/note: 2 resultsets encounter + entries, same-tenant longitudinal read without assignment narrowing.
CREATE PROCEDURE dbo.usp_encounter_get @encounter_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_clinical_scope N'PRO,ASI,AUD'; EXEC dbo.usp_require_transaction; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF NOT EXISTS(SELECT 1 FROM dbo.encounters WHERE tenant_id=@t AND id=@encounter_id) THROW 51002,'HP_NOT_FOUND:Atencion inexistente',1; EXEC dbo.usp_audit_event @t,N'ENCOUNTER_READ',@encounter_id; SELECT id,tenant_id,patient_id,branch_id,professional_id,specialty_code,status,note,revision,profile_snapshot,created_at,finalized_at,active_patient FROM dbo.encounters WHERE tenant_id=@t AND id=@encounter_id; SELECT id,tenant_id,encounter_id,kind,payload,profile_snapshot,actor_id,created_at FROM dbo.clinical_entries WHERE tenant_id=@t AND encounter_id=@encounter_id ORDER BY created_at,id;
END;
GO

-- DocumentService.list: same tenant across branches, audited internally, 200 complete documents.
CREATE PROCEDURE dbo.usp_documents_list @patient_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_clinical_scope N'PRO,ASI,AUD'; EXEC dbo.usp_require_transaction; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF NOT EXISTS(SELECT 1 FROM dbo.patients WHERE tenant_id=@t AND id=@patient_id) THROW 51002,'HP_NOT_FOUND:Paciente inexistente',1; EXEC dbo.usp_audit_event @t,N'DOCUMENT_LIST_READ',@patient_id; SELECT TOP(200) id,tenant_id,patient_id,encounter_id,title,type,content,status,revision,original_id,signer_id,signed_at,content_hash,published,withdrawn,created_at FROM dbo.documents WHERE tenant_id=@t AND patient_id=@patient_id ORDER BY created_at DESC,id;
END;
GO

-- DocumentService.get/create/change result: full document, internal audit, no body in audit metadata.
CREATE PROCEDURE dbo.usp_document_get @document_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_clinical_scope N'PRO,ASI,AUD'; EXEC dbo.usp_require_transaction; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF NOT EXISTS(SELECT 1 FROM dbo.documents WHERE tenant_id=@t AND id=@document_id) THROW 51002,'HP_NOT_FOUND:Documento inexistente',1; EXEC dbo.usp_audit_event @t,N'DOCUMENT_READ',@document_id; SELECT id,tenant_id,patient_id,encounter_id,title,type,content,status,revision,original_id,signer_id,signed_at,content_hash,published,withdrawn,created_at FROM dbo.documents WHERE tenant_id=@t AND id=@document_id;
END;
GO
-- PRIVATE strict DTO JSON shape with explicitly nullable properties; no SQL text dispatcher.
CREATE PROCEDURE dbo.usp_clinical_json_object @input nvarchar(max),@contract nvarchar(max),@nullable nvarchar(max)=N'[]'
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @input IS NULL OR ISJSON(@input,OBJECT)<>1 THROW 51000,'HP_INVALID:Objeto JSON requerido',1; IF EXISTS(SELECT [key] FROM OPENJSON(@input) GROUP BY [key] HAVING COUNT(*)>1) OR EXISTS(SELECT 1 FROM OPENJSON(@input) i LEFT JOIN OPENJSON(@contract) c ON c.[key]=i.[key] WHERE c.[key] IS NULL OR (i.type<>TRY_CONVERT(int,c.value) AND NOT(i.type=0 AND EXISTS(SELECT 1 FROM OPENJSON(@nullable) n WHERE n.value COLLATE Latin1_General_100_BIN2=i.[key])))) OR EXISTS(SELECT 1 FROM OPENJSON(@contract) c WHERE NOT EXISTS(SELECT 1 FROM OPENJSON(@input) i WHERE i.[key]=c.[key])) THROW 51000,'HP_INVALID:Campos JSON ausentes, repetidos o de tipo incorrecto',1;
END;
GO

-- PatientService.save / MySQL V3 sp_patient_save: create expected0/update expected>=1, domain fixed by tenant. RS full patient; Spring retains Checks.json depth validation.
CREATE PROCEDURE dbo.usp_patient_save @patient_id char(36),@input nvarchar(max),@expected_revision int=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_clinical_scope N'ADM,REC,PRO',@write=1; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@domain nvarchar(6),@name nvarchar(max),@d nvarchar(max),@identifier nvarchar(max),@birth nvarchar(max),@species nvarchar(max),@contact nvarchar(max),@allergies nvarchar(max),@date date,@rev int;
 EXEC dbo.usp_clinical_json_object @input,N'{"name":1,"domain":1,"identifier":1,"birthDate":1,"species":1,"contact":5,"allergies":4}',N'["birthDate","species"]';
 SELECT @name=name,@d=domain,@identifier=identifier,@birth=birthDate,@species=species,@contact=contact,@allergies=allergies FROM OPENJSON(@input) WITH(name nvarchar(max),domain nvarchar(max),identifier nvarchar(max),birthDate nvarchar(max),species nvarchar(max),contact nvarchar(max) AS JSON,allergies nvarchar(max) AS JSON);
 SELECT @domain=domain FROM dbo.tenants WHERE id=@t; SET @date=TRY_CONVERT(date,@birth,23);
 IF @patient_id IS NULL OR @expected_revision IS NULL OR @expected_revision<0 OR NULLIF(LTRIM(RTRIM(@name)),N'') IS NULL OR DATALENGTH(@name)>320 OR NULLIF(LTRIM(RTRIM(@identifier)),N'') IS NULL OR DATALENGTH(@identifier)>200 OR @d COLLATE Latin1_General_100_BIN2<>@domain COLLATE Latin1_General_100_BIN2 OR DATALENGTH(@d)<>2*LEN(@d) OR DATALENGTH(@species)>160 OR (@domain='ANIMAL' AND NULLIF(LTRIM(RTRIM(@species)),N'') IS NULL) OR (@birth IS NOT NULL AND (@date IS NULL OR DATALENGTH(@birth)<>20 OR CONVERT(nvarchar(10),@date,23)<>@birth OR @date>CONVERT(date,SYSUTCDATETIME()))) OR DATALENGTH(@contact)>400000 THROW 51000,'HP_INVALID:Datos de paciente invalidos',1;
 IF EXISTS(SELECT 1 FROM OPENJSON(@allergies) WHERE type<>1 OR DATALENGTH(value)>320) OR EXISTS(SELECT value COLLATE Latin1_General_100_BIN2 FROM OPENJSON(@allergies) GROUP BY value COLLATE Latin1_General_100_BIN2 HAVING COUNT(*)>1) THROW 51000,'HP_INVALID:Lista de alergias invalida',1;
 SELECT @rev=revision FROM dbo.patients WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@patient_id;
 IF @expected_revision=0 AND EXISTS(SELECT 1 FROM dbo.patients WHERE id=@patient_id) THROW 51003,'HP_CONFLICT:Paciente existente',1; IF @expected_revision>0 AND @rev IS NULL THROW 51002,'HP_NOT_FOUND:Paciente inexistente',1; IF @expected_revision>0 AND @rev<>@expected_revision THROW 51003,'HP_CONFLICT:Revision del paciente desactualizada',1;
 IF EXISTS(SELECT 1 FROM dbo.patients WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND identifier=@identifier AND id<>@patient_id) THROW 51003,'HP_CONFLICT:Identificador de paciente utilizado',1;
 IF @expected_revision=0 INSERT dbo.patients(id,tenant_id,name,domain,identifier,birth_date,species,contact,allergies) VALUES(@patient_id,@t,@name,@domain,@identifier,@date,@species,@contact,@allergies); ELSE UPDATE dbo.patients SET name=@name,identifier=@identifier,birth_date=@date,species=@species,contact=@contact,allergies=@allergies,revision=revision+1 WHERE tenant_id=@t AND id=@patient_id AND revision=@expected_revision;
 DECLARE @next int=@expected_revision+1,@meta nvarchar(max); SET @meta=(SELECT @next revision FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event @t,N'PATIENT_SAVED',@patient_id,@meta; EXEC dbo.usp_patient_get @patient_id;
END;
GO

-- PatientService.link / V3 sp_patient_link: own tenant active PAC/RES membership, valid scopes, grant/revoke audit, RS saved link; no expectedRevision in current Link DTO.
CREATE PROCEDURE dbo.usp_patient_link_save @patient_id char(36),@input nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_clinical_scope N'ADM,REC',@write=1,@module=N'PORTAL'; EXEC dbo.usp_org_json_object @input,N'{"userId":1,"relationship":1,"active":3,"scopes":4}'; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u nvarchar(max),@relationship nvarchar(max),@active bit,@scopes nvarchar(max); SELECT @u=userId,@relationship=relationship,@active=CASE WHEN active='true' THEN 1 ELSE 0 END,@scopes=scopes FROM OPENJSON(@input) WITH(userId nvarchar(max),relationship nvarchar(max),active nvarchar(max),scopes nvarchar(max) AS JSON); IF DATALENGTH(@u)<>72 OR TRY_CONVERT(uniqueidentifier,@u) IS NULL OR NULLIF(LTRIM(RTRIM(@relationship)),N'') IS NULL OR DATALENGTH(@relationship)>160 THROW 51000,'HP_INVALID:Datos de vinculo invalidos',1; EXEC dbo.usp_org_json_strings @scopes,20,N'["APPOINTMENTS","DOCUMENTS","BILLING"]'; IF NOT EXISTS(SELECT 1 FROM dbo.patients WHERE tenant_id=@t AND id=@patient_id) OR NOT EXISTS(SELECT 1 FROM dbo.memberships m JOIN dbo.users u ON u.id=m.user_id WHERE m.tenant_id=@t AND m.user_id=@u AND (@active=0 OR (m.status='ACTIVE' AND u.active=1)) AND u.platform_role IS NULL AND EXISTS(SELECT 1 FROM OPENJSON(m.roles) WHERE value IN ('PAC','RES'))) THROW 51002,'HP_NOT_FOUND:Paciente o cuenta de portal no disponible',1; IF EXISTS(SELECT 1 FROM dbo.patient_links WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND patient_id=@patient_id AND user_id=@u) UPDATE dbo.patient_links SET relationship=@relationship,active=@active,scopes=@scopes WHERE tenant_id=@t AND patient_id=@patient_id AND user_id=@u; ELSE INSERT dbo.patient_links(tenant_id,patient_id,user_id,relationship,active,scopes) VALUES(@t,@patient_id,@u,@relationship,@active,@scopes); DECLARE @meta nvarchar(max)=(SELECT @u userId,@active active FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event @t,N'PORTAL_LINK_CHANGED',@patient_id,@meta; SELECT tenant_id,patient_id,user_id,relationship,active,scopes FROM dbo.patient_links WHERE tenant_id=@t AND patient_id=@patient_id AND user_id=@u;
END;
GO
-- SchedulingService.list: fixed UTC window, optional authorized branch, tenant-wide when omitted, limit200.
CREATE PROCEDURE dbo.usp_appointments_list @from datetime2(6),@to datetime2(6),@branch_id char(36)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_clinical_scope N'REC,PRO,ASI,AUD'; IF @from IS NULL OR @to IS NULL OR @to<=@from OR DATEDIFF_BIG(microsecond,@from,@to)/86400000000>93 THROW 51000,'HP_INVALID:Consulta como maximo 93 dias UTC',1; IF @branch_id IS NOT NULL EXEC dbo.usp_clinical_branch_guard @branch_id; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); SELECT TOP(200) id,tenant_id,patient_id,branch_id,professional_id,specialty_code,starts_at,ends_at,status,service,note,revision,request_key,request_hash FROM dbo.appointments WHERE tenant_id=@t AND starts_at>=@from AND starts_at<@to AND (@branch_id IS NULL OR branch_id=@branch_id) ORDER BY starts_at,id;
END;
GO

-- SchedulingService.get/row: current tenant, existing read policy does not add a branch assignment filter.
CREATE PROCEDURE dbo.usp_appointment_get @appointment_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_clinical_scope N'REC,PRO,ASI,AUD'; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF NOT EXISTS(SELECT 1 FROM dbo.appointments WHERE tenant_id=@t AND id=@appointment_id) THROW 51002,'HP_NOT_FOUND:Cita inexistente',1; SELECT id,tenant_id,patient_id,branch_id,professional_id,specialty_code,starts_at,ends_at,status,service,note,revision,request_key,request_hash FROM dbo.appointments WHERE tenant_id=@t AND id=@appointment_id;
END;
GO

-- SchedulingService.reserve (staff/portal) / V3: server SHA256 of exact Requests.Reserve serialization, same key+hash returns prior row. UTC body format yyyy-MM-dd HH:mm:ss.ffffff; global PRO lock, no foreign-tenant schedule details returned.
CREATE PROCEDURE dbo.usp_appointment_reserve @appointment_id char(36),@input nvarchar(max),@request_key nvarchar(max),@request_hash char(64),@portal bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @portal IS NULL THROW 51000,'HP_INVALID:Origen de reserva requerido',1; IF @portal=1 EXEC dbo.usp_clinical_scope N'PAC,RES',@write=1; ELSE EXEC dbo.usp_clinical_scope N'REC,PRO',@write=1;
 EXEC dbo.usp_org_json_object @input,N'{"patientId":1,"branchId":1,"professionalId":1,"specialtyCode":1,"startsAt":1,"endsAt":1,"status":1,"service":1,"note":1}';
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@patient nvarchar(max),@branch nvarchar(max),@pro nvarchar(max),@spec nvarchar(max),@ss nvarchar(max),@es nvarchar(max),@status nvarchar(max),@service nvarchar(max),@note nvarchar(max),@start datetime2(6),@end datetime2(6),@existing char(36),@hash char(64),@b char(36),@u char(36),@code varchar(100);
 SELECT @patient=patientId,@branch=branchId,@pro=professionalId,@spec=specialtyCode,@ss=startsAt,@es=endsAt,@status=status,@service=service,@note=note FROM OPENJSON(@input) WITH(patientId nvarchar(max),branchId nvarchar(max),professionalId nvarchar(max),specialtyCode nvarchar(max),startsAt nvarchar(max),endsAt nvarchar(max),status nvarchar(max),service nvarchar(max),note nvarchar(max));
 SET @start=TRY_CONVERT(datetime2(6),@ss,121); SET @end=TRY_CONVERT(datetime2(6),@es,121);
 IF @appointment_id IS NULL OR @request_key IS NULL OR LEN(@request_key) NOT BETWEEN 8 AND 100 OR DATALENGTH(@request_key)<>2*LEN(@request_key) OR @request_key COLLATE Latin1_General_100_BIN2 LIKE N'%[^-A-Za-z0-9_.:]%' OR @request_hash IS NULL OR LEN(@request_hash)<>64 OR @request_hash COLLATE Latin1_General_100_BIN2 LIKE '%[^0-9a-f]%' OR DATALENGTH(@patient)<>72 OR TRY_CONVERT(uniqueidentifier,@patient) IS NULL OR DATALENGTH(@branch)<>72 OR TRY_CONVERT(uniqueidentifier,@branch) IS NULL OR DATALENGTH(@pro)<>72 OR TRY_CONVERT(uniqueidentifier,@pro) IS NULL OR NULLIF(@spec,N'') IS NULL OR DATALENGTH(@spec)>200 OR @spec COLLATE Latin1_General_100_BIN2 LIKE N'%[^-A-Za-z0-9_:]%' OR DATALENGTH(@status)<>2*LEN(@status) OR @status COLLATE Latin1_General_100_BIN2 NOT IN ('REQUESTED','RESERVED') OR NULLIF(LTRIM(RTRIM(@service)),N'') IS NULL OR DATALENGTH(@service)>320 OR DATALENGTH(@note)>2000 OR @start IS NULL OR @end IS NULL OR DATALENGTH(@ss)<>52 OR DATALENGTH(@es)<>52 OR CONVERT(nvarchar(26),@start,121)<>@ss OR CONVERT(nvarchar(26),@end,121)<>@es OR @end<=@start OR DATEDIFF_BIG(microsecond,@start,@end)/60000000<5 OR DATEDIFF_BIG(microsecond,@start,@end)/60000000>480 THROW 51000,'HP_INVALID:Datos u horario de cita invalidos',1;
 SET @b=CONVERT(char(36),@branch); SET @u=CONVERT(char(36),@pro); SET @code=CONVERT(varchar(100),@spec);
 IF @portal=1 BEGIN IF @status<>'REQUESTED' THROW 51000,'HP_INVALID:El portal solo solicita citas',1; DECLARE @p char(36)=CONVERT(char(36),@patient); EXEC dbo.usp_portal_scope @p,N'APPOINTMENTS'; END ELSE EXEC dbo.usp_clinical_branch_guard @b;
 -- Serialize by tenant request key before returning any prior result. No repeat audit on replay.
 SELECT @existing=id,@hash=request_hash FROM dbo.appointments WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND request_key=@request_key;
 IF @existing IS NOT NULL BEGIN IF @hash<>@request_hash THROW 51003,'HP_CONFLICT:Clave de idempotencia utilizada con otros datos',1; SELECT id,tenant_id,patient_id,branch_id,professional_id,specialty_code,starts_at,ends_at,status,service,note,revision,request_key,request_hash FROM dbo.appointments WHERE tenant_id=@t AND id=@existing; RETURN; END;
 IF @start<DATEADD(second,-60,SYSUTCDATETIME()) THROW 51000,'HP_INVALID:Selecciona un horario futuro',1;
 EXEC dbo.usp_clinical_professional_guard @u,@b,@code;
 IF NOT EXISTS(SELECT 1 FROM dbo.patients WHERE tenant_id=@t AND id=@patient) THROW 51002,'HP_NOT_FOUND:Paciente inexistente',1;
 IF EXISTS(SELECT 1 FROM dbo.appointments WHERE professional_id=@u AND status NOT IN ('CANCELLED','WITHDRAWN') AND starts_at<@end AND ends_at>@start) THROW 51003,'HP_CONFLICT:Profesional ocupado en ese horario',1;
 INSERT dbo.appointments(id,tenant_id,patient_id,branch_id,professional_id,specialty_code,starts_at,ends_at,status,service,note,request_key,request_hash) VALUES(@appointment_id,@t,@patient,@b,@u,@code,@start,@end,@status,@service,@note,@request_key,@request_hash);
 EXEC dbo.usp_audit_event @t,N'APPOINTMENT_RESERVED',@appointment_id; SELECT id,tenant_id,patient_id,branch_id,professional_id,specialty_code,starts_at,ends_at,status,service,note,revision,request_key,request_hash FROM dbo.appointments WHERE tenant_id=@t AND id=@appointment_id;
END;
GO

-- SchedulingService.change + AppointmentStates / V3: state machine and expectedRevision, branch assignment, optional atomic reschedule. No SELECT Java needed after write.
CREATE PROCEDURE dbo.usp_appointment_change @appointment_id char(36),@expected_revision int,@status nvarchar(max),@starts_at datetime2(6)=NULL,@ends_at datetime2(6)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_clinical_scope N'REC,PRO',@write=1;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@pro char(36),@branch char(36),@spec varchar(100),@rev int,@old nvarchar(9),@locked char(36);
 SELECT @pro=professional_id FROM dbo.appointments WHERE tenant_id=@t AND id=@appointment_id; IF @pro IS NULL THROW 51002,'HP_NOT_FOUND:Cita inexistente',1;
 -- Same GLOBAL user lock order as reserve; take row write lock only after professional identity.
 SELECT @locked=id FROM dbo.users WITH(UPDLOCK,HOLDLOCK) WHERE id=@pro;
 SELECT @branch=branch_id,@spec=specialty_code,@rev=revision,@old=status FROM dbo.appointments WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@appointment_id;
 EXEC dbo.usp_clinical_branch_guard @branch;
 IF @expected_revision IS NULL OR @expected_revision<1 OR @status IS NULL OR DATALENGTH(@status)<>2*LEN(@status) OR @status COLLATE Latin1_General_100_BIN2 NOT IN ('RESERVED','CONFIRMED','WAITING','CALLED','IN_CARE','COMPLETED','CANCELLED','WITHDRAWN') THROW 51000,'HP_INVALID:Revision o estado invalido',1;
 IF @rev<>@expected_revision THROW 51003,'HP_CONFLICT:La cita cambio; actualiza la vista',1;
 IF NOT ((@old='REQUESTED' AND @status IN ('RESERVED','CANCELLED')) OR (@old='RESERVED' AND @status IN ('RESERVED','CONFIRMED','CANCELLED')) OR (@old='CONFIRMED' AND @status IN ('RESERVED','WAITING','CANCELLED')) OR (@old='WAITING' AND @status IN ('CALLED','WITHDRAWN')) OR (@old='CALLED' AND @status IN ('IN_CARE','WAITING','WITHDRAWN')) OR (@old='IN_CARE' AND @status='COMPLETED')) THROW 51003,'HP_CONFLICT:Transicion de cita no permitida',1;
 IF @starts_at IS NOT NULL OR @ends_at IS NOT NULL BEGIN IF @starts_at IS NULL OR @ends_at IS NULL OR @ends_at<=@starts_at OR DATEDIFF_BIG(microsecond,@starts_at,@ends_at)/60000000<5 OR DATEDIFF_BIG(microsecond,@starts_at,@ends_at)/60000000>480 OR @starts_at<SYSUTCDATETIME() OR @status<>'RESERVED' THROW 51000,'HP_INVALID:Reprograma reserva a horario futuro valido',1; EXEC dbo.usp_clinical_professional_guard @pro,@branch,@spec; IF EXISTS(SELECT 1 FROM dbo.appointments WHERE id<>@appointment_id AND professional_id=@pro AND status NOT IN ('CANCELLED','WITHDRAWN') AND starts_at<@ends_at AND ends_at>@starts_at) THROW 51003,'HP_CONFLICT:El nuevo horario esta ocupado',1; END;
 UPDATE dbo.appointments SET starts_at=COALESCE(@starts_at,starts_at),ends_at=COALESCE(@ends_at,ends_at),status=@status,revision=revision+1 WHERE tenant_id=@t AND id=@appointment_id AND revision=@expected_revision;
 DECLARE @next int=@rev+1,@meta nvarchar(max); SET @meta=(SELECT @status status,@next revision FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event @t,N'APPOINTMENT_CHANGED',@appointment_id,@meta; SELECT id,tenant_id,patient_id,branch_id,professional_id,specialty_code,starts_at,ends_at,status,service,note,revision,request_key,request_hash FROM dbo.appointments WHERE tenant_id=@t AND id=@appointment_id;
END;
GO
-- ClinicalService.start / V3: one ACTIVE/PENDING per patient, snapshot complete catalog profile, current author PRO and assignments. RS encounter+entries.
CREATE PROCEDURE dbo.usp_encounter_start @encounter_id char(36),@input nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_clinical_scope N'PRO',@write=1; EXEC dbo.usp_org_json_object @input,N'{"patientId":1,"branchId":1,"specialtyCode":1}'; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),@patient nvarchar(max),@branch nvarchar(max),@spec nvarchar(max),@b char(36),@code varchar(100),@locked char(36),@profile nvarchar(max); SELECT @patient=patientId,@branch=branchId,@spec=specialtyCode FROM OPENJSON(@input) WITH(patientId nvarchar(max),branchId nvarchar(max),specialtyCode nvarchar(max)); IF @encounter_id IS NULL OR DATALENGTH(@patient)<>72 OR TRY_CONVERT(uniqueidentifier,@patient) IS NULL OR DATALENGTH(@branch)<>72 OR TRY_CONVERT(uniqueidentifier,@branch) IS NULL OR NULLIF(@spec,N'') IS NULL OR DATALENGTH(@spec)>200 OR @spec COLLATE Latin1_General_100_BIN2 LIKE N'%[^-A-Za-z0-9_:]%' THROW 51000,'HP_INVALID:Datos de atencion invalidos',1; SET @b=CONVERT(char(36),@branch); SET @code=CONVERT(varchar(100),@spec); EXEC dbo.usp_clinical_branch_guard @b; EXEC dbo.usp_clinical_professional_guard @u,@b,@code; SELECT @locked=id FROM dbo.patients WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@patient; IF @locked IS NULL THROW 51002,'HP_NOT_FOUND:Paciente inexistente',1; IF EXISTS(SELECT 1 FROM dbo.encounters WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND patient_id=@patient AND status<>'FINALIZED') THROW 51003,'HP_CONFLICT:El paciente ya tiene atencion activa o pendiente',1; IF EXISTS(SELECT 1 FROM dbo.encounters WHERE id=@encounter_id) THROW 51003,'HP_CONFLICT:Atencion existente',1; SELECT @profile=profile FROM dbo.specialties WHERE code=@code; IF @profile IS NULL THROW 51002,'HP_NOT_FOUND:Perfil inexistente',1; INSERT dbo.encounters(id,tenant_id,patient_id,branch_id,professional_id,specialty_code,status,note,profile_snapshot) VALUES(@encounter_id,@t,@patient,@b,@u,@code,'ACTIVE',N'',@profile); EXEC dbo.usp_audit_event @t,N'ENCOUNTER_STARTED',@encounter_id; EXEC dbo.usp_encounter_get @encounter_id;
END;
GO

-- ClinicalService.note/finalize / V3 sp_encounter_save: author+branch+revision; preserves note MAX100000 UTF16 units, no text in audit. RS encounter+entries.
CREATE PROCEDURE dbo.usp_encounter_note @encounter_id char(36),@expected_revision int,@note nvarchar(max),@finalize bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_clinical_scope N'PRO',@write=1; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),@branch char(36),@author char(36),@status nvarchar(9),@rev int; IF @note IS NULL OR DATALENGTH(@note)>200000 OR @expected_revision IS NULL OR @expected_revision<1 OR @finalize IS NULL OR (@finalize=1 AND NULLIF(LTRIM(RTRIM(@note)),N'') IS NULL) THROW 51000,'HP_INVALID:Nota o revision de atencion invalida',1; SELECT @branch=branch_id,@author=professional_id,@status=status,@rev=revision FROM dbo.encounters WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@encounter_id; IF @rev IS NULL OR @author<>@u THROW 51002,'HP_NOT_FOUND:Atencion no disponible para este profesional',1; EXEC dbo.usp_clinical_branch_guard @branch; IF @rev<>@expected_revision OR @status='FINALIZED' THROW 51003,'HP_CONFLICT:Atencion finalizada o revision desactualizada',1; UPDATE dbo.encounters SET note=@note,revision=revision+1,status=CASE WHEN @finalize=1 THEN 'FINALIZED' ELSE status END,finalized_at=CASE WHEN @finalize=1 THEN SYSUTCDATETIME() ELSE NULL END WHERE tenant_id=@t AND id=@encounter_id AND revision=@expected_revision; DECLARE @action nvarchar(80)=CASE WHEN @finalize=1 THEN N'ENCOUNTER_FINALIZED' ELSE N'ENCOUNTER_SAVED' END,@next int=@rev+1,@meta nvarchar(max); SET @meta=(SELECT @next revision FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event @t,@action,@encounter_id,@meta; EXEC dbo.usp_encounter_get @encounter_id;
END;
GO

-- ClinicalService.entry / V3: OBSERVATION PRO/ASI; other kinds author PRO. Spring MUST retain ClinicalValidation(profile fields/components/required/types/options) before calling. RS complete saved entry, no TODO rule engine substitution.
CREATE PROCEDURE dbo.usp_clinical_entry_add @entry_id char(36),@encounter_id char(36),@kind nvarchar(max),@payload nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @kind='OBSERVATION' EXEC dbo.usp_clinical_scope N'PRO,ASI',@write=1; ELSE EXEC dbo.usp_clinical_scope N'PRO',@write=1; IF @entry_id IS NULL OR @kind IS NULL OR DATALENGTH(@kind)<>2*LEN(@kind) OR @kind COLLATE Latin1_General_100_BIN2 NOT IN ('EVALUATION','OBSERVATION','ANNOTATION','ORDER','PRESCRIPTION') OR @payload IS NULL OR ISJSON(@payload,OBJECT)<>1 OR DATALENGTH(@payload)>400000 THROW 51000,'HP_INVALID:Tipo o captura clinica invalida',1; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),@branch char(36),@author char(36),@status nvarchar(9),@snapshot nvarchar(max),@component nvarchar(max); SELECT @branch=branch_id,@author=professional_id,@status=status,@snapshot=profile_snapshot FROM dbo.encounters WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@encounter_id; IF @status IS NULL THROW 51002,'HP_NOT_FOUND:Atencion inexistente',1; EXEC dbo.usp_clinical_branch_guard @branch; IF @status='FINALIZED' THROW 51003,'HP_CONFLICT:La atencion esta finalizada',1; IF @kind<>'OBSERVATION' AND @author<>@u THROW 51001,'HP_FORBIDDEN:Entrada reservada al profesional de la atencion',1; SELECT @component=component FROM OPENJSON(@payload) WITH(component nvarchar(max)); IF @kind='ANNOTATION' AND @component COLLATE Latin1_General_100_BIN2 IN ('HUMAN_DENTAL','VET_DENTAL','PERIODONTAL','ENDO','ORTHODONTIC','PROSTHETIC') EXEC dbo.usp_write_guard @t,N'DENTAL'; INSERT dbo.clinical_entries(id,tenant_id,encounter_id,kind,payload,profile_snapshot,actor_id) VALUES(@entry_id,@t,@encounter_id,@kind,@payload,@snapshot,@u); DECLARE @meta nvarchar(max)=(SELECT @kind kind,@encounter_id encounterId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event @t,N'CLINICAL_ENTRY_ADDED',@entry_id,@meta; SELECT id,tenant_id,encounter_id,kind,payload,profile_snapshot,actor_id,created_at FROM dbo.clinical_entries WHERE tenant_id=@t AND id=@entry_id;
END;
GO

-- DocumentService.create / V3: PRO tenant, signed original same patient/tenant and optional encounter same patient; no new branch restriction. Full MAX content, draft adenda only. RS document.
CREATE PROCEDURE dbo.usp_document_create @document_id char(36),@input nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_clinical_scope N'PRO',@write=1; EXEC dbo.usp_clinical_json_object @input,N'{"patientId":1,"encounterId":1,"title":1,"type":1,"content":1,"originalId":1}',N'["encounterId","originalId"]'; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@patient nvarchar(max),@encounter nvarchar(max),@original nvarchar(max),@title nvarchar(max),@type nvarchar(max),@content nvarchar(max); SELECT @patient=patientId,@encounter=encounterId,@original=originalId,@title=title,@type=type,@content=content FROM OPENJSON(@input) WITH(patientId nvarchar(max),encounterId nvarchar(max),originalId nvarchar(max),title nvarchar(max),type nvarchar(max),content nvarchar(max)); IF @document_id IS NULL OR DATALENGTH(@patient)<>72 OR TRY_CONVERT(uniqueidentifier,@patient) IS NULL OR (@encounter IS NOT NULL AND (DATALENGTH(@encounter)<>72 OR TRY_CONVERT(uniqueidentifier,@encounter) IS NULL)) OR (@original IS NOT NULL AND (DATALENGTH(@original)<>72 OR TRY_CONVERT(uniqueidentifier,@original) IS NULL)) OR NULLIF(LTRIM(RTRIM(@title)),N'') IS NULL OR DATALENGTH(@title)>400 OR NULLIF(LTRIM(RTRIM(@type)),N'') IS NULL OR DATALENGTH(@type)>120 OR NULLIF(LTRIM(RTRIM(@content)),N'') IS NULL OR DATALENGTH(@content)>200000 THROW 51000,'HP_INVALID:Datos documentales invalidos',1; IF NOT EXISTS(SELECT 1 FROM dbo.patients WHERE tenant_id=@t AND id=@patient) THROW 51002,'HP_NOT_FOUND:Paciente inexistente',1; IF @original IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.documents WHERE tenant_id=@t AND id=@original AND patient_id=@patient AND status='SIGNED') THROW 51002,'HP_NOT_FOUND:Original firmado no disponible para este paciente',1; IF @encounter IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.encounters WHERE tenant_id=@t AND id=@encounter AND patient_id=@patient) THROW 51002,'HP_NOT_FOUND:Atencion no corresponde al paciente',1; INSERT dbo.documents(id,tenant_id,patient_id,encounter_id,title,type,content,status,original_id) VALUES(@document_id,@t,@patient,@encounter,@title,@type,@content,'DRAFT',@original); DECLARE @meta nvarchar(max)=(SELECT @original originalId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event @t,N'DOCUMENT_CREATED',@document_id,@meta; EXEC dbo.usp_document_get @document_id;
END;
GO

-- DocumentService.change / V3: expectedRevision, immutable signatures and adendas, publication link check, withdrawal prevents future portal read. No raw text in general audit. RS document.
CREATE PROCEDURE dbo.usp_document_change @document_id char(36),@expected_revision int,@operation nvarchar(max),@content nvarchar(max)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_clinical_scope N'PRO',@write=1; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),@status nvarchar(6),@rev int,@patient char(36),@stored nvarchar(max),@hash char(64); IF @expected_revision IS NULL OR @expected_revision<1 OR @operation IS NULL OR DATALENGTH(@operation)<>2*LEN(@operation) OR @operation COLLATE Latin1_General_100_BIN2 NOT IN ('SAVE','SIGN','PUBLISH','WITHDRAW') OR DATALENGTH(@content)>200000 THROW 51000,'HP_INVALID:Operacion documental invalida',1; SELECT @status=status,@rev=revision,@patient=patient_id,@stored=content FROM dbo.documents WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@document_id; IF @rev IS NULL THROW 51002,'HP_NOT_FOUND:Documento inexistente',1; IF @rev<>@expected_revision THROW 51003,'HP_CONFLICT:Revision documental desactualizada',1; IF @operation IN ('SAVE','SIGN') AND @status<>'DRAFT' THROW 51003,'HP_CONFLICT:Documento firmado inmutable; utiliza una adenda',1;
 IF @operation='SAVE' BEGIN IF NULLIF(LTRIM(RTRIM(@content)),N'') IS NULL THROW 51000,'HP_INVALID:Escribe el contenido del borrador',1; UPDATE dbo.documents SET content=@content,revision=revision+1 WHERE tenant_id=@t AND id=@document_id; END
 ELSE IF @operation='SIGN' BEGIN
 -- HASHBYTES(NVARCHAR) hashes UTF16 and is WRONG for Checks.hash/MySQL SHA2.
 -- Explicit UTF8 VARCHAR collation preserves ASCII, accented text and supplementary emoji bytes.
 -- Verify expected SHA256 against Java StandardCharsets.UTF_8 for all three cases on engine.
 SET @hash=LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',CONVERT(varchar(max),@stored COLLATE Latin1_General_100_BIN2_UTF8)),2));
 UPDATE dbo.documents SET status='SIGNED',signer_id=@u,signed_at=SYSUTCDATETIME(),content_hash=@hash,revision=revision+1 WHERE tenant_id=@t AND id=@document_id; END
 ELSE IF @operation='PUBLISH' BEGIN EXEC dbo.usp_write_guard @t,N'PORTAL'; IF @status<>'SIGNED' OR NOT EXISTS(SELECT 1 FROM dbo.patient_links l WITH(HOLDLOCK) WHERE l.tenant_id=@t AND l.patient_id=@patient AND l.active=1 AND EXISTS(SELECT 1 FROM OPENJSON(l.scopes) WHERE value COLLATE Latin1_General_100_BIN2='DOCUMENTS')) THROW 51003,'HP_CONFLICT:Se requiere firma y vinculo vigente de documentos',1; UPDATE dbo.documents SET published=1,withdrawn=0,revision=revision+1 WHERE tenant_id=@t AND id=@document_id; END
 ELSE UPDATE dbo.documents SET published=0,withdrawn=1,revision=revision+1 WHERE tenant_id=@t AND id=@document_id;
 DECLARE @action nvarchar(80)=N'DOCUMENT_'+@operation,@next int=@rev+1,@meta nvarchar(max); SET @meta=(SELECT @next revision FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event @t,@action,@document_id,@meta; EXEC dbo.usp_document_get @document_id;
END;
GO
-- PortalService.patients: active own links only, full scopes JSON, safe access audit added, external TX required even on read.
CREATE PROCEDURE dbo.usp_portal_patients
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_portal_scope; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')); EXEC dbo.usp_audit_event @t,N'PORTAL_PATIENTS_READ',@u; SELECT p.id,p.name,p.domain,p.birth_date,p.species,l.relationship,l.scopes FROM dbo.patients p JOIN dbo.patient_links l WITH(HOLDLOCK) ON l.tenant_id=p.tenant_id AND l.patient_id=p.id WHERE p.tenant_id=@t AND l.user_id=@u AND l.active=1 ORDER BY p.name,p.id;
END;
GO

-- PortalService.documents: current own DOCUMENTS link and only published signed non-withdrawn documents; revocation denies later reads. Content MAX, safe audit.
CREATE PROCEDURE dbo.usp_portal_documents @patient_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_portal_scope @patient_id,N'DOCUMENTS'; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); EXEC dbo.usp_audit_event @t,N'PORTAL_DOCUMENTS_READ',@patient_id; SELECT TOP(200) id,title,type,content,revision,signer_id,signed_at,content_hash,original_id FROM dbo.documents WHERE tenant_id=@t AND patient_id=@patient_id AND published=1 AND withdrawn=0 AND status='SIGNED' ORDER BY signed_at DESC,id;
END;
GO

-- PortalService.appointments: own APPOINTMENTS scope, same limited public projection, internal audit added.
CREATE PROCEDURE dbo.usp_portal_appointments @patient_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_portal_scope @patient_id,N'APPOINTMENTS'; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); EXEC dbo.usp_audit_event @t,N'PORTAL_APPOINTMENTS_READ',@patient_id; SELECT TOP(200) id,branch_id,professional_id,specialty_code,starts_at,ends_at,status,service,revision FROM dbo.appointments WHERE tenant_id=@t AND patient_id=@patient_id ORDER BY starts_at DESC,id;
END;
GO

-- PortalService.balance: existing FINANCE+BILLING linked read only; no finance writes ported, refund sign semantics preserved.
CREATE PROCEDURE dbo.usp_portal_balance @patient_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_portal_scope @patient_id,N'BILLING',@finance=1; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); EXEC dbo.usp_audit_event @t,N'PORTAL_BALANCE_READ',@patient_id; SELECT COALESCE(SUM(CASE WHEN kind='PAYMENT' THEN -amount_minor ELSE amount_minor END),CONVERT(bigint,0)) balance_minor,CAST('PEN' AS char(3)) currency FROM dbo.finance_movements WHERE tenant_id=@t AND patient_id=@patient_id;
END;
GO
