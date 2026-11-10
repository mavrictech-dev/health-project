-- PAC-01.B1 engine QA PREPARED ONLY. NO_SQL_EXECUTED in the implementation Dispatch.
-- SQL2022 / fixed isolated database / separate CONTROL migration connection (-E), LPC only.
-- Execute ONLY the embedded controller after supervisor review, FROM REPOSITORY ROOT:
-- $text=Get-Content backend/scripts/verify-sqlserver-patient-links-read.sql -Raw -Encoding UTF8
-- $code=[regex]::Match($text,'(?s)-- B1_RUNNER_BEGIN\r?\n/\*\r?\n(.*?)\r?\n\*/\r?\n-- B1_RUNNER_END').Groups[1].Value
-- if(!$code){throw 'Missing B1 controller'}
-- $code | python -B - PRE_APLICACION
-- Later, ONLY after independently authorized application of V13, NEW connection:
-- $code | python -B - AUTOCOMMIT_POST_APLICACION
-- POST without installed V13 emits PENDIENTE_POR_PRERREQUISITO and exits2, NEVER PASS.
-- PRE installs V13 and all fixtures/users in each phase's EXTERNAL transaction.
-- It NEVER commits. Each negative uses a NEW process/connection. Expected doomed
-- transactions are left to connection-close rollback; no unsafe REVERT while doomed.
-- Raw exit16/engine3998 is accepted ONLY with an exact expected error/state frame AND
-- identical NEW-connection baseline before/after. Other messages/exits are failures.
-- Fixed SQL test strings exercise actual SELECT/INSERT/DDL/private EXECUTE denials;
-- they are NOT request-driven dynamic SQL. No logins, real secrets, mail or API.
-- Global application mode is observed, NEVER changed. To test READ_ONLY in-engine,
-- the supervisor must independently prepare that QA state before a later PRE run;
-- a run reporting OPEN must not be presented as a READ_ONLY engine observation.
-- Existing PACQA patients are never used/updated; all B1 fixtures have fresh UUIDs.
-- Rollback removes fixture data/DDL; SQL identity allocator gaps are not undone.
-- Independent fingerprints compare existing row values/modules/ACL/principals,
-- excluding allocator counters. Do not treat ACL counts as business verification.
:On Error exit
THROW 59999,N'Use reviewed embedded B1 controller; raw whole-file execution is forbidden',1;
GO

-- B1_COMMON_BEGIN
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
SET IMPLICIT_TRANSACTIONS OFF;
-- Capture caller state before catalog/permission expressions open internal contexts.
DECLARE @commonTransactionCount int=@@TRANCOUNT;
DECLARE @commonTransactionState int=XACT_STATE();
IF DB_NAME() COLLATE Latin1_General_100_BIN2<>N'health_project_sqlserver_qa_isolated_20261105'
 OR CONVERT(nvarchar(128),SERVERPROPERTY('InstanceName'))<>N'HEALTHPROJECTQA'
 OR CONVERT(int,SERVERPROPERTY('ProductMajorVersion'))<>16
 OR (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID())<>160
 THROW 59999,N'B1 wrong isolated SQL2022 target',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'health_project_scope'
 AND CONVERT(nvarchar(4000),value) COLLATE Latin1_General_100_BIN2=N'Health Project isolated JDBC QA; provisioned 2026-11-05; no real data'
 AND DATALENGTH(CONVERT(nvarchar(4000),value))=138)
 THROW 59999,N'B1 isolated scope marker mismatch',1;
IF @commonTransactionCount<>0 OR @commonTransactionState<>0 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>1
 OR ISNULL(IS_ROLEMEMBER(N'hp_runtime_executor'),0)=1 OR ISNULL(IS_ROLEMEMBER(N'hp_bootstrap_executor'),0)=1
 THROW 59999,N'B1 separate CONTROL connection without transaction required',1;
-- B1_COMMON_END

-- B1_PRE_BEGIN
IF OBJECT_ID(N'dbo.usp_patient_links_list') IS NOT NULL
 OR DATABASE_PRINCIPAL_ID(N'hp_qa_b1_runtime') IS NOT NULL OR DATABASE_PRINCIPAL_ID(N'hp_qa_b1_bootstrap') IS NOT NULL
 OR OBJECT_ID(N'dbo.hp_qa_b1_unauthorized') IS NOT NULL
 THROW 59999,N'B1 prerequisite/collision: no existing object or principal is repurposed',1;
