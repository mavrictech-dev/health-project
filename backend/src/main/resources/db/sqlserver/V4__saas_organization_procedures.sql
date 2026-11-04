-- SQL Server 2022 / compatibility 160. SaaS and organization only.
-- Java owns the outer transaction; all helpers are PRIVATE and must not receive runtime grants.
-- JSON DTOs are server-normalized Requests records. No password hash in business result sets.
-- APIs without expectedRevision remain last-writer-wins; locks protect invariants, not stale edit detection.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
-- PRIVATE DTO validation: contract maps required property names to JSON types. No query text is accepted.
CREATE PROCEDURE dbo.usp_org_json_object @input nvarchar(max),@contract nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @input IS NULL OR ISJSON(@input,OBJECT)<>1 THROW 51000,'HP_INVALID:Objeto JSON requerido',1; IF EXISTS(SELECT [key] FROM OPENJSON(@input) GROUP BY [key] HAVING COUNT(*)<>1) OR EXISTS(SELECT 1 FROM OPENJSON(@input) i LEFT JOIN OPENJSON(@contract) c ON c.[key]=i.[key] WHERE c.[key] IS NULL OR i.type<>TRY_CONVERT(int,c.value)) OR EXISTS(SELECT 1 FROM OPENJSON(@contract) c WHERE NOT EXISTS(SELECT 1 FROM OPENJSON(@input) i WHERE i.[key]=c.[key])) THROW 51000,'HP_INVALID:Campos JSON ausentes, repetidos o de tipo incorrecto',1;
END;
GO

-- PRIVATE strict unique string arrays, no silent coercion/truncation. RS none.
CREATE PROCEDURE dbo.usp_org_json_strings @input nvarchar(max),@max_length int,@allowed nvarchar(max)=NULL,@nonempty bit=1
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @input IS NULL OR ISJSON(@input,ARRAY)<>1 THROW 51000,'HP_INVALID:Lista JSON requerida',1; IF @nonempty=1 AND NOT EXISTS(SELECT 1 FROM OPENJSON(@input)) THROW 51000,'HP_INVALID:Lista vacia',1; IF EXISTS(SELECT 1 FROM OPENJSON(@input) i WHERE i.type<>1 OR NULLIF(LTRIM(RTRIM(i.value)),N'') IS NULL OR DATALENGTH(i.value)<>2*LEN(i.value) OR DATALENGTH(i.value)>2*@max_length OR (@allowed IS NOT NULL AND NOT EXISTS(SELECT 1 FROM OPENJSON(@allowed) a WHERE a.value COLLATE Latin1_General_100_BIN2=i.value COLLATE Latin1_General_100_BIN2))) OR EXISTS(SELECT value COLLATE Latin1_General_100_BIN2 FROM OPENJSON(@input) GROUP BY value COLLATE Latin1_General_100_BIN2 HAVING COUNT(*)>1) THROW 51000,'HP_INVALID:Valores de lista invalidos o duplicados',1;
END;
GO

-- PRIVATE shared OPEN gate; no actor substitution and no transaction commits.
CREATE PROCEDURE dbo.usp_saas_write_gate
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_transaction; DECLARE @mode nvarchar(11); SELECT @mode=mode FROM dbo.application_state WITH(HOLDLOCK) WHERE id=1; IF @mode IS NULL OR @mode<>'OPEN' THROW 51005,'HP_APPLICATION_READ_ONLY:Escrituras no disponibles',1;
END;
GO

-- PRIVATE OrganizationService.target: SAD explicit target or ADM current tenant. Write locks serialize quota changes.
CREATE PROCEDURE dbo.usp_org_target @tenant_id char(36),@write bit=0,@require_active bit=1
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @tenant_id IS NULL THROW 51000,'HP_INVALID:Organizacion requerida',1; DECLARE @host char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF @host IS NULL EXEC dbo.usp_require_actor @roles=N'SAD',@platform_only=1; ELSE BEGIN EXEC dbo.usp_require_actor @roles=N'ADM'; IF @host<>@tenant_id THROW 51001,'HP_FORBIDDEN:La organizacion no corresponde al host',1; END; IF @write=0 BEGIN IF NOT EXISTS(SELECT 1 FROM dbo.tenants WHERE id=@tenant_id) THROW 51002,'HP_NOT_FOUND:Organizacion inexistente',1; END ELSE BEGIN EXEC dbo.usp_saas_write_gate; DECLARE @status nvarchar(10),@modules nvarchar(max); SELECT @status=t.status,@modules=v.modules FROM dbo.tenants t WITH(UPDLOCK,HOLDLOCK) JOIN dbo.subscriptions s ON s.tenant_id=t.id JOIN dbo.plan_versions v ON v.plan_id=s.plan_id AND v.version=s.plan_version WHERE t.id=@tenant_id; IF @status IS NULL THROW 51002,'HP_NOT_FOUND:Organizacion inexistente',1; IF @require_active=1 AND @status NOT IN ('TRIAL','ACTIVE') THROW 51004,'HP_SUSPENDED:Organizacion suspendida',1; IF @require_active=1 AND NOT EXISTS(SELECT 1 FROM OPENJSON(@modules) WHERE value='CORE') THROW 51001,'HP_FORBIDDEN:Modulo no incluido',1; END;
END;
GO

-- PlatformService.plans/plan result: all plan/current-version columns explicitly, optional id existence/read.
CREATE PROCEDURE dbo.usp_platform_plans @plan_id char(36)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'SAD',@platform_only=1; SELECT p.id,p.name,p.description,p.status,p.current_version,v.plan_id,v.version,v.base_minor,v.branch_minor,v.professional_minor,v.included_branches,v.included_professionals,v.included_specialties,v.max_branches,v.max_professionals,v.max_specialties,v.annual_discount,v.kinds,v.domains,v.modules,v.created_at FROM dbo.plans p JOIN dbo.plan_versions v ON v.plan_id=p.id AND v.version=p.current_version WHERE @plan_id IS NULL OR p.id=@plan_id ORDER BY p.name,p.id;
END;
GO

-- PlatformService.tenants/tenant/create/status: explicit TENANT_QUERY. Java retains hostname/url construction from trusted Settings.
CREATE PROCEDURE dbo.usp_platform_tenants @tenant_id char(36)=NULL,@limit int=100
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'SAD',@platform_only=1; SET @limit=CASE WHEN @limit IS NULL THEN 100 WHEN @limit<1 THEN 1 WHEN @limit>200 THEN 200 ELSE @limit END; SELECT TOP(@limit) t.id,t.name,t.slug,t.kind,t.domain,t.status,t.owner_user_id,t.timezone,t.created_at,u.name owner_name,u.email owner_email,s.plan_id,s.plan_version,s.cycle,s.branch_quota,s.professional_quota,s.specialty_quota,s.renewal_date,p.name plan_name,v.modules,v.base_minor,v.branch_minor,v.professional_minor,v.included_branches,v.included_professionals,v.annual_discount,(SELECT COUNT_BIG(*) FROM dbo.branches b WHERE b.tenant_id=t.id AND b.active=1 AND b.[external]=0) branches_used,(SELECT COUNT_BIG(*) FROM dbo.memberships m WHERE m.tenant_id=t.id AND m.status<>'INACTIVE' AND EXISTS(SELECT 1 FROM OPENJSON(m.roles) WHERE value='PRO')) professionals_used,(SELECT COUNT_BIG(*) FROM dbo.tenant_specialties x WHERE x.tenant_id=t.id) specialties_used FROM dbo.tenants t JOIN dbo.users u ON u.id=t.owner_user_id JOIN dbo.subscriptions s ON s.tenant_id=t.id JOIN dbo.plans p ON p.id=s.plan_id JOIN dbo.plan_versions v ON v.plan_id=s.plan_id AND v.version=s.plan_version WHERE @tenant_id IS NULL OR t.id=@tenant_id ORDER BY t.created_at DESC,t.id;
END;
GO

