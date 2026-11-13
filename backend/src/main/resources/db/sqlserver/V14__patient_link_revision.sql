-- PAC-01.C1.P1 / SQL Server 2022, compatibility 160. OFFLINE PREPARATION ONLY.
-- NEW migration: +one revision column/default/check; ALTER existing writer;
-- CREATE one public edit reader; +two object EXECUTE ACLs. Never install with
-- the old API writer: C2 must first support expectedRevision and ACK5.
-- Caller owns ONE external committable transaction on ONE connection and MUST
-- stop on the first batch error (Flyway or SQLcmd :On Error exit / -b).
-- No BEGIN/COMMIT/ROLLBACK, repair/reapply, dynamic queries or new helper here.
-- Expected 134SP/564 role ACL ->135/566 only if that accepted baseline holds;
-- optional Flyway history permissions, when present, remain unchanged.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
SET NOCOUNT ON;
IF @@TRANCOUNT=0 OR XACT_STATE()<>1
 THROW 51000,N'HP_INVALID:External committable migration transaction required',1;
IF ISNULL(TRY_CONVERT(int,SERVERPROPERTY('ProductMajorVersion')),0)<>16
 OR ISNULL((SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID()),0)<>160
 THROW 51000,N'HP_INVALID:SQL Server 2022 compatibility160 required',1;
IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>1
 OR ISNULL(IS_ROLEMEMBER(N'hp_runtime_executor'),0)=1
 OR ISNULL(IS_ROLEMEMBER(N'hp_bootstrap_executor'),0)=1
 THROW 51001,N'HP_FORBIDDEN:Separate administrative migration principal required',1;
IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE name COLLATE Latin1_General_100_BIN2=N'dbo'
 AND DATALENGTH(name)=6 AND principal_id=1)
 OR NOT EXISTS(SELECT 1 FROM sys.database_principals p JOIN sys.databases d
 ON d.database_id=DB_ID() AND p.sid=d.owner_sid WHERE p.name COLLATE Latin1_General_100_BIN2=N'dbo'
 AND DATALENGTH(p.name)=6 AND p.principal_id=1 AND DATALENGTH(p.sid)>0
 AND ((p.type COLLATE Latin1_General_100_BIN2='S' AND p.authentication_type=1)
 OR (p.type COLLATE Latin1_General_100_BIN2='U' AND p.authentication_type=3)))
 THROW 51000,N'HP_INVALID:Expected dbo ownership required',1;
