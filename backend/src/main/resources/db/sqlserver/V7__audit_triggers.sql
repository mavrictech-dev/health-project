-- SQL-01.A6 / SQL Server 2022 compat 160. Dependencies: accepted dbo tables V1 and
-- the audit_events/SESSION_CONTEXT contract of V3.usp_audit_change.
-- Sources: MySQL V10__business_change_triggers.sql (29 targets), V9 immutable audit.
-- D-14.A: four structured safe values become *_sha256, never escaped JSON arrays.
-- support_comments attribution comes from EACH state's own ticket, not hp_tenant_id;
-- a missing parent is an integrity error, never an implicit platform/global event.
--
-- One AFTER INSERT,UPDATE,DELETE trigger per business table; all work is set based.
-- The FULL JOIN uses the COMPLETE primary key plus the evidence tenant. Stable-key
-- changes emit UPDATE; a key/tenant rewrite emits DELETE(old)+INSERT(new), since
-- no stable row identity exists to pair arbitrary composite-key rewrites. Empty
-- inserted/deleted sets emit nothing. Unprojected-only changes and identical safe
-- projections emit nothing. BIN2 comparison plus DATALENGTH preserves case,
-- accents and trailing spaces; INCLUDE_NULL_VALUES preserves SQL NULL separately
-- from the literal text 'null', empty text, and a hex SHA256 value.
--
-- D-14.B hash pipeline: original NVARCHAR(MAX) value -> direct INSERT SELECT
-- into a local VARCHAR(MAX) column COLLATE Latin1_General_100_BIN2_UTF8, THEN
-- HASHBYTES SHA2_256 of that STORED UTF8 column -> lowercase 64 hex chars.
-- A table-variable assignment is the conversion/materialization boundary:
-- inline CONVERT(varchar, Unicode-column COLLATE UTF8) lost CJK/emoji on our
-- SQL2022 engine, and another output COLLATE cannot recover lost characters.
-- No such inline VARCHAR conversion remains in these 40 before/after hashes.
-- Each local row is identified by I/D side and COMPLETE, original-typed PK;
-- key collations match V1. Plaintext lives only in transient hashing input,
-- never audit evidence, a resultset, a permanent helper/table, or a general log.
-- Do NOT hash NVARCHAR directly (UTF16), round-trip through a non-UTF8 code page,
-- cast to bounded VARCHAR(4000/8000), parse JSON scalars or normalize JSON arrays.
-- Birth DATE first becomes ISO yyyy-MM-dd NVARCHAR(MAX), preserving SQL NULL.
-- Supervisor engine matrix: ASCII, case/accent/trailing-space changes, emoji,
-- >4000 characters and >8000 UTF8 bytes, SQL NULL versus N'null' versus empty,
-- multirow INSERT/UPDATE/DELETE/MERGE, composite-key and cross-tenant rewrites,
-- no-op, missing-ticket rejection, context capture and transaction rollback.
--
-- Each trigger inserts the same explicit audit columns/action/metadata as the
-- private scalar usp_audit_change, but in ONE set-based INSERT (no cursor and no
-- new runtime entry point). Fixed whitelisted projections are flat scalar JSON;
-- before/after JSON text is stored directly, never wrapped/escaped as a string.
-- Context is copied from trusted Spring/V3 hp_* keys, never from row payloads.
-- Trigger work belongs to the firing statement's transaction. No COMMIT/ROLLBACK,
-- independent transaction, DDL permissions, EXECUTE AS or hp_scope bypass.
-- audit_events has only unconditional UPDATE/DELETE denial triggers, so audit
-- INSERT cannot recursively re-enter business audit. Existing FKs/retention are
-- preserved; immutable audit must not be disabled to facilitate fixture cleanup.
-- V7 does NOT activate JDBC/HTTP or grant runtime access to any table or procedure.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Matrix: users | PK(id) | I/U/D | target_id=id
-- Tenant: NULL (historical global); join complete PK + evidence tenant.
-- Safe scalars: id,name,active,clinical_domain,platform_role,email_verified.
-- SHA256 UTF8: password_hash_sha256<-password_hash.
CREATE TRIGGER dbo.trace_users_change ON dbo.[users]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 -- D-14.B: materialize original Unicode directly into UTF8-typed local columns.
 -- Do not inline CONVERT(varchar) here: real-column evaluation lost code points.
 -- No persistent object/output/log; side + COMPLETE PK keeps I/D values separate.
 DECLARE @hash_utf8 TABLE (
  [_side] char(1) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k0] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [password_hash_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  PRIMARY KEY ([_side],[_k0])
 );
 INSERT @hash_utf8([_side],[_k0],[password_hash_utf8])
 SELECT 'I',r.[id],
   CONVERT(nvarchar(max),r.[password_hash])
 FROM inserted r
 UNION ALL
 SELECT 'D',r.[id],
   CONVERT(nvarchar(max),r.[password_hash])
 FROM deleted r;
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   CONVERT(char(36),NULL) AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[name] AS [name],
       r.[active] AS [active],
       r.[clinical_domain] AS [clinical_domain],
       r.[platform_role] AS [platform_role],
       r.[email_verified] AS [email_verified],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[password_hash_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[id])),2)) AS [password_hash_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   CONVERT(char(36),NULL) AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[name] AS [name],
       r.[active] AS [active],
       r.[clinical_domain] AS [clinical_domain],
       r.[platform_role] AS [platform_role],
       r.[email_verified] AS [email_verified],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[password_hash_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[id])),2)) AS [password_hash_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'users_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'users'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: plans | PK(id) | I/U/D | target_id=id
-- Tenant: NULL (historical global); join complete PK + evidence tenant.
-- Safe scalars: id,name,status,current_version.
-- SHA256 UTF8: none.
CREATE TRIGGER dbo.trace_plans_change ON dbo.[plans]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   CONVERT(char(36),NULL) AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[name] AS [name],
       r.[status] AS [status],
       r.[current_version] AS [current_version]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   CONVERT(char(36),NULL) AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[name] AS [name],
       r.[status] AS [status],
       r.[current_version] AS [current_version]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'plans_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'plans'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: plan_versions | PK(plan_id,version) | I/U/D | target_id=plan_id
-- Tenant: NULL (historical global); join complete PK + evidence tenant.
-- Safe scalars: plan_id,version,base_minor,branch_minor,professional_minor,included_branches,included_professionals,max_branches,max_professionals,max_specialties.
-- SHA256 UTF8: modules_sha256<-modules.
CREATE TRIGGER dbo.trace_plan_versions_change ON dbo.[plan_versions]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 -- D-14.B: materialize original Unicode directly into UTF8-typed local columns.
 -- Do not inline CONVERT(varchar) here: real-column evaluation lost code points.
 -- No persistent object/output/log; side + COMPLETE PK keeps I/D values separate.
 DECLARE @hash_utf8 TABLE (
  [_side] char(1) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k0] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k1] INT NOT NULL,
  [modules_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  PRIMARY KEY ([_side],[_k0],[_k1])
 );
 INSERT @hash_utf8([_side],[_k0],[_k1],[modules_utf8])
 SELECT 'I',r.[plan_id],r.[version],
   CONVERT(nvarchar(max),r.[modules])
 FROM inserted r
 UNION ALL
 SELECT 'D',r.[plan_id],r.[version],
   CONVERT(nvarchar(max),r.[modules])
 FROM deleted r;
 ;WITH
 new_rows AS (
  SELECT r.[plan_id] AS [_k0],r.[version] AS [_k1],
   CONVERT(char(36),NULL) AS [evidence_tenant],CONVERT(nvarchar(100),r.[plan_id]) AS [target],
   (SELECT r.[plan_id] AS [plan_id],
       r.[version] AS [version],
       r.[base_minor] AS [base_minor],
       r.[branch_minor] AS [branch_minor],
       r.[professional_minor] AS [professional_minor],
       r.[included_branches] AS [included_branches],
       r.[included_professionals] AS [included_professionals],
       r.[max_branches] AS [max_branches],
       r.[max_professionals] AS [max_professionals],
       r.[max_specialties] AS [max_specialties],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[modules_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[plan_id] AND u.[_k1]=r.[version])),2)) AS [modules_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[plan_id] AS [_k0],r.[version] AS [_k1],
   CONVERT(char(36),NULL) AS [evidence_tenant],CONVERT(nvarchar(100),r.[plan_id]) AS [target],
   (SELECT r.[plan_id] AS [plan_id],
       r.[version] AS [version],
       r.[base_minor] AS [base_minor],
       r.[branch_minor] AS [branch_minor],
       r.[professional_minor] AS [professional_minor],
       r.[included_branches] AS [included_branches],
       r.[included_professionals] AS [included_professionals],
       r.[max_branches] AS [max_branches],
       r.[max_professionals] AS [max_professionals],
       r.[max_specialties] AS [max_specialties],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[modules_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[plan_id] AND u.[_k1]=r.[version])),2)) AS [modules_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0] AND n.[_k1]=o.[_k1]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'plan_versions_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'plan_versions'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: tenants | PK(id) | I/U/D | target_id=id
