-- SQL Server 2022, compatibility 160. No grants and no autonomous commits.
-- Every procedure below participates in the caller's Spring transaction.
-- Private helpers (require_*, audit_*, write_guard) must never receive runtime grants.
-- Context parameters come from Spring filters, never HTTP request bodies.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
-- Sql connection boundary: replace every hp_* key, including anonymous/background calls.
-- No result set. hp_scope is a trusted adapter capability, not a client-selectable role.
CREATE PROCEDURE dbo.usp_request_context
 @request_id char(36)=NULL, @method nvarchar(10)=NULL, @route nvarchar(250)=NULL,
 @source_ip nvarchar(80)=NULL, @user_agent nvarchar(300)=NULL,
 @actor_id char(36)=NULL, @actor_roles nvarchar(max)=NULL, @tenant_id char(36)=NULL,
 @token_hash char(64)=NULL, @scope varchar(20)='REQUEST'
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 -- Clear first: even invalid replacement arguments cannot retain a previous principal.
 EXEC sys.sp_set_session_context @key=N'hp_request_id',@value=NULL;
 EXEC sys.sp_set_session_context @key=N'hp_method',@value=NULL;
 EXEC sys.sp_set_session_context @key=N'hp_route',@value=NULL;
 EXEC sys.sp_set_session_context @key=N'hp_source_ip',@value=NULL;
 EXEC sys.sp_set_session_context @key=N'hp_user_agent',@value=NULL;
 EXEC sys.sp_set_session_context @key=N'hp_actor_id',@value=NULL;
 EXEC sys.sp_set_session_context @key=N'hp_actor_roles',@value=NULL;
 EXEC sys.sp_set_session_context @key=N'hp_tenant_id',@value=NULL;
 EXEC sys.sp_set_session_context @key=N'hp_token_hash',@value=NULL;
 EXEC sys.sp_set_session_context @key=N'hp_scope',@value=NULL;
 IF @scope NOT IN ('REQUEST','IDENTITY','BOOTSTRAP','WORKER') OR @scope IS NULL
   THROW 51000,'HP_INVALID:Context scope',1;
 IF @actor_roles IS NOT NULL AND (ISJSON(@actor_roles,ARRAY)<>1 OR DATALENGTH(@actor_roles)>8000)
   THROW 51000,'HP_INVALID:Context roles',1;
 DECLARE @roles nvarchar(4000)=CONVERT(nvarchar(4000),@actor_roles);
 EXEC sys.sp_set_session_context @key=N'hp_request_id',@value=@request_id;
 EXEC sys.sp_set_session_context @key=N'hp_method',@value=@method;
 EXEC sys.sp_set_session_context @key=N'hp_route',@value=@route;
 EXEC sys.sp_set_session_context @key=N'hp_source_ip',@value=@source_ip;
 EXEC sys.sp_set_session_context @key=N'hp_user_agent',@value=@user_agent;
 EXEC sys.sp_set_session_context @key=N'hp_actor_id',@value=@actor_id;
 EXEC sys.sp_set_session_context @key=N'hp_actor_roles',@value=@roles;
 EXEC sys.sp_set_session_context @key=N'hp_tenant_id',@value=@tenant_id;
 EXEC sys.sp_set_session_context @key=N'hp_token_hash',@value=@token_hash;
 EXEC sys.sp_set_session_context @key=N'hp_scope',@value=@scope;
END;
GO
CREATE PROCEDURE dbo.usp_require_transaction
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @@TRANCOUNT=0 THROW 51000,'HP_INVALID:External transaction required',1;
END;
GO
-- Resolves actual current membership/platform role instead of trusting hp_actor_roles.
-- @roles is an internal comma-delimited constant supplied by another approved SP.
CREATE PROCEDURE dbo.usp_require_actor @roles nvarchar(200)=NULL, @platform_only bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF ISNULL(CONVERT(varchar(20),SESSION_CONTEXT(N'hp_scope')),'') NOT IN ('REQUEST','IDENTITY') THROW 51001,'HP_FORBIDDEN:Complete HTTP context required',1;
 DECLARE @u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),
 @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),
 @h char(64)=CONVERT(char(64),SESSION_CONTEXT(N'hp_token_hash'));
 IF @u IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.users WHERE id=@u AND active=1 AND email_verified=1)
   THROW 51001,'HP_FORBIDDEN:Authentication required',1;
 IF @h IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.auth_sessions WHERE token_hash=@h AND user_id=@u
   AND (tenant_id=@t OR tenant_id IS NULL AND @t IS NULL) AND revoked=0 AND expires_at>SYSUTCDATETIME())
   THROW 51001,'HP_FORBIDDEN:Session no longer active',1;
 IF @t IS NULL
 BEGIN
   IF NOT EXISTS(SELECT 1 FROM dbo.users u WHERE u.id=@u AND u.platform_role IN ('SAD','SOP')
     AND (@roles IS NULL OR EXISTS(SELECT 1 FROM STRING_SPLIT(@roles,',') r WHERE r.value COLLATE Latin1_General_100_BIN2=u.platform_role COLLATE Latin1_General_100_BIN2)))
     THROW 51001,'HP_FORBIDDEN:Platform permission required',1;
 END
 ELSE
 BEGIN
   IF @platform_only=1 THROW 51001,'HP_FORBIDDEN:Platform host required',1;
   IF NOT EXISTS(SELECT 1 FROM dbo.memberships m JOIN dbo.users u ON u.id=m.user_id
     WHERE m.tenant_id=@t AND m.user_id=@u AND m.status='ACTIVE' AND u.platform_role IS NULL
     AND (@roles IS NULL OR EXISTS(SELECT 1 FROM OPENJSON(m.roles) j JOIN STRING_SPLIT(@roles,',') r ON r.value COLLATE Latin1_General_100_BIN2=j.value COLLATE Latin1_General_100_BIN2)))
     THROW 51001,'HP_FORBIDDEN:Tenant permission required',1;
 END;
END;
GO
CREATE PROCEDURE dbo.usp_require_scope @scope varchar(20)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF SESSION_CONTEXT(N'hp_scope') IS NULL OR CONVERT(varchar(20),SESSION_CONTEXT(N'hp_scope'))<>@scope
   THROW 51001,'HP_FORBIDDEN:Internal scope required',1;
