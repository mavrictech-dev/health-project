-- SQL-01.A7 / D-15 and D-15.A. SQL Server2022; EXTERNAL migration transaction required.
-- 133 SP:107 runtime entries,2 bootstrap-only entries,24 private helpers.
-- request_context is shared: runtime107 grants/26 denies; bootstrap3 grants/130 denies.
-- Both roles:37 business objects x4 DML DENYs=148 object permissions each. Total562.
-- D-15.C/D optional history:8 CRUD DENYs + runtime object VIEW DEFINITION, total571.
-- No login, persistent user, fixed role membership, schema/database GRANT or dynamic SQL.
-- Preconditions precede ALL mutations; existing roles are rejected, never repurposed.
-- D-15.A is the ONLY SP evolution:2 literal ALTERs append the role alternative to
-- the bootstrap elevation guard. V3 files remain immutable; all other bodies identical.
-- Runtime DB role is a trusted SERVER adapter capability, not an HTTP identity.
-- Java bootstrap must later move to the separate bootstrap connection/principal.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
IF @@TRANCOUNT=0 THROW 51000,N'HP_INVALID:External migration transaction required',1;
IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),'DATABASE','CONTROL'),0)<>1 THROW 51001,N'HP_FORBIDDEN:Separate administrative migration principal required',1;
IF DATABASE_PRINCIPAL_ID(N'hp_runtime_executor') IS NOT NULL OR DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor') IS NOT NULL
 THROW 51003,N'HP_CONFLICT:Execution roles already exist; no existing permissions were changed',1;
IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE name=N'dbo' AND principal_id=DATABASE_PRINCIPAL_ID(N'dbo'))
 THROW 51000,N'HP_INVALID:dbo schema missing',1;
IF EXISTS(SELECT 1 FROM sys.database_permissions WHERE grantee_principal_id=DATABASE_PRINCIPAL_ID(N'public') AND state IN ('G','W')
 AND ((class=0 AND permission_name NOT IN ('CONNECT','VIEW ANY COLUMN ENCRYPTION KEY DEFINITION','VIEW ANY COLUMN MASTER KEY DEFINITION'))
 OR (class=3 AND major_id=SCHEMA_ID(N'dbo'))
 OR (class=1 AND OBJECT_SCHEMA_NAME(major_id)=N'dbo')))
 THROW 51000,N'HP_INVALID:Incompatible broad public permissions; migration will not change them',1;
DECLARE @procedures TABLE(name sysname PRIMARY KEY,access_class varchar(10) NOT NULL);
INSERT @procedures(name,access_class) VALUES
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
 (N'usp_workflow_step',N'runtime');
