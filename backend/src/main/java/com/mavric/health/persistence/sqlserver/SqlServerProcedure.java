package com.mavric.health.persistence.sqlserver;

import java.sql.JDBCType;
import java.time.Instant;
import java.util.Collections;
import java.util.List;

/** Closed V3-V6 input contracts approved by V8; SQL defaults are explicit caller arguments. */
public enum SqlServerProcedure {
    // V3 / runtime; arguments stay positional, including SQL defaults.
    TENANT_BY_SLUG("usp_tenant_by_slug",
            input("slug", JDBCType.VARCHAR, 63, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    HEALTH_READY("usp_health_ready"),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    APPLICATION_STATUS("usp_application_status"),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    IDENTITY_CREDENTIALS("usp_identity_credentials",
            input("email", JDBCType.NVARCHAR, 254, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    SESSION_RESOLVE("usp_session_resolve",
            input("token_hash", JDBCType.CHAR, 64, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    SESSION_SAVE("usp_session_save",
            input("token_hash", JDBCType.CHAR, 64, null),
            input("user_id", JDBCType.CHAR, 36, null),
            input("expires_at", JDBCType.TIMESTAMP, 6, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    SESSION_CURRENT("usp_session_current"),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    IDENTITY_MEMBERSHIP("usp_identity_membership",
            input("user_id", JDBCType.CHAR, 36, null),
            input("tenant_id", JDBCType.CHAR, 36, null),
            input("active_only", JDBCType.BIT, 0, "1")),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    SUPPORT_DETAIL("usp_support_detail",
            input("ticket_id", JDBCType.CHAR, 36, null)),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    ORGANIZATION_CONFIGURATION("usp_organization_configuration",
            input("tenant_id", JDBCType.CHAR, 36, null)),
    // V3 / bootstrap; arguments stay positional, including SQL defaults.
    BOOTSTRAP_EXISTS("usp_bootstrap_exists"),
    // V3 / bootstrap; arguments stay positional, including SQL defaults.
    BOOTSTRAP_CREATE("usp_bootstrap_create",
            input("id", JDBCType.CHAR, 36, null),
            input("email", JDBCType.NVARCHAR, 254, null),
            input("password_hash", JDBCType.NVARCHAR, 100, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    REGISTRATION_PLANS("usp_registration_plans"),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    REGISTRATION_SPECIALTIES("usp_registration_specialties"),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    REGISTRATION_PLAN("usp_registration_plan",
            input("plan_id", JDBCType.CHAR, 36, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    IDENTITY_ACCOUNT_LOOKUP("usp_identity_account_lookup",
            input("email", JDBCType.NVARCHAR, 254, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    IDENTITY_EMAIL_EXISTS("usp_identity_email_exists",
            input("email", JDBCType.NVARCHAR, 254, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    USER_CREATE("usp_user_create",
            input("id", JDBCType.CHAR, 36, null),
            input("name", JDBCType.NVARCHAR, 160, null),
            input("email", JDBCType.NVARCHAR, 254, null),
            input("password_hash", JDBCType.NVARCHAR, 100, null),
            input("domain", JDBCType.NVARCHAR, 6, "NULL"),
            input("credential", JDBCType.NVARCHAR, 100, "NULL")),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    IDENTITY_PENDING("usp_identity_pending",
            input("user_id", JDBCType.CHAR, 36, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    IDENTITY_PASSWORD_HASH("usp_identity_password_hash"),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    PASSWORD_CHANGE("usp_password_change",
            input("password_hash", JDBCType.NVARCHAR, 100, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    SESSIONS_LIST("usp_sessions_list"),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    SESSION_REVOKE("usp_session_revoke",
            input("session_id", JDBCType.CHAR, 64, "NULL")),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    SESSION_TOUCH("usp_session_touch"),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    LOGIN_FAILURE("usp_login_failure",
            input("user_id", JDBCType.CHAR, 36, "NULL")),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    IDENTITY_ISSUE("usp_identity_issue",
            input("token_hash", JDBCType.CHAR, 64, null),
            input("user_id", JDBCType.CHAR, 36, null),
            input("purpose", JDBCType.NVARCHAR, 6, null),
            input("expires_at", JDBCType.TIMESTAMP, 6, null),
            input("mail_id", JDBCType.CHAR, 36, null),
            input("subject", JDBCType.NVARCHAR, 200, null),
            input("body", JDBCType.NVARCHAR, -1, null),
            input("registration_tenant", JDBCType.CHAR, 36, "NULL")),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    IDENTITY_REDEEM("usp_identity_redeem",
            input("token_hash", JDBCType.CHAR, 64, null),
            input("purpose", JDBCType.NVARCHAR, 6, null),
            input("password_hash", JDBCType.NVARCHAR, 100, "NULL")),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    PORTAL_REGISTER("usp_portal_register",
            input("user_id", JDBCType.CHAR, 36, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    INVITATION_ACCEPT("usp_invitation_accept",
            input("user_id", JDBCType.CHAR, 36, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    ACCESS_BRANCH("usp_access_branch",
            input("branch_id", JDBCType.CHAR, 36, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    ACCESS_PATIENT_LINK("usp_access_patient_link",
            input("patient_id", JDBCType.CHAR, 36, null),
            input("scope", JDBCType.NVARCHAR, 80, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    MAIL_CLAIM("usp_mail_claim",
            input("limit", JDBCType.INTEGER, 0, "10")),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    MAIL_COMPLETE("usp_mail_complete",
            input("mail_id", JDBCType.CHAR, 36, null),
            input("claim_version", JDBCType.INTEGER, 0, null),
            input("outcome", JDBCType.VARCHAR, 20, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    APPLICATION_MODE("usp_application_mode",
            input("expected_revision", JDBCType.INTEGER, 0, null),
            input("mode", JDBCType.NVARCHAR, 11, null),
            input("message", JDBCType.NVARCHAR, 300, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    HEALTH_SAMPLE("usp_health_sample",
            input("instance_id", JDBCType.CHAR, 36, null),
            input("db_status", JDBCType.NVARCHAR, 20, null),
            input("db_latency_ms", JDBCType.BIGINT, 0, null),
            input("memory_used", JDBCType.BIGINT, 0, null),
            input("memory_max", JDBCType.BIGINT, 0, null),
            input("uptime_ms", JDBCType.BIGINT, 0, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    MONITOR_SAMPLES("usp_monitor_samples"),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    MONITOR_MAIL("usp_monitor_mail"),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    MONITOR_REQUESTS("usp_monitor_requests"),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    MONITOR_MIGRATIONS("usp_monitor_migrations"),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    REQUEST_FINISH("usp_request_finish",
            input("status", JDBCType.INTEGER, 0, null),
            input("duration_ms", JDBCType.BIGINT, 0, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    AUDIT_LIST("usp_audit_list",
            input("limit", JDBCType.INTEGER, 0, "50")),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    TRACE_EVENTS("usp_trace_events",
            input("query", JDBCType.NVARCHAR, 100, "NULL"),
            input("actor_id", JDBCType.CHAR, 36, "NULL"),
            input("resource", JDBCType.NVARCHAR, 60, "NULL"),
            input("request_id", JDBCType.CHAR, 36, "NULL"),
            input("from", JDBCType.TIMESTAMP, 6, "NULL"),
            input("to", JDBCType.TIMESTAMP, 6, "NULL"),
            input("before", JDBCType.BIGINT, 0, "0"),
            input("limit", JDBCType.INTEGER, 0, "50")),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    TRACE_REQUESTS("usp_trace_requests",
            input("limit", JDBCType.INTEGER, 0, "50"),
            input("status", JDBCType.INTEGER, 0, "0"),
            input("query", JDBCType.NVARCHAR, 250, "NULL")),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    TRACE_JOURNEY("usp_trace_journey",
            input("request_id", JDBCType.CHAR, 36, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    SUPPORT_LIST("usp_support_list"),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    SUPPORT_CREATE("usp_support_create",
            input("ticket_id", JDBCType.CHAR, 36, null),
            input("reference", JDBCType.NVARCHAR, 30, null),
            input("input", JDBCType.NVARCHAR, -1, null)),
    // V3 / runtime; arguments stay positional, including SQL defaults.
    SUPPORT_STEP("usp_support_step",
            input("ticket_id", JDBCType.CHAR, 36, null),
            input("expected_revision", JDBCType.INTEGER, 0, null),
            input("status", JDBCType.NVARCHAR, 12, null),
            input("priority", JDBCType.NVARCHAR, 6, null),
            input("comment_id", JDBCType.CHAR, 36, null),
            input("comment", JDBCType.NVARCHAR, -1, "NULL")),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    PLATFORM_PLANS("usp_platform_plans",
            input("plan_id", JDBCType.CHAR, 36, "NULL")),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    PLATFORM_TENANTS("usp_platform_tenants",
            input("tenant_id", JDBCType.CHAR, 36, "NULL"),
            input("limit", JDBCType.INTEGER, 0, "100")),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    PLATFORM_USERS("usp_platform_users",
            input("user_id", JDBCType.CHAR, 36, "NULL"),
            input("limit", JDBCType.INTEGER, 0, "100")),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    PLATFORM_SPECIALTIES("usp_platform_specialties",
            input("query", JDBCType.NVARCHAR, 220, "N''")),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    PLATFORM_AUDIT("usp_platform_audit",
            input("limit", JDBCType.INTEGER, 0, "100")),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    ORGANIZATION_LOOKUP("usp_organization_lookup",
            input("email", JDBCType.NVARCHAR, 254, null)),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    ORGANIZATION_DIRECTORY("usp_organization_directory"),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    ORGANIZATION_PROFESSIONALS("usp_organization_professionals",
            input("branch_id", JDBCType.CHAR, 36, "NULL")),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    ORGANIZATION_CATALOG("usp_organization_catalog"),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    ORGANIZATION_PLANS("usp_organization_plans"),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    SAAS_PLAN_SAVE("usp_saas_plan_save",
            input("plan_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null),
            input("create", JDBCType.BIT, 0, "0")),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    SAAS_TENANT_CREATE("usp_saas_tenant_create",
            input("tenant_id", JDBCType.CHAR, 36, null),
            input("branch_id", JDBCType.CHAR, 36, null),
            input("owner_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null)),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    SAAS_TENANT_STATUS("usp_saas_tenant_status",
            input("tenant_id", JDBCType.CHAR, 36, null),
            input("status", JDBCType.NVARCHAR, 10, null),
            input("reason", JDBCType.NVARCHAR, -1, null)),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    ORGANIZATION_SUBSCRIPTION_CHANGE("usp_organization_subscription_change",
            input("tenant_id", JDBCType.CHAR, 36, null),
            input("invoice_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null)),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    SAAS_INVOICE_PAY("usp_saas_invoice_pay",
            input("tenant_id", JDBCType.CHAR, 36, null),
            input("invoice_id", JDBCType.CHAR, 36, null)),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    ORGANIZATION_BRANCH_SAVE("usp_organization_branch_save",
            input("tenant_id", JDBCType.CHAR, 36, null),
            input("branch_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null),
            input("create", JDBCType.BIT, 0, "0")),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    ORGANIZATION_AREA_SAVE("usp_organization_area_save",
            input("tenant_id", JDBCType.CHAR, 36, null),
            input("area_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null),
            input("create", JDBCType.BIT, 0, "0")),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    ORGANIZATION_SPECIALTIES_SAVE("usp_organization_specialties_save",
            input("tenant_id", JDBCType.CHAR, 36, null),
            input("codes", JDBCType.NVARCHAR, -1, null)),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    ORGANIZATION_MEMBER_SAVE("usp_organization_member_save",
            input("tenant_id", JDBCType.CHAR, 36, null),
            input("user_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null)),
    // V4 / runtime; arguments stay positional, including SQL defaults.
    PLATFORM_USER("usp_platform_user",
            input("user_id", JDBCType.CHAR, 36, null),
            input("active_only", JDBCType.BIT, 0, "0")),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    PATIENTS_LIST("usp_patients_list",
            input("query", JDBCType.NVARCHAR, -1, "N''"),
            input("limit", JDBCType.INTEGER, 0, "100"),
            input("offset", JDBCType.INTEGER, 0, "0")),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    PATIENT_GET("usp_patient_get",
            input("patient_id", JDBCType.CHAR, 36, null)),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    PATIENT_HISTORY("usp_patient_history",
            input("patient_id", JDBCType.CHAR, 36, null)),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    ENCOUNTER_GET("usp_encounter_get",
            input("encounter_id", JDBCType.CHAR, 36, null)),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    DOCUMENTS_LIST("usp_documents_list",
            input("patient_id", JDBCType.CHAR, 36, null)),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    DOCUMENT_GET("usp_document_get",
            input("document_id", JDBCType.CHAR, 36, null)),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    PATIENT_SAVE("usp_patient_save",
            input("patient_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null),
            input("expected_revision", JDBCType.INTEGER, 0, "0")),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    PATIENT_LINK_SAVE("usp_patient_link_save",
            input("patient_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null)),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    APPOINTMENTS_LIST("usp_appointments_list",
            input("from", JDBCType.TIMESTAMP, 6, null),
            input("to", JDBCType.TIMESTAMP, 6, null),
            input("branch_id", JDBCType.CHAR, 36, "NULL")),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    APPOINTMENT_GET("usp_appointment_get",
            input("appointment_id", JDBCType.CHAR, 36, null)),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    APPOINTMENT_RESERVE("usp_appointment_reserve",
            input("appointment_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null),
            input("request_key", JDBCType.NVARCHAR, -1, null),
            input("request_hash", JDBCType.CHAR, 64, null),
            input("portal", JDBCType.BIT, 0, "0")),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    APPOINTMENT_CHANGE("usp_appointment_change",
            input("appointment_id", JDBCType.CHAR, 36, null),
            input("expected_revision", JDBCType.INTEGER, 0, null),
            input("status", JDBCType.NVARCHAR, -1, null),
            input("starts_at", JDBCType.TIMESTAMP, 6, "NULL"),
            input("ends_at", JDBCType.TIMESTAMP, 6, "NULL")),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    ENCOUNTER_START("usp_encounter_start",
            input("encounter_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null)),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    ENCOUNTER_NOTE("usp_encounter_note",
            input("encounter_id", JDBCType.CHAR, 36, null),
            input("expected_revision", JDBCType.INTEGER, 0, null),
            input("note", JDBCType.NVARCHAR, -1, null),
            input("finalize", JDBCType.BIT, 0, "0")),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    CLINICAL_ENTRY_ADD("usp_clinical_entry_add",
            input("entry_id", JDBCType.CHAR, 36, null),
            input("encounter_id", JDBCType.CHAR, 36, null),
            input("kind", JDBCType.NVARCHAR, -1, null),
            input("payload", JDBCType.NVARCHAR, -1, null)),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    DOCUMENT_CREATE("usp_document_create",
            input("document_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null)),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    DOCUMENT_CHANGE("usp_document_change",
            input("document_id", JDBCType.CHAR, 36, null),
            input("expected_revision", JDBCType.INTEGER, 0, null),
            input("operation", JDBCType.NVARCHAR, -1, null),
            input("content", JDBCType.NVARCHAR, -1, "NULL")),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    PORTAL_PATIENTS("usp_portal_patients"),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    PORTAL_DOCUMENTS("usp_portal_documents",
            input("patient_id", JDBCType.CHAR, 36, null)),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    PORTAL_APPOINTMENTS("usp_portal_appointments",
            input("patient_id", JDBCType.CHAR, 36, null)),
    // V5 / runtime; arguments stay positional, including SQL defaults.
    PORTAL_BALANCE("usp_portal_balance",
            input("patient_id", JDBCType.CHAR, 36, null)),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    FINANCE_BALANCE("usp_finance_balance",
            input("patient_id", JDBCType.CHAR, 36, null)),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    FINANCE_MOVEMENTS("usp_finance_movements",
            input("patient_id", JDBCType.CHAR, 36, null)),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    FINANCE_POST("usp_finance_post",
            input("movement_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null),
            input("request_key", JDBCType.NVARCHAR, -1, null),
            input("request_hash", JDBCType.CHAR, 64, null)),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    INVENTORY_LOTS("usp_inventory_lots"),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    INVENTORY_TRANSFERS("usp_inventory_transfers"),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    INVENTORY_PRESCRIPTIONS("usp_inventory_prescriptions"),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    INVENTORY_LOT_CREATE("usp_inventory_lot_create",
            input("lot_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null)),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    INVENTORY_MOVE("usp_inventory_move",
            input("movement_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null),
            input("request_key", JDBCType.NVARCHAR, -1, null),
            input("request_hash", JDBCType.CHAR, 64, null)),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    INVENTORY_TRANSFER_START("usp_inventory_transfer_start",
            input("transfer_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null),
            input("request_key", JDBCType.NVARCHAR, -1, null),
            input("request_hash", JDBCType.CHAR, 64, null)),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    INVENTORY_TRANSFER_RECEIVE("usp_inventory_transfer_receive",
            input("transfer_id", JDBCType.CHAR, 36, null)),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    HOSPITAL_RESOURCES("usp_hospital_resources"),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    HOSPITAL_RESOURCE_CREATE("usp_hospital_resource_create",
            input("resource_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null)),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    HOSPITAL_ADMISSIONS("usp_hospital_admissions"),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    HOSPITAL_ADMIT("usp_hospital_admit",
            input("admission_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null)),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    HOSPITAL_DISCHARGE("usp_hospital_discharge",
            input("admission_id", JDBCType.CHAR, 36, null),
            input("expected_revision", JDBCType.INTEGER, 0, null)),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    WORKFLOW_DEFINITIONS("usp_workflow_definitions"),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    WORKFLOW_LIST("usp_workflow_list",
            input("type", JDBCType.NVARCHAR, -1, null)),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    WORKFLOW_GET("usp_workflow_get",
            input("case_id", JDBCType.CHAR, 36, null)),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    WORKFLOW_CREATE("usp_workflow_create",
            input("case_id", JDBCType.CHAR, 36, null),
            input("input", JDBCType.NVARCHAR, -1, null)),
    // V6 / runtime; arguments stay positional, including SQL defaults.
    WORKFLOW_STEP("usp_workflow_step",
            input("case_id", JDBCType.CHAR, 36, null),
            input("expected_revision", JDBCType.INTEGER, 0, null),
            input("next_status", JDBCType.NVARCHAR, -1, null),
            input("payload", JDBCType.NVARCHAR, -1, null));

    private final String call;
    private final List<Parameter> parameters;

    SqlServerProcedure(String name, Parameter... parameters) {
        this.parameters = List.of(parameters);
        this.call = "{call dbo." + name + "(" + String.join(",", Collections.nCopies(parameters.length, "?")) + ")}";
    }

    String call() { return call; }
    List<Parameter> parameters() { return parameters; }
    boolean bootstrap() { return this == BOOTSTRAP_EXISTS || this == BOOTSTRAP_CREATE; }

    private static Parameter input(String name, JDBCType type, int length, String defaultLiteral) {
        return new Parameter(type, length, type == JDBCType.CHAR || type == JDBCType.VARCHAR, name, defaultLiteral);
    }
    static Parameter ascii(JDBCType type, int length) { return new Parameter(type, length, true); }
    static Parameter unicode(int length) { return new Parameter(JDBCType.NVARCHAR, length, false); }

    /** length is the SQL text length (-1 = MAX), or DATETIME2 fractional precision; 0 for scalars.
     *  Defaults are documentation/contract metadata, NEVER substituted for missing arguments. */
    record Parameter(JDBCType type, int length, boolean ascii, String sqlName, String defaultLiteral) {
        Parameter(JDBCType type, int length, boolean ascii) { this(type, length, ascii, null, null); }
        private static final Instant DATETIME2_MIN=Instant.parse("0001-01-01T00:00:00Z");
        private static final Instant DATETIME2_MAX=Instant.parse("9999-12-31T23:59:59.999999999Z");
        void validate(Object value) {
            if (value == null) return; // SQL NULL is bound with this declared type.
            boolean valid = switch (type) {
                case BIT -> value instanceof Boolean;
                case INTEGER -> value instanceof Integer;
                case BIGINT -> value instanceof Long;
                case TIMESTAMP -> value instanceof Instant instant && !instant.isBefore(DATETIME2_MIN)
                        && !instant.isAfter(DATETIME2_MAX);
                case CHAR, VARCHAR, NVARCHAR -> value instanceof String text
                        && (length == -1 || text.length() <= length)
                        && (!ascii || text.chars().allMatch(c -> c <= 127));
                default -> false;
            };
            if (!valid) throw SqlServerErrors.invalid();
        }
    }
}