END;
GO
-- Access.write and shared sp_write_guard; no platform identity may access clinical tenant data.
CREATE PROCEDURE dbo.usp_write_guard @tenant_id char(36), @feature nvarchar(40)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_transaction;
 IF @tenant_id IS NULL OR ISNULL(CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),'')<>@tenant_id THROW 51001,'HP_FORBIDDEN:Tenant write scope mismatch',1;
 IF ISNULL(CONVERT(varchar(20),SESSION_CONTEXT(N'hp_scope')),'')<>'IDENTITY' EXEC dbo.usp_require_actor;
 DECLARE @state nvarchar(11),@status nvarchar(10),@modules nvarchar(max);
 SELECT @state=mode FROM dbo.application_state WITH(HOLDLOCK) WHERE id=1;
 IF @state IS NULL OR @state<>'OPEN' THROW 51005,'HP_APPLICATION_READ_ONLY:Business writes unavailable',1;
 SELECT @status=t.status,@modules=v.modules FROM dbo.tenants t WITH(UPDLOCK,HOLDLOCK)
 JOIN dbo.subscriptions s ON s.tenant_id=t.id JOIN dbo.plan_versions v ON v.plan_id=s.plan_id AND v.version=s.plan_version WHERE t.id=@tenant_id;
 IF @status IS NULL THROW 51002,'HP_NOT_FOUND:Tenant',1;
 IF @status NOT IN ('ACTIVE','TRIAL') THROW 51004,'HP_SUSPENDED:Tenant writes suspended',1;
 IF @feature IS NOT NULL AND NOT EXISTS(SELECT 1 FROM OPENJSON(@modules) WHERE value=@feature)
   THROW 51001,'HP_FORBIDDEN:Module not included',1;
END;
GO
-- Private metadata-only audit. Never accepts raw credentials, tokens or clinical bodies.
CREATE PROCEDURE dbo.usp_audit_event @tenant_id char(36),@action nvarchar(80),@target_id nvarchar(100),@metadata nvarchar(max)=N'{}',@actor_override char(36)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_transaction;
 IF @metadata IS NULL OR ISJSON(@metadata,OBJECT)<>1 THROW 51000,'HP_INVALID:Audit metadata',1;
 IF EXISTS(SELECT 1 FROM OPENJSON(@metadata) WHERE type IN (4,5) OR [key] COLLATE Latin1_General_100_CI_AI IN
 ('password','password_hash','token','token_hash','csrf','csrf_token','body','content','payload'))
   THROW 51000,'HP_INVALID:Sensitive audit metadata',1;
 INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles)
 VALUES(@tenant_id,COALESCE(@actor_override,CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id'))),@action,@target_id,@metadata,
 CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),
 CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),
 CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles')));
END;
GO

-- HostFilter.doFilter: host resolution, public. RS id/name/slug/kind/domain/status/modules JSON.
CREATE PROCEDURE dbo.usp_tenant_by_slug @slug varchar(63)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT t.id,t.name,t.slug,t.kind,t.domain,t.status,v.modules FROM dbo.tenants t JOIN dbo.subscriptions s ON s.tenant_id=t.id JOIN dbo.plan_versions v ON v.plan_id=s.plan_id AND v.version=s.plan_version WHERE t.slug=@slug;
END;
GO

-- AccountLifecycleService.options: public published offers, JSON remains text.
CREATE PROCEDURE dbo.usp_registration_plans
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT p.id,p.name,v.kinds,v.domains,v.included_branches,v.included_professionals,v.included_specialties,v.base_minor FROM dbo.plans p JOIN dbo.plan_versions v ON v.plan_id=p.id AND v.version=p.current_version WHERE p.status='PUBLISHED' ORDER BY v.base_minor,p.id;
END;
GO

-- AccountLifecycleService.options: public specialty catalog; RS code/name/domain/dental BIT.
CREATE PROCEDURE dbo.usp_registration_specialties
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT code,name,domain,dental FROM dbo.specialties ORDER BY name,code;
END;
GO

-- AccountLifecycleService.register: published plan defaults; tenant creation belongs to SaaS package.
CREATE PROCEDURE dbo.usp_registration_plan @plan_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'IDENTITY'; SELECT p.id,v.included_branches,v.included_professionals,v.included_specialties FROM dbo.plans p JOIN dbo.plan_versions v ON v.plan_id=p.id AND v.version=p.current_version WHERE p.id=@plan_id AND p.status='PUBLISHED';
END;
GO

-- INTERNAL credential result only: IdentityService.login/accept; never serialize password_hash to HTTP.
CREATE PROCEDURE dbo.usp_identity_credentials @email nvarchar(254)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'IDENTITY'; SELECT id,name,email,password_hash,platform_role,email_verified,locked_until,CAST(CASE WHEN locked_until>SYSUTCDATETIME() THEN 1 ELSE 0 END AS bit) locked FROM dbo.users WHERE email=LOWER(LTRIM(RTRIM(@email))) AND active=1;
END;
GO

-- AccountLifecycleService.request: internal eligibility lookup; no credential hash.
CREATE PROCEDURE dbo.usp_identity_account_lookup @email nvarchar(254)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'IDENTITY'; SELECT id,email,email_verified,platform_role FROM dbo.users WHERE email=LOWER(LTRIM(RTRIM(@email))) AND active=1;
END;
GO

-- AccountLifecycleService.register: optional id, including inactive identities; avoid duplicate enrollment.
CREATE PROCEDURE dbo.usp_identity_email_exists @email nvarchar(254)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'IDENTITY'; SELECT id FROM dbo.users WHERE email=LOWER(LTRIM(RTRIM(@email)));
END;
GO

-- IdentityService.login, SessionFilter, AccountLifecycleService.request: host-scoped membership roles JSON.
CREATE PROCEDURE dbo.usp_identity_membership @user_id char(36),@tenant_id char(36),@active_only bit=1
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'IDENTITY'; IF @tenant_id IS NULL OR ISNULL(CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),'')<>@tenant_id THROW 51001,'HP_FORBIDDEN:Host mismatch',1; SELECT user_id,roles,status FROM dbo.memberships WHERE tenant_id=@tenant_id AND user_id=@user_id AND ((@active_only=1 AND status='ACTIVE') OR (@active_only=0 AND status<>'INACTIVE'));
END;
GO

