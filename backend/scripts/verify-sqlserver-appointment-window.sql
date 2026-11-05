-- R-A36-SQL-WINDOW / SQL2022 administrative synthetic QA only; NOT runtime/JDBC authentication.
-- From REPOSITORY ROOT, fixed phase on a fresh connection:
-- sqlcmd -S localhost -E -C -b -f 65001 -d health_project_sqlserver_qa_20261103 -v A36Phase=exact93 -i backend/scripts/verify-sqlserver-appointment-window.sql
-- All phases: exact93,day93hour23,below94,reject94,reversed,equal,deny_unassigned,deny_foreign.
-- Run embedded stdlib runner from repository root (creates NO helper/log file):
-- $qaText=Get-Content backend/scripts/verify-sqlserver-appointment-window.sql -Raw -Encoding UTF8
-- $qaRunner=[regex]::Match($qaText,'(?s)-- A36_RUNNER_BEGIN\r?\n/\*\r?\n(.*?)\r?\n\*/\r?\n-- A36_RUNNER_END').Groups[1].Value
-- if(!$qaRunner){throw 'Missing runner'}; $qaRunner | python -B -
-- if($LASTEXITCODE -ne 0){throw 'A36 QA failed'}
-- :r path is trusted/local and relative to repository root. V9 is installed only inside
-- an EXTERNAL transaction, then rolled back in EVERY phase. No COMMIT, role, user,
-- login, grant, impersonation, service/transport change, trigger disabling or audit delete.
-- Expected errors are asserted by NUMBER and MESSAGE; ROLLBACK also handles doomed TX.
-- Python checks branch result rows and NEW-connection baseline before/after every phase,
-- even after failed sqlcmd. Never infer cleanup solely from an in-connection message.
:On Error exit
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
SET NOCOUNT ON;
IF DB_NAME()<>N'health_project_sqlserver_qa_20261103' THROW 59999,N'Wrong QA database',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'health_project_scope' AND CONVERT(nvarchar(max),value)=N'Health Project synthetic SQL Server migration QA; provisioned 2026-11-03; no real data') THROW 59999,N'Wrong QA marker',1;
IF DATABASE_PRINCIPAL_ID(N'dbo') IS NULL OR @@TRANCOUNT<>0
 OR (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo'))<>133
 OR (SELECT COUNT(*) FROM sys.triggers WHERE parent_class=1)<>31
 OR (SELECT COUNT(*) FROM sys.tables WHERE schema_id=SCHEMA_ID(N'dbo'))<>37 OR EXISTS(SELECT 1 FROM dbo.users)
 OR EXISTS(SELECT 1 FROM sys.database_principals WHERE name IN (N'hp_runtime_executor',N'hp_bootstrap_executor',N'hp_qa_runtime_a7',N'hp_qa_bootstrap_a7'))
 OR OBJECT_ID(N'dbo.hp_qa_future_a7') IS NOT NULL OR OBJECT_ID(N'dbo.hp_qa_future_procedure_a7') IS NOT NULL OR OBJECT_ID(N'dbo.hp_qa_unauthorized_a7') IS NOT NULL OR OBJECT_ID(N'dbo.flyway_schema_history') IS NOT NULL OR OBJECT_ID(N'dbo.hp_qa_unknown_history_a7') IS NOT NULL THROW 59999,N'Baseline/cleanup mismatch',1;
IF CONVERT(int,SERVERPROPERTY('ProductMajorVersion'))<>16 OR (SELECT compatibility_level FROM sys.databases WHERE name=DB_NAME())<>160 OR CONVERT(nvarchar(40),CONNECTIONPROPERTY('net_transport'))<>N'Shared memory' OR USER_NAME()<>N'dbo' THROW 59999,N'SQL2022 shared-memory administrative QA connection required',1;
IF EXISTS(SELECT 1 FROM sys.triggers WHERE parent_class=1 AND is_disabled=1) THROW 59999,N'Disabled QA trigger',1;
IF CHARINDEX(N'/86400000000>93',OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_appointments_list')))=0 THROW 59999,N'Expected unapplied V5 appointment window baseline',1;

IF N'$(A36Phase)' NOT IN (N'exact93',N'day93hour23',N'below94',N'reject94',N'reversed',N'equal',N'deny_unassigned',N'deny_foreign') THROW 59999,N'Unknown A36 phase',1;
SELECT p.object_id,p.name,HASHBYTES('SHA2_256',CONVERT(varbinary(max),m.definition)) fingerprint,
 m.uses_ansi_nulls,m.uses_quoted_identifier,m.execute_as_principal_id,p.principal_id
 INTO #a36_modules_before FROM sys.procedures p JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.schema_id=SCHEMA_ID(N'dbo');
SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state INTO #a36_acl_before FROM sys.database_permissions;
BEGIN TRANSACTION;
GO
:r "backend/src/main/resources/db/sqlserver/V9__appointment_window_days.sql"
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 59999,N'External transaction was lost',1;
IF EXISTS(SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM #a36_acl_before EXCEPT SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions)
 OR EXISTS(SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions EXCEPT SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM #a36_acl_before)
 THROW 59999,N'ALTER changed permissions',1;
IF EXISTS(SELECT object_id,name,fingerprint,uses_ansi_nulls,uses_quoted_identifier,execute_as_principal_id,principal_id FROM #a36_modules_before WHERE name<>N'usp_appointments_list'
 EXCEPT SELECT p.object_id,p.name,HASHBYTES('SHA2_256',CONVERT(varbinary(max),m.definition)),m.uses_ansi_nulls,m.uses_quoted_identifier,m.execute_as_principal_id,p.principal_id FROM sys.procedures p JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.schema_id=SCHEMA_ID(N'dbo') AND p.name<>N'usp_appointments_list')
 OR (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo'))<>133
 OR CHARINDEX(N'/CONVERT(bigint,86400000000)>93',OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_appointments_list')))=0
 THROW 59999,N'Unexpected procedure definition change',1;
SELECT N'DEFINITION_BEFORE',CONVERT(char(64),fingerprint,2) FROM #a36_modules_before WHERE name=N'usp_appointments_list';
SELECT N'DEFINITION_V9',CONVERT(char(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_appointments_list')))),2);
PRINT N'PASS ALTER ACL unchanged; other132 procedure definitions unchanged';
DECLARE @phase nvarchar(30)=N'$(A36Phase)',@expected int=0,@observed int=NULL,@message nvarchar(2048)=NULL,@error_state int=NULL;
DECLARE @actor char(36)='a3600001-0000-4000-8000-000000000001',@owner char(36)='a3600002-0000-4000-8000-000000000001',
 @tenant char(36)='a3600003-0000-4000-8000-000000000001',@other_tenant char(36)='a3600004-0000-4000-8000-000000000001',
 @branch char(36)='a3600005-0000-4000-8000-000000000001',@unassigned char(36)='a3600006-0000-4000-8000-000000000001',@foreign_branch char(36)='a3600007-0000-4000-8000-000000000001',
 @patient char(36)='a3600008-0000-4000-8000-000000000001',@foreign_patient char(36)='a3600009-0000-4000-8000-000000000001',
 @own_appointment char(36)='a3600010-0000-4000-8000-000000000001',@bound_appointment char(36)='a3600011-0000-4000-8000-000000000001',
 @other_appointment char(36)='a3600012-0000-4000-8000-000000000001',@unassigned_appointment char(36)='a3600013-0000-4000-8000-000000000001',
 @token char(64)=REPLICATE('b',64),@request char(36)='a3600014-0000-4000-8000-000000000001',@selected_branch char(36)=NULL,
 @from datetime2(6)='2026-01-01T00:00:00.000000',@to datetime2(6);
SET @to=DATEADD(day,93,@from);
IF @phase=N'day93hour23' SET @to=DATEADD(hour,23,@to);
IF @phase=N'below94' SET @to=DATEADD(microsecond,-1,DATEADD(day,94,@from));
IF @phase=N'reject94' BEGIN SET @to=DATEADD(day,94,@from);SET @expected=51000;END;
IF @phase=N'reversed' BEGIN SET @to=DATEADD(microsecond,-1,@from);SET @expected=51000;END;
IF @phase=N'equal' BEGIN SET @to=@from;SET @expected=51000;END;
IF @phase IN (N'deny_unassigned',N'deny_foreign') BEGIN SET @to=DATEADD(day,1,@from);SET @expected=51001;SET @selected_branch=CASE WHEN @phase=N'deny_unassigned' THEN @unassigned ELSE @foreign_branch END;END;
BEGIN TRY
 EXEC dbo.usp_request_context @request_id=NULL,@method=NULL,@route=NULL,@source_ip=NULL,@user_agent=NULL,@actor_id=NULL,@actor_roles=NULL,@tenant_id=NULL,@token_hash=NULL,@scope='REQUEST';
 IF NOT EXISTS(SELECT 1 FROM dbo.specialties WHERE code='H_FAMILY' AND domain='HUMAN') THROW 59999,N'Required accepted synthetic catalog seed missing',1;
 INSERT dbo.users(id,name,email,password_hash,clinical_domain) VALUES
 (@actor,N'Synthetic A36 reader',N'a36-reader@example.test',N'synthetic-not-a-login-hash','HUMAN'),(@owner,N'Synthetic A36 owner',N'a36-owner@example.test',N'synthetic-not-a-login-hash','HUMAN');
 INSERT dbo.tenants(id,name,slug,kind,domain,status,owner_user_id) VALUES
 (@tenant,N'Synthetic A36 own','qa-a36-own','CLINIC','HUMAN','ACTIVE',@owner),(@other_tenant,N'Synthetic A36 foreign','qa-a36-foreign','CLINIC','HUMAN','ACTIVE',@owner);
 INSERT dbo.branches(id,tenant_id,name) VALUES(@branch,@tenant,N'Synthetic assigned'),(@unassigned,@tenant,N'Synthetic unassigned'),(@foreign_branch,@other_tenant,N'Synthetic foreign');
 INSERT dbo.tenant_specialties(tenant_id,specialty_code) VALUES(@tenant,'H_FAMILY'),(@other_tenant,'H_FAMILY');
 INSERT dbo.memberships(tenant_id,user_id,roles,status,owner) VALUES(@tenant,@actor,N'["REC","PRO"]','ACTIVE',0),(@tenant,@owner,N'["ADM","PRO"]','ACTIVE',1),(@other_tenant,@owner,N'["ADM","PRO"]','ACTIVE',1);
 INSERT dbo.membership_branches(tenant_id,user_id,branch_id) VALUES(@tenant,@actor,@branch),(@tenant,@owner,@unassigned),(@other_tenant,@owner,@foreign_branch);
 INSERT dbo.membership_specialties(tenant_id,user_id,specialty_code) VALUES(@tenant,@actor,'H_FAMILY'),(@tenant,@owner,'H_FAMILY'),(@other_tenant,@owner,'H_FAMILY');
 INSERT dbo.auth_sessions(token_hash,user_id,tenant_id,expires_at,csrf_token) VALUES(@token,@actor,@tenant,DATEADD(hour,1,SYSUTCDATETIME()),REPLICATE('c',64));
 INSERT dbo.patients(id,tenant_id,name,domain,identifier,contact,allergies) VALUES(@patient,@tenant,N'Synthetic patient A','HUMAN',N'SYN-A36-A',N'{}',N'[]'),(@foreign_patient,@other_tenant,N'Synthetic patient B','HUMAN',N'SYN-A36-B',N'{}',N'[]');
 INSERT dbo.appointments(id,tenant_id,patient_id,branch_id,professional_id,specialty_code,starts_at,ends_at,status,service,note,request_key,request_hash) VALUES
 (@own_appointment,@tenant,@patient,@branch,@actor,'H_FAMILY',@from,DATEADD(minute,30,@from),'RESERVED',N'Synthetic service',N'Synthetic note','qa-a36-own',REPLICATE('a',64)),
 (@bound_appointment,@tenant,@patient,@branch,@actor,'H_FAMILY',@to,DATEADD(minute,30,@to),'RESERVED',N'Synthetic service',N'Synthetic bound','qa-a36-bound',REPLICATE('b',64)),
 (@unassigned_appointment,@tenant,@patient,@unassigned,@owner,'H_FAMILY',DATEADD(minute,120,@from),DATEADD(minute,150,@from),'RESERVED',N'Synthetic service',N'Synthetic unassigned','qa-a36-unassigned',REPLICATE('c',64)),
 (@other_appointment,@other_tenant,@foreign_patient,@foreign_branch,@owner,'H_FAMILY',DATEADD(minute,60,@from),DATEADD(minute,90,@from),'RESERVED',N'Synthetic service',N'Synthetic foreign','qa-a36-foreign',REPLICATE('d',64));
 EXEC dbo.usp_request_context @request_id=@request,@method=N'GET',@route=N'/api/appointments',@source_ip=N'127.0.0.1',@user_agent=N'Synthetic A36 QA',@actor_id=@actor,@actor_roles=N'["REC","PRO"]',@tenant_id=@tenant,@token_hash=@token,@scope='REQUEST';
 BEGIN TRY
  IF @expected=0
  BEGIN
   DECLARE @rows TABLE(id char(36),tenant_id char(36),patient_id char(36),branch_id char(36),professional_id char(36),specialty_code varchar(100),starts_at datetime2(6),ends_at datetime2(6),status nvarchar(9),service nvarchar(160),note nvarchar(1000),revision int,request_key varchar(100),request_hash char(64));
   -- NULL avoids the branch helper's internal INSERT EXEC nesting; it remains the real public SP.
   INSERT @rows EXEC dbo.usp_appointments_list @from=@from,@to=@to,@branch_id=NULL;
   IF (SELECT COUNT(*) FROM @rows)<>2 OR NOT EXISTS(SELECT 1 FROM @rows WHERE id=@own_appointment AND starts_at=@from)
    OR NOT EXISTS(SELECT 1 FROM @rows WHERE id=@unassigned_appointment) OR EXISTS(SELECT 1 FROM @rows WHERE tenant_id<>@tenant OR patient_id<>@patient OR id IN (@bound_appointment,@other_appointment))
    THROW 59999,N'Positive result/tenant/inclusive-from/exclusive-to assertion failed',1;
   PRINT N'PASS real list: own rows2;from inclusive;to exclusive;foreign row absent';
   -- Real branch guard call, with its 14-column result checked by the embedded runner.
   PRINT N'ROWS_OWN_BRANCH_BEGIN';
   EXEC dbo.usp_appointments_list @from=@from,@to=@to,@branch_id=@branch;
   PRINT N'ROWS_OWN_BRANCH_END';
  END
  ELSE EXEC dbo.usp_appointments_list @from=@from,@to=@to,@branch_id=@selected_branch;
 END TRY
 BEGIN CATCH
  SET @observed=ERROR_NUMBER();SET @message=ERROR_MESSAGE();SET @error_state=XACT_STATE();
 END CATCH;
 IF @expected=0 AND @observed IS NOT NULL BEGIN PRINT CONCAT(N'OBSERVED unexpected ',@observed,N' ',@message);THROW 59999,N'Unexpected positive procedure error',1;END;
 IF @expected<>0 AND (@observed IS NULL OR @observed<>@expected OR @message<>CASE WHEN @expected=51000 THEN N'HP_INVALID:Consulta como maximo 93 dias UTC' ELSE N'HP_FORBIDDEN:Sede no disponible para esta membresia' END)
  BEGIN PRINT CONCAT(N'OBSERVED mismatch ',COALESCE(@observed,-1),N' ',COALESCE(@message,N'NO ERROR'));THROW 59999,N'Expected exact public procedure error was not observed',1;END;
 PRINT CONCAT(N'OBSERVED ',COALESCE(@observed,0),N' XACT_STATE=',XACT_STATE(),N' EXPECTED=',@expected);
 IF @@TRANCOUNT<>1 THROW 59999,N'Caller transaction count changed',1;
 ROLLBACK TRANSACTION;
 EXEC dbo.usp_request_context @request_id=NULL,@method=NULL,@route=NULL,@source_ip=NULL,@user_agent=NULL,@actor_id=NULL,@actor_roles=NULL,@tenant_id=NULL,@token_hash=NULL,@scope='REQUEST';
 DECLARE @cleanup_count bigint,@cleanup_tx int,@cleanup_state int;
 SELECT @cleanup_count=COUNT_BIG(*) FROM dbo.users;
 SET @cleanup_tx=@@TRANCOUNT;SET @cleanup_state=XACT_STATE();
 PRINT CONCAT(N'CLEANUP_LOCAL users=',@cleanup_count,N' trancount=',@cleanup_tx,N' state=',@cleanup_state);
 IF @cleanup_tx<>0 OR @cleanup_state<>0 OR @cleanup_count<>0 THROW 59999,N'Rollback/user cleanup failed',1;
 IF EXISTS(SELECT object_id,name,fingerprint,uses_ansi_nulls,uses_quoted_identifier,execute_as_principal_id,principal_id FROM #a36_modules_before
 EXCEPT SELECT p.object_id,p.name,HASHBYTES('SHA2_256',CONVERT(varbinary(max),m.definition)),m.uses_ansi_nulls,m.uses_quoted_identifier,m.execute_as_principal_id,p.principal_id FROM sys.procedures p JOIN sys.sql_modules m ON m.object_id=p.object_id WHERE p.schema_id=SCHEMA_ID(N'dbo'))
 OR (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo'))<>133 THROW 59999,N'Procedure rollback mismatch',1;
 IF EXISTS(SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM #a36_acl_before EXCEPT SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions)
 OR EXISTS(SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions EXCEPT SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM #a36_acl_before) THROW 59999,N'Permission rollback mismatch',1;
 SELECT N'DEFINITION_RESTORED',CONVERT(char(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_appointments_list')))),2);
 PRINT CONCAT(N'A36 ',@phase,N' PASS;ROLLBACK performed;new-connection fingerprint still REQUIRED');
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 EXEC dbo.usp_request_context @request_id=NULL,@method=NULL,@route=NULL,@source_ip=NULL,@user_agent=NULL,@actor_id=NULL,@actor_roles=NULL,@tenant_id=NULL,@token_hash=NULL,@scope='REQUEST';
 THROW;
END CATCH;
GO

-- A36_RUNNER_BEGIN
/*
import subprocess,re,json
from pathlib import Path
baseline_sql="SET NOCOUNT ON;\nIF DB_NAME()<>N'health_project_sqlserver_qa_20261103' THROW 59999,N'Wrong QA database',1;\nIF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'health_project_scope' AND CONVERT(nvarchar(max),value)=N'Health Project synthetic SQL Server migration QA; provisioned 2026-11-03; no real data') THROW 59999,N'Wrong QA marker',1;\nIF DATABASE_PRINCIPAL_ID(N'dbo') IS NULL OR @@TRANCOUNT<>0\n OR (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo'))<>133\n OR (SELECT COUNT(*) FROM sys.triggers WHERE parent_class=1)<>31\n OR (SELECT COUNT(*) FROM sys.tables WHERE schema_id=SCHEMA_ID(N'dbo'))<>37 OR EXISTS(SELECT 1 FROM dbo.users)\n OR EXISTS(SELECT 1 FROM sys.database_principals WHERE name IN (N'hp_runtime_executor',N'hp_bootstrap_executor',N'hp_qa_runtime_a7',N'hp_qa_bootstrap_a7'))\n OR OBJECT_ID(N'dbo.hp_qa_future_a7') IS NOT NULL OR OBJECT_ID(N'dbo.hp_qa_future_procedure_a7') IS NOT NULL OR OBJECT_ID(N'dbo.hp_qa_unauthorized_a7') IS NOT NULL OR OBJECT_ID(N'dbo.flyway_schema_history') IS NOT NULL OR OBJECT_ID(N'dbo.hp_qa_unknown_history_a7') IS NOT NULL THROW 59999,N'Baseline/cleanup mismatch',1;\nIF CONVERT(int,SERVERPROPERTY('ProductMajorVersion'))<>16 OR (SELECT compatibility_level FROM sys.databases WHERE name=DB_NAME())<>160 OR CONVERT(nvarchar(40),CONNECTIONPROPERTY('net_transport'))<>N'Shared memory' OR USER_NAME()<>N'dbo' THROW 59999,N'SQL2022 shared-memory administrative QA connection required',1;\nIF EXISTS(SELECT 1 FROM sys.triggers WHERE parent_class=1 AND is_disabled=1) THROW 59999,N'Disabled QA trigger',1;\nIF CHARINDEX(N'/86400000000>93',OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_appointments_list')))=0 THROW 59999,N'Expected unapplied V5 appointment window baseline',1;\nDECLARE @counts nvarchar(max)=(SELECT name,n FROM (SELECT N'users' name,COUNT_BIG(*) n FROM dbo.[users]\nUNION ALL\nSELECT N'plans' name,COUNT_BIG(*) n FROM dbo.[plans]\nUNION ALL\nSELECT N'plan_versions' name,COUNT_BIG(*) n FROM dbo.[plan_versions]\nUNION ALL\nSELECT N'tenants' name,COUNT_BIG(*) n FROM dbo.[tenants]\nUNION ALL\nSELECT N'subscriptions' name,COUNT_BIG(*) n FROM dbo.[subscriptions]\nUNION ALL\nSELECT N'specialties' name,COUNT_BIG(*) n FROM dbo.[specialties]\nUNION ALL\nSELECT N'tenant_specialties' name,COUNT_BIG(*) n FROM dbo.[tenant_specialties]\nUNION ALL\nSELECT N'branches' name,COUNT_BIG(*) n FROM dbo.[branches]\nUNION ALL\nSELECT N'areas' name,COUNT_BIG(*) n FROM dbo.[areas]\nUNION ALL\nSELECT N'memberships' name,COUNT_BIG(*) n FROM dbo.[memberships]\nUNION ALL\nSELECT N'membership_branches' name,COUNT_BIG(*) n FROM dbo.[membership_branches]\nUNION ALL\nSELECT N'membership_specialties' name,COUNT_BIG(*) n FROM dbo.[membership_specialties]\nUNION ALL\nSELECT N'auth_sessions' name,COUNT_BIG(*) n FROM dbo.[auth_sessions]\nUNION ALL\nSELECT N'audit_events' name,COUNT_BIG(*) n FROM dbo.[audit_events]\nUNION ALL\nSELECT N'saas_invoices' name,COUNT_BIG(*) n FROM dbo.[saas_invoices]\nUNION ALL\nSELECT N'patients' name,COUNT_BIG(*) n FROM dbo.[patients]\nUNION ALL\nSELECT N'patient_links' name,COUNT_BIG(*) n FROM dbo.[patient_links]\nUNION ALL\nSELECT N'appointments' name,COUNT_BIG(*) n FROM dbo.[appointments]\nUNION ALL\nSELECT N'encounters' name,COUNT_BIG(*) n FROM dbo.[encounters]\nUNION ALL\nSELECT N'clinical_entries' name,COUNT_BIG(*) n FROM dbo.[clinical_entries]\nUNION ALL\nSELECT N'documents' name,COUNT_BIG(*) n FROM dbo.[documents]\nUNION ALL\nSELECT N'finance_movements' name,COUNT_BIG(*) n FROM dbo.[finance_movements]\nUNION ALL\nSELECT N'stock_lots' name,COUNT_BIG(*) n FROM dbo.[stock_lots]\nUNION ALL\nSELECT N'stock_movements' name,COUNT_BIG(*) n FROM dbo.[stock_movements]\nUNION ALL\nSELECT N'stock_transfers' name,COUNT_BIG(*) n FROM dbo.[stock_transfers]\nUNION ALL\nSELECT N'hospital_resources' name,COUNT_BIG(*) n FROM dbo.[hospital_resources]\nUNION ALL\nSELECT N'admissions' name,COUNT_BIG(*) n FROM dbo.[admissions]\nUNION ALL\nSELECT N'workflow_cases' name,COUNT_BIG(*) n FROM dbo.[workflow_cases]\nUNION ALL\nSELECT N'workflow_history' name,COUNT_BIG(*) n FROM dbo.[workflow_history]\nUNION ALL\nSELECT N'workflow_definitions' name,COUNT_BIG(*) n FROM dbo.[workflow_definitions]\nUNION ALL\nSELECT N'request_traces' name,COUNT_BIG(*) n FROM dbo.[request_traces]\nUNION ALL\nSELECT N'identity_tokens' name,COUNT_BIG(*) n FROM dbo.[identity_tokens]\nUNION ALL\nSELECT N'mail_outbox' name,COUNT_BIG(*) n FROM dbo.[mail_outbox]\nUNION ALL\nSELECT N'support_tickets' name,COUNT_BIG(*) n FROM dbo.[support_tickets]\nUNION ALL\nSELECT N'support_comments' name,COUNT_BIG(*) n FROM dbo.[support_comments]\nUNION ALL\nSELECT N'application_state' name,COUNT_BIG(*) n FROM dbo.[application_state]\nUNION ALL\nSELECT N'health_samples' name,COUNT_BIG(*) n FROM dbo.[health_samples]) c ORDER BY name FOR JSON PATH);\nDECLARE @sp nvarchar(max)=(SELECT name,CONVERT(char(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(object_id))),2) fingerprint FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo') ORDER BY name FOR JSON PATH);\nDECLARE @tr nvarchar(max)=(SELECT name,CONVERT(char(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(object_id))),2) fingerprint FROM sys.triggers WHERE parent_class=1 ORDER BY name FOR JSON PATH);\nDECLARE @permissions nvarchar(max)=(SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions ORDER BY class,major_id,minor_id,grantee_principal_id,type FOR JSON PATH);\nDECLARE @principals nvarchar(max)=(SELECT principal_id,name,type,owning_principal_id FROM sys.database_principals ORDER BY principal_id FOR JSON PATH);\nDECLARE @members nvarchar(max)=(SELECT role_principal_id,member_principal_id FROM sys.database_role_members ORDER BY role_principal_id,member_principal_id FOR JSON PATH);\nDECLARE @flags nvarchar(max)=(SELECT o.name,o.principal_id,m.uses_ansi_nulls,m.uses_quoted_identifier,m.execute_as_principal_id FROM sys.sql_modules m JOIN sys.objects o ON o.object_id=m.object_id WHERE o.schema_id=SCHEMA_ID(N'dbo') ORDER BY o.name FOR JSON PATH);\nDECLARE @enabled nvarchar(max)=(SELECT name,is_disabled FROM sys.triggers WHERE parent_class=1 ORDER BY name FOR JSON PATH);\nDECLARE @all nvarchar(max)=@principals+N'|'+@members+N'|'+@flags+N'|'+@enabled+N'|'+@counts+N'|'+@sp+N'|'+@tr+N'|'+@permissions;\nSELECT CONVERT(char(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@all)),2) baseline_fingerprint;"
common=['sqlcmd','-S','localhost','-E','-C','-b','-f','65001','-d','health_project_sqlserver_qa_20261103']
def baseline():
 r=subprocess.run(common+['-h','-1','-W','-Q',baseline_sql],capture_output=True,encoding='utf-8',errors='strict')
 print('BASELINE_EXIT',r.returncode,flush=True)
 if r.returncode:raise RuntimeError('BASELINE FAIL '+r.stdout+r.stderr)
 matches=re.findall(r'(?m)^[A-F0-9]{64}$',r.stdout.strip())
 assert len(matches)==1,r.stdout
 return matches[0]
v5=Path('backend/src/main/resources/db/sqlserver/V5__clinical_procedures.sql').read_text('utf-8')
v9=Path('backend/src/main/resources/db/sqlserver/V9__appointment_window_days.sql').read_text('utf-8')
old=re.search(r'CREATE PROCEDURE dbo\.usp_appointments_list\b.*?^GO\s*$',v5,re.M|re.S).group().strip()
new=re.search(r'ALTER PROCEDURE dbo\.usp_appointments_list\b.*?^GO\s*$',v9,re.M|re.S).group().strip()
assert new==old.replace('CREATE PROCEDURE','ALTER PROCEDURE',1).replace('/86400000000>93','/CONVERT(bigint,86400000000)>93'),'V9 not exact one-literal correction'
original=baseline();print('BASELINE',original,flush=True)
phases=['exact93','day93hour23','below94','reject94','reversed','equal','deny_unassigned','deny_foreign']
results=[]
for phase in phases:
 before=baseline();assert before==original,(phase,'before mismatch',before)
 r=subprocess.run(common+['-h','-1','-W','-s','|','-v','A36Phase='+phase,'-i','backend/scripts/verify-sqlserver-appointment-window.sql'],capture_output=True,encoding='utf-8',errors='strict')
 print('PHASE',phase,'RAW_EXIT',r.returncode,flush=True);print(r.stdout,flush=True)
 if r.stderr:print(r.stderr,flush=True)
 after=baseline();print('CLEANUP_NEW_CONNECTION',phase,after,flush=True);assert after==original,(phase,'after mismatch',after)
 results.append({'phase':phase,'exit':r.returncode,'before':before,'after':after,'stdout':r.stdout,'stderr':r.stderr})
 assert r.returncode==0,(phase,'unexpected sqlcmd exit',r.returncode)
 assert 'A36 '+phase+' PASS;' in r.stdout,(phase,'missing PASS')
 assert not re.search(r'Msg \d+,',r.stdout+r.stderr),(phase,'uncaught SQL error')
 if phase in phases[:3]:
  block=r.stdout.split('ROWS_OWN_BRANCH_BEGIN',1)[1].split('ROWS_OWN_BRANCH_END',1)[0]
  rows=[line.strip().split('|') for line in block.splitlines() if re.match(r'^[a-f0-9]{8}-',line.strip())]
  assert len(rows)==1 and len(rows[0])==14,(phase,'branch result shape',rows)
  assert rows[0][0]=='a3600010-0000-4000-8000-000000000001' and rows[0][1]=='a3600003-0000-4000-8000-000000000001',(phase,'foreign/bound result',rows)
  assert 'OBSERVED 0 XACT_STATE=1 EXPECTED=0' in r.stdout
 else:
  expected=51001 if phase.startswith('deny_') else 51000
  assert 'OBSERVED '+str(expected)+' XACT_STATE=-1 EXPECTED='+str(expected) in r.stdout,(phase,'expected engine error/state absent')
print('ALL8_PHASES_PASS',json.dumps(results,ensure_ascii=True),flush=True)

*/
-- A36_RUNNER_END