-- Tenant: NULL (historical global); join complete PK + evidence tenant.
-- Safe scalars: id,name,slug,kind,domain,status,owner_user_id,timezone.
-- SHA256 UTF8: none.
CREATE TRIGGER dbo.trace_tenants_change ON dbo.[tenants]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   CONVERT(char(36),NULL) AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[name] AS [name],
       r.[slug] AS [slug],
       r.[kind] AS [kind],
       r.[domain] AS [domain],
       r.[status] AS [status],
       r.[owner_user_id] AS [owner_user_id],
       r.[timezone] AS [timezone]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   CONVERT(char(36),NULL) AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[name] AS [name],
       r.[slug] AS [slug],
       r.[kind] AS [kind],
       r.[domain] AS [domain],
       r.[status] AS [status],
       r.[owner_user_id] AS [owner_user_id],
       r.[timezone] AS [timezone]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'tenants_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'tenants'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: subscriptions | PK(tenant_id) | I/U/D | target_id=plan_id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: tenant_id,plan_id,plan_version,cycle,branch_quota,professional_quota,specialty_quota,renewal_date.
-- SHA256 UTF8: none.
CREATE TRIGGER dbo.trace_subscriptions_change ON dbo.[subscriptions]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 ;WITH
 new_rows AS (
  SELECT r.[tenant_id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[plan_id]) AS [target],
   (SELECT r.[tenant_id] AS [tenant_id],
       r.[plan_id] AS [plan_id],
       r.[plan_version] AS [plan_version],
       r.[cycle] AS [cycle],
       r.[branch_quota] AS [branch_quota],
       r.[professional_quota] AS [professional_quota],
       r.[specialty_quota] AS [specialty_quota],
       r.[renewal_date] AS [renewal_date]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[tenant_id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[plan_id]) AS [target],
   (SELECT r.[tenant_id] AS [tenant_id],
       r.[plan_id] AS [plan_id],
       r.[plan_version] AS [plan_version],
       r.[cycle] AS [cycle],
       r.[branch_quota] AS [branch_quota],
       r.[professional_quota] AS [professional_quota],
       r.[specialty_quota] AS [specialty_quota],
       r.[renewal_date] AS [renewal_date]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'subscriptions_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'subscriptions'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: tenant_specialties | PK(tenant_id,specialty_code) | I/U/D | target_id=tenant_id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: tenant_id,specialty_code.
-- SHA256 UTF8: none.
CREATE TRIGGER dbo.trace_tenant_specialties_change ON dbo.[tenant_specialties]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 ;WITH
 new_rows AS (
  SELECT r.[tenant_id] AS [_k0],r.[specialty_code] AS [_k1],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[tenant_id]) AS [target],
   (SELECT r.[tenant_id] AS [tenant_id],
       r.[specialty_code] AS [specialty_code]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[tenant_id] AS [_k0],r.[specialty_code] AS [_k1],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[tenant_id]) AS [target],
   (SELECT r.[tenant_id] AS [tenant_id],
       r.[specialty_code] AS [specialty_code]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0] AND n.[_k1]=o.[_k1]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'tenant_specialties_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'tenant_specialties'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: branches | PK(id) | I/U/D | target_id=id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,tenant_id,name,external,active.
-- SHA256 UTF8: none.
CREATE TRIGGER dbo.trace_branches_change ON dbo.[branches]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[name] AS [name],
       r.[external] AS [external],
       r.[active] AS [active]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[name] AS [name],
       r.[external] AS [external],
       r.[active] AS [active]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'branches_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'branches'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: areas | PK(id) | I/U/D | target_id=id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,tenant_id,branch_id,name.
-- SHA256 UTF8: specialties_sha256<-specialties.
CREATE TRIGGER dbo.trace_areas_change ON dbo.[areas]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 -- D-14.B: materialize original Unicode directly into UTF8-typed local columns.
 -- Do not inline CONVERT(varchar) here: real-column evaluation lost code points.
 -- No persistent object/output/log; side + COMPLETE PK keeps I/D values separate.
 DECLARE @hash_utf8 TABLE (
  [_side] char(1) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k0] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [specialties_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  PRIMARY KEY ([_side],[_k0])
 );
 INSERT @hash_utf8([_side],[_k0],[specialties_utf8])
 SELECT 'I',r.[id],
   CONVERT(nvarchar(max),r.[specialties])
 FROM inserted r
 UNION ALL
 SELECT 'D',r.[id],
   CONVERT(nvarchar(max),r.[specialties])
 FROM deleted r;
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[branch_id] AS [branch_id],
       r.[name] AS [name],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[specialties_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[id])),2)) AS [specialties_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[branch_id] AS [branch_id],
       r.[name] AS [name],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[specialties_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[id])),2)) AS [specialties_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'areas_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'areas'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: memberships | PK(tenant_id,user_id) | I/U/D | target_id=user_id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: tenant_id,user_id,status,owner.
-- SHA256 UTF8: roles_sha256<-roles.
CREATE TRIGGER dbo.trace_memberships_change ON dbo.[memberships]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 -- D-14.B: materialize original Unicode directly into UTF8-typed local columns.
 -- Do not inline CONVERT(varchar) here: real-column evaluation lost code points.
 -- No persistent object/output/log; side + COMPLETE PK keeps I/D values separate.
 DECLARE @hash_utf8 TABLE (
  [_side] char(1) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k0] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k1] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [roles_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  PRIMARY KEY ([_side],[_k0],[_k1])
 );
 INSERT @hash_utf8([_side],[_k0],[_k1],[roles_utf8])
 SELECT 'I',r.[tenant_id],r.[user_id],
   CONVERT(nvarchar(max),r.[roles])
 FROM inserted r
 UNION ALL
 SELECT 'D',r.[tenant_id],r.[user_id],
   CONVERT(nvarchar(max),r.[roles])
 FROM deleted r;
 ;WITH
 new_rows AS (
  SELECT r.[tenant_id] AS [_k0],r.[user_id] AS [_k1],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[user_id]) AS [target],
   (SELECT r.[tenant_id] AS [tenant_id],
       r.[user_id] AS [user_id],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[roles_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[tenant_id] AND u.[_k1]=r.[user_id])),2)) AS [roles_sha256],
       r.[status] AS [status],
       r.[owner] AS [owner]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[tenant_id] AS [_k0],r.[user_id] AS [_k1],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[user_id]) AS [target],
   (SELECT r.[tenant_id] AS [tenant_id],
       r.[user_id] AS [user_id],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[roles_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[tenant_id] AND u.[_k1]=r.[user_id])),2)) AS [roles_sha256],
       r.[status] AS [status],
       r.[owner] AS [owner]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0] AND n.[_k1]=o.[_k1]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'memberships_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'memberships'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: membership_branches | PK(tenant_id,user_id,branch_id) | I/U/D | target_id=user_id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: tenant_id,user_id,branch_id.