-- PlatformService.users/createUser and active owner resolution (caller checks active). Credential hashes never returned; identity creation remains V3 user_create inside caller transaction.
CREATE PROCEDURE dbo.usp_platform_users @user_id char(36)=NULL,@limit int=100
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'SAD',@platform_only=1; SET @limit=CASE WHEN @limit IS NULL THEN 100 WHEN @limit<1 THEN 1 WHEN @limit>200 THEN 200 ELSE @limit END; SELECT TOP(@limit) id,name,email,clinical_domain,credential,active FROM dbo.users WHERE @user_id IS NULL OR id=@user_id ORDER BY name,id;
END;
GO

-- PlatformService.specialties: full profiles, no truncation or invented paging.
CREATE PROCEDURE dbo.usp_platform_specialties @query nvarchar(220)=N''
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'SAD',@platform_only=1; SELECT code,name,domain,dental,profile FROM dbo.specialties WHERE name LIKE N'%'+COALESCE(@query,N'')+N'%' ORDER BY name,code;
END;
GO

-- PlatformService.audit: same administrative actions only, SAD only.
CREATE PROCEDURE dbo.usp_platform_audit @limit int=100
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'SAD',@platform_only=1; SET @limit=CASE WHEN @limit IS NULL THEN 100 WHEN @limit<1 THEN 1 WHEN @limit>200 THEN 200 ELSE @limit END; SELECT TOP(@limit) id,tenant_id,actor_id,action,target_id,metadata,created_at FROM dbo.audit_events WHERE action IN ('TENANT_CREATED','TENANT_STATUS_CHANGED','PLAN_VERSION_CREATED','SUBSCRIPTION_CHANGED','BRANCH_SAVED','AREA_SAVED','MEMBERSHIP_SAVED','SPECIALTIES_CONFIGURED','SAAS_PAYMENT_RECORDED') ORDER BY id DESC;
END;
GO

-- OrganizationService.configuration: 8 result sets root (id AND tenant_id),branches,areas,specialties,members,member-branch pairs,member-specialty pairs,invoices. Java groups pairs into string[] without changing DTO shape.
CREATE PROCEDURE dbo.usp_organization_configuration @tenant_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_org_target @tenant_id; SELECT t.id,t.name,t.slug,t.domain,t.kind,t.status,t.timezone,s.tenant_id,s.plan_id,s.plan_version,s.cycle,s.branch_quota,s.professional_quota,s.specialty_quota,s.renewal_date,p.name plan_name,v.version,v.base_minor,v.branch_minor,v.professional_minor,v.included_branches,v.included_professionals,v.included_specialties,v.max_branches,v.max_professionals,v.max_specialties,v.annual_discount,v.kinds,v.domains,v.modules,v.created_at FROM dbo.tenants t JOIN dbo.subscriptions s ON s.tenant_id=t.id JOIN dbo.plans p ON p.id=s.plan_id JOIN dbo.plan_versions v ON v.plan_id=s.plan_id AND v.version=s.plan_version WHERE t.id=@tenant_id; SELECT id,tenant_id,name,address,[external],active FROM dbo.branches WHERE tenant_id=@tenant_id ORDER BY name,id; SELECT id,tenant_id,branch_id,name,specialties FROM dbo.areas WHERE tenant_id=@tenant_id ORDER BY name,id; SELECT a.code,a.name,a.domain,a.dental,a.profile FROM dbo.specialties a JOIN dbo.tenant_specialties s ON s.specialty_code=a.code WHERE s.tenant_id=@tenant_id ORDER BY a.name,a.code; SELECT u.id,u.name,u.email,u.clinical_domain,u.credential,m.roles,m.status,m.owner FROM dbo.memberships m JOIN dbo.users u ON u.id=m.user_id WHERE m.tenant_id=@tenant_id ORDER BY u.name,u.id; SELECT user_id,branch_id FROM dbo.membership_branches WHERE tenant_id=@tenant_id ORDER BY user_id,branch_id; SELECT user_id,specialty_code FROM dbo.membership_specialties WHERE tenant_id=@tenant_id ORDER BY user_id,specialty_code; SELECT id,tenant_id,amount_minor,currency,cycle,status,created_at,paid_at FROM dbo.saas_invoices WHERE tenant_id=@tenant_id ORDER BY created_at DESC,id;
END;
GO

-- OrganizationService.lookup: ADM tenant only, existing identity lookup with no password hashes.
CREATE PROCEDURE dbo.usp_organization_lookup @email nvarchar(254)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF @t IS NULL THROW 51001,'HP_FORBIDDEN:Host de organizacion requerido',1; EXEC dbo.usp_org_target @t; SELECT id,name,email,clinical_domain,credential FROM dbo.users WHERE email=LOWER(@email) AND active=1 AND platform_role IS NULL;
END;
GO

-- OrganizationService.directory: any authenticated current tenant membership, active branches, platform denied.
CREATE PROCEDURE dbo.usp_organization_directory
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF @t IS NULL THROW 51001,'HP_FORBIDDEN:Host de organizacion requerido',1; SELECT id,name,address,[external],active FROM dbo.branches WHERE tenant_id=@t AND active=1 ORDER BY name,id;
END;
GO

-- OrganizationService.professionals: active PRO identities, optional branch membership authorization, no history.
CREATE PROCEDURE dbo.usp_organization_professionals @branch_id char(36)=NULL
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')),@u char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id')); IF @t IS NULL THROW 51001,'HP_FORBIDDEN:Host tenant requerido',1; IF @branch_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM dbo.branches b WHERE b.tenant_id=@t AND b.id=@branch_id AND b.active=1 AND (EXISTS(SELECT 1 FROM dbo.memberships m CROSS APPLY OPENJSON(m.roles) j WHERE m.tenant_id=@t AND m.user_id=@u AND j.value='ADM') OR EXISTS(SELECT 1 FROM dbo.membership_branches WHERE tenant_id=@t AND user_id=@u AND branch_id=@branch_id))) THROW 51001,'HP_FORBIDDEN:Sede no asignada',1; SELECT u.id,u.name,u.clinical_domain,u.credential,m.roles FROM dbo.memberships m JOIN dbo.users u ON u.id=m.user_id WHERE m.tenant_id=@t AND m.status='ACTIVE' AND EXISTS(SELECT 1 FROM OPENJSON(m.roles) WHERE value='PRO') AND (@branch_id IS NULL OR EXISTS(SELECT 1 FROM dbo.membership_branches b WHERE b.tenant_id=m.tenant_id AND b.user_id=m.user_id AND b.branch_id=@branch_id)) ORDER BY u.name,u.id;
END;
GO

-- OrganizationService.catalog: compatible specialty profiles, tenant only.
CREATE PROCEDURE dbo.usp_organization_catalog
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor; DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF @t IS NULL THROW 51001,'HP_FORBIDDEN:Host tenant requerido',1; SELECT a.code,a.name,a.domain,a.dental,a.profile FROM dbo.specialties a JOIN dbo.tenants t ON t.id=@t AND t.domain=a.domain WHERE t.kind<>'DENTAL' OR a.dental=1 ORDER BY a.name,a.code;
END;
GO

