-- HP8: branch calendar, manual collection status and immutable reconciliation changes.
-- Caller owns the transaction. Runtime receives EXECUTE only; no payment provider is invoked.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>1 THROW 51000,'HP_INVALID:Separate transactional migration principal required',1;
IF COL_LENGTH(N'dbo.medical_consultations',N'appointment_id') IS NULL OR OBJECT_ID(N'dbo.appointment_collections') IS NOT NULL THROW 51003,'HP_CONFLICT:V18 required; V19 cannot be reapplied',1;
CREATE TABLE dbo.appointment_collections(
 tenant_id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
 appointment_id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
 status varchar(7) COLLATE Latin1_General_100_BIN2 NOT NULL,
 amount_minor int NOT NULL CHECK(amount_minor BETWEEN 0 AND 2000000000),
 payment_method varchar(8) COLLATE Latin1_General_100_BIN2 NULL,
 revision int NOT NULL CHECK(revision>0),
 updated_by char(36) COLLATE Latin1_General_100_BIN2 NOT NULL REFERENCES dbo.users(id),
 updated_at datetime2(6) NOT NULL,
 CONSTRAINT PK_appointment_collections PRIMARY KEY(tenant_id,appointment_id),
 CONSTRAINT FK_appointment_collection FOREIGN KEY(tenant_id,appointment_id) REFERENCES dbo.appointments(tenant_id,id),
 CONSTRAINT CK_appointment_collection CHECK((status='PENDING' AND payment_method IS NULL) OR (status='PAID' AND amount_minor>0 AND payment_method IS NOT NULL AND payment_method IN ('CASH','CARD','TRANSFER','YAPE','PLIN','OTHER')))
);
CREATE TABLE dbo.appointment_collection_changes(
 id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
 tenant_id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
 appointment_id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
 actor_id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL REFERENCES dbo.users(id),
 before_status varchar(7) COLLATE Latin1_General_100_BIN2 NOT NULL,
 after_status varchar(7) COLLATE Latin1_General_100_BIN2 NOT NULL,
 before_amount int NOT NULL,after_amount int NOT NULL,
 before_method varchar(8) COLLATE Latin1_General_100_BIN2 NULL,
 after_method varchar(8) COLLATE Latin1_General_100_BIN2 NULL,
 revision int NOT NULL,
 request_hash char(64) COLLATE Latin1_General_100_BIN2 NOT NULL,
 created_at datetime2(6) NOT NULL,
 CONSTRAINT FK_appointment_collection_change FOREIGN KEY(tenant_id,appointment_id) REFERENCES dbo.appointment_collections(tenant_id,appointment_id),
 CONSTRAINT UQ_appointment_collection_change UNIQUE(tenant_id,appointment_id,revision)
);
CREATE INDEX IX_collection_changes_date ON dbo.appointment_collection_changes(tenant_id,created_at);
GO
CREATE TRIGGER dbo.collection_changes_immutable ON dbo.appointment_collection_changes INSTEAD OF UPDATE,DELETE AS
BEGIN THROW 51003,'HP_CONFLICT:Collection history is immutable',1; END;
GO
CREATE PROCEDURE dbo.usp_agenda_context @branch_id char(36)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.usp_clinical_scope N'ADM,REC,PRO,ASI,AUD,CAJ';EXEC dbo.usp_require_transaction;EXEC dbo.usp_clinical_branch_guard @branch_id;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id'));
 SELECT (SELECT t.timezone,t.domain,JSON_QUERY((SELECT u.id,u.name,s.code specialtyCode,s.name specialtyName
 FROM dbo.memberships m JOIN dbo.users u ON u.id=m.user_id JOIN dbo.membership_branches mb ON mb.tenant_id=m.tenant_id AND mb.user_id=m.user_id
 JOIN dbo.membership_specialties ms ON ms.tenant_id=m.tenant_id AND ms.user_id=m.user_id JOIN dbo.tenant_specialties ts ON ts.tenant_id=ms.tenant_id AND ts.specialty_code=ms.specialty_code
 JOIN dbo.specialties s ON s.code=ts.specialty_code WHERE m.tenant_id=@t AND mb.branch_id=@branch_id AND m.status='ACTIVE' AND u.active=1 AND u.email_verified=1 AND u.platform_role IS NULL AND EXISTS(SELECT 1 FROM OPENJSON(m.roles) WHERE value='PRO') ORDER BY u.name,s.name FOR JSON PATH)) professionals FROM dbo.tenants t WHERE id=@t FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) payload;