-- SHA256 UTF8: none.
CREATE TRIGGER dbo.trace_membership_branches_change ON dbo.[membership_branches]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 ;WITH
 new_rows AS (
  SELECT r.[tenant_id] AS [_k0],r.[user_id] AS [_k1],r.[branch_id] AS [_k2],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[user_id]) AS [target],
   (SELECT r.[tenant_id] AS [tenant_id],
       r.[user_id] AS [user_id],
       r.[branch_id] AS [branch_id]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[tenant_id] AS [_k0],r.[user_id] AS [_k1],r.[branch_id] AS [_k2],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[user_id]) AS [target],
   (SELECT r.[tenant_id] AS [tenant_id],
       r.[user_id] AS [user_id],
       r.[branch_id] AS [branch_id]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0] AND n.[_k1]=o.[_k1] AND n.[_k2]=o.[_k2]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'membership_branches_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'membership_branches'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: membership_specialties | PK(tenant_id,user_id,specialty_code) | I/U/D | target_id=user_id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: tenant_id,user_id,specialty_code.
-- SHA256 UTF8: none.
CREATE TRIGGER dbo.trace_membership_specialties_change ON dbo.[membership_specialties]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 ;WITH
 new_rows AS (
  SELECT r.[tenant_id] AS [_k0],r.[user_id] AS [_k1],r.[specialty_code] AS [_k2],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[user_id]) AS [target],
   (SELECT r.[tenant_id] AS [tenant_id],
       r.[user_id] AS [user_id],
       r.[specialty_code] AS [specialty_code]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[tenant_id] AS [_k0],r.[user_id] AS [_k1],r.[specialty_code] AS [_k2],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[user_id]) AS [target],
   (SELECT r.[tenant_id] AS [tenant_id],
       r.[user_id] AS [user_id],
       r.[specialty_code] AS [specialty_code]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0] AND n.[_k1]=o.[_k1] AND n.[_k2]=o.[_k2]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'membership_specialties_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'membership_specialties'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: patients | PK(id) | I/U/D | target_id=id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,tenant_id,domain,revision.
