-- SQL Server 2022, caller-owned migration transaction.
-- Encode the scalar allergy history for the executor's existing JSON-column contract.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>1
 THROW 51000,'HP_INVALID:Separate transactional migration principal required',1;
IF OBJECT_ID(N'dbo.medical_consultations') IS NULL OR OBJECT_ID(N'dbo.medical_services') IS NOT NULL
 THROW 51003,'HP_CONFLICT:V16 required; V17 cannot be reapplied',1;
CREATE TABLE dbo.medical_services(
 id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
 tenant_id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL REFERENCES dbo.tenants(id),
 name nvarchar(160) NOT NULL,
 price_minor int NOT NULL CHECK(price_minor>=0),
 active bit NOT NULL,revision int NOT NULL CHECK(revision>0),
 CONSTRAINT UQ_medical_service_name UNIQUE(tenant_id,name)
);
CREATE TABLE dbo.medical_agreements(
 id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,
 tenant_id char(36) COLLATE Latin1_General_100_BIN2 NOT NULL REFERENCES dbo.tenants(id),
 name nvarchar(160) NOT NULL,
 discount_percent int NOT NULL CHECK(discount_percent BETWEEN 0 AND 100),
 active bit NOT NULL,revision int NOT NULL CHECK(revision>0),
 CONSTRAINT UQ_medical_agreement_name UNIQUE(tenant_id,name)
);
GO
CREATE PROCEDURE dbo.usp_medical_services
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.usp_clinical_scope N'ADM,REC,PRO,ASI,AUD';
 SELECT id,name,price_minor,active,revision FROM dbo.medical_services WHERE tenant_id=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')) ORDER BY name,id;
END;
GO
CREATE PROCEDURE dbo.usp_medical_agreements
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.usp_clinical_scope N'ADM,REC,PRO,ASI,AUD';
 SELECT id,name,discount_percent,active,revision FROM dbo.medical_agreements WHERE tenant_id=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')) ORDER BY name,id;
END;
GO
CREATE PROCEDURE dbo.usp_medical_catalog_save @id char(36),@kind varchar(10),@input nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.usp_clinical_scope N'ADM',@write=1;EXEC dbo.usp_require_transaction;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@name nvarchar(160),@value int,@active bit,@expected int,@revision int,@lock char(36);
 -- Serialize catalog changes per tenant, including insert-name uniqueness and revisions.
 SELECT @lock=id FROM dbo.tenants WITH(UPDLOCK,HOLDLOCK) WHERE id=@t;
 IF @kind NOT IN ('SERVICE','AGREEMENT') OR ISJSON(@input,OBJECT)<>1 THROW 51000,'HP_INVALID:Catalog input required',1;
 IF (SELECT COUNT(*) FROM OPENJSON(@input))<>4 OR EXISTS(SELECT [key] FROM OPENJSON(@input) GROUP BY [key] HAVING COUNT(*)<>1)
 OR EXISTS(SELECT 1 FROM OPENJSON(@input) WHERE [key] NOT IN ('name','value','active','expectedRevision') OR ([key]='name' AND ([type]<>1 OR DATALENGTH(value)>320 OR NULLIF(LTRIM(RTRIM(value)),N'') IS NULL)) OR ([key]='active' AND [type]<>3) OR ([key] IN ('value','expectedRevision') AND [type]<>2))
 THROW 51000,'HP_INVALID:Invalid catalog fields',1;
 SELECT @name=JSON_VALUE(@input,'$.name'),@value=TRY_CONVERT(int,JSON_VALUE(@input,'$.value')),@active=CASE JSON_VALUE(@input,'$.active') WHEN 'true' THEN 1 WHEN 'false' THEN 0 END,@expected=TRY_CONVERT(int,JSON_VALUE(@input,'$.expectedRevision'));
 IF @value IS NULL OR @value<0 OR (@kind='AGREEMENT' AND @value>100) OR @active IS NULL OR @expected IS NULL OR @expected<0 OR @expected=2147483647 THROW 51000,'HP_INVALID:Invalid amount or revision',1;
 IF @kind='SERVICE'
 BEGIN
  SELECT @revision=revision FROM dbo.medical_services WHERE tenant_id=@t AND id=@id;
  IF ISNULL(@revision,0)<>@expected THROW 51003,'HP_CONFLICT:Service changed; reload',1;
  IF @revision IS NULL INSERT dbo.medical_services(id,tenant_id,name,price_minor,active,revision) VALUES(@id,@t,@name,@value,@active,1);
  ELSE UPDATE dbo.medical_services SET name=@name,price_minor=@value,active=@active,revision=revision+1 WHERE id=@id AND tenant_id=@t;
 END
 ELSE BEGIN
  SELECT @revision=revision FROM dbo.medical_agreements WHERE tenant_id=@t AND id=@id;
  IF ISNULL(@revision,0)<>@expected THROW 51003,'HP_CONFLICT:Agreement changed; reload',1;
  IF @revision IS NULL INSERT dbo.medical_agreements(id,tenant_id,name,discount_percent,active,revision) VALUES(@id,@t,@name,@value,@active,1);
  ELSE UPDATE dbo.medical_agreements SET name=@name,discount_percent=@value,active=@active,revision=revision+1 WHERE id=@id AND tenant_id=@t;
 END;
 EXEC dbo.usp_audit_event @t,N'MEDICAL_CATALOG_SAVED',@id;
 SELECT @id id,ISNULL(@revision,0)+1 revision;
