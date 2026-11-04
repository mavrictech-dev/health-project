-- SQL Server 2022 / compatibility 160. Consolidated historical schema V1..V11.
-- V1: core 29 tables; V4: workflow definitions; V9: identity/trace/support/monitor.
-- V2/V3/V6/V7/V8/V10/V11 contain routines, grants or triggers, deferred to the SP package.
-- No cascades, database creation, principals or grants. Run only in the selected database.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
GO

-- Source: V1__schema.sql + V9 ALTERs
CREATE TABLE dbo.users (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [name] nvarchar(160) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [email] nvarchar(254) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [password_hash] nvarchar(100) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [clinical_domain] nvarchar(6) COLLATE Latin1_General_100_BIN2 NULL,
    [credential] nvarchar(100) COLLATE Latin1_General_100_CI_AI_SC NULL,
    [platform_role] nvarchar(3) COLLATE Latin1_General_100_BIN2 NULL,
    [active] bit NOT NULL CONSTRAINT DF_users_active DEFAULT (1),
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_users_created_at DEFAULT (SYSUTCDATETIME()),
    [email_verified] bit NOT NULL CONSTRAINT DF_users_email_verified DEFAULT (1),
    [login_failures] INT NOT NULL CONSTRAINT DF_users_login_failures DEFAULT (0),
    [locked_until] datetime2(6) NULL,
    CONSTRAINT PK_users PRIMARY KEY ([id]),
    CONSTRAINT CK_users_clinical_domain_enum CHECK ([clinical_domain] IN ('HUMAN','ANIMAL')),
    CONSTRAINT CK_users_platform_role_enum CHECK ([platform_role] IN ('SAD','SOP')),
    CONSTRAINT UQ_users_1 UNIQUE ([email])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.plans (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [name] nvarchar(100) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [description] nvarchar(500) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [status] nvarchar(9) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [current_version] INT NOT NULL CONSTRAINT DF_plans_current_version DEFAULT (0),
    CONSTRAINT PK_plans PRIMARY KEY ([id]),
    CONSTRAINT CK_plans_status_enum CHECK ([status] IN ('DRAFT','PUBLISHED','ARCHIVED')),
    CONSTRAINT UQ_plans_1 UNIQUE ([name])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.plan_versions (
    [plan_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [version] INT NOT NULL,
    [base_minor] BIGINT NOT NULL,
    [branch_minor] BIGINT NOT NULL,
    [professional_minor] BIGINT NOT NULL,
    [included_branches] INT NOT NULL,
    [included_professionals] INT NOT NULL,
    [included_specialties] INT NOT NULL,
    [max_branches] INT NOT NULL,
    [max_professionals] INT NOT NULL,
    [max_specialties] INT NOT NULL,
    [annual_discount] INT NOT NULL,
    [kinds] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [domains] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [modules] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_plan_versions_created_at DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_plan_versions PRIMARY KEY ([plan_id],[version]),
    CONSTRAINT CK_plan_versions_kinds_json CHECK ([kinds] IS NULL OR ISJSON([kinds], VALUE)=1),
    CONSTRAINT CK_plan_versions_domains_json CHECK ([domains] IS NULL OR ISJSON([domains], VALUE)=1),
    CONSTRAINT CK_plan_versions_modules_json CHECK ([modules] IS NULL OR ISJSON([modules], VALUE)=1),
    CONSTRAINT FK_plan_versions_1 FOREIGN KEY([plan_id]) REFERENCES dbo.plans([id]),
    CONSTRAINT CK_plan_versions_4 CHECK ([base_minor]>=0 AND [branch_minor]>=0 AND [professional_minor]>=0),
    CONSTRAINT CK_plan_versions_5 CHECK ([included_branches]>=1 AND [included_professionals]>=1 AND [included_specialties]>=1),
    CONSTRAINT CK_plan_versions_6 CHECK ([max_branches]>=[included_branches] AND [max_professionals]>=[included_professionals] AND [max_specialties]>=[included_specialties]),
    CONSTRAINT CK_plan_versions_7 CHECK ([annual_discount] BETWEEN 0 AND 60)
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.tenants (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [name] nvarchar(160) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [slug] varchar(63) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [kind] nvarchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [domain] nvarchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [status] nvarchar(9) COLLATE Latin1_General_100_BIN2 NOT NULL CONSTRAINT DF_tenants_status DEFAULT ('TRIAL'),
    [owner_user_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [timezone] nvarchar(64) COLLATE Latin1_General_100_CI_AI_SC NOT NULL CONSTRAINT DF_tenants_timezone DEFAULT ('America/Lima'),
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_tenants_created_at DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_tenants PRIMARY KEY ([id]),
    CONSTRAINT CK_tenants_kind_enum CHECK ([kind] IN ('DOCTOR','CLINIC','HOSPITAL','VETERINARY','DENTAL','SPECIALTY_CENTER')),
    CONSTRAINT CK_tenants_domain_enum CHECK ([domain] IN ('HUMAN','ANIMAL')),
    CONSTRAINT CK_tenants_status_enum CHECK ([status] IN ('TRIAL','ACTIVE','SUSPENDED','CANCELLED')),
    CONSTRAINT FK_tenants_1 FOREIGN KEY([owner_user_id]) REFERENCES dbo.users([id]),
    CONSTRAINT CK_tenants_4 CHECK (LEN([slug]) BETWEEN 1 AND 63 AND [slug] NOT LIKE '%[^a-z0-9-]%' COLLATE Latin1_General_100_BIN2 AND LEFT([slug],1)<>'-' AND RIGHT([slug],1)<>'-' AND [slug] NOT LIKE '%--%' AND DATALENGTH([slug])=LEN([slug])),
    CONSTRAINT CK_tenants_5 CHECK ([slug] NOT IN ('www','admin','api','app','saas','mail','support','status','auth','portal','localhost')),
    CONSTRAINT CK_tenants_6 CHECK (([kind] IN ('DOCTOR','VETERINARY') OR [domain]='HUMAN') AND ([kind]<>'VETERINARY' OR [domain]='ANIMAL')),
    CONSTRAINT UQ_tenants_1 UNIQUE ([slug])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.subscriptions (
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [plan_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [plan_version] INT NOT NULL,
    [cycle] nvarchar(7) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [branch_quota] INT NOT NULL,
    [professional_quota] INT NOT NULL,
    [specialty_quota] INT NOT NULL,
    [renewal_date] DATE NOT NULL,
    CONSTRAINT PK_subscriptions PRIMARY KEY ([tenant_id]),
    CONSTRAINT CK_subscriptions_cycle_enum CHECK ([cycle] IN ('MONTHLY','YEARLY')),
    CONSTRAINT FK_subscriptions_1 FOREIGN KEY([tenant_id]) REFERENCES dbo.tenants([id]),
    CONSTRAINT FK_subscriptions_2 FOREIGN KEY([plan_id],[plan_version]) REFERENCES dbo.plan_versions([plan_id],[version]),
    CONSTRAINT CK_subscriptions_2 CHECK ([branch_quota]>=1 AND [professional_quota]>=1 AND [specialty_quota]>=1)
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.specialties (
    [code] varchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [name] nvarchar(220) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [domain] nvarchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [dental] bit NOT NULL,
    [profile] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    CONSTRAINT PK_specialties PRIMARY KEY ([code]),
    CONSTRAINT CK_specialties_domain_enum CHECK ([domain] IN ('HUMAN','ANIMAL')),
    CONSTRAINT CK_specialties_profile_json CHECK ([profile] IS NULL OR ISJSON([profile], VALUE)=1)
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.tenant_specialties (
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [specialty_code] varchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
    CONSTRAINT PK_tenant_specialties PRIMARY KEY ([tenant_id],[specialty_code]),
    CONSTRAINT FK_tenant_specialties_1 FOREIGN KEY([tenant_id]) REFERENCES dbo.tenants([id]),
    CONSTRAINT FK_tenant_specialties_2 FOREIGN KEY([specialty_code]) REFERENCES dbo.specialties([code])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.branches (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [name] nvarchar(160) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [address] nvarchar(300) COLLATE Latin1_General_100_CI_AI_SC NOT NULL CONSTRAINT DF_branches_address DEFAULT (''),
    [external] bit NOT NULL CONSTRAINT DF_branches_external DEFAULT (0),
    [active] bit NOT NULL CONSTRAINT DF_branches_active DEFAULT (1),
    CONSTRAINT PK_branches PRIMARY KEY ([id]),
    CONSTRAINT FK_branches_1 FOREIGN KEY([tenant_id]) REFERENCES dbo.tenants([id]),
    CONSTRAINT UQ_branches_1 UNIQUE ([tenant_id],[id]),
    CONSTRAINT UQ_branches_2 UNIQUE ([tenant_id],[name])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.areas (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [branch_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [name] nvarchar(160) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [specialties] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    CONSTRAINT PK_areas PRIMARY KEY ([id]),
    CONSTRAINT CK_areas_specialties_json CHECK ([specialties] IS NULL OR ISJSON([specialties], VALUE)=1),
    CONSTRAINT FK_areas_1 FOREIGN KEY([tenant_id],[branch_id]) REFERENCES dbo.branches([tenant_id],[id]),
    CONSTRAINT UQ_areas_1 UNIQUE ([tenant_id],[id]),
    CONSTRAINT UQ_areas_2 UNIQUE ([tenant_id],[branch_id],[name])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.memberships (
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [user_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [roles] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [status] nvarchar(8) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [owner] bit NOT NULL CONSTRAINT DF_memberships_owner DEFAULT (0),
    CONSTRAINT PK_memberships PRIMARY KEY ([tenant_id],[user_id]),
    CONSTRAINT CK_memberships_roles_json CHECK ([roles] IS NULL OR ISJSON([roles], VALUE)=1),
    CONSTRAINT CK_memberships_status_enum CHECK ([status] IN ('ACTIVE','INVITED','INACTIVE')),
    CONSTRAINT FK_memberships_1 FOREIGN KEY([tenant_id]) REFERENCES dbo.tenants([id]),
    CONSTRAINT FK_memberships_2 FOREIGN KEY([user_id]) REFERENCES dbo.users([id]),
    CONSTRAINT CK_memberships_roles CHECK (ISJSON([roles], ARRAY)=1 AND JSON_VALUE([roles],'$[0]') IS NOT NULL AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([roles],'"ADM"',''),'"REC"',''),'"PRO"',''),'"ASI"',''),'"DIA"',''),'"FAR"',''),'"CAJ"',''),'"ALM"',''),'"PAC"',''),'"RES"',''),'"AUD"',''),'[',''),']',''),',',''),' ',''),CHAR(9),''),CHAR(10),''),CHAR(13),'')='')
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.membership_branches (
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [user_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [branch_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    CONSTRAINT PK_membership_branches PRIMARY KEY ([tenant_id],[user_id],[branch_id]),
    CONSTRAINT FK_membership_branches_1 FOREIGN KEY([tenant_id],[user_id]) REFERENCES dbo.memberships([tenant_id],[user_id]),
    CONSTRAINT FK_membership_branches_2 FOREIGN KEY([tenant_id],[branch_id]) REFERENCES dbo.branches([tenant_id],[id])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.membership_specialties (
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [user_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [specialty_code] varchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
    CONSTRAINT PK_membership_specialties PRIMARY KEY ([tenant_id],[user_id],[specialty_code]),
    CONSTRAINT FK_membership_specialties_1 FOREIGN KEY([tenant_id],[user_id]) REFERENCES dbo.memberships([tenant_id],[user_id]),
    CONSTRAINT FK_membership_specialties_2 FOREIGN KEY([tenant_id],[specialty_code]) REFERENCES dbo.tenant_specialties([tenant_id],[specialty_code])
 );
GO

-- Source: V1__schema.sql + V9 ALTERs
CREATE TABLE dbo.auth_sessions (
    [token_hash] char(64) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [user_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NULL,
    [expires_at] datetime2(6) NOT NULL,
    [revoked] bit NOT NULL CONSTRAINT DF_auth_sessions_revoked DEFAULT (0),
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_auth_sessions_created_at DEFAULT (SYSUTCDATETIME()),
    [csrf_token] char(64) COLLATE Latin1_General_100_BIN2 NOT NULL CONSTRAINT DF_auth_sessions_csrf_token DEFAULT (''),
    [last_seen_at] datetime2(6) NOT NULL CONSTRAINT DF_auth_sessions_last_seen_at DEFAULT (SYSUTCDATETIME()),
    [user_agent] nvarchar(300) COLLATE Latin1_General_100_CI_AI_SC NOT NULL CONSTRAINT DF_auth_sessions_user_agent DEFAULT (''),
    [source_ip] nvarchar(80) COLLATE Latin1_General_100_CI_AI_SC NOT NULL CONSTRAINT DF_auth_sessions_source_ip DEFAULT (''),
    CONSTRAINT PK_auth_sessions PRIMARY KEY ([token_hash]),
    CONSTRAINT FK_auth_sessions_1 FOREIGN KEY([user_id]) REFERENCES dbo.users([id]),
    CONSTRAINT FK_auth_sessions_2 FOREIGN KEY([tenant_id]) REFERENCES dbo.tenants([id])
 );
GO

-- Source: V1__schema.sql + V9 ALTERs
CREATE TABLE dbo.audit_events (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NULL,
    [actor_id] char(36) COLLATE Latin1_General_100_BIN2 NULL,
    [action] nvarchar(80) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [target_id] nvarchar(100) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [metadata] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_audit_events_created_at DEFAULT (SYSUTCDATETIME()),
    [request_id] char(36) COLLATE Latin1_General_100_BIN2 NULL,
    [method] nvarchar(10) COLLATE Latin1_General_100_CI_AI_SC NULL,
    [route] nvarchar(250) COLLATE Latin1_General_100_CI_AI_SC NULL,
    [source_ip] nvarchar(80) COLLATE Latin1_General_100_CI_AI_SC NULL,
    [user_agent] nvarchar(300) COLLATE Latin1_General_100_CI_AI_SC NULL,
    [actor_roles] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
    [before_state] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
    [after_state] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,
    [resource_type] nvarchar(60) COLLATE Latin1_General_100_CI_AI_SC NULL,
    CONSTRAINT PK_audit_events PRIMARY KEY ([id]),
    CONSTRAINT CK_audit_events_metadata_json CHECK ([metadata] IS NULL OR ISJSON([metadata], VALUE)=1),
    CONSTRAINT FK_audit_events_1 FOREIGN KEY([tenant_id]) REFERENCES dbo.tenants([id]),
    CONSTRAINT FK_audit_events_2 FOREIGN KEY([actor_id]) REFERENCES dbo.users([id]),
    CONSTRAINT CK_audit_events_actor_roles_json CHECK ([actor_roles] IS NULL OR ISJSON([actor_roles], VALUE)=1),
    CONSTRAINT CK_audit_events_before_state_json CHECK ([before_state] IS NULL OR ISJSON([before_state], VALUE)=1),
    CONSTRAINT CK_audit_events_after_state_json CHECK ([after_state] IS NULL OR ISJSON([after_state], VALUE)=1)
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.saas_invoices (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [amount_minor] BIGINT NOT NULL,
    [currency] char(3) COLLATE Latin1_General_100_BIN2 NOT NULL CONSTRAINT DF_saas_invoices_currency DEFAULT ('PEN'),
    [cycle] nvarchar(10) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [status] nvarchar(7) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_saas_invoices_created_at DEFAULT (SYSUTCDATETIME()),
    [paid_at] datetime2(6) NULL,
    CONSTRAINT PK_saas_invoices PRIMARY KEY ([id]),
    CONSTRAINT CK_saas_invoices_status_enum CHECK ([status] IN ('PENDING','PAID')),
    CONSTRAINT FK_saas_invoices_1 FOREIGN KEY([tenant_id]) REFERENCES dbo.tenants([id]),
    CONSTRAINT CK_saas_invoices_2 CHECK ([amount_minor]>=0),
    CONSTRAINT UQ_saas_invoices_1 UNIQUE ([tenant_id],[id])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.patients (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [name] nvarchar(160) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [domain] nvarchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [identifier] nvarchar(100) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [birth_date] DATE NULL,
    [species] nvarchar(80) COLLATE Latin1_General_100_CI_AI_SC NULL,
    [contact] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [allergies] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [revision] INT NOT NULL CONSTRAINT DF_patients_revision DEFAULT (1),
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_patients_created_at DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_patients PRIMARY KEY ([id]),
    CONSTRAINT CK_patients_domain_enum CHECK ([domain] IN ('HUMAN','ANIMAL')),
    CONSTRAINT CK_patients_contact_json CHECK ([contact] IS NULL OR ISJSON([contact], VALUE)=1),
    CONSTRAINT CK_patients_allergies_json CHECK ([allergies] IS NULL OR ISJSON([allergies], VALUE)=1),
    CONSTRAINT FK_patients_1 FOREIGN KEY([tenant_id]) REFERENCES dbo.tenants([id]),
    CONSTRAINT UQ_patients_1 UNIQUE ([tenant_id],[id]),
    CONSTRAINT UQ_patients_2 UNIQUE ([tenant_id],[identifier])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.patient_links (
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [patient_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [user_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [relationship] nvarchar(80) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [active] bit NOT NULL CONSTRAINT DF_patient_links_active DEFAULT (1),
    [scopes] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    CONSTRAINT PK_patient_links PRIMARY KEY ([tenant_id],[patient_id],[user_id]),
    CONSTRAINT CK_patient_links_scopes_json CHECK ([scopes] IS NULL OR ISJSON([scopes], VALUE)=1),
    CONSTRAINT FK_patient_links_1 FOREIGN KEY([tenant_id],[patient_id]) REFERENCES dbo.patients([tenant_id],[id]),
    CONSTRAINT FK_patient_links_2 FOREIGN KEY([user_id]) REFERENCES dbo.users([id])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.appointments (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [patient_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [branch_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [professional_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [specialty_code] varchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [starts_at] datetime2(6) NOT NULL,
    [ends_at] datetime2(6) NOT NULL,
    [status] nvarchar(9) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [service] nvarchar(160) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [note] nvarchar(1000) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [revision] INT NOT NULL CONSTRAINT DF_appointments_revision DEFAULT (1),
    [request_key] varchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [request_hash] char(64) COLLATE Latin1_General_100_BIN2 NOT NULL,
    CONSTRAINT PK_appointments PRIMARY KEY ([id]),
    CONSTRAINT CK_appointments_status_enum CHECK ([status] IN ('REQUESTED','RESERVED','CONFIRMED','WAITING','CALLED','IN_CARE','COMPLETED','CANCELLED','WITHDRAWN')),
    CONSTRAINT FK_appointments_1 FOREIGN KEY([tenant_id],[patient_id]) REFERENCES dbo.patients([tenant_id],[id]),
    CONSTRAINT FK_appointments_2 FOREIGN KEY([tenant_id],[branch_id]) REFERENCES dbo.branches([tenant_id],[id]),
    CONSTRAINT FK_appointments_3 FOREIGN KEY([tenant_id],[professional_id]) REFERENCES dbo.memberships([tenant_id],[user_id]),
    CONSTRAINT FK_appointments_4 FOREIGN KEY([tenant_id],[specialty_code]) REFERENCES dbo.tenant_specialties([tenant_id],[specialty_code]),
    CONSTRAINT CK_appointments_2 CHECK ([ends_at]>[starts_at]),
    CONSTRAINT UQ_appointments_1 UNIQUE ([tenant_id],[id]),
    CONSTRAINT UQ_appointments_2 UNIQUE ([tenant_id],[request_key])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.encounters (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [patient_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [branch_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [professional_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [specialty_code] varchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [status] nvarchar(9) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [note] nvarchar(max) NOT NULL,
    [revision] INT NOT NULL CONSTRAINT DF_encounters_revision DEFAULT (1),
    [profile_snapshot] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_encounters_created_at DEFAULT (SYSUTCDATETIME()),
    [finalized_at] datetime2(6) NULL,
    [active_patient] AS (CONVERT(char(36),CASE WHEN [status] <> 'FINALIZED' THEN [patient_id] ELSE NULL END) COLLATE Latin1_General_100_BIN2) PERSISTED,
    CONSTRAINT PK_encounters PRIMARY KEY ([id]),
    CONSTRAINT CK_encounters_status_enum CHECK ([status] IN ('ACTIVE','PENDING','FINALIZED')),
    CONSTRAINT CK_encounters_profile_snapshot_json CHECK ([profile_snapshot] IS NULL OR ISJSON([profile_snapshot], VALUE)=1),
    CONSTRAINT FK_encounters_1 FOREIGN KEY([tenant_id],[patient_id]) REFERENCES dbo.patients([tenant_id],[id]),
    CONSTRAINT FK_encounters_2 FOREIGN KEY([tenant_id],[branch_id]) REFERENCES dbo.branches([tenant_id],[id]),
    CONSTRAINT FK_encounters_3 FOREIGN KEY([tenant_id],[professional_id]) REFERENCES dbo.memberships([tenant_id],[user_id]),
    CONSTRAINT FK_encounters_4 FOREIGN KEY([tenant_id],[specialty_code]) REFERENCES dbo.tenant_specialties([tenant_id],[specialty_code]),
    CONSTRAINT UQ_encounters_1 UNIQUE ([tenant_id],[id])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.clinical_entries (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [encounter_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [kind] nvarchar(12) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [payload] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [profile_snapshot] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [actor_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_clinical_entries_created_at DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_clinical_entries PRIMARY KEY ([id]),
    CONSTRAINT CK_clinical_entries_kind_enum CHECK ([kind] IN ('EVALUATION','OBSERVATION','ANNOTATION','ORDER','PRESCRIPTION')),
    CONSTRAINT CK_clinical_entries_payload_json CHECK ([payload] IS NULL OR ISJSON([payload], VALUE)=1),
    CONSTRAINT CK_clinical_entries_profile_snapshot_json CHECK ([profile_snapshot] IS NULL OR ISJSON([profile_snapshot], VALUE)=1),
    CONSTRAINT FK_clinical_entries_1 FOREIGN KEY([tenant_id],[encounter_id]) REFERENCES dbo.encounters([tenant_id],[id]),
    CONSTRAINT FK_clinical_entries_2 FOREIGN KEY([actor_id]) REFERENCES dbo.users([id]),
    CONSTRAINT UQ_clinical_entries_1 UNIQUE ([tenant_id],[id])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.documents (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [patient_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [encounter_id] char(36) COLLATE Latin1_General_100_BIN2 NULL,
    [title] nvarchar(200) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [type] nvarchar(60) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [content] nvarchar(max) NOT NULL,
    [status] nvarchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [revision] INT NOT NULL CONSTRAINT DF_documents_revision DEFAULT (1),
    [original_id] char(36) COLLATE Latin1_General_100_BIN2 NULL,
    [signer_id] char(36) COLLATE Latin1_General_100_BIN2 NULL,
    [signed_at] datetime2(6) NULL,
    [content_hash] char(64) COLLATE Latin1_General_100_BIN2 NULL,
    [published] bit NOT NULL CONSTRAINT DF_documents_published DEFAULT (0),
    [withdrawn] bit NOT NULL CONSTRAINT DF_documents_withdrawn DEFAULT (0),
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_documents_created_at DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_documents PRIMARY KEY ([id]),
    CONSTRAINT CK_documents_status_enum CHECK ([status] IN ('DRAFT','SIGNED')),
    CONSTRAINT FK_documents_1 FOREIGN KEY([tenant_id],[patient_id]) REFERENCES dbo.patients([tenant_id],[id]),
    CONSTRAINT FK_documents_2 FOREIGN KEY([tenant_id],[encounter_id]) REFERENCES dbo.encounters([tenant_id],[id]),
    CONSTRAINT FK_documents_3 FOREIGN KEY([tenant_id],[original_id]) REFERENCES dbo.documents([tenant_id],[id]),
    CONSTRAINT FK_documents_4 FOREIGN KEY([signer_id]) REFERENCES dbo.users([id]),
    CONSTRAINT UQ_documents_1 UNIQUE ([tenant_id],[id])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.finance_movements (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [patient_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [kind] nvarchar(7) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [amount_minor] BIGINT NOT NULL,
    [currency] char(3) COLLATE Latin1_General_100_BIN2 NOT NULL CONSTRAINT DF_finance_movements_currency DEFAULT ('PEN'),
    [title] nvarchar(200) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [parent_id] char(36) COLLATE Latin1_General_100_BIN2 NULL,
    [actor_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [request_key] varchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [request_hash] char(64) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_finance_movements_created_at DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_finance_movements PRIMARY KEY ([id]),
    CONSTRAINT CK_finance_movements_kind_enum CHECK ([kind] IN ('CHARGE','PAYMENT','REFUND')),
    CONSTRAINT FK_finance_movements_1 FOREIGN KEY([tenant_id],[patient_id]) REFERENCES dbo.patients([tenant_id],[id]),
    CONSTRAINT FK_finance_movements_2 FOREIGN KEY([tenant_id],[parent_id]) REFERENCES dbo.finance_movements([tenant_id],[id]),
    CONSTRAINT FK_finance_movements_3 FOREIGN KEY([actor_id]) REFERENCES dbo.users([id]),
    CONSTRAINT CK_finance_movements_2 CHECK ([amount_minor]>0),
    CONSTRAINT UQ_finance_movements_1 UNIQUE ([tenant_id],[id]),
    CONSTRAINT UQ_finance_movements_2 UNIQUE ([tenant_id],[request_key])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.stock_lots (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [branch_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [name] nvarchar(160) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [lot] nvarchar(100) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [expiry] DATE NOT NULL,
    [quantity] DECIMAL(14,3) NOT NULL CONSTRAINT DF_stock_lots_quantity DEFAULT (0),
    [unit] nvarchar(30) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    CONSTRAINT PK_stock_lots PRIMARY KEY ([id]),
    CONSTRAINT FK_stock_lots_1 FOREIGN KEY([tenant_id],[branch_id]) REFERENCES dbo.branches([tenant_id],[id]),
    CONSTRAINT CK_stock_lots_1 CHECK ([quantity]>=0),
    CONSTRAINT UQ_stock_lots_1 UNIQUE ([tenant_id],[id]),
    CONSTRAINT UQ_stock_lots_2 UNIQUE ([tenant_id],[branch_id],[name],[lot],[expiry])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.stock_movements (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [lot_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [kind] nvarchar(8) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [quantity] DECIMAL(14,3) NOT NULL,
    [patient_id] char(36) COLLATE Latin1_General_100_BIN2 NULL,
    [prescription_id] char(36) COLLATE Latin1_General_100_BIN2 NULL,
    [actor_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [request_key] varchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [request_hash] char(64) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_stock_movements_created_at DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_stock_movements PRIMARY KEY ([id]),
    CONSTRAINT CK_stock_movements_kind_enum CHECK ([kind] IN ('RECEIVE','DISPENSE')),
    CONSTRAINT FK_stock_movements_1 FOREIGN KEY([tenant_id],[lot_id]) REFERENCES dbo.stock_lots([tenant_id],[id]),
    CONSTRAINT FK_stock_movements_2 FOREIGN KEY([tenant_id],[patient_id]) REFERENCES dbo.patients([tenant_id],[id]),
    CONSTRAINT FK_stock_movements_3 FOREIGN KEY([tenant_id],[prescription_id]) REFERENCES dbo.clinical_entries([tenant_id],[id]),
    CONSTRAINT FK_stock_movements_4 FOREIGN KEY([actor_id]) REFERENCES dbo.users([id]),
    CONSTRAINT CK_stock_movements_2 CHECK ([quantity]>0),
    CONSTRAINT UQ_stock_movements_1 UNIQUE ([tenant_id],[id]),
    CONSTRAINT UQ_stock_movements_2 UNIQUE ([tenant_id],[request_key])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.stock_transfers (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [lot_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [destination_branch_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [quantity] DECIMAL(14,3) NOT NULL,
    [status] nvarchar(10) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [request_key] varchar(100) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [request_hash] char(64) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_stock_transfers_created_at DEFAULT (SYSUTCDATETIME()),
    [received_at] datetime2(6) NULL,
    CONSTRAINT PK_stock_transfers PRIMARY KEY ([id]),
    CONSTRAINT CK_stock_transfers_status_enum CHECK ([status] IN ('IN_TRANSIT','RECEIVED')),
    CONSTRAINT FK_stock_transfers_1 FOREIGN KEY([tenant_id],[lot_id]) REFERENCES dbo.stock_lots([tenant_id],[id]),
    CONSTRAINT FK_stock_transfers_2 FOREIGN KEY([tenant_id],[destination_branch_id]) REFERENCES dbo.branches([tenant_id],[id]),
    CONSTRAINT CK_stock_transfers_2 CHECK ([quantity]>0),
    CONSTRAINT UQ_stock_transfers_1 UNIQUE ([tenant_id],[id]),
    CONSTRAINT UQ_stock_transfers_2 UNIQUE ([tenant_id],[request_key])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.hospital_resources (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [branch_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [name] nvarchar(100) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [kind] nvarchar(4) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [active] bit NOT NULL CONSTRAINT DF_hospital_resources_active DEFAULT (1),
    CONSTRAINT PK_hospital_resources PRIMARY KEY ([id]),
    CONSTRAINT CK_hospital_resources_kind_enum CHECK ([kind] IN ('BED','CAGE')),
    CONSTRAINT FK_hospital_resources_1 FOREIGN KEY([tenant_id],[branch_id]) REFERENCES dbo.branches([tenant_id],[id]),
    CONSTRAINT UQ_hospital_resources_1 UNIQUE ([tenant_id],[id]),
    CONSTRAINT UQ_hospital_resources_2 UNIQUE ([tenant_id],[branch_id],[name])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.admissions (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [patient_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [resource_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [status] nvarchar(10) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [reason] nvarchar(1000) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [revision] INT NOT NULL CONSTRAINT DF_admissions_revision DEFAULT (1),
    [admitted_at] datetime2(6) NOT NULL CONSTRAINT DF_admissions_admitted_at DEFAULT (SYSUTCDATETIME()),
    [discharged_at] datetime2(6) NULL,
    [occupied_resource] AS (CONVERT(char(36),CASE WHEN [status]='ADMITTED' THEN [resource_id] ELSE NULL END) COLLATE Latin1_General_100_BIN2) PERSISTED,
    [admitted_patient] AS (CONVERT(char(36),CASE WHEN [status]='ADMITTED' THEN [patient_id] ELSE NULL END) COLLATE Latin1_General_100_BIN2) PERSISTED,
    CONSTRAINT PK_admissions PRIMARY KEY ([id]),
    CONSTRAINT CK_admissions_status_enum CHECK ([status] IN ('ADMITTED','DISCHARGED')),
    CONSTRAINT FK_admissions_1 FOREIGN KEY([tenant_id],[patient_id]) REFERENCES dbo.patients([tenant_id],[id]),
    CONSTRAINT FK_admissions_2 FOREIGN KEY([tenant_id],[resource_id]) REFERENCES dbo.hospital_resources([tenant_id],[id]),
    CONSTRAINT UQ_admissions_1 UNIQUE ([tenant_id],[id])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.workflow_cases (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [branch_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [patient_id] char(36) COLLATE Latin1_General_100_BIN2 NULL,
    [type] nvarchar(60) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [status] nvarchar(40) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [title] nvarchar(200) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [payload] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [revision] INT NOT NULL CONSTRAINT DF_workflow_cases_revision DEFAULT (1),
    [actor_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_workflow_cases_created_at DEFAULT (SYSUTCDATETIME()),
    [updated_at] datetime2(6) NOT NULL CONSTRAINT DF_workflow_cases_updated_at DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_workflow_cases PRIMARY KEY ([id]),
    CONSTRAINT CK_workflow_cases_payload_json CHECK ([payload] IS NULL OR ISJSON([payload], VALUE)=1),
    CONSTRAINT FK_workflow_cases_1 FOREIGN KEY([tenant_id],[branch_id]) REFERENCES dbo.branches([tenant_id],[id]),
    CONSTRAINT FK_workflow_cases_2 FOREIGN KEY([tenant_id],[patient_id]) REFERENCES dbo.patients([tenant_id],[id]),
    CONSTRAINT FK_workflow_cases_3 FOREIGN KEY([actor_id]) REFERENCES dbo.users([id]),
    CONSTRAINT UQ_workflow_cases_1 UNIQUE ([tenant_id],[id])
 );
GO

-- Source: V1__schema.sql
CREATE TABLE dbo.workflow_history (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [case_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [revision] INT NOT NULL,
    [status] nvarchar(40) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [payload] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [actor_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_workflow_history_created_at DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_workflow_history PRIMARY KEY ([id]),
    CONSTRAINT CK_workflow_history_payload_json CHECK ([payload] IS NULL OR ISJSON([payload], VALUE)=1),
    CONSTRAINT FK_workflow_history_1 FOREIGN KEY([tenant_id],[case_id]) REFERENCES dbo.workflow_cases([tenant_id],[id]),
    CONSTRAINT FK_workflow_history_2 FOREIGN KEY([actor_id]) REFERENCES dbo.users([id]),
    CONSTRAINT UQ_workflow_history_1 UNIQUE ([tenant_id],[case_id],[revision])
 );
GO

-- Source: V4__operation_procedures.sql
CREATE TABLE dbo.workflow_definitions (
    [type] nvarchar(60) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [module] nvarchar(40) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [patient_required] bit NOT NULL,
    [animal_only] bit NOT NULL CONSTRAINT DF_workflow_definitions_animal_only DEFAULT (0),
    [creators] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [operators] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [readers] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [transitions] nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,
    CONSTRAINT PK_workflow_definitions PRIMARY KEY ([type]),
    CONSTRAINT CK_workflow_definitions_creators_json CHECK ([creators] IS NULL OR ISJSON([creators], VALUE)=1),
    CONSTRAINT CK_workflow_definitions_operators_json CHECK ([operators] IS NULL OR ISJSON([operators], VALUE)=1),
    CONSTRAINT CK_workflow_definitions_readers_json CHECK ([readers] IS NULL OR ISJSON([readers], VALUE)=1),
    CONSTRAINT CK_workflow_definitions_transitions_json CHECK ([transitions] IS NULL OR ISJSON([transitions], VALUE)=1)
 );
GO

-- Source: V9__identity_trace_support_and_monitor.sql
CREATE TABLE dbo.request_traces (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NULL,
    [actor_id] char(36) COLLATE Latin1_General_100_BIN2 NULL,
    [method] nvarchar(10) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [route] nvarchar(250) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [status] INT NOT NULL,
    [duration_ms] BIGINT NOT NULL,
    [source_ip] nvarchar(80) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [user_agent] nvarchar(300) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_request_traces_created_at DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_request_traces PRIMARY KEY ([id])
 );
GO

-- Source: V9__identity_trace_support_and_monitor.sql
CREATE TABLE dbo.identity_tokens (
    [token_hash] char(64) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [user_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NULL,
    [purpose] nvarchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [expires_at] datetime2(6) NOT NULL,
    [used_at] datetime2(6) NULL,
    CONSTRAINT PK_identity_tokens PRIMARY KEY ([token_hash]),
    CONSTRAINT CK_identity_tokens_purpose_enum CHECK ([purpose] IN ('VERIFY','RESET')),
    CONSTRAINT FK_identity_tokens_1 FOREIGN KEY([user_id]) REFERENCES dbo.users([id]),
    CONSTRAINT FK_identity_tokens_2 FOREIGN KEY([tenant_id]) REFERENCES dbo.tenants([id])
 );
GO

-- Source: V9__identity_trace_support_and_monitor.sql
CREATE TABLE dbo.mail_outbox (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [recipient] nvarchar(254) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [subject] nvarchar(200) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [body] nvarchar(max) NOT NULL,
    [status] nvarchar(7) COLLATE Latin1_General_100_BIN2 NOT NULL CONSTRAINT DF_mail_outbox_status DEFAULT ('PENDING'),
    [attempts] INT NOT NULL CONSTRAINT DF_mail_outbox_attempts DEFAULT (0),
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_mail_outbox_created_at DEFAULT (SYSUTCDATETIME()),
    [sent_at] datetime2(6) NULL,
    [retry_at] datetime2(6) NULL,
    CONSTRAINT PK_mail_outbox PRIMARY KEY ([id]),
    CONSTRAINT CK_mail_outbox_status_enum CHECK ([status] IN ('PENDING','SENDING','SENT','FAILED'))
 );
GO

-- Source: V9__identity_trace_support_and_monitor.sql
CREATE TABLE dbo.support_tickets (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [tenant_id] char(36) COLLATE Latin1_General_100_BIN2 NULL,
    [actor_id] char(36) COLLATE Latin1_General_100_BIN2 NULL,
    [reference] nvarchar(30) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [email] nvarchar(254) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [subject] nvarchar(180) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [message] nvarchar(max) NOT NULL,
    [status] nvarchar(12) COLLATE Latin1_General_100_BIN2 NOT NULL CONSTRAINT DF_support_tickets_status DEFAULT ('OPEN'),
    [priority] nvarchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [revision] INT NOT NULL CONSTRAINT DF_support_tickets_revision DEFAULT (1),
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_support_tickets_created_at DEFAULT (SYSUTCDATETIME()),
    [updated_at] datetime2(6) NOT NULL CONSTRAINT DF_support_tickets_updated_at DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_support_tickets PRIMARY KEY ([id]),
    CONSTRAINT CK_support_tickets_status_enum CHECK ([status] IN ('OPEN','IN_PROGRESS','WAITING_USER','RESOLVED','CLOSED')),
    CONSTRAINT CK_support_tickets_priority_enum CHECK ([priority] IN ('LOW','NORMAL','HIGH','URGENT')),
    CONSTRAINT UQ_support_tickets_1 UNIQUE ([reference])
 );
GO

-- Source: V9__identity_trace_support_and_monitor.sql
CREATE TABLE dbo.support_comments (
    [id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [ticket_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [actor_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [message] nvarchar(max) NOT NULL,
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_support_comments_created_at DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_support_comments PRIMARY KEY ([id]),
    CONSTRAINT FK_support_comments_1 FOREIGN KEY([ticket_id]) REFERENCES dbo.support_tickets([id])
 );
GO

-- Source: V9__identity_trace_support_and_monitor.sql
CREATE TABLE dbo.application_state (
    [id] INT NOT NULL,
    [mode] nvarchar(11) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [message] nvarchar(300) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [revision] INT NOT NULL CONSTRAINT DF_application_state_revision DEFAULT (1),
    CONSTRAINT PK_application_state PRIMARY KEY ([id]),
    CONSTRAINT CK_application_state_mode_enum CHECK ([mode] IN ('OPEN','READ_ONLY','MAINTENANCE'))
 );
GO

-- Source: V9__identity_trace_support_and_monitor.sql
CREATE TABLE dbo.health_samples (
    [id] BIGINT IDENTITY(1,1) NOT NULL,
    [instance_id] char(36) COLLATE Latin1_General_100_BIN2 NOT NULL,
    [db_status] nvarchar(20) COLLATE Latin1_General_100_CI_AI_SC NOT NULL,
    [db_latency_ms] BIGINT NOT NULL,
    [memory_used] BIGINT NOT NULL,
    [memory_max] BIGINT NOT NULL,
    [uptime_ms] BIGINT NOT NULL,
    [created_at] datetime2(6) NOT NULL CONSTRAINT DF_health_samples_created_at DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_health_samples PRIMARY KEY ([id])
 );
GO

-- Filtered unique indexes preserve multiple historical finalized/discharged rows.
CREATE INDEX IX_auth_sessions_1 ON dbo.auth_sessions([expires_at]);
CREATE INDEX IX_audit_events_2 ON dbo.audit_events([tenant_id],[id]);
CREATE INDEX IX_audit_events_3 ON dbo.audit_events([request_id]);
CREATE INDEX IX_audit_events_4 ON dbo.audit_events([tenant_id],[created_at]);
CREATE INDEX IX_appointments_5 ON dbo.appointments([professional_id],[starts_at],[ends_at]);
CREATE UNIQUE INDEX UX_encounters_active_patient ON dbo.encounters([tenant_id],[patient_id]) WHERE [status] <> 'FINALIZED';
CREATE UNIQUE INDEX UX_admissions_occupied_resource ON dbo.admissions([tenant_id],[resource_id]) WHERE [status] = 'ADMITTED';
CREATE UNIQUE INDEX UX_admissions_admitted_patient ON dbo.admissions([tenant_id],[patient_id]) WHERE [status] = 'ADMITTED';
CREATE INDEX IX_request_traces_9 ON dbo.request_traces([tenant_id],[created_at]);
CREATE INDEX IX_request_traces_10 ON dbo.request_traces([actor_id],[created_at]);
CREATE INDEX IX_request_traces_11 ON dbo.request_traces([status],[created_at]);
CREATE INDEX IX_identity_tokens_12 ON dbo.identity_tokens([user_id],[purpose]);
CREATE INDEX IX_support_tickets_13 ON dbo.support_tickets([tenant_id],[created_at]);
CREATE INDEX IX_health_samples_14 ON dbo.health_samples([created_at]);
GO

-- SQL Server does not automatically index referencing foreign-key columns.
CREATE INDEX IX_fk_tenants_1 ON dbo.tenants([owner_user_id]);
CREATE INDEX IX_fk_subscriptions_2 ON dbo.subscriptions([plan_id],[plan_version]);
CREATE INDEX IX_fk_tenant_specialties_2 ON dbo.tenant_specialties([specialty_code]);
CREATE INDEX IX_fk_memberships_2 ON dbo.memberships([user_id]);
CREATE INDEX IX_fk_membership_branches_2 ON dbo.membership_branches([tenant_id],[branch_id]);
CREATE INDEX IX_fk_membership_specialties_2 ON dbo.membership_specialties([tenant_id],[specialty_code]);
CREATE INDEX IX_fk_auth_sessions_1 ON dbo.auth_sessions([user_id]);
CREATE INDEX IX_fk_auth_sessions_2 ON dbo.auth_sessions([tenant_id]);
CREATE INDEX IX_fk_audit_events_2 ON dbo.audit_events([actor_id]);
CREATE INDEX IX_fk_patient_links_2 ON dbo.patient_links([user_id]);
CREATE INDEX IX_fk_appointments_1 ON dbo.appointments([tenant_id],[patient_id]);
CREATE INDEX IX_fk_appointments_2 ON dbo.appointments([tenant_id],[branch_id]);
CREATE INDEX IX_fk_appointments_3 ON dbo.appointments([tenant_id],[professional_id]);
CREATE INDEX IX_fk_appointments_4 ON dbo.appointments([tenant_id],[specialty_code]);
CREATE INDEX IX_fk_encounters_2 ON dbo.encounters([tenant_id],[branch_id]);
CREATE INDEX IX_fk_encounters_3 ON dbo.encounters([tenant_id],[professional_id]);
CREATE INDEX IX_fk_encounters_4 ON dbo.encounters([tenant_id],[specialty_code]);
CREATE INDEX IX_fk_clinical_entries_1 ON dbo.clinical_entries([tenant_id],[encounter_id]);
CREATE INDEX IX_fk_clinical_entries_2 ON dbo.clinical_entries([actor_id]);
CREATE INDEX IX_fk_documents_1 ON dbo.documents([tenant_id],[patient_id]);
CREATE INDEX IX_fk_documents_2 ON dbo.documents([tenant_id],[encounter_id]);
CREATE INDEX IX_fk_documents_3 ON dbo.documents([tenant_id],[original_id]);
CREATE INDEX IX_fk_documents_4 ON dbo.documents([signer_id]);
CREATE INDEX IX_fk_finance_movements_1 ON dbo.finance_movements([tenant_id],[patient_id]);
CREATE INDEX IX_fk_finance_movements_2 ON dbo.finance_movements([tenant_id],[parent_id]);
CREATE INDEX IX_fk_finance_movements_3 ON dbo.finance_movements([actor_id]);
CREATE INDEX IX_fk_stock_movements_1 ON dbo.stock_movements([tenant_id],[lot_id]);
CREATE INDEX IX_fk_stock_movements_2 ON dbo.stock_movements([tenant_id],[patient_id]);
CREATE INDEX IX_fk_stock_movements_3 ON dbo.stock_movements([tenant_id],[prescription_id]);
CREATE INDEX IX_fk_stock_movements_4 ON dbo.stock_movements([actor_id]);
CREATE INDEX IX_fk_stock_transfers_1 ON dbo.stock_transfers([tenant_id],[lot_id]);
CREATE INDEX IX_fk_stock_transfers_2 ON dbo.stock_transfers([tenant_id],[destination_branch_id]);
CREATE INDEX IX_fk_workflow_cases_1 ON dbo.workflow_cases([tenant_id],[branch_id]);
CREATE INDEX IX_fk_workflow_cases_2 ON dbo.workflow_cases([tenant_id],[patient_id]);
CREATE INDEX IX_fk_workflow_cases_3 ON dbo.workflow_cases([actor_id]);
CREATE INDEX IX_fk_workflow_history_2 ON dbo.workflow_history([actor_id]);
CREATE INDEX IX_fk_identity_tokens_2 ON dbo.identity_tokens([tenant_id]);
CREATE INDEX IX_fk_support_comments_1 ON dbo.support_comments([ticket_id]);
GO
