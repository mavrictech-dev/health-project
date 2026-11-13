-- SQL Server 2022. Apply with a separate migration principal in an external transaction.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>1
 THROW 51000,'HP_INVALID:Separate transactional migration principal required',1;
IF COL_LENGTH(N'dbo.tenants',N'ruc') IS NULL OR OBJECT_ID(N'dbo.patient_antecedents') IS NOT NULL OR OBJECT_ID(N'dbo.medical_consultations') IS NOT NULL
 THROW 51003,'HP_CONFLICT:V15 required; V16 cannot be reapplied',1;
CREATE TABLE dbo.patient_antecedents (
 id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
 tenant_id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
 patient_id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
 version int NOT NULL CHECK(version>0),
 personal nvarchar(max) NOT NULL, family nvarchar(max) NOT NULL,
 allergies nvarchar(max) NOT NULL, medication nvarchar(max) NOT NULL,
 actor_id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL REFERENCES dbo.users(id),
 created_at datetime2(6) NOT NULL DEFAULT SYSUTCDATETIME(),
 CONSTRAINT FK_antecedent_patient FOREIGN KEY(tenant_id,patient_id) REFERENCES dbo.patients(tenant_id,id),
 CONSTRAINT UQ_antecedent_version UNIQUE(tenant_id,patient_id,version)
);
CREATE TABLE dbo.medical_consultations (
 id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
 tenant_id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
 patient_id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
 branch_id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
 professional_id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
 anamnesis nvarchar(max) NOT NULL, physical_exam nvarchar(max) NOT NULL,
 diagnosis nvarchar(max) NOT NULL, treatment nvarchar(max) NOT NULL,
 status varchar(9) COLLATE Latin1_General_100_BIN2 NOT NULL CHECK(status IN ('ATTENDED','PENDING','CANCELLED','NO_SHOW')),
 request_hash char(64) COLLATE Latin1_General_100_BIN2 NOT NULL,
 created_at datetime2(6) NOT NULL DEFAULT SYSUTCDATETIME(),
 CONSTRAINT FK_consultation_patient FOREIGN KEY(tenant_id,patient_id) REFERENCES dbo.patients(tenant_id,id),
 CONSTRAINT FK_consultation_branch FOREIGN KEY(tenant_id,branch_id) REFERENCES dbo.branches(tenant_id,id),
 CONSTRAINT FK_consultation_member FOREIGN KEY(tenant_id,professional_id) REFERENCES dbo.memberships(tenant_id,user_id)
);
CREATE INDEX IX_consultation_history ON dbo.medical_consultations(tenant_id,patient_id,created_at DESC);
GO
CREATE TRIGGER dbo.antecedents_immutable ON dbo.patient_antecedents INSTEAD OF UPDATE,DELETE AS
BEGIN THROW 51003,'HP_CONFLICT:Antecedents are append only; insert a new version',1; END;
GO
CREATE TRIGGER dbo.consultations_immutable ON dbo.medical_consultations INSTEAD OF UPDATE,DELETE AS
BEGIN THROW 51003,'HP_CONFLICT:Consultation records are immutable',1; END;
GO
CREATE PROCEDURE dbo.usp_login_branches @ruc nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor;EXEC dbo.usp_require_transaction;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id'));
 IF @ruc IS NULL OR DATALENGTH(@ruc)<>22 OR NOT EXISTS(SELECT 1 FROM dbo.tenants WHERE id=@t AND ruc COLLATE Latin1_General_100_BIN2=@ruc COLLATE Latin1_General_100_BIN2)
  THROW 51001,'HP_FORBIDDEN:RUC does not match the authenticated space',1;
 SELECT b.id,b.name,b.address FROM dbo.branches b WHERE b.tenant_id=@t AND b.active=1 AND
 (EXISTS(SELECT 1 FROM dbo.memberships m CROSS APPLY OPENJSON(m.roles) r WHERE m.tenant_id=@t AND m.user_id=@u AND m.status='ACTIVE' AND r.value='ADM')
 OR EXISTS(SELECT 1 FROM dbo.membership_branches mb WHERE mb.tenant_id=@t AND mb.user_id=@u AND mb.branch_id=b.id)) ORDER BY b.name,b.id;
END;
GO
-- General directory of this business, across its branches. Never discloses another tenant.
CREATE PROCEDURE dbo.usp_patient_dni_directory @dni nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.usp_clinical_scope N'ADM,REC,PRO,ASI';EXEC dbo.usp_require_transaction;
 IF @dni IS NULL OR DATALENGTH(@dni)<6 OR DATALENGTH(@dni)>16 OR @dni COLLATE Latin1_General_100_BIN2 LIKE N'%[^0-9]%'
 THROW 51000,'HP_INVALID:DNI prefix requires 3 to 8 ASCII digits',1;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id'));
 EXEC dbo.usp_audit_event @t,N'PATIENT_DIRECTORY_READ',N'dni';
 SELECT TOP(15) id,name,identifier,birth_date,contact FROM dbo.patients WHERE tenant_id=@t AND domain='HUMAN' AND identifier LIKE @dni+N'%' ORDER BY identifier,id;