-- SHA256 UTF8: name_sha256<-name,identifier_sha256<-identifier,birth_date_sha256<-birth_date,species_sha256<-species,contact_sha256<-contact,allergies_sha256<-allergies.
CREATE TRIGGER dbo.trace_patients_change ON dbo.[patients]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 -- D-14.B: materialize original Unicode directly into UTF8-typed local columns.
 -- Do not inline CONVERT(varchar) here: real-column evaluation lost code points.
 -- No persistent object/output/log; side + COMPLETE PK keeps I/D values separate.
 DECLARE @hash_utf8 TABLE (
  [_side] char(1) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k0] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [name_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  [identifier_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  [birth_date_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  [species_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  [contact_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  [allergies_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  PRIMARY KEY ([_side],[_k0])
 );
 INSERT @hash_utf8([_side],[_k0],[name_utf8],[identifier_utf8],[birth_date_utf8],[species_utf8],[contact_utf8],[allergies_utf8])
 SELECT 'I',r.[id],
   CONVERT(nvarchar(max),r.[name]),
   CONVERT(nvarchar(max),r.[identifier]),
   CONVERT(nvarchar(max),r.[birth_date],23),
   CONVERT(nvarchar(max),r.[species]),
   CONVERT(nvarchar(max),r.[contact]),
   CONVERT(nvarchar(max),r.[allergies])
 FROM inserted r
 UNION ALL
 SELECT 'D',r.[id],
   CONVERT(nvarchar(max),r.[name]),
   CONVERT(nvarchar(max),r.[identifier]),
   CONVERT(nvarchar(max),r.[birth_date],23),
   CONVERT(nvarchar(max),r.[species]),
   CONVERT(nvarchar(max),r.[contact]),
   CONVERT(nvarchar(max),r.[allergies])
 FROM deleted r;
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[domain] AS [domain],
       r.[revision] AS [revision],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[name_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[id])),2)) AS [name_sha256],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[identifier_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[id])),2)) AS [identifier_sha256],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[birth_date_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[id])),2)) AS [birth_date_sha256],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[species_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[id])),2)) AS [species_sha256],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[contact_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[id])),2)) AS [contact_sha256],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[allergies_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[id])),2)) AS [allergies_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[domain] AS [domain],
       r.[revision] AS [revision],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[name_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[id])),2)) AS [name_sha256],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[identifier_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[id])),2)) AS [identifier_sha256],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[birth_date_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[id])),2)) AS [birth_date_sha256],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[species_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[id])),2)) AS [species_sha256],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[contact_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[id])),2)) AS [contact_sha256],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[allergies_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[id])),2)) AS [allergies_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'patients_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'patients'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: patient_links | PK(tenant_id,patient_id,user_id) | I/U/D | target_id=user_id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: tenant_id,patient_id,user_id,relationship,active.
-- SHA256 UTF8: scopes_sha256<-scopes.
CREATE TRIGGER dbo.trace_patient_links_change ON dbo.[patient_links]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 -- D-14.B: materialize original Unicode directly into UTF8-typed local columns.
 -- Do not inline CONVERT(varchar) here: real-column evaluation lost code points.
 -- No persistent object/output/log; side + COMPLETE PK keeps I/D values separate.
 DECLARE @hash_utf8 TABLE (
  [_side] char(1) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k0] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k1] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k2] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [scopes_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  PRIMARY KEY ([_side],[_k0],[_k1],[_k2])
 );
 INSERT @hash_utf8([_side],[_k0],[_k1],[_k2],[scopes_utf8])
 SELECT 'I',r.[tenant_id],r.[patient_id],r.[user_id],
   CONVERT(nvarchar(max),r.[scopes])
 FROM inserted r
 UNION ALL
 SELECT 'D',r.[tenant_id],r.[patient_id],r.[user_id],
   CONVERT(nvarchar(max),r.[scopes])
 FROM deleted r;
 ;WITH
 new_rows AS (
  SELECT r.[tenant_id] AS [_k0],r.[patient_id] AS [_k1],r.[user_id] AS [_k2],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[user_id]) AS [target],
   (SELECT r.[tenant_id] AS [tenant_id],
       r.[patient_id] AS [patient_id],
       r.[user_id] AS [user_id],
       r.[relationship] AS [relationship],
       r.[active] AS [active],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[scopes_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[tenant_id] AND u.[_k1]=r.[patient_id] AND u.[_k2]=r.[user_id])),2)) AS [scopes_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[tenant_id] AS [_k0],r.[patient_id] AS [_k1],r.[user_id] AS [_k2],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[user_id]) AS [target],
   (SELECT r.[tenant_id] AS [tenant_id],
       r.[patient_id] AS [patient_id],
       r.[user_id] AS [user_id],
       r.[relationship] AS [relationship],
       r.[active] AS [active],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[scopes_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[tenant_id] AND u.[_k1]=r.[patient_id] AND u.[_k2]=r.[user_id])),2)) AS [scopes_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0] AND n.[_k1]=o.[_k1] AND n.[_k2]=o.[_k2]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'patient_links_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'patient_links'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: appointments | PK(id) | I/U/D | target_id=id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,tenant_id,patient_id,branch_id,professional_id,specialty_code,starts_at,ends_at,status,revision.