IF (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo'))<>133
 OR (SELECT COUNT(*) FROM sys.triggers WHERE parent_class=1)<>31
 THROW 59999,N'B1 expected accepted V1..V12 baseline',1;
SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state INTO #b1_acl_before FROM sys.database_permissions;
SELECT o.object_id,o.name,o.type,m.definition,m.uses_ansi_nulls,m.uses_quoted_identifier,m.execute_as_principal_id
 INTO #b1_modules_before FROM sys.sql_modules m JOIN sys.objects o ON o.object_id=m.object_id;
DECLARE @prior int=(SELECT COUNT(*) FROM #b1_acl_before WHERE grantee_principal_id IN (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor')));
IF @prior<>CASE WHEN OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NULL THEN 562 ELSE 571 END
 THROW 59999,N'B1 expected562/571 ACL baseline',1;
CREATE TABLE #b1_phase(phase varchar(40) NOT NULL);
INSERT #b1_phase VALUES('__B1_PHASE__');
BEGIN TRANSACTION;
GO
-- B1_INSTALL_MIGRATION
GO
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 59999,N'B1 external migration transaction lost',1;
DECLARE @entry int=OBJECT_ID(N'dbo.usp_patient_links_list',N'P'),@runtime int=DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),@bootstrap int=DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor');
IF @entry IS NULL OR (SELECT COUNT(*) FROM sys.database_permissions)<>(SELECT COUNT(*)+2 FROM #b1_acl_before)
 THROW 59999,N'B1 ACL cardinality delta must be exactly2',1;
IF EXISTS(SELECT * FROM #b1_acl_before EXCEPT SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions)
 OR EXISTS(SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions WHERE NOT(class=1 AND major_id=@entry) EXCEPT SELECT * FROM #b1_acl_before)
 THROW 59999,N'B1 original ACL changed',1;
IF (SELECT COUNT(*) FROM sys.database_permissions WHERE class=1 AND major_id=@entry AND minor_id=0 AND type='EX'
 AND ((grantee_principal_id=@runtime AND state='G') OR (grantee_principal_id=@bootstrap AND state='D')))<>2
 THROW 59999,N'B1 exact new runtime GRANT/bootstrap DENY required',1;
IF EXISTS(SELECT object_id,name,type,definition,uses_ansi_nulls,uses_quoted_identifier,execute_as_principal_id FROM #b1_modules_before
 EXCEPT SELECT o.object_id,o.name,o.type,m.definition,m.uses_ansi_nulls,m.uses_quoted_identifier,m.execute_as_principal_id FROM sys.sql_modules m JOIN sys.objects o ON o.object_id=m.object_id)
 OR (SELECT COUNT(*) FROM sys.sql_modules)<>(SELECT COUNT(*)+1 FROM #b1_modules_before)
 OR EXISTS(SELECT 1 FROM sys.sql_modules WHERE object_id=@entry AND execute_as_principal_id IS NOT NULL)
 THROW 59999,N'B1 only one caller-context module may be added',1;
DECLARE @columns TABLE(ordinal int,name sysname,type_id int,bytes int);
INSERT @columns VALUES(1,N'tenant_id',175,36),(2,N'patient_id',175,36),(3,N'user_id',175,36),(4,N'user_name',231,320),(5,N'relationship',231,160),(6,N'active',104,1),(7,N'scopes',231,-1);
IF EXISTS(SELECT 1 FROM sys.dm_exec_describe_first_result_set_for_object(@entry,0) WHERE error_number IS NOT NULL)
 OR EXISTS(SELECT ordinal,name,type_id,bytes FROM @columns EXCEPT SELECT column_ordinal,name,system_type_id,max_length FROM sys.dm_exec_describe_first_result_set_for_object(@entry,0) WHERE is_hidden=0)
 OR EXISTS(SELECT column_ordinal,name,system_type_id,max_length FROM sys.dm_exec_describe_first_result_set_for_object(@entry,0) WHERE is_hidden=0 EXCEPT SELECT ordinal,name,type_id,bytes FROM @columns)
 THROW 59999,N'B1 exact seven-column result contract required',1;
IF (SELECT COUNT(*) FROM sys.parameters WHERE object_id=@entry)<>3
 OR NOT EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=@entry AND parameter_id=1 AND name=N'@patient_id' AND system_type_id=175 AND max_length=36 AND is_output=0)
 OR NOT EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=@entry AND parameter_id=2 AND name=N'@limit' AND system_type_id=56 AND is_output=0)
 OR NOT EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=@entry AND parameter_id=3 AND name=N'@offset' AND system_type_id=56 AND is_output=0)
 THROW 59999,N'B1 positional signature mismatch',1;
CREATE USER hp_qa_b1_runtime WITHOUT LOGIN;
CREATE USER hp_qa_b1_bootstrap WITHOUT LOGIN;
ALTER ROLE hp_runtime_executor ADD MEMBER hp_qa_b1_runtime;
ALTER ROLE hp_bootstrap_executor ADD MEMBER hp_qa_b1_bootstrap;
DECLARE @phase varchar(40)=(SELECT phase FROM #b1_phase),@tag varchar(32)=REPLACE(LOWER(CONVERT(char(36),NEWID())),'-',''),
 @actor char(36)=LOWER(CONVERT(char(36),NEWID())),@owner char(36)=LOWER(CONVERT(char(36),NEWID())),
 @tenant char(36)=LOWER(CONVERT(char(36),NEWID())),@other char(36)=LOWER(CONVERT(char(36),NEWID())),
 @patient char(36)=LOWER(CONVERT(char(36),NEWID())),@empty char(36)=LOWER(CONVERT(char(36),NEWID())),
 @foreign char(36)=LOWER(CONVERT(char(36),NEWID())),@missing char(36)=LOWER(CONVERT(char(36),NEWID())),
 @request char(36)=LOWER(CONVERT(char(36),NEWID())),@token char(64),@roles nvarchar(max)=N'["ADM"]',
 @domain nvarchar(6)=N'HUMAN',@selected char(36),@expected int=51001,@message nvarchar(4000),@scope varchar(20)='REQUEST';
SET @token=CONVERT(char(64),HASHBYTES('SHA2_256',@tag),2);
IF @phase IN ('positive_rec','positive_animal') SET @roles=N'["REC"]';
IF @phase IN ('positive_animal','positive_animal_adm') SET @domain=N'ANIMAL';
IF @phase LIKE 'role[_]%' SET @roles=N'["'+UPPER(SUBSTRING(@phase,6,10))+N'"]';
IF @phase='mixed_adm_pac' SET @roles=N'["ADM","PAC"]';
IF @phase='mixed_rec_res' SET @roles=N'["REC","RES"]';
IF @phase IN ('scope_identity','scope_worker') SET @scope=CASE WHEN @phase='scope_identity' THEN 'IDENTITY' ELSE 'WORKER' END;
EXEC dbo.usp_request_context @request_id=@request,@method=N'GET',@route=N'/qa/pac-b1',@source_ip=N'127.0.0.1',@user_agent=N'B1 rollback-only fixture setup',@scope='REQUEST';
BEGIN TRY
 INSERT dbo.users(id,name,email,password_hash,active,email_verified,platform_role)
 VALUES(@actor,N'B1 actor',N'b1-'+@tag+N'-actor@qa.example.test',N'!B1-NON-LOGIN-FIXTURE!',CASE WHEN @phase='inactive_user' THEN 0 ELSE 1 END,CASE WHEN @phase='unverified' THEN 0 ELSE 1 END,CASE WHEN @phase='platform_sad' THEN N'SAD' WHEN @phase='platform_sop' THEN N'SOP' ELSE NULL END),
       (@owner,N'B1 owner',N'b1-'+@tag+N'-owner@qa.example.test',N'!B1-NON-LOGIN-FIXTURE!',1,1,NULL);
 INSERT dbo.tenants(id,name,slug,kind,domain,owner_user_id,status)
 VALUES(@tenant,N'B1 own','qa-b1-'+@tag,CASE WHEN @domain='ANIMAL' THEN 'VETERINARY' ELSE 'CLINIC' END,@domain,@owner,'SUSPENDED'),
       (@other,N'B1 other','qa-b1-other-'+@tag,'CLINIC','HUMAN',@owner,'SUSPENDED');
 -- No subscriptions or PORTAL module are created. Suspended own tenants must read.
 IF @phase<>'no_membership' INSERT dbo.memberships(tenant_id,user_id,roles,status) VALUES(@tenant,@actor,@roles,CASE WHEN @phase='inactive_membership' THEN 'INACTIVE' ELSE 'ACTIVE' END);
 INSERT dbo.auth_sessions(token_hash,user_id,tenant_id,expires_at,revoked)
 VALUES(@token,@actor,CASE WHEN @phase IN ('platform_sad','platform_sop','tenant_null') THEN NULL ELSE @tenant END,DATEADD(day,CASE WHEN @phase='expired' THEN -1 ELSE 1 END,SYSUTCDATETIME()),CASE WHEN @phase='revoked' THEN 1 ELSE 0 END);
 INSERT dbo.patients(id,tenant_id,name,domain,identifier,species,contact,allergies)
 VALUES(@patient,@tenant,N'B1 own',@domain,N'B1-'+@tag+N'-OWN',CASE WHEN @domain='ANIMAL' THEN N'B1 canino' ELSE NULL END,N'{}',N'[]'),
       (@empty,@tenant,N'B1 empty',@domain,N'B1-'+@tag+N'-EMPTY',NULL,N'{}',N'[]'),
       (@foreign,@other,N'B1 foreign','HUMAN',N'B1-'+@tag+N'-FOREIGN',NULL,N'{}',N'[]');
 DECLARE @i int=1,@n int=CASE WHEN @phase LIKE 'positive[_]%' THEN 205 ELSE 2 END,@linked char(36);
 WHILE @i<=@n
 BEGIN
  SET @linked=LOWER(CONVERT(char(36),NEWID()));
  INSERT dbo.users(id,name,email,password_hash,active,email_verified)
  VALUES(@linked,N'B1 group '+CONVERT(nvarchar(10),@i%7),N'b1-'+@tag+N'-'+CONVERT(nvarchar(10),@i)+N'@qa.example.test',N'!B1-NON-LOGIN-FIXTURE!',CASE WHEN @i%3=0 THEN 0 ELSE 1 END,1);
  IF @i%2=0 INSERT dbo.memberships(tenant_id,user_id,roles,status) VALUES(@tenant,@linked,N'["PAC"]','INACTIVE');
  INSERT dbo.patient_links(tenant_id,patient_id,user_id,relationship,active,scopes)
  VALUES(@tenant,@patient,@linked,N'B1 relationship',@i%2,N'["APPOINTMENTS","DOCUMENTS"]');
  SET @i+=1;
 END;
 INSERT dbo.patient_links(tenant_id,patient_id,user_id,relationship,active,scopes) VALUES(@other,@foreign,@owner,N'B1 foreign hidden',1,N'["BILLING"]');
 SET @selected=@patient;
 IF @phase='foreign_patient' SET @selected=@foreign;
 IF @phase='missing_patient' SET @selected=@missing;
 IF @phase='null_patient' SET @selected=NULL;
 IF @phase='uppercase_uuid' SET @selected='AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA';
 IF @phase='malformed_uuid' SET @selected='not-a-canonical-uuid';
 IF @phase IN ('foreign_patient','missing_patient') BEGIN SET @expected=51002; SET @message=N'HP_NOT_FOUND:Paciente no disponible en este espacio'; END;
 IF @phase IN ('null_patient','uppercase_uuid','malformed_uuid') BEGIN SET @expected=51000; SET @message=N'HP_INVALID:Canonical patient UUID required'; END;
 IF @phase IN ('deny_select','deny_insert','deny_private','deny_bootstrap') SET @expected=229;
 IF @phase='deny_ddl' SET @expected=262;
 DECLARE @ctxTenant char(36)=CASE WHEN @phase IN ('platform_sad','platform_sop','tenant_null') THEN NULL ELSE @tenant END,
         @ctxActor char(36)=CASE WHEN @phase='no_session' THEN NULL ELSE @actor END;
 -- Deliberately forged claims: ADM/REC positives claim SAD; role negatives claim ADM.
 -- Only DB roles can decide authorization.
 EXEC dbo.usp_request_context @request_id=@request,@method=N'GET',@route=N'/qa/pac-b1',@source_ip=N'127.0.0.1',@user_agent=N'B1 rollback-only verification',@actor_id=@ctxActor,@actor_roles=N'["ADM","REC","SAD"]',@tenant_id=@ctxTenant,@token_hash=@token,@scope=@scope;
 IF @phase='scope_lowercase' EXEC sys.sp_set_session_context @key=N'hp_scope',@value=N'request';
 IF @phase='scope_padding' EXEC sys.sp_set_session_context @key=N'hp_scope',@value=N'REQUEST ';
 IF @phase='positive_forged_claims' EXEC sys.sp_set_session_context @key=N'hp_actor_roles',@value=N'["PAC","SAD"]';
 IF @phase LIKE 'positive[_]%'
 BEGIN
  CREATE TABLE #b1_expected(ordinal bigint,tenant_id char(36) COLLATE Latin1_General_100_BIN2,patient_id char(36) COLLATE Latin1_General_100_BIN2,user_id char(36) COLLATE Latin1_General_100_BIN2,user_name nvarchar(160) COLLATE Latin1_General_100_BIN2,relationship nvarchar(80) COLLATE Latin1_General_100_BIN2,active bit,scopes nvarchar(max) COLLATE Latin1_General_100_BIN2);
  INSERT #b1_expected SELECT ROW_NUMBER() OVER(ORDER BY u.name,u.id),l.tenant_id,l.patient_id,l.user_id,u.name,l.relationship,l.active,l.scopes
  FROM dbo.patient_links l JOIN dbo.users u ON u.id=l.user_id WHERE l.tenant_id=@tenant AND l.patient_id=@patient;
  CREATE TABLE #b1_actual(ordinal int IDENTITY(1,1),tenant_id char(36) COLLATE Latin1_General_100_BIN2,patient_id char(36) COLLATE Latin1_General_100_BIN2,user_id char(36) COLLATE Latin1_General_100_BIN2,user_name nvarchar(160) COLLATE Latin1_General_100_BIN2,relationship nvarchar(80) COLLATE Latin1_General_100_BIN2,active bit,scopes nvarchar(max) COLLATE Latin1_General_100_BIN2);
  DECLARE @cases TABLE(n int PRIMARY KEY,lim int NULL,page_offset int NULL,wanted int,start_at int,empty bit,defaults bit);
  INSERT @cases VALUES(1,21,0,21,1,0,0),(2,21,20,21,21,0,0),(3,200,200,5,201,0,0),(4,201,0,200,1,0,0),
   (5,0,0,1,1,0,0),(6,-4,-2,1,1,0,0),(7,NULL,NULL,50,1,0,0),(8,20,-1,20,1,0,0),(9,21,2147483647,0,1,0,0),(10,50,0,50,1,0,1),(11,21,0,0,1,1,0);
  DECLARE @case int=1,@lim int,@off int,@wanted int,@start int,@emptyCase bit,@defaults bit,@readPatient char(36),@audit bigint=(SELECT COUNT_BIG(*) FROM dbo.audit_events WHERE action=N'PATIENT_LINKS_READ' AND request_id=@request);
  WHILE @case<=11
  BEGIN
   SELECT @lim=lim,@off=page_offset,@wanted=wanted,@start=start_at,@emptyCase=empty,@defaults=defaults FROM @cases WHERE n=@case;
   SET @readPatient=CASE WHEN @emptyCase=1 THEN @empty ELSE @patient END;
   TRUNCATE TABLE #b1_actual;
   EXECUTE AS USER=N'hp_qa_b1_runtime';
   IF @defaults=1 INSERT #b1_actual(tenant_id,patient_id,user_id,user_name,relationship,active,scopes) EXEC dbo.usp_patient_links_list @readPatient;
   ELSE INSERT #b1_actual(tenant_id,patient_id,user_id,user_name,relationship,active,scopes) EXEC dbo.usp_patient_links_list @readPatient,@lim,@off;
   REVERT;
   DECLARE @readTransactionCount int=@@TRANCOUNT;
   DECLARE @readTransactionState int=XACT_STATE();
   IF @readTransactionCount<>1 OR @readTransactionState<>1 OR (SELECT COUNT(*) FROM #b1_actual)<>@wanted THROW 59999,N'B1 paging/count/transaction assertion failed',1;
   IF @wanted>0 AND (EXISTS(SELECT ordinal+@start-1,tenant_id,patient_id,user_id,user_name,relationship,active,scopes FROM #b1_actual EXCEPT SELECT ordinal,tenant_id,patient_id,user_id,user_name,relationship,active,scopes FROM #b1_expected WHERE ordinal>=@start AND ordinal<@start+@wanted)
    OR EXISTS(SELECT ordinal,tenant_id,patient_id,user_id,user_name,relationship,active,scopes FROM #b1_expected WHERE ordinal>=@start AND ordinal<@start+@wanted EXCEPT SELECT ordinal+@start-1,tenant_id,patient_id,user_id,user_name,relationship,active,scopes FROM #b1_actual))
    THROW 59999,N'B1 deterministic ordering/projection/scopes assertion failed',1;
   IF (SELECT COUNT_BIG(*) FROM dbo.audit_events WHERE action=N'PATIENT_LINKS_READ' AND request_id=@request)<>@audit+@case
    OR EXISTS(SELECT 1 FROM dbo.audit_events WHERE action=N'PATIENT_LINKS_READ' AND request_id=@request AND (tenant_id IS NULL OR tenant_id<>@tenant OR actor_id IS NULL OR actor_id<>@actor OR metadata<>N'{}' OR target_id NOT IN (@patient,@empty)))
    THROW 59999,N'B1 exactly one minimal real-actor audit per valid read required',1;
   SET @case+=1;
  END;
  IF NOT EXISTS(SELECT 1 FROM #b1_expected WHERE active=0) OR NOT EXISTS(SELECT 1 FROM #b1_expected e JOIN dbo.users u ON u.id=e.user_id WHERE u.active=0 AND e.active=1)
   THROW 59999,N'B1 historical/inactive reference fixture missing',1;
  ROLLBACK TRANSACTION;
  IF OBJECT_ID(N'dbo.usp_patient_links_list') IS NOT NULL OR DATABASE_PRINCIPAL_ID(N'hp_qa_b1_runtime') IS NOT NULL
   OR EXISTS(SELECT * FROM #b1_acl_before EXCEPT SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions)
   OR EXISTS(SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions EXCEPT SELECT * FROM #b1_acl_before)
   THROW 59999,N'B1 in-connection rollback mismatch',1;
  SELECT N'B1_RESULT'+(SELECT @phase phase,N'PASS' status,CAST(0 AS int) error,CAST(0 AS int) xact_state FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS b1_frame;
 END
 ELSE
 BEGIN
  IF @phase='deny_bootstrap' EXECUTE AS USER=N'hp_qa_b1_bootstrap';
  ELSE EXECUTE AS USER=N'hp_qa_b1_runtime';
  BEGIN TRY
   IF @phase='deny_select' EXEC sys.sp_executesql N'SELECT id FROM dbo.patients WHERE id=@id;',N'@id char(36)',@patient;
   ELSE IF @phase='deny_insert' EXEC sys.sp_executesql N'INSERT dbo.patients(id,tenant_id,name,domain,identifier,contact,allergies) VALUES(@id,@t,N''B1 denied'',N''HUMAN'',N''B1 denied'',N''{}'',N''[]'');',N'@id char(36),@t char(36)',@missing,@tenant;
   ELSE IF @phase='deny_ddl' EXEC(N'CREATE TABLE dbo.hp_qa_b1_unauthorized(id int NOT NULL);');
   ELSE IF @phase='deny_private' EXEC dbo.usp_require_actor;
   ELSE EXEC dbo.usp_patient_links_list @selected,21,0;
   THROW 59999,N'B1 negative unexpectedly succeeded',1;
  END TRY
  BEGIN CATCH
   IF ERROR_NUMBER()<>@expected OR (@message IS NOT NULL AND ERROR_MESSAGE()<>@message) THROW;
   DECLARE @state int=XACT_STATE();
   IF @state NOT IN (-1,1) THROW 59999,N'B1 unexpected negative transaction state',1;
   IF @state=1 BEGIN REVERT; ROLLBACK TRANSACTION; END;
   -- If doomed, keep impersonation/TX and immediately END the connection. The
   -- embedded controller requires engine3998 plus the exact error/state frame.
   SELECT N'B1_RESULT'+(SELECT @phase phase,N'PASS' status,@expected error,@state xact_state FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS b1_frame;
  END CATCH;
 END;
END TRY
BEGIN CATCH
 -- Never try REVERT under a doomed transaction. Connection closure is the boundary.
 IF XACT_STATE()=1 BEGIN IF USER_NAME() IN (N'hp_qa_b1_runtime',N'hp_qa_b1_bootstrap') REVERT; ROLLBACK TRANSACTION; END;
 THROW;
END CATCH;
-- B1_PRE_END

-- B1_POST_BEGIN
IF OBJECT_ID(N'dbo.usp_patient_links_list',N'P') IS NULL
 THROW 59999,N'B1 post-application prerequisite missing',1;
IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE name=N'hp_qa_runtime_20261105' AND type='S')
 OR (SELECT COUNT(*) FROM sys.database_role_members WHERE member_principal_id=DATABASE_PRINCIPAL_ID(N'hp_qa_runtime_20261105'))<>1
 OR NOT EXISTS(SELECT 1 FROM sys.database_role_members WHERE member_principal_id=DATABASE_PRINCIPAL_ID(N'hp_qa_runtime_20261105') AND role_principal_id=DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'))
 THROW 59999,N'B1 existing restricted runtime principal required',1;
DECLARE @audit bigint=(SELECT COUNT_BIG(*) FROM dbo.audit_events WHERE action=N'PATIENT_LINKS_READ');
EXECUTE AS USER=N'hp_qa_runtime_20261105';
DECLARE @runtimeTransactionCount int=@@TRANCOUNT;
DECLARE @runtimeTransactionState int=XACT_STATE();
IF IS_ROLEMEMBER(N'hp_runtime_executor')<>1 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>0
 OR IS_ROLEMEMBER(N'db_owner')=1 OR @runtimeTransactionCount<>0 OR @runtimeTransactionState<>0 OR (@@OPTIONS & 2)<>0
 THROW 59999,N'B1 restricted runtime/autocommit guard mismatch',1;
BEGIN TRY
 EXEC dbo.usp_patient_links_list '00000000-0000-0000-0000-000000000000',21,0;
 THROW 59999,N'B1 autocommit unexpectedly succeeded',1;
END TRY
BEGIN CATCH
 DECLARE @autocommitTransactionCount int=@@TRANCOUNT;
 DECLARE @autocommitTransactionState int=XACT_STATE();
 IF ERROR_NUMBER()<>51000 OR ERROR_MESSAGE()<>N'HP_INVALID:External transaction required' OR @autocommitTransactionState<>0 OR @autocommitTransactionCount<>0 THROW;
 REVERT;
 IF (SELECT COUNT_BIG(*) FROM dbo.audit_events WHERE action=N'PATIENT_LINKS_READ')<>@audit THROW 59999,N'B1 autocommit emitted audit',1;
 SELECT N'B1_RESULT'+(SELECT N'autocommit' phase,N'PASS' status,51000 error,0 xact_state FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS b1_frame;
END CATCH;
-- B1_POST_END

-- B1_RUNNER_BEGIN
/*
"""Reviewed future engine controller; NEVER executed during B1 implementation.
Run from repository root with exactly PRE_APLICACION or AUTOCOMMIT_POST_APLICACION.
Only Windows integrated migration transport by fixed local LPC; no TCP fallback.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

DATABASE = 'health_project_sqlserver_qa_isolated_20261105'
MIGRATION_SHA256 = '667D8C0731557625C662285DC0E56C885B57E50E7AFA5AF63EBEA2030E3ACF51'
PHASES = ('positive_adm', 'positive_rec', 'positive_animal', 'positive_animal_adm', 'positive_forged_claims',
 'foreign_patient', 'missing_patient', 'null_patient', 'uppercase_uuid', 'malformed_uuid',
 'platform_sad', 'platform_sop', 'tenant_null', 'role_pro', 'role_asi', 'role_aud', 'role_caj',
 'role_pac', 'role_res', 'role_dia', 'role_far', 'role_alm', 'mixed_adm_pac', 'mixed_rec_res',
 'revoked', 'expired', 'unverified', 'inactive_user', 'inactive_membership', 'no_membership',
 'no_session', 'scope_identity', 'scope_worker', 'scope_lowercase', 'scope_padding',
 'deny_select', 'deny_insert', 'deny_ddl', 'deny_private', 'deny_bootstrap')

class Failure(Exception):
    pass

def need(value, code):
    if not value:
        raise Failure(code)

def section(source, name):
    match = re.search(r'-- B1_' + name + r'_BEGIN\r?\n(.*?)\r?\n-- B1_' + name + r'_END', source, re.S)
    need(match is not None, 'SECTION_MISSING')
    return match.group(1)

def environment():
    need(not any(key.upper().startswith('SQLCMD') for key in os.environ), 'HOSTILE_SQLCMD_ENVIRONMENT')
    allowed = {'SYSTEMROOT','WINDIR','SYSTEMDRIVE','TEMP','TMP','PATH','COMSPEC','PATHEXT'}
    return {k:v for k,v in os.environ.items() if k.upper() in allowed}

def executable(env):
    for directory in next((v for k,v in env.items() if k.upper() == 'PATH'), '').split(';'):
        directory = Path(directory.strip().strip('"'))
        if directory.is_absolute() and (directory/'sqlcmd.exe').is_file():
            return str((directory/'sqlcmd.exe').resolve())
    raise Failure('SQLCMD_MISSING')

def invoke(exe, env, sql):
    return subprocess.run([exe, '-S', r'lpc:.\HEALTHPROJECTQA', '-d', DATABASE, '-E', '-C', '-b', '-V', '11', '-r', '1', '-f', '65001', '-y', '0', '-w', '65535', '-x', '-X1', '-l', '5', '-t', '120'], input=(':On Error exit\n'+sql+'\n').encode('utf-8'), capture_output=True, env=env, shell=False, timeout=300, creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))

def frame(raw, prefix):
    # -y0 preserves long JSON and cannot be combined with -h. Only the fixed
    # b1_frame header plus its separator may surround our ONE data line.
    # Some sqlcmd variants suppress that header with -y0; bare frames stay valid.
    try:
        text = raw.decode('utf-8-sig', errors='strict')
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        if len(lines) == 3 and lines[0] == 'b1_frame' and re.fullmatch(r'-{8,65535}', lines[1]):
            lines = lines[2:]
        need(len(lines) == 1 and lines[0].startswith(prefix), 'OUTPUT_FRAME_INVALID')
        def invalid_constant(_):
            raise ValueError('Non-JSON constant')
        value = json.loads(lines[0][len(prefix):], parse_constant=invalid_constant)
        need(type(value) is dict, 'OUTPUT_FRAME_INVALID')
        return value
    except (UnicodeError, ValueError, TypeError):
        raise Failure('OUTPUT_FRAME_INVALID') from None

# Hashes stay in SQL Server: no row values/credentials are exported or logged.
# Stable row ordering, module definitions, ACL grantors/states and memberships are
# compared from NEW connections, not inferred from rollback/row-count messages.
def baseline_sql(common):
    pieces = []
    for table, order in (('users','id'),('tenants','id'),('memberships','tenant_id,user_id'),
                        ('auth_sessions','token_hash'),('patients','tenant_id,id'),
                        ('patient_links','tenant_id,patient_id,user_id'),('audit_events','id'),('application_state','id')):
        pieces.append("CONVERT(varchar(64),HASHBYTES('SHA2_256',(SELECT * FROM dbo.["+table+"] ORDER BY "+order+" FOR JSON PATH,INCLUDE_NULL_VALUES)),2) AS ["+table+"]")
    pieces.extend([
     "CONVERT(varchar(64),HASHBYTES('SHA2_256',(SELECT o.object_id,o.name,o.type,m.definition,m.uses_ansi_nulls,m.uses_quoted_identifier,m.execute_as_principal_id FROM sys.objects o JOIN sys.sql_modules m ON m.object_id=o.object_id ORDER BY o.object_id FOR JSON PATH,INCLUDE_NULL_VALUES)),2) modules",
     "CONVERT(varchar(64),HASHBYTES('SHA2_256',(SELECT object_id,column_id,name,system_type_id,user_type_id,max_length,[precision],[scale],collation_name,is_nullable,is_identity FROM sys.columns ORDER BY object_id,column_id FOR JSON PATH,INCLUDE_NULL_VALUES)),2) columns",
     "CONVERT(varchar(64),HASHBYTES('SHA2_256',(SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions ORDER BY class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FOR JSON PATH)),2) acl",
     "CONVERT(varchar(64),HASHBYTES('SHA2_256',(SELECT principal_id,name,type,owning_principal_id,is_fixed_role,sid FROM sys.database_principals ORDER BY principal_id FOR JSON PATH,INCLUDE_NULL_VALUES)),2) principals",
     "CONVERT(varchar(64),HASHBYTES('SHA2_256',(SELECT role_principal_id,member_principal_id FROM sys.database_role_members ORDER BY role_principal_id,member_principal_id FOR JSON PATH)),2) role_memberships",
     "CASE WHEN OBJECT_ID(N'dbo.usp_patient_links_list',N'P') IS NULL THEN 0 ELSE 1 END installed",
     "(SELECT COUNT(*) FROM sys.database_permissions WHERE grantee_principal_id IN (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor'))) role_acl_count",
     "CASE WHEN OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NULL THEN 0 ELSE 1 END optional_history",
     "(SELECT mode FROM dbo.application_state WHERE id=1) application_mode"
    ])
    return common+"\nSELECT N'B1_BASELINE'+(SELECT "+',\n'.join(pieces)+" FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS b1_frame;"

def baseline(exe, env, sql):
    response = invoke(exe, env, sql)
    need(response.returncode == 0 and not response.stderr.strip(), 'BASELINE_FAILED')
    return frame(response.stdout, 'B1_BASELINE')

def validate_response(response, phase):
    value = frame(response.stdout, 'B1_RESULT')
    need(value.get('phase') == phase and value.get('status') == 'PASS', 'PHASE_ASSERTION_FAILED')
    need(type(value.get('error')) is int and type(value.get('xact_state')) is int, 'PHASE_FRAME_INVALID')
    if value['xact_state'] == -1:
        need(response.returncode == 16, 'DOOMED_EXIT_MISMATCH')
        text = response.stderr.decode('utf-8-sig', errors='strict').strip()
        # Accept ONLY the SQL Server batch-end rollback notification, never other errors.
        need(re.fullmatch(r'Msg 3998, Level 16, State \d+,(?: Server [^\r\n]+,)? Line \d+\r?\nUncommittable transaction is detected at the end of the batch\. The transaction is rolled back\.', text) is not None, 'UNEXPECTED_ENGINE_ERROR')
    else:
        need(response.returncode == 0 and not response.stderr.strip(), 'UNEXPECTED_ENGINE_EXIT')
        need(value['xact_state'] in (0,1), 'PHASE_STATE_INVALID')
    expected = 0 if phase.startswith('positive_') else 51000 if phase in ('null_patient','uppercase_uuid','malformed_uuid','autocommit') else 51002 if phase in ('foreign_patient','missing_patient') else 262 if phase == 'deny_ddl' else 229 if phase in ('deny_select','deny_insert','deny_private','deny_bootstrap') else 51001
    need(value['error'] == expected, 'EXPECTED_ERROR_MISMATCH')
    return {'phase':phase,'status':'PASS','rawExit':response.returncode,'error':value['error'],'xactState':value['xact_state'],'baselineRestored':True}

def main():
    need(len(sys.argv) == 2 and sys.argv[1] in ('PRE_APLICACION','AUTOCOMMIT_POST_APLICACION'), 'MODE_INVALID')
    need(os.name == 'nt', 'WINDOWS_INTEGRATED_TRANSPORT_REQUIRED')
    mode = sys.argv[1]
    root = Path.cwd().resolve()
    source = (root/'backend/scripts/verify-sqlserver-patient-links-read.sql').read_text(encoding='utf-8-sig')
    migration_path = root/'backend/src/main/resources/db/sqlserver/V13__patient_links_read.sql'
    raw_migration = migration_path.read_bytes()
    need(hashlib.sha256(raw_migration).hexdigest().upper() == MIGRATION_SHA256, 'REVIEWED_MIGRATION_CHANGED')
    common = section(source, 'COMMON')
    env = environment()
    exe = executable(env)
    snapshot_sql = baseline_sql(common)
    original = baseline(exe, env, snapshot_sql)
    expected_acl = (571 if original['optional_history'] else 562)+2*original['installed']
    need(original['role_acl_count'] == expected_acl, 'ACL_PREREQUISITE_MISMATCH')
    if mode == 'AUTOCOMMIT_POST_APLICACION' and not original['installed']:
        print(json.dumps({'mode':mode,'status':'PENDIENTE_POR_PRERREQUISITO','reason':'V13_NO_INSTALADA','checks':[]}))
        return 2
    need(mode != 'PRE_APLICACION' or not original['installed'], 'PRE_REQUIRES_UNAPPLIED_V13')
    phases = PHASES if mode == 'PRE_APLICACION' else ('autocommit',)
    controls = []
    for phase in phases:
        before = baseline(exe, env, snapshot_sql)
        need(before == original, 'BASELINE_DRIFT_BEFORE_PHASE')
        sql = section(source,'PRE' if mode == 'PRE_APLICACION' else 'POST')
        if mode == 'PRE_APLICACION':
            sql = sql.replace("'__B1_PHASE__'", "'"+phase+"'").replace('-- B1_INSTALL_MIGRATION',raw_migration.decode('utf-8-sig'))
        response = None
        failure = None
        try:
            response = invoke(exe, env, common+'\n'+sql)
        except Exception:
            failure = 'PHASE_TRANSPORT_FAILED'
        # Always verify connection-close cleanup, including after timeout/nonzero/compile failure.
        after = baseline(exe, env, snapshot_sql)
        need(after == original, 'BASELINE_DRIFT_AFTER_PHASE')
        need(failure is None, failure or 'PHASE_TRANSPORT_FAILED')
        controls.append(validate_response(response,phase))
    print(json.dumps({'mode':mode,'status':'PASS','checks':controls,'sqlBusinessProof':'real SP calls; ACL proof reported separately','autocommitPostApplicationPrerequisite':mode=='PRE_APLICACION','applicationModeObserved':original['application_mode']}))
    return 0

if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except Exception as error:
        # Do not dump engine stderr, row values, SQL statements or credentials.
        code = str(error) if isinstance(error,Failure) else 'CONTROLLER_FAILED'
        print(json.dumps({'status':'FAIL','code':code}))
        raise SystemExit(1)
*/
-- B1_RUNNER_END
