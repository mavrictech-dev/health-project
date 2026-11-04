-- SQL-01.A7 / D-15.B rollback-only SQLcmd harness, synthetic SQL2022 QA ONLY.
-- Run from repository root, NEW connection for EACH named phase:
-- sqlcmd -S localhost -E -C -b -f 65001 -d health_project_sqlserver_qa_20261103 -v A7Phase=normal -i backend/scripts/verify-sqlserver-permissions.sql
-- Repeat SEQUENTIALLY: normal,ddl_runtime,ddl_bootstrap,impersonate_runtime,
-- impersonate_bootstrap,scope_exists,scope_create,history,monitor_unauthorized. Runner also tests
-- unknown_table via an exact in-memory V8 first batch inside TRY/CATCH.
-- History is SYNTHETIC representative metadata, never a real Flyway/JDBC run.
-- Every phase starts at the original baseline and installs V8/roles/users in ONE
-- EXTERNAL transaction, with no COMMIT. Normal explicitly REVERTs and ROLLBACKs.
-- Expected262/15517/51001 can doom the transaction even with XACT_ABORT OFF;
-- these phases assert the expected error AND XACT_STATE=-1, print PASS, then end
-- the connection. Do NOT force REVERT while doomed or after its user rolls back.
-- Connection closure rolls back and releases impersonation; verify from a NEW
-- administrative connection before/after EVERY phase. Stop on any discrepancy.
-- The executable stdlib runner and independent baseline query are embedded at EOF.
-- Run all phases from PowerShell (no new helper file):
-- $qaText=Get-Content backend/scripts/verify-sqlserver-permissions.sql -Raw -Encoding UTF8
-- $qaRunner=[regex]::Match($qaText,'(?s)-- A7_RUNNER_BEGIN\r?\n/\*\r?\n(.*?)\r?\n\*/\r?
-- A7_RUNNER_END').Groups[1].Value
-- if(!$qaRunner){throw 'Missing QA runner'}; $qaRunner | python -B -
-- if($LASTEXITCODE -ne 0){throw 'A7 verification failed'}
-- Normal raw sqlcmd exit is0; each expected doomed phase raw exit is1 with
-- ONLY engine Msg3998 at batch end, after the exact PASS/error/state assertion.
-- The runner accepts this known pair ONLY after its NEW-connection before/after
-- fingerprint matches; any unexpected exit/message/assertion/cleanup fails runner.
-- Runner overall exit0 means all10phases and20fresh baseline checks passed.
-- Before-TRY/:r/compile failures also exit via :On Error exit/-b, closing and
-- rolling back the connection. External baseline verification is always required.
-- No login authentication/JDBC/HTTP/SMTP/production validation. SQLcmd phase
-- input is a trusted operator selector; only the fixed names below are accepted.
-- Dynamic SQL is QA-only, from fixed test strings, never request/client text.
:On Error exit
-- and -b; SQL Server rolls back the open transaction when that connection closes.
-- A failure inside TRY safely REVERTs, rolls back, checks cleanup, THEN rethrows.
-- Always run the documented independent baseline query on a NEW connection even
-- after nonzero exit; connection-close rollback is not a printed cleanup claim.
-- No SMTP, login authentication, JDBC, HTTP or production validation is performed.
-- Dynamic SQL below is QA ONLY: fixed literal test cases, not caller/client SQL.
-- Negative permission errors use XACT_ABORT OFF. The wrong-scope bootstrap SP
-- sets XACT_ABORT ON itself; it is tested LAST, then immediately ROLLBACK.
:On Error exit
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
IF DB_NAME()<>N'health_project_sqlserver_qa_20261103'
 THROW 59999,N'Wrong database: QA exact name required',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'health_project_scope'
 AND CONVERT(nvarchar(max),value)=N'Health Project synthetic SQL Server migration QA; provisioned 2026-11-03; no real data')
 THROW 59999,N'Wrong synthetic scope marker',1;
IF N'$(A7Phase)' NOT IN (N'normal',N'ddl_runtime',N'ddl_bootstrap',N'impersonate_runtime',N'impersonate_bootstrap',N'scope_exists',N'scope_create',N'history',N'monitor_unauthorized')
 THROW 59999,N'Unknown A7Phase',1;
IF @@TRANCOUNT<>0 OR (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo'))<>133
 OR (SELECT COUNT(*) FROM sys.tables WHERE schema_id=SCHEMA_ID(N'dbo'))<>37
 OR (SELECT COUNT(*) FROM sys.triggers WHERE parent_class=1)<>31 OR EXISTS(SELECT 1 FROM dbo.users)
 THROW 59999,N'Wrong QA baseline',1;
IF EXISTS(SELECT 1 FROM sys.database_principals WHERE name IN (N'hp_runtime_executor',N'hp_bootstrap_executor',N'hp_qa_runtime_a7',N'hp_qa_bootstrap_a7'))
 OR OBJECT_ID(N'dbo.hp_qa_future_a7') IS NOT NULL OR OBJECT_ID(N'dbo.hp_qa_future_procedure_a7') IS NOT NULL
 OR OBJECT_ID(N'dbo.hp_qa_unauthorized_a7') IS NOT NULL OR OBJECT_ID(N'dbo.flyway_schema_history') IS NOT NULL OR OBJECT_ID(N'dbo.hp_qa_unknown_history_a7') IS NOT NULL
 THROW 59999,N'Fixture/principal collision; nothing was changed',1;
SELECT name,HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(object_id))) definition_fingerprint
 INTO #a7_procedures_before FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo');
-- Definition fingerprint is same-byte metadata comparison (not a business UTF8 hash).
SELECT name,HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(object_id))) definition_fingerprint
 INTO #a7_triggers_before FROM sys.triggers WHERE parent_class=1;