-- SHA256 UTF8: note_sha256<-note.
CREATE TRIGGER dbo.trace_appointments_change ON dbo.[appointments]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 -- D-14.B: materialize original Unicode directly into UTF8-typed local columns.
 -- Do not inline CONVERT(varchar) here: real-column evaluation lost code points.
 -- No persistent object/output/log; side + COMPLETE PK keeps I/D values separate.
 DECLARE @hash_utf8 TABLE (
  [_side] char(1) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k0] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [note_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  PRIMARY KEY ([_side],[_k0])
 );
 INSERT @hash_utf8([_side],[_k0],[note_utf8])
 SELECT 'I',r.[id],
   CONVERT(nvarchar(max),r.[note])
 FROM inserted r
 UNION ALL
 SELECT 'D',r.[id],
   CONVERT(nvarchar(max),r.[note])
 FROM deleted r;
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[patient_id] AS [patient_id],
       r.[branch_id] AS [branch_id],
       r.[professional_id] AS [professional_id],
       r.[specialty_code] AS [specialty_code],
       r.[starts_at] AS [starts_at],
       r.[ends_at] AS [ends_at],
       r.[status] AS [status],
       r.[revision] AS [revision],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[note_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[id])),2)) AS [note_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[patient_id] AS [patient_id],
       r.[branch_id] AS [branch_id],
       r.[professional_id] AS [professional_id],
       r.[specialty_code] AS [specialty_code],
       r.[starts_at] AS [starts_at],
       r.[ends_at] AS [ends_at],
       r.[status] AS [status],
       r.[revision] AS [revision],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[note_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[id])),2)) AS [note_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'appointments_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'appointments'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: encounters | PK(id) | I/U/D | target_id=id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,tenant_id,patient_id,branch_id,professional_id,specialty_code,status,revision,finalized_at.
-- SHA256 UTF8: note_sha256<-note.
CREATE TRIGGER dbo.trace_encounters_change ON dbo.[encounters]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 -- D-14.B: materialize original Unicode directly into UTF8-typed local columns.
 -- Do not inline CONVERT(varchar) here: real-column evaluation lost code points.
 -- No persistent object/output/log; side + COMPLETE PK keeps I/D values separate.
 DECLARE @hash_utf8 TABLE (
  [_side] char(1) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k0] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [note_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  PRIMARY KEY ([_side],[_k0])
 );
 INSERT @hash_utf8([_side],[_k0],[note_utf8])
 SELECT 'I',r.[id],
   CONVERT(nvarchar(max),r.[note])
 FROM inserted r
 UNION ALL
 SELECT 'D',r.[id],
   CONVERT(nvarchar(max),r.[note])
 FROM deleted r;
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[patient_id] AS [patient_id],
       r.[branch_id] AS [branch_id],
       r.[professional_id] AS [professional_id],
       r.[specialty_code] AS [specialty_code],
       r.[status] AS [status],
       r.[revision] AS [revision],
       r.[finalized_at] AS [finalized_at],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[note_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[id])),2)) AS [note_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[patient_id] AS [patient_id],
       r.[branch_id] AS [branch_id],
       r.[professional_id] AS [professional_id],
       r.[specialty_code] AS [specialty_code],
       r.[status] AS [status],
       r.[revision] AS [revision],
       r.[finalized_at] AS [finalized_at],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[note_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[id])),2)) AS [note_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'encounters_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'encounters'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: clinical_entries | PK(id) | I/U/D | target_id=id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,tenant_id,encounter_id,kind,actor_id.
-- SHA256 UTF8: payload_sha256<-payload,profile_snapshot_sha256<-profile_snapshot.
CREATE TRIGGER dbo.trace_clinical_entries_change ON dbo.[clinical_entries]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 -- D-14.B: materialize original Unicode directly into UTF8-typed local columns.
 -- Do not inline CONVERT(varchar) here: real-column evaluation lost code points.
 -- No persistent object/output/log; side + COMPLETE PK keeps I/D values separate.
 DECLARE @hash_utf8 TABLE (
  [_side] char(1) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k0] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [payload_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  [profile_snapshot_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  PRIMARY KEY ([_side],[_k0])
 );
 INSERT @hash_utf8([_side],[_k0],[payload_utf8],[profile_snapshot_utf8])
 SELECT 'I',r.[id],
   CONVERT(nvarchar(max),r.[payload]),
   CONVERT(nvarchar(max),r.[profile_snapshot])
 FROM inserted r
 UNION ALL
 SELECT 'D',r.[id],
   CONVERT(nvarchar(max),r.[payload]),
   CONVERT(nvarchar(max),r.[profile_snapshot])
 FROM deleted r;
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[encounter_id] AS [encounter_id],
       r.[kind] AS [kind],
       r.[actor_id] AS [actor_id],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[payload_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[id])),2)) AS [payload_sha256],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[profile_snapshot_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[id])),2)) AS [profile_snapshot_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[encounter_id] AS [encounter_id],
       r.[kind] AS [kind],
       r.[actor_id] AS [actor_id],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[payload_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[id])),2)) AS [payload_sha256],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[profile_snapshot_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[id])),2)) AS [profile_snapshot_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'clinical_entries_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'clinical_entries'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: documents | PK(id) | I/U/D | target_id=id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,tenant_id,patient_id,encounter_id,type,status,revision,original_id,signer_id,signed_at,content_hash,published,withdrawn.
-- SHA256 UTF8: content_sha256<-content.
CREATE TRIGGER dbo.trace_documents_change ON dbo.[documents]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 -- D-14.B: materialize original Unicode directly into UTF8-typed local columns.
 -- Do not inline CONVERT(varchar) here: real-column evaluation lost code points.
 -- No persistent object/output/log; side + COMPLETE PK keeps I/D values separate.
 DECLARE @hash_utf8 TABLE (
  [_side] char(1) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k0] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [content_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  PRIMARY KEY ([_side],[_k0])
 );
 INSERT @hash_utf8([_side],[_k0],[content_utf8])
 SELECT 'I',r.[id],
   CONVERT(nvarchar(max),r.[content])
 FROM inserted r
 UNION ALL
 SELECT 'D',r.[id],
   CONVERT(nvarchar(max),r.[content])
 FROM deleted r;
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[patient_id] AS [patient_id],
       r.[encounter_id] AS [encounter_id],
       r.[type] AS [type],
       r.[status] AS [status],
       r.[revision] AS [revision],
       r.[original_id] AS [original_id],
       r.[signer_id] AS [signer_id],
       r.[signed_at] AS [signed_at],
       r.[content_hash] AS [content_hash],
       r.[published] AS [published],
       r.[withdrawn] AS [withdrawn],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[content_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[id])),2)) AS [content_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[patient_id] AS [patient_id],
       r.[encounter_id] AS [encounter_id],
       r.[type] AS [type],
       r.[status] AS [status],
       r.[revision] AS [revision],
       r.[original_id] AS [original_id],
       r.[signer_id] AS [signer_id],
       r.[signed_at] AS [signed_at],
       r.[content_hash] AS [content_hash],
       r.[published] AS [published],
       r.[withdrawn] AS [withdrawn],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[content_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[id])),2)) AS [content_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'documents_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'documents'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: finance_movements | PK(id) | I/U/D | target_id=id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,tenant_id,patient_id,kind,amount_minor,currency,parent_id,actor_id.
-- SHA256 UTF8: none.
CREATE TRIGGER dbo.trace_finance_movements_change ON dbo.[finance_movements]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[patient_id] AS [patient_id],
       r.[kind] AS [kind],
       r.[amount_minor] AS [amount_minor],
       r.[currency] AS [currency],
       r.[parent_id] AS [parent_id],
       r.[actor_id] AS [actor_id]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[patient_id] AS [patient_id],
       r.[kind] AS [kind],
       r.[amount_minor] AS [amount_minor],
       r.[currency] AS [currency],
       r.[parent_id] AS [parent_id],
       r.[actor_id] AS [actor_id]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'finance_movements_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'finance_movements'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: saas_invoices | PK(id) | I/U/D | target_id=id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,tenant_id,amount_minor,currency,cycle,status,paid_at.
-- SHA256 UTF8: none.
CREATE TRIGGER dbo.trace_saas_invoices_change ON dbo.[saas_invoices]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[amount_minor] AS [amount_minor],
       r.[currency] AS [currency],
       r.[cycle] AS [cycle],
       r.[status] AS [status],
       r.[paid_at] AS [paid_at]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[amount_minor] AS [amount_minor],
       r.[currency] AS [currency],
       r.[cycle] AS [cycle],
       r.[status] AS [status],
       r.[paid_at] AS [paid_at]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'saas_invoices_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'saas_invoices'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: stock_lots | PK(id) | I/U/D | target_id=id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,tenant_id,branch_id,name,lot,expiry,quantity,unit.
-- SHA256 UTF8: none.
CREATE TRIGGER dbo.trace_stock_lots_change ON dbo.[stock_lots]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[branch_id] AS [branch_id],
       r.[name] AS [name],
       r.[lot] AS [lot],
       r.[expiry] AS [expiry],
       r.[quantity] AS [quantity],
       r.[unit] AS [unit]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[branch_id] AS [branch_id],
       r.[name] AS [name],
       r.[lot] AS [lot],
       r.[expiry] AS [expiry],
       r.[quantity] AS [quantity],
       r.[unit] AS [unit]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'stock_lots_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'stock_lots'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: stock_movements | PK(id) | I/U/D | target_id=id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,tenant_id,lot_id,kind,quantity,patient_id,prescription_id,actor_id.
-- SHA256 UTF8: none.
CREATE TRIGGER dbo.trace_stock_movements_change ON dbo.[stock_movements]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[lot_id] AS [lot_id],
       r.[kind] AS [kind],
       r.[quantity] AS [quantity],
       r.[patient_id] AS [patient_id],
       r.[prescription_id] AS [prescription_id],
       r.[actor_id] AS [actor_id]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[lot_id] AS [lot_id],
       r.[kind] AS [kind],
       r.[quantity] AS [quantity],
       r.[patient_id] AS [patient_id],
       r.[prescription_id] AS [prescription_id],
       r.[actor_id] AS [actor_id]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'stock_movements_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'stock_movements'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: stock_transfers | PK(id) | I/U/D | target_id=id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,tenant_id,lot_id,destination_branch_id,quantity,status,received_at.
-- SHA256 UTF8: none.
CREATE TRIGGER dbo.trace_stock_transfers_change ON dbo.[stock_transfers]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[lot_id] AS [lot_id],
       r.[destination_branch_id] AS [destination_branch_id],
       r.[quantity] AS [quantity],
       r.[status] AS [status],
       r.[received_at] AS [received_at]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[lot_id] AS [lot_id],
       r.[destination_branch_id] AS [destination_branch_id],
       r.[quantity] AS [quantity],
       r.[status] AS [status],
       r.[received_at] AS [received_at]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'stock_transfers_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'stock_transfers'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: hospital_resources | PK(id) | I/U/D | target_id=id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,tenant_id,branch_id,name,kind,active.
-- SHA256 UTF8: none.
CREATE TRIGGER dbo.trace_hospital_resources_change ON dbo.[hospital_resources]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[branch_id] AS [branch_id],
       r.[name] AS [name],
       r.[kind] AS [kind],
       r.[active] AS [active]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[branch_id] AS [branch_id],
       r.[name] AS [name],
       r.[kind] AS [kind],
       r.[active] AS [active]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'hospital_resources_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'hospital_resources'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: admissions | PK(id) | I/U/D | target_id=id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,tenant_id,patient_id,resource_id,status,revision,admitted_at,discharged_at.
-- SHA256 UTF8: none.
CREATE TRIGGER dbo.trace_admissions_change ON dbo.[admissions]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[patient_id] AS [patient_id],
       r.[resource_id] AS [resource_id],
       r.[status] AS [status],
       r.[revision] AS [revision],
       r.[admitted_at] AS [admitted_at],
       r.[discharged_at] AS [discharged_at]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[patient_id] AS [patient_id],
       r.[resource_id] AS [resource_id],
       r.[status] AS [status],
       r.[revision] AS [revision],
       r.[admitted_at] AS [admitted_at],
       r.[discharged_at] AS [discharged_at]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'admissions_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'admissions'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: workflow_cases | PK(id) | I/U/D | target_id=id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,tenant_id,branch_id,patient_id,type,status,revision,actor_id.
-- SHA256 UTF8: payload_sha256<-payload.
CREATE TRIGGER dbo.trace_workflow_cases_change ON dbo.[workflow_cases]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 -- D-14.B: materialize original Unicode directly into UTF8-typed local columns.
 -- Do not inline CONVERT(varchar) here: real-column evaluation lost code points.
 -- No persistent object/output/log; side + COMPLETE PK keeps I/D values separate.
 DECLARE @hash_utf8 TABLE (
  [_side] char(1) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k0] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [payload_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  PRIMARY KEY ([_side],[_k0])
 );
 INSERT @hash_utf8([_side],[_k0],[payload_utf8])
 SELECT 'I',r.[id],
   CONVERT(nvarchar(max),r.[payload])
 FROM inserted r
 UNION ALL
 SELECT 'D',r.[id],
   CONVERT(nvarchar(max),r.[payload])
 FROM deleted r;
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[branch_id] AS [branch_id],
       r.[patient_id] AS [patient_id],
       r.[type] AS [type],
       r.[status] AS [status],
       r.[revision] AS [revision],
       r.[actor_id] AS [actor_id],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[payload_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[id])),2)) AS [payload_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[branch_id] AS [branch_id],
       r.[patient_id] AS [patient_id],
       r.[type] AS [type],
       r.[status] AS [status],
       r.[revision] AS [revision],
       r.[actor_id] AS [actor_id],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[payload_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[id])),2)) AS [payload_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'workflow_cases_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'workflow_cases'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: workflow_history | PK(id) | I/U/D | target_id=id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,tenant_id,case_id,revision,status,actor_id.
-- SHA256 UTF8: payload_sha256<-payload.
CREATE TRIGGER dbo.trace_workflow_history_change ON dbo.[workflow_history]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 -- D-14.B: materialize original Unicode directly into UTF8-typed local columns.
 -- Do not inline CONVERT(varchar) here: real-column evaluation lost code points.
 -- No persistent object/output/log; side + COMPLETE PK keeps I/D values separate.
 DECLARE @hash_utf8 TABLE (
  [_side] char(1) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k0] BIGINT NOT NULL,
  [payload_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  PRIMARY KEY ([_side],[_k0])
 );
 INSERT @hash_utf8([_side],[_k0],[payload_utf8])
 SELECT 'I',r.[id],
   CONVERT(nvarchar(max),r.[payload])
 FROM inserted r
 UNION ALL
 SELECT 'D',r.[id],
   CONVERT(nvarchar(max),r.[payload])
 FROM deleted r;
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[case_id] AS [case_id],
       r.[revision] AS [revision],
       r.[status] AS [status],
       r.[actor_id] AS [actor_id],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[payload_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[id])),2)) AS [payload_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[case_id] AS [case_id],
       r.[revision] AS [revision],
       r.[status] AS [status],
       r.[actor_id] AS [actor_id],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[payload_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[id])),2)) AS [payload_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'workflow_history_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'workflow_history'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: support_tickets | PK(id) | I/U/D | target_id=id
-- Tenant: tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,tenant_id,actor_id,reference,status,priority,revision.
-- SHA256 UTF8: message_sha256<-message.
CREATE TRIGGER dbo.trace_support_tickets_change ON dbo.[support_tickets]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 -- D-14.B: materialize original Unicode directly into UTF8-typed local columns.
 -- Do not inline CONVERT(varchar) here: real-column evaluation lost code points.
 -- No persistent object/output/log; side + COMPLETE PK keeps I/D values separate.
 DECLARE @hash_utf8 TABLE (
  [_side] char(1) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k0] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [message_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  PRIMARY KEY ([_side],[_k0])
 );
 INSERT @hash_utf8([_side],[_k0],[message_utf8])
 SELECT 'I',r.[id],
   CONVERT(nvarchar(max),r.[message])
 FROM inserted r
 UNION ALL
 SELECT 'D',r.[id],
   CONVERT(nvarchar(max),r.[message])
 FROM deleted r;
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[actor_id] AS [actor_id],
       r.[reference] AS [reference],
       r.[status] AS [status],
       r.[priority] AS [priority],
       r.[revision] AS [revision],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[message_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[id])),2)) AS [message_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   r.[tenant_id] AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[tenant_id] AS [tenant_id],
       r.[actor_id] AS [actor_id],
       r.[reference] AS [reference],
       r.[status] AS [status],
       r.[priority] AS [priority],
       r.[revision] AS [revision],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[message_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[id])),2)) AS [message_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'support_tickets_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'support_tickets'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: support_comments | PK(id) | I/U/D | target_id=id
-- Tenant: ticket.tenant_id; join complete PK + evidence tenant.
-- Safe scalars: id,ticket_id,actor_id.
-- SHA256 UTF8: message_sha256<-message.
CREATE TRIGGER dbo.trace_support_comments_change ON dbo.[support_comments]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 -- HOLDLOCK retains each validated parent through this transaction; no missing
 -- parent can disappear between integrity validation and the attribution join.
 IF EXISTS(SELECT 1 FROM inserted c LEFT JOIN dbo.support_tickets t WITH(HOLDLOCK) ON t.id=c.ticket_id WHERE t.id IS NULL)
  OR EXISTS(SELECT 1 FROM deleted c LEFT JOIN dbo.support_tickets t WITH(HOLDLOCK) ON t.id=c.ticket_id WHERE t.id IS NULL)
  THROW 51000,N'HP_INVALID:Ticket de auditoria inexistente',1;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 -- D-14.B: materialize original Unicode directly into UTF8-typed local columns.
 -- Do not inline CONVERT(varchar) here: real-column evaluation lost code points.
 -- No persistent object/output/log; side + COMPLETE PK keeps I/D values separate.
 DECLARE @hash_utf8 TABLE (
  [_side] char(1) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [_k0] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
  [message_utf8] varchar(max) COLLATE Latin1_General_100_BIN2_UTF8 NULL,
  PRIMARY KEY ([_side],[_k0])
 );
 INSERT @hash_utf8([_side],[_k0],[message_utf8])
 SELECT 'I',r.[id],
   CONVERT(nvarchar(max),r.[message])
 FROM inserted r
 UNION ALL
 SELECT 'D',r.[id],
   CONVERT(nvarchar(max),r.[message])
 FROM deleted r;
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   t.tenant_id AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[ticket_id] AS [ticket_id],
       r.[actor_id] AS [actor_id],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[message_utf8] FROM @hash_utf8 u WHERE u.[_side]='I' AND u.[_k0]=r.[id])),2)) AS [message_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r JOIN dbo.support_tickets t ON t.id=r.ticket_id
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   t.tenant_id AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[ticket_id] AS [ticket_id],
       r.[actor_id] AS [actor_id],
       LOWER(CONVERT(char(64),HASHBYTES('SHA2_256',(SELECT u.[message_utf8] FROM @hash_utf8 u WHERE u.[_side]='D' AND u.[_k0]=r.[id])),2)) AS [message_sha256]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r JOIN dbo.support_tickets t ON t.id=r.ticket_id
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'support_comments_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'support_comments'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- Matrix: application_state | PK(id) | I/U/D | target_id=id
-- Tenant: NULL (historical global); join complete PK + evidence tenant.
-- Safe scalars: id,mode,message,revision.
-- SHA256 UTF8: none.
CREATE TRIGGER dbo.trace_application_state_change ON dbo.[application_state]
AFTER INSERT,UPDATE,DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @actor char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
  @request char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),
  @method nvarchar(10)=CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
  @route nvarchar(250)=CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),
  @ip nvarchar(80)=CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
  @agent nvarchar(300)=CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),
  @roles nvarchar(4000)=CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles'));
 ;WITH
 new_rows AS (
  SELECT r.[id] AS [_k0],
   CONVERT(char(36),NULL) AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[mode] AS [mode],
       r.[message] AS [message],
       r.[revision] AS [revision]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM inserted r
 ),
 old_rows AS (
  SELECT r.[id] AS [_k0],
   CONVERT(char(36),NULL) AS [evidence_tenant],CONVERT(nvarchar(100),r.[id]) AS [target],
   (SELECT r.[id] AS [id],
       r.[mode] AS [mode],
       r.[message] AS [message],
       r.[revision] AS [revision]
      FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER) AS [safe_state]
  FROM deleted r
 ),
 changes AS (
  SELECT CASE WHEN n.[_k0] IS NULL THEN 'DELETE' WHEN o.[_k0] IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS [operation],
   CASE WHEN n.[_k0] IS NULL THEN o.evidence_tenant ELSE n.evidence_tenant END AS [tenant_id],
   CASE WHEN n.[_k0] IS NULL THEN o.[target] ELSE n.[target] END AS [target_id],
   o.safe_state AS [before_safe],n.safe_state AS [after_safe]
  FROM new_rows n FULL OUTER JOIN old_rows o ON n.[_k0]=o.[_k0]
   AND (n.evidence_tenant=o.evidence_tenant OR n.evidence_tenant IS NULL AND o.evidence_tenant IS NULL)
 )
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type)
 SELECT c.tenant_id,@actor,N'application_state_'+c.operation,c.target_id,
  (SELECT c.operation AS [operation] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER),
  @request,@method,@route,@ip,@agent,@roles,c.before_safe,c.after_safe,N'application_state'
 FROM changes c
 WHERE c.operation<>'UPDATE'
  OR c.before_safe COLLATE Latin1_General_100_BIN2<>c.after_safe COLLATE Latin1_General_100_BIN2
  OR DATALENGTH(c.before_safe)<>DATALENGTH(c.after_safe);
END;
GO

-- V9 audit_no_update / audit_no_delete: statement-wide and unconditional, including
-- attempted zero-row writes. No identity/scope/metadata switch can bypass them.
CREATE TRIGGER dbo.audit_no_update ON dbo.audit_events
AFTER UPDATE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 THROW 51001,N'HP_FORBIDDEN:La auditoría es inmutable',1;
END;
GO
CREATE TRIGGER dbo.audit_no_delete ON dbo.audit_events
AFTER DELETE
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 THROW 51001,N'HP_FORBIDDEN:La auditoría es inmutable',1;
END;
GO