-- IdentityService.create / V2 sp_user_create; public registration invokes identity_pending in the same transaction; administrative provisioning keeps historical verified default.
CREATE PROCEDURE dbo.usp_user_create @id char(36),@name nvarchar(160),@email nvarchar(254),@password_hash nvarchar(100),@domain nvarchar(6)=NULL,@credential nvarchar(100)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_transaction; IF ISNULL(CONVERT(varchar(20),SESSION_CONTEXT(N'hp_scope')),'')<>'IDENTITY' BEGIN EXEC dbo.usp_require_actor @roles=N'SAD,ADM'; END; IF NULLIF(LTRIM(RTRIM(@name)),N'') IS NULL OR NULLIF(@email,N'') IS NULL OR NULLIF(@password_hash,N'') IS NULL OR (@domain IS NOT NULL AND @domain NOT IN ('HUMAN','ANIMAL')) THROW 51000,'HP_INVALID:Identity fields',1; IF EXISTS(SELECT 1 FROM dbo.users WITH(UPDLOCK,HOLDLOCK) WHERE email=LOWER(LTRIM(RTRIM(@email)))) THROW 51003,'HP_CONFLICT:Identity already exists',1; INSERT dbo.users(id,name,email,password_hash,clinical_domain,credential,email_verified) VALUES(@id,LTRIM(RTRIM(@name)),LOWER(LTRIM(RTRIM(@email))),@password_hash,@domain,@credential,1);
END;
GO

-- Bootstrap.run: SETUP-ONLY, no runtime EXECUTE grant.
CREATE PROCEDURE dbo.usp_bootstrap_exists
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'BOOTSTRAP'; IF ISNULL(IS_ROLEMEMBER(N'db_owner'),0)<>1 AND ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 THROW 51001,'HP_FORBIDDEN:Separate elevated setup principal required',1; SELECT TOP(1) id FROM dbo.users WHERE platform_role='SAD' ORDER BY id;
END;
GO

-- Bootstrap.run / V2 sp_bootstrap: SETUP-ONLY separate principal, never runtime grant.
CREATE PROCEDURE dbo.usp_bootstrap_create @id char(36),@email nvarchar(254),@password_hash nvarchar(100)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_transaction; EXEC dbo.usp_require_scope 'BOOTSTRAP'; IF ISNULL(IS_ROLEMEMBER(N'db_owner'),0)<>1 AND ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 THROW 51001,'HP_FORBIDDEN:Separate elevated setup principal required',1; IF EXISTS(SELECT 1 FROM dbo.users WITH(UPDLOCK,HOLDLOCK) WHERE platform_role='SAD') RETURN; IF NULLIF(@email,N'') IS NULL OR NULLIF(@password_hash,N'') IS NULL THROW 51000,'HP_INVALID:Bootstrap fields',1; INSERT dbo.users(id,name,email,password_hash,platform_role,email_verified) VALUES(@id,N'Administrador general',LOWER(@email),@password_hash,'SAD',1);
END;
GO

-- AccountLifecycleService.register / V9 sp_identity_pending.
CREATE PROCEDURE dbo.usp_identity_pending @user_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'IDENTITY'; EXEC dbo.usp_require_transaction; UPDATE dbo.users SET email_verified=0 WHERE id=@user_id AND platform_role IS NULL; IF @@ROWCOUNT<>1 THROW 51002,'HP_NOT_FOUND:Pending identity',1;
END;
GO

-- IdentityService.password: INTERNAL own credential verification only.
CREATE PROCEDURE dbo.usp_identity_password_hash
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor; SELECT password_hash FROM dbo.users WHERE id=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id'));
END;
GO

-- IdentityService.password / V2 sp_password_change: revoke every session atomically, never audit hash.
CREATE PROCEDURE dbo.usp_password_change @password_hash nvarchar(100)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor; EXEC dbo.usp_require_transaction; DECLARE @u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),@t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF NULLIF(@password_hash,N'') IS NULL THROW 51000,'HP_INVALID:Password hash',1; UPDATE dbo.users WITH(UPDLOCK) SET password_hash=@password_hash WHERE id=@u; UPDATE dbo.auth_sessions SET revoked=1 WHERE user_id=@u; EXEC dbo.usp_audit_event @t,N'PASSWORD_CHANGED',@u;
END;
GO

-- SessionFilter: internal token-bound host/session lookup. CSRF is internal until browser session endpoint.
CREATE PROCEDURE dbo.usp_session_resolve @token_hash char(64)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'IDENTITY'; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); SELECT s.user_id,s.tenant_id,s.csrf_token,u.name,u.email,u.platform_role FROM dbo.auth_sessions s JOIN dbo.users u ON u.id=s.user_id WHERE s.token_hash=@token_hash AND s.revoked=0 AND s.expires_at>SYSUTCDATETIME() AND u.active=1 AND u.email_verified=1 AND ((s.tenant_id=@t AND u.platform_role IS NULL AND EXISTS(SELECT 1 FROM dbo.memberships m WHERE m.tenant_id=@t AND m.user_id=u.id AND m.status='ACTIVE')) OR (@t IS NULL AND s.tenant_id IS NULL AND u.platform_role IN ('SAD','SOP')));
END;
GO

-- IdentityService.login + BrowserSessionController.login; password verified by Spring before trusted IDENTITY call. RS csrf_token/expires_at replaces post-login SELECT.
CREATE PROCEDURE dbo.usp_session_save @token_hash char(64),@user_id char(36),@expires_at datetime2(6)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'IDENTITY'; EXEC dbo.usp_require_transaction; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF @expires_at<=SYSUTCDATETIME() THROW 51000,'HP_INVALID:Session expiry',1; IF NOT EXISTS(SELECT 1 FROM dbo.users WITH(UPDLOCK,HOLDLOCK) WHERE id=@user_id AND active=1 AND email_verified=1 AND (locked_until IS NULL OR locked_until<=SYSUTCDATETIME()) AND ((@t IS NULL AND platform_role IN ('SAD','SOP')) OR (@t IS NOT NULL AND platform_role IS NULL AND EXISTS(SELECT 1 FROM dbo.memberships WHERE tenant_id=@t AND user_id=@user_id AND status='ACTIVE')))) THROW 51001,'HP_FORBIDDEN:Login eligibility changed',1; INSERT dbo.auth_sessions(token_hash,user_id,tenant_id,expires_at,csrf_token,user_agent,source_ip) VALUES(@token_hash,@user_id,@t,@expires_at,CONVERT(char(64),CRYPT_GEN_RANDOM(32),2),COALESCE(CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),N''),COALESCE(CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),N'')); UPDATE dbo.users SET login_failures=0,locked_until=NULL WHERE id=@user_id; EXEC dbo.usp_audit_event @t,N'LOGIN_SUCCEEDED',@user_id,@actor_override=@user_id; SELECT csrf_token,expires_at FROM dbo.auth_sessions WHERE token_hash=@token_hash;
END;
GO

-- BrowserSessionController.current: own CSRF/expiry only.
CREATE PROCEDURE dbo.usp_session_current
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor; SELECT csrf_token,expires_at FROM dbo.auth_sessions WHERE token_hash=CONVERT(char(64),SESSION_CONTEXT(N'hp_token_hash'));
END;
GO