END;
GO
GRANT EXECUTE ON dbo.usp_medical_services TO hp_runtime_executor;
GRANT EXECUTE ON dbo.usp_medical_agreements TO hp_runtime_executor;
GRANT EXECUTE ON dbo.usp_medical_catalog_save TO hp_runtime_executor;
DENY EXECUTE ON dbo.usp_medical_services TO hp_bootstrap_executor;
DENY EXECUTE ON dbo.usp_medical_agreements TO hp_bootstrap_executor;
DENY EXECUTE ON dbo.usp_medical_catalog_save TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON dbo.medical_services TO hp_runtime_executor,hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON dbo.medical_agreements TO hp_runtime_executor,hp_bootstrap_executor;
GO

ALTER PROCEDURE dbo.usp_patient_antecedents @patient_id char(36)
AS
BEGIN
 SET NOCOUNT ON;SET XACT_ABORT ON;EXEC dbo.usp_clinical_scope N'PRO,ASI,AUD';EXEC dbo.usp_require_transaction;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id'));
 IF NOT EXISTS(SELECT 1 FROM dbo.patients WHERE tenant_id=@t AND id=@patient_id)THROW 51002,'HP_NOT_FOUND:Patient not found',1;
 EXEC dbo.usp_audit_event @t,N'ANTECEDENTS_READ',@patient_id;
 SELECT a.id,a.patient_id,a.version,a.personal,a.family,N'"'+STRING_ESCAPE(a.allergies,'json')+N'"' allergies,a.medication,a.actor_id,u.name actor_name,a.created_at
 FROM dbo.patient_antecedents a JOIN dbo.users u ON u.id=a.actor_id WHERE a.tenant_id=@t AND a.patient_id=@patient_id ORDER BY a.version DESC;
END;

GO

ALTER PROCEDURE dbo.usp_patient_antecedent_add @id char(36),@patient_id char(36),@input nvarchar(max)
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
 SELECT a.id,a.patient_id,a.version,a.personal,a.family,N'"'+STRING_ESCAPE(a.allergies,'json')+N'"' allergies,a.medication,a.actor_id,u.name actor_name,a.created_at FROM dbo.patient_antecedents a JOIN dbo.users u ON u.id=a.actor_id WHERE a.id=@id AND a.tenant_id=@t;
END;

GO