SELECT * INTO #a7_counts_before FROM (
 SELECT N'users' name,COUNT_BIG(*) n FROM dbo.[users]
 UNION ALL
 SELECT N'plans' name,COUNT_BIG(*) n FROM dbo.[plans]
 UNION ALL
 SELECT N'plan_versions' name,COUNT_BIG(*) n FROM dbo.[plan_versions]
 UNION ALL
 SELECT N'tenants' name,COUNT_BIG(*) n FROM dbo.[tenants]
 UNION ALL
 SELECT N'subscriptions' name,COUNT_BIG(*) n FROM dbo.[subscriptions]
 UNION ALL
 SELECT N'specialties' name,COUNT_BIG(*) n FROM dbo.[specialties]
 UNION ALL
 SELECT N'tenant_specialties' name,COUNT_BIG(*) n FROM dbo.[tenant_specialties]
 UNION ALL
 SELECT N'branches' name,COUNT_BIG(*) n FROM dbo.[branches]
 UNION ALL
 SELECT N'areas' name,COUNT_BIG(*) n FROM dbo.[areas]
 UNION ALL
 SELECT N'memberships' name,COUNT_BIG(*) n FROM dbo.[memberships]
 UNION ALL
 SELECT N'membership_branches' name,COUNT_BIG(*) n FROM dbo.[membership_branches]
 UNION ALL
 SELECT N'membership_specialties' name,COUNT_BIG(*) n FROM dbo.[membership_specialties]
 UNION ALL
 SELECT N'auth_sessions' name,COUNT_BIG(*) n FROM dbo.[auth_sessions]
 UNION ALL
 SELECT N'audit_events' name,COUNT_BIG(*) n FROM dbo.[audit_events]
 UNION ALL
 SELECT N'saas_invoices' name,COUNT_BIG(*) n FROM dbo.[saas_invoices]
 UNION ALL
 SELECT N'patients' name,COUNT_BIG(*) n FROM dbo.[patients]
 UNION ALL
 SELECT N'patient_links' name,COUNT_BIG(*) n FROM dbo.[patient_links]
 UNION ALL
 SELECT N'appointments' name,COUNT_BIG(*) n FROM dbo.[appointments]
 UNION ALL
 SELECT N'encounters' name,COUNT_BIG(*) n FROM dbo.[encounters]
 UNION ALL
 SELECT N'clinical_entries' name,COUNT_BIG(*) n FROM dbo.[clinical_entries]
 UNION ALL
 SELECT N'documents' name,COUNT_BIG(*) n FROM dbo.[documents]
 UNION ALL
 SELECT N'finance_movements' name,COUNT_BIG(*) n FROM dbo.[finance_movements]
 UNION ALL
 SELECT N'stock_lots' name,COUNT_BIG(*) n FROM dbo.[stock_lots]
 UNION ALL
 SELECT N'stock_movements' name,COUNT_BIG(*) n FROM dbo.[stock_movements]
 UNION ALL
 SELECT N'stock_transfers' name,COUNT_BIG(*) n FROM dbo.[stock_transfers]
 UNION ALL
 SELECT N'hospital_resources' name,COUNT_BIG(*) n FROM dbo.[hospital_resources]
 UNION ALL
 SELECT N'admissions' name,COUNT_BIG(*) n FROM dbo.[admissions]
 UNION ALL
 SELECT N'workflow_cases' name,COUNT_BIG(*) n FROM dbo.[workflow_cases]
 UNION ALL
 SELECT N'workflow_history' name,COUNT_BIG(*) n FROM dbo.[workflow_history]
 UNION ALL
 SELECT N'workflow_definitions' name,COUNT_BIG(*) n FROM dbo.[workflow_definitions]
 UNION ALL
 SELECT N'request_traces' name,COUNT_BIG(*) n FROM dbo.[request_traces]
 UNION ALL
 SELECT N'identity_tokens' name,COUNT_BIG(*) n FROM dbo.[identity_tokens]
 UNION ALL
 SELECT N'mail_outbox' name,COUNT_BIG(*) n FROM dbo.[mail_outbox]
 UNION ALL
 SELECT N'support_tickets' name,COUNT_BIG(*) n FROM dbo.[support_tickets]
 UNION ALL
 SELECT N'support_comments' name,COUNT_BIG(*) n FROM dbo.[support_comments]
 UNION ALL
 SELECT N'application_state' name,COUNT_BIG(*) n FROM dbo.[application_state]
 UNION ALL
 SELECT N'health_samples' name,COUNT_BIG(*) n FROM dbo.[health_samples]
) c;
CREATE TABLE #a7_expected(role_name sysname COLLATE DATABASE_DEFAULT,object_name sysname COLLATE DATABASE_DEFAULT,permission_name sysname COLLATE DATABASE_DEFAULT,permission_state char(1) COLLATE DATABASE_DEFAULT);
INSERT #a7_expected VALUES
 (N'hp_runtime_executor',N'usp_request_context',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_request_context',N'EXECUTE',N'G'),
 (N'hp_runtime_executor',N'usp_require_transaction',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_require_transaction',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_require_actor',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_require_actor',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_require_scope',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_require_scope',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_write_guard',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_write_guard',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_audit_event',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_audit_event',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_tenant_by_slug',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_tenant_by_slug',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_registration_plans',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_registration_plans',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_registration_specialties',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_registration_specialties',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_registration_plan',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_registration_plan',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_identity_credentials',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_identity_credentials',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_identity_account_lookup',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_identity_account_lookup',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_identity_email_exists',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_identity_email_exists',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_identity_membership',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_identity_membership',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_user_create',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_user_create',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_bootstrap_exists',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_bootstrap_exists',N'EXECUTE',N'G'),
 (N'hp_runtime_executor',N'usp_bootstrap_create',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_bootstrap_create',N'EXECUTE',N'G'),
 (N'hp_runtime_executor',N'usp_identity_pending',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_identity_pending',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_identity_password_hash',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_identity_password_hash',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_password_change',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_password_change',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_session_resolve',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_session_resolve',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_session_save',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_session_save',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_session_current',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_session_current',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_sessions_list',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_sessions_list',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_session_revoke',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_session_revoke',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_session_touch',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_session_touch',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_login_failure',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_login_failure',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_identity_issue',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_identity_issue',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_identity_redeem',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_identity_redeem',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_portal_register',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_portal_register',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_invitation_accept',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_invitation_accept',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_access_branch',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_access_branch',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_access_patient_link',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_access_patient_link',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_mail_claim',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_mail_claim',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_mail_complete',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_mail_complete',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_health_ready',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_health_ready',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_application_status',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_application_status',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_application_mode',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_application_mode',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_health_sample',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_health_sample',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_monitor_samples',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_monitor_samples',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_monitor_mail',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_monitor_mail',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_monitor_requests',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_monitor_requests',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_monitor_migrations',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_monitor_migrations',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_request_finish',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_request_finish',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_audit_list',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_audit_list',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_trace_events',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_trace_events',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_trace_requests',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_trace_requests',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_trace_journey',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_trace_journey',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_support_list',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_support_list',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_require_support_ticket',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_require_support_ticket',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_support_detail',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_support_detail',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_support_create',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_support_create',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_support_step',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_support_step',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_audit_change',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_audit_change',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_org_json_object',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_org_json_object',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_org_json_strings',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_org_json_strings',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_saas_write_gate',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_saas_write_gate',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_org_target',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_org_target',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_platform_plans',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_platform_plans',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_platform_tenants',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_platform_tenants',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_platform_users',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_platform_users',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_platform_specialties',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_platform_specialties',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_platform_audit',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_platform_audit',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_organization_configuration',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_organization_configuration',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_organization_lookup',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_organization_lookup',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_organization_directory',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_organization_directory',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_organization_professionals',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_organization_professionals',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_organization_catalog',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_organization_catalog',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_organization_plans',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_organization_plans',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_saas_plan_save',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_saas_plan_save',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_org_subscription_resolve',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_org_subscription_resolve',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_org_validate_specialties',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_org_validate_specialties',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_saas_tenant_create',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_saas_tenant_create',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_saas_tenant_status',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_saas_tenant_status',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_organization_subscription_change',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_organization_subscription_change',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_saas_invoice_pay',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_saas_invoice_pay',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_organization_branch_save',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_organization_branch_save',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_organization_area_save',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_organization_area_save',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_organization_specialties_save',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_organization_specialties_save',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_organization_member_save',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_organization_member_save',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_platform_user',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_platform_user',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_clinical_scope',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_clinical_scope',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_clinical_branch_guard',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_clinical_branch_guard',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_clinical_professional_guard',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_clinical_professional_guard',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_portal_scope',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_portal_scope',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_patients_list',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_patients_list',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_patient_get',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_patient_get',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_patient_history',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_patient_history',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_encounter_get',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_encounter_get',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_documents_list',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_documents_list',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_document_get',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_document_get',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_clinical_json_object',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_clinical_json_object',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_patient_save',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_patient_save',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_patient_link_save',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_patient_link_save',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_appointments_list',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_appointments_list',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_appointment_get',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_appointment_get',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_appointment_reserve',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_appointment_reserve',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_appointment_change',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_appointment_change',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_encounter_start',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_encounter_start',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_encounter_note',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_encounter_note',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_clinical_entry_add',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_clinical_entry_add',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_document_create',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_document_create',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_document_change',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_document_change',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_portal_patients',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_portal_patients',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_portal_documents',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_portal_documents',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_portal_appointments',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_portal_appointments',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_portal_balance',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_portal_balance',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_operations_scope',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_operations_scope',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_operations_branch',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_operations_branch',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_operations_json',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_operations_json',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_operations_idempotency',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_operations_idempotency',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_operations_quantity',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_operations_quantity',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_finance_balance',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_finance_balance',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_finance_movements',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_finance_movements',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_finance_post',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_finance_post',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_inventory_lots',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_inventory_lots',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_inventory_transfers',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_inventory_transfers',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_inventory_prescriptions',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_inventory_prescriptions',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_inventory_lot_create',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_inventory_lot_create',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_inventory_move',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_inventory_move',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_inventory_transfer_start',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_inventory_transfer_start',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_inventory_transfer_receive',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_inventory_transfer_receive',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_hospital_resources',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_hospital_resources',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_hospital_resource_create',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_hospital_resource_create',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_hospital_admissions',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_hospital_admissions',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_hospital_admit',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_hospital_admit',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_hospital_discharge',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_hospital_discharge',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_operations_workflow_guard',N'EXECUTE',N'D'),
 (N'hp_bootstrap_executor',N'usp_operations_workflow_guard',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_workflow_definitions',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_workflow_definitions',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_workflow_list',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_workflow_list',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_workflow_get',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_workflow_get',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_workflow_create',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_workflow_create',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'usp_workflow_step',N'EXECUTE',N'G'),
 (N'hp_bootstrap_executor',N'usp_workflow_step',N'EXECUTE',N'D'),
 (N'hp_runtime_executor',N'users',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'users',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'users',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'users',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'users',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'users',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'users',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'users',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'plans',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'plans',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'plans',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'plans',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'plans',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'plans',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'plans',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'plans',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'plan_versions',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'plan_versions',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'plan_versions',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'plan_versions',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'plan_versions',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'plan_versions',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'plan_versions',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'plan_versions',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'tenants',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'tenants',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'tenants',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'tenants',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'tenants',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'tenants',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'tenants',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'tenants',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'subscriptions',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'subscriptions',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'subscriptions',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'subscriptions',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'subscriptions',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'subscriptions',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'subscriptions',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'subscriptions',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'specialties',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'specialties',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'specialties',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'specialties',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'specialties',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'specialties',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'specialties',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'specialties',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'tenant_specialties',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'tenant_specialties',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'tenant_specialties',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'tenant_specialties',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'tenant_specialties',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'tenant_specialties',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'tenant_specialties',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'tenant_specialties',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'branches',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'branches',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'branches',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'branches',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'branches',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'branches',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'branches',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'branches',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'areas',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'areas',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'areas',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'areas',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'areas',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'areas',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'areas',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'areas',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'memberships',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'memberships',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'memberships',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'memberships',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'memberships',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'memberships',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'memberships',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'memberships',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'membership_branches',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'membership_branches',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'membership_branches',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'membership_branches',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'membership_branches',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'membership_branches',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'membership_branches',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'membership_branches',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'membership_specialties',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'membership_specialties',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'membership_specialties',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'membership_specialties',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'membership_specialties',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'membership_specialties',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'membership_specialties',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'membership_specialties',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'auth_sessions',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'auth_sessions',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'auth_sessions',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'auth_sessions',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'auth_sessions',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'auth_sessions',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'auth_sessions',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'auth_sessions',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'audit_events',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'audit_events',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'audit_events',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'audit_events',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'audit_events',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'audit_events',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'audit_events',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'audit_events',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'saas_invoices',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'saas_invoices',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'saas_invoices',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'saas_invoices',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'saas_invoices',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'saas_invoices',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'saas_invoices',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'saas_invoices',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'patients',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'patients',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'patients',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'patients',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'patients',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'patients',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'patients',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'patients',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'patient_links',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'patient_links',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'patient_links',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'patient_links',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'patient_links',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'patient_links',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'patient_links',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'patient_links',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'appointments',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'appointments',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'appointments',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'appointments',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'appointments',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'appointments',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'appointments',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'appointments',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'encounters',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'encounters',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'encounters',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'encounters',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'encounters',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'encounters',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'encounters',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'encounters',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'clinical_entries',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'clinical_entries',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'clinical_entries',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'clinical_entries',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'clinical_entries',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'clinical_entries',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'clinical_entries',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'clinical_entries',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'documents',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'documents',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'documents',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'documents',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'documents',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'documents',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'documents',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'documents',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'finance_movements',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'finance_movements',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'finance_movements',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'finance_movements',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'finance_movements',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'finance_movements',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'finance_movements',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'finance_movements',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'stock_lots',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'stock_lots',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'stock_lots',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'stock_lots',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'stock_lots',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'stock_lots',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'stock_lots',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'stock_lots',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'stock_movements',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'stock_movements',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'stock_movements',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'stock_movements',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'stock_movements',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'stock_movements',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'stock_movements',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'stock_movements',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'stock_transfers',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'stock_transfers',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'stock_transfers',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'stock_transfers',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'stock_transfers',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'stock_transfers',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'stock_transfers',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'stock_transfers',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'hospital_resources',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'hospital_resources',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'hospital_resources',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'hospital_resources',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'hospital_resources',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'hospital_resources',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'hospital_resources',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'hospital_resources',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'admissions',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'admissions',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'admissions',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'admissions',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'admissions',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'admissions',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'admissions',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'admissions',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'workflow_cases',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'workflow_cases',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'workflow_cases',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'workflow_cases',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'workflow_cases',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'workflow_cases',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'workflow_cases',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'workflow_cases',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'workflow_history',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'workflow_history',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'workflow_history',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'workflow_history',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'workflow_history',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'workflow_history',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'workflow_history',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'workflow_history',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'workflow_definitions',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'workflow_definitions',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'workflow_definitions',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'workflow_definitions',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'workflow_definitions',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'workflow_definitions',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'workflow_definitions',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'workflow_definitions',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'request_traces',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'request_traces',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'request_traces',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'request_traces',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'request_traces',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'request_traces',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'request_traces',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'request_traces',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'identity_tokens',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'identity_tokens',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'identity_tokens',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'identity_tokens',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'identity_tokens',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'identity_tokens',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'identity_tokens',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'identity_tokens',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'mail_outbox',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'mail_outbox',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'mail_outbox',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'mail_outbox',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'mail_outbox',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'mail_outbox',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'mail_outbox',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'mail_outbox',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'support_tickets',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'support_tickets',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'support_tickets',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'support_tickets',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'support_tickets',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'support_tickets',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'support_tickets',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'support_tickets',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'support_comments',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'support_comments',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'support_comments',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'support_comments',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'support_comments',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'support_comments',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'support_comments',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'support_comments',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'application_state',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'application_state',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'application_state',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'application_state',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'application_state',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'application_state',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'application_state',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'application_state',N'DELETE',N'D'),
 (N'hp_runtime_executor',N'health_samples',N'SELECT',N'D'),
 (N'hp_runtime_executor',N'health_samples',N'INSERT',N'D'),
 (N'hp_runtime_executor',N'health_samples',N'UPDATE',N'D'),
 (N'hp_runtime_executor',N'health_samples',N'DELETE',N'D'),
 (N'hp_bootstrap_executor',N'health_samples',N'SELECT',N'D'),
 (N'hp_bootstrap_executor',N'health_samples',N'INSERT',N'D'),
 (N'hp_bootstrap_executor',N'health_samples',N'UPDATE',N'D'),
 (N'hp_bootstrap_executor',N'health_samples',N'DELETE',N'D');
CREATE TABLE #a7_negatives(role_name varchar(12),case_name nvarchar(160),sql_text nvarchar(max),expected_error int);
INSERT #a7_negatives VALUES
 (N'runtime',N'runtime:users:SELECT',N'SELECT TOP(0) * FROM dbo.[users];',229),
 (N'runtime',N'runtime:users:INSERT',N'INSERT dbo.[users] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:users:UPDATE',N'UPDATE dbo.[users] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:users:DELETE',N'DELETE dbo.[users] WHERE 1=0;',229),
 (N'runtime',N'runtime:plans:SELECT',N'SELECT TOP(0) * FROM dbo.[plans];',229),
 (N'runtime',N'runtime:plans:INSERT',N'INSERT dbo.[plans] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:plans:UPDATE',N'UPDATE dbo.[plans] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:plans:DELETE',N'DELETE dbo.[plans] WHERE 1=0;',229),
 (N'runtime',N'runtime:plan_versions:SELECT',N'SELECT TOP(0) * FROM dbo.[plan_versions];',229),
 (N'runtime',N'runtime:plan_versions:INSERT',N'INSERT dbo.[plan_versions] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:plan_versions:UPDATE',N'UPDATE dbo.[plan_versions] SET [plan_id]=[plan_id] WHERE 1=0;',229),
 (N'runtime',N'runtime:plan_versions:DELETE',N'DELETE dbo.[plan_versions] WHERE 1=0;',229),
 (N'runtime',N'runtime:tenants:SELECT',N'SELECT TOP(0) * FROM dbo.[tenants];',229),
 (N'runtime',N'runtime:tenants:INSERT',N'INSERT dbo.[tenants] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:tenants:UPDATE',N'UPDATE dbo.[tenants] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:tenants:DELETE',N'DELETE dbo.[tenants] WHERE 1=0;',229),
 (N'runtime',N'runtime:subscriptions:SELECT',N'SELECT TOP(0) * FROM dbo.[subscriptions];',229),
 (N'runtime',N'runtime:subscriptions:INSERT',N'INSERT dbo.[subscriptions] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:subscriptions:UPDATE',N'UPDATE dbo.[subscriptions] SET [tenant_id]=[tenant_id] WHERE 1=0;',229),
 (N'runtime',N'runtime:subscriptions:DELETE',N'DELETE dbo.[subscriptions] WHERE 1=0;',229),
 (N'runtime',N'runtime:specialties:SELECT',N'SELECT TOP(0) * FROM dbo.[specialties];',229),
 (N'runtime',N'runtime:specialties:INSERT',N'INSERT dbo.[specialties] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:specialties:UPDATE',N'UPDATE dbo.[specialties] SET [code]=[code] WHERE 1=0;',229),
 (N'runtime',N'runtime:specialties:DELETE',N'DELETE dbo.[specialties] WHERE 1=0;',229),
 (N'runtime',N'runtime:tenant_specialties:SELECT',N'SELECT TOP(0) * FROM dbo.[tenant_specialties];',229),
 (N'runtime',N'runtime:tenant_specialties:INSERT',N'INSERT dbo.[tenant_specialties] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:tenant_specialties:UPDATE',N'UPDATE dbo.[tenant_specialties] SET [tenant_id]=[tenant_id] WHERE 1=0;',229),
 (N'runtime',N'runtime:tenant_specialties:DELETE',N'DELETE dbo.[tenant_specialties] WHERE 1=0;',229),
 (N'runtime',N'runtime:branches:SELECT',N'SELECT TOP(0) * FROM dbo.[branches];',229),
 (N'runtime',N'runtime:branches:INSERT',N'INSERT dbo.[branches] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:branches:UPDATE',N'UPDATE dbo.[branches] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:branches:DELETE',N'DELETE dbo.[branches] WHERE 1=0;',229),
 (N'runtime',N'runtime:areas:SELECT',N'SELECT TOP(0) * FROM dbo.[areas];',229),
 (N'runtime',N'runtime:areas:INSERT',N'INSERT dbo.[areas] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:areas:UPDATE',N'UPDATE dbo.[areas] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:areas:DELETE',N'DELETE dbo.[areas] WHERE 1=0;',229),
 (N'runtime',N'runtime:memberships:SELECT',N'SELECT TOP(0) * FROM dbo.[memberships];',229),
 (N'runtime',N'runtime:memberships:INSERT',N'INSERT dbo.[memberships] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:memberships:UPDATE',N'UPDATE dbo.[memberships] SET [tenant_id]=[tenant_id] WHERE 1=0;',229),
 (N'runtime',N'runtime:memberships:DELETE',N'DELETE dbo.[memberships] WHERE 1=0;',229),
 (N'runtime',N'runtime:membership_branches:SELECT',N'SELECT TOP(0) * FROM dbo.[membership_branches];',229),
 (N'runtime',N'runtime:membership_branches:INSERT',N'INSERT dbo.[membership_branches] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:membership_branches:UPDATE',N'UPDATE dbo.[membership_branches] SET [tenant_id]=[tenant_id] WHERE 1=0;',229),
 (N'runtime',N'runtime:membership_branches:DELETE',N'DELETE dbo.[membership_branches] WHERE 1=0;',229),
 (N'runtime',N'runtime:membership_specialties:SELECT',N'SELECT TOP(0) * FROM dbo.[membership_specialties];',229),
 (N'runtime',N'runtime:membership_specialties:INSERT',N'INSERT dbo.[membership_specialties] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:membership_specialties:UPDATE',N'UPDATE dbo.[membership_specialties] SET [tenant_id]=[tenant_id] WHERE 1=0;',229),
 (N'runtime',N'runtime:membership_specialties:DELETE',N'DELETE dbo.[membership_specialties] WHERE 1=0;',229),
 (N'runtime',N'runtime:auth_sessions:SELECT',N'SELECT TOP(0) * FROM dbo.[auth_sessions];',229),
 (N'runtime',N'runtime:auth_sessions:INSERT',N'INSERT dbo.[auth_sessions] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:auth_sessions:UPDATE',N'UPDATE dbo.[auth_sessions] SET [token_hash]=[token_hash] WHERE 1=0;',229),
 (N'runtime',N'runtime:auth_sessions:DELETE',N'DELETE dbo.[auth_sessions] WHERE 1=0;',229),
 (N'runtime',N'runtime:audit_events:SELECT',N'SELECT TOP(0) * FROM dbo.[audit_events];',229),
 (N'runtime',N'runtime:audit_events:INSERT',N'INSERT dbo.[audit_events] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:audit_events:UPDATE',N'UPDATE dbo.[audit_events] SET [tenant_id]=[tenant_id] WHERE 1=0;',229),
 (N'runtime',N'runtime:audit_events:DELETE',N'DELETE dbo.[audit_events] WHERE 1=0;',229),
 (N'runtime',N'runtime:saas_invoices:SELECT',N'SELECT TOP(0) * FROM dbo.[saas_invoices];',229),
 (N'runtime',N'runtime:saas_invoices:INSERT',N'INSERT dbo.[saas_invoices] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:saas_invoices:UPDATE',N'UPDATE dbo.[saas_invoices] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:saas_invoices:DELETE',N'DELETE dbo.[saas_invoices] WHERE 1=0;',229),
 (N'runtime',N'runtime:patients:SELECT',N'SELECT TOP(0) * FROM dbo.[patients];',229),
 (N'runtime',N'runtime:patients:INSERT',N'INSERT dbo.[patients] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:patients:UPDATE',N'UPDATE dbo.[patients] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:patients:DELETE',N'DELETE dbo.[patients] WHERE 1=0;',229),
 (N'runtime',N'runtime:patient_links:SELECT',N'SELECT TOP(0) * FROM dbo.[patient_links];',229),
 (N'runtime',N'runtime:patient_links:INSERT',N'INSERT dbo.[patient_links] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:patient_links:UPDATE',N'UPDATE dbo.[patient_links] SET [tenant_id]=[tenant_id] WHERE 1=0;',229),
 (N'runtime',N'runtime:patient_links:DELETE',N'DELETE dbo.[patient_links] WHERE 1=0;',229),
 (N'runtime',N'runtime:appointments:SELECT',N'SELECT TOP(0) * FROM dbo.[appointments];',229),
 (N'runtime',N'runtime:appointments:INSERT',N'INSERT dbo.[appointments] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:appointments:UPDATE',N'UPDATE dbo.[appointments] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:appointments:DELETE',N'DELETE dbo.[appointments] WHERE 1=0;',229),
 (N'runtime',N'runtime:encounters:SELECT',N'SELECT TOP(0) * FROM dbo.[encounters];',229),
 (N'runtime',N'runtime:encounters:INSERT',N'INSERT dbo.[encounters] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:encounters:UPDATE',N'UPDATE dbo.[encounters] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:encounters:DELETE',N'DELETE dbo.[encounters] WHERE 1=0;',229),
 (N'runtime',N'runtime:clinical_entries:SELECT',N'SELECT TOP(0) * FROM dbo.[clinical_entries];',229),
 (N'runtime',N'runtime:clinical_entries:INSERT',N'INSERT dbo.[clinical_entries] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:clinical_entries:UPDATE',N'UPDATE dbo.[clinical_entries] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:clinical_entries:DELETE',N'DELETE dbo.[clinical_entries] WHERE 1=0;',229),
 (N'runtime',N'runtime:documents:SELECT',N'SELECT TOP(0) * FROM dbo.[documents];',229),
 (N'runtime',N'runtime:documents:INSERT',N'INSERT dbo.[documents] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:documents:UPDATE',N'UPDATE dbo.[documents] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:documents:DELETE',N'DELETE dbo.[documents] WHERE 1=0;',229),
 (N'runtime',N'runtime:finance_movements:SELECT',N'SELECT TOP(0) * FROM dbo.[finance_movements];',229),
 (N'runtime',N'runtime:finance_movements:INSERT',N'INSERT dbo.[finance_movements] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:finance_movements:UPDATE',N'UPDATE dbo.[finance_movements] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:finance_movements:DELETE',N'DELETE dbo.[finance_movements] WHERE 1=0;',229),
 (N'runtime',N'runtime:stock_lots:SELECT',N'SELECT TOP(0) * FROM dbo.[stock_lots];',229),
 (N'runtime',N'runtime:stock_lots:INSERT',N'INSERT dbo.[stock_lots] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:stock_lots:UPDATE',N'UPDATE dbo.[stock_lots] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:stock_lots:DELETE',N'DELETE dbo.[stock_lots] WHERE 1=0;',229),
 (N'runtime',N'runtime:stock_movements:SELECT',N'SELECT TOP(0) * FROM dbo.[stock_movements];',229),
 (N'runtime',N'runtime:stock_movements:INSERT',N'INSERT dbo.[stock_movements] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:stock_movements:UPDATE',N'UPDATE dbo.[stock_movements] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:stock_movements:DELETE',N'DELETE dbo.[stock_movements] WHERE 1=0;',229),
 (N'runtime',N'runtime:stock_transfers:SELECT',N'SELECT TOP(0) * FROM dbo.[stock_transfers];',229),
 (N'runtime',N'runtime:stock_transfers:INSERT',N'INSERT dbo.[stock_transfers] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:stock_transfers:UPDATE',N'UPDATE dbo.[stock_transfers] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:stock_transfers:DELETE',N'DELETE dbo.[stock_transfers] WHERE 1=0;',229),
 (N'runtime',N'runtime:hospital_resources:SELECT',N'SELECT TOP(0) * FROM dbo.[hospital_resources];',229),
 (N'runtime',N'runtime:hospital_resources:INSERT',N'INSERT dbo.[hospital_resources] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:hospital_resources:UPDATE',N'UPDATE dbo.[hospital_resources] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:hospital_resources:DELETE',N'DELETE dbo.[hospital_resources] WHERE 1=0;',229),
 (N'runtime',N'runtime:admissions:SELECT',N'SELECT TOP(0) * FROM dbo.[admissions];',229),
 (N'runtime',N'runtime:admissions:INSERT',N'INSERT dbo.[admissions] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:admissions:UPDATE',N'UPDATE dbo.[admissions] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:admissions:DELETE',N'DELETE dbo.[admissions] WHERE 1=0;',229),
 (N'runtime',N'runtime:workflow_cases:SELECT',N'SELECT TOP(0) * FROM dbo.[workflow_cases];',229),
 (N'runtime',N'runtime:workflow_cases:INSERT',N'INSERT dbo.[workflow_cases] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:workflow_cases:UPDATE',N'UPDATE dbo.[workflow_cases] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:workflow_cases:DELETE',N'DELETE dbo.[workflow_cases] WHERE 1=0;',229),
 (N'runtime',N'runtime:workflow_history:SELECT',N'SELECT TOP(0) * FROM dbo.[workflow_history];',229),
 (N'runtime',N'runtime:workflow_history:INSERT',N'INSERT dbo.[workflow_history] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:workflow_history:UPDATE',N'UPDATE dbo.[workflow_history] SET [tenant_id]=[tenant_id] WHERE 1=0;',229),
 (N'runtime',N'runtime:workflow_history:DELETE',N'DELETE dbo.[workflow_history] WHERE 1=0;',229),
 (N'runtime',N'runtime:workflow_definitions:SELECT',N'SELECT TOP(0) * FROM dbo.[workflow_definitions];',229),
 (N'runtime',N'runtime:workflow_definitions:INSERT',N'INSERT dbo.[workflow_definitions] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:workflow_definitions:UPDATE',N'UPDATE dbo.[workflow_definitions] SET [type]=[type] WHERE 1=0;',229),
 (N'runtime',N'runtime:workflow_definitions:DELETE',N'DELETE dbo.[workflow_definitions] WHERE 1=0;',229),
 (N'runtime',N'runtime:request_traces:SELECT',N'SELECT TOP(0) * FROM dbo.[request_traces];',229),
 (N'runtime',N'runtime:request_traces:INSERT',N'INSERT dbo.[request_traces] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:request_traces:UPDATE',N'UPDATE dbo.[request_traces] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:request_traces:DELETE',N'DELETE dbo.[request_traces] WHERE 1=0;',229),
 (N'runtime',N'runtime:identity_tokens:SELECT',N'SELECT TOP(0) * FROM dbo.[identity_tokens];',229),
 (N'runtime',N'runtime:identity_tokens:INSERT',N'INSERT dbo.[identity_tokens] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:identity_tokens:UPDATE',N'UPDATE dbo.[identity_tokens] SET [token_hash]=[token_hash] WHERE 1=0;',229),
 (N'runtime',N'runtime:identity_tokens:DELETE',N'DELETE dbo.[identity_tokens] WHERE 1=0;',229),
 (N'runtime',N'runtime:mail_outbox:SELECT',N'SELECT TOP(0) * FROM dbo.[mail_outbox];',229),
 (N'runtime',N'runtime:mail_outbox:INSERT',N'INSERT dbo.[mail_outbox] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:mail_outbox:UPDATE',N'UPDATE dbo.[mail_outbox] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:mail_outbox:DELETE',N'DELETE dbo.[mail_outbox] WHERE 1=0;',229),
 (N'runtime',N'runtime:support_tickets:SELECT',N'SELECT TOP(0) * FROM dbo.[support_tickets];',229),
 (N'runtime',N'runtime:support_tickets:INSERT',N'INSERT dbo.[support_tickets] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:support_tickets:UPDATE',N'UPDATE dbo.[support_tickets] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:support_tickets:DELETE',N'DELETE dbo.[support_tickets] WHERE 1=0;',229),
 (N'runtime',N'runtime:support_comments:SELECT',N'SELECT TOP(0) * FROM dbo.[support_comments];',229),
 (N'runtime',N'runtime:support_comments:INSERT',N'INSERT dbo.[support_comments] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:support_comments:UPDATE',N'UPDATE dbo.[support_comments] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:support_comments:DELETE',N'DELETE dbo.[support_comments] WHERE 1=0;',229),
 (N'runtime',N'runtime:application_state:SELECT',N'SELECT TOP(0) * FROM dbo.[application_state];',229),
 (N'runtime',N'runtime:application_state:INSERT',N'INSERT dbo.[application_state] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:application_state:UPDATE',N'UPDATE dbo.[application_state] SET [id]=[id] WHERE 1=0;',229),
 (N'runtime',N'runtime:application_state:DELETE',N'DELETE dbo.[application_state] WHERE 1=0;',229),
 (N'runtime',N'runtime:health_samples:SELECT',N'SELECT TOP(0) * FROM dbo.[health_samples];',229),
 (N'runtime',N'runtime:health_samples:INSERT',N'INSERT dbo.[health_samples] DEFAULT VALUES;',229),
 (N'runtime',N'runtime:health_samples:UPDATE',N'UPDATE dbo.[health_samples] SET [instance_id]=[instance_id] WHERE 1=0;',229),
 (N'runtime',N'runtime:health_samples:DELETE',N'DELETE dbo.[health_samples] WHERE 1=0;',229),
 (N'runtime',N'runtime:private_helper',N'EXEC dbo.usp_require_actor;',229),
 (N'runtime',N'runtime:private_audit',N'EXEC dbo.usp_audit_change NULL,N''plans'',N''fake'',N''INSERT'',NULL,N''{}'';',229),
 (N'runtime',N'runtime:future_table',N'SELECT TOP(0) id FROM dbo.hp_qa_future_a7;',229),
 (N'runtime',N'runtime:future_procedure',N'EXEC dbo.hp_qa_future_procedure_a7;',229),
 (N'bootstrap',N'bootstrap:users:SELECT',N'SELECT TOP(0) * FROM dbo.[users];',229),
 (N'bootstrap',N'bootstrap:users:INSERT',N'INSERT dbo.[users] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:users:UPDATE',N'UPDATE dbo.[users] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:users:DELETE',N'DELETE dbo.[users] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:plans:SELECT',N'SELECT TOP(0) * FROM dbo.[plans];',229),
 (N'bootstrap',N'bootstrap:plans:INSERT',N'INSERT dbo.[plans] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:plans:UPDATE',N'UPDATE dbo.[plans] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:plans:DELETE',N'DELETE dbo.[plans] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:plan_versions:SELECT',N'SELECT TOP(0) * FROM dbo.[plan_versions];',229),
 (N'bootstrap',N'bootstrap:plan_versions:INSERT',N'INSERT dbo.[plan_versions] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:plan_versions:UPDATE',N'UPDATE dbo.[plan_versions] SET [plan_id]=[plan_id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:plan_versions:DELETE',N'DELETE dbo.[plan_versions] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:tenants:SELECT',N'SELECT TOP(0) * FROM dbo.[tenants];',229),
 (N'bootstrap',N'bootstrap:tenants:INSERT',N'INSERT dbo.[tenants] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:tenants:UPDATE',N'UPDATE dbo.[tenants] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:tenants:DELETE',N'DELETE dbo.[tenants] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:subscriptions:SELECT',N'SELECT TOP(0) * FROM dbo.[subscriptions];',229),
 (N'bootstrap',N'bootstrap:subscriptions:INSERT',N'INSERT dbo.[subscriptions] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:subscriptions:UPDATE',N'UPDATE dbo.[subscriptions] SET [tenant_id]=[tenant_id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:subscriptions:DELETE',N'DELETE dbo.[subscriptions] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:specialties:SELECT',N'SELECT TOP(0) * FROM dbo.[specialties];',229),
 (N'bootstrap',N'bootstrap:specialties:INSERT',N'INSERT dbo.[specialties] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:specialties:UPDATE',N'UPDATE dbo.[specialties] SET [code]=[code] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:specialties:DELETE',N'DELETE dbo.[specialties] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:tenant_specialties:SELECT',N'SELECT TOP(0) * FROM dbo.[tenant_specialties];',229),
 (N'bootstrap',N'bootstrap:tenant_specialties:INSERT',N'INSERT dbo.[tenant_specialties] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:tenant_specialties:UPDATE',N'UPDATE dbo.[tenant_specialties] SET [tenant_id]=[tenant_id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:tenant_specialties:DELETE',N'DELETE dbo.[tenant_specialties] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:branches:SELECT',N'SELECT TOP(0) * FROM dbo.[branches];',229),
 (N'bootstrap',N'bootstrap:branches:INSERT',N'INSERT dbo.[branches] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:branches:UPDATE',N'UPDATE dbo.[branches] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:branches:DELETE',N'DELETE dbo.[branches] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:areas:SELECT',N'SELECT TOP(0) * FROM dbo.[areas];',229),
 (N'bootstrap',N'bootstrap:areas:INSERT',N'INSERT dbo.[areas] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:areas:UPDATE',N'UPDATE dbo.[areas] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:areas:DELETE',N'DELETE dbo.[areas] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:memberships:SELECT',N'SELECT TOP(0) * FROM dbo.[memberships];',229),
 (N'bootstrap',N'bootstrap:memberships:INSERT',N'INSERT dbo.[memberships] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:memberships:UPDATE',N'UPDATE dbo.[memberships] SET [tenant_id]=[tenant_id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:memberships:DELETE',N'DELETE dbo.[memberships] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:membership_branches:SELECT',N'SELECT TOP(0) * FROM dbo.[membership_branches];',229),
 (N'bootstrap',N'bootstrap:membership_branches:INSERT',N'INSERT dbo.[membership_branches] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:membership_branches:UPDATE',N'UPDATE dbo.[membership_branches] SET [tenant_id]=[tenant_id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:membership_branches:DELETE',N'DELETE dbo.[membership_branches] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:membership_specialties:SELECT',N'SELECT TOP(0) * FROM dbo.[membership_specialties];',229),
 (N'bootstrap',N'bootstrap:membership_specialties:INSERT',N'INSERT dbo.[membership_specialties] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:membership_specialties:UPDATE',N'UPDATE dbo.[membership_specialties] SET [tenant_id]=[tenant_id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:membership_specialties:DELETE',N'DELETE dbo.[membership_specialties] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:auth_sessions:SELECT',N'SELECT TOP(0) * FROM dbo.[auth_sessions];',229),
 (N'bootstrap',N'bootstrap:auth_sessions:INSERT',N'INSERT dbo.[auth_sessions] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:auth_sessions:UPDATE',N'UPDATE dbo.[auth_sessions] SET [token_hash]=[token_hash] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:auth_sessions:DELETE',N'DELETE dbo.[auth_sessions] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:audit_events:SELECT',N'SELECT TOP(0) * FROM dbo.[audit_events];',229),
 (N'bootstrap',N'bootstrap:audit_events:INSERT',N'INSERT dbo.[audit_events] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:audit_events:UPDATE',N'UPDATE dbo.[audit_events] SET [tenant_id]=[tenant_id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:audit_events:DELETE',N'DELETE dbo.[audit_events] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:saas_invoices:SELECT',N'SELECT TOP(0) * FROM dbo.[saas_invoices];',229),
 (N'bootstrap',N'bootstrap:saas_invoices:INSERT',N'INSERT dbo.[saas_invoices] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:saas_invoices:UPDATE',N'UPDATE dbo.[saas_invoices] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:saas_invoices:DELETE',N'DELETE dbo.[saas_invoices] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:patients:SELECT',N'SELECT TOP(0) * FROM dbo.[patients];',229),
 (N'bootstrap',N'bootstrap:patients:INSERT',N'INSERT dbo.[patients] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:patients:UPDATE',N'UPDATE dbo.[patients] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:patients:DELETE',N'DELETE dbo.[patients] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:patient_links:SELECT',N'SELECT TOP(0) * FROM dbo.[patient_links];',229),
 (N'bootstrap',N'bootstrap:patient_links:INSERT',N'INSERT dbo.[patient_links] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:patient_links:UPDATE',N'UPDATE dbo.[patient_links] SET [tenant_id]=[tenant_id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:patient_links:DELETE',N'DELETE dbo.[patient_links] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:appointments:SELECT',N'SELECT TOP(0) * FROM dbo.[appointments];',229),
 (N'bootstrap',N'bootstrap:appointments:INSERT',N'INSERT dbo.[appointments] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:appointments:UPDATE',N'UPDATE dbo.[appointments] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:appointments:DELETE',N'DELETE dbo.[appointments] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:encounters:SELECT',N'SELECT TOP(0) * FROM dbo.[encounters];',229),
 (N'bootstrap',N'bootstrap:encounters:INSERT',N'INSERT dbo.[encounters] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:encounters:UPDATE',N'UPDATE dbo.[encounters] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:encounters:DELETE',N'DELETE dbo.[encounters] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:clinical_entries:SELECT',N'SELECT TOP(0) * FROM dbo.[clinical_entries];',229),
 (N'bootstrap',N'bootstrap:clinical_entries:INSERT',N'INSERT dbo.[clinical_entries] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:clinical_entries:UPDATE',N'UPDATE dbo.[clinical_entries] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:clinical_entries:DELETE',N'DELETE dbo.[clinical_entries] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:documents:SELECT',N'SELECT TOP(0) * FROM dbo.[documents];',229),
 (N'bootstrap',N'bootstrap:documents:INSERT',N'INSERT dbo.[documents] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:documents:UPDATE',N'UPDATE dbo.[documents] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:documents:DELETE',N'DELETE dbo.[documents] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:finance_movements:SELECT',N'SELECT TOP(0) * FROM dbo.[finance_movements];',229),
 (N'bootstrap',N'bootstrap:finance_movements:INSERT',N'INSERT dbo.[finance_movements] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:finance_movements:UPDATE',N'UPDATE dbo.[finance_movements] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:finance_movements:DELETE',N'DELETE dbo.[finance_movements] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:stock_lots:SELECT',N'SELECT TOP(0) * FROM dbo.[stock_lots];',229),
 (N'bootstrap',N'bootstrap:stock_lots:INSERT',N'INSERT dbo.[stock_lots] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:stock_lots:UPDATE',N'UPDATE dbo.[stock_lots] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:stock_lots:DELETE',N'DELETE dbo.[stock_lots] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:stock_movements:SELECT',N'SELECT TOP(0) * FROM dbo.[stock_movements];',229),
 (N'bootstrap',N'bootstrap:stock_movements:INSERT',N'INSERT dbo.[stock_movements] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:stock_movements:UPDATE',N'UPDATE dbo.[stock_movements] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:stock_movements:DELETE',N'DELETE dbo.[stock_movements] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:stock_transfers:SELECT',N'SELECT TOP(0) * FROM dbo.[stock_transfers];',229),
 (N'bootstrap',N'bootstrap:stock_transfers:INSERT',N'INSERT dbo.[stock_transfers] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:stock_transfers:UPDATE',N'UPDATE dbo.[stock_transfers] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:stock_transfers:DELETE',N'DELETE dbo.[stock_transfers] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:hospital_resources:SELECT',N'SELECT TOP(0) * FROM dbo.[hospital_resources];',229),
 (N'bootstrap',N'bootstrap:hospital_resources:INSERT',N'INSERT dbo.[hospital_resources] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:hospital_resources:UPDATE',N'UPDATE dbo.[hospital_resources] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:hospital_resources:DELETE',N'DELETE dbo.[hospital_resources] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:admissions:SELECT',N'SELECT TOP(0) * FROM dbo.[admissions];',229),
 (N'bootstrap',N'bootstrap:admissions:INSERT',N'INSERT dbo.[admissions] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:admissions:UPDATE',N'UPDATE dbo.[admissions] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:admissions:DELETE',N'DELETE dbo.[admissions] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:workflow_cases:SELECT',N'SELECT TOP(0) * FROM dbo.[workflow_cases];',229),
 (N'bootstrap',N'bootstrap:workflow_cases:INSERT',N'INSERT dbo.[workflow_cases] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:workflow_cases:UPDATE',N'UPDATE dbo.[workflow_cases] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:workflow_cases:DELETE',N'DELETE dbo.[workflow_cases] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:workflow_history:SELECT',N'SELECT TOP(0) * FROM dbo.[workflow_history];',229),
 (N'bootstrap',N'bootstrap:workflow_history:INSERT',N'INSERT dbo.[workflow_history] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:workflow_history:UPDATE',N'UPDATE dbo.[workflow_history] SET [tenant_id]=[tenant_id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:workflow_history:DELETE',N'DELETE dbo.[workflow_history] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:workflow_definitions:SELECT',N'SELECT TOP(0) * FROM dbo.[workflow_definitions];',229),
 (N'bootstrap',N'bootstrap:workflow_definitions:INSERT',N'INSERT dbo.[workflow_definitions] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:workflow_definitions:UPDATE',N'UPDATE dbo.[workflow_definitions] SET [type]=[type] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:workflow_definitions:DELETE',N'DELETE dbo.[workflow_definitions] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:request_traces:SELECT',N'SELECT TOP(0) * FROM dbo.[request_traces];',229),
 (N'bootstrap',N'bootstrap:request_traces:INSERT',N'INSERT dbo.[request_traces] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:request_traces:UPDATE',N'UPDATE dbo.[request_traces] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:request_traces:DELETE',N'DELETE dbo.[request_traces] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:identity_tokens:SELECT',N'SELECT TOP(0) * FROM dbo.[identity_tokens];',229),
 (N'bootstrap',N'bootstrap:identity_tokens:INSERT',N'INSERT dbo.[identity_tokens] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:identity_tokens:UPDATE',N'UPDATE dbo.[identity_tokens] SET [token_hash]=[token_hash] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:identity_tokens:DELETE',N'DELETE dbo.[identity_tokens] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:mail_outbox:SELECT',N'SELECT TOP(0) * FROM dbo.[mail_outbox];',229),
 (N'bootstrap',N'bootstrap:mail_outbox:INSERT',N'INSERT dbo.[mail_outbox] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:mail_outbox:UPDATE',N'UPDATE dbo.[mail_outbox] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:mail_outbox:DELETE',N'DELETE dbo.[mail_outbox] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:support_tickets:SELECT',N'SELECT TOP(0) * FROM dbo.[support_tickets];',229),
 (N'bootstrap',N'bootstrap:support_tickets:INSERT',N'INSERT dbo.[support_tickets] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:support_tickets:UPDATE',N'UPDATE dbo.[support_tickets] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:support_tickets:DELETE',N'DELETE dbo.[support_tickets] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:support_comments:SELECT',N'SELECT TOP(0) * FROM dbo.[support_comments];',229),
 (N'bootstrap',N'bootstrap:support_comments:INSERT',N'INSERT dbo.[support_comments] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:support_comments:UPDATE',N'UPDATE dbo.[support_comments] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:support_comments:DELETE',N'DELETE dbo.[support_comments] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:application_state:SELECT',N'SELECT TOP(0) * FROM dbo.[application_state];',229),
 (N'bootstrap',N'bootstrap:application_state:INSERT',N'INSERT dbo.[application_state] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:application_state:UPDATE',N'UPDATE dbo.[application_state] SET [id]=[id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:application_state:DELETE',N'DELETE dbo.[application_state] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:health_samples:SELECT',N'SELECT TOP(0) * FROM dbo.[health_samples];',229),
 (N'bootstrap',N'bootstrap:health_samples:INSERT',N'INSERT dbo.[health_samples] DEFAULT VALUES;',229),
 (N'bootstrap',N'bootstrap:health_samples:UPDATE',N'UPDATE dbo.[health_samples] SET [instance_id]=[instance_id] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:health_samples:DELETE',N'DELETE dbo.[health_samples] WHERE 1=0;',229),
 (N'bootstrap',N'bootstrap:private_helper',N'EXEC dbo.usp_require_actor;',229),
 (N'bootstrap',N'bootstrap:private_audit',N'EXEC dbo.usp_audit_change NULL,N''plans'',N''fake'',N''INSERT'',NULL,N''{}'';',229),
 (N'bootstrap',N'bootstrap:future_table',N'SELECT TOP(0) id FROM dbo.hp_qa_future_a7;',229),
 (N'bootstrap',N'bootstrap:future_procedure',N'EXEC dbo.hp_qa_future_procedure_a7;',229),
 (N'runtime',N'runtime:bootstrap_exists',N'EXEC dbo.usp_bootstrap_exists;',229),
 (N'runtime',N'runtime:bootstrap_create',N'EXEC dbo.usp_bootstrap_create ''a7000000-0000-4000-8000-000000000099'',N''qa-denied@example.test'',N''synthetic-not-a-login-hash'';',229),
 (N'bootstrap',N'bootstrap:business',N'EXEC dbo.usp_organization_directory;',229),
 (N'bootstrap',N'bootstrap:health_not_approved',N'EXEC dbo.usp_health_ready;',229);
BEGIN TRANSACTION;
IF N'$(A7Phase)' IN (N'history',N'monitor_unauthorized')
BEGIN
 -- Current baseline has NO real history. This representative exists only in TX.
 CREATE TABLE dbo.flyway_schema_history(installed_rank int NOT NULL PRIMARY KEY,
  version nvarchar(50),description nvarchar(200) NOT NULL,installed_on datetime2(6) NOT NULL,success bit NOT NULL);
 INSERT dbo.flyway_schema_history VALUES(1,N'qa-1',N'Synthetic metadata; NOT Flyway execution',SYSUTCDATETIME(),1);
 INSERT #a7_expected(role_name,object_name,permission_name,permission_state)
 VALUES (N'hp_runtime_executor',N'flyway_schema_history',N'SELECT','D'),
 (N'hp_runtime_executor',N'flyway_schema_history',N'INSERT','D'),
 (N'hp_runtime_executor',N'flyway_schema_history',N'UPDATE','D'),
 (N'hp_runtime_executor',N'flyway_schema_history',N'DELETE','D'),
 (N'hp_bootstrap_executor',N'flyway_schema_history',N'SELECT','D'),
 (N'hp_bootstrap_executor',N'flyway_schema_history',N'INSERT','D'),
 (N'hp_bootstrap_executor',N'flyway_schema_history',N'UPDATE','D'),
 (N'hp_bootstrap_executor',N'flyway_schema_history',N'DELETE','D'),
 (N'hp_runtime_executor',N'flyway_schema_history',N'VIEW DEFINITION','G');
 INSERT #a7_negatives VALUES
 ('runtime',N'runtime:history:SELECT',N'SELECT TOP(0) * FROM dbo.flyway_schema_history;',229),
 ('runtime',N'runtime:history:INSERT',N'INSERT dbo.flyway_schema_history DEFAULT VALUES;',229),
 ('runtime',N'runtime:history:UPDATE',N'UPDATE dbo.flyway_schema_history SET description=description WHERE 1=0;',229),
 ('runtime',N'runtime:history:DELETE',N'DELETE dbo.flyway_schema_history WHERE 1=0;',229),
 ('bootstrap',N'bootstrap:history:SELECT',N'SELECT TOP(0) * FROM dbo.flyway_schema_history;',229),
 ('bootstrap',N'bootstrap:history:INSERT',N'INSERT dbo.flyway_schema_history DEFAULT VALUES;',229),
 ('bootstrap',N'bootstrap:history:UPDATE',N'UPDATE dbo.flyway_schema_history SET description=description WHERE 1=0;',229),
 ('bootstrap',N'bootstrap:history:DELETE',N'DELETE dbo.flyway_schema_history WHERE 1=0;',229),
 ('bootstrap',N'bootstrap:history:monitor',N'EXEC dbo.usp_monitor_migrations;',229);
END;
GO
:r backend/src/main/resources/db/sqlserver/V8__execution_permissions.sql
GO
SET NOCOUNT ON;
SET XACT_ABORT OFF;
DECLARE @impersonating bit=0,@failure nvarchar(2048)=NULL,@caught int,@message nvarchar(2048),
 @case nvarchar(160),@sql nvarchar(max),@expected int,@role varchar(12),@negative_count int=0;
DECLARE @phase nvarchar(40)=N'$(A7Phase)',@permission_count int=CASE WHEN N'$(A7Phase)' IN (N'history',N'monitor_unauthorized') THEN 571 ELSE 562 END;
IF @phase NOT IN (N'normal',N'history')
BEGIN
 BEGIN TRY
  IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 59999,N'Negative phase needs the external transaction',1;
  IF @phase IN (N'ddl_runtime',N'impersonate_runtime',N'monitor_unauthorized')
  BEGIN
   CREATE USER hp_qa_runtime_a7 WITHOUT LOGIN;
   ALTER ROLE hp_runtime_executor ADD MEMBER hp_qa_runtime_a7;
   EXECUTE AS USER=N'hp_qa_runtime_a7';
  END
  ELSE
  BEGIN
   CREATE USER hp_qa_bootstrap_a7 WITHOUT LOGIN;
   ALTER ROLE hp_bootstrap_executor ADD MEMBER hp_qa_bootstrap_a7;
   EXECUTE AS USER=N'hp_qa_bootstrap_a7';
  END;
  SET @impersonating=1; SET XACT_ABORT OFF;
  IF @phase IN (N'scope_exists',N'scope_create',N'monitor_unauthorized') EXEC dbo.usp_request_context @scope='REQUEST';
  IF @phase LIKE N'ddl[_]%' BEGIN SET @expected=262; SET @sql=N'CREATE TABLE dbo.hp_qa_unauthorized_a7(id int);'; END
  ELSE IF @phase LIKE N'impersonate[_]%' BEGIN SET @expected=15517; SET @sql=N'EXECUTE AS USER=N''dbo''; REVERT;'; END
  ELSE IF @phase=N'monitor_unauthorized' BEGIN SET @expected=51001; SET @sql=N'EXEC dbo.usp_monitor_migrations;'; END
  ELSE IF @phase=N'scope_exists' BEGIN SET @expected=51001; SET @sql=N'EXEC dbo.usp_bootstrap_exists;'; END
  ELSE BEGIN SET @expected=51001; SET @sql=N'EXEC dbo.usp_bootstrap_create ''a7000000-0000-4000-8000-000000000099'',N''qa-denied@example.test'',N''synthetic-not-a-login-hash'';'; END;
  SET @caught=NULL;
  BEGIN TRY EXEC sys.sp_executesql @sql; END TRY BEGIN CATCH SET @caught=ERROR_NUMBER(); END CATCH;
  IF @phase=N'monitor_unauthorized' AND (OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NULL OR ISNULL(HAS_PERMS_BY_NAME(N'dbo.flyway_schema_history',N'OBJECT',N'VIEW DEFINITION'),0)<>1) THROW 59999,N'Unauthorized monitor test must have metadata visibility',1;
  IF @caught IS NULL OR @caught<>@expected OR XACT_STATE()<>-1 OR @@TRANCOUNT<>1
  BEGIN SET @message=CONCAT(N'Phase mismatch ',@phase,N' expected ',@expected,N'/state-1/tran1; observed ',COALESCE(CONVERT(nvarchar(20),@caught),N'SUCCESS'),N'/',XACT_STATE(),N'/',@@TRANCOUNT); THROW 59999,@message,1; END;
  PRINT CONCAT(N'PASS doomed phase ',@phase,N': expected error=',@caught,N', XACT_STATE=',XACT_STATE(),N', tran=',@@TRANCOUNT,N'; connection-close rollback; external baseline check REQUIRED');
 END TRY
 BEGIN CATCH
  PRINT CONCAT(N'FAIL doomed phase ',@phase,N': ',ERROR_NUMBER(),N' ',ERROR_MESSAGE(),N'; closing connection, no unsafe REVERT');
  THROW;
 END CATCH;
 RETURN;
END;

BEGIN TRY
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 59999,N'Installation must stay in the external transaction',1;
 IF EXISTS(SELECT role_name,object_name,permission_name,permission_state FROM #a7_expected
  EXCEPT SELECT r.name COLLATE DATABASE_DEFAULT,OBJECT_NAME(p.major_id) COLLATE DATABASE_DEFAULT,p.permission_name COLLATE DATABASE_DEFAULT,p.state COLLATE DATABASE_DEFAULT FROM sys.database_permissions p JOIN sys.database_principals r ON r.principal_id=p.grantee_principal_id WHERE r.name IN (N'hp_runtime_executor',N'hp_bootstrap_executor'))
 OR EXISTS(SELECT r.name COLLATE DATABASE_DEFAULT,OBJECT_NAME(p.major_id) COLLATE DATABASE_DEFAULT,p.permission_name COLLATE DATABASE_DEFAULT,p.state COLLATE DATABASE_DEFAULT FROM sys.database_permissions p JOIN sys.database_principals r ON r.principal_id=p.grantee_principal_id WHERE r.name IN (N'hp_runtime_executor',N'hp_bootstrap_executor')
  EXCEPT SELECT role_name,object_name,permission_name,permission_state FROM #a7_expected)
 OR (SELECT COUNT(*) FROM sys.database_permissions WHERE grantee_principal_id IN (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor')))<>@permission_count
 OR EXISTS(SELECT 1 FROM sys.database_permissions WHERE grantee_principal_id IN (DATABASE_PRINCIPAL_ID(N'hp_runtime_executor'),DATABASE_PRINCIPAL_ID(N'hp_bootstrap_executor')) AND (class<>1 OR minor_id<>0))
  THROW 59999,N'Exact object permission inventory mismatch',1;
 IF (SELECT COUNT(*) FROM sys.database_principals WHERE name IN (N'hp_runtime_executor',N'hp_bootstrap_executor') AND type='R' AND owning_principal_id=DATABASE_PRINCIPAL_ID(N'dbo'))<>2
  THROW 59999,N'Roles must be owned by dbo',1;
 PRINT CONCAT(N'PASS catalog: runtime107 grants/26 denies; bootstrap3 grants/130 denies; total',@permission_count,N' exact object permissions');
 CREATE USER hp_qa_runtime_a7 WITHOUT LOGIN;
 CREATE USER hp_qa_bootstrap_a7 WITHOUT LOGIN;
 ALTER ROLE hp_runtime_executor ADD MEMBER hp_qa_runtime_a7;
 ALTER ROLE hp_bootstrap_executor ADD MEMBER hp_qa_bootstrap_a7;
 CREATE TABLE dbo.hp_qa_future_a7(id int);
 EXEC(N'CREATE PROCEDURE dbo.hp_qa_future_procedure_a7 AS BEGIN SET NOCOUNT ON; SELECT 1 ready; END;');
 -- These future objects deliberately have NO object permission entries.
 DECLARE principal_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT 'runtime' UNION ALL SELECT 'bootstrap';
 OPEN principal_cursor; FETCH NEXT FROM principal_cursor INTO @role;
 WHILE @@FETCH_STATUS=0
 BEGIN
  IF @role='runtime' EXECUTE AS USER=N'hp_qa_runtime_a7';
  ELSE EXECUTE AS USER=N'hp_qa_bootstrap_a7';
  SET @impersonating=1;
  IF EXISTS(SELECT 1 FROM #a7_expected WHERE role_name=CASE @role WHEN 'runtime' THEN N'hp_runtime_executor' ELSE N'hp_bootstrap_executor' END
   AND ISNULL(HAS_PERMS_BY_NAME(N'dbo.'+QUOTENAME(object_name),N'OBJECT',permission_name),0)<>CASE permission_state WHEN 'G' THEN 1 ELSE 0 END)
   THROW 59999,N'Effective object permissions mismatch',1;
  IF ISNULL(IS_ROLEMEMBER(N'db_owner'),0)<>0 OR ISNULL(IS_ROLEMEMBER(N'db_datareader'),0)<>0 OR ISNULL(IS_ROLEMEMBER(N'db_datawriter'),0)<>0 OR ISNULL(IS_ROLEMEMBER(N'db_ddladmin'),0)<>0
   OR EXISTS(SELECT 1 FROM sys.fn_my_permissions(NULL,N'DATABASE') WHERE permission_name IN (N'CONTROL',N'ALTER',N'TAKE OWNERSHIP',N'IMPERSONATE ANY USER',N'EXECUTE',N'SELECT',N'INSERT',N'UPDATE',N'DELETE',N'VIEW DEFINITION',N'VIEW SECURITY DEFINITION',N'VIEW PERFORMANCE DEFINITION') OR permission_name LIKE N'CREATE %' OR permission_name LIKE N'ALTER ANY %')
   OR ISNULL(HAS_PERMS_BY_NAME(N'dbo',N'USER',N'IMPERSONATE'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'dbo.hp_qa_future_a7',N'OBJECT',N'SELECT'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'dbo.hp_qa_future_procedure_a7',N'OBJECT',N'EXECUTE'),0)<>0
   THROW 59999,N'Unexpected broad/fixed-role/impersonation/future permission',1;
  IF @phase=N'history' AND
   ((@role='runtime' AND (OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NULL OR ISNULL(HAS_PERMS_BY_NAME(N'dbo.flyway_schema_history',N'OBJECT',N'VIEW DEFINITION'),0)<>1))
    OR (@role='bootstrap' AND ISNULL(HAS_PERMS_BY_NAME(N'dbo.flyway_schema_history',N'OBJECT',N'VIEW DEFINITION'),0)<>0)
    OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'dbo',N'SCHEMA',N'VIEW DEFINITION'),0)<>0)
    THROW 59999,N'History metadata visibility must be runtime object-only',1;
  REVERT; SET @impersonating=0;
  FETCH NEXT FROM principal_cursor INTO @role;
 END;
 CLOSE principal_cursor; DEALLOCATE principal_cursor;
 PRINT CONCAT(N'PASS effective:',@permission_count,N' object checks; both roles no broad/fixed-role/impersonation/future grants');
 -- Bootstrap is a scoped setup capability, not runtime and not HTTP authentication.
 DECLARE @exists TABLE(id char(36)); DECLARE @sad char(36)='a7000000-0000-4000-8000-000000000001';
 EXECUTE AS USER=N'hp_qa_bootstrap_a7'; SET @impersonating=1;
 EXEC dbo.usp_request_context @scope='BOOTSTRAP';
 INSERT @exists EXEC dbo.usp_bootstrap_exists;
 IF EXISTS(SELECT 1 FROM @exists) THROW 59999,N'Bootstrap baseline must be empty',1;
 EXEC dbo.usp_bootstrap_create @sad,N'qa-a7-admin@example.test',N'synthetic-not-a-login-hash';
 INSERT @exists EXEC dbo.usp_bootstrap_exists;
 IF (SELECT COUNT(*) FROM @exists)<>1 OR NOT EXISTS(SELECT 1 FROM @exists WHERE id=@sad) THROW 59999,N'Bootstrap create/exists failed',1;
 EXEC dbo.usp_bootstrap_create 'a7000000-0000-4000-8000-000000000099',N'qa-a7-unused@example.test',N'synthetic-not-a-login-hash';
 REVERT; SET @impersonating=0; SET XACT_ABORT OFF;
 IF (SELECT COUNT(*) FROM dbo.users WHERE platform_role='SAD')<>1 THROW 59999,N'Bootstrap repeat duplicated administrator',1;
 PRINT N'PASS bootstrap: scoped exists/create/repeat; private scope helper and users/audit ownership chain';
 -- Admin creates SYNTHETIC tenant actor/session only, all in this same TX.
 EXEC dbo.usp_request_context;
 DECLARE @actor char(36)='a7000000-0000-4000-8000-000000000002',@tenant char(36)='a7000000-0000-4000-8000-000000000003',
  @branch char(36)='a7000000-0000-4000-8000-000000000004',@request char(36)='a7000000-0000-4000-8000-000000000010',
  @token char(64)=REPLICATE('a',64);
 INSERT dbo.users(id,name,email,password_hash,clinical_domain) VALUES(@actor,N'Synthetic QA ADM',N'qa-a7-adm@example.test',N'synthetic-not-a-login-hash',N'HUMAN');
 INSERT dbo.tenants(id,name,slug,kind,domain,status,owner_user_id) VALUES(@tenant,N'Synthetic QA tenant','qa-a7-tenant','CLINIC','HUMAN','ACTIVE',@actor);
 INSERT dbo.subscriptions(tenant_id,plan_id,plan_version,cycle,branch_quota,professional_quota,specialty_quota,renewal_date)
 SELECT @tenant,id,current_version,'MONTHLY',2,1,1,'2099-01-01' FROM dbo.plans WHERE id='00000000-0000-0000-0000-000000000002';
 INSERT dbo.memberships(tenant_id,user_id,roles,status,owner) VALUES(@tenant,@actor,N'["ADM"]','ACTIVE',1);
 INSERT dbo.auth_sessions(token_hash,user_id,tenant_id,expires_at) VALUES(@token,@actor,@tenant,DATEADD(hour,1,SYSUTCDATETIME()));
 DECLARE @health TABLE(ready int); DECLARE @status TABLE(mode nvarchar(11),message nvarchar(300),revision int);
 DECLARE @branch_result TABLE(id char(36),tenant_id char(36),name nvarchar(160),address nvarchar(300),[external] bit,active bit);
 DECLARE @directory TABLE(id char(36),name nvarchar(160),address nvarchar(300),[external] bit,active bit);
 EXECUTE AS USER=N'hp_qa_runtime_a7'; SET @impersonating=1;
 EXEC dbo.usp_request_context @request_id=@request,@method=N'POST',@route=N'/api/tenant/branches',
  @actor_id=@actor,@actor_roles=N'["ADM"]',@tenant_id=@tenant,@token_hash=@token,@scope='REQUEST';
 INSERT @health EXEC dbo.usp_health_ready;
 INSERT @status EXEC dbo.usp_application_status;
 IF NOT EXISTS(SELECT 1 FROM @health WHERE ready=1) OR NOT EXISTS(SELECT 1 FROM @status WHERE mode='OPEN') THROW 59999,N'Runtime public readiness/status failed',1;
 INSERT @branch_result EXEC dbo.usp_organization_branch_save @tenant,@branch,N'{"name":"Synthetic QA branch","address":"Synthetic only","external":false,"active":true}',@create=1;
 INSERT @directory EXEC dbo.usp_organization_directory;
 IF NOT EXISTS(SELECT 1 FROM @branch_result WHERE id=@branch AND tenant_id=@tenant AND active=1)
  OR NOT EXISTS(SELECT 1 FROM @directory WHERE id=@branch AND name=N'Synthetic QA branch') THROW 59999,N'Runtime business create/read failed',1;
 REVERT; SET @impersonating=0; SET XACT_ABORT OFF;
 IF NOT EXISTS(SELECT 1 FROM dbo.audit_events WHERE resource_type=N'branches' AND target_id=@branch AND tenant_id=@tenant AND actor_id=@actor AND request_id=@request AND JSON_VALUE(metadata,'$.operation')='INSERT')
  OR NOT EXISTS(SELECT 1 FROM dbo.audit_events WHERE action='BRANCH_SAVED' AND target_id=@branch AND tenant_id=@tenant AND actor_id=@actor AND request_id=@request)
  THROW 59999,N'Business/private audit/trigger context chain failed',1;
 PRINT N'PASS runtime: context/ready/status + authenticated ADM branch create + directory SP + scoped audit via ownership chain';
 IF @phase=N'history'
 BEGIN
  -- Authenticated platform SAD and SOP: real DB session/identity, no tenant host.
  DECLARE @sop char(36)='a7000000-0000-4000-8000-000000000020',@ptoken char(64),
   @platform_actor char(36),@platform_role nvarchar(3);
  DECLARE @migrations TABLE(version nvarchar(50),description nvarchar(200),installed_on datetime2(6),success bit);
  INSERT dbo.users(id,name,email,password_hash,platform_role) VALUES(@sop,N'Synthetic QA SOP',N'qa-a7-sop@example.test',N'synthetic-not-a-login-hash',N'SOP');
  INSERT dbo.auth_sessions(token_hash,user_id,tenant_id,expires_at)
   VALUES(REPLICATE('c',64),@sad,NULL,DATEADD(hour,1,SYSUTCDATETIME())),(REPLICATE('d',64),@sop,NULL,DATEADD(hour,1,SYSUTCDATETIME()));
  DECLARE history_actor_cursor CURSOR LOCAL FAST_FORWARD FOR
   SELECT @sad,CONVERT(char(64),REPLICATE('c',64)),N'SAD' UNION ALL SELECT @sop,CONVERT(char(64),REPLICATE('d',64)),N'SOP';
  OPEN history_actor_cursor; FETCH NEXT FROM history_actor_cursor INTO @platform_actor,@ptoken,@platform_role;
  WHILE @@FETCH_STATUS=0
  BEGIN
   DELETE @migrations;
   EXECUTE AS USER=N'hp_qa_runtime_a7'; SET @impersonating=1;
   DECLARE @trusted_roles nvarchar(max)=CASE WHEN @platform_role=N'SAD' THEN N'["SAD"]' ELSE N'["SOP"]' END;
   EXEC dbo.usp_request_context @actor_id=@platform_actor,@actor_roles=@trusted_roles,@tenant_id=NULL,@token_hash=@ptoken,@scope='REQUEST';
   INSERT @migrations EXEC dbo.usp_monitor_migrations;
   DECLARE @history_rows int=(SELECT COUNT(*) FROM @migrations);
   PRINT CONCAT(N'HISTORY CHECK: metadataVisible=',CASE WHEN OBJECT_ID(N'dbo.flyway_schema_history',N'U') IS NULL THEN 0 ELSE 1 END,N', SP rows=',@history_rows);
   IF (SELECT COUNT(*) FROM @migrations)<>1 OR NOT EXISTS(SELECT 1 FROM @migrations WHERE version=N'qa-1' AND description=N'Synthetic metadata; NOT Flyway execution' AND success=1 AND installed_on IS NOT NULL)
    THROW 59999,N'Platform history SP result mismatch',1;
   REVERT; SET @impersonating=0; SET XACT_ABORT OFF;
   PRINT CONCAT(N'PASS history runtime authenticated ',@platform_role,N': usp_monitor_migrations synthetic row through dbo ownership chain');
   FETCH NEXT FROM history_actor_cursor INTO @platform_actor,@ptoken,@platform_role;
  END;
  CLOSE history_actor_cursor; DEALLOCATE history_actor_cursor;
 END;

 -- Fixed literal negative cases:37 tables x4 operations x2 roles, plus helpers,
 -- bootstrap, business, DDL, impersonation and newly created future objects.
 DECLARE negative_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT role_name,case_name,sql_text,expected_error FROM #a7_negatives ORDER BY role_name,case_name;
 OPEN negative_cursor; FETCH NEXT FROM negative_cursor INTO @role,@case,@sql,@expected;
 WHILE @@FETCH_STATUS=0
 BEGIN
  IF @role='runtime' EXECUTE AS USER=N'hp_qa_runtime_a7';
  ELSE EXECUTE AS USER=N'hp_qa_bootstrap_a7';
  SET @impersonating=1; SET XACT_ABORT OFF; SET @caught=NULL;
  IF @role='runtime' AND @case LIKE N'runtime:bootstrap[_]%' EXEC dbo.usp_request_context @scope='BOOTSTRAP';
  BEGIN TRY EXEC sys.sp_executesql @sql; END TRY
  BEGIN CATCH SET @caught=ERROR_NUMBER(); END CATCH;
  IF XACT_STATE()<>1 THROW 59999,N'Unexpected doomed normal case; close connection and verify baseline',1;
  REVERT; SET @impersonating=0;
  IF @caught IS NULL OR @caught<>@expected BEGIN
   SET @message=CONCAT(N'Negative mismatch ',@case,N' expected ',@expected,N' observed ',COALESCE(CONVERT(nvarchar(20),@caught),N'SUCCESS'));
   THROW 59999,@message,1;
  END;
  IF XACT_STATE()<>1 THROW 59999,N'Expected permission error doomed the outer transaction',1;
  SET @negative_count+=1;
  FETCH NEXT FROM negative_cursor INTO @role,@case,@sql,@expected;
 END;
 CLOSE negative_cursor; DEALLOCATE negative_cursor;
 PRINT CONCAT(N'PASS negative errors: ',@negative_count,N' cases (ALL expected permission229; real DDL/impersonation/scope in separate phases)');
 ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
 SET @failure=CONCAT(N'A7 FAIL ',ERROR_NUMBER(),N': ',ERROR_MESSAGE());
 IF @impersonating=1 AND XACT_STATE()<>1 THROW;
 IF @impersonating=1 BEGIN REVERT; SET @impersonating=0; END;
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
END CATCH;
-- OUTSIDE transaction: verify full cleanup even after a caught failure.
EXEC dbo.usp_request_context;
IF @@TRANCOUNT<>0 OR EXISTS(SELECT 1 FROM sys.database_principals WHERE name IN (N'hp_runtime_executor',N'hp_bootstrap_executor',N'hp_qa_runtime_a7',N'hp_qa_bootstrap_a7'))
 OR OBJECT_ID(N'dbo.hp_qa_future_a7') IS NOT NULL OR OBJECT_ID(N'dbo.hp_qa_future_procedure_a7') IS NOT NULL OR OBJECT_ID(N'dbo.hp_qa_unauthorized_a7') IS NOT NULL OR OBJECT_ID(N'dbo.flyway_schema_history') IS NOT NULL OR OBJECT_ID(N'dbo.hp_qa_unknown_history_a7') IS NOT NULL
 THROW 59999,N'CLEANUP FAIL: transaction/principals/future objects remain',1;
IF EXISTS(SELECT name,definition_fingerprint FROM #a7_procedures_before EXCEPT SELECT name,HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(object_id))) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo'))
 OR (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo'))<>133
 OR EXISTS(SELECT name,definition_fingerprint FROM #a7_triggers_before EXCEPT SELECT name,HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(object_id))) FROM sys.triggers WHERE parent_class=1)
 OR (SELECT COUNT(*) FROM sys.triggers WHERE parent_class=1)<>31
 THROW 59999,N'CLEANUP FAIL: procedure/bootstrap or trigger definitions changed',1;
IF EXISTS(SELECT name,n FROM #a7_counts_before EXCEPT SELECT name,n FROM (
 SELECT N'users' name,COUNT_BIG(*) n FROM dbo.[users]
 UNION ALL
 SELECT N'plans' name,COUNT_BIG(*) n FROM dbo.[plans]
 UNION ALL
 SELECT N'plan_versions' name,COUNT_BIG(*) n FROM dbo.[plan_versions]
 UNION ALL
 SELECT N'tenants' name,COUNT_BIG(*) n FROM dbo.[tenants]
 UNION ALL
 SELECT N'subscriptions' name,COUNT_BIG(*) n FROM dbo.[subscriptions]
 UNION ALL
 SELECT N'specialties' name,COUNT_BIG(*) n FROM dbo.[specialties]
 UNION ALL
 SELECT N'tenant_specialties' name,COUNT_BIG(*) n FROM dbo.[tenant_specialties]
 UNION ALL
 SELECT N'branches' name,COUNT_BIG(*) n FROM dbo.[branches]
 UNION ALL
 SELECT N'areas' name,COUNT_BIG(*) n FROM dbo.[areas]
 UNION ALL
 SELECT N'memberships' name,COUNT_BIG(*) n FROM dbo.[memberships]
 UNION ALL
 SELECT N'membership_branches' name,COUNT_BIG(*) n FROM dbo.[membership_branches]
 UNION ALL
 SELECT N'membership_specialties' name,COUNT_BIG(*) n FROM dbo.[membership_specialties]
 UNION ALL
 SELECT N'auth_sessions' name,COUNT_BIG(*) n FROM dbo.[auth_sessions]
 UNION ALL
 SELECT N'audit_events' name,COUNT_BIG(*) n FROM dbo.[audit_events]
 UNION ALL
 SELECT N'saas_invoices' name,COUNT_BIG(*) n FROM dbo.[saas_invoices]
 UNION ALL
 SELECT N'patients' name,COUNT_BIG(*) n FROM dbo.[patients]
 UNION ALL
 SELECT N'patient_links' name,COUNT_BIG(*) n FROM dbo.[patient_links]
 UNION ALL
 SELECT N'appointments' name,COUNT_BIG(*) n FROM dbo.[appointments]
 UNION ALL
 SELECT N'encounters' name,COUNT_BIG(*) n FROM dbo.[encounters]
 UNION ALL
 SELECT N'clinical_entries' name,COUNT_BIG(*) n FROM dbo.[clinical_entries]
 UNION ALL
 SELECT N'documents' name,COUNT_BIG(*) n FROM dbo.[documents]
 UNION ALL
 SELECT N'finance_movements' name,COUNT_BIG(*) n FROM dbo.[finance_movements]
 UNION ALL
 SELECT N'stock_lots' name,COUNT_BIG(*) n FROM dbo.[stock_lots]
 UNION ALL
 SELECT N'stock_movements' name,COUNT_BIG(*) n FROM dbo.[stock_movements]
 UNION ALL
 SELECT N'stock_transfers' name,COUNT_BIG(*) n FROM dbo.[stock_transfers]
 UNION ALL
 SELECT N'hospital_resources' name,COUNT_BIG(*) n FROM dbo.[hospital_resources]
 UNION ALL
 SELECT N'admissions' name,COUNT_BIG(*) n FROM dbo.[admissions]
 UNION ALL
 SELECT N'workflow_cases' name,COUNT_BIG(*) n FROM dbo.[workflow_cases]
 UNION ALL
 SELECT N'workflow_history' name,COUNT_BIG(*) n FROM dbo.[workflow_history]
 UNION ALL
 SELECT N'workflow_definitions' name,COUNT_BIG(*) n FROM dbo.[workflow_definitions]
 UNION ALL
 SELECT N'request_traces' name,COUNT_BIG(*) n FROM dbo.[request_traces]
 UNION ALL
 SELECT N'identity_tokens' name,COUNT_BIG(*) n FROM dbo.[identity_tokens]
 UNION ALL
 SELECT N'mail_outbox' name,COUNT_BIG(*) n FROM dbo.[mail_outbox]
 UNION ALL
 SELECT N'support_tickets' name,COUNT_BIG(*) n FROM dbo.[support_tickets]
 UNION ALL
 SELECT N'support_comments' name,COUNT_BIG(*) n FROM dbo.[support_comments]
 UNION ALL
 SELECT N'application_state' name,COUNT_BIG(*) n FROM dbo.[application_state]
 UNION ALL
 SELECT N'health_samples' name,COUNT_BIG(*) n FROM dbo.[health_samples]
) c) OR (SELECT COUNT(*) FROM sys.tables WHERE schema_id=SCHEMA_ID(N'dbo'))<>37
 THROW 59999,N'CLEANUP FAIL: business rows/catalog changed',1;
PRINT N'PASS cleanup: rollback verified outside TX;37 table counts,133 original SP definitions,31 triggers,0 product roles/QA users/future objects';
IF @failure IS NOT NULL THROW 59999,@failure,1;
PRINT CONCAT(N'A7 ',UPPER(@phase),N' PASS; SQL2022 EXECUTE AS WITHOUT LOGIN; history only simulated, no Flyway/login/JDBC/HTTP claim');
GO

-- A7_RUNNER_BEGIN
/*
import subprocess,re,json
from pathlib import Path
baseline_sql="SET NOCOUNT ON;\nIF DB_NAME()<>N'health_project_sqlserver_qa_20261103' THROW 59999,N'Wrong QA database',1;\nIF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'health_project_scope' AND CONVERT(nvarchar(max),value)=N'Health Project synthetic SQL Server migration QA; provisioned 2026-11-03; no real data') THROW 59999,N'Wrong QA marker',1;\nIF DATABASE_PRINCIPAL_ID(N'dbo') IS NULL OR @@TRANCOUNT<>0\n OR (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo'))<>133\n OR (SELECT COUNT(*) FROM sys.triggers WHERE parent_class=1)<>31\n OR (SELECT COUNT(*) FROM sys.tables WHERE schema_id=SCHEMA_ID(N'dbo'))<>37 OR EXISTS(SELECT 1 FROM dbo.users)\n OR EXISTS(SELECT 1 FROM sys.database_principals WHERE name IN (N'hp_runtime_executor',N'hp_bootstrap_executor',N'hp_qa_runtime_a7',N'hp_qa_bootstrap_a7'))\n OR OBJECT_ID(N'dbo.hp_qa_future_a7') IS NOT NULL OR OBJECT_ID(N'dbo.hp_qa_future_procedure_a7') IS NOT NULL OR OBJECT_ID(N'dbo.hp_qa_unauthorized_a7') IS NOT NULL OR OBJECT_ID(N'dbo.flyway_schema_history') IS NOT NULL OR OBJECT_ID(N'dbo.hp_qa_unknown_history_a7') IS NOT NULL THROW 59999,N'Baseline/cleanup mismatch',1;\nDECLARE @counts nvarchar(max)=(SELECT name,n FROM (SELECT N'users' name,COUNT_BIG(*) n FROM dbo.[users]\nUNION ALL\nSELECT N'plans' name,COUNT_BIG(*) n FROM dbo.[plans]\nUNION ALL\nSELECT N'plan_versions' name,COUNT_BIG(*) n FROM dbo.[plan_versions]\nUNION ALL\nSELECT N'tenants' name,COUNT_BIG(*) n FROM dbo.[tenants]\nUNION ALL\nSELECT N'subscriptions' name,COUNT_BIG(*) n FROM dbo.[subscriptions]\nUNION ALL\nSELECT N'specialties' name,COUNT_BIG(*) n FROM dbo.[specialties]\nUNION ALL\nSELECT N'tenant_specialties' name,COUNT_BIG(*) n FROM dbo.[tenant_specialties]\nUNION ALL\nSELECT N'branches' name,COUNT_BIG(*) n FROM dbo.[branches]\nUNION ALL\nSELECT N'areas' name,COUNT_BIG(*) n FROM dbo.[areas]\nUNION ALL\nSELECT N'memberships' name,COUNT_BIG(*) n FROM dbo.[memberships]\nUNION ALL\nSELECT N'membership_branches' name,COUNT_BIG(*) n FROM dbo.[membership_branches]\nUNION ALL\nSELECT N'membership_specialties' name,COUNT_BIG(*) n FROM dbo.[membership_specialties]\nUNION ALL\nSELECT N'auth_sessions' name,COUNT_BIG(*) n FROM dbo.[auth_sessions]\nUNION ALL\nSELECT N'audit_events' name,COUNT_BIG(*) n FROM dbo.[audit_events]\nUNION ALL\nSELECT N'saas_invoices' name,COUNT_BIG(*) n FROM dbo.[saas_invoices]\nUNION ALL\nSELECT N'patients' name,COUNT_BIG(*) n FROM dbo.[patients]\nUNION ALL\nSELECT N'patient_links' name,COUNT_BIG(*) n FROM dbo.[patient_links]\nUNION ALL\nSELECT N'appointments' name,COUNT_BIG(*) n FROM dbo.[appointments]\nUNION ALL\nSELECT N'encounters' name,COUNT_BIG(*) n FROM dbo.[encounters]\nUNION ALL\nSELECT N'clinical_entries' name,COUNT_BIG(*) n FROM dbo.[clinical_entries]\nUNION ALL\nSELECT N'documents' name,COUNT_BIG(*) n FROM dbo.[documents]\nUNION ALL\nSELECT N'finance_movements' name,COUNT_BIG(*) n FROM dbo.[finance_movements]\nUNION ALL\nSELECT N'stock_lots' name,COUNT_BIG(*) n FROM dbo.[stock_lots]\nUNION ALL\nSELECT N'stock_movements' name,COUNT_BIG(*) n FROM dbo.[stock_movements]\nUNION ALL\nSELECT N'stock_transfers' name,COUNT_BIG(*) n FROM dbo.[stock_transfers]\nUNION ALL\nSELECT N'hospital_resources' name,COUNT_BIG(*) n FROM dbo.[hospital_resources]\nUNION ALL\nSELECT N'admissions' name,COUNT_BIG(*) n FROM dbo.[admissions]\nUNION ALL\nSELECT N'workflow_cases' name,COUNT_BIG(*) n FROM dbo.[workflow_cases]\nUNION ALL\nSELECT N'workflow_history' name,COUNT_BIG(*) n FROM dbo.[workflow_history]\nUNION ALL\nSELECT N'workflow_definitions' name,COUNT_BIG(*) n FROM dbo.[workflow_definitions]\nUNION ALL\nSELECT N'request_traces' name,COUNT_BIG(*) n FROM dbo.[request_traces]\nUNION ALL\nSELECT N'identity_tokens' name,COUNT_BIG(*) n FROM dbo.[identity_tokens]\nUNION ALL\nSELECT N'mail_outbox' name,COUNT_BIG(*) n FROM dbo.[mail_outbox]\nUNION ALL\nSELECT N'support_tickets' name,COUNT_BIG(*) n FROM dbo.[support_tickets]\nUNION ALL\nSELECT N'support_comments' name,COUNT_BIG(*) n FROM dbo.[support_comments]\nUNION ALL\nSELECT N'application_state' name,COUNT_BIG(*) n FROM dbo.[application_state]\nUNION ALL\nSELECT N'health_samples' name,COUNT_BIG(*) n FROM dbo.[health_samples]) c ORDER BY name FOR JSON PATH);\nDECLARE @sp nvarchar(max)=(SELECT name,CONVERT(char(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(object_id))),2) fingerprint FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo') ORDER BY name FOR JSON PATH);\nDECLARE @tr nvarchar(max)=(SELECT name,CONVERT(char(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(object_id))),2) fingerprint FROM sys.triggers WHERE parent_class=1 ORDER BY name FOR JSON PATH);\nDECLARE @permissions nvarchar(max)=(SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions ORDER BY class,major_id,minor_id,grantee_principal_id,type FOR JSON PATH);\nDECLARE @all nvarchar(max)=@counts+N'|'+@sp+N'|'+@tr+N'|'+@permissions;\nSELECT CONVERT(char(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),@all)),2) baseline_fingerprint;"
common=['sqlcmd','-S','localhost','-E','-C','-b','-f','65001','-d','health_project_sqlserver_qa_20261103']
def baseline():
 r=subprocess.run(common+['-h','-1','-W','-Q',baseline_sql],capture_output=True,encoding='utf-8')
 if r.returncode:raise RuntimeError('BASELINE FAIL '+r.stdout+r.stderr)
 matches=re.findall(r'(?m)^[A-F0-9]{64}$',r.stdout.strip());assert len(matches)==1,r.stdout
 return matches[0]
def unknown_script():
 # Exact product first batch contains EVERY precondition before ANY role/ACL/ALTER.
 # No product SQL rewriting, generated helper file, or persistent helper object.
 migration=Path('backend/src/main/resources/db/sqlserver/V8__execution_permissions.sql').read_text('utf-8')
 prefix=re.split(r'^GO\s*$',migration,flags=re.M)[0]
 assert 'CREATE ROLE hp_runtime_executor' in prefix and 'ALTER PROCEDURE' not in prefix
 guards=baseline_sql.split('DECLARE @counts',1)[0]
 return ':On Error exit\n'+guards+"""
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET XACT_ABORT ON;
DECLARE @original_user sysname=USER_NAME(),@observed int=NULL,@observed_message nvarchar(2048);
SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state INTO #u_before_permissions FROM sys.database_permissions;
SELECT object_id,HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(object_id))) fingerprint INTO #u_before_definitions FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo');
BEGIN TRANSACTION;
CREATE TABLE dbo.hp_qa_unknown_history_a7(id int PRIMARY KEY);
BEGIN TRY
"""+prefix+"""
END TRY
BEGIN CATCH
 SET @observed=ERROR_NUMBER(); SET @observed_message=ERROR_MESSAGE();
END CATCH;
IF @observed IS NULL OR @observed<>51000 OR @observed_message<>N'HP_INVALID:Expected37 approved business tables and only optional flyway_schema_history'
 THROW 59999,N'Unknown table must fail the exact catalog precondition51000',1;
IF XACT_STATE()<>-1 OR @@TRANCOUNT<>1 OR USER_NAME()<>@original_user
 THROW 59999,N'Unknown table test transaction/admin context mismatch',1;
IF EXISTS(SELECT 1 FROM sys.database_principals WHERE name IN (N'hp_runtime_executor',N'hp_bootstrap_executor',N'hp_qa_runtime_a7',N'hp_qa_bootstrap_a7'))
 OR EXISTS(SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM #u_before_permissions EXCEPT SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions)
 OR EXISTS(SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM sys.database_permissions EXCEPT SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state FROM #u_before_permissions)
 OR EXISTS(SELECT object_id,fingerprint FROM #u_before_definitions EXCEPT SELECT object_id,HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(object_id))) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo'))
 OR (SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo'))<>133
 THROW 59999,N'Unknown table caused a role/permission/SP mutation before rejection',1;
PRINT N'PASS unknown_table: exact51000 BEFORE roles/ACL/SP changes; admin context retained; XACT_STATE=-1';
ROLLBACK TRANSACTION;
IF @@TRANCOUNT<>0 OR OBJECT_ID(N'dbo.hp_qa_unknown_history_a7') IS NOT NULL THROW 59999,N'Unknown table rollback failed',1;
PRINT N'A7 UNKNOWN_TABLE PASS; rollback performed; NEW-connection baseline check REQUIRED';
GO
"""
original=baseline();print('BASELINE',original,flush=True)
results=[]
phases=['normal','ddl_runtime','ddl_bootstrap','impersonate_runtime','impersonate_bootstrap','scope_exists','scope_create','history','unknown_table','monitor_unauthorized']
for phase in phases:
 before=baseline();assert before==original,(phase,'before changed',before)
 if phase=='unknown_table':
  r=subprocess.run(common,input=unknown_script(),capture_output=True,encoding='utf-8')
 else:
  r=subprocess.run(common+['-v','A7Phase='+phase,'-i','backend/scripts/verify-sqlserver-permissions.sql'],capture_output=True,encoding='utf-8')
 print('PHASE',phase,'EXIT',r.returncode,flush=True);print(r.stdout,flush=True)
 if r.stderr:print(r.stderr,flush=True)
 after=baseline();assert after==original,(phase,'after changed',after)
 print('CLEANUP new connection',phase,after,flush=True)
 results.append({'phase':phase,'exit':r.returncode,'before':before,'after':after,'stdout':r.stdout,'stderr':r.stderr})
 if phase in ('normal','history','unknown_table'):
  assert r.returncode==0,(phase,'failure',r.returncode)
  assert 'A7 '+phase.upper()+' PASS' in r.stdout
 else:
  numbers=re.findall(r'Msg (\d+),',r.stdout+r.stderr)
  assert r.returncode==1 and numbers==['3998'],('unexpected negative exit/errors',r.returncode,numbers)
  assert 'FAIL doomed phase' not in r.stdout and 'PASS doomed phase '+phase in r.stdout
print('ALL10_PHASES_PASS',json.dumps(results,ensure_ascii=True),flush=True)

*/
-- A7_RUNNER_END