-- BrowserSessionController.sessions: SHA256 of stored ASCII token hash, never returns token_hash.
CREATE PROCEDURE dbo.usp_sessions_list
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor; DECLARE @h char(64)=CONVERT(char(64),SESSION_CONTEXT(N'hp_token_hash')); SELECT TOP(100) LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(64),token_hash)),2)) id,tenant_id,created_at,last_seen_at,expires_at,revoked,user_agent,source_ip,CAST(CASE WHEN token_hash=@h THEN 1 ELSE 0 END AS bit) [current] FROM dbo.auth_sessions WHERE user_id=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')) ORDER BY created_at DESC,token_hash;
END;
GO

-- IdentityService.logout + BrowserSessionController.revoke; own opaque session id, no hash lookup escape.
CREATE PROCEDURE dbo.usp_session_revoke @session_id char(64)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor; EXEC dbo.usp_require_transaction; DECLARE @u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),@t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@h char(64)=CONVERT(char(64),SESSION_CONTEXT(N'hp_token_hash')); UPDATE dbo.auth_sessions SET revoked=1 WHERE user_id=@u AND ((@session_id IS NULL AND token_hash=@h) OR LOWER(CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varchar(64),token_hash)),2))=@session_id); IF @@ROWCOUNT=0 THROW 51002,'HP_NOT_FOUND:Session',1; EXEC dbo.usp_audit_event @t,N'SESSION_REVOKED',@u;
END;
GO

-- SessionFilter / V9 sp_session_touch: throttle own session touch.
CREATE PROCEDURE dbo.usp_session_touch
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor; UPDATE dbo.auth_sessions SET last_seen_at=SYSUTCDATETIME() WHERE token_hash=CONVERT(char(64),SESSION_CONTEXT(N'hp_token_hash')) AND last_seen_at<DATEADD(minute,-1,SYSUTCDATETIME());
END;
GO

-- AttemptRecorder.failed / V11: independent Spring REQUIRES_NEW, anonymous actor and safe attempted account target.
CREATE PROCEDURE dbo.usp_login_failure @user_id char(36)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'IDENTITY'; EXEC dbo.usp_require_transaction; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF @user_id IS NOT NULL UPDATE dbo.users WITH(UPDLOCK,HOLDLOCK) SET login_failures=CASE WHEN locked_until<SYSUTCDATETIME() THEN 1 ELSE login_failures+1 END,locked_until=CASE WHEN (CASE WHEN locked_until<SYSUTCDATETIME() THEN 1 ELSE login_failures+1 END)>=5 THEN DATEADD(minute,15,SYSUTCDATETIME()) ELSE locked_until END WHERE id=@user_id; INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent) VALUES(@t,NULL,N'LOGIN_FAILED',COALESCE(@user_id,'unknown'),N'{"result":"REJECTED"}',CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')));
END;
GO

-- AccountLifecycleService.issue / V9: atomic token invalidation + outbox. Recipient is server account email; optional registration_tenant must be newly enrolled owner membership on platform host. Content MAX, no audit body/token.
CREATE PROCEDURE dbo.usp_identity_issue @token_hash char(64),@user_id char(36),@purpose nvarchar(6),@expires_at datetime2(6),@mail_id char(36),@subject nvarchar(200),@body nvarchar(max),@registration_tenant char(36)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'IDENTITY'; EXEC dbo.usp_require_transaction; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@email nvarchar(254),@verified bit,@platform nvarchar(3); IF @registration_tenant IS NOT NULL BEGIN IF @t IS NOT NULL OR @purpose<>'VERIFY' OR @purpose IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.memberships m JOIN dbo.users u ON u.id=m.user_id WHERE m.tenant_id=@registration_tenant AND m.user_id=@user_id AND m.owner=1 AND m.status='ACTIVE' AND u.email_verified=0 AND u.platform_role IS NULL) THROW 51001,'HP_FORBIDDEN:Registration token scope',1; SET @t=@registration_tenant; END; SELECT @email=email,@verified=email_verified,@platform=platform_role FROM dbo.users WITH(UPDLOCK,HOLDLOCK) WHERE id=@user_id AND active=1; IF @email IS NULL OR @purpose NOT IN ('VERIFY','RESET') OR @purpose IS NULL OR @expires_at<=SYSUTCDATETIME() OR @expires_at IS NULL OR NULLIF(@body,N'') IS NULL OR NULLIF(@subject,N'') IS NULL THROW 51000,'HP_INVALID:Identity link',1; IF @t IS NULL AND @platform IS NULL THROW 51001,'HP_FORBIDDEN:Platform identity required',1; IF @t IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.memberships WHERE tenant_id=@t AND user_id=@user_id AND status<>'INACTIVE') THROW 51001,'HP_FORBIDDEN:Identity host',1; IF @purpose='RESET' AND @verified=0 THROW 51001,'HP_FORBIDDEN:Unverified identity',1; UPDATE dbo.identity_tokens SET used_at=SYSUTCDATETIME() WHERE user_id=@user_id AND purpose=@purpose AND used_at IS NULL; INSERT dbo.identity_tokens(token_hash,user_id,tenant_id,purpose,expires_at,used_at) VALUES(@token_hash,@user_id,@t,@purpose,@expires_at,NULL); INSERT dbo.mail_outbox(id,recipient,subject,body) VALUES(@mail_id,@email,@subject,@body); DECLARE @action nvarchar(80)=@purpose+N'_LINK_REQUESTED'; EXEC dbo.usp_audit_event @t,@action,@user_id,@actor_override=@user_id;
END;
GO