IF (SELECT COUNT(*) FROM sys.database_principals WHERE name IN (N'hp_runtime_executor',N'hp_bootstrap_executor')
 AND type='R' AND is_fixed_role=0 AND owning_principal_id=1)<>2
 OR EXISTS(SELECT 1 FROM sys.database_role_members WHERE member_principal_id IN
 (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor')))
 OR EXISTS(SELECT 1 FROM sys.schemas WHERE principal_id IN
 (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor')))
 OR EXISTS(SELECT 1 FROM sys.objects WHERE principal_id IN
 (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor')))
 THROW 51000,N'HP_INVALID:Expected execution roles and ownership chain required',1;
IF OBJECT_ID(N'dbo.usp_patient_link_edit_get') IS NOT NULL
 OR COL_LENGTH(N'dbo.patient_links',N'revision') IS NOT NULL
 OR OBJECT_ID(N'dbo.DF_patient_links_revision') IS NOT NULL
 OR OBJECT_ID(N'dbo.CK_patient_links_revision') IS NOT NULL
 THROW 51003,N'HP_CONFLICT:Link revision migration already present',1;

-- Exact accepted dependencies. Normalize CRLF or lone CR to LF and trim ONLY
-- outer ASCII space/tab/CR/LF. Accept the entire canonical GO batch (comments
-- included) OR the exact CREATE/ALTER statement without its known comment
-- prefix, because module storage/import boundaries can omit that prefix.
-- Never remove internal whitespace/comments, change keyword case, replace
-- CREATE/ALTER, or ignore an arbitrary prefix/suffix. Hash is UTF16LE SHA256.
DECLARE @modules TABLE(name sysname PRIMARY KEY,kind char(2),full_hash char(64),statement_hash char(64));
INSERT @modules(name,kind,full_hash,statement_hash) VALUES
 (N'usp_patient_link_save',N'P',N'C05D47ED844BF988FBB51B51599863C1FCD03A79B9B24F0987634E0B377C4C21',N'0CB4C21B6AB3ADFDA979156E130AF4BF767EFB796BC769888920125F7A19D2BC'),
 (N'trace_patient_links_change',N'TR',N'3AD3A51C6792B2E2AB46511C073DC2F4E35020DADF1B857D4BEC4F89BD3F62B9',N'EEBB88F94F14467171E3DA215265C0653DE1C84C91EF6F9A149E422732A3B775'),
 (N'usp_require_transaction',N'P',N'ED26307798A06C0AD45451707EFB4DD233BC236AF76F2C4CDA05207090AC3DD4',N'ED26307798A06C0AD45451707EFB4DD233BC236AF76F2C4CDA05207090AC3DD4'),
 (N'usp_require_actor',N'P',N'E2FF440DC1F4E36020B08AC7522F127F9CC1F0590F108F93E3F287E693E24C69',N'C0E38B8A3D8CB589B85EE61C53D72C5341CB4B196E2F3B95DAFF47352E536921'),
 (N'usp_write_guard',N'P',N'E92BD284EEA8DB194ACD849E6AD53C214B9AD2C9C6D521590835F8DE991BCE9E',N'4B61FD5E5295F8E75D5F5397BB08530D5887025022628311D8FE8958ACFAE3BE'),
 (N'usp_audit_event',N'P',N'85CAF28531CA043B4C93AC8164E4CC685C2364642A11032A9A5728BA6BD430E6',N'68C0931A743C9F0495BD28C54C10CDFB29295C2B924C022FA9DEB67C2C460FF4'),
 (N'usp_request_context',N'P',N'6041E70D99CF16EF7523DBC51336F2076FFE92285B5C0B7FA580D9D3CD5823E9',N'8D9AEECAEFC6CD286293342E4846B6C704EC257C8B927BB54A2921A7FE37542C'),
 (N'usp_clinical_scope',N'P',N'592E74E40833ADA4EB4904A275180F712982E55AD268972D2442431F2DFAE100',N'74EFAB8B6E1CE7DD7E96DD331C1D30534F0D35E9062A44366049AA71091D95D1'),
 (N'usp_patient_links_list',N'P',N'238A044649B952D40ABD1DAADD10AE1C49C596AF34DFDD7724CAD9F73EEF21AA',N'238A044649B952D40ABD1DAADD10AE1C49C596AF34DFDD7724CAD9F73EEF21AA');
IF EXISTS(SELECT 1 FROM @modules e LEFT JOIN sys.objects o
 ON o.object_id=OBJECT_ID(N'dbo.'+e.name) AND o.type COLLATE Latin1_General_100_BIN2=e.kind COLLATE Latin1_General_100_BIN2
 LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id
 CROSS APPLY(SELECT TRIM(N' '+NCHAR(9)+NCHAR(10)+NCHAR(13) FROM
 REPLACE(REPLACE(m.definition,NCHAR(13)+NCHAR(10),NCHAR(10)),NCHAR(13),NCHAR(10))) AS normalized) n
 WHERE o.object_id IS NULL OR m.definition IS NULL OR o.is_ms_shipped<>0
 OR o.schema_id<>SCHEMA_ID(N'dbo') OR ISNULL(o.principal_id,1)<>1
 OR m.uses_ansi_nulls<>1 OR m.uses_quoted_identifier<>1
 OR m.execute_as_principal_id IS NOT NULL OR m.is_schema_bound<>0 OR m.is_recompiled<>0
 OR CONVERT(char(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),n.normalized)),2)
 COLLATE Latin1_General_100_BIN2 NOT IN (e.full_hash,e.statement_hash,CASE WHEN e.name=N'usp_require_transaction' THEN N'CE4B7FCEA8D43FA84999D7776652E26A65003B845D07F5B5743E1A3B7E7503FA' ELSE e.full_hash END))
 THROW 51000,N'HP_INVALID:Accepted link writer trigger or helper definition drift',1;
IF EXISTS(SELECT 1 FROM (VALUES(N'users'),(N'auth_sessions'),(N'memberships'),(N'tenants'),
 (N'subscriptions'),(N'plan_versions'),(N'patients'),(N'application_state'),(N'audit_events')) x(name)
 LEFT JOIN sys.tables t ON t.object_id=OBJECT_ID(N'dbo.'+x.name,N'U')
 WHERE t.object_id IS NULL OR ISNULL(t.principal_id,1)<>1)
 THROW 51000,N'HP_INVALID:Accepted dbo data dependencies required',1;

-- Native shapes for the accepted authority/audit dependencies, from V1.
-- Reject widened/alias/nullable/computed fields before assigning their values
-- to fixed local types; no data or credentials are included in this manifest.
DECLARE @shape TABLE(table_name sysname,column_id int,name sysname,type_name sysname,max_length smallint,collation_name sysname NULL,is_nullable bit,is_identity bit,scale tinyint);
INSERT @shape VALUES
 (N'users',1,N'id',N'char',36,N'Latin1_General_100_BIN2',0,0,0),
 (N'users',2,N'name',N'nvarchar',320,N'Latin1_General_100_CI_AI_SC',0,0,0),
 (N'users',3,N'email',N'nvarchar',508,N'Latin1_General_100_CI_AI_SC',0,0,0),
 (N'users',4,N'password_hash',N'nvarchar',200,N'Latin1_General_100_CI_AI_SC',0,0,0),
 (N'users',5,N'clinical_domain',N'nvarchar',12,N'Latin1_General_100_BIN2',1,0,0),
 (N'users',6,N'credential',N'nvarchar',200,N'Latin1_General_100_CI_AI_SC',1,0,0),
 (N'users',7,N'platform_role',N'nvarchar',6,N'Latin1_General_100_BIN2',1,0,0),
 (N'users',8,N'active',N'bit',1,NULL,0,0,0),
 (N'users',9,N'created_at',N'datetime2',8,NULL,0,0,6),
 (N'users',10,N'email_verified',N'bit',1,NULL,0,0,0),
 (N'users',11,N'login_failures',N'int',4,NULL,0,0,0),
 (N'users',12,N'locked_until',N'datetime2',8,NULL,1,0,6),
 (N'auth_sessions',1,N'token_hash',N'char',64,N'Latin1_General_100_BIN2',0,0,0),
 (N'auth_sessions',2,N'user_id',N'char',36,N'Latin1_General_100_BIN2',0,0,0),
 (N'auth_sessions',3,N'tenant_id',N'char',36,N'Latin1_General_100_BIN2',1,0,0),
 (N'auth_sessions',4,N'expires_at',N'datetime2',8,NULL,0,0,6),
 (N'auth_sessions',5,N'revoked',N'bit',1,NULL,0,0,0),
 (N'auth_sessions',6,N'created_at',N'datetime2',8,NULL,0,0,6),
 (N'auth_sessions',7,N'csrf_token',N'char',64,N'Latin1_General_100_BIN2',0,0,0),
 (N'auth_sessions',8,N'last_seen_at',N'datetime2',8,NULL,0,0,6),
 (N'auth_sessions',9,N'user_agent',N'nvarchar',600,N'Latin1_General_100_CI_AI_SC',0,0,0),
 (N'auth_sessions',10,N'source_ip',N'nvarchar',160,N'Latin1_General_100_CI_AI_SC',0,0,0),
 (N'memberships',1,N'tenant_id',N'char',36,N'Latin1_General_100_BIN2',0,0,0),
 (N'memberships',2,N'user_id',N'char',36,N'Latin1_General_100_BIN2',0,0,0),
 (N'memberships',3,N'roles',N'nvarchar',-1,N'Latin1_General_100_BIN2',0,0,0),
 (N'memberships',4,N'status',N'nvarchar',16,N'Latin1_General_100_BIN2',0,0,0),
 (N'memberships',5,N'owner',N'bit',1,NULL,0,0,0),
 (N'tenants',1,N'id',N'char',36,N'Latin1_General_100_BIN2',0,0,0),
 (N'tenants',2,N'name',N'nvarchar',320,N'Latin1_General_100_CI_AI_SC',0,0,0),
 (N'tenants',3,N'slug',N'varchar',63,N'Latin1_General_100_BIN2',0,0,0),
 (N'tenants',4,N'kind',N'nvarchar',32,N'Latin1_General_100_BIN2',0,0,0),
 (N'tenants',5,N'domain',N'nvarchar',12,N'Latin1_General_100_BIN2',0,0,0),
 (N'tenants',6,N'status',N'nvarchar',18,N'Latin1_General_100_BIN2',0,0,0),
 (N'tenants',7,N'owner_user_id',N'char',36,N'Latin1_General_100_BIN2',0,0,0),
 (N'tenants',8,N'timezone',N'nvarchar',128,N'Latin1_General_100_CI_AI_SC',0,0,0),
 (N'tenants',9,N'created_at',N'datetime2',8,NULL,0,0,6),
 (N'subscriptions',1,N'tenant_id',N'char',36,N'Latin1_General_100_BIN2',0,0,0),
 (N'subscriptions',2,N'plan_id',N'char',36,N'Latin1_General_100_BIN2',0,0,0),
 (N'subscriptions',3,N'plan_version',N'int',4,NULL,0,0,0),
 (N'subscriptions',4,N'cycle',N'nvarchar',14,N'Latin1_General_100_BIN2',0,0,0),
 (N'subscriptions',5,N'branch_quota',N'int',4,NULL,0,0,0),
 (N'subscriptions',6,N'professional_quota',N'int',4,NULL,0,0,0),
 (N'subscriptions',7,N'specialty_quota',N'int',4,NULL,0,0,0),
 (N'subscriptions',8,N'renewal_date',N'date',3,NULL,0,0,0),
 (N'plan_versions',1,N'plan_id',N'char',36,N'Latin1_General_100_BIN2',0,0,0),
 (N'plan_versions',2,N'version',N'int',4,NULL,0,0,0),
 (N'plan_versions',3,N'base_minor',N'bigint',8,NULL,0,0,0),
 (N'plan_versions',4,N'branch_minor',N'bigint',8,NULL,0,0,0),
 (N'plan_versions',5,N'professional_minor',N'bigint',8,NULL,0,0,0),
 (N'plan_versions',6,N'included_branches',N'int',4,NULL,0,0,0),
 (N'plan_versions',7,N'included_professionals',N'int',4,NULL,0,0,0),
 (N'plan_versions',8,N'included_specialties',N'int',4,NULL,0,0,0),
 (N'plan_versions',9,N'max_branches',N'int',4,NULL,0,0,0),
 (N'plan_versions',10,N'max_professionals',N'int',4,NULL,0,0,0),
 (N'plan_versions',11,N'max_specialties',N'int',4,NULL,0,0,0),
 (N'plan_versions',12,N'annual_discount',N'int',4,NULL,0,0,0),
 (N'plan_versions',13,N'kinds',N'nvarchar',-1,N'Latin1_General_100_BIN2',0,0,0),
 (N'plan_versions',14,N'domains',N'nvarchar',-1,N'Latin1_General_100_BIN2',0,0,0),
 (N'plan_versions',15,N'modules',N'nvarchar',-1,N'Latin1_General_100_BIN2',0,0,0),
 (N'plan_versions',16,N'created_at',N'datetime2',8,NULL,0,0,6),
 (N'patients',1,N'id',N'char',36,N'Latin1_General_100_BIN2',0,0,0),
 (N'patients',2,N'tenant_id',N'char',36,N'Latin1_General_100_BIN2',0,0,0),
 (N'patients',3,N'name',N'nvarchar',320,N'Latin1_General_100_CI_AI_SC',0,0,0),
 (N'patients',4,N'domain',N'nvarchar',12,N'Latin1_General_100_BIN2',0,0,0),
 (N'patients',5,N'identifier',N'nvarchar',200,N'Latin1_General_100_CI_AI_SC',0,0,0),
 (N'patients',6,N'birth_date',N'date',3,NULL,1,0,0),
 (N'patients',7,N'species',N'nvarchar',160,N'Latin1_General_100_CI_AI_SC',1,0,0),
 (N'patients',8,N'contact',N'nvarchar',-1,N'Latin1_General_100_BIN2',0,0,0),
 (N'patients',9,N'allergies',N'nvarchar',-1,N'Latin1_General_100_BIN2',0,0,0),
 (N'patients',10,N'revision',N'int',4,NULL,0,0,0),
 (N'patients',11,N'created_at',N'datetime2',8,NULL,0,0,6),
 (N'application_state',1,N'id',N'int',4,NULL,0,0,0),
 (N'application_state',2,N'mode',N'nvarchar',22,N'Latin1_General_100_BIN2',0,0,0),
 (N'application_state',3,N'message',N'nvarchar',600,N'Latin1_General_100_CI_AI_SC',0,0,0),
 (N'application_state',4,N'revision',N'int',4,NULL,0,0,0),
 (N'audit_events',1,N'id',N'bigint',8,NULL,0,1,0),
 (N'audit_events',2,N'tenant_id',N'char',36,N'Latin1_General_100_BIN2',1,0,0),
 (N'audit_events',3,N'actor_id',N'char',36,N'Latin1_General_100_BIN2',1,0,0),
 (N'audit_events',4,N'action',N'nvarchar',160,N'Latin1_General_100_CI_AI_SC',0,0,0),
 (N'audit_events',5,N'target_id',N'nvarchar',200,N'Latin1_General_100_CI_AI_SC',0,0,0),
 (N'audit_events',6,N'metadata',N'nvarchar',-1,N'Latin1_General_100_BIN2',0,0,0),
 (N'audit_events',7,N'created_at',N'datetime2',8,NULL,0,0,6),
 (N'audit_events',8,N'request_id',N'char',36,N'Latin1_General_100_BIN2',1,0,0),
 (N'audit_events',9,N'method',N'nvarchar',20,N'Latin1_General_100_CI_AI_SC',1,0,0),
 (N'audit_events',10,N'route',N'nvarchar',500,N'Latin1_General_100_CI_AI_SC',1,0,0),
 (N'audit_events',11,N'source_ip',N'nvarchar',160,N'Latin1_General_100_CI_AI_SC',1,0,0),
 (N'audit_events',12,N'user_agent',N'nvarchar',600,N'Latin1_General_100_CI_AI_SC',1,0,0),
 (N'audit_events',13,N'actor_roles',N'nvarchar',-1,N'Latin1_General_100_BIN2',1,0,0),
 (N'audit_events',14,N'before_state',N'nvarchar',-1,N'Latin1_General_100_BIN2',1,0,0),
 (N'audit_events',15,N'after_state',N'nvarchar',-1,N'Latin1_General_100_BIN2',1,0,0),
 (N'audit_events',16,N'resource_type',N'nvarchar',120,N'Latin1_General_100_CI_AI_SC',1,0,0);
IF EXISTS(SELECT 1 FROM @shape e LEFT JOIN sys.columns c
 ON c.object_id=OBJECT_ID(N'dbo.'+e.table_name,N'U') AND c.column_id=e.column_id
 AND c.name COLLATE Latin1_General_100_BIN2=e.name COLLATE Latin1_General_100_BIN2
 WHERE c.column_id IS NULL OR TYPE_NAME(c.system_type_id)<>e.type_name
 OR c.user_type_id<>c.system_type_id OR c.max_length<>e.max_length
 OR c.is_nullable<>e.is_nullable OR c.is_identity<>e.is_identity OR c.scale<>e.scale
 OR c.is_computed<>0 OR c.generated_always_type<>0
 OR ISNULL(c.collation_name,N'') COLLATE Latin1_General_100_BIN2<>ISNULL(e.collation_name,N'') COLLATE Latin1_General_100_BIN2)
 OR EXISTS(SELECT 1 FROM (SELECT table_name,COUNT(*) AS n FROM @shape GROUP BY table_name) e
 WHERE e.n<>(SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.'+e.table_name,N'U')))
 THROW 51000,N'HP_INVALID:Accepted authority or audit column shape drift',1;

-- Full six-column V1 link shape before mutation, including physical ID/order,
-- collations and native types. Reject alias/computed/identity/generated columns.
DECLARE @link int=OBJECT_ID(N'dbo.patient_links',N'U');
IF @link IS NULL OR NOT EXISTS(SELECT 1 FROM sys.tables WHERE object_id=@link
 AND temporal_type=0 AND is_memory_optimized=0 AND ISNULL(principal_id,1)=1)
 OR EXISTS(SELECT 1 FROM sys.security_predicates WHERE target_object_id=@link)
 THROW 51000,N'HP_INVALID:Accepted patient links table required',1;
DECLARE @columns TABLE(column_id int,name sysname,type_name sysname,max_length smallint,collation_name sysname NULL);
INSERT @columns VALUES
 (1,N'tenant_id',N'char',36,N'Latin1_General_100_BIN2'),
 (2,N'patient_id',N'char',36,N'Latin1_General_100_BIN2'),
 (3,N'user_id',N'char',36,N'Latin1_General_100_BIN2'),
 (4,N'relationship',N'nvarchar',160,N'Latin1_General_100_CI_AI_SC'),
 (5,N'active',N'bit',1,NULL),
 (6,N'scopes',N'nvarchar',-1,N'Latin1_General_100_BIN2');
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id=@link)<>6
 OR EXISTS(SELECT 1 FROM @columns e LEFT JOIN sys.columns c
 ON c.object_id=@link AND c.column_id=e.column_id AND c.name COLLATE Latin1_General_100_BIN2=e.name COLLATE Latin1_General_100_BIN2
 WHERE c.column_id IS NULL OR TYPE_NAME(c.system_type_id)<>e.type_name
 OR c.user_type_id<>c.system_type_id OR c.max_length<>e.max_length OR c.is_nullable<>0
 OR c.is_identity<>0 OR c.is_computed<>0 OR c.generated_always_type<>0
 OR ISNULL(c.collation_name,N'') COLLATE Latin1_General_100_BIN2<>ISNULL(e.collation_name,N'') COLLATE Latin1_General_100_BIN2)
 THROW 51000,N'HP_INVALID:Patient links column drift',1;
IF (SELECT COUNT(*) FROM sys.default_constraints WHERE parent_object_id=@link)<>1
 OR NOT EXISTS(SELECT 1 FROM sys.default_constraints WHERE parent_object_id=@link
 AND name=N'DF_patient_links_active' AND parent_column_id=5
 AND definition COLLATE Latin1_General_100_BIN2 IN (N'(1)',N'((1))'))
 OR (SELECT COUNT(*) FROM sys.check_constraints WHERE parent_object_id=@link)<>1
 OR NOT EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id=@link
 AND name=N'CK_patient_links_scopes_json' AND is_disabled=0 AND is_not_trusted=0 AND is_not_for_replication=0
 -- Only explicit, semantics-equivalent engine formatting variants are allowed.
 AND UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(definition COLLATE Latin1_General_100_BIN2,N'[',N''),N']',N''),
 N' ',N''),NCHAR(9),N''),NCHAR(10),N''),NCHAR(13),N'')) COLLATE Latin1_General_100_BIN2
 IN (N'(SCOPESISNULLORISJSON(SCOPES,VALUE)=1)',N'(SCOPESISNULLORISJSON(SCOPES,VALUE)=(1))'))
 THROW 51000,N'HP_INVALID:Patient links check or default drift',1;