-- OrganizationService.availablePlans: ADM, published kind/domain-compatible offers.
CREATE PROCEDURE dbo.usp_organization_plans
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 DECLARE @t char(36)=CONVERT(char(36),SESSION_CONTEXT(N'hp_tenant_id')); IF @t IS NULL THROW 51001,'HP_FORBIDDEN:Host tenant requerido',1; EXEC dbo.usp_org_target @t; SELECT p.id,p.name,p.description,p.status,p.current_version,v.plan_id,v.version,v.base_minor,v.branch_minor,v.professional_minor,v.included_branches,v.included_professionals,v.included_specialties,v.max_branches,v.max_professionals,v.max_specialties,v.annual_discount,v.kinds,v.domains,v.modules,v.created_at FROM dbo.plans p JOIN dbo.plan_versions v ON v.plan_id=p.id AND v.version=p.current_version JOIN dbo.tenants t ON t.id=@t WHERE p.status='PUBLISHED' AND EXISTS(SELECT 1 FROM OPENJSON(v.kinds) WHERE value=t.kind) AND EXISTS(SELECT 1 FROM OPENJSON(v.domains) WHERE value=t.domain) ORDER BY p.name,p.id;
END;
GO
-- PlatformService.plan / V6 sp_plan_save: immutable version append, current pointer changes under lock; no expectedRevision in API. RS plan/current version.
CREATE PROCEDURE dbo.usp_saas_plan_save @plan_id char(36),@input nvarchar(max),@create bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'SAD',@platform_only=1; EXEC dbo.usp_saas_write_gate;
 EXEC dbo.usp_org_json_object @input,N'{"name":1,"description":1,"status":1,"baseMinor":2,"branchMinor":2,"professionalMinor":2,"includedBranches":2,"includedProfessionals":2,"includedSpecialties":2,"maxBranches":2,"maxProfessionals":2,"maxSpecialties":2,"annualDiscount":2,"kinds":4,"domains":4,"modules":4}';
 DECLARE @name nvarchar(max),@description nvarchar(max),@status nvarchar(max),@base bigint,@branch bigint,@professional bigint,@ib int,@ip int,@is int,@mb int,@mp int,@ms int,@discount int,@kinds nvarchar(max),@domains nvarchar(max),@modules nvarchar(max),@ver int;
 SELECT @name=name,@description=description,@status=status,@base=TRY_CONVERT(bigint,base),@branch=TRY_CONVERT(bigint,branch),@professional=TRY_CONVERT(bigint,professional),@ib=TRY_CONVERT(int,ib),@ip=TRY_CONVERT(int,ip),@is=TRY_CONVERT(int,ins),@mb=TRY_CONVERT(int,mb),@mp=TRY_CONVERT(int,mp),@ms=TRY_CONVERT(int,ms),@discount=TRY_CONVERT(int,discount),@kinds=kinds,@domains=domains,@modules=modules FROM OPENJSON(@input) WITH(name nvarchar(max),description nvarchar(max),status nvarchar(max),base nvarchar(max) '$.baseMinor',branch nvarchar(max) '$.branchMinor',professional nvarchar(max) '$.professionalMinor',ib nvarchar(max) '$.includedBranches',ip nvarchar(max) '$.includedProfessionals',ins nvarchar(max) '$.includedSpecialties',mb nvarchar(max) '$.maxBranches',mp nvarchar(max) '$.maxProfessionals',ms nvarchar(max) '$.maxSpecialties',discount nvarchar(max) '$.annualDiscount',kinds nvarchar(max) AS JSON,domains nvarchar(max) AS JSON,modules nvarchar(max) AS JSON);
 IF @create IS NULL OR @plan_id IS NULL OR NULLIF(LTRIM(RTRIM(@name)),N'') IS NULL OR DATALENGTH(@name)>200 OR DATALENGTH(@description)>1000 OR DATALENGTH(@status)<>2*LEN(@status) OR @status COLLATE Latin1_General_100_BIN2 NOT IN ('DRAFT','PUBLISHED','ARCHIVED') OR @base IS NULL OR @branch IS NULL OR @professional IS NULL OR @base NOT BETWEEN 0 AND 1000000000000 OR @branch NOT BETWEEN 0 AND 1000000000000 OR @professional NOT BETWEEN 0 AND 1000000000000 OR @ib IS NULL OR @ip IS NULL OR @is IS NULL OR @mb IS NULL OR @mp IS NULL OR @ms IS NULL OR @discount IS NULL OR @ib<1 OR @ip<1 OR @is<1 OR @mb<@ib OR @mp<@ip OR @ms<@is OR @mb>10000 OR @mp>100000 OR @ms>241 OR @discount NOT BETWEEN 0 AND 60 THROW 51000,'HP_INVALID:Oferta o limites invalidos',1;
 EXEC dbo.usp_org_json_strings @kinds,40,N'["DOCTOR","CLINIC","HOSPITAL","VETERINARY","DENTAL","SPECIALTY_CENTER"]'; EXEC dbo.usp_org_json_strings @domains,6,N'["HUMAN","ANIMAL"]'; EXEC dbo.usp_org_json_strings @modules,40,N'["CORE","PORTAL","DENTAL","DIAGNOSTICS","PHARMACY","FINANCE","INVENTORY","HOSPITAL","SURGERY","ADVANCED","VET_POPULATION","REPORTS"]';
 IF NOT EXISTS(SELECT 1 FROM OPENJSON(@modules) WHERE value COLLATE Latin1_General_100_BIN2='CORE') OR EXISTS(SELECT 1 FROM OPENJSON(@kinds) WHERE value='DOCTOR') AND @ip<>1 THROW 51000,'HP_INVALID:CORE requerido e independiente con una identidad',1;
 SELECT @ver=current_version FROM dbo.plans WITH(UPDLOCK,HOLDLOCK) WHERE id=@plan_id; IF @create=1 AND @ver IS NOT NULL THROW 51003,'HP_CONFLICT:Oferta existente',1; IF @create=0 AND @ver IS NULL THROW 51002,'HP_NOT_FOUND:Oferta inexistente',1;
 IF EXISTS(SELECT 1 FROM dbo.plans WITH(UPDLOCK,HOLDLOCK) WHERE name=@name AND id<>@plan_id) THROW 51003,'HP_CONFLICT:Nombre de oferta utilizado',1;
 SET @ver=COALESCE(@ver,0)+1; IF @create=1 INSERT dbo.plans(id,name,description,status,current_version) VALUES(@plan_id,@name,@description,@status,@ver); ELSE UPDATE dbo.plans SET name=@name,description=@description,status=@status,current_version=@ver WHERE id=@plan_id;
 INSERT dbo.plan_versions(plan_id,version,base_minor,branch_minor,professional_minor,included_branches,included_professionals,included_specialties,max_branches,max_professionals,max_specialties,annual_discount,kinds,domains,modules) VALUES(@plan_id,@ver,@base,@branch,@professional,@ib,@ip,@is,@mb,@mp,@ms,@discount,@kinds,@domains,@modules);
 DECLARE @meta nvarchar(max)=(SELECT @ver version FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event NULL,N'PLAN_VERSION_CREATED',@plan_id,@meta; EXEC dbo.usp_platform_plans @plan_id;
END;
GO

-- PRIVATE V2 sp_subscription_validate: locks selected current published version. Public derives MONTHLY and included quotas server-side; no client-selected version.
CREATE PROCEDURE dbo.usp_org_subscription_resolve @input nvarchar(max),@kind nvarchar(40),@domain nvarchar(6),@public bit,@plan_id char(36) OUTPUT,@version int OUTPUT,@cycle nvarchar(7) OUTPUT,@branch_quota int OUTPUT,@professional_quota int OUTPUT,@specialty_quota int OUTPUT,@modules nvarchar(max) OUTPUT
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_transaction;
 EXEC dbo.usp_org_json_object @input,N'{"planId":1,"cycle":1,"branchQuota":2,"professionalQuota":2,"specialtyQuota":2}';
 DECLARE @pid nvarchar(max),@cy nvarchar(max),@b nvarchar(max),@pr nvarchar(max),@sc nvarchar(max),@ib int,@ip int,@mb int,@mp int,@ms int,@ins int,@k nvarchar(max),@d nvarchar(max);
 SELECT @pid=planId,@cy=cycle,@b=b,@pr=pr,@sc=sc FROM OPENJSON(@input) WITH(planId nvarchar(max),cycle nvarchar(max),b nvarchar(max) '$.branchQuota',pr nvarchar(max) '$.professionalQuota',sc nvarchar(max) '$.specialtyQuota');
 IF DATALENGTH(@pid)<>72 OR TRY_CONVERT(uniqueidentifier,@pid) IS NULL THROW 51000,'HP_INVALID:Plan invalido',1;
 SET @plan_id=CONVERT(char(36),@pid); SET @version=NULL;
 SELECT @version=p.current_version,@ib=v.included_branches,@ip=v.included_professionals,@ins=v.included_specialties,@mb=v.max_branches,@mp=v.max_professionals,@ms=v.max_specialties,@k=v.kinds,@d=v.domains,@modules=v.modules FROM dbo.plans p WITH(HOLDLOCK) JOIN dbo.plan_versions v WITH(HOLDLOCK) ON v.plan_id=p.id AND v.version=p.current_version WHERE p.id=@plan_id AND p.status='PUBLISHED';
 IF @version IS NULL OR NOT EXISTS(SELECT 1 FROM OPENJSON(@k) WHERE value COLLATE Latin1_General_100_BIN2=@kind COLLATE Latin1_General_100_BIN2) OR NOT EXISTS(SELECT 1 FROM OPENJSON(@d) WHERE value COLLATE Latin1_General_100_BIN2=@domain COLLATE Latin1_General_100_BIN2) THROW 51000,'HP_INVALID:Plan no publicado o incompatible',1;
 SET @branch_quota=CASE WHEN @public=1 THEN @ib ELSE TRY_CONVERT(int,@b) END; SET @professional_quota=CASE WHEN @public=1 THEN @ip ELSE TRY_CONVERT(int,@pr) END; SET @specialty_quota=CASE WHEN @public=1 THEN @ins ELSE TRY_CONVERT(int,@sc) END; SET @cycle=CASE WHEN @public=1 THEN 'MONTHLY' ELSE @cy END;
 IF @branch_quota IS NULL OR @professional_quota IS NULL OR @specialty_quota IS NULL OR @branch_quota NOT BETWEEN @ib AND @mb OR @professional_quota NOT BETWEEN @ip AND @mp OR @specialty_quota NOT BETWEEN 1 AND @ms OR @cy COLLATE Latin1_General_100_BIN2 NOT IN ('MONTHLY','YEARLY') OR (@kind='DOCTOR' AND @professional_quota<>1) THROW 51003,'HP_CONFLICT:HP_QUOTA Capacidad fuera de limites del plan',1;
 IF DATALENGTH(@cy)<>2*LEN(@cy) OR (@public=0 AND DATALENGTH(@cy)>14) THROW 51000,'HP_INVALID:Ciclo invalido',1;
END;
GO

-- PRIVATE V2 sp_specialties_validate: catalog codes/domain/DENTAL/selected count, no clinical activation implied.
CREATE PROCEDURE dbo.usp_org_validate_specialties @codes nvarchar(max),@domain nvarchar(6),@kind nvarchar(40),@quota int,@modules nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_org_json_strings @codes,100; IF (SELECT COUNT(*) FROM OPENJSON(@codes))>@quota THROW 51003,'HP_CONFLICT:HP_QUOTA Cupo de especialidades excedido',1; IF EXISTS(SELECT 1 FROM OPENJSON(@codes) j LEFT JOIN dbo.specialties s ON s.code=j.value COLLATE Latin1_General_100_BIN2 WHERE s.code IS NULL OR s.domain<>@domain OR (@kind='DENTAL' AND s.dental=0)) THROW 51000,'HP_INVALID:Perfil o dominio incompatible',1; IF EXISTS(SELECT 1 FROM OPENJSON(@codes) j JOIN dbo.specialties s ON s.code=j.value COLLATE Latin1_General_100_BIN2 WHERE s.dental=1) AND NOT EXISTS(SELECT 1 FROM OPENJSON(@modules) WHERE value COLLATE Latin1_General_100_BIN2='DENTAL') THROW 51001,'HP_FORBIDDEN:El perfil requiere modulo odontologico',1;
END;
GO
-- PlatformService.create + AccountLifecycleService.register / V2 sp_tenant_create: owner resolved by Spring new/existing XOR in same TX; public only pending fresh owner, server included quotas/MONTHLY. IANA ZoneId validation remains Spring. RS tenant (SAD) or public created scope. No expectedRevision exists.
CREATE PROCEDURE dbo.usp_saas_tenant_create @tenant_id char(36),@branch_id char(36),@owner_id char(36),@input nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_saas_write_gate;
 DECLARE @public bit=CASE WHEN CONVERT(varchar(20),SESSION_CONTEXT(N'hp_scope'))='IDENTITY' AND SESSION_CONTEXT(N'hp_actor_id') IS NULL AND SESSION_CONTEXT(N'hp_tenant_id') IS NULL THEN 1 ELSE 0 END;
 IF @public=0 EXEC dbo.usp_require_actor @roles=N'SAD',@platform_only=1;
 EXEC dbo.usp_org_json_object @input,N'{"name":1,"slug":1,"kind":1,"domain":1,"timezone":1,"branchName":1,"address":1,"specialties":4,"subscription":5}';
 DECLARE @name nvarchar(max),@slug nvarchar(max),@kind nvarchar(max),@domain nvarchar(max),@zone nvarchar(max),@bname nvarchar(max),@address nvarchar(max),@codes nvarchar(max),@sub nvarchar(max),@pid char(36),@ver int,@cycle nvarchar(7),@b int,@pr int,@sc int,@modules nvarchar(max),@owner_domain nvarchar(6),@verified bit,@user_exists char(36);
 SELECT @name=name,@slug=slug,@kind=kind,@domain=domain,@zone=timezone,@bname=branchName,@address=address,@codes=specialties,@sub=subscription FROM OPENJSON(@input) WITH(name nvarchar(max),slug nvarchar(max),kind nvarchar(max),domain nvarchar(max),timezone nvarchar(max),branchName nvarchar(max),address nvarchar(max),specialties nvarchar(max) AS JSON,subscription nvarchar(max) AS JSON);
 IF @tenant_id IS NULL OR @branch_id IS NULL OR @owner_id IS NULL OR NULLIF(LTRIM(RTRIM(@name)),N'') IS NULL OR DATALENGTH(@name)>320 OR NULLIF(LTRIM(RTRIM(@bname)),N'') IS NULL OR DATALENGTH(@bname)>320 OR DATALENGTH(@address)>600 OR NULLIF(LTRIM(RTRIM(@zone)),N'') IS NULL OR DATALENGTH(@zone)>128 OR DATALENGTH(@kind)<>2*LEN(@kind) OR DATALENGTH(@domain)<>2*LEN(@domain) OR @kind COLLATE Latin1_General_100_BIN2 NOT IN ('DOCTOR','CLINIC','HOSPITAL','VETERINARY','DENTAL','SPECIALTY_CENTER') OR @domain COLLATE Latin1_General_100_BIN2 NOT IN ('HUMAN','ANIMAL') OR (@kind='VETERINARY' AND @domain<>'ANIMAL') OR (@kind NOT IN ('DOCTOR','VETERINARY') AND @domain<>'HUMAN') THROW 51000,'HP_INVALID:Datos de organizacion invalidos',1;
 IF LEN(@slug) NOT BETWEEN 1 AND 63 OR DATALENGTH(@slug)<>2*LEN(@slug) OR @slug COLLATE Latin1_General_100_BIN2 LIKE N'%[^a-z0-9-]%' OR LEFT(@slug,1)='-' OR RIGHT(@slug,1)='-' OR @slug LIKE N'%--%' OR @slug IN ('www','admin','api','app','saas','mail','support','status','auth','portal','localhost') THROW 51000,'HP_INVALID:Subdominio invalido o reservado',1;
 SELECT @user_exists=id,@owner_domain=clinical_domain,@verified=email_verified FROM dbo.users WITH(UPDLOCK,HOLDLOCK) WHERE id=@owner_id AND active=1 AND platform_role IS NULL;
 IF @user_exists IS NULL OR (@kind='DOCTOR' AND (@owner_domain IS NULL OR @owner_domain<>@domain)) THROW 51000,'HP_INVALID:Propietario o dominio incompatible',1;
 IF @public=1 AND (@verified<>0 OR EXISTS(SELECT 1 FROM dbo.memberships WITH(UPDLOCK,HOLDLOCK) WHERE user_id=@owner_id) OR EXISTS(SELECT 1 FROM dbo.tenants WITH(UPDLOCK,HOLDLOCK) WHERE owner_user_id=@owner_id)) THROW 51001,'HP_FORBIDDEN:El registro requiere identidad nueva sin membresias',1;
 IF EXISTS(SELECT 1 FROM dbo.branches WITH(UPDLOCK,HOLDLOCK) WHERE id=@branch_id) THROW 51003,'HP_CONFLICT:Identificador de sede existente',1; IF EXISTS(SELECT 1 FROM dbo.tenants WITH(UPDLOCK,HOLDLOCK) WHERE slug=@slug OR id=@tenant_id) THROW 51003,'HP_CONFLICT:Subdominio o cliente existente',1;
 EXEC dbo.usp_org_subscription_resolve @sub,@kind,@domain,@public,@pid OUTPUT,@ver OUTPUT,@cycle OUTPUT,@b OUTPUT,@pr OUTPUT,@sc OUTPUT,@modules OUTPUT;
 EXEC dbo.usp_org_validate_specialties @codes,@domain,@kind,@sc,@modules;
 INSERT dbo.tenants(id,name,slug,kind,domain,owner_user_id,timezone) VALUES(@tenant_id,@name,@slug,@kind,@domain,@owner_id,@zone);
 INSERT dbo.subscriptions(tenant_id,plan_id,plan_version,cycle,branch_quota,professional_quota,specialty_quota,renewal_date) VALUES(@tenant_id,@pid,@ver,@cycle,@b,@pr,@sc,CONVERT(date,CASE WHEN @cycle='YEARLY' THEN DATEADD(year,1,SYSUTCDATETIME()) ELSE DATEADD(month,1,SYSUTCDATETIME()) END));
 INSERT dbo.branches(id,tenant_id,name,address,[external],active) VALUES(@branch_id,@tenant_id,@bname,@address,0,1);
 INSERT dbo.tenant_specialties(tenant_id,specialty_code) SELECT @tenant_id,value FROM OPENJSON(@codes);
 INSERT dbo.areas(id,tenant_id,branch_id,name,specialties) VALUES(CONVERT(char(36),NEWID()),@tenant_id,@branch_id,N'Consulta y atencion',@codes);
 INSERT dbo.memberships(tenant_id,user_id,roles,status,owner) VALUES(@tenant_id,@owner_id,CASE WHEN @kind='DOCTOR' THEN N'["ADM","PRO"]' ELSE N'["ADM"]' END,'ACTIVE',1);
 INSERT dbo.membership_branches(tenant_id,user_id,branch_id) VALUES(@tenant_id,@owner_id,@branch_id);
 IF @kind='DOCTOR' INSERT dbo.membership_specialties(tenant_id,user_id,specialty_code) SELECT @tenant_id,@owner_id,value FROM OPENJSON(@codes);
 DECLARE @meta nvarchar(max)=(SELECT @slug slug FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event @tenant_id,N'TENANT_CREATED',@tenant_id,@meta;
 IF @public=0 EXEC dbo.usp_platform_tenants @tenant_id; ELSE SELECT @tenant_id id,@tenant_id tenant_id,@slug slug,@kind kind,@domain domain,CAST('TRIAL' AS nvarchar(10)) status;
END;
GO

-- PlatformService.status / V2: recovery from suspended/cancelled allowed, global OPEN required; no optimistic revision in current DTO.
CREATE PROCEDURE dbo.usp_saas_tenant_status @tenant_id char(36),@status nvarchar(10),@reason nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'SAD',@platform_only=1; EXEC dbo.usp_saas_write_gate; IF @status IS NULL OR DATALENGTH(@status)<>2*LEN(@status) OR @status COLLATE Latin1_General_100_BIN2 NOT IN ('TRIAL','ACTIVE','SUSPENDED','CANCELLED') OR NULLIF(LTRIM(RTRIM(@reason)),N'') IS NULL OR DATALENGTH(@reason)>1000 THROW 51000,'HP_INVALID:Estado y motivo requeridos',1; UPDATE dbo.tenants WITH(UPDLOCK,HOLDLOCK) SET status=@status WHERE id=@tenant_id; IF @@ROWCOUNT<>1 THROW 51002,'HP_NOT_FOUND:Organizacion inexistente',1; DECLARE @meta nvarchar(max)=(SELECT @status status,@reason reason FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event @tenant_id,N'TENANT_STATUS_CHANGED',@tenant_id,@meta; EXEC dbo.usp_platform_tenants @tenant_id;
END;
GO

-- OrganizationService.subscription / V2: locked tenant serializes consumption; snapshots old plan versions/invoices preserved. RS eight configuration sets, no tenant auto-resume; no expectedRevision in API.
CREATE PROCEDURE dbo.usp_organization_subscription_change @tenant_id char(36),@invoice_id char(36),@input nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 IF @invoice_id IS NULL THROW 51000,'HP_INVALID:Comprobante requerido',1; DECLARE @require_active bit=CASE WHEN SESSION_CONTEXT(N'hp_tenant_id') IS NULL THEN 0 ELSE 1 END; EXEC dbo.usp_org_target @tenant_id,@write=1,@require_active=@require_active;
 DECLARE @kind nvarchar(40),@domain nvarchar(6),@pid char(36),@ver int,@cycle nvarchar(7),@b int,@pr int,@sc int,@modules nvarchar(max),@amount decimal(38,0),@base bigint,@br bigint,@pro bigint,@ib int,@ip int,@discount int;
 SELECT @kind=kind,@domain=domain FROM dbo.tenants WHERE id=@tenant_id;
 EXEC dbo.usp_org_subscription_resolve @input,@kind,@domain,0,@pid OUTPUT,@ver OUTPUT,@cycle OUTPUT,@b OUTPUT,@pr OUTPUT,@sc OUTPUT,@modules OUTPUT;
 IF @b<(SELECT COUNT_BIG(*) FROM dbo.branches WHERE tenant_id=@tenant_id AND active=1 AND [external]=0) OR @pr<(SELECT COUNT_BIG(*) FROM dbo.memberships m WHERE m.tenant_id=@tenant_id AND m.status<>'INACTIVE' AND EXISTS(SELECT 1 FROM OPENJSON(m.roles) WHERE value='PRO')) OR @sc<(SELECT COUNT_BIG(*) FROM dbo.tenant_specialties WHERE tenant_id=@tenant_id) THROW 51003,'HP_CONFLICT:HP_QUOTA Contrato inferior al consumo',1;
 IF EXISTS(SELECT 1 FROM dbo.tenant_specialties ts JOIN dbo.specialties s ON s.code=ts.specialty_code WHERE ts.tenant_id=@tenant_id AND s.dental=1) AND NOT EXISTS(SELECT 1 FROM OPENJSON(@modules) WHERE value='DENTAL') THROW 51001,'HP_FORBIDDEN:Conserva modulo odontologico de perfiles asignados',1;
 SELECT @base=base_minor,@br=branch_minor,@pro=professional_minor,@ib=included_branches,@ip=included_professionals,@discount=annual_discount FROM dbo.plan_versions WHERE plan_id=@pid AND version=@ver;
 SET @amount=CONVERT(decimal(38,0),@base)+CONVERT(decimal(38,0),CASE WHEN @b>@ib THEN @b-@ib ELSE 0 END)*@br+CONVERT(decimal(38,0),CASE WHEN @pr>@ip THEN @pr-@ip ELSE 0 END)*@pro;
 IF @cycle='YEARLY' SET @amount=FLOOR((@amount*12*(100-@discount)+50)/100);
 IF @amount>9223372036854775807 THROW 51000,'HP_INVALID:Importe fuera de rango',1;
 UPDATE dbo.subscriptions SET plan_id=@pid,plan_version=@ver,cycle=@cycle,branch_quota=@b,professional_quota=@pr,specialty_quota=@sc,renewal_date=CONVERT(date,CASE WHEN @cycle='YEARLY' THEN DATEADD(year,1,SYSUTCDATETIME()) ELSE DATEADD(month,1,SYSUTCDATETIME()) END) WHERE tenant_id=@tenant_id;
 INSERT dbo.saas_invoices(id,tenant_id,amount_minor,cycle,status) VALUES(@invoice_id,@tenant_id,CONVERT(bigint,@amount),@cycle,'PENDING');
 DECLARE @meta nvarchar(max)=(SELECT @pid planId,@ver version FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event @tenant_id,N'SUBSCRIPTION_CHANGED',@tenant_id,@meta; EXEC dbo.usp_organization_configuration @tenant_id;
END;
GO

-- PlatformService.pay / V2: idempotent internal SaaS payment marker only; no external payment provider or clinical finance side effects.
CREATE PROCEDURE dbo.usp_saas_invoice_pay @tenant_id char(36),@invoice_id char(36)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'SAD',@platform_only=1; EXEC dbo.usp_saas_write_gate; DECLARE @state nvarchar(7); SELECT @state=status FROM dbo.saas_invoices WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@tenant_id AND id=@invoice_id; IF @state IS NULL THROW 51002,'HP_NOT_FOUND:Comprobante inexistente',1; IF @state='PENDING' BEGIN UPDATE dbo.saas_invoices SET status='PAID',paid_at=SYSUTCDATETIME() WHERE tenant_id=@tenant_id AND id=@invoice_id; EXEC dbo.usp_audit_event @tenant_id,N'SAAS_PAYMENT_RECORDED',@invoice_id; END; SELECT id,tenant_id,amount_minor,currency,cycle,status,created_at,paid_at FROM dbo.saas_invoices WHERE tenant_id=@tenant_id AND id=@invoice_id;
END;
GO
-- OrganizationService.branch / active V6: same-tenant POST/PUT existence, quota and last owned active branch, external DOCTOR-owner, pending operations block deactivation. RS Branch; API has no revision.
CREATE PROCEDURE dbo.usp_organization_branch_save @tenant_id char(36),@branch_id char(36),@input nvarchar(max),@create bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_org_target @tenant_id,@write=1; EXEC dbo.usp_org_json_object @input,N'{"name":1,"address":1,"external":3,"active":3}';
 DECLARE @name nvarchar(max),@address nvarchar(max),@ext bit,@active bit,@kind nvarchar(40),@owner char(36),@quota int,@used int,@oldactive bit,@oldext bit;
 SELECT @name=name,@address=address,@ext=CASE WHEN [external]='true' THEN 1 ELSE 0 END,@active=CASE WHEN active='true' THEN 1 ELSE 0 END FROM OPENJSON(@input) WITH(name nvarchar(max),address nvarchar(max),[external] nvarchar(max),active nvarchar(max));
 IF @branch_id IS NULL OR NULLIF(LTRIM(RTRIM(@name)),N'') IS NULL OR DATALENGTH(@name)>320 OR DATALENGTH(@address)>600 OR @create IS NULL THROW 51000,'HP_INVALID:Datos de sede invalidos',1;
 SELECT @kind=kind,@owner=owner_user_id FROM dbo.tenants WHERE id=@tenant_id; SELECT @quota=branch_quota FROM dbo.subscriptions WHERE tenant_id=@tenant_id;
 IF @ext=1 AND (@kind<>'DOCTOR' OR (SESSION_CONTEXT(N'hp_tenant_id') IS NOT NULL AND CONVERT(char(36),SESSION_CONTEXT(N'hp_actor_id'))<>@owner)) THROW 51001,'HP_FORBIDDEN:Lugar externo solo para propietario independiente',1;
 IF EXISTS(SELECT 1 FROM dbo.branches WHERE id=@branch_id AND tenant_id<>@tenant_id) THROW 51002,'HP_NOT_FOUND:Sede inexistente',1;
 SELECT @oldactive=active,@oldext=[external] FROM dbo.branches WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@tenant_id AND id=@branch_id;
 IF @create=1 AND @oldactive IS NOT NULL THROW 51003,'HP_CONFLICT:Sede existente',1; IF @create=0 AND @oldactive IS NULL THROW 51002,'HP_NOT_FOUND:Sede inexistente',1;
 SELECT @used=COUNT(*) FROM dbo.branches WHERE tenant_id=@tenant_id AND active=1 AND [external]=0;
 IF (@oldactive IS NULL OR @oldactive=0 OR @oldext=1) AND @active=1 AND @ext=0 AND @used>=@quota THROW 51003,'HP_CONFLICT:HP_QUOTA No hay capacidad de sedes',1;
 IF @oldactive=1 AND @oldext=0 AND (@active=0 OR @ext=1) AND @used<=1 THROW 51000,'HP_INVALID:Debe quedar una sede propia activa',1;
 IF @oldactive=1 AND @active=0 AND (EXISTS(SELECT 1 FROM dbo.appointments WHERE tenant_id=@tenant_id AND branch_id=@branch_id AND status NOT IN ('CANCELLED','WITHDRAWN','COMPLETED')) OR EXISTS(SELECT 1 FROM dbo.encounters WHERE tenant_id=@tenant_id AND branch_id=@branch_id AND status<>'FINALIZED') OR EXISTS(SELECT 1 FROM dbo.admissions a JOIN dbo.hospital_resources r ON r.tenant_id=a.tenant_id AND r.id=a.resource_id WHERE a.tenant_id=@tenant_id AND r.branch_id=@branch_id AND a.status='ADMITTED') OR EXISTS(SELECT 1 FROM dbo.stock_transfers x JOIN dbo.stock_lots l ON l.tenant_id=x.tenant_id AND l.id=x.lot_id WHERE x.tenant_id=@tenant_id AND x.status='IN_TRANSIT' AND (x.destination_branch_id=@branch_id OR l.branch_id=@branch_id)) OR EXISTS(SELECT 1 FROM dbo.stock_lots WHERE tenant_id=@tenant_id AND branch_id=@branch_id AND quantity>0) OR EXISTS(SELECT 1 FROM dbo.workflow_cases WHERE tenant_id=@tenant_id AND branch_id=@branch_id AND status NOT IN ('COMPLETED','CANCELLED'))) THROW 51003,'HP_CONFLICT:La sede mantiene operaciones o stock pendientes',1;
 IF EXISTS(SELECT 1 FROM dbo.branches WHERE tenant_id=@tenant_id AND name=@name AND id<>@branch_id) THROW 51003,'HP_CONFLICT:Nombre de sede utilizado',1;
 IF @create=1 INSERT dbo.branches(id,tenant_id,name,address,[external],active) VALUES(@branch_id,@tenant_id,@name,@address,@ext,@active); ELSE UPDATE dbo.branches SET name=@name,address=@address,[external]=@ext,active=@active WHERE tenant_id=@tenant_id AND id=@branch_id;
 DECLARE @meta nvarchar(max)=(SELECT @active active FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event @tenant_id,N'BRANCH_SAVED',@branch_id,@meta; SELECT id,tenant_id,name,address,[external],active FROM dbo.branches WHERE tenant_id=@tenant_id AND id=@branch_id;
END;
GO

-- OrganizationService.area / V2: own active branch and activated specialties; no expectedRevision exists. RS Area JSON specialties.
CREATE PROCEDURE dbo.usp_organization_area_save @tenant_id char(36),@area_id char(36),@input nvarchar(max),@create bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_org_target @tenant_id,@write=1; EXEC dbo.usp_org_json_object @input,N'{"branchId":1,"name":1,"specialties":4}'; DECLARE @branch nvarchar(max),@name nvarchar(max),@codes nvarchar(max); SELECT @branch=branchId,@name=name,@codes=specialties FROM OPENJSON(@input) WITH(branchId nvarchar(max),name nvarchar(max),specialties nvarchar(max) AS JSON); IF @area_id IS NULL OR @create IS NULL OR DATALENGTH(@branch)<>72 OR TRY_CONVERT(uniqueidentifier,@branch) IS NULL OR NULLIF(LTRIM(RTRIM(@name)),N'') IS NULL OR DATALENGTH(@name)>320 THROW 51000,'HP_INVALID:Datos de area invalidos',1; IF NOT EXISTS(SELECT 1 FROM dbo.branches WHERE tenant_id=@tenant_id AND id=@branch AND active=1) THROW 51002,'HP_NOT_FOUND:Sede no disponible',1; EXEC dbo.usp_org_json_strings @codes,100; IF EXISTS(SELECT 1 FROM OPENJSON(@codes) j WHERE NOT EXISTS(SELECT 1 FROM dbo.tenant_specialties ts WHERE ts.tenant_id=@tenant_id AND ts.specialty_code=j.value COLLATE Latin1_General_100_BIN2)) THROW 51000,'HP_INVALID:Especialidad no activada en la organizacion',1; IF EXISTS(SELECT 1 FROM dbo.areas WHERE id=@area_id AND tenant_id<>@tenant_id) THROW 51002,'HP_NOT_FOUND:Area inexistente',1; IF @create=0 AND NOT EXISTS(SELECT 1 FROM dbo.areas WHERE tenant_id=@tenant_id AND id=@area_id) THROW 51002,'HP_NOT_FOUND:Area inexistente',1; IF @create=1 AND EXISTS(SELECT 1 FROM dbo.areas WHERE id=@area_id) THROW 51003,'HP_CONFLICT:Area existente',1; IF EXISTS(SELECT 1 FROM dbo.areas WHERE tenant_id=@tenant_id AND branch_id=@branch AND name=@name AND id<>@area_id) THROW 51003,'HP_CONFLICT:Nombre de area utilizado',1; IF @create=1 INSERT dbo.areas(id,tenant_id,branch_id,name,specialties) VALUES(@area_id,@tenant_id,@branch,@name,@codes); ELSE UPDATE dbo.areas SET branch_id=@branch,name=@name,specialties=@codes WHERE tenant_id=@tenant_id AND id=@area_id; EXEC dbo.usp_audit_event @tenant_id,N'AREA_SAVED',@area_id; SELECT id,tenant_id,branch_id,name,specialties FROM dbo.areas WHERE tenant_id=@tenant_id AND id=@area_id;
END;
GO

-- OrganizationService.specialties / V2: preserve referenced specialties including area assignments, no clinical activation certification. RS configuration.
CREATE PROCEDURE dbo.usp_organization_specialties_save @tenant_id char(36),@codes nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_org_target @tenant_id,@write=1; DECLARE @domain nvarchar(6),@kind nvarchar(40),@quota int,@modules nvarchar(max); SELECT @domain=t.domain,@kind=t.kind,@quota=s.specialty_quota,@modules=v.modules FROM dbo.tenants t JOIN dbo.subscriptions s ON s.tenant_id=t.id JOIN dbo.plan_versions v ON v.plan_id=s.plan_id AND v.version=s.plan_version WHERE t.id=@tenant_id; EXEC dbo.usp_org_validate_specialties @codes,@domain,@kind,@quota,@modules; IF EXISTS(SELECT 1 FROM dbo.membership_specialties m WHERE m.tenant_id=@tenant_id AND NOT EXISTS(SELECT 1 FROM OPENJSON(@codes) j WHERE j.value COLLATE Latin1_General_100_BIN2=m.specialty_code)) OR EXISTS(SELECT 1 FROM dbo.appointments a WHERE a.tenant_id=@tenant_id AND NOT EXISTS(SELECT 1 FROM OPENJSON(@codes) j WHERE j.value COLLATE Latin1_General_100_BIN2=a.specialty_code)) OR EXISTS(SELECT 1 FROM dbo.encounters e WHERE e.tenant_id=@tenant_id AND NOT EXISTS(SELECT 1 FROM OPENJSON(@codes) j WHERE j.value COLLATE Latin1_General_100_BIN2=e.specialty_code)) OR EXISTS(SELECT 1 FROM dbo.areas a CROSS APPLY OPENJSON(a.specialties) j WHERE a.tenant_id=@tenant_id AND NOT EXISTS(SELECT 1 FROM OPENJSON(@codes) selected WHERE selected.value COLLATE Latin1_General_100_BIN2=j.value COLLATE Latin1_General_100_BIN2)) THROW 51003,'HP_CONFLICT:Conserva perfiles con asignaciones o historia',1; DELETE dbo.tenant_specialties WHERE tenant_id=@tenant_id AND NOT EXISTS(SELECT 1 FROM OPENJSON(@codes) j WHERE j.value COLLATE Latin1_General_100_BIN2=specialty_code); INSERT dbo.tenant_specialties(tenant_id,specialty_code) SELECT @tenant_id,j.value FROM OPENJSON(@codes) j WHERE NOT EXISTS(SELECT 1 FROM dbo.tenant_specialties ts WHERE ts.tenant_id=@tenant_id AND ts.specialty_code=j.value COLLATE Latin1_General_100_BIN2); DECLARE @count int=(SELECT COUNT(*) FROM OPENJSON(@codes)),@meta nvarchar(max); SET @meta=(SELECT @count [count] FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event @tenant_id,N'SPECIALTIES_CONFIGURED',@tenant_id,@meta; EXEC dbo.usp_organization_configuration @tenant_id;
END;
GO

-- OrganizationService.member / V2: Spring resolves userId XOR newly created user in same TX via V3. Actual tenant lock serializes counted PRO active/invited; owner preserved, DOCTOR sole clinical identity. RS saved member; no revision in API.
CREATE PROCEDURE dbo.usp_organization_member_save @tenant_id char(36),@user_id char(36),@input nvarchar(max)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_org_target @tenant_id,@write=1; EXEC dbo.usp_org_json_object @input,N'{"roles":4,"status":1,"branches":4,"specialties":4}'; DECLARE @roles nvarchar(max),@status nvarchar(max),@branches nvarchar(max),@codes nvarchar(max),@domain nvarchar(6),@kind nvarchar(40),@ownerid char(36),@quota int,@used int,@owner bit,@oldpro bit=0,@newpro bit=0,@userdomain nvarchar(6); SELECT @roles=roles,@status=status,@branches=branches,@codes=specialties FROM OPENJSON(@input) WITH(roles nvarchar(max) AS JSON,status nvarchar(max),branches nvarchar(max) AS JSON,specialties nvarchar(max) AS JSON); EXEC dbo.usp_org_json_strings @roles,3,N'["ADM","REC","PRO","ASI","DIA","FAR","CAJ","ALM","PAC","RES","AUD"]'; EXEC dbo.usp_org_json_strings @branches,36; EXEC dbo.usp_org_json_strings @codes,100,@nonempty=0; IF DATALENGTH(@status)<>2*LEN(@status) OR @status COLLATE Latin1_General_100_BIN2 NOT IN ('ACTIVE','INVITED','INACTIVE') THROW 51000,'HP_INVALID:Estado de miembro invalido',1; SELECT @domain=domain,@kind=kind,@ownerid=owner_user_id FROM dbo.tenants WHERE id=@tenant_id; SELECT @quota=professional_quota FROM dbo.subscriptions WHERE tenant_id=@tenant_id; IF NOT EXISTS(SELECT 1 FROM dbo.users WITH(UPDLOCK,HOLDLOCK) WHERE id=@user_id AND active=1 AND platform_role IS NULL) THROW 51002,'HP_NOT_FOUND:Identidad no disponible',1; SELECT @userdomain=clinical_domain FROM dbo.users WHERE id=@user_id; SELECT @owner=owner,@oldpro=CASE WHEN status<>'INACTIVE' AND EXISTS(SELECT 1 FROM OPENJSON(roles) WHERE value='PRO') THEN 1 ELSE 0 END FROM dbo.memberships WITH(UPDLOCK,HOLDLOCK) WHERE tenant_id=@tenant_id AND user_id=@user_id; IF EXISTS(SELECT 1 FROM OPENJSON(@roles) WHERE value='PRO') BEGIN IF (@status<>'INACTIVE' AND (@userdomain IS NULL OR @userdomain<>@domain)) OR (@kind='DOCTOR' AND @user_id<>@ownerid) THROW 51000,'HP_INVALID:Identidad profesional incompatible',1; IF @status<>'INACTIVE' SET @newpro=1; END; SELECT @used=COUNT(*) FROM dbo.memberships m WHERE m.tenant_id=@tenant_id AND m.status<>'INACTIVE' AND EXISTS(SELECT 1 FROM OPENJSON(m.roles) WHERE value='PRO'); IF @newpro=1 AND @oldpro=0 AND @used>=@quota THROW 51003,'HP_CONFLICT:HP_QUOTA Sin licencias profesionales disponibles',1; IF @owner=1 AND (@status<>'ACTIVE' OR NOT EXISTS(SELECT 1 FROM OPENJSON(@roles) WHERE value='ADM')) THROW 51000,'HP_INVALID:Conserva administrador propietario activo',1; IF EXISTS(SELECT 1 FROM OPENJSON(@branches) j WHERE DATALENGTH(j.value)<>72 OR TRY_CONVERT(uniqueidentifier,j.value) IS NULL OR NOT EXISTS(SELECT 1 FROM dbo.branches b WHERE b.tenant_id=@tenant_id AND b.id=j.value COLLATE Latin1_General_100_BIN2 AND b.active=1)) THROW 51000,'HP_INVALID:Asigna sedes activas del mismo tenant',1; IF EXISTS(SELECT 1 FROM OPENJSON(@roles) WHERE value='PRO') AND ((@newpro=1 AND NOT EXISTS(SELECT 1 FROM OPENJSON(@codes))) OR EXISTS(SELECT 1 FROM OPENJSON(@codes) j WHERE NOT EXISTS(SELECT 1 FROM dbo.tenant_specialties ts WHERE ts.tenant_id=@tenant_id AND ts.specialty_code=j.value COLLATE Latin1_General_100_BIN2))) THROW 51000,'HP_INVALID:Asigna especialidades activadas del tenant',1; IF NOT EXISTS(SELECT 1 FROM dbo.memberships WHERE tenant_id=@tenant_id AND user_id=@user_id) INSERT dbo.memberships(tenant_id,user_id,roles,status,owner) VALUES(@tenant_id,@user_id,@roles,@status,0); ELSE UPDATE dbo.memberships SET roles=@roles,status=@status WHERE tenant_id=@tenant_id AND user_id=@user_id; DELETE dbo.membership_branches WHERE tenant_id=@tenant_id AND user_id=@user_id; INSERT dbo.membership_branches(tenant_id,user_id,branch_id) SELECT @tenant_id,@user_id,value FROM OPENJSON(@branches); DELETE dbo.membership_specialties WHERE tenant_id=@tenant_id AND user_id=@user_id; IF EXISTS(SELECT 1 FROM OPENJSON(@roles) WHERE value='PRO') INSERT dbo.membership_specialties(tenant_id,user_id,specialty_code) SELECT @tenant_id,@user_id,value FROM OPENJSON(@codes); DECLARE @meta nvarchar(max)=(SELECT @status status FOR JSON PATH,WITHOUT_ARRAY_WRAPPER); EXEC dbo.usp_audit_event @tenant_id,N'MEMBERSHIP_SAVED',@user_id,@meta; SELECT u.id,u.name,u.email,u.clinical_domain,m.roles,m.status,m.owner FROM dbo.memberships m JOIN dbo.users u ON u.id=m.user_id WHERE m.tenant_id=@tenant_id AND m.user_id=@user_id;
END;
GO

-- PlatformService.createUser: saved user projection, no password hash and no extra active field.
CREATE PROCEDURE dbo.usp_platform_user @user_id char(36),@active_only bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_actor @roles=N'SAD',@platform_only=1;
 SELECT id,name,email,clinical_domain,credential FROM dbo.users WHERE id=@user_id AND (@active_only=0 OR active=1);
END;
GO