END;
GO
CREATE PROCEDURE dbo.usp_agenda_list @branch_id char(36),@from datetime2(6),@to datetime2(6),@professional_id char(36)=NULL
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.usp_clinical_scope N'ADM,REC,PRO,ASI,AUD,CAJ';EXEC dbo.usp_require_transaction;EXEC dbo.usp_clinical_branch_guard @branch_id;
 IF @from IS NULL OR @to IS NULL OR @to<=@from OR DATEDIFF_BIG(second,@from,@to)>691200 THROW 51000,'HP_INVALID:Select up to eight days',1;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id'));
 EXEC dbo.usp_audit_event @t,N'AGENDA_READ',@branch_id;
 SELECT TOP(1001) a.id,a.patient_id,p.name patient_name,p.identifier,a.branch_id,a.professional_id,u.name professional_name,a.specialty_code,a.starts_at,a.ends_at,a.status,a.service,a.note,a.revision,
 COALESCE(c.status,'PENDING') collection_status,COALESCE(c.amount_minor,0) amount_minor,c.payment_method,COALESCE(c.revision,0) collection_revision,c.updated_at collection_updated_at
 FROM dbo.appointments a JOIN dbo.patients p ON p.tenant_id=a.tenant_id AND p.id=a.patient_id JOIN dbo.users u ON u.id=a.professional_id
 LEFT JOIN dbo.appointment_collections c ON c.tenant_id=a.tenant_id AND c.appointment_id=a.id
 WHERE a.tenant_id=@t AND a.branch_id=@branch_id AND a.starts_at<@to AND a.ends_at>@from AND (@professional_id IS NULL OR a.professional_id=@professional_id) ORDER BY a.starts_at,a.id;