IF (SELECT COUNT(*) FROM sys.key_constraints WHERE parent_object_id=@link)<>1
 OR NOT EXISTS(SELECT 1 FROM sys.key_constraints WHERE parent_object_id=@link AND name=N'PK_patient_links' AND type='PK')
 OR (SELECT COUNT(*) FROM sys.indexes WHERE object_id=@link AND index_id>0)<>2
 OR NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=@link AND name=N'PK_patient_links'
 AND type=1 AND is_unique=1 AND is_primary_key=1 AND is_disabled=0 AND is_hypothetical=0 AND has_filter=0)
 OR NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=@link AND name=N'IX_fk_patient_links_2'
 AND type=2 AND is_unique=0 AND is_primary_key=0 AND is_disabled=0 AND is_hypothetical=0 AND has_filter=0)
 OR (SELECT COUNT(*) FROM sys.index_columns WHERE object_id=@link AND index_id IN
 (SELECT index_id FROM sys.indexes WHERE object_id=@link AND name=N'PK_patient_links'))<>3
 OR EXISTS(SELECT 1 FROM sys.index_columns c JOIN sys.indexes i ON i.object_id=c.object_id AND i.index_id=c.index_id
 WHERE c.object_id=@link AND i.name=N'PK_patient_links'
 AND (c.key_ordinal<>c.column_id OR c.column_id NOT IN (1,2,3) OR c.is_descending_key<>0 OR c.is_included_column<>0))
 OR (SELECT COUNT(*) FROM sys.index_columns c JOIN sys.indexes i ON i.object_id=c.object_id AND i.index_id=c.index_id
 WHERE c.object_id=@link AND i.name=N'IX_fk_patient_links_2')<>1
 OR NOT EXISTS(SELECT 1 FROM sys.index_columns c JOIN sys.indexes i ON i.object_id=c.object_id AND i.index_id=c.index_id
 WHERE c.object_id=@link AND i.name=N'IX_fk_patient_links_2' AND c.column_id=3 AND c.key_ordinal=1 AND c.is_descending_key=0 AND c.is_included_column=0)
 THROW 51000,N'HP_INVALID:Patient links key or index drift',1;
IF (SELECT COUNT(*) FROM sys.foreign_keys WHERE parent_object_id=@link)<>2
 OR NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=@link AND name=N'FK_patient_links_1'
 AND referenced_object_id=OBJECT_ID(N'dbo.patients',N'U') AND is_disabled=0 AND is_not_trusted=0
 AND is_not_for_replication=0 AND delete_referential_action=0 AND update_referential_action=0)
 OR NOT EXISTS(SELECT 1 FROM sys.foreign_keys WHERE parent_object_id=@link AND name=N'FK_patient_links_2'
 AND referenced_object_id=OBJECT_ID(N'dbo.users',N'U') AND is_disabled=0 AND is_not_trusted=0
 AND is_not_for_replication=0 AND delete_referential_action=0 AND update_referential_action=0)
 OR (SELECT COUNT(*) FROM sys.foreign_key_columns WHERE parent_object_id=@link)<>3
 OR NOT EXISTS(SELECT 1 FROM sys.foreign_key_columns WHERE constraint_object_id=OBJECT_ID(N'dbo.FK_patient_links_1')
 AND constraint_column_id=1 AND parent_column_id=1 AND referenced_column_id=COLUMNPROPERTY(OBJECT_ID(N'dbo.patients'),N'tenant_id','ColumnId'))
 OR NOT EXISTS(SELECT 1 FROM sys.foreign_key_columns WHERE constraint_object_id=OBJECT_ID(N'dbo.FK_patient_links_1')
 AND constraint_column_id=2 AND parent_column_id=2 AND referenced_column_id=COLUMNPROPERTY(OBJECT_ID(N'dbo.patients'),N'id','ColumnId'))
 OR NOT EXISTS(SELECT 1 FROM sys.foreign_key_columns WHERE constraint_object_id=OBJECT_ID(N'dbo.FK_patient_links_2')
 AND constraint_column_id=1 AND parent_column_id=3 AND referenced_column_id=COLUMNPROPERTY(OBJECT_ID(N'dbo.users'),N'id','ColumnId'))
 THROW 51000,N'HP_INVALID:Patient links foreign key drift',1;
IF (SELECT COUNT(*) FROM sys.triggers WHERE parent_id=@link)<>1
 OR NOT EXISTS(SELECT 1 FROM sys.triggers WHERE object_id=OBJECT_ID(N'dbo.trace_patient_links_change',N'TR')
 AND parent_id=@link AND is_disabled=0 AND is_instead_of_trigger=0 AND is_not_for_replication=0)
 THROW 51000,N'HP_INVALID:Accepted enabled link audit trigger required',1;