IF EXISTS(SELECT 1 FROM @procedures x WHERE OBJECT_ID(N'dbo.'+x.name,N'P') IS NULL)
 OR (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo'))<>133
 THROW 51000,N'HP_INVALID:Expected exactly the approved133 dbo procedures',1;
IF EXISTS(SELECT 1 FROM sys.procedures p WHERE p.schema_id=SCHEMA_ID(N'dbo') AND p.principal_id IS NOT NULL AND p.principal_id<>DATABASE_PRINCIPAL_ID(N'dbo'))
 THROW 51000,N'HP_INVALID:Incompatible procedure ownership chain',1;
DECLARE @tables TABLE(name sysname PRIMARY KEY);
INSERT @tables(name) VALUES
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
-- D-15.C: exactly the named37 business tables, plus ONLY optional migrator history.
-- This is a closed set, not a lower bound on table count; V8 never creates history.
IF EXISTS(SELECT 1 FROM @tables x WHERE OBJECT_ID(N'dbo.'+x.name,N'U') IS NULL)
 OR EXISTS(SELECT 1 FROM sys.tables t LEFT JOIN @tables x ON x.name=t.name
  WHERE t.schema_id=SCHEMA_ID(N'dbo') AND x.name IS NULL AND t.name<>N'flyway_schema_history')
 OR (OBJECT_ID(N'dbo.flyway_schema_history') IS NOT NULL AND OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NULL)
 THROW 51000,N'HP_INVALID:Expected37 approved business tables and only optional flyway_schema_history',1;
IF EXISTS(SELECT 1 FROM sys.tables t WHERE t.schema_id=SCHEMA_ID(N'dbo') AND t.principal_id IS NOT NULL AND t.principal_id<>DATABASE_PRINCIPAL_ID(N'dbo'))
 THROW 51000,N'HP_INVALID:Incompatible table ownership chain',1;
DECLARE @triggers TABLE(name sysname PRIMARY KEY,parent_name sysname NOT NULL);
INSERT @triggers VALUES
 (N'trace_users_change',N'users'),
 (N'trace_plans_change',N'plans'),
 (N'trace_plan_versions_change',N'plan_versions'),
 (N'trace_tenants_change',N'tenants'),
 (N'trace_subscriptions_change',N'subscriptions'),
 (N'trace_tenant_specialties_change',N'tenant_specialties'),
 (N'trace_branches_change',N'branches'),
 (N'trace_areas_change',N'areas'),
 (N'trace_memberships_change',N'memberships'),
 (N'trace_membership_branches_change',N'membership_branches'),
 (N'trace_membership_specialties_change',N'membership_specialties'),
 (N'trace_patients_change',N'patients'),
 (N'trace_patient_links_change',N'patient_links'),
 (N'trace_appointments_change',N'appointments'),
 (N'trace_encounters_change',N'encounters'),
 (N'trace_clinical_entries_change',N'clinical_entries'),
 (N'trace_documents_change',N'documents'),
 (N'trace_finance_movements_change',N'finance_movements'),
 (N'trace_saas_invoices_change',N'saas_invoices'),
 (N'trace_stock_lots_change',N'stock_lots'),
 (N'trace_stock_movements_change',N'stock_movements'),
 (N'trace_stock_transfers_change',N'stock_transfers'),
 (N'trace_hospital_resources_change',N'hospital_resources'),
 (N'trace_admissions_change',N'admissions'),
 (N'trace_workflow_cases_change',N'workflow_cases'),
 (N'trace_workflow_history_change',N'workflow_history'),
 (N'trace_support_tickets_change',N'support_tickets'),
 (N'trace_support_comments_change',N'support_comments'),
 (N'trace_application_state_change',N'application_state'),
 (N'audit_no_update',N'audit_events'),
 (N'audit_no_delete',N'audit_events');
IF EXISTS(SELECT 1 FROM @triggers x LEFT JOIN sys.triggers t ON t.object_id=OBJECT_ID(N'dbo.'+x.name,N'TR') WHERE t.object_id IS NULL OR t.parent_id<>OBJECT_ID(N'dbo.'+x.parent_name,N'U') OR t.is_disabled<>0)
 OR (SELECT COUNT(*) FROM sys.triggers WHERE parent_class=1)<>31
 OR EXISTS(SELECT 1 FROM sys.objects WHERE type='TR' AND principal_id IS NOT NULL AND principal_id<>DATABASE_PRINCIPAL_ID(N'dbo'))
 THROW 51000,N'HP_INVALID:Expected31 enabled audit triggers with dbo ownership chain',1;
-- Fail before changes if the immutable V3 bootstrap contract has drifted.
IF OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_bootstrap_create')) IS NULL OR TRIM(N' '+NCHAR(9)+NCHAR(10)+NCHAR(13) FROM REPLACE(SUBSTRING(OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_bootstrap_create')),CHARINDEX(N'CREATE PROCEDURE dbo.usp_bootstrap_create',OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_bootstrap_create')) COLLATE Latin1_General_100_BIN2),2147483647),NCHAR(13),N'')) COLLATE Latin1_General_100_BIN2
 <> REPLACE(N'CREATE PROCEDURE dbo.usp_bootstrap_create @id char(36),@email nvarchar(254),@password_hash nvarchar(100)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_transaction; EXEC dbo.usp_require_scope ''BOOTSTRAP''; IF ISNULL(IS_ROLEMEMBER(N''db_owner''),0)<>1 AND ISNULL(IS_SRVROLEMEMBER(N''sysadmin''),0)<>1 THROW 51001,''HP_FORBIDDEN:Separate elevated setup principal required'',1; IF EXISTS(SELECT 1 FROM dbo.users WITH(UPDLOCK,HOLDLOCK) WHERE platform_role=''SAD'') RETURN; IF NULLIF(@email,N'''') IS NULL OR NULLIF(@password_hash,N'''') IS NULL THROW 51000,''HP_INVALID:Bootstrap fields'',1; INSERT dbo.users(id,name,email,password_hash,platform_role,email_verified) VALUES(@id,N''Administrador general'',LOWER(@email),@password_hash,''SAD'',1);
END;',NCHAR(13),N'') COLLATE Latin1_General_100_BIN2
 THROW 51000,N'HP_INVALID:Unexpected bootstrap definition',1;
-- Fail before changes if the immutable V3 bootstrap contract has drifted.
IF OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_bootstrap_exists')) IS NULL OR TRIM(N' '+NCHAR(9)+NCHAR(10)+NCHAR(13) FROM REPLACE(SUBSTRING(OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_bootstrap_exists')),CHARINDEX(N'CREATE PROCEDURE dbo.usp_bootstrap_exists',OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_bootstrap_exists')) COLLATE Latin1_General_100_BIN2),2147483647),NCHAR(13),N'')) COLLATE Latin1_General_100_BIN2
 <> REPLACE(N'CREATE PROCEDURE dbo.usp_bootstrap_exists
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope ''BOOTSTRAP''; IF ISNULL(IS_ROLEMEMBER(N''db_owner''),0)<>1 AND ISNULL(IS_SRVROLEMEMBER(N''sysadmin''),0)<>1 THROW 51001,''HP_FORBIDDEN:Separate elevated setup principal required'',1; SELECT TOP(1) id FROM dbo.users WHERE platform_role=''SAD'' ORDER BY id;
END;',NCHAR(13),N'') COLLATE Latin1_General_100_BIN2
 THROW 51000,N'HP_INVALID:Unexpected bootstrap definition',1;
CREATE ROLE hp_runtime_executor AUTHORIZATION dbo;
CREATE ROLE hp_bootstrap_executor AUTHORIZATION dbo;

-- usp_request_context | runtime | Runtime + bootstrap: trusted connection context replacement; never HTTP body role selection
GRANT EXECUTE ON OBJECT::dbo.usp_request_context TO hp_runtime_executor;
GRANT EXECUTE ON OBJECT::dbo.usp_request_context TO hp_bootstrap_executor;

-- usp_require_transaction | private | Internal external-transaction guard
DENY EXECUTE ON OBJECT::dbo.usp_require_transaction TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_require_transaction TO hp_bootstrap_executor;

-- usp_require_actor | private | Internal membership/session/platform authorization
DENY EXECUTE ON OBJECT::dbo.usp_require_actor TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_require_actor TO hp_bootstrap_executor;

-- usp_require_scope | private | Internal trusted adapter scope guard
DENY EXECUTE ON OBJECT::dbo.usp_require_scope TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_require_scope TO hp_bootstrap_executor;

-- usp_write_guard | private | Internal application/tenant/module write guard
DENY EXECUTE ON OBJECT::dbo.usp_write_guard TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_write_guard TO hp_bootstrap_executor;

-- usp_audit_event | private | Internal scalar safe audit writer
DENY EXECUTE ON OBJECT::dbo.usp_audit_event TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_audit_event TO hp_bootstrap_executor;

-- usp_tenant_by_slug | runtime | HostFilter.doFilter: host resolution, public. RS id/name/slug/kind/domain/status/modules JSON.
GRANT EXECUTE ON OBJECT::dbo.usp_tenant_by_slug TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_tenant_by_slug TO hp_bootstrap_executor;

-- usp_registration_plans | runtime | AccountLifecycleService.options: public published offers, JSON remains text.
GRANT EXECUTE ON OBJECT::dbo.usp_registration_plans TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_registration_plans TO hp_bootstrap_executor;

-- usp_registration_specialties | runtime | AccountLifecycleService.options: public specialty catalog; RS code/name/domain/dental BIT.
GRANT EXECUTE ON OBJECT::dbo.usp_registration_specialties TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_registration_specialties TO hp_bootstrap_executor;

-- usp_registration_plan | runtime | AccountLifecycleService.register: published plan defaults; tenant creation belongs to SaaS package.
GRANT EXECUTE ON OBJECT::dbo.usp_registration_plan TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_registration_plan TO hp_bootstrap_executor;

-- usp_identity_credentials | runtime | INTERNAL credential result only: IdentityService.login/accept; never serialize password_hash to HTTP.
GRANT EXECUTE ON OBJECT::dbo.usp_identity_credentials TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_identity_credentials TO hp_bootstrap_executor;

-- usp_identity_account_lookup | runtime | AccountLifecycleService.request: internal eligibility lookup; no credential hash.
GRANT EXECUTE ON OBJECT::dbo.usp_identity_account_lookup TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_identity_account_lookup TO hp_bootstrap_executor;

-- usp_identity_email_exists | runtime | AccountLifecycleService.register: optional id, including inactive identities; avoid duplicate enrollment.
GRANT EXECUTE ON OBJECT::dbo.usp_identity_email_exists TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_identity_email_exists TO hp_bootstrap_executor;

-- usp_identity_membership | runtime | IdentityService.login, SessionFilter, AccountLifecycleService.request: host-scoped membership roles JSON.
GRANT EXECUTE ON OBJECT::dbo.usp_identity_membership TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_identity_membership TO hp_bootstrap_executor;

-- usp_user_create | runtime | IdentityService.create / V2 sp_user_create; public registration invokes identity_pending in the same transaction; administrative provisioning keeps historical verified default.
GRANT EXECUTE ON OBJECT::dbo.usp_user_create TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_user_create TO hp_bootstrap_executor;

-- usp_bootstrap_exists | bootstrap | Bootstrap.run ONLY separate role; D-15.A scoped role guard, never runtime
DENY EXECUTE ON OBJECT::dbo.usp_bootstrap_exists TO hp_runtime_executor;
GRANT EXECUTE ON OBJECT::dbo.usp_bootstrap_exists TO hp_bootstrap_executor;

-- usp_bootstrap_create | bootstrap | Bootstrap.run ONLY separate role; D-15.A scoped role guard, never runtime
DENY EXECUTE ON OBJECT::dbo.usp_bootstrap_create TO hp_runtime_executor;
GRANT EXECUTE ON OBJECT::dbo.usp_bootstrap_create TO hp_bootstrap_executor;

-- usp_identity_pending | runtime | AccountLifecycleService.register / V9 sp_identity_pending.
GRANT EXECUTE ON OBJECT::dbo.usp_identity_pending TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_identity_pending TO hp_bootstrap_executor;

-- usp_identity_password_hash | runtime | IdentityService.password: INTERNAL own credential verification only.
GRANT EXECUTE ON OBJECT::dbo.usp_identity_password_hash TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_identity_password_hash TO hp_bootstrap_executor;

-- usp_password_change | runtime | IdentityService.password / V2 sp_password_change: revoke every session atomically, never audit hash.
GRANT EXECUTE ON OBJECT::dbo.usp_password_change TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_password_change TO hp_bootstrap_executor;

-- usp_session_resolve | runtime | SessionFilter: internal token-bound host/session lookup. CSRF is internal until browser session endpoint.
GRANT EXECUTE ON OBJECT::dbo.usp_session_resolve TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_session_resolve TO hp_bootstrap_executor;

-- usp_session_save | runtime | IdentityService.login + BrowserSessionController.login; password verified by Spring before trusted IDENTITY call. RS csrf_token/expires_at replaces post-login SELECT.
GRANT EXECUTE ON OBJECT::dbo.usp_session_save TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_session_save TO hp_bootstrap_executor;

-- usp_session_current | runtime | BrowserSessionController.current: own CSRF/expiry only.
GRANT EXECUTE ON OBJECT::dbo.usp_session_current TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_session_current TO hp_bootstrap_executor;

-- usp_sessions_list | runtime | BrowserSessionController.sessions: SHA256 of stored ASCII token hash, never returns token_hash.
GRANT EXECUTE ON OBJECT::dbo.usp_sessions_list TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_sessions_list TO hp_bootstrap_executor;

-- usp_session_revoke | runtime | IdentityService.logout + BrowserSessionController.revoke; own opaque session id, no hash lookup escape.
GRANT EXECUTE ON OBJECT::dbo.usp_session_revoke TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_session_revoke TO hp_bootstrap_executor;

-- usp_session_touch | runtime | SessionFilter / V9 sp_session_touch: throttle own session touch.
GRANT EXECUTE ON OBJECT::dbo.usp_session_touch TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_session_touch TO hp_bootstrap_executor;

-- usp_login_failure | runtime | AttemptRecorder.failed / V11: independent Spring REQUIRES_NEW, anonymous actor and safe attempted account target.
GRANT EXECUTE ON OBJECT::dbo.usp_login_failure TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_login_failure TO hp_bootstrap_executor;

-- usp_identity_issue | runtime | AccountLifecycleService.issue / V9: atomic token invalidation + outbox. Recipient is server account email; optional registration_tenant must be newly enrolled owner membership on platform host. Content MAX, no audit body/token.
GRANT EXECUTE ON OBJECT::dbo.usp_identity_issue TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_identity_issue TO hp_bootstrap_executor;

-- usp_identity_redeem | runtime | AccountLifecycleService.redeem / V9: user then token lock order matches issue; one-use, host-bound; reset revokes all sessions.
GRANT EXECUTE ON OBJECT::dbo.usp_identity_redeem TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_identity_redeem TO hp_bootstrap_executor;

-- usp_portal_register | runtime | AccountLifecycleService.register / V9: no patient links or clinical access invented.
GRANT EXECUTE ON OBJECT::dbo.usp_portal_register TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_portal_register TO hp_bootstrap_executor;

-- usp_invitation_accept | runtime | IdentityService.accept / V2: Spring must verify supplied password before trusted IDENTITY operation.
GRANT EXECUTE ON OBJECT::dbo.usp_invitation_accept TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_invitation_accept TO hp_bootstrap_executor;

-- usp_access_branch | runtime | Access.branch: replaces both branch and membership SELECTs, returns optional id/branch_id, platform never bypasses.
GRANT EXECUTE ON OBJECT::dbo.usp_access_branch TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_access_branch TO hp_bootstrap_executor;

-- usp_access_patient_link | runtime | Access.link: scoped optional patient_id only; no histories returned.
GRANT EXECUTE ON OBJECT::dbo.usp_access_patient_link TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_access_patient_link TO hp_bootstrap_executor;

-- usp_mail_claim | runtime | MailDelivery.deliver: claim atomically, commit before SMTP. SENDING is NEVER automatically reclaimed; no exactly-once promise.
GRANT EXECUTE ON OBJECT::dbo.usp_mail_claim TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_mail_claim TO hp_bootstrap_executor;

-- usp_mail_complete | runtime | MailDelivery.deliver / replaces sp_mail_status: REJECTED only definite pre-acceptance rejection; unknown SMTP outcome stays SENDING for manual reconciliation.
GRANT EXECUTE ON OBJECT::dbo.usp_mail_complete TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_mail_complete TO hp_bootstrap_executor;

-- usp_health_ready | runtime | MonitorService.sample/details, future Hikari/Actuator probe: constant query is inside SP, never Java SQL.
GRANT EXECUTE ON OBJECT::dbo.usp_health_ready TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_health_ready TO hp_bootstrap_executor;

-- usp_application_status | runtime | SessionFilter write gate + MonitorService.status public view, no identities/secrets.
GRANT EXECUTE ON OBJECT::dbo.usp_application_status TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_application_status TO hp_bootstrap_executor;

-- usp_application_mode | runtime | MonitorService.mode / V9 sp_application_mode: SAD only, works during maintenance, revision conflict.
GRANT EXECUTE ON OBJECT::dbo.usp_application_mode TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_application_mode TO hp_bootstrap_executor;

-- usp_health_sample | runtime | MonitorService.sample / V9 sp_health_sample: worker sample and 7-day retention in caller transaction.
GRANT EXECUTE ON OBJECT::dbo.usp_health_sample TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_health_sample TO hp_bootstrap_executor;

-- usp_monitor_samples | runtime | MonitorService.details.samples: platform only, exact health fields.
GRANT EXECUTE ON OBJECT::dbo.usp_monitor_samples TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_monitor_samples TO hp_bootstrap_executor;

-- usp_monitor_mail | runtime | MonitorService.details.mail: aggregated counts only, no recipients or content.
GRANT EXECUTE ON OBJECT::dbo.usp_monitor_mail TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_monitor_mail TO hp_bootstrap_executor;

-- usp_monitor_requests | runtime | MonitorService.details.requests: platform aggregate or current tenant only.
GRANT EXECUTE ON OBJECT::dbo.usp_monitor_requests TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_monitor_requests TO hp_bootstrap_executor;

-- usp_monitor_migrations | runtime | MonitorService.details.migrations: Flyway-owned history table, deferred resolution until Flyway runtime package.
GRANT EXECUTE ON OBJECT::dbo.usp_monitor_migrations TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_monitor_migrations TO hp_bootstrap_executor;

-- usp_request_finish | runtime | TraceFilter.finally / V9 sp_request_finish: server status/duration, all identity/correlation from replaced context.
GRANT EXECUTE ON OBJECT::dbo.usp_request_finish TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_request_finish TO hp_bootstrap_executor;

-- usp_audit_list | runtime | AuditService.list: tenant legacy audit list, no global tenant bypass.
GRANT EXECUTE ON OBJECT::dbo.usp_audit_list TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_audit_list TO hp_bootstrap_executor;

-- usp_trace_events | runtime | AuditService.events: returns limit+1 rows, caller preserves hasMore/nextCursor exactly; no interpolated filters.
GRANT EXECUTE ON OBJECT::dbo.usp_trace_events TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_trace_events TO hp_bootstrap_executor;

-- usp_trace_requests | runtime | AuditService.requests: all trace columns plus actor_name, status lower bound and search.
GRANT EXECUTE ON OBJECT::dbo.usp_trace_requests TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_trace_requests TO hp_bootstrap_executor;

-- usp_trace_journey | runtime | AuditService.journey: result set 1 request, result set 2 up to201 event rows; caller keeps first200 as existing HTTP contract.
GRANT EXECUTE ON OBJECT::dbo.usp_trace_journey TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_trace_journey TO hp_bootstrap_executor;

-- usp_support_list | runtime | SupportController.list: platform200 or current tenant/current author100, no ticket ids from other tenants.
GRANT EXECUTE ON OBJECT::dbo.usp_support_list TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_support_list TO hp_bootstrap_executor;

-- usp_require_support_ticket | private | Internal support ownership guard
DENY EXECUTE ON OBJECT::dbo.usp_require_support_ticket TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_require_support_ticket TO hp_bootstrap_executor;

-- usp_support_detail | runtime | SupportController.get: result set1 ticket and result set2 comments; MAX messages preserved.
GRANT EXECUTE ON OBJECT::dbo.usp_support_detail TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_support_detail TO hp_bootstrap_executor;

-- usp_support_create | runtime | SupportController.create public / V9: preserve anonymous support in maintenance; no request body tenant/actor trusted.
GRANT EXECUTE ON OBJECT::dbo.usp_support_create TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_support_create TO hp_bootstrap_executor;

-- usp_support_step | runtime | SupportController.step / V9: expectedRevision and state transitions, tenant only own comments, platform technical status edit. Returns detail+comments.
GRANT EXECUTE ON OBJECT::dbo.usp_support_step TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_support_step TO hp_bootstrap_executor;

-- usp_audit_change | private | Internal safe before/after audit writer
DENY EXECUTE ON OBJECT::dbo.usp_audit_change TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_audit_change TO hp_bootstrap_executor;

-- usp_org_json_object | private | Internal DTO object validator
DENY EXECUTE ON OBJECT::dbo.usp_org_json_object TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_org_json_object TO hp_bootstrap_executor;

-- usp_org_json_strings | private | Internal DTO array validator
DENY EXECUTE ON OBJECT::dbo.usp_org_json_strings TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_org_json_strings TO hp_bootstrap_executor;

-- usp_saas_write_gate | private | Internal global OPEN write guard
DENY EXECUTE ON OBJECT::dbo.usp_saas_write_gate TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_saas_write_gate TO hp_bootstrap_executor;

-- usp_org_target | private | Internal SAD/ADM target authorization
DENY EXECUTE ON OBJECT::dbo.usp_org_target TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_org_target TO hp_bootstrap_executor;

-- usp_platform_plans | runtime | PlatformService.plans/plan result: all plan/current-version columns explicitly, optional id existence/read.
GRANT EXECUTE ON OBJECT::dbo.usp_platform_plans TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_platform_plans TO hp_bootstrap_executor;

-- usp_platform_tenants | runtime | PlatformService.tenants/tenant/create/status: explicit TENANT_QUERY. Java retains hostname/url construction from trusted Settings.
GRANT EXECUTE ON OBJECT::dbo.usp_platform_tenants TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_platform_tenants TO hp_bootstrap_executor;

-- usp_platform_users | runtime | PlatformService.users/createUser and active owner resolution (caller checks active). Credential hashes never returned; identity creation remains V3 user_create inside caller transaction.
GRANT EXECUTE ON OBJECT::dbo.usp_platform_users TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_platform_users TO hp_bootstrap_executor;

-- usp_platform_specialties | runtime | PlatformService.specialties: full profiles, no truncation or invented paging.
GRANT EXECUTE ON OBJECT::dbo.usp_platform_specialties TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_platform_specialties TO hp_bootstrap_executor;

-- usp_platform_audit | runtime | PlatformService.audit: same administrative actions only, SAD only.
GRANT EXECUTE ON OBJECT::dbo.usp_platform_audit TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_platform_audit TO hp_bootstrap_executor;

-- usp_organization_configuration | runtime | OrganizationService.configuration: 8 result sets root (id AND tenant_id),branches,areas,specialties,members,member-branch pairs,member-specialty pairs,invoices. Java groups pairs into string[] without changing DTO shape.
GRANT EXECUTE ON OBJECT::dbo.usp_organization_configuration TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_organization_configuration TO hp_bootstrap_executor;

-- usp_organization_lookup | runtime | OrganizationService.lookup: ADM tenant only, existing identity lookup with no password hashes.
GRANT EXECUTE ON OBJECT::dbo.usp_organization_lookup TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_organization_lookup TO hp_bootstrap_executor;

-- usp_organization_directory | runtime | OrganizationService.directory: any authenticated current tenant membership, active branches, platform denied.
GRANT EXECUTE ON OBJECT::dbo.usp_organization_directory TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_organization_directory TO hp_bootstrap_executor;

-- usp_organization_professionals | runtime | OrganizationService.professionals: active PRO identities, optional branch membership authorization, no history.
GRANT EXECUTE ON OBJECT::dbo.usp_organization_professionals TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_organization_professionals TO hp_bootstrap_executor;

-- usp_organization_catalog | runtime | OrganizationService.catalog: compatible specialty profiles, tenant only.
GRANT EXECUTE ON OBJECT::dbo.usp_organization_catalog TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_organization_catalog TO hp_bootstrap_executor;

-- usp_organization_plans | runtime | OrganizationService.availablePlans: ADM, published kind/domain-compatible offers.
GRANT EXECUTE ON OBJECT::dbo.usp_organization_plans TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_organization_plans TO hp_bootstrap_executor;

-- usp_saas_plan_save | runtime | PlatformService.plan / V6 sp_plan_save: immutable version append, current pointer changes under lock; no expectedRevision in API. RS plan/current version.
GRANT EXECUTE ON OBJECT::dbo.usp_saas_plan_save TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_saas_plan_save TO hp_bootstrap_executor;

-- usp_org_subscription_resolve | private | Internal published plan/quota resolution
DENY EXECUTE ON OBJECT::dbo.usp_org_subscription_resolve TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_org_subscription_resolve TO hp_bootstrap_executor;

-- usp_org_validate_specialties | private | Internal profile/domain/quota validator
DENY EXECUTE ON OBJECT::dbo.usp_org_validate_specialties TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_org_validate_specialties TO hp_bootstrap_executor;

-- usp_saas_tenant_create | runtime | PlatformService.create + AccountLifecycleService.register / V2 sp_tenant_create: owner resolved by Spring new/existing XOR in same TX; public only pending fresh owner, server included quotas/MONTHLY. IANA ZoneId validation remains Spring. RS tenant (SAD) or public created scope. No expectedRevision exists.
GRANT EXECUTE ON OBJECT::dbo.usp_saas_tenant_create TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_saas_tenant_create TO hp_bootstrap_executor;

-- usp_saas_tenant_status | runtime | PlatformService.status / V2: recovery from suspended/cancelled allowed, global OPEN required; no optimistic revision in current DTO.
GRANT EXECUTE ON OBJECT::dbo.usp_saas_tenant_status TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_saas_tenant_status TO hp_bootstrap_executor;

-- usp_organization_subscription_change | runtime | OrganizationService.subscription / V2: locked tenant serializes consumption; snapshots old plan versions/invoices preserved. RS eight configuration sets, no tenant auto-resume; no expectedRevision in API.
GRANT EXECUTE ON OBJECT::dbo.usp_organization_subscription_change TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_organization_subscription_change TO hp_bootstrap_executor;

-- usp_saas_invoice_pay | runtime | PlatformService.pay / V2: idempotent internal SaaS payment marker only; no external payment provider or clinical finance side effects.
GRANT EXECUTE ON OBJECT::dbo.usp_saas_invoice_pay TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_saas_invoice_pay TO hp_bootstrap_executor;

-- usp_organization_branch_save | runtime | OrganizationService.branch / active V6: same-tenant POST/PUT existence, quota and last owned active branch, external DOCTOR-owner, pending operations block deactivation. RS Branch; API has no revision.
GRANT EXECUTE ON OBJECT::dbo.usp_organization_branch_save TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_organization_branch_save TO hp_bootstrap_executor;

-- usp_organization_area_save | runtime | OrganizationService.area / V2: own active branch and activated specialties; no expectedRevision exists. RS Area JSON specialties.
GRANT EXECUTE ON OBJECT::dbo.usp_organization_area_save TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_organization_area_save TO hp_bootstrap_executor;

-- usp_organization_specialties_save | runtime | OrganizationService.specialties / V2: preserve referenced specialties including area assignments, no clinical activation certification. RS configuration.
GRANT EXECUTE ON OBJECT::dbo.usp_organization_specialties_save TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_organization_specialties_save TO hp_bootstrap_executor;

-- usp_organization_member_save | runtime | OrganizationService.member / V2: Spring resolves userId XOR newly created user in same TX via V3. Actual tenant lock serializes counted PRO active/invited; owner preserved, DOCTOR sole clinical identity. RS saved member; no revision in API.
GRANT EXECUTE ON OBJECT::dbo.usp_organization_member_save TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_organization_member_save TO hp_bootstrap_executor;

-- usp_platform_user | runtime | PlatformService.createUser: saved user projection, no password hash and no extra active field.
GRANT EXECUTE ON OBJECT::dbo.usp_platform_user TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_platform_user TO hp_bootstrap_executor;

-- usp_clinical_scope | private | Internal clinical membership/module guard
DENY EXECUTE ON OBJECT::dbo.usp_clinical_scope TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_clinical_scope TO hp_bootstrap_executor;

-- usp_clinical_branch_guard | private | Internal clinical branch guard
DENY EXECUTE ON OBJECT::dbo.usp_clinical_branch_guard TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_clinical_branch_guard TO hp_bootstrap_executor;

-- usp_clinical_professional_guard | private | Internal global professional assignment lock/guard
DENY EXECUTE ON OBJECT::dbo.usp_clinical_professional_guard TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_clinical_professional_guard TO hp_bootstrap_executor;

-- usp_portal_scope | private | Internal current portal link guard
DENY EXECUTE ON OBJECT::dbo.usp_portal_scope TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_portal_scope TO hp_bootstrap_executor;

-- usp_patients_list | runtime | PatientService.list: limit1..200, nonnegative offset; complete patient projection, own tenant only.
GRANT EXECUTE ON OBJECT::dbo.usp_patients_list TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_patients_list TO hp_bootstrap_executor;

-- usp_patient_get | runtime | PatientService.get/save result + patient existence lookup: same tenant, no branch filter.
GRANT EXECUTE ON OBJECT::dbo.usp_patient_get TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_patient_get TO hp_bootstrap_executor;

-- usp_patient_history | runtime | PatientService.history: four resultsets encounters/entries/documents/limits+patient_id; longitudinal ALL branches of same tenant, never cross-tenant.
GRANT EXECUTE ON OBJECT::dbo.usp_patient_history TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_patient_history TO hp_bootstrap_executor;

-- usp_encounter_get | runtime | ClinicalService.get/start/note: 2 resultsets encounter + entries, same-tenant longitudinal read without assignment narrowing.
GRANT EXECUTE ON OBJECT::dbo.usp_encounter_get TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_encounter_get TO hp_bootstrap_executor;

-- usp_documents_list | runtime | DocumentService.list: same tenant across branches, audited internally, 200 complete documents.
GRANT EXECUTE ON OBJECT::dbo.usp_documents_list TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_documents_list TO hp_bootstrap_executor;

-- usp_document_get | runtime | DocumentService.get/create/change result: full document, internal audit, no body in audit metadata.
GRANT EXECUTE ON OBJECT::dbo.usp_document_get TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_document_get TO hp_bootstrap_executor;

-- usp_clinical_json_object | private | Internal clinical DTO validator
DENY EXECUTE ON OBJECT::dbo.usp_clinical_json_object TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_clinical_json_object TO hp_bootstrap_executor;

-- usp_patient_save | runtime | PatientService.save / MySQL V3 sp_patient_save: create expected0/update expected>=1, domain fixed by tenant. RS full patient; Spring retains Checks.json depth validation.
GRANT EXECUTE ON OBJECT::dbo.usp_patient_save TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_patient_save TO hp_bootstrap_executor;

-- usp_patient_link_save | runtime | PatientService.link / V3 sp_patient_link: own tenant active PAC/RES membership, valid scopes, grant/revoke audit, RS saved link; no expectedRevision in current Link DTO.
GRANT EXECUTE ON OBJECT::dbo.usp_patient_link_save TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_patient_link_save TO hp_bootstrap_executor;

-- usp_appointments_list | runtime | SchedulingService.list: fixed UTC window, optional authorized branch, tenant-wide when omitted, limit200.
GRANT EXECUTE ON OBJECT::dbo.usp_appointments_list TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_appointments_list TO hp_bootstrap_executor;

-- usp_appointment_get | runtime | SchedulingService.get/row: current tenant, existing read policy does not add a branch assignment filter.
GRANT EXECUTE ON OBJECT::dbo.usp_appointment_get TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_appointment_get TO hp_bootstrap_executor;

-- usp_appointment_reserve | runtime | SchedulingService.reserve (staff/portal) / V3: server SHA256 of exact Requests.Reserve serialization, same key+hash returns prior row. UTC body format yyyy-MM-dd HH:mm:ss.ffffff; global PRO lock, no foreign-tenant schedule details returned.
GRANT EXECUTE ON OBJECT::dbo.usp_appointment_reserve TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_appointment_reserve TO hp_bootstrap_executor;

-- usp_appointment_change | runtime | SchedulingService.change + AppointmentStates / V3: state machine and expectedRevision, branch assignment, optional atomic reschedule. No SELECT Java needed after write.
GRANT EXECUTE ON OBJECT::dbo.usp_appointment_change TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_appointment_change TO hp_bootstrap_executor;

-- usp_encounter_start | runtime | ClinicalService.start / V3: one ACTIVE/PENDING per patient, snapshot complete catalog profile, current author PRO and assignments. RS encounter+entries.
GRANT EXECUTE ON OBJECT::dbo.usp_encounter_start TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_encounter_start TO hp_bootstrap_executor;

-- usp_encounter_note | runtime | ClinicalService.note/finalize / V3 sp_encounter_save: author+branch+revision; preserves note MAX100000 UTF16 units, no text in audit. RS encounter+entries.
GRANT EXECUTE ON OBJECT::dbo.usp_encounter_note TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_encounter_note TO hp_bootstrap_executor;

-- usp_clinical_entry_add | runtime | ClinicalService.entry / V3: OBSERVATION PRO/ASI; other kinds author PRO. Spring MUST retain ClinicalValidation(profile fields/components/required/types/options) before calling. RS complete saved entry, no TODO rule engine substitution.
GRANT EXECUTE ON OBJECT::dbo.usp_clinical_entry_add TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_clinical_entry_add TO hp_bootstrap_executor;

-- usp_document_create | runtime | DocumentService.create / V3: PRO tenant, signed original same patient/tenant and optional encounter same patient; no new branch restriction. Full MAX content, draft adenda only. RS document.
GRANT EXECUTE ON OBJECT::dbo.usp_document_create TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_document_create TO hp_bootstrap_executor;

-- usp_document_change | runtime | DocumentService.change / V3: expectedRevision, immutable signatures and adendas, publication link check, withdrawal prevents future portal read. No raw text in general audit. RS document.
GRANT EXECUTE ON OBJECT::dbo.usp_document_change TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_document_change TO hp_bootstrap_executor;

-- usp_portal_patients | runtime | PortalService.patients: active own links only, full scopes JSON, safe access audit added, external TX required even on read.
GRANT EXECUTE ON OBJECT::dbo.usp_portal_patients TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_portal_patients TO hp_bootstrap_executor;

-- usp_portal_documents | runtime | PortalService.documents: current own DOCUMENTS link and only published signed non-withdrawn documents; revocation denies later reads. Content MAX, safe audit.
GRANT EXECUTE ON OBJECT::dbo.usp_portal_documents TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_portal_documents TO hp_bootstrap_executor;

-- usp_portal_appointments | runtime | PortalService.appointments: own APPOINTMENTS scope, same limited public projection, internal audit added.
GRANT EXECUTE ON OBJECT::dbo.usp_portal_appointments TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_portal_appointments TO hp_bootstrap_executor;

-- usp_portal_balance | runtime | PortalService.balance: existing FINANCE+BILLING linked read only; no finance writes ported, refund sign semantics preserved.
GRANT EXECUTE ON OBJECT::dbo.usp_portal_balance TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_portal_balance TO hp_bootstrap_executor;

-- usp_operations_scope | private | Internal operations role/module guard
DENY EXECUTE ON OBJECT::dbo.usp_operations_scope TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_operations_scope TO hp_bootstrap_executor;

-- usp_operations_branch | private | Internal operations branch guard
DENY EXECUTE ON OBJECT::dbo.usp_operations_branch TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_operations_branch TO hp_bootstrap_executor;

-- usp_operations_json | private | Internal nullable DTO validator
DENY EXECUTE ON OBJECT::dbo.usp_operations_json TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_operations_json TO hp_bootstrap_executor;

-- usp_operations_idempotency | private | Internal key/hash validator
DENY EXECUTE ON OBJECT::dbo.usp_operations_idempotency TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_operations_idempotency TO hp_bootstrap_executor;

-- usp_operations_quantity | private | Internal exact quantity parser
DENY EXECUTE ON OBJECT::dbo.usp_operations_quantity TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_operations_quantity TO hp_bootstrap_executor;

-- usp_finance_balance | runtime | FinanceService.balance: CAJ/AUD, no PRO permission dependency. Exact decimal38 aggregate avoids BIGINT SUM overflow; Java Number/monetary serialization unchanged.
GRANT EXECUTE ON OBJECT::dbo.usp_finance_balance TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_finance_balance TO hp_bootstrap_executor;

-- usp_finance_movements | runtime | FinanceService.movements: patient existence directly, not a clinical patient_get call; existing 200-row projection.
GRANT EXECUTE ON OBJECT::dbo.usp_finance_movements TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_finance_movements TO hp_bootstrap_executor;

-- usp_finance_post | runtime | FinanceService.post / historical V4: patient + refund parent locks; existing same-key/hash returns row without new effects; no SaaS invoice or external charge.
GRANT EXECUTE ON OBJECT::dbo.usp_finance_post TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_finance_post TO hp_bootstrap_executor;

-- usp_inventory_lots | runtime | InventoryService.lots: 200 tenant lots in expiry/name order, full decimal quantity.
GRANT EXECUTE ON OBJECT::dbo.usp_inventory_lots TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_inventory_lots TO hp_bootstrap_executor;

-- usp_inventory_transfers | runtime | InventoryService.transfers: tenant list, 200 complete transfer rows.
GRANT EXECUTE ON OBJECT::dbo.usp_inventory_transfers TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_inventory_transfers TO hp_bootstrap_executor;

-- usp_inventory_prescriptions | runtime | InventoryService.prescriptions: FAR/PRO/AUD projection, no V5 encounter reader requiring PRO; full payload MAX.
GRANT EXECUTE ON OBJECT::dbo.usp_inventory_prescriptions TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_inventory_prescriptions TO hp_bootstrap_executor;

-- usp_inventory_lot_create | runtime | InventoryService.lot / V4 sp_stock_lot: assigned active branch, starts at zero as existing contract, dates may be historical; unusable expired stock cannot be dispensed/transferred. RS lot.
GRANT EXECUTE ON OBJECT::dbo.usp_inventory_lot_create TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_inventory_lot_create TO hp_bootstrap_executor;

-- usp_inventory_move | runtime | Quantities aggregate as DECIMAL(38,0) thousandths: DECIMAL(38,3) +/- can reduce scale to 2 under SQL Server precision rules. No rounding at the .001 boundary. InventoryService.move / V4: lock lot and prescription before aggregate; exact quantity/unit, own patient prescription, stock never negative, exact retry returns existing row.
GRANT EXECUTE ON OBJECT::dbo.usp_inventory_move TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_inventory_move TO hp_bootstrap_executor;

-- usp_inventory_transfer_start | runtime | InventoryService.transfer / V4: reserve stock in source exactly once, both branches active/assigned and same tenant. Tenant UPDLOCK from guard gives deterministic shared lock order.
GRANT EXECUTE ON OBJECT::dbo.usp_inventory_transfer_start TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_inventory_transfer_start TO hp_bootstrap_executor;

-- usp_inventory_transfer_receive | runtime | InventoryService.receive / active V7: source names/lot/expiry/unit copied explicitly; existing destination with different unit conflicts, no conversion/merge. Lock transfer+tenant and target range; replay RECEIVED has no effects.
GRANT EXECUTE ON OBJECT::dbo.usp_inventory_transfer_receive TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_inventory_transfer_receive TO hp_bootstrap_executor;

-- usp_hospital_resources | runtime | HospitalService.resources: RS resource columns + occupied BIT, tenant-wide for ADM/PRO/ASI/AUD, TOP 200.
GRANT EXECUTE ON OBJECT::dbo.usp_hospital_resources TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_hospital_resources TO hp_bootstrap_executor;

-- usp_hospital_resource_create | runtime | HospitalService.resource / MySQL V4 sp_resource_create. RS full created resource; no existing resource activation/deactivation API is invented.
GRANT EXECUTE ON OBJECT::dbo.usp_hospital_resource_create TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_hospital_resource_create TO hp_bootstrap_executor;

-- usp_hospital_admissions | runtime | HospitalService.admissions: RS full admissions including existing computed active keys; TOP 200, tenant-wide, no patient clinical body.
GRANT EXECUTE ON OBJECT::dbo.usp_hospital_admissions TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_hospital_admissions TO hp_bootstrap_executor;

-- usp_hospital_admit | runtime | HospitalService.admit (including resource branch lookup) / MySQL V4 sp_admit. RS created admission; tenant guard then patient/resource locks plus filtered unique constraints.
GRANT EXECUTE ON OBJECT::dbo.usp_hospital_admit TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_hospital_admit TO hp_bootstrap_executor;

-- usp_hospital_discharge | runtime | HospitalService.discharge + branch lookup / MySQL V4 sp_discharge. RS revised admission, never closes encounters or removes histories.
GRANT EXECUTE ON OBJECT::dbo.usp_hospital_discharge TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_hospital_discharge TO hp_bootstrap_executor;

-- usp_operations_workflow_guard | private | Internal workflow definition role/module guard
DENY EXECUTE ON OBJECT::dbo.usp_operations_workflow_guard TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_operations_workflow_guard TO hp_bootstrap_executor;

-- usp_workflow_definitions | runtime | WorkflowService.definitions: RS type,module,patient_required,animal_only,creators,operators,readers,transitions (JSON text), filtered by actual modules/current membership readers. Existing definitions contain role arrays/transitions only, no conditions/requiredData engine. No new laboratory/surgery/provider effects are implied.
GRANT EXECUTE ON OBJECT::dbo.usp_workflow_definitions TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_workflow_definitions TO hp_bootstrap_executor;

-- usp_workflow_list | runtime | WorkflowService.list(type) + private definition lookup: RS full workflow case columns, TOP 200, immutable full JSON text.
GRANT EXECUTE ON OBJECT::dbo.usp_workflow_list TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_workflow_list TO hp_bootstrap_executor;

-- usp_workflow_get | runtime | WorkflowService.get: RS1 full own case; RS2 history{revision,status,payload,actor_id,created_at} ordered revision; Java assembles history array without JSON stringification/truncation.
GRANT EXECUTE ON OBJECT::dbo.usp_workflow_get TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_workflow_get TO hp_bootstrap_executor;

-- usp_workflow_create | runtime | WorkflowService.create / V4 sp_workflow_create: input exact Requests.Create; RS1 case + RS2 history as get. Payload object MAX, Spring retains Checks.json 200000 UTF16/depth30 validation.
GRANT EXECUTE ON OBJECT::dbo.usp_workflow_create TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_workflow_create TO hp_bootstrap_executor;

-- usp_workflow_step | runtime | WorkflowService.step / V4 sp_workflow_step: typed expected revision/status, JSON object payload MAX. RS1 revised case + RS2 full history; terminal states cannot advance without a server definition transition. No autonomous commits; tenant write guard serializes mutations before case locks. Revision is re-read under lock; history has no mutating/deleting procedure.
GRANT EXECUTE ON OBJECT::dbo.usp_workflow_step TO hp_runtime_executor;
DENY EXECUTE ON OBJECT::dbo.usp_workflow_step TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[users] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[users] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[plans] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[plans] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[plan_versions] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[plan_versions] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[tenants] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[tenants] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[subscriptions] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[subscriptions] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[specialties] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[specialties] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[tenant_specialties] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[tenant_specialties] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[branches] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[branches] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[areas] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[areas] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[memberships] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[memberships] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[membership_branches] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[membership_branches] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[membership_specialties] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[membership_specialties] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[auth_sessions] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[auth_sessions] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[audit_events] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[audit_events] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[saas_invoices] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[saas_invoices] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[patients] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[patients] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[patient_links] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[patient_links] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[appointments] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[appointments] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[encounters] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[encounters] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[clinical_entries] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[clinical_entries] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[documents] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[documents] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[finance_movements] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[finance_movements] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[stock_lots] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[stock_lots] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[stock_movements] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[stock_movements] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[stock_transfers] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[stock_transfers] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[hospital_resources] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[hospital_resources] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[admissions] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[admissions] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[workflow_cases] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[workflow_cases] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[workflow_history] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[workflow_history] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[workflow_definitions] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[workflow_definitions] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[request_traces] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[request_traces] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[identity_tokens] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[identity_tokens] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[mail_outbox] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[mail_outbox] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[support_tickets] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[support_tickets] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[support_comments] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[support_comments] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[application_state] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[application_state] TO hp_bootstrap_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[health_samples] TO hp_runtime_executor;
DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.[health_samples] TO hp_bootstrap_executor;
-- D-15.D: history belongs to the migrator. The ONLY extra GRANT is object metadata
-- visibility for runtime so the fixed monitor OBJECT_ID guard can see its table.
-- This grants NO data access; the authenticated SAD/SOP SP remains the reader.
-- Same dbo owner-chain precondition above also covers this optional table.
IF OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NOT NULL
BEGIN
 DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.flyway_schema_history TO hp_runtime_executor;
 DENY SELECT,INSERT,UPDATE,DELETE ON OBJECT::dbo.flyway_schema_history TO hp_bootstrap_executor;
 GRANT VIEW DEFINITION ON OBJECT::dbo.flyway_schema_history TO hp_runtime_executor;
END;
GO
-- D-15.A: exact V3 body, only the reviewed bootstrap role alternative added.
ALTER PROCEDURE dbo.usp_bootstrap_exists
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_scope 'BOOTSTRAP'; IF ISNULL(IS_ROLEMEMBER(N'db_owner'),0)<>1 AND ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 AND ISNULL(IS_ROLEMEMBER(N'hp_bootstrap_executor'),0)<>1 THROW 51001,'HP_FORBIDDEN:Separate elevated setup principal required',1; SELECT TOP(1) id FROM dbo.users WHERE platform_role='SAD' ORDER BY id;
END;
GO
-- D-15.A: exact V3 body, only the reviewed bootstrap role alternative added.
ALTER PROCEDURE dbo.usp_bootstrap_create @id char(36),@email nvarchar(254),@password_hash nvarchar(100)
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT ON;
 EXEC dbo.usp_require_transaction; EXEC dbo.usp_require_scope 'BOOTSTRAP'; IF ISNULL(IS_ROLEMEMBER(N'db_owner'),0)<>1 AND ISNULL(IS_SRVROLEMEMBER(N'sysadmin'),0)<>1 AND ISNULL(IS_ROLEMEMBER(N'hp_bootstrap_executor'),0)<>1 THROW 51001,'HP_FORBIDDEN:Separate elevated setup principal required',1; IF EXISTS(SELECT 1 FROM dbo.users WITH(UPDLOCK,HOLDLOCK) WHERE platform_role='SAD') RETURN; IF NULLIF(@email,N'') IS NULL OR NULLIF(@password_hash,N'') IS NULL THROW 51000,'HP_INVALID:Bootstrap fields',1; INSERT dbo.users(id,name,email,password_hash,platform_role,email_verified) VALUES(@id,N'Administrador general',LOWER(@email),@password_hash,'SAD',1);
END;
GO