END;
GO
CREATE PROCEDURE dbo.usp_agenda_collection_save @appointment_id char(36),@branch_id char(36),@request_id char(36),@expected_revision int,@status varchar(7),@amount_minor int,@payment_method varchar(8)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.usp_clinical_scope N'ADM,REC,CAJ',@write=1;EXEC dbo.usp_require_transaction;EXEC dbo.usp_clinical_branch_guard @branch_id;
 IF @expected_revision IS NULL OR @expected_revision<0 OR @expected_revision=2147483647 OR @request_id IS NULL OR TRY_CONVERT(uniqueidentifier,@request_id) IS NULL
 OR @status IS NULL OR @amount_minor IS NULL OR @amount_minor<0 OR @amount_minor>2000000000 OR NOT ((@status='PENDING' AND @payment_method IS NULL) OR (@status='PAID' AND @amount_minor>0 AND @payment_method IS NOT NULL AND @payment_method IN ('CASH','CARD','TRANSFER','YAPE','PLIN','OTHER')))
 THROW 51000,'HP_INVALID:Invalid collection status, amount or method',1;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),@locked char(36),@old varchar(7)='PENDING',@old_amount int=0,@old_method varchar(8),@rev int=0,@now datetime2(6)=SYSUTCDATETIME();
 SELECT @locked=id FROM dbo.appointments WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND branch_id=@branch_id AND id=@appointment_id;
 IF @locked IS NULL THROW 51002,'HP_NOT_FOUND:Appointment not available in this branch',1;
 DECLARE @hash char(64)=CONVERT(char(64),HASHBYTES('SHA2_256',CONCAT(@appointment_id,'|',@branch_id,'|',@expected_revision,'|',@status,'|',@amount_minor,'|',COALESCE(@payment_method,'-'))),2);
 IF EXISTS(SELECT 1 FROM dbo.appointment_collection_changes WITH(UPDLOCK,HOLDLOCK) WHERE id=@request_id)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.appointment_collection_changes WHERE id=@request_id AND tenant_id=@t AND appointment_id=@appointment_id AND actor_id=@u AND request_hash=@hash) THROW 51003,'HP_CONFLICT:Request key already used with different content',1;
  SELECT appointment_id,after_status status,after_amount amount_minor,after_method payment_method,revision,created_at updated_at FROM dbo.appointment_collection_changes WHERE id=@request_id AND tenant_id=@t;RETURN;
 END;
 SELECT @old=status,@old_amount=amount_minor,@old_method=payment_method,@rev=revision FROM dbo.appointment_collections WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND appointment_id=@appointment_id;
 IF @rev<>@expected_revision THROW 51003,'HP_CONFLICT:Collection changed; reload before editing',1;
 IF @rev=0 INSERT dbo.appointment_collections(tenant_id,appointment_id,status,amount_minor,payment_method,revision,updated_by,updated_at) VALUES(@t,@appointment_id,@status,@amount_minor,@payment_method,1,@u,@now);
 ELSE UPDATE dbo.appointment_collections SET status=@status,amount_minor=@amount_minor,payment_method=@payment_method,revision=revision+1,updated_by=@u,updated_at=@now WHERE tenant_id=@t AND appointment_id=@appointment_id;
 INSERT dbo.appointment_collection_changes(id,tenant_id,appointment_id,actor_id,before_status,after_status,before_amount,after_amount,before_method,after_method,revision,request_hash,created_at) VALUES(@request_id,@t,@appointment_id,@u,@old,@status,@old_amount,@amount_minor,@old_method,@payment_method,@rev+1,@hash,@now);
 DECLARE @meta nvarchar(max)=(SELECT @status status,@amount_minor amountMinor,@payment_method paymentMethod,@rev+1 revision FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.usp_audit_event @t,N'APPOINTMENT_COLLECTION_CHANGED',@appointment_id,@meta;
 SELECT appointment_id,status,amount_minor,payment_method,revision,updated_at FROM dbo.appointment_collections WHERE tenant_id=@t AND appointment_id=@appointment_id;
END;
GO
CREATE PROCEDURE dbo.usp_agenda_collection_summary @branch_id char(36),@from datetime2(6),@to datetime2(6)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.usp_clinical_scope N'ADM,REC,CAJ,AUD';EXEC dbo.usp_require_transaction;EXEC dbo.usp_clinical_branch_guard @branch_id;
 IF @from IS NULL OR @to IS NULL OR @to<=@from OR DATEDIFF_BIG(second,@from,@to)>691200 THROW 51000,'HP_INVALID:Select up to eight days',1;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id'));
 EXEC dbo.usp_audit_event @t,N'COLLECTION_RECONCILIATION_READ',@branch_id;
 SELECT leg.payment_method,SUM(CONVERT(bigint,leg.amount_minor)) net_minor,SUM(CASE WHEN leg.amount_minor>0 THEN 1 ELSE 0 END) receipts,SUM(CASE WHEN leg.amount_minor<0 THEN 1 ELSE 0 END) reversals
 FROM dbo.appointment_collection_changes c JOIN dbo.appointments a ON a.tenant_id=c.tenant_id AND a.id=c.appointment_id
 CROSS APPLY(VALUES(CASE WHEN c.before_status='PAID' THEN c.before_method END,CASE WHEN c.before_status='PAID' THEN -c.before_amount ELSE 0 END),(CASE WHEN c.after_status='PAID' THEN c.after_method END,CASE WHEN c.after_status='PAID' THEN c.after_amount ELSE 0 END)) leg(payment_method,amount_minor)
 WHERE c.tenant_id=@t AND a.branch_id=@branch_id AND c.created_at>=@from AND c.created_at<@to AND leg.payment_method IS NOT NULL GROUP BY leg.payment_method ORDER BY leg.payment_method;
END;
GO
GRANT EXECUTE ON dbo.usp_agenda_context TO hp_runtime_executor;
GRANT EXECUTE ON dbo.usp_agenda_list TO hp_runtime_executor;
GRANT EXECUTE ON dbo.usp_agenda_collection_save TO hp_runtime_executor;
GRANT EXECUTE ON dbo.usp_agenda_collection_summary TO hp_runtime_executor;
DENY EXECUTE ON dbo.usp_agenda_context TO hp_bootstrap_executor;
DENY EXECUTE ON dbo.usp_agenda_list TO hp_bootstrap_executor;
DENY EXECUTE ON dbo.usp_agenda_collection_save TO hp_bootstrap_executor;
DENY EXECUTE ON dbo.usp_agenda_collection_summary TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON dbo.appointment_collections TO hp_runtime_executor,hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON dbo.appointment_collection_changes TO hp_runtime_executor,hp_bootstrap_executor;
GO

-- A no-show releases the professional time slot, like a cancellation.
ALTER PROCEDURE dbo.usp_appointment_reserve @appointment_id char(36),@input nvarchar(max),@request_key nvarchar(max),@request_hash char(64),@portal bit=0
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
 IF EXISTS(SELECT 1 FROM dbo.appointments WHERE professional_id=@u AND status NOT IN ('CANCELLED','WITHDRAWN','NO_SHOW') AND starts_at<@end AND ends_at>@start) THROW 51003,'HP_CONFLICT:Profesional ocupado en ese horario',1;
 INSERT dbo.appointments(id,tenant_id,patient_id,branch_id,professional_id,specialty_code,starts_at,ends_at,status,service,note,request_key,request_hash) VALUES(@appointment_id,@t,@patient,@b,@u,@code,@start,@end,@status,@service,@note,@request_key,@request_hash);
 EXEC dbo.usp_audit_event @t,N'APPOINTMENT_RESERVED',@appointment_id; SELECT id,tenant_id,patient_id,branch_id,professional_id,specialty_code,starts_at,ends_at,status,service,note,revision,request_key,request_hash FROM dbo.appointments WHERE tenant_id=@t AND id=@appointment_id;
END;
GO

-- A no-show releases the professional time slot, like a cancellation.
ALTER PROCEDURE dbo.usp_appointment_change @appointment_id char(36),@expected_revision int,@status nvarchar(max),@starts_at datetime2(6)=NULL,@ends_at datetime2(6)=NULL
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
 IF @starts_at IS NOT NULL OR @ends_at IS NOT NULL BEGIN IF @starts_at IS NULL OR @ends_at IS NULL OR @ends_at<=@starts_at OR DATEDIFF_BIG(microsecond,@starts_at,@ends_at)/60000000<5 OR DATEDIFF_BIG(microsecond,@starts_at,@ends_at)/60000000>480 OR @starts_at<SYSUTCDATETIME() OR @status<>'RESERVED' THROW 51000,'HP_INVALID:Reprograma reserva a horario futuro valido',1; EXEC dbo.usp_clinical_professional_guard @pro,@branch,@spec; IF EXISTS(SELECT 1 FROM dbo.appointments WHERE id<>@appointment_id AND professional_id=@pro AND status NOT IN ('CANCELLED','WITHDRAWN','NO_SHOW') AND starts_at<@ends_at AND ends_at>@starts_at) THROW 51003,'HP_CONFLICT:El nuevo horario esta ocupado',1; END;
 UPDATE dbo.appointments SET starts_at=COALESCE(@starts_at,starts_at),ends_at=COALESCE(@ends_at,ends_at),status=@status,revision=revision+1 WHERE tenant_id=@t AND id=@appointment_id AND revision=@expected_revision;
 DECLARE @next int=@rev+1,@meta nvarchar(max); SET @meta=(SELECT @status status,@next revision FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event @t,N'APPOINTMENT_CHANGED',@appointment_id,@meta; SELECT id,tenant_id,patient_id,branch_id,professional_id,specialty_code,starts_at,ends_at,status,service,note,revision,request_key,request_hash FROM dbo.appointments WHERE tenant_id=@t AND id=@appointment_id;
END;
GO
