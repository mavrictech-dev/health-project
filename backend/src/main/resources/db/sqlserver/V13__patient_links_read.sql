-- PAC-01.B1 / SQL Server 2022. ONE new public read and TWO object ACL entries.
-- Apply with a SEPARATE CONTROL principal in an EXTERNAL committable transaction.
-- The caller must stop at the first batch error (Flyway, or SQLcmd :On Error exit/-b).
-- GO separates CREATE PROCEDURE; never continue past a failed precondition.
-- No autonomous transaction, previous migration changes, data remediation or broad grants.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
IF @@TRANCOUNT=0 OR XACT_STATE()<>1
 THROW 51000,N'HP_INVALID:External migration transaction required',1;
IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>1
 OR ISNULL(IS_ROLEMEMBER(N'hp_runtime_executor'),0)=1
 OR ISNULL(IS_ROLEMEMBER(N'hp_bootstrap_executor'),0)=1
 THROW 51001,N'HP_FORBIDDEN:Separate administrative migration principal required',1;
IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE name COLLATE Latin1_General_100_BIN2=N'dbo' AND DATALENGTH(name)=6 AND principal_id=1)
 OR NOT EXISTS(SELECT 1 FROM sys.database_principals p JOIN sys.databases d ON d.database_id=DB_ID() AND p.sid=d.owner_sid
  WHERE p.name COLLATE Latin1_General_100_BIN2=N'dbo' AND DATALENGTH(p.name)=6 AND p.principal_id=1 AND DATALENGTH(p.sid)>0
  AND ((p.type COLLATE Latin1_General_100_BIN2='S' AND p.authentication_type=1)
    OR (p.type COLLATE Latin1_General_100_BIN2='U' AND p.authentication_type=3)))
 THROW 51000,N'HP_INVALID:Expected dbo ownership required',1;
IF (SELECT COUNT(*) FROM sys.database_principals WHERE name IN (N'hp_runtime_executor',N'hp_bootstrap_executor')
 AND type='R' AND is_fixed_role=0 AND owning_principal_id=DATABASE_PRINCIPAL_ID(N'dbo'))<>2
 THROW 51000,N'HP_INVALID:Expected execution roles required',1;
IF OBJECT_ID(N'dbo.usp_patient_links_list') IS NOT NULL
 THROW 51003,N'HP_CONFLICT:Patient links read entry already exists',1;
IF OBJECT_ID(N'dbo.usp_require_transaction',N'P') IS NULL
 OR OBJECT_ID(N'dbo.usp_clinical_scope',N'P') IS NULL
 OR OBJECT_ID(N'dbo.usp_require_actor',N'P') IS NULL
 OR OBJECT_ID(N'dbo.usp_audit_event',N'P') IS NULL
 THROW 51000,N'HP_INVALID:Accepted transaction and actor helpers required',1;
GO
CREATE PROCEDURE dbo.usp_patient_links_list
 @patient_id char(36), @limit int=50, @offset int=0
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;
 EXEC dbo.usp_require_transaction;
 DECLARE @scope nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_scope'));
 IF @scope IS NULL OR @scope COLLATE Latin1_General_100_BIN2<>N'REQUEST' OR DATALENGTH(@scope)<>14
  THROW 51001,N'HP_FORBIDDEN:Request scope required',1;
 EXEC dbo.usp_clinical_scope @roles=N'ADM,REC',@write=0;
 DECLARE @tenant char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),
         @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
         @roles nvarchar(max);
 -- Hold the current DB membership until the caller completes the audited read.
 -- hp_actor_roles is NEVER an authorization source (the audit helper owns its capture).
 SELECT @roles=m.roles FROM dbo.memberships m WITH(HOLDLOCK)
 WHERE m.tenant_id=@tenant AND m.user_id=@actor AND m.status='ACTIVE';
 IF @tenant IS NULL OR @roles IS NULL
  OR NOT EXISTS(SELECT 1 FROM OPENJSON(@roles) WHERE type=1 AND value COLLATE Latin1_General_100_BIN2 IN (N'ADM',N'REC'))
  OR EXISTS(SELECT 1 FROM OPENJSON(@roles) WHERE type=1 AND value COLLATE Latin1_General_100_BIN2 IN (N'PAC',N'RES'))
  THROW 51001,N'HP_FORBIDDEN:Internal administrative membership required',1;
 IF @patient_id IS NULL OR TRY_CONVERT(uniqueidentifier,@patient_id) IS NULL
  OR @patient_id COLLATE Latin1_General_100_BIN2<>LOWER(CONVERT(char(36),TRY_CONVERT(uniqueidentifier,@patient_id))) COLLATE Latin1_General_100_BIN2
  THROW 51000,N'HP_INVALID:Canonical patient UUID required',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.patients WITH(HOLDLOCK) WHERE tenant_id=@tenant AND id=@patient_id)
  THROW 51002,N'HP_NOT_FOUND:Paciente no disponible en este espacio',1;
 SET @limit=CASE WHEN @limit IS NULL THEN 50 WHEN @limit<1 THEN 1 WHEN @limit>200 THEN 200 ELSE @limit END;
 SET @offset=CASE WHEN @offset IS NULL OR @offset<0 THEN 0 ELSE @offset END;
 EXEC dbo.usp_audit_event @tenant_id=@tenant,@action=N'PATIENT_LINKS_READ',@target_id=@patient_id,@metadata=N'{}';
 -- Linked identities ONLY. Historical account/membership state does not hide a link.
 -- active describes the link; this read grants no portal, clinical or scope access.
 SELECT l.tenant_id,l.patient_id,l.user_id,u.name AS user_name,l.relationship,l.active,l.scopes
 FROM dbo.patient_links l
 JOIN dbo.users u ON u.id=l.user_id
 WHERE l.tenant_id=@tenant AND l.patient_id=@patient_id
 ORDER BY u.name,u.id
 OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY;
END;
GO
GRANT EXECUTE ON OBJECT::dbo.usp_patient_links_list TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_patient_links_list TO hp_bootstrap_executor;
GO