-- AccountLifecycleService.redeem / V9: user then token lock order matches issue; one-use, host-bound; reset revokes all sessions.
CREATE PROCEDURE dbo.usp_identity_redeem @token_hash char(64),@purpose nvarchar(6),@password_hash nvarchar(100)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'IDENTITY'; EXEC dbo.usp_require_transaction; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36),@tt char(36),@expiry datetime2(6),@used datetime2(6); SELECT @u=user_id,@tt=tenant_id FROM dbo.identity_tokens WHERE token_hash=@token_hash AND purpose=@purpose; IF @u IS NULL THROW 51000,'HP_INVALID:Link invalid or expired',1; DECLARE @exists char(36); SELECT @exists=id FROM dbo.users WITH(UPDLOCK,HOLDLOCK) WHERE id=@u AND active=1; SELECT @expiry=expires_at,@used=used_at,@tt=tenant_id FROM dbo.identity_tokens WITH(UPDLOCK,HOLDLOCK) WHERE token_hash=@token_hash AND purpose=@purpose; IF @exists IS NULL OR @used IS NOT NULL OR @expiry<=SYSUTCDATETIME() OR @expiry IS NULL OR (@tt IS NULL AND @t IS NOT NULL) OR (@tt IS NOT NULL AND @t IS NULL) OR @tt<>@t OR @purpose IS NULL OR @purpose NOT IN ('VERIFY','RESET') THROW 51000,'HP_INVALID:Link invalid or expired',1; IF @purpose='VERIFY' UPDATE dbo.users SET email_verified=1 WHERE id=@u; ELSE BEGIN IF NULLIF(@password_hash,N'') IS NULL THROW 51000,'HP_INVALID:Password hash required',1; UPDATE dbo.users SET password_hash=@password_hash,login_failures=0,locked_until=NULL WHERE id=@u; UPDATE dbo.auth_sessions SET revoked=1 WHERE user_id=@u; END; UPDATE dbo.identity_tokens SET used_at=SYSUTCDATETIME() WHERE user_id=@u AND purpose=@purpose AND used_at IS NULL; DECLARE @action nvarchar(80)=@purpose+N'_COMPLETED'; EXEC dbo.usp_audit_event @t,@action,@u,@actor_override=@u;
END;
GO

-- AccountLifecycleService.register / V9: no patient links or clinical access invented.
CREATE PROCEDURE dbo.usp_portal_register @user_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'IDENTITY'; EXEC dbo.usp_require_transaction; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@b char(36),@d nvarchar(6); IF @t IS NULL THROW 51001,'HP_FORBIDDEN:Tenant host',1; EXEC dbo.usp_write_guard @t,N'PORTAL'; SELECT @d=domain FROM dbo.tenants WHERE id=@t; SELECT TOP(1) @b=id FROM dbo.branches WHERE tenant_id=@t AND active=1 ORDER BY id; IF @b IS NULL THROW 51003,'HP_CONFLICT:No active branch',1; IF NOT EXISTS(SELECT 1 FROM dbo.users WITH(UPDLOCK,HOLDLOCK) WHERE id=@user_id AND active=1 AND platform_role IS NULL AND email_verified=0) THROW 51001,'HP_FORBIDDEN:Pending portal identity required',1; INSERT dbo.memberships(tenant_id,user_id,roles,status,owner) VALUES(@t,@user_id,CASE WHEN @d='ANIMAL' THEN N'["RES"]' ELSE N'["PAC"]' END,'ACTIVE',0); INSERT dbo.membership_branches(tenant_id,user_id,branch_id) VALUES(@t,@user_id,@b); EXEC dbo.usp_audit_event @t,N'PORTAL_ACCOUNT_REGISTERED',@user_id,@actor_override=@user_id;
END;
GO

-- IdentityService.accept / V2: Spring must verify supplied password before trusted IDENTITY operation.
CREATE PROCEDURE dbo.usp_invitation_accept @user_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'IDENTITY'; EXEC dbo.usp_require_transaction; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF @t IS NULL THROW 51001,'HP_FORBIDDEN:Tenant host',1; EXEC dbo.usp_write_guard @t,N'CORE'; IF NOT EXISTS(SELECT 1 FROM dbo.users WHERE id=@user_id AND active=1 AND email_verified=1 AND platform_role IS NULL) THROW 51001,'HP_FORBIDDEN:Invitation identity',1; UPDATE dbo.memberships WITH(UPDLOCK,HOLDLOCK) SET status='ACTIVE' WHERE tenant_id=@t AND user_id=@user_id AND status='INVITED'; IF @@ROWCOUNT<>1 THROW 51001,'HP_FORBIDDEN:Invitation unavailable',1; EXEC dbo.usp_audit_event @t,N'INVITATION_ACCEPTED',@user_id,@actor_override=@user_id;
END;
GO

-- Access.branch: replaces both branch and membership SELECTs, returns optional id/branch_id, platform never bypasses.
CREATE PROCEDURE dbo.usp_access_branch @branch_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')); IF @t IS NULL THROW 51001,'HP_FORBIDDEN:Tenant host required',1; SELECT b.id,b.id branch_id FROM dbo.branches b WHERE b.tenant_id=@t AND b.id=@branch_id AND b.active=1 AND EXISTS(SELECT 1 FROM dbo.memberships m WHERE m.tenant_id=@t AND m.user_id=@u AND m.status='ACTIVE' AND (EXISTS(SELECT 1 FROM OPENJSON(m.roles) WHERE value='ADM') OR EXISTS(SELECT 1 FROM dbo.membership_branches mb WHERE mb.tenant_id=@t AND mb.user_id=@u AND mb.branch_id=b.id)));
END;
GO

-- Access.link: scoped optional patient_id only; no histories returned.
CREATE PROCEDURE dbo.usp_access_patient_link @patient_id char(36),@scope nvarchar(80)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')); IF @t IS NULL THROW 51001,'HP_FORBIDDEN:Tenant host required',1; SELECT patient_id FROM dbo.patient_links l WHERE l.tenant_id=@t AND l.user_id=@u AND l.patient_id=@patient_id AND l.active=1 AND EXISTS(SELECT 1 FROM OPENJSON(l.scopes) WHERE value=@scope);
END;
GO

-- MailDelivery.deliver: claim atomically, commit before SMTP. SENDING is NEVER automatically reclaimed; no exactly-once promise.
CREATE PROCEDURE dbo.usp_mail_claim @limit int=10
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'WORKER'; EXEC dbo.usp_require_transaction; IF @limit IS NULL OR @limit<1 OR @limit>10 THROW 51000,'HP_INVALID:Claim limit',1; ;WITH candidates AS(SELECT TOP(@limit) id,recipient,subject,body,status,attempts,retry_at FROM dbo.mail_outbox WITH(UPDLOCK,READPAST,READCOMMITTEDLOCK) WHERE attempts<5 AND (status='PENDING' OR status='FAILED' AND retry_at<=SYSUTCDATETIME()) ORDER BY created_at,id) UPDATE candidates SET status='SENDING',attempts=attempts+1,retry_at=DATEADD(minute,2,SYSUTCDATETIME()) OUTPUT inserted.id,inserted.recipient,inserted.subject,inserted.body,inserted.attempts claim_version;
END;
GO