-- Exact role-object ACL baseline from V8 + V13, not broad schema/database grants.
DECLARE @entries TABLE(name sysname PRIMARY KEY,access_class varchar(10));
INSERT @entries VALUES
 (N'usp_request_context',N'runtime'),
 (N'usp_require_transaction',N'private'),
 (N'usp_require_actor',N'private'),
 (N'usp_require_scope',N'private'),
 (N'usp_write_guard',N'private'),
 (N'usp_audit_event',N'private'),
 (N'usp_tenant_by_slug',N'runtime'),
 (N'usp_registration_plans',N'runtime'),
 (N'usp_registration_specialties',N'runtime'),
 (N'usp_registration_plan',N'runtime'),
 (N'usp_identity_credentials',N'runtime'),
 (N'usp_identity_account_lookup',N'runtime'),
 (N'usp_identity_email_exists',N'runtime'),
 (N'usp_identity_membership',N'runtime'),
 (N'usp_user_create',N'runtime'),
 (N'usp_bootstrap_exists',N'bootstrap'),
 (N'usp_bootstrap_create',N'bootstrap'),
 (N'usp_identity_pending',N'runtime'),
 (N'usp_identity_password_hash',N'runtime'),
 (N'usp_password_change',N'runtime'),
 (N'usp_session_resolve',N'runtime'),
 (N'usp_session_save',N'runtime'),
 (N'usp_session_current',N'runtime'),
 (N'usp_sessions_list',N'runtime'),
 (N'usp_session_revoke',N'runtime'),
 (N'usp_session_touch',N'runtime'),
 (N'usp_login_failure',N'runtime'),
 (N'usp_identity_issue',N'runtime'),
 (N'usp_identity_redeem',N'runtime'),
 (N'usp_portal_register',N'runtime'),
 (N'usp_invitation_accept',N'runtime'),
 (N'usp_access_branch',N'runtime'),
 (N'usp_access_patient_link',N'runtime'),
 (N'usp_mail_claim',N'runtime'),
 (N'usp_mail_complete',N'runtime'),
 (N'usp_health_ready',N'runtime'),
 (N'usp_application_status',N'runtime'),
 (N'usp_application_mode',N'runtime'),
 (N'usp_health_sample',N'runtime'),
 (N'usp_monitor_samples',N'runtime'),
 (N'usp_monitor_mail',N'runtime'),
 (N'usp_monitor_requests',N'runtime'),
 (N'usp_monitor_migrations',N'runtime'),
 (N'usp_request_finish',N'runtime'),
 (N'usp_audit_list',N'runtime'),
 (N'usp_trace_events',N'runtime'),
 (N'usp_trace_requests',N'runtime'),
 (N'usp_trace_journey',N'runtime'),
 (N'usp_support_list',N'runtime'),
 (N'usp_require_support_ticket',N'private'),
 (N'usp_support_detail',N'runtime'),
 (N'usp_support_create',N'runtime'),
 (N'usp_support_step',N'runtime'),
 (N'usp_audit_change',N'private'),
 (N'usp_org_json_object',N'private'),
 (N'usp_org_json_strings',N'private'),
 (N'usp_saas_write_gate',N'private'),
 (N'usp_org_target',N'private'),
 (N'usp_platform_plans',N'runtime'),
 (N'usp_platform_tenants',N'runtime'),
 (N'usp_platform_users',N'runtime'),
 (N'usp_platform_specialties',N'runtime'),
 (N'usp_platform_audit',N'runtime'),
 (N'usp_organization_configuration',N'runtime'),
 (N'usp_organization_lookup',N'runtime'),
 (N'usp_organization_directory',N'runtime'),
 (N'usp_organization_professionals',N'runtime'),
 (N'usp_organization_catalog',N'runtime'),
 (N'usp_organization_plans',N'runtime'),
 (N'usp_saas_plan_save',N'runtime'),
 (N'usp_org_subscription_resolve',N'private'),
 (N'usp_org_validate_specialties',N'private'),
 (N'usp_saas_tenant_create',N'runtime'),
 (N'usp_saas_tenant_status',N'runtime'),
 (N'usp_organization_subscription_change',N'runtime'),
 (N'usp_saas_invoice_pay',N'runtime'),
 (N'usp_organization_branch_save',N'runtime'),
 (N'usp_organization_area_save',N'runtime'),
 (N'usp_organization_specialties_save',N'runtime'),
 (N'usp_organization_member_save',N'runtime'),
 (N'usp_platform_user',N'runtime'),
 (N'usp_clinical_scope',N'private'),
 (N'usp_clinical_branch_guard',N'private'),
 (N'usp_clinical_professional_guard',N'private'),
 (N'usp_portal_scope',N'private'),
 (N'usp_patients_list',N'runtime'),
 (N'usp_patient_get',N'runtime'),
 (N'usp_patient_history',N'runtime'),
 (N'usp_encounter_get',N'runtime'),
 (N'usp_documents_list',N'runtime'),
 (N'usp_document_get',N'runtime'),
 (N'usp_clinical_json_object',N'private'),
 (N'usp_patient_save',N'runtime'),
 (N'usp_patient_link_save',N'runtime'),
 (N'usp_appointments_list',N'runtime'),
 (N'usp_appointment_get',N'runtime'),
 (N'usp_appointment_reserve',N'runtime'),
 (N'usp_appointment_change',N'runtime'),
 (N'usp_encounter_start',N'runtime'),
 (N'usp_encounter_note',N'runtime'),
 (N'usp_clinical_entry_add',N'runtime'),
 (N'usp_document_create',N'runtime'),
 (N'usp_document_change',N'runtime'),
 (N'usp_portal_patients',N'runtime'),
 (N'usp_portal_documents',N'runtime'),
 (N'usp_portal_appointments',N'runtime'),
 (N'usp_portal_balance',N'runtime'),
 (N'usp_operations_scope',N'private'),
 (N'usp_operations_branch',N'private'),
 (N'usp_operations_json',N'private'),
 (N'usp_operations_idempotency',N'private'),
 (N'usp_operations_quantity',N'private'),
 (N'usp_finance_balance',N'runtime'),
 (N'usp_finance_movements',N'runtime'),
 (N'usp_finance_post',N'runtime'),
 (N'usp_inventory_lots',N'runtime'),
 (N'usp_inventory_transfers',N'runtime'),
 (N'usp_inventory_prescriptions',N'runtime'),
 (N'usp_inventory_lot_create',N'runtime'),
 (N'usp_inventory_move',N'runtime'),
 (N'usp_inventory_transfer_start',N'runtime'),
 (N'usp_inventory_transfer_receive',N'runtime'),
 (N'usp_hospital_resources',N'runtime'),
 (N'usp_hospital_resource_create',N'runtime'),
 (N'usp_hospital_admissions',N'runtime'),
 (N'usp_hospital_admit',N'runtime'),
 (N'usp_hospital_discharge',N'runtime'),
 (N'usp_operations_workflow_guard',N'private'),
 (N'usp_workflow_definitions',N'runtime'),
 (N'usp_workflow_list',N'runtime'),
 (N'usp_workflow_get',N'runtime'),
 (N'usp_workflow_create',N'runtime'),
 (N'usp_workflow_step',N'runtime'),
 (N'usp_patient_links_list',N'runtime');
DECLARE @tables TABLE(name sysname PRIMARY KEY);
INSERT @tables VALUES
 (N'users'),
 (N'plans'),
 (N'plan_versions'),
 (N'tenants'),
 (N'subscriptions'),
 (N'specialties'),
 (N'tenant_specialties'),
 (N'branches'),
 (N'areas'),
 (N'memberships'),
 (N'membership_branches'),
 (N'membership_specialties'),
 (N'auth_sessions'),
 (N'audit_events'),
 (N'saas_invoices'),
 (N'patients'),
 (N'patient_links'),
 (N'appointments'),
 (N'encounters'),
 (N'clinical_entries'),
 (N'documents'),
 (N'finance_movements'),
 (N'stock_lots'),
 (N'stock_movements'),
 (N'stock_transfers'),
 (N'hospital_resources'),
 (N'admissions'),
 (N'workflow_cases'),
 (N'workflow_history'),
 (N'workflow_definitions'),
 (N'request_traces'),
 (N'identity_tokens'),
 (N'mail_outbox'),
 (N'support_tickets'),
 (N'support_comments'),
 (N'application_state'),
 (N'health_samples');
DECLARE @roles TABLE(name sysname PRIMARY KEY);
IF EXISTS(SELECT 1 FROM @entries WHERE OBJECT_ID(N'dbo.'+name,N'P') IS NULL)
 OR (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo'))<>134
 THROW 51000,N'HP_INVALID:Expected approved134 dbo procedures required',1;
INSERT @roles VALUES(N'hp_runtime_executor'),(N'hp_bootstrap_executor');
DECLARE @acl TABLE(principal_id int,object_id int,permission_name nvarchar(128),state char(1));
INSERT @acl
 SELECT DATABASE_PRINCIPAL_ID(r.name),OBJECT_ID(N'dbo.'+p.name),N'EXECUTE',
 CASE WHEN r.name=N'hp_runtime_executor' AND p.access_class='runtime'
 OR r.name=N'hp_bootstrap_executor' AND (p.access_class='bootstrap' OR p.name=N'usp_request_context') THEN 'G' ELSE 'D' END
 FROM @roles r CROSS JOIN @entries p;
INSERT @acl
 SELECT DATABASE_PRINCIPAL_ID(r.name),OBJECT_ID(N'dbo.'+t.name,N'U'),v.permission_name,'D'
 FROM @roles r CROSS JOIN @tables t CROSS JOIN (VALUES(N'SELECT'),(N'INSERT'),(N'UPDATE'),(N'DELETE')) v(permission_name);
IF OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NOT NULL
BEGIN
 INSERT @acl SELECT DATABASE_PRINCIPAL_ID(r.name),OBJECT_ID(N'dbo.flyway_schema_history'),v.permission_name,'D'
 FROM @roles r CROSS JOIN (VALUES(N'SELECT'),(N'INSERT'),(N'UPDATE'),(N'DELETE')) v(permission_name);
 INSERT @acl VALUES(DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),OBJECT_ID(N'dbo.flyway_schema_history'),N'VIEW DEFINITION','G');
