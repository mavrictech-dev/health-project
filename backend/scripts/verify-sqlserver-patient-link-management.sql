-- C1P2 PREPARATION ONLY. Never execute this whole file or apply/commit V14 here.
:On Error exit
THROW 59999,N'Use the separately reviewed C1P2 PRE_APLICACION controller',1;
GO
/* Templates only: raw whole-file execution cannot reach any following SQL.
-- C1P2_COMMON_BEGIN
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
SET IMPLICIT_TRANSACTIONS OFF;
DECLARE @entry_count int=@@TRANCOUNT,@entry_state int=XACT_STATE();
IF DB_NAME() COLLATE Latin1_General_100_BIN2<>N'health_project_sqlserver_qa_isolated_20261105'
 OR CONVERT(nvarchar(128),SERVERPROPERTY('InstanceName')) COLLATE Latin1_General_100_BIN2<>N'HEALTHPROJECTQA'
 OR ISNULL(TRY_CONVERT(int,SERVERPROPERTY('ProductMajorVersion')),0)<>16
 OR (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID())<>160
 OR CONVERT(nvarchar(40),CONNECTIONPROPERTY('net_transport'))<>N'Shared memory'
 THROW 59999,N'C1P2 wrong isolated SQL2022 LPC target',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'health_project_scope'
 AND CONVERT(nvarchar(max),value) COLLATE Latin1_General_100_BIN2=N'Health Project isolated JDBC QA; provisioned 2026-11-05; no real data'
 AND DATALENGTH(CONVERT(nvarchar(max),value))=138)
 THROW 59999,N'C1P2 isolated marker prerequisite',1;
IF @entry_count<>0 OR @entry_state<>0 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>1
 OR ISNULL(IS_ROLEMEMBER(N'hp_runtime_executor'),0)=1 OR ISNULL(IS_ROLEMEMBER(N'hp_bootstrap_executor'),0)=1
 THROW 59999,N'C1P2 separate CONTROL connection prerequisite',1;
IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE name COLLATE Latin1_General_100_BIN2=N'dbo' AND DATALENGTH(name)=6 AND principal_id=1)
 OR NOT EXISTS(SELECT 1 FROM sys.database_principals p JOIN sys.databases d ON d.database_id=DB_ID() AND p.sid=d.owner_sid
 WHERE p.principal_id=1 AND p.name COLLATE Latin1_General_100_BIN2=N'dbo' AND DATALENGTH(p.name)=6 AND DATALENGTH(p.sid)>0
 AND (p.type='S' AND p.authentication_type=1 OR p.type='U' AND p.authentication_type=3))
 THROW 59999,N'C1P2 accepted dbo owner prerequisite',1;
IF OBJECT_ID(N'dbo.usp_patient_links_list',N'P') IS NULL
 OR OBJECT_ID(N'dbo.usp_patient_link_edit_get') IS NOT NULL OR COL_LENGTH(N'dbo.patient_links',N'revision') IS NOT NULL
 OR OBJECT_ID(N'dbo.DF_patient_links_revision') IS NOT NULL OR OBJECT_ID(N'dbo.CK_patient_links_revision') IS NOT NULL
 OR DATABASE_PRINCIPAL_ID(N'hp_qa_c1p2_runtime') IS NOT NULL OR DATABASE_PRINCIPAL_ID(N'hp_qa_c1p2_bootstrap') IS NOT NULL
 OR OBJECT_ID(N'dbo.hp_qa_c1p2_denied') IS NOT NULL OR OBJECT_ID(N'dbo.hp_qa_c1p2_audit_failure') IS NOT NULL
 THROW 59999,N'C1P2 unapplied V14 and collision-free namespace prerequisite',1;
IF (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo'))<>134
 OR (SELECT COUNT(*) FROM sys.triggers WHERE parent_class=1)<>31
 OR (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0)<>CASE WHEN OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NULL THEN 37 ELSE 38 END
 OR EXISTS(SELECT 1 FROM sys.tables WHERE is_ms_shipped=0 AND schema_id<>SCHEMA_ID(N'dbo'))
 OR EXISTS(SELECT 1 FROM sys.sql_modules WHERE definition IS NULL)
 OR (SELECT COUNT(*) FROM sys.database_principals WHERE name IN (N'hp_runtime_executor',N'hp_bootstrap_executor') AND type='R' AND owning_principal_id=1)<>2
 OR (SELECT COUNT(*) FROM sys.database_permissions WHERE grantee_principal_id IN (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor')))
 <>CASE WHEN OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NULL THEN 564 ELSE 573 END
 THROW 59999,N'C1P2 accepted134SP31triggers role ACL prerequisite',1;
IF NOT EXISTS(SELECT 1 FROM dbo.application_state WHERE id=1 AND mode COLLATE Latin1_General_100_BIN2=N'OPEN' AND DATALENGTH(mode)=8)
 THROW 59999,N'C1P2 OPEN prerequisite; global state is never changed',1;
-- C1P2_COMMON_END

-- C1P2_BASELINE_BEGIN
-- All37 user tables are hashed in-engine by closed canonical PKs. No row,
-- password hash, session material or module definition leaves the database.
__BASELINE_SHAPE_GUARDS__
DECLARE @fingerprints nvarchar(max)=(SELECT __FINGERPRINTS_SQL__ FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
SELECT N'C1P2_BASELINE'+(SELECT N'BASELINE' kind,N'PRE_APLICACION' mode,N'__NONCE__' nonce,N'PASS' status,
 CAST(134 AS int) sp_count,CAST(31 AS int) trigger_count,
 (SELECT COUNT(*) FROM sys.database_permissions WHERE grantee_principal_id IN (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor'))) role_acl_count,
 CAST(CASE WHEN OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NULL THEN 0 ELSE 1 END AS bit) optional_history,
 N'OPEN' application_mode,JSON_QUERY(@fingerprints) fingerprints,
 REPLICATE(CAST(N'🦷中' AS nvarchar(max)),3000) probe FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS c1p2_frame;
-- C1P2_BASELINE_END

-- C1P2_PRE_BEGIN
SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state INTO #c1p2_acl_before FROM sys.database_permissions;
SELECT o.object_id,o.name,o.type,m.definition,m.uses_ansi_nulls,m.uses_quoted_identifier,m.execute_as_principal_id
 INTO #c1p2_modules_before FROM sys.sql_modules m JOIN sys.objects o ON o.object_id=m.object_id;
CREATE TABLE #c1p2_phase(name varchar(80) NOT NULL);
INSERT #c1p2_phase VALUES('__PHASE__');
BEGIN TRANSACTION;
GO
-- C1P2_PRE_END

-- C1P2_AFTER_V14_BEGIN
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 59999,N'C1P2 external V14 transaction lost',1;
DECLARE @edit_object int=OBJECT_ID(N'dbo.usp_patient_link_edit_get',N'P'),@writer_object int=OBJECT_ID(N'dbo.usp_patient_link_save',N'P');
IF @edit_object IS NULL OR (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo'))<>135
 OR (SELECT COUNT(*) FROM sys.triggers WHERE parent_class=1)<>31
 OR (SELECT COUNT(*) FROM sys.database_permissions)<>(SELECT COUNT(*)+2 FROM #c1p2_acl_before)
 OR EXISTS(SELECT * FROM #c1p2_acl_before EXCEPT SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions)
 OR EXISTS(SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions WHERE major_id<>@edit_object OR class<>1 EXCEPT SELECT * FROM #c1p2_acl_before)
 OR (SELECT COUNT(*) FROM sys.database_permissions WHERE class=1 AND major_id=@edit_object AND minor_id=0 AND type='EX'
 AND (grantee_principal_id=DATABASE_PRINCIPAL_ID(N'hp_runtime_executor') AND state='G' OR grantee_principal_id=DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor') AND state='D'))<>2
 THROW 59999,N'C1P2 exact one SP and two object ACL delta required',1;
IF EXISTS(SELECT object_id,name,type,definition,uses_ansi_nulls,uses_quoted_identifier,execute_as_principal_id FROM #c1p2_modules_before WHERE object_id<>@writer_object
 EXCEPT SELECT o.object_id,o.name,o.type,m.definition,m.uses_ansi_nulls,m.uses_quoted_identifier,m.execute_as_principal_id FROM sys.sql_modules m JOIN sys.objects o ON o.object_id=m.object_id)
 OR (SELECT COUNT(*) FROM sys.sql_modules)<>(SELECT COUNT(*)+1 FROM #c1p2_modules_before)
 OR EXISTS(SELECT 1 FROM sys.sql_modules WHERE object_id IN (@writer_object,@edit_object) AND execute_as_principal_id IS NOT NULL)
 THROW 59999,N'C1P2 only writer definition and new caller-context reader may change',1;
DECLARE @shape TABLE(object_id int,ordinal int,name sysname,type_id int,bytes int);
INSERT @shape VALUES
 (@writer_object,1,N'tenant_id',175,36),(@writer_object,2,N'patient_id',175,36),(@writer_object,3,N'user_id',175,36),(@writer_object,4,N'active',104,1),(@writer_object,5,N'revision',56,4),
 (@edit_object,1,N'tenant_id',175,36),(@edit_object,2,N'patient_id',175,36),(@edit_object,3,N'user_id',175,36),(@edit_object,4,N'user_name',231,320),(@edit_object,5,N'relationship',231,160),(@edit_object,6,N'active',104,1),(@edit_object,7,N'scopes',231,-1),(@edit_object,8,N'revision',56,4);
IF EXISTS(SELECT 1 FROM @shape s CROSS APPLY sys.dm_exec_describe_first_result_set_for_object(s.object_id,0) r WHERE r.error_number IS NOT NULL)
 OR EXISTS(SELECT * FROM @shape EXCEPT SELECT s.object_id,r.column_ordinal,r.name,r.system_type_id,r.max_length FROM (SELECT DISTINCT object_id FROM @shape) s CROSS APPLY sys.dm_exec_describe_first_result_set_for_object(s.object_id,0) r WHERE r.is_hidden=0)
 OR EXISTS(SELECT s.object_id,r.column_ordinal,r.name,r.system_type_id,r.max_length FROM (SELECT DISTINCT object_id FROM @shape) s CROSS APPLY sys.dm_exec_describe_first_result_set_for_object(s.object_id,0) r WHERE r.is_hidden=0 EXCEPT SELECT * FROM @shape)
 THROW 59999,N'C1P2 metadata must be ACK5 and edit8 exactly',1;
IF (SELECT COUNT(*) FROM sys.parameters WHERE object_id IN (@writer_object,@edit_object))<>4
 OR NOT EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=@writer_object AND parameter_id=1 AND name=N'@patient_id' AND system_type_id=175 AND max_length=36 AND is_output=0)
 OR NOT EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=@writer_object AND parameter_id=2 AND name=N'@input' AND system_type_id=231 AND max_length=-1 AND is_output=0)
 OR NOT EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=@edit_object AND parameter_id=1 AND name=N'@patient_id' AND system_type_id=175 AND max_length=36 AND is_output=0)
 OR NOT EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=@edit_object AND parameter_id=2 AND name=N'@user_id' AND system_type_id=175 AND max_length=36 AND is_output=0)
 THROW 59999,N'C1P2 exact positional management signatures required',1;
DECLARE @b int=OBJECT_ID(N'dbo.usp_patient_links_list',N'P');
IF (SELECT COUNT(*) FROM sys.dm_exec_describe_first_result_set_for_object(@b,0) WHERE is_hidden=0)<>7
 THROW 59999,N'C1P2 V13 seven columns must remain unchanged',1;
CREATE USER hp_qa_c1p2_runtime WITHOUT LOGIN;
CREATE USER hp_qa_c1p2_bootstrap WITHOUT LOGIN;
ALTER ROLE hp_runtime_executor ADD MEMBER hp_qa_c1p2_runtime;
ALTER ROLE hp_bootstrap_executor ADD MEMBER hp_qa_c1p2_bootstrap;
CREATE TABLE #c1p2_fixture(actor char(36),owner_id char(36),target_id char(36),tenant char(36),other_tenant char(36),patient char(36),foreign_patient char(36),missing_id char(36),plan_id char(36),token char(64),tag varchar(32));
INSERT #c1p2_fixture SELECT LOWER(CONVERT(char(36),NEWID())),LOWER(CONVERT(char(36),NEWID())),LOWER(CONVERT(char(36),NEWID())),LOWER(CONVERT(char(36),NEWID())),LOWER(CONVERT(char(36),NEWID())),LOWER(CONVERT(char(36),NEWID())),LOWER(CONVERT(char(36),NEWID())),LOWER(CONVERT(char(36),NEWID())),LOWER(CONVERT(char(36),NEWID())),LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',CONVERT(nvarchar(36),NEWID())),2)),REPLACE(LOWER(CONVERT(char(36),NEWID())),'-','');
GO
-- C1P2_AFTER_V14_END

-- C1P2_AUDIT_FAILURE_BEGIN
-- New transient auxiliary trigger only, after V14 delta checks. V7/helper stay unchanged.
CREATE TRIGGER dbo.hp_qa_c1p2_audit_failure ON dbo.audit_events AFTER INSERT AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(SELECT 1 FROM inserted WHERE action IN (N'PORTAL_LINK_CHANGED',N'PATIENT_LINK_EDIT_READ') AND user_agent=N'C1P2_INJECT_AUDIT_FAILURE')
  THROW 59998,N'C1P2 expected transient semantic audit failure',1;
END;
GO
-- C1P2_AUDIT_FAILURE_END

-- C1P2_CASE_BEGIN
DECLARE @actor char(36),@owner char(36),@target char(36),@tenant char(36),@other char(36),@patient char(36),@foreign char(36),@missing char(36),@plan char(36),@token char(64),@tag varchar(32);
SELECT @actor=actor,@owner=owner_id,@target=target_id,@tenant=tenant,@other=other_tenant,@patient=patient,@foreign=foreign_patient,@missing=missing_id,@plan=plan_id,@token=token,@tag=tag FROM #c1p2_fixture;
DECLARE @phase varchar(80)=(SELECT name FROM #c1p2_phase),@domain nvarchar(6)=N'__DOMAIN__',@actor_roles nvarchar(max)=N'__ACTOR_ROLES__',@target_roles nvarchar(max)=N'__TARGET_ROLES__';
EXEC dbo.usp_request_context @scope='REQUEST',@user_agent=N'C1P2 rollback-only fixture setup';
INSERT dbo.users(id,name,email,password_hash,active,email_verified) VALUES
 (@actor,N'C1P2 actor',N'c1p2-'+@tag+N'-actor@qa.example.test',N'!C1P2-NO-LOGIN!',1,1),
 (@owner,N'C1P2 owner',N'c1p2-'+@tag+N'-owner@qa.example.test',N'!C1P2-NO-LOGIN!',1,1),
 (@target,N'C1P2 中🦷',N'c1p2-'+@tag+N'-target@qa.example.test',N'!C1P2-NO-LOGIN!',1,1);
INSERT dbo.plans(id,name,description,status,current_version) VALUES(@plan,N'C1P2-'+@tag,N'Own rollback-only QA plan',N'PUBLISHED',1);
INSERT dbo.plan_versions(plan_id,version,base_minor,branch_minor,professional_minor,included_branches,included_professionals,included_specialties,max_branches,max_professionals,max_specialties,annual_discount,kinds,domains,modules)
 VALUES(@plan,1,0,0,0,1,1,1,2,2,2,0,N'["CLINIC","VETERINARY"]',N'["HUMAN","ANIMAL"]',N'["CORE","PORTAL"]');
INSERT dbo.tenants(id,name,slug,kind,domain,owner_user_id,status) VALUES
 (@tenant,N'C1P2 own',N'qa-c1p2-'+@tag,CASE WHEN @domain=N'ANIMAL' THEN N'VETERINARY' ELSE N'CLINIC' END,@domain,@owner,N'ACTIVE'),
 (@other,N'C1P2 other',N'qa-c1p2-other-'+@tag,N'CLINIC',N'HUMAN',@owner,N'ACTIVE');
INSERT dbo.subscriptions(tenant_id,plan_id,plan_version,cycle,branch_quota,professional_quota,specialty_quota,renewal_date) VALUES(@tenant,@plan,1,N'MONTHLY',1,1,1,DATEADD(day,30,CONVERT(date,SYSUTCDATETIME()))),(@other,@plan,1,N'MONTHLY',1,1,1,DATEADD(day,30,CONVERT(date,SYSUTCDATETIME())));
INSERT dbo.memberships(tenant_id,user_id,roles,status) VALUES(@tenant,@actor,@actor_roles,N'ACTIVE'),(@tenant,@target,@target_roles,N'ACTIVE');
INSERT dbo.auth_sessions(token_hash,user_id,tenant_id,expires_at,revoked) VALUES(@token,@actor,@tenant,DATEADD(day,1,SYSUTCDATETIME()),0);
INSERT dbo.patients(id,tenant_id,name,domain,identifier,species,contact,allergies) VALUES
 (@patient,@tenant,N'C1P2 patient',@domain,N'C1P2-'+@tag,CASE WHEN @domain=N'ANIMAL' THEN N'Synthetic' ELSE NULL END,N'{}',N'[]'),
 (@foreign,@other,N'C1P2 foreign',N'HUMAN',N'C1P2-foreign-'+@tag,NULL,N'{}',N'[]');
DECLARE @relationship nvarchar(max)=N'Tutor 🦷中',@scopes nvarchar(max)=N'["BILLING","DOCUMENTS","APPOINTMENTS"]',@selected char(36)=@patient,
 @ctx_actor char(36)=@actor,@ctx_tenant char(36)=@tenant,@scope varchar(20)='REQUEST',@claims nvarchar(max)=N'["PAC","SAD"]',
 @expected int=__EXPECTED_ERROR__,@scenario varchar(20)='__SCENARIO__',@operation varchar(24)='__OPERATION__',@input nvarchar(max),@request char(36),@checks int=0,@cutoff bigint,
 @reported_error int=0,@reported_state int=0,@cleanup nvarchar(12)=N'EXPLICIT',@agent nvarchar(100)=N'C1P2 runtime verification';
__FIXTURE_SQL__
SET @input=N'{"userId":"'+@target+N'","expectedRevision":0,"relationship":"'+STRING_ESCAPE(@relationship,'json')+N'","active":true,"scopes":'+@scopes+N'}';
__INPUT_SQL__
IF @expected=59998 SET @agent=N'C1P2_INJECT_AUDIT_FAILURE';
-- Audit cutoff AFTER all fixtures/configuration; setup events are never command evidence.
SET @cutoff=(SELECT ISNULL(MAX(id),0) FROM dbo.audit_events);
DECLARE @commands TABLE(ordinal int PRIMARY KEY,payload nvarchar(max),active bit,previous_revision int,revision int);
IF @scenario='sequence'
BEGIN
 INSERT @commands VALUES
 (1,@input,1,0,1),
 (2,N'{"userId":"'+@target+N'","expectedRevision":1,"relationship":"Changed","active":true,"scopes":["DOCUMENTS","APPOINTMENTS"]}',1,1,2),
 (3,N'{"userId":"'+@target+N'","expectedRevision":2,"relationship":"Changed","active":true,"scopes":["DOCUMENTS","APPOINTMENTS"]}',1,2,3),
 (4,N'{"userId":"'+@target+N'","expectedRevision":3,"active":false}',0,3,4),
 (5,N'{"userId":"'+@target+N'","expectedRevision":4,"active":false}',0,4,5),
 (6,N'{"userId":"'+@target+N'","expectedRevision":5,"relationship":"'+STRING_ESCAPE(@relationship,'json')+N'","active":true,"scopes":'+@scopes+N'}',1,5,6);
END;
IF @scenario='history' INSERT @commands VALUES(1,N'{"userId":"'+@target+N'","expectedRevision":7,"active":false}',0,7,8);
IF @scenario='one_set' INSERT @commands VALUES(1,@input,1,0,1);
IF @scenario='sequential_stale' INSERT @commands VALUES(1,@input,1,0,1);
DECLARE @meta_keys TABLE([key] nvarchar(40) COLLATE Latin1_General_100_BIN2,[type] int);
INSERT @meta_keys VALUES(N'userId',1),(N'active',3),(N'previousRevision',2),(N'revision',2),(N'operation',1);
DECLARE @ack TABLE(tenant_id char(36),patient_id char(36),user_id char(36),active bit,revision int);
DECLARE @edit TABLE(tenant_id char(36),patient_id char(36),user_id char(36),user_name nvarchar(160),relationship nvarchar(80),active bit,scopes nvarchar(max),revision int);
BEGIN TRY
 DECLARE @ordinal int=1,@payload nvarchar(max),@want_active bit,@previous int,@want_revision int,@old_relation nvarchar(max),@old_scopes nvarchar(max),@old_active bit,@row_action nvarchar(40),@projected_change int,@meta nvarchar(max);
 WHILE EXISTS(SELECT 1 FROM @commands WHERE ordinal=@ordinal)
 BEGIN
  SELECT @payload=payload,@want_active=active,@previous=previous_revision,@want_revision=revision FROM @commands WHERE ordinal=@ordinal;
  SET @old_relation=NULL;SET @old_scopes=NULL;SET @old_active=NULL;
  SELECT @old_relation=relationship,@old_scopes=scopes,@old_active=active FROM dbo.patient_links WHERE tenant_id=@tenant AND patient_id=@patient AND user_id=@target;
  SET @request=LOWER(CONVERT(char(36),NEWID()));
  EXEC dbo.usp_request_context @request_id=@request,@method=N'PUT',@route=N'/qa/c1p2/link',@actor_id=@actor,@actor_roles=@claims,@tenant_id=@tenant,@token_hash=@token,@scope='REQUEST',@user_agent=@agent;
  DELETE FROM @ack;
  EXECUTE AS USER=N'hp_qa_c1p2_runtime';
  IF USER_NAME()<>N'hp_qa_c1p2_runtime' THROW 59999,N'C1P2 limited principal required',1;
  INSERT @ack EXEC dbo.usp_patient_link_save @patient,@payload;
  IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 59999,N'C1P2 positive lost external committable TX',1;
  REVERT;
  IF (SELECT COUNT(*) FROM @ack)<>1 OR NOT EXISTS(SELECT 1 FROM @ack WHERE tenant_id=@tenant AND patient_id=@patient AND user_id=@target AND active=@want_active AND revision=@want_revision)
   THROW 59999,N'C1P2 ACK5 identity state revision mismatch',1;
  IF NOT EXISTS(SELECT 1 FROM dbo.patient_links WHERE tenant_id=@tenant AND patient_id=@patient AND user_id=@target AND active=@want_active AND revision=@want_revision)
   OR (SELECT revision FROM dbo.patients WHERE tenant_id=@tenant AND id=@patient)<>1
   THROW 59999,N'C1P2 link row or patient revision mismatch',1;
  IF @want_active=0 AND NOT EXISTS(SELECT 1 FROM dbo.patient_links WHERE tenant_id=@tenant AND patient_id=@patient AND user_id=@target
   AND DATALENGTH(relationship)=DATALENGTH(@old_relation) AND CONVERT(varbinary(max),relationship)=CONVERT(varbinary(max),@old_relation)
   AND DATALENGTH(scopes)=DATALENGTH(@old_scopes) AND CONVERT(varbinary(max),scopes)=CONVERT(varbinary(max),@old_scopes))
   THROW 59999,N'C1P2 withdrawal changed historical bytes',1;
  IF @want_active=1 AND NOT EXISTS(SELECT 1 FROM dbo.patient_links WHERE tenant_id=@tenant AND patient_id=@patient AND user_id=@target
   AND CONVERT(varbinary(max),relationship)=CONVERT(varbinary(max),JSON_VALUE(@payload,'$.relationship'))
   AND CONVERT(varbinary(max),scopes)=CONVERT(varbinary(max),JSON_QUERY(@payload,'$.scopes')))
   THROW 59999,N'C1P2 SET value/order preservation mismatch',1;
  IF (SELECT COUNT(*) FROM dbo.audit_events WHERE id>@cutoff AND request_id=@request AND action=N'PORTAL_LINK_CHANGED' AND actor_id=@actor AND tenant_id=@tenant AND target_id=@patient)<>1
   THROW 59999,N'C1P2 exactly one semantic writer event required',1;
  SELECT @meta=metadata FROM dbo.audit_events WHERE id>@cutoff AND request_id=@request AND action=N'PORTAL_LINK_CHANGED';
  IF ISJSON(@meta,OBJECT)<>1 OR (SELECT COUNT(*) FROM OPENJSON(@meta))<>5
   OR EXISTS(SELECT [key],[type],DATALENGTH([key]) FROM @meta_keys EXCEPT SELECT [key] COLLATE Latin1_General_100_BIN2,[type],DATALENGTH([key]) FROM OPENJSON(@meta))
   OR JSON_VALUE(@meta,'$.userId') COLLATE Latin1_General_100_BIN2<>@target
   OR JSON_VALUE(@meta,'$.active')<>CASE WHEN @want_active=1 THEN N'true' ELSE N'false' END
   OR ISNULL(TRY_CONVERT(int,JSON_VALUE(@meta,'$.previousRevision')),-1)<>@previous OR ISNULL(TRY_CONVERT(int,JSON_VALUE(@meta,'$.revision')),-1)<>@want_revision
   OR JSON_VALUE(@meta,'$.operation')<>CASE WHEN @want_active=1 THEN N'SET' ELSE N'DEACTIVATE' END
   OR EXISTS(SELECT 1 FROM OPENJSON(@meta) WHERE [key] COLLATE Latin1_General_100_BIN2 NOT IN (N'userId',N'active',N'previousRevision',N'revision',N'operation'))
   THROW 59999,N'C1P2 semantic metadata mismatch',1;
  SET @row_action=CASE WHEN @previous=0 THEN N'patient_links_INSERT' ELSE N'patient_links_UPDATE' END;
  SELECT @projected_change=CASE WHEN @previous=0 OR @old_active<>active OR DATALENGTH(@old_relation)<>DATALENGTH(relationship)
   OR CONVERT(varbinary(max),@old_relation)<>CONVERT(varbinary(max),relationship) OR DATALENGTH(@old_scopes)<>DATALENGTH(scopes)
   OR CONVERT(varbinary(max),@old_scopes)<>CONVERT(varbinary(max),scopes) THEN 1 ELSE 0 END FROM dbo.patient_links WHERE tenant_id=@tenant AND patient_id=@patient AND user_id=@target;
  IF (SELECT COUNT(*) FROM dbo.audit_events WHERE id>@cutoff AND request_id=@request AND action=@row_action AND actor_id=@actor AND tenant_id=@tenant AND target_id=@target)<>@projected_change
   OR (SELECT COUNT(*) FROM dbo.audit_events WHERE id>@cutoff AND request_id=@request)<>1+@projected_change
   THROW 59999,N'C1P2 V7 projected-change audit mismatch',1;
  SET @checks+=1;SET @ordinal+=1;
 END;
 IF @expected=0
 BEGIN
  SET @request=LOWER(CONVERT(char(36),NEWID()));
  EXEC dbo.usp_request_context @request_id=@request,@method=N'GET',@route=N'/qa/c1p2/edit',@actor_id=@actor,@actor_roles=@claims,@tenant_id=@tenant,@token_hash=@token,@scope='REQUEST',@user_agent=@agent;
  EXECUTE AS USER=N'hp_qa_c1p2_runtime';
  INSERT @edit EXEC dbo.usp_patient_link_edit_get @patient,@target;
  IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 59999,N'C1P2 edit lost external committable TX',1;
  REVERT;
  IF (SELECT COUNT(*) FROM @edit)<>1 OR NOT EXISTS(SELECT 1 FROM @edit e JOIN dbo.patient_links l ON l.tenant_id=e.tenant_id AND l.patient_id=e.patient_id AND l.user_id=e.user_id JOIN dbo.users u ON u.id=l.user_id
   WHERE e.tenant_id=@tenant AND e.patient_id=@patient AND e.user_id=@target AND e.active=l.active AND e.revision=l.revision
   AND CONVERT(varbinary(max),e.user_name)=CONVERT(varbinary(max),u.name) AND CONVERT(varbinary(max),e.relationship)=CONVERT(varbinary(max),l.relationship) AND CONVERT(varbinary(max),e.scopes)=CONVERT(varbinary(max),l.scopes))
   THROW 59999,N'C1P2 edit8 atomic historical snapshot mismatch',1;
  IF (SELECT COUNT(*) FROM dbo.audit_events WHERE id>@cutoff AND request_id=@request)<>1
   OR NOT EXISTS(SELECT 1 FROM dbo.audit_events WHERE id>@cutoff AND request_id=@request AND action=N'PATIENT_LINK_EDIT_READ' AND actor_id=@actor AND tenant_id=@tenant AND target_id=@patient
   AND ISJSON(metadata,OBJECT)=1 AND (SELECT COUNT(*) FROM OPENJSON(metadata))=1 AND JSON_VALUE(metadata,'$.userId')=@target)
   THROW 59999,N'C1P2 edit read audit mismatch',1;
  SET @checks+=1;
  ROLLBACK TRANSACTION;
 END
 ELSE
 BEGIN
  SET @request=LOWER(CONVERT(char(36),NEWID()));
  DECLARE @negative_before nvarchar(max)=(SELECT * FROM dbo.patient_links WHERE tenant_id IN (@tenant,@other) ORDER BY tenant_id,patient_id,user_id FOR JSON PATH,INCLUDE_NULL_VALUES);
  EXEC dbo.usp_request_context @request_id=@request,@method=N'PUT',@route=N'/qa/c1p2/negative',@actor_id=@ctx_actor,@actor_roles=@claims,@tenant_id=@ctx_tenant,@token_hash=@token,@scope=@scope,@user_agent=@agent;
  __CONTEXT_SQL__
  IF @operation='bootstrap_write' OR @operation='bootstrap_read' EXECUTE AS USER=N'hp_qa_c1p2_bootstrap';
  ELSE EXECUTE AS USER=N'hp_qa_c1p2_runtime';
  BEGIN TRY
   __NEGATIVE_CALL_SQL__
   THROW 59999,N'C1P2 negative unexpectedly succeeded',1;
  END TRY
  BEGIN CATCH
   IF ERROR_NUMBER()<>@expected THROW;
   IF @expected=59998 AND ERROR_MESSAGE()<>N'C1P2 expected transient semantic audit failure' THROW;
   SET @reported_error=ERROR_NUMBER();SET @reported_state=XACT_STATE();
   IF @reported_state NOT IN (-1,1) OR @@TRANCOUNT<>1 THROW 59999,N'C1P2 unexpected negative TX state or depth',1;
   IF @reported_state=1
   BEGIN
    REVERT;
    IF CONVERT(varbinary(max),@negative_before)<>CONVERT(varbinary(max),(SELECT * FROM dbo.patient_links WHERE tenant_id IN (@tenant,@other) ORDER BY tenant_id,patient_id,user_id FOR JSON PATH,INCLUDE_NULL_VALUES))
     OR EXISTS(SELECT 1 FROM @ack) OR EXISTS(SELECT 1 FROM @edit)
     OR EXISTS(SELECT 1 FROM dbo.audit_events WHERE id>@cutoff AND request_id=@request AND action IN (N'PORTAL_LINK_CHANGED',N'PATIENT_LINK_EDIT_READ'))
     THROW 59999,N'C1P2 negative left an in-TX row or semantic event',1;
    ROLLBACK TRANSACTION;
   END
   ELSE SET @cleanup=N'CLOSE'; -- NO REVERT or compensation in doomed TX.
   SET @checks+=1;
  END CATCH;
 END;
 IF @cleanup=N'EXPLICIT' AND (@@TRANCOUNT<>0 OR XACT_STATE()<>0) THROW 59999,N'C1P2 explicit rollback did not end TX',1;
 IF @cleanup=N'CLOSE' AND (@@TRANCOUNT<>1 OR XACT_STATE()<>-1) THROW 59999,N'C1P2 expected doomed TX before connection close',1;
 SELECT N'C1P2_RESULT'+(SELECT N'PHASE' kind,N'PRE_APLICACION' mode,N'__NONCE__' nonce,@phase phase,N'PASS' status,@reported_error error,@reported_state xact_state,@cleanup cleanup,@checks checks,
 REPLICATE(CAST(N'🦷中' AS nvarchar(max)),3000) probe FOR JSON PATH,WITHOUT_ARRAY_WRAPPER) AS c1p2_frame;
END TRY
BEGIN CATCH
 IF XACT_STATE()=1
 BEGIN
  IF USER_NAME() IN (N'hp_qa_c1p2_runtime',N'hp_qa_c1p2_bootstrap') REVERT;
  ROLLBACK TRANSACTION;
 END;
 THROW;
END CATCH;
-- C1P2_CASE_END
*/