-- MailDelivery.deliver / replaces sp_mail_status: REJECTED only definite pre-acceptance rejection; unknown SMTP outcome stays SENDING for manual reconciliation.
CREATE PROCEDURE dbo.usp_mail_complete @mail_id char(36),@claim_version int,@outcome varchar(20)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'WORKER'; IF @outcome IS NULL OR @outcome NOT IN ('SENT','REJECTED','AMBIGUOUS') THROW 51000,'HP_INVALID:Mail outcome',1; UPDATE dbo.mail_outbox SET status=CASE @outcome WHEN 'SENT' THEN 'SENT' WHEN 'REJECTED' THEN 'FAILED' ELSE 'SENDING' END,sent_at=CASE WHEN @outcome='SENT' THEN SYSUTCDATETIME() ELSE NULL END,body=CASE WHEN @outcome='SENT' THEN N'[contenido entregado]' ELSE body END,retry_at=CASE WHEN @outcome='REJECTED' THEN DATEADD(minute,2,SYSUTCDATETIME()) ELSE retry_at END WHERE id=@mail_id AND status='SENDING' AND attempts=@claim_version; IF @@ROWCOUNT<>1 THROW 51003,'HP_CONFLICT:Mail claim no longer current',1;
END;
GO

-- MonitorService.sample/details, future Hikari/Actuator probe: constant query is inside SP, never Java SQL.
CREATE PROCEDURE dbo.usp_health_ready
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT CAST(1 AS int) ready;
END;
GO

-- SessionFilter write gate + MonitorService.status public view, no identities/secrets.
CREATE PROCEDURE dbo.usp_application_status
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 SELECT mode,message,revision FROM dbo.application_state WHERE id=1;
END;
GO

-- MonitorService.mode / V9 sp_application_mode: SAD only, works during maintenance, revision conflict.
CREATE PROCEDURE dbo.usp_application_mode @expected_revision int,@mode nvarchar(11),@message nvarchar(300)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'SAD',@platform_only=1; EXEC dbo.usp_require_transaction; IF @mode IS NULL OR @mode NOT IN ('OPEN','READ_ONLY','MAINTENANCE') OR NULLIF(LTRIM(RTRIM(@message)),N'') IS NULL THROW 51000,'HP_INVALID:Mode and reason required',1; UPDATE dbo.application_state WITH(UPDLOCK,HOLDLOCK) SET mode=@mode,message=@message,revision=revision+1 WHERE id=1 AND revision=@expected_revision; IF @@ROWCOUNT<>1 THROW 51003,'HP_CONFLICT:Application state changed',1; DECLARE @meta nvarchar(max)=(SELECT @mode mode,@message reason FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event NULL,N'APPLICATION_MODE_CHANGED',N'application',@meta;
END;
GO

-- MonitorService.sample / V9 sp_health_sample: worker sample and 7-day retention in caller transaction.
CREATE PROCEDURE dbo.usp_health_sample @instance_id char(36),@db_status nvarchar(20),@db_latency_ms bigint,@memory_used bigint,@memory_max bigint,@uptime_ms bigint
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'WORKER'; EXEC dbo.usp_require_transaction; IF @instance_id IS NULL OR @db_status IS NULL OR @db_latency_ms IS NULL OR @memory_used IS NULL OR @memory_max IS NULL OR @uptime_ms IS NULL OR @db_latency_ms<0 OR @memory_used<0 OR @memory_max<0 OR @uptime_ms<0 THROW 51000,'HP_INVALID:Health metrics',1; INSERT dbo.health_samples(instance_id,db_status,db_latency_ms,memory_used,memory_max,uptime_ms) VALUES(@instance_id,@db_status,@db_latency_ms,@memory_used,@memory_max,@uptime_ms); DELETE dbo.health_samples WHERE created_at<DATEADD(day,-7,SYSUTCDATETIME());
END;
GO

-- MonitorService.details.samples: platform only, exact health fields.
CREATE PROCEDURE dbo.usp_monitor_samples
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'SAD,SOP',@platform_only=1; SELECT TOP(120) id,instance_id,db_status,db_latency_ms,memory_used,memory_max,uptime_ms,created_at FROM dbo.health_samples ORDER BY id DESC;
END;
GO

-- MonitorService.details.mail: aggregated counts only, no recipients or content.
CREATE PROCEDURE dbo.usp_monitor_mail
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'SAD,SOP',@platform_only=1; SELECT status,COUNT_BIG(*) total FROM dbo.mail_outbox GROUP BY status;
END;
GO

-- MonitorService.details.requests: platform aggregate or current tenant only.
CREATE PROCEDURE dbo.usp_monitor_requests
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'SAD,SOP,ADM,AUD'; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); SELECT (status/100)*100 status_group,COUNT_BIG(*) total,CONVERT(bigint,ROUND(AVG(CONVERT(decimal(20,3),duration_ms)),0)) average_ms FROM dbo.request_traces WHERE created_at>DATEADD(hour,-1,SYSUTCDATETIME()) AND (@t IS NULL OR tenant_id=@t) GROUP BY (status/100)*100;
END;
GO

-- MonitorService.details.migrations: Flyway-owned history table, deferred resolution until Flyway runtime package.
CREATE PROCEDURE dbo.usp_monitor_migrations
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'SAD,SOP',@platform_only=1; IF OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NULL SELECT CAST(NULL AS nvarchar(50)) version,CAST(NULL AS nvarchar(200)) description,CAST(NULL AS datetime2(6)) installed_on,CAST(NULL AS bit) success WHERE 1=0; ELSE SELECT TOP(20) version,description,installed_on,success FROM dbo.flyway_schema_history ORDER BY installed_rank DESC;
END;
GO

-- TraceFilter.finally / V9 sp_request_finish: server status/duration, all identity/correlation from replaced context.
CREATE PROCEDURE dbo.usp_request_finish @status int,@duration_ms bigint
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF ISNULL(CONVERT(varchar(20),SESSION_CONTEXT(N'hp_scope')),'') NOT IN ('REQUEST','IDENTITY') THROW 51001,'HP_FORBIDDEN:HTTP request context required',1; IF @status IS NULL OR @status<100 OR @status>599 OR @duration_ms IS NULL OR @duration_ms<0 THROW 51000,'HP_INVALID:Request metrics',1; DECLARE @id char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')); IF @id IS NULL THROW 51000,'HP_INVALID:Request context required',1; INSERT dbo.request_traces(id,tenant_id,actor_id,method,route,status,duration_ms,source_ip,user_agent) VALUES(@id,CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),COALESCE(CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),N''),COALESCE(CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),N''),@status,@duration_ms,COALESCE(CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),N''),COALESCE(CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),N''));
END;
GO

-- AuditService.list: tenant legacy audit list, no global tenant bypass.
CREATE PROCEDURE dbo.usp_audit_list @limit int=50
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'ADM,AUD'; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF @t IS NULL THROW 51001,'HP_FORBIDDEN:Tenant audit required',1; IF @limit IS NULL SET @limit=50; SET @limit=CASE WHEN @limit<1 THEN 1 WHEN @limit>200 THEN 200 ELSE @limit END; SELECT TOP(@limit) id,actor_id,action,target_id,metadata,created_at FROM dbo.audit_events WHERE tenant_id=@t ORDER BY id DESC;
END;
GO