END;
GO
CREATE PROCEDURE dbo.usp_patient_antecedents @patient_id char(36)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.usp_clinical_scope N'PRO,ASI,AUD';EXEC dbo.usp_require_transaction;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id'));
 IF NOT EXISTS(SELECT 1 FROM dbo.patients WHERE tenant_id=@t AND id=@patient_id)THROW 51002,'HP_NOT_FOUND:Patient not found',1;
 EXEC dbo.usp_audit_event @t,N'ANTECEDENTS_READ',@patient_id;
 SELECT a.id,a.patient_id,a.version,a.personal,a.family,a.allergies,a.medication,a.actor_id,u.name actor_name,a.created_at
 FROM dbo.patient_antecedents a JOIN dbo.users u ON u.id=a.actor_id WHERE a.tenant_id=@t AND a.patient_id=@patient_id ORDER BY a.version DESC;
END;
GO
CREATE PROCEDURE dbo.usp_patient_antecedent_add @id char(36),@patient_id char(36),@input nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.usp_clinical_scope N'PRO',@write=1;EXEC dbo.usp_require_transaction;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),@locked char(36),@version int;
 SELECT @locked=id FROM dbo.patients WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@t AND id=@patient_id;
 IF @locked IS NULL THROW 51002,'HP_NOT_FOUND:Patient not found',1;
 IF ISJSON(@input,OBJECT)<>1 THROW 51000,'HP_INVALID:Antecedent object required',1;
 IF (SELECT COUNT(*) FROM OPENJSON(@input))<>5 OR EXISTS(SELECT [key] FROM OPENJSON(@input) GROUP BY [key] HAVING COUNT(*)<>1)
 OR EXISTS(SELECT 1 FROM OPENJSON(@input) WHERE [key] NOT IN ('expectedVersion','personal','family','allergies','medication') OR ([key]<>'expectedVersion' AND ([type]<>1 OR DATALENGTH(value)>40000)) OR ([key]='expectedVersion' AND [type]<>2))
 THROW 51000,'HP_INVALID:Invalid antecedent fields',1;
 DECLARE @expected int=TRY_CONVERT(int,JSON_VALUE(@input,'$.expectedVersion'));
 IF @expected IS NULL OR @expected<0 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@input) WHERE [key]='personal' AND NULLIF(LTRIM(RTRIM(value)),N'') IS NOT NULL) THROW 51000,'HP_INVALID:Version and personal antecedents required',1;
 SELECT @version=ISNULL(MAX(version),0) FROM dbo.patient_antecedents WHERE tenant_id=@t AND patient_id=@patient_id;
 IF @expected<>@version THROW 51003,'HP_CONFLICT:Antecedents changed; reload before inserting a new version',1;
 INSERT dbo.patient_antecedents(id,tenant_id,patient_id,version,personal,family,allergies,medication,actor_id)
 SELECT @id,@t,@patient_id,@version+1,j.personal,j.family,j.allergies,j.medication,@u
 FROM OPENJSON(@input) WITH(personal nvarchar(max),family nvarchar(max),allergies nvarchar(max),medication nvarchar(max)) j;
 EXEC dbo.usp_audit_event @t,N'ANTECEDENT_ADDED',@id;
 SELECT a.id,a.patient_id,a.version,a.personal,a.family,a.allergies,a.medication,a.actor_id,u.name actor_name,a.created_at FROM dbo.patient_antecedents a JOIN dbo.users u ON u.id=a.actor_id WHERE a.id=@id AND a.tenant_id=@t;
END;
GO
CREATE PROCEDURE dbo.usp_consultations_list @patient_id char(36)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.usp_clinical_scope N'PRO,ASI,AUD';EXEC dbo.usp_require_transaction;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id'));
 IF NOT EXISTS(SELECT 1 FROM dbo.patients WHERE tenant_id=@t AND id=@patient_id)THROW 51002,'HP_NOT_FOUND:Patient not found',1;
 EXEC dbo.usp_audit_event @t,N'CONSULTATIONS_READ',@patient_id;
 SELECT c.id,c.patient_id,c.branch_id,b.name branch_name,c.professional_id,u.name professional_name,c.anamnesis,c.physical_exam,c.diagnosis,c.treatment,c.status,c.created_at
 FROM dbo.medical_consultations c JOIN dbo.users u ON u.id=c.professional_id JOIN dbo.branches b ON b.tenant_id=c.tenant_id AND b.id=c.branch_id
 WHERE c.tenant_id=@t AND c.patient_id=@patient_id ORDER BY c.created_at DESC,c.id;