END;
IF EXISTS(SELECT 1 FROM @acl WHERE principal_id IS NULL OR object_id IS NULL)
 OR EXISTS(SELECT 1,principal_id,object_id,0,permission_name COLLATE Latin1_General_100_BIN2,state COLLATE Latin1_General_100_BIN2 FROM @acl
 EXCEPT SELECT class,grantee_principal_id,major_id,minor_id,permission_name COLLATE Latin1_General_100_BIN2,state COLLATE Latin1_General_100_BIN2 FROM sys.database_permissions
 WHERE grantee_principal_id IN (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor')))
 OR EXISTS(SELECT class,grantee_principal_id,major_id,minor_id,permission_name COLLATE Latin1_General_100_BIN2,state COLLATE Latin1_General_100_BIN2 FROM sys.database_permissions
 WHERE grantee_principal_id IN (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor'))
 EXCEPT SELECT 1,principal_id,object_id,0,permission_name COLLATE Latin1_General_100_BIN2,state COLLATE Latin1_General_100_BIN2 FROM @acl)
 OR EXISTS(SELECT 1 FROM sys.database_permissions WHERE grantee_principal_id=DATABASE_PRINCIPAL_ID(N'public') AND state IN ('G','W')
 AND ((class=0 AND permission_name NOT IN (N'CONNECT',N'VIEW ANY COLUMN ENCRYPTION KEY DEFINITION',N'VIEW ANY COLUMN MASTER KEY DEFINITION'))
 OR (class=3 AND major_id=SCHEMA_ID(N'dbo')) OR (class=1 AND OBJECT_SCHEMA_NAME(major_id)=N'dbo')))
 THROW 51000,N'HP_INVALID:Accepted object-only execution ACL drift',1;

-- All preconditions above precede the FIRST persistent mutation. Existing
-- relationship/active/scopes/keys are never rewritten or used as new grants.
ALTER TABLE dbo.patient_links ADD revision int NOT NULL
 CONSTRAINT DF_patient_links_revision DEFAULT(1) WITH VALUES;
GO
-- Same caller-owned transaction and stop-on-error policy across every GO.
IF @@TRANCOUNT=0 OR XACT_STATE()<>1
 THROW 51000,N'HP_INVALID:External committable migration transaction required',1;
ALTER TABLE dbo.patient_links WITH CHECK
 ADD CONSTRAINT CK_patient_links_revision CHECK(revision>=1);
GO
ALTER PROCEDURE dbo.usp_patient_link_save @patient_id char(36),@input nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;

 -- Reuse V10 to materialize ONLY a caller-selected implicit transaction.
 -- Caller retains commit/rollback ownership; autocommit remains rejected.
 -- Reject doom before the helper; no business result/audit/mutation precedes
 -- this boundary or its committable check (no prior business read required).
 IF XACT_STATE()=-1
  THROW 51000,N'HP_INVALID:External committable transaction required',1;
 EXEC dbo.usp_require_transaction;
 IF @@TRANCOUNT=0 OR XACT_STATE()<>1
  THROW 51000,N'HP_INVALID:External committable transaction required',1;
 -- Keep complete sql_variant strings until type/length/canonical validation.
 -- hp_actor_roles is audit-only; it NEVER grants authority in this operation.
 IF ISNULL(CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(SESSION_CONTEXT(N'hp_scope'),'BaseType')),N'') NOT IN (N'varchar',N'nvarchar',N'char',N'nchar')
  OR ISNULL(CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(SESSION_CONTEXT(N'hp_tenant_id'),'BaseType')),N'') NOT IN (N'varchar',N'nvarchar',N'char',N'nchar')
  OR ISNULL(CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(SESSION_CONTEXT(N'hp_actor_id'),'BaseType')),N'') NOT IN (N'varchar',N'nvarchar',N'char',N'nchar')
  OR ISNULL(CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(SESSION_CONTEXT(N'hp_request_id'),'BaseType')),N'') NOT IN (N'varchar',N'nvarchar',N'char',N'nchar')
  OR ISNULL(CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(SESSION_CONTEXT(N'hp_token_hash'),'BaseType')),N'') NOT IN (N'varchar',N'nvarchar',N'char',N'nchar')
  OR ISNULL(CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(SESSION_CONTEXT(N'hp_method'),'BaseType')),N'') NOT IN (N'varchar',N'nvarchar',N'char',N'nchar')
  OR ISNULL(CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(SESSION_CONTEXT(N'hp_route'),'BaseType')),N'') NOT IN (N'varchar',N'nvarchar',N'char',N'nchar')
  THROW 51001,N'HP_FORBIDDEN:Complete trusted request context required',1;
 DECLARE @scope_raw nvarchar(max)=CONVERT(nvarchar(max),SESSION_CONTEXT(N'hp_scope')),
  @tenant_raw nvarchar(max)=CONVERT(nvarchar(max),SESSION_CONTEXT(N'hp_tenant_id')),
  @actor_raw nvarchar(max)=CONVERT(nvarchar(max),SESSION_CONTEXT(N'hp_actor_id')),
  @request_raw nvarchar(max)=CONVERT(nvarchar(max),SESSION_CONTEXT(N'hp_request_id')),
  @token_raw nvarchar(max)=CONVERT(nvarchar(max),SESSION_CONTEXT(N'hp_token_hash')),
  @method_raw nvarchar(max)=CONVERT(nvarchar(max),SESSION_CONTEXT(N'hp_method')),
  @route_raw nvarchar(max)=CONVERT(nvarchar(max),SESSION_CONTEXT(N'hp_route'));
 IF @scope_raw IS NULL OR DATALENGTH(@scope_raw)<>14 OR @scope_raw COLLATE Latin1_General_100_BIN2<>N'REQUEST'
  THROW 51001,N'HP_FORBIDDEN:Request scope required',1;
 IF @tenant_raw IS NULL OR DATALENGTH(@tenant_raw)<>72 OR TRY_CONVERT(uniqueidentifier,@tenant_raw) IS NULL
  OR @tenant_raw COLLATE Latin1_General_100_BIN2<>LOWER(CONVERT(nvarchar(36),TRY_CONVERT(uniqueidentifier,@tenant_raw))) COLLATE Latin1_General_100_BIN2
  OR @actor_raw IS NULL OR DATALENGTH(@actor_raw)<>72 OR TRY_CONVERT(uniqueidentifier,@actor_raw) IS NULL
  OR @actor_raw COLLATE Latin1_General_100_BIN2<>LOWER(CONVERT(nvarchar(36),TRY_CONVERT(uniqueidentifier,@actor_raw))) COLLATE Latin1_General_100_BIN2
  OR @request_raw IS NULL OR DATALENGTH(@request_raw)<>72 OR TRY_CONVERT(uniqueidentifier,@request_raw) IS NULL
  OR @request_raw COLLATE Latin1_General_100_BIN2<>LOWER(CONVERT(nvarchar(36),TRY_CONVERT(uniqueidentifier,@request_raw))) COLLATE Latin1_General_100_BIN2
  OR @token_raw IS NULL OR DATALENGTH(@token_raw)<>128 OR @token_raw COLLATE Latin1_General_100_BIN2 LIKE N'%[^0-9a-f]%'
  OR @method_raw IS NULL OR DATALENGTH(@method_raw) NOT BETWEEN 2 AND 20 OR DATALENGTH(LTRIM(RTRIM(@method_raw)))=0
  OR @route_raw IS NULL OR DATALENGTH(@route_raw) NOT BETWEEN 2 AND 500 OR DATALENGTH(LTRIM(RTRIM(@route_raw)))=0
  THROW 51001,N'HP_FORBIDDEN:Canonical complete request context required',1;
 DECLARE @tenant char(36)=CONVERT(char(36),@tenant_raw),@actor char(36)=CONVERT(char(36),@actor_raw),
  @token char(64)=CONVERT(char(64),@token_raw);
 -- Q1: these fixed CHAR parameters can validate only the received value.
 -- C2 MUST reject a longer original HTTP ID BEFORE RPC binding; this SP cannot
 -- recover a prefix that SQL parameter binding has already truncated.
 IF @patient_id IS NULL OR DATALENGTH(@patient_id)<>36 OR TRY_CONVERT(uniqueidentifier,@patient_id) IS NULL
  OR @patient_id COLLATE Latin1_General_100_BIN2<>LOWER(CONVERT(char(36),TRY_CONVERT(uniqueidentifier,@patient_id))) COLLATE Latin1_General_100_BIN2
  THROW 51000,N'HP_INVALID:Canonical patient UUID required',1;

 -- Order shared with existing tenant business writes: write_guard acquires
 -- application_state then tenant/subscription guard; retain subscription/plan
 -- explicitly, then actor user -> session -> actor membership -> patient ->
 -- target user/membership (SET only; reader target user) -> link PK key/range.
 -- Initial helper authority reads are provisional: revalidate after HOLDLOCK.
 -- Existing global identity/session operations can still deadlock with this
 -- order. Caller rolls back; NO hidden retry. Two-connection QA is a later gate.
 EXEC dbo.usp_write_guard @tenant,N'PORTAL';
 DECLARE @mode nvarchar(11),@tenant_status nvarchar(9),@modules nvarchar(max);
 SELECT @mode=mode FROM dbo.application_state WITH(HOLDLOCK) WHERE id=1;
 IF @mode IS NULL OR DATALENGTH(@mode)<>8 OR @mode COLLATE Latin1_General_100_BIN2<>N'OPEN'
  THROW 51005,N'HP_APPLICATION_READ_ONLY:Business writes unavailable',1;
 SELECT @tenant_status=t.status,@modules=v.modules
 FROM dbo.tenants t WITH(UPDLOCK,HOLDLOCK)
 JOIN dbo.subscriptions s WITH(HOLDLOCK) ON s.tenant_id=t.id
 JOIN dbo.plan_versions v WITH(HOLDLOCK) ON v.plan_id=s.plan_id AND v.version=s.plan_version
 WHERE t.id=@tenant;
 IF @tenant_status IS NULL THROW 51002,N'HP_NOT_FOUND:Recurso no disponible en este espacio',1;
 IF NOT ((@tenant_status COLLATE Latin1_General_100_BIN2=N'ACTIVE' AND DATALENGTH(@tenant_status)=12)
 OR (@tenant_status COLLATE Latin1_General_100_BIN2=N'TRIAL' AND DATALENGTH(@tenant_status)=10))
  THROW 51004,N'HP_SUSPENDED:Tenant writes suspended',1;
 IF @modules IS NULL OR ISJSON(@modules,ARRAY)<>1
  THROW 51001,N'HP_FORBIDDEN:Module not included',1;
 IF NOT EXISTS(SELECT 1 FROM OPENJSON(@modules) WHERE type=1 AND value COLLATE Latin1_General_100_BIN2=N'PORTAL' AND DATALENGTH(value)=12)
  THROW 51001,N'HP_FORBIDDEN:Module not included',1;
 DECLARE @actor_active bit,@actor_verified bit,@actor_platform nvarchar(3),
  @session_user char(36),@session_tenant char(36),@revoked bit,@expires datetime2(6),
  @actor_status nvarchar(8),@actor_roles nvarchar(max);
 SELECT @actor_active=active,@actor_verified=email_verified,@actor_platform=platform_role
 FROM dbo.users WITH(HOLDLOCK) WHERE id=@actor;
 IF ISNULL(@actor_active,0)<>1 OR ISNULL(@actor_verified,0)<>1 OR @actor_platform IS NOT NULL
  THROW 51001,N'HP_FORBIDDEN:Internal administrative session required',1;
 SELECT @session_user=user_id,@session_tenant=tenant_id,@revoked=revoked,@expires=expires_at
 FROM dbo.auth_sessions WITH(HOLDLOCK) WHERE token_hash=@token;
 IF @session_user IS NULL OR @session_user<>@actor OR @session_tenant IS NULL OR @session_tenant<>@tenant
  OR ISNULL(@revoked,1)<>0 OR @expires IS NULL OR @expires<=SYSUTCDATETIME()
  THROW 51001,N'HP_FORBIDDEN:Internal administrative session required',1;
 SELECT @actor_status=status,@actor_roles=roles
 FROM dbo.memberships WITH(HOLDLOCK) WHERE tenant_id=@tenant AND user_id=@actor;
 IF @actor_status IS NULL OR @actor_status COLLATE Latin1_General_100_BIN2<>N'ACTIVE' OR DATALENGTH(@actor_status)<>12
  OR @actor_roles IS NULL OR ISJSON(@actor_roles,ARRAY)<>1
  THROW 51001,N'HP_FORBIDDEN:Internal administrative membership required',1;
 IF NOT EXISTS(SELECT 1 FROM OPENJSON(@actor_roles) WHERE type=1 AND value COLLATE Latin1_General_100_BIN2 IN (N'ADM',N'REC') AND DATALENGTH(value)=6)
  OR EXISTS(SELECT 1 FROM OPENJSON(@actor_roles) WHERE type<>1 OR value COLLATE Latin1_General_100_BIN2 IN (N'PAC',N'RES',N'SAD',N'SOP'))
  THROW 51001,N'HP_FORBIDDEN:Internal administrative membership required',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.patients WITH(HOLDLOCK) WHERE tenant_id=@tenant AND id=@patient_id)
  THROW 51002,N'HP_NOT_FOUND:Recurso no disponible en este espacio',1;

 -- Parse the complete JSON text, without WITH projections that can truncate
 -- or coerce. OPENJSON type2 retains numeric lexical text for the checks below.
 IF @input IS NULL OR ISJSON(@input,OBJECT)<>1
  THROW 51000,N'HP_INVALID:Objeto JSON requerido',1;
 DECLARE @fields TABLE([key] nvarchar(4000) COLLATE Latin1_General_100_BIN2,[value] nvarchar(max),[type] int);
 INSERT @fields SELECT [key],[value],[type] FROM OPENJSON(@input);
 IF EXISTS(SELECT 1 FROM @fields GROUP BY [key] COLLATE Latin1_General_100_BIN2,DATALENGTH([key]) HAVING COUNT(*)>1)
  OR NOT EXISTS(SELECT 1 FROM @fields WHERE [key]=N'active' AND DATALENGTH([key])=12 AND [type]=3 AND [value] COLLATE Latin1_General_100_BIN2 IN (N'true',N'false'))
  THROW 51000,N'HP_INVALID:Campos JSON invalidos',1;
 DECLARE @active bit=(SELECT CASE WHEN [value] COLLATE Latin1_General_100_BIN2=N'true' THEN 1 ELSE 0 END FROM @fields WHERE [key]=N'active' AND DATALENGTH([key])=12);
 DECLARE @contract TABLE([key] nvarchar(40) COLLATE Latin1_General_100_BIN2,[type] int);
 INSERT @contract VALUES(N'userId',1),(N'expectedRevision',2),(N'active',3);
 IF @active=1 INSERT @contract VALUES(N'relationship',1),(N'scopes',4);
 IF (SELECT COUNT(*) FROM @fields)<>(SELECT COUNT(*) FROM @contract)
  OR EXISTS(SELECT 1 FROM @fields f LEFT JOIN @contract c ON c.[key]=f.[key] AND DATALENGTH(c.[key])=DATALENGTH(f.[key]) WHERE c.[key] IS NULL OR c.[type]<>f.[type])
  OR EXISTS(SELECT 1 FROM @contract c WHERE NOT EXISTS(SELECT 1 FROM @fields f WHERE f.[key]=c.[key] AND DATALENGTH(f.[key])=DATALENGTH(c.[key]) AND f.[type]=c.[type]))
  THROW 51000,N'HP_INVALID:Campos JSON ausentes extras o de tipo incorrecto',1;
 DECLARE @user_raw nvarchar(max)=(SELECT [value] FROM @fields WHERE [key]=N'userId'),
  @expected_raw nvarchar(max)=(SELECT [value] FROM @fields WHERE [key]=N'expectedRevision'),
  @relationship nvarchar(max),@scopes nvarchar(max);
 IF @user_raw IS NULL OR DATALENGTH(@user_raw)<>72 OR TRY_CONVERT(uniqueidentifier,@user_raw) IS NULL
  OR @user_raw COLLATE Latin1_General_100_BIN2<>LOWER(CONVERT(nvarchar(36),TRY_CONVERT(uniqueidentifier,@user_raw))) COLLATE Latin1_General_100_BIN2
  THROW 51000,N'HP_INVALID:Canonical user UUID required',1;
 IF @expected_raw IS NULL OR DATALENGTH(@expected_raw) NOT BETWEEN 2 AND 20
  OR @expected_raw COLLATE Latin1_General_100_BIN2 LIKE N'%[^0-9]%'
  OR TRY_CONVERT(int,@expected_raw) IS NULL
  THROW 51000,N'HP_INVALID:Integer expected revision required',1;
 DECLARE @user char(36)=CONVERT(char(36),@user_raw),@expected int=CONVERT(int,@expected_raw);
 IF @active=1
 BEGIN
  SELECT @relationship=[value] FROM @fields WHERE [key]=N'relationship';
  SELECT @scopes=[value] FROM @fields WHERE [key]=N'scopes';
  -- UTF16 units (including trailing space/surrogate pairs), never LEN/truncate.
  IF @relationship IS NULL OR DATALENGTH(@relationship)>160
   OR DATALENGTH(TRIM(N' '+NCHAR(9)+NCHAR(10)+NCHAR(11)+NCHAR(12)+NCHAR(13)+NCHAR(160)+NCHAR(5760)
    +NCHAR(8192)+NCHAR(8193)+NCHAR(8194)+NCHAR(8195)+NCHAR(8196)+NCHAR(8197)+NCHAR(8198)
    +NCHAR(8199)+NCHAR(8200)+NCHAR(8201)+NCHAR(8202)+NCHAR(8232)+NCHAR(8233)+NCHAR(8239)+NCHAR(8287)+NCHAR(12288)
    FROM @relationship))=0
   THROW 51000,N'HP_INVALID:Relacion de vinculo invalida',1;
  IF @scopes IS NULL OR ISJSON(@scopes,ARRAY)<>1
   THROW 51000,N'HP_INVALID:Alcances de vinculo invalidos',1;
  IF NOT EXISTS(SELECT 1 FROM OPENJSON(@scopes))
   OR EXISTS(SELECT 1 FROM OPENJSON(@scopes) WHERE type<>1 OR NOT
    (value COLLATE Latin1_General_100_BIN2=N'APPOINTMENTS' AND DATALENGTH(value)=24
     OR value COLLATE Latin1_General_100_BIN2=N'DOCUMENTS' AND DATALENGTH(value)=18
     OR value COLLATE Latin1_General_100_BIN2=N'BILLING' AND DATALENGTH(value)=14))
   OR EXISTS(SELECT 1 FROM OPENJSON(@scopes) GROUP BY value COLLATE Latin1_General_100_BIN2,DATALENGTH(value) HAVING COUNT(*)>1)
   THROW 51000,N'HP_INVALID:Alcances de vinculo invalidos',1;
 END;
 -- Lock grant eligibility now, decide it only AFTER CAS so a stale existing
 -- version cannot turn into a silent update or an eligibility-dependent grant.
 -- Retraction intentionally performs NONE of these recipient eligibility reads.
 DECLARE @target_active bit,@target_verified bit,@target_platform nvarchar(3),
  @target_status nvarchar(8),@target_roles nvarchar(max);
 IF @active=1
 BEGIN
  SELECT @target_active=active,@target_verified=email_verified,@target_platform=platform_role
  FROM dbo.users WITH(HOLDLOCK) WHERE id=@user;
  SELECT @target_status=status,@target_roles=roles
  FROM dbo.memberships WITH(HOLDLOCK) WHERE tenant_id=@tenant AND user_id=@user;
 END;
 DECLARE @previous int,@revision int;
 SELECT @previous=revision FROM dbo.patient_links WITH(UPDLOCK,HOLDLOCK)
 WHERE tenant_id=@tenant AND patient_id=@patient_id AND user_id=@user;
 IF @previous IS NULL AND (@active=0 OR @expected>0)
  THROW 51002,N'HP_NOT_FOUND:Recurso no disponible en este espacio',1;
 IF @previous IS NOT NULL AND (@expected=0 OR @expected<>@previous OR @previous=2147483647)
  THROW 51003,N'HP_CONFLICT:El recurso cambio o la operacion entra en conflicto',1;
 IF @active=1
 BEGIN
  IF ISNULL(@target_active,0)<>1 OR ISNULL(@target_verified,0)<>1 OR @target_platform IS NOT NULL
   OR @target_status IS NULL OR @target_status COLLATE Latin1_General_100_BIN2<>N'ACTIVE' OR DATALENGTH(@target_status)<>12
   OR @target_roles IS NULL OR ISJSON(@target_roles,ARRAY)<>1
   THROW 51002,N'HP_NOT_FOUND:Recurso no disponible en este espacio',1;
  IF (SELECT COUNT(*) FROM OPENJSON(@target_roles)) NOT BETWEEN 1 AND 2
   OR EXISTS(SELECT 1 FROM OPENJSON(@target_roles) WHERE type<>1 OR value COLLATE Latin1_General_100_BIN2 NOT IN (N'PAC',N'RES') OR DATALENGTH(value)<>6)
   OR EXISTS(SELECT 1 FROM OPENJSON(@target_roles) GROUP BY value COLLATE Latin1_General_100_BIN2,DATALENGTH(value) HAVING COUNT(*)>1)
   THROW 51002,N'HP_NOT_FOUND:Recurso no disponible en este espacio',1;
 END;
 IF XACT_STATE()<>1 THROW 51000,N'HP_INVALID:Committable transaction required',1;
 IF @previous IS NULL
 BEGIN
  SET @previous=0;
  SET @revision=1;
  INSERT dbo.patient_links(tenant_id,patient_id,user_id,relationship,active,scopes,revision)
  VALUES(@tenant,@patient_id,@user,@relationship,1,@scopes,@revision);
 END
 ELSE
 BEGIN
  SET @revision=@previous+1; -- INTMAX was rejected before arithmetic.
  IF @active=1
   UPDATE dbo.patient_links SET relationship=@relationship,active=1,scopes=@scopes,revision=@revision
   WHERE tenant_id=@tenant AND patient_id=@patient_id AND user_id=@user AND revision=@previous;
  ELSE
   -- Byte-for-byte preservation of historical relationship/scopes, even when
   -- unusable for any grant. No delete, target-membership or session mutation.
   UPDATE dbo.patient_links SET active=0,revision=@revision
   WHERE tenant_id=@tenant AND patient_id=@patient_id AND user_id=@user AND revision=@previous;
  IF @@ROWCOUNT<>1 THROW 51003,N'HP_CONFLICT:El recurso cambio o la operacion entra en conflicto',1;
 END;
 DECLARE @operation nvarchar(10)=CASE WHEN @active=1 THEN N'SET' ELSE N'DEACTIVATE' END,
  @metadata nvarchar(max);
 SET @metadata=(SELECT @user AS userId,@active AS active,@previous AS previousRevision,@revision AS revision,@operation AS operation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.usp_audit_event @tenant_id=@tenant,@action=N'PORTAL_LINK_CHANGED',@target_id=@patient_id,@metadata=@metadata;
 -- V7 may omit a revision-only change event. Semantic event above is exactly
 -- one per accepted command, including SET identical or already-inactive.
 IF XACT_STATE()<>1 THROW 51000,N'HP_INVALID:Committable transaction required',1;
 SELECT tenant_id,patient_id,user_id,active,revision FROM dbo.patient_links
 WHERE tenant_id=@tenant AND patient_id=@patient_id AND user_id=@user;
END;
GO
CREATE PROCEDURE dbo.usp_patient_link_edit_get @patient_id char(36),@user_id char(36)
AS
BEGIN
 SET NOCOUNT ON;
 SET XACT_ABORT ON;

 -- Reuse V10 to materialize ONLY a caller-selected implicit transaction.
 -- Caller retains commit/rollback ownership; autocommit remains rejected.
 -- Reject doom before the helper; no business result/audit/mutation precedes
 -- this boundary or its committable check (no prior business read required).
 IF XACT_STATE()=-1
  THROW 51000,N'HP_INVALID:External committable transaction required',1;
 EXEC dbo.usp_require_transaction;
 IF @@TRANCOUNT=0 OR XACT_STATE()<>1
  THROW 51000,N'HP_INVALID:External committable transaction required',1;
 -- Keep complete sql_variant strings until type/length/canonical validation.
 -- hp_actor_roles is audit-only; it NEVER grants authority in this operation.
 IF ISNULL(CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(SESSION_CONTEXT(N'hp_scope'),'BaseType')),N'') NOT IN (N'varchar',N'nvarchar',N'char',N'nchar')
  OR ISNULL(CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(SESSION_CONTEXT(N'hp_tenant_id'),'BaseType')),N'') NOT IN (N'varchar',N'nvarchar',N'char',N'nchar')
  OR ISNULL(CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(SESSION_CONTEXT(N'hp_actor_id'),'BaseType')),N'') NOT IN (N'varchar',N'nvarchar',N'char',N'nchar')
  OR ISNULL(CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(SESSION_CONTEXT(N'hp_request_id'),'BaseType')),N'') NOT IN (N'varchar',N'nvarchar',N'char',N'nchar')
  OR ISNULL(CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(SESSION_CONTEXT(N'hp_token_hash'),'BaseType')),N'') NOT IN (N'varchar',N'nvarchar',N'char',N'nchar')
  OR ISNULL(CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(SESSION_CONTEXT(N'hp_method'),'BaseType')),N'') NOT IN (N'varchar',N'nvarchar',N'char',N'nchar')
  OR ISNULL(CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(SESSION_CONTEXT(N'hp_route'),'BaseType')),N'') NOT IN (N'varchar',N'nvarchar',N'char',N'nchar')
  THROW 51001,N'HP_FORBIDDEN:Complete trusted request context required',1;
 DECLARE @scope_raw nvarchar(max)=CONVERT(nvarchar(max),SESSION_CONTEXT(N'hp_scope')),
  @tenant_raw nvarchar(max)=CONVERT(nvarchar(max),SESSION_CONTEXT(N'hp_tenant_id')),
  @actor_raw nvarchar(max)=CONVERT(nvarchar(max),SESSION_CONTEXT(N'hp_actor_id')),
  @request_raw nvarchar(max)=CONVERT(nvarchar(max),SESSION_CONTEXT(N'hp_request_id')),
  @token_raw nvarchar(max)=CONVERT(nvarchar(max),SESSION_CONTEXT(N'hp_token_hash')),
  @method_raw nvarchar(max)=CONVERT(nvarchar(max),SESSION_CONTEXT(N'hp_method')),
  @route_raw nvarchar(max)=CONVERT(nvarchar(max),SESSION_CONTEXT(N'hp_route'));
 IF @scope_raw IS NULL OR DATALENGTH(@scope_raw)<>14 OR @scope_raw COLLATE Latin1_General_100_BIN2<>N'REQUEST'
  THROW 51001,N'HP_FORBIDDEN:Request scope required',1;
 IF @tenant_raw IS NULL OR DATALENGTH(@tenant_raw)<>72 OR TRY_CONVERT(uniqueidentifier,@tenant_raw) IS NULL
  OR @tenant_raw COLLATE Latin1_General_100_BIN2<>LOWER(CONVERT(nvarchar(36),TRY_CONVERT(uniqueidentifier,@tenant_raw))) COLLATE Latin1_General_100_BIN2
  OR @actor_raw IS NULL OR DATALENGTH(@actor_raw)<>72 OR TRY_CONVERT(uniqueidentifier,@actor_raw) IS NULL
  OR @actor_raw COLLATE Latin1_General_100_BIN2<>LOWER(CONVERT(nvarchar(36),TRY_CONVERT(uniqueidentifier,@actor_raw))) COLLATE Latin1_General_100_BIN2
  OR @request_raw IS NULL OR DATALENGTH(@request_raw)<>72 OR TRY_CONVERT(uniqueidentifier,@request_raw) IS NULL
  OR @request_raw COLLATE Latin1_General_100_BIN2<>LOWER(CONVERT(nvarchar(36),TRY_CONVERT(uniqueidentifier,@request_raw))) COLLATE Latin1_General_100_BIN2
  OR @token_raw IS NULL OR DATALENGTH(@token_raw)<>128 OR @token_raw COLLATE Latin1_General_100_BIN2 LIKE N'%[^0-9a-f]%'
  OR @method_raw IS NULL OR DATALENGTH(@method_raw) NOT BETWEEN 2 AND 20 OR DATALENGTH(LTRIM(RTRIM(@method_raw)))=0
  OR @route_raw IS NULL OR DATALENGTH(@route_raw) NOT BETWEEN 2 AND 500 OR DATALENGTH(LTRIM(RTRIM(@route_raw)))=0
  THROW 51001,N'HP_FORBIDDEN:Canonical complete request context required',1;
 DECLARE @tenant char(36)=CONVERT(char(36),@tenant_raw),@actor char(36)=CONVERT(char(36),@actor_raw),
  @token char(64)=CONVERT(char(64),@token_raw);
 -- Q1: these fixed CHAR parameters can validate only the received value.
 -- C2 MUST reject a longer original HTTP ID BEFORE RPC binding; this SP cannot
 -- recover a prefix that SQL parameter binding has already truncated.
 IF @patient_id IS NULL OR DATALENGTH(@patient_id)<>36 OR TRY_CONVERT(uniqueidentifier,@patient_id) IS NULL
  OR @patient_id COLLATE Latin1_General_100_BIN2<>LOWER(CONVERT(char(36),TRY_CONVERT(uniqueidentifier,@patient_id))) COLLATE Latin1_General_100_BIN2
  THROW 51000,N'HP_INVALID:Canonical patient UUID required',1;

 -- Order shared with existing tenant business writes: write_guard acquires
 -- application_state then tenant/subscription guard; retain subscription/plan
 -- explicitly, then actor user -> session -> actor membership -> patient ->
 -- target user/membership (SET only; reader target user) -> link PK key/range.
 -- Initial helper authority reads are provisional: revalidate after HOLDLOCK.
 -- Existing global identity/session operations can still deadlock with this
 -- order. Caller rolls back; NO hidden retry. Two-connection QA is a later gate.
 EXEC dbo.usp_write_guard @tenant,N'PORTAL';
 DECLARE @mode nvarchar(11),@tenant_status nvarchar(9),@modules nvarchar(max);
 SELECT @mode=mode FROM dbo.application_state WITH(HOLDLOCK) WHERE id=1;
 IF @mode IS NULL OR DATALENGTH(@mode)<>8 OR @mode COLLATE Latin1_General_100_BIN2<>N'OPEN'
  THROW 51005,N'HP_APPLICATION_READ_ONLY:Business writes unavailable',1;
 SELECT @tenant_status=t.status,@modules=v.modules
 FROM dbo.tenants t WITH(UPDLOCK,HOLDLOCK)
 JOIN dbo.subscriptions s WITH(HOLDLOCK) ON s.tenant_id=t.id
 JOIN dbo.plan_versions v WITH(HOLDLOCK) ON v.plan_id=s.plan_id AND v.version=s.plan_version
 WHERE t.id=@tenant;
 IF @tenant_status IS NULL THROW 51002,N'HP_NOT_FOUND:Recurso no disponible en este espacio',1;
 IF NOT ((@tenant_status COLLATE Latin1_General_100_BIN2=N'ACTIVE' AND DATALENGTH(@tenant_status)=12)
 OR (@tenant_status COLLATE Latin1_General_100_BIN2=N'TRIAL' AND DATALENGTH(@tenant_status)=10))
  THROW 51004,N'HP_SUSPENDED:Tenant writes suspended',1;
 IF @modules IS NULL OR ISJSON(@modules,ARRAY)<>1
  THROW 51001,N'HP_FORBIDDEN:Module not included',1;
 IF NOT EXISTS(SELECT 1 FROM OPENJSON(@modules) WHERE type=1 AND value COLLATE Latin1_General_100_BIN2=N'PORTAL' AND DATALENGTH(value)=12)
  THROW 51001,N'HP_FORBIDDEN:Module not included',1;
 DECLARE @actor_active bit,@actor_verified bit,@actor_platform nvarchar(3),
  @session_user char(36),@session_tenant char(36),@revoked bit,@expires datetime2(6),
  @actor_status nvarchar(8),@actor_roles nvarchar(max);
 SELECT @actor_active=active,@actor_verified=email_verified,@actor_platform=platform_role
 FROM dbo.users WITH(HOLDLOCK) WHERE id=@actor;
 IF ISNULL(@actor_active,0)<>1 OR ISNULL(@actor_verified,0)<>1 OR @actor_platform IS NOT NULL
  THROW 51001,N'HP_FORBIDDEN:Internal administrative session required',1;
 SELECT @session_user=user_id,@session_tenant=tenant_id,@revoked=revoked,@expires=expires_at
 FROM dbo.auth_sessions WITH(HOLDLOCK) WHERE token_hash=@token;
 IF @session_user IS NULL OR @session_user<>@actor OR @session_tenant IS NULL OR @session_tenant<>@tenant
  OR ISNULL(@revoked,1)<>0 OR @expires IS NULL OR @expires<=SYSUTCDATETIME()
  THROW 51001,N'HP_FORBIDDEN:Internal administrative session required',1;
 SELECT @actor_status=status,@actor_roles=roles
 FROM dbo.memberships WITH(HOLDLOCK) WHERE tenant_id=@tenant AND user_id=@actor;
 IF @actor_status IS NULL OR @actor_status COLLATE Latin1_General_100_BIN2<>N'ACTIVE' OR DATALENGTH(@actor_status)<>12
  OR @actor_roles IS NULL OR ISJSON(@actor_roles,ARRAY)<>1
  THROW 51001,N'HP_FORBIDDEN:Internal administrative membership required',1;
 IF NOT EXISTS(SELECT 1 FROM OPENJSON(@actor_roles) WHERE type=1 AND value COLLATE Latin1_General_100_BIN2 IN (N'ADM',N'REC') AND DATALENGTH(value)=6)
  OR EXISTS(SELECT 1 FROM OPENJSON(@actor_roles) WHERE type<>1 OR value COLLATE Latin1_General_100_BIN2 IN (N'PAC',N'RES',N'SAD',N'SOP'))
  THROW 51001,N'HP_FORBIDDEN:Internal administrative membership required',1;
 IF NOT EXISTS(SELECT 1 FROM dbo.patients WITH(HOLDLOCK) WHERE tenant_id=@tenant AND id=@patient_id)
  THROW 51002,N'HP_NOT_FOUND:Recurso no disponible en este espacio',1;

 IF @user_id IS NULL OR DATALENGTH(@user_id)<>36 OR TRY_CONVERT(uniqueidentifier,@user_id) IS NULL
  OR @user_id COLLATE Latin1_General_100_BIN2<>LOWER(CONVERT(char(36),TRY_CONVERT(uniqueidentifier,@user_id))) COLLATE Latin1_General_100_BIN2
  THROW 51000,N'HP_INVALID:Canonical user UUID required',1;
 -- Lock identity name, not eligibility: inactive/unverified/departed accounts
 -- remain visible in this specific historical edit snapshot.
 DECLARE @name nvarchar(160),@revision int;
 SELECT @name=name FROM dbo.users WITH(HOLDLOCK) WHERE id=@user_id;
 SELECT @revision=revision FROM dbo.patient_links WITH(HOLDLOCK)
 WHERE tenant_id=@tenant AND patient_id=@patient_id AND user_id=@user_id;
 IF @name IS NULL OR @revision IS NULL
  THROW 51002,N'HP_NOT_FOUND:Recurso no disponible en este espacio',1;
 DECLARE @metadata nvarchar(max)=(SELECT @user_id AS userId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC dbo.usp_audit_event @tenant_id=@tenant,@action=N'PATIENT_LINK_EDIT_READ',@target_id=@patient_id,@metadata=@metadata;
 IF XACT_STATE()<>1 THROW 51000,N'HP_INVALID:Committable transaction required',1;
 -- EXACT eight columns. Historical scopes are raw JSON, never a permission.
 -- Both identity and link remain locked until the caller completes its TX.
 SELECT l.tenant_id,l.patient_id,l.user_id,u.name AS user_name,l.relationship,l.active,l.scopes,l.revision
 FROM dbo.patient_links l JOIN dbo.users u ON u.id=l.user_id
 WHERE l.tenant_id=@tenant AND l.patient_id=@patient_id AND l.user_id=@user_id;
END;
GO
IF @@TRANCOUNT=0 OR XACT_STATE()<>1
 THROW 51000,N'HP_INVALID:External committable migration transaction required',1;
GRANT EXECUTE ON OBJECT::dbo.usp_patient_link_edit_get TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_patient_link_edit_get TO hp_bootstrap_executor;
GO