-- AuditService.events: returns limit+1 rows, caller preserves hasMore/nextCursor exactly; no interpolated filters.
CREATE PROCEDURE dbo.usp_trace_events @query nvarchar(100)=NULL,@actor_id char(36)=NULL,@resource nvarchar(60)=NULL,@request_id char(36)=NULL,@from datetime2(6)=NULL,@to datetime2(6)=NULL,@before bigint=0,@limit int=50
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'SAD,SOP,ADM,AUD'; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF @limit IS NULL SET @limit=50; SET @limit=CASE WHEN @limit<1 THEN 1 WHEN @limit>200 THEN 200 ELSE @limit END; IF @before IS NULL SET @before=0; DECLARE @take int=@limit+1; SELECT TOP(@take) e.id,e.tenant_id,e.actor_id,e.action,e.target_id,e.metadata,e.created_at,e.request_id,e.method,e.route,e.source_ip,e.user_agent,e.actor_roles,e.before_state,e.after_state,e.resource_type,u.name actor_name,u.email actor_email,t.name tenant_name FROM dbo.audit_events e LEFT JOIN dbo.users u ON u.id=e.actor_id LEFT JOIN dbo.tenants t ON t.id=e.tenant_id WHERE (@t IS NULL OR e.tenant_id=@t OR e.tenant_id IS NULL AND EXISTS(SELECT 1 FROM dbo.request_traces r WHERE r.id=e.request_id AND r.tenant_id=@t)) AND (NULLIF(@query,N'') IS NULL OR e.action LIKE N'%'+@query+N'%' OR e.target_id LIKE N'%'+@query+N'%' OR u.name LIKE N'%'+@query+N'%') AND (@actor_id IS NULL OR e.actor_id=@actor_id) AND (NULLIF(@resource,N'') IS NULL OR e.resource_type=@resource) AND (@request_id IS NULL OR e.request_id=@request_id) AND (@from IS NULL OR e.created_at>=@from) AND (@to IS NULL OR e.created_at<@to) AND (@before<=0 OR e.id<@before) ORDER BY e.id DESC;
END;
GO

-- AuditService.requests: all trace columns plus actor_name, status lower bound and search.
CREATE PROCEDURE dbo.usp_trace_requests @limit int=50,@status int=0,@query nvarchar(250)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'SAD,SOP,ADM,AUD'; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF @limit IS NULL SET @limit=50; SET @limit=CASE WHEN @limit<1 THEN 1 WHEN @limit>200 THEN 200 ELSE @limit END; SELECT TOP(@limit) r.id,r.tenant_id,r.actor_id,r.method,r.route,r.status,r.duration_ms,r.source_ip,r.user_agent,r.created_at,u.name actor_name FROM dbo.request_traces r LEFT JOIN dbo.users u ON u.id=r.actor_id WHERE (@t IS NULL OR r.tenant_id=@t) AND (@status<=0 OR r.status>=@status) AND (NULLIF(@query,N'') IS NULL OR r.route LIKE N'%'+@query+N'%' OR r.id=@query) ORDER BY r.created_at DESC,r.id DESC;
END;
GO

-- AuditService.journey: result set 1 request, result set 2 up to201 event rows; caller keeps first200 as existing HTTP contract.
CREATE PROCEDURE dbo.usp_trace_journey @request_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'SAD,SOP,ADM,AUD'; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF NOT EXISTS(SELECT 1 FROM dbo.request_traces WHERE id=@request_id AND (@t IS NULL OR tenant_id=@t)) THROW 51002,'HP_NOT_FOUND:Request trace',1; SELECT r.id,r.tenant_id,r.actor_id,r.method,r.route,r.status,r.duration_ms,r.source_ip,r.user_agent,r.created_at,u.name actor_name FROM dbo.request_traces r LEFT JOIN dbo.users u ON u.id=r.actor_id WHERE r.id=@request_id AND (@t IS NULL OR r.tenant_id=@t); EXEC dbo.usp_trace_events @request_id=@request_id,@limit=200;
END;
GO

-- SupportController.list: platform200 or current tenant/current author100, no ticket ids from other tenants.
CREATE PROCEDURE dbo.usp_support_list
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),@limit int=100; IF @t IS NULL BEGIN EXEC dbo.usp_require_actor @roles=N'SAD,SOP',@platform_only=1; SET @limit=200; END; SELECT TOP(@limit) id,tenant_id,actor_id,reference,email,subject,message,status,priority,revision,created_at,updated_at FROM dbo.support_tickets WHERE @t IS NULL OR tenant_id=@t AND actor_id=@u ORDER BY updated_at DESC,id;
END;
GO

-- PRIVATE SupportController.ticket authorization for detail/comments/update, masked404 for foreign tickets.
CREATE PROCEDURE dbo.usp_require_support_ticket @ticket_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')); IF @t IS NULL EXEC dbo.usp_require_actor @roles=N'SAD,SOP',@platform_only=1; IF NOT EXISTS(SELECT 1 FROM dbo.support_tickets WHERE id=@ticket_id AND (@t IS NULL OR tenant_id=@t AND actor_id=@u)) THROW 51002,'HP_NOT_FOUND:Support ticket',1;
END;
GO

-- SupportController.get: result set1 ticket and result set2 comments; MAX messages preserved.
CREATE PROCEDURE dbo.usp_support_detail @ticket_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_support_ticket @ticket_id; SELECT id,tenant_id,actor_id,reference,email,subject,message,status,priority,revision,created_at,updated_at FROM dbo.support_tickets WHERE id=@ticket_id; SELECT c.id,c.message,c.created_at,u.name actor_name FROM dbo.support_comments c JOIN dbo.users u ON u.id=c.actor_id WHERE c.ticket_id=@ticket_id ORDER BY c.created_at,c.id;
END;
GO