END;
GO
CREATE PROCEDURE dbo.usp_consultation_add @id char(36),@input nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.usp_clinical_scope N'PRO',@write=1;EXEC dbo.usp_require_transaction;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id'));
 IF ISJSON(@input,OBJECT)<>1 THROW 51000,'HP_INVALID:Consultation object required',1;
 IF (SELECT COUNT(*) FROM OPENJSON(@input))<>8 OR EXISTS(SELECT [key] FROM OPENJSON(@input) GROUP BY [key] HAVING COUNT(*)<>1)
 OR EXISTS(SELECT 1 FROM OPENJSON(@input) WHERE [type]<>1 OR [key] NOT IN ('requestId','patientId','branchId','anamnesis','physicalExam','diagnosis','treatment','status') OR DATALENGTH(value)>40000)
 THROW 51000,'HP_INVALID:Invalid consultation fields',1;
 DECLARE @patient char(36)=JSON_VALUE(@input,'$.patientId'),@branch char(36)=JSON_VALUE(@input,'$.branchId'),@state varchar(9)=JSON_VALUE(@input,'$.status'),@hash char(64)=CONVERT(char(64),HASHBYTES('SHA2_256',@input),2);
 IF JSON_VALUE(@input,'$.requestId')<>@id OR DATALENGTH(JSON_VALUE(@input,'$.patientId'))<>72 OR DATALENGTH(JSON_VALUE(@input,'$.branchId'))<>72
 OR JSON_VALUE(@input,'$.status') COLLATE Latin1_General_100_BIN2 NOT IN ('ATTENDED','PENDING','CANCELLED','NO_SHOW')
 OR NOT EXISTS(SELECT 1 FROM OPENJSON(@input) WHERE [key]='anamnesis' AND NULLIF(LTRIM(RTRIM(value)),N'') IS NOT NULL) THROW 51000,'HP_INVALID:Invalid consultation identity or content',1;
 EXEC dbo.usp_clinical_branch_guard @branch;
 IF NOT EXISTS(SELECT 1 FROM dbo.patients WHERE tenant_id=@t AND id=@patient)THROW 51002,'HP_NOT_FOUND:Patient not found',1;
 IF EXISTS(SELECT 1 FROM dbo.medical_consultations WITH(UPDLOCK,HOLDLOCK) WHERE id=@id)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM dbo.medical_consultations WHERE id=@id AND tenant_id=@t AND professional_id=@u AND request_hash=@hash)THROW 51003,'HP_CONFLICT:Request already used with different content',1;
 END
 ELSE BEGIN
  INSERT dbo.medical_consultations(id,tenant_id,patient_id,branch_id,professional_id,anamnesis,physical_exam,diagnosis,treatment,status,request_hash)
  SELECT @id,@t,@patient,@branch,@u,j.anamnesis,j.physicalExam,j.diagnosis,j.treatment,@state,@hash FROM OPENJSON(@input) WITH(anamnesis nvarchar(max),physicalExam nvarchar(max),diagnosis nvarchar(max),treatment nvarchar(max)) j;
  EXEC dbo.usp_audit_event @t,N'CONSULTATION_ADDED',@id;
 END;
 SELECT c.id,c.patient_id,c.branch_id,b.name branch_name,c.professional_id,u.name professional_name,c.anamnesis,c.physical_exam,c.diagnosis,c.treatment,c.status,c.created_at
 FROM dbo.medical_consultations c JOIN dbo.users u ON u.id=c.professional_id JOIN dbo.branches b ON b.tenant_id=c.tenant_id AND b.id=c.branch_id WHERE c.id=@id AND c.tenant_id=@t;
END;
GO
GRANT EXECUTE ON dbo.usp_login_branches TO hp_runtime_executor;
GRANT EXECUTE ON dbo.usp_patient_dni_directory TO hp_runtime_executor;
GRANT EXECUTE ON dbo.usp_patient_antecedents TO hp_runtime_executor;
GRANT EXECUTE ON dbo.usp_patient_antecedent_add TO hp_runtime_executor;
GRANT EXECUTE ON dbo.usp_consultations_list TO hp_runtime_executor;
GRANT EXECUTE ON dbo.usp_consultation_add TO hp_runtime_executor;
DENY EXECUTE ON dbo.usp_login_branches TO hp_bootstrap_executor;
DENY EXECUTE ON dbo.usp_patient_dni_directory TO hp_bootstrap_executor;
DENY EXECUTE ON dbo.usp_patient_antecedents TO hp_bootstrap_executor;
DENY EXECUTE ON dbo.usp_patient_antecedent_add TO hp_bootstrap_executor;
DENY EXECUTE ON dbo.usp_consultations_list TO hp_bootstrap_executor;
DENY EXECUTE ON dbo.usp_consultation_add TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON dbo.patient_antecedents TO hp_runtime_executor,hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON dbo.medical_consultations TO hp_runtime_executor,hp_bootstrap_executor;
GO