-- SupportController.create public / V9: preserve anonymous support in maintenance; no request body tenant/actor trusted.
CREATE PROCEDURE dbo.usp_support_create @ticket_id char(36),@reference nvarchar(30),@input nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_transaction; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')); IF @u IS NOT NULL EXEC dbo.usp_require_actor; IF @t IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.tenants WHERE id=@t) THROW 51002,'HP_NOT_FOUND:Support host',1; IF ISJSON(@input,OBJECT)<>1 OR @input IS NULL THROW 51000,'HP_INVALID:Support body',1; DECLARE @email nvarchar(max),@subject nvarchar(max),@message nvarchar(max),@priority nvarchar(max); SELECT @email=email,@subject=subject,@message=message,@priority=priority FROM OPENJSON(@input) WITH(email nvarchar(max),subject nvarchar(max),message nvarchar(max),priority nvarchar(max)); IF NULLIF(LTRIM(RTRIM(@email)),N'') IS NULL OR DATALENGTH(@email)>508 OR NULLIF(LTRIM(RTRIM(@subject)),N'') IS NULL OR DATALENGTH(@subject)>360 OR NULLIF(LTRIM(RTRIM(@message)),N'') IS NULL OR DATALENGTH(@message)>8000 OR @priority IS NULL OR @priority NOT IN ('LOW','NORMAL','HIGH','URGENT') THROW 51000,'HP_INVALID:Support fields',1; INSERT dbo.support_tickets(id,tenant_id,actor_id,reference,email,subject,message,priority) VALUES(@ticket_id,@t,@u,@reference,@email,@subject,@message,@priority); DECLARE @meta nvarchar(max)=(SELECT @reference reference FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event @t,N'SUPPORT_REQUESTED',@ticket_id,@meta;
END;
GO

-- SupportController.step / V9: expectedRevision and state transitions, tenant only own comments, platform technical status edit. Returns detail+comments.
CREATE PROCEDURE dbo.usp_support_step @ticket_id char(36),@expected_revision int,@status nvarchar(12),@priority nvarchar(6),@comment_id char(36),@comment nvarchar(max)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_transaction; EXEC dbo.usp_require_support_ticket @ticket_id; DECLARE @t char(36),@host char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),@rev int,@old nvarchar(12),@oldpriority nvarchar(6); SELECT @t=tenant_id,@rev=revision,@old=status,@oldpriority=priority FROM dbo.support_tickets WITH(UPDLOCK,HOLDLOCK) WHERE id=@ticket_id; IF @rev IS NULL THROW 51002,'HP_NOT_FOUND:Support ticket',1; IF @rev<>@expected_revision OR @expected_revision IS NULL THROW 51003,'HP_CONFLICT:Support ticket changed',1; IF @status IS NULL OR @status NOT IN ('OPEN','IN_PROGRESS','WAITING_USER','RESOLVED','CLOSED') OR @priority IS NULL OR @priority NOT IN ('LOW','NORMAL','HIGH','URGENT') OR DATALENGTH(@comment)>8000 THROW 51000,'HP_INVALID:Support step',1; IF @host IS NOT NULL AND (@old<>@status OR @oldpriority<>@priority OR NULLIF(LTRIM(RTRIM(@comment)),N'') IS NULL) THROW 51001,'HP_FORBIDDEN:Tenant can only comment',1; IF @old<>@status AND NOT ((@old='OPEN' AND @status IN ('IN_PROGRESS','CLOSED')) OR (@old='IN_PROGRESS' AND @status IN ('WAITING_USER','RESOLVED','CLOSED')) OR (@old='WAITING_USER' AND @status IN ('IN_PROGRESS','RESOLVED','CLOSED')) OR (@old='RESOLVED' AND @status IN ('IN_PROGRESS','CLOSED'))) THROW 51003,'HP_CONFLICT:Support transition',1; UPDATE dbo.support_tickets SET status=@status,priority=@priority,revision=revision+1,updated_at=SYSUTCDATETIME() WHERE id=@ticket_id; IF NULLIF(@comment,N'') IS NOT NULL INSERT dbo.support_comments(id,ticket_id,actor_id,message) VALUES(@comment_id,@ticket_id,@u,@comment); DECLARE @meta nvarchar(max)=(SELECT @old [from],@status [to],@rev+1 revision FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event @t,N'SUPPORT_UPDATED',@ticket_id,@meta; EXEC dbo.usp_support_detail @ticket_id;
END;
GO

-- PRIVATE V9 sp_audit_change foundation for future routines/triggers: only flat safe fields/hashes, no raw clinical or credential JSON.
CREATE PROCEDURE dbo.usp_audit_change @tenant_id char(36),@resource nvarchar(60),@target_id nvarchar(100),@operation varchar(10),@before_safe nvarchar(max)=NULL,@after_safe nvarchar(max)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_transaction; IF @operation IS NULL OR @operation NOT IN ('INSERT','UPDATE','DELETE') THROW 51000,'HP_INVALID:Audit operation',1; IF (@before_safe IS NOT NULL AND ISJSON(@before_safe,OBJECT)<>1) OR (@after_safe IS NOT NULL AND ISJSON(@after_safe,OBJECT)<>1) THROW 51000,'HP_INVALID:Audit projection',1; IF EXISTS(SELECT 1 FROM OPENJSON(COALESCE(@before_safe,N'{}')) UNION ALL SELECT 1 FROM OPENJSON(COALESCE(@after_safe,N'{}'))) BEGIN IF EXISTS(SELECT 1 FROM OPENJSON(COALESCE(@before_safe,N'{}')) WHERE type IN (4,5) OR [key] COLLATE Latin1_General_100_CI_AI IN ('password','password_hash','token','token_hash','csrf','csrf_token','body','content','payload','contact','allergies','note','profile','profile_snapshot')) OR EXISTS(SELECT 1 FROM OPENJSON(COALESCE(@after_safe,N'{}')) WHERE type IN (4,5) OR [key] COLLATE Latin1_General_100_CI_AI IN ('password','password_hash','token','token_hash','csrf','csrf_token','body','content','payload','contact','allergies','note','profile','profile_snapshot')) THROW 51000,'HP_INVALID:Audit requires flat safe projection; hash sensitive fields',1; END; DECLARE @action nvarchar(80)=@resource+N'_'+@operation,@meta nvarchar(max)=(SELECT @operation operation FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); INSERT dbo.audit_events(tenant_id,actor_id,action,target_id,metadata,request_id,method,route,source_ip,user_agent,actor_roles,before_state,after_state,resource_type) VALUES(@tenant_id,CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')),@action,@target_id,@meta,CONVERT(char(36),SESSION_CONTEXT(N'hp_request_id')),CONVERT(nvarchar(10),SESSION_CONTEXT(N'hp_method')),CONVERT(nvarchar(250),SESSION_CONTEXT(N'hp_route')),CONVERT(nvarchar(80),SESSION_CONTEXT(N'hp_source_ip')),CONVERT(nvarchar(300),SESSION_CONTEXT(N'hp_user_agent')),CONVERT(nvarchar(4000),SESSION_CONTEXT(N'hp_actor_roles')),@before_safe,@after_safe,@resource);
END;
GO
