CREATE TABLE users (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 name VARCHAR(160) NOT NULL, email VARCHAR(254) NOT NULL UNIQUE, password_hash VARCHAR(100) NOT NULL,
 clinical_domain ENUM('HUMAN','ANIMAL') NULL, credential VARCHAR(100) NULL,
 platform_role ENUM('SAD','SOP') NULL, active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
);
CREATE TABLE plans (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 name VARCHAR(100) NOT NULL UNIQUE, description VARCHAR(500) NOT NULL,
 status ENUM('DRAFT','PUBLISHED','ARCHIVED') NOT NULL, current_version INT NOT NULL DEFAULT 0
);
CREATE TABLE plan_versions (
 plan_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, version INT NOT NULL,
 base_minor BIGINT NOT NULL, branch_minor BIGINT NOT NULL, professional_minor BIGINT NOT NULL,
 included_branches INT NOT NULL, included_professionals INT NOT NULL, included_specialties INT NOT NULL,
 max_branches INT NOT NULL, max_professionals INT NOT NULL, max_specialties INT NOT NULL,
 annual_discount INT NOT NULL, kinds JSON NOT NULL, domains JSON NOT NULL, modules JSON NOT NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 PRIMARY KEY(plan_id,version), FOREIGN KEY(plan_id) REFERENCES plans(id),
 CHECK(base_minor>=0 AND branch_minor>=0 AND professional_minor>=0),
 CHECK(included_branches>=1 AND included_professionals>=1 AND included_specialties>=1),
 CHECK(max_branches>=included_branches AND max_professionals>=included_professionals AND max_specialties>=included_specialties),
 CHECK(annual_discount BETWEEN 0 AND 60)
);
CREATE TABLE tenants (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 name VARCHAR(160) NOT NULL, slug VARCHAR(63) CHARACTER SET ascii COLLATE ascii_bin NOT NULL UNIQUE,
 kind ENUM('DOCTOR','CLINIC','HOSPITAL','VETERINARY','DENTAL','SPECIALTY_CENTER') NOT NULL,
 domain ENUM('HUMAN','ANIMAL') NOT NULL, status ENUM('TRIAL','ACTIVE','SUSPENDED','CANCELLED') NOT NULL DEFAULT 'TRIAL',
 owner_user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 timezone VARCHAR(64) NOT NULL DEFAULT 'America/Lima', created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 FOREIGN KEY(owner_user_id) REFERENCES users(id),
 CHECK(slug REGEXP '^[a-z0-9]+(-[a-z0-9]+)*$'),
 CHECK(slug NOT IN ('www','admin','api','app','saas','mail','support','status','auth','portal','localhost')),
 CHECK((kind IN ('DOCTOR','VETERINARY') OR domain='HUMAN') AND (kind<>'VETERINARY' OR domain='ANIMAL'))
);
CREATE TABLE subscriptions (
 tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 plan_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, plan_version INT NOT NULL,
 cycle ENUM('MONTHLY','YEARLY') NOT NULL, branch_quota INT NOT NULL, professional_quota INT NOT NULL, specialty_quota INT NOT NULL,
 renewal_date DATE NOT NULL, FOREIGN KEY(tenant_id) REFERENCES tenants(id),
 FOREIGN KEY(plan_id,plan_version) REFERENCES plan_versions(plan_id,version),
 CHECK(branch_quota>=1 AND professional_quota>=1 AND specialty_quota>=1)
);
CREATE TABLE specialties (
 code VARCHAR(100) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, name VARCHAR(220) NOT NULL,
 domain ENUM('HUMAN','ANIMAL') NOT NULL, dental BOOLEAN NOT NULL, profile JSON NOT NULL
);
CREATE TABLE tenant_specialties (
 tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, specialty_code VARCHAR(100) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 PRIMARY KEY(tenant_id,specialty_code), FOREIGN KEY(tenant_id) REFERENCES tenants(id), FOREIGN KEY(specialty_code) REFERENCES specialties(code)
);
CREATE TABLE branches (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 name VARCHAR(160) NOT NULL, address VARCHAR(300) NOT NULL DEFAULT '', external BOOLEAN NOT NULL DEFAULT FALSE,
 active BOOLEAN NOT NULL DEFAULT TRUE, UNIQUE(tenant_id,id), UNIQUE(tenant_id,name), FOREIGN KEY(tenant_id) REFERENCES tenants(id)
);
CREATE TABLE areas (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 branch_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, name VARCHAR(160) NOT NULL,
 specialties JSON NOT NULL, UNIQUE(tenant_id,id), UNIQUE(tenant_id,branch_id,name), FOREIGN KEY(tenant_id,branch_id) REFERENCES branches(tenant_id,id)
);
CREATE TABLE memberships (
 tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 roles JSON NOT NULL, status ENUM('ACTIVE','INVITED','INACTIVE') NOT NULL, owner BOOLEAN NOT NULL DEFAULT FALSE,
 PRIMARY KEY(tenant_id,user_id), FOREIGN KEY(tenant_id) REFERENCES tenants(id), FOREIGN KEY(user_id) REFERENCES users(id)
);
CREATE TABLE membership_branches (
 tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 branch_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, PRIMARY KEY(tenant_id,user_id,branch_id),
 FOREIGN KEY(tenant_id,user_id) REFERENCES memberships(tenant_id,user_id), FOREIGN KEY(tenant_id,branch_id) REFERENCES branches(tenant_id,id)
);
CREATE TABLE membership_specialties (
 tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 specialty_code VARCHAR(100) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, PRIMARY KEY(tenant_id,user_id,specialty_code),
 FOREIGN KEY(tenant_id,user_id) REFERENCES memberships(tenant_id,user_id), FOREIGN KEY(tenant_id,specialty_code) REFERENCES tenant_specialties(tenant_id,specialty_code)
);
CREATE TABLE auth_sessions (
 token_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NULL,
 expires_at DATETIME(6) NOT NULL, revoked BOOLEAN NOT NULL DEFAULT FALSE, created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 FOREIGN KEY(user_id) REFERENCES users(id), FOREIGN KEY(tenant_id) REFERENCES tenants(id), INDEX(expires_at)
);
CREATE TABLE audit_events (
 id BIGINT AUTO_INCREMENT PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NULL,
 actor_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, action VARCHAR(80) NOT NULL,
 target_id VARCHAR(100) NOT NULL, metadata JSON NOT NULL, created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 FOREIGN KEY(tenant_id) REFERENCES tenants(id), FOREIGN KEY(actor_id) REFERENCES users(id), INDEX(tenant_id,id)
);
CREATE TABLE saas_invoices (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 amount_minor BIGINT NOT NULL, currency CHAR(3) NOT NULL DEFAULT 'PEN', cycle VARCHAR(10) NOT NULL,
 status ENUM('PENDING','PAID') NOT NULL, created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), paid_at DATETIME(6) NULL,
 UNIQUE(tenant_id,id), FOREIGN KEY(tenant_id) REFERENCES tenants(id), CHECK(amount_minor>=0)
);
CREATE TABLE patients (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 name VARCHAR(160) NOT NULL, domain ENUM('HUMAN','ANIMAL') NOT NULL, identifier VARCHAR(100) NOT NULL,
 birth_date DATE NULL, species VARCHAR(80) NULL, contact JSON NOT NULL, allergies JSON NOT NULL,
 revision INT NOT NULL DEFAULT 1, created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 UNIQUE(tenant_id,id), UNIQUE(tenant_id,identifier), FOREIGN KEY(tenant_id) REFERENCES tenants(id)
);
CREATE TABLE patient_links (
 tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, patient_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 user_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, relationship VARCHAR(80) NOT NULL,
 active BOOLEAN NOT NULL DEFAULT TRUE, scopes JSON NOT NULL, PRIMARY KEY(tenant_id,patient_id,user_id),
 FOREIGN KEY(tenant_id,patient_id) REFERENCES patients(tenant_id,id), FOREIGN KEY(user_id) REFERENCES users(id)
);
CREATE TABLE appointments (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 patient_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, branch_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 professional_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, specialty_code VARCHAR(100) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 starts_at DATETIME(6) NOT NULL, ends_at DATETIME(6) NOT NULL, status ENUM('REQUESTED','RESERVED','CONFIRMED','WAITING','CALLED','IN_CARE','COMPLETED','CANCELLED','WITHDRAWN') NOT NULL,
 service VARCHAR(160) NOT NULL, note VARCHAR(1000) NOT NULL, revision INT NOT NULL DEFAULT 1,
 request_key VARCHAR(100) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, request_hash CHAR(64) NOT NULL,
 UNIQUE(tenant_id,id), UNIQUE(tenant_id,request_key), INDEX(professional_id,starts_at,ends_at),
 FOREIGN KEY(tenant_id,patient_id) REFERENCES patients(tenant_id,id), FOREIGN KEY(tenant_id,branch_id) REFERENCES branches(tenant_id,id),
 FOREIGN KEY(tenant_id,professional_id) REFERENCES memberships(tenant_id,user_id), FOREIGN KEY(tenant_id,specialty_code) REFERENCES tenant_specialties(tenant_id,specialty_code), CHECK(ends_at>starts_at)
);
CREATE TABLE encounters (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 patient_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, branch_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 professional_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, specialty_code VARCHAR(100) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 status ENUM('ACTIVE','PENDING','FINALIZED') NOT NULL, note MEDIUMTEXT NOT NULL, revision INT NOT NULL DEFAULT 1, profile_snapshot JSON NOT NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), finalized_at DATETIME(6) NULL,
 active_patient CHAR(36) CHARACTER SET ascii COLLATE ascii_bin GENERATED ALWAYS AS (CASE WHEN status <> 'FINALIZED' THEN patient_id ELSE NULL END) STORED,
 UNIQUE(tenant_id,id), UNIQUE(tenant_id,active_patient),
 FOREIGN KEY(tenant_id,patient_id) REFERENCES patients(tenant_id,id), FOREIGN KEY(tenant_id,branch_id) REFERENCES branches(tenant_id,id),
 FOREIGN KEY(tenant_id,professional_id) REFERENCES memberships(tenant_id,user_id), FOREIGN KEY(tenant_id,specialty_code) REFERENCES tenant_specialties(tenant_id,specialty_code)
);
CREATE TABLE clinical_entries (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 encounter_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 kind ENUM('EVALUATION','OBSERVATION','ANNOTATION','ORDER','PRESCRIPTION') NOT NULL, payload JSON NOT NULL, profile_snapshot JSON NOT NULL,
 actor_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 UNIQUE(tenant_id,id), FOREIGN KEY(tenant_id,encounter_id) REFERENCES encounters(tenant_id,id), FOREIGN KEY(actor_id) REFERENCES users(id)
);
CREATE TABLE documents (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 patient_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, encounter_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NULL,
 title VARCHAR(200) NOT NULL, type VARCHAR(60) NOT NULL, content MEDIUMTEXT NOT NULL, status ENUM('DRAFT','SIGNED') NOT NULL,
 revision INT NOT NULL DEFAULT 1, original_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NULL,
 signer_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NULL, signed_at DATETIME(6) NULL, content_hash CHAR(64) NULL,
 published BOOLEAN NOT NULL DEFAULT FALSE, withdrawn BOOLEAN NOT NULL DEFAULT FALSE,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 UNIQUE(tenant_id,id), FOREIGN KEY(tenant_id,patient_id) REFERENCES patients(tenant_id,id), FOREIGN KEY(tenant_id,encounter_id) REFERENCES encounters(tenant_id,id),
 FOREIGN KEY(tenant_id,original_id) REFERENCES documents(tenant_id,id), FOREIGN KEY(signer_id) REFERENCES users(id)
);
CREATE TABLE finance_movements (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 patient_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, kind ENUM('CHARGE','PAYMENT','REFUND') NOT NULL,
 amount_minor BIGINT NOT NULL, currency CHAR(3) NOT NULL DEFAULT 'PEN', title VARCHAR(200) NOT NULL,
 parent_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NULL, actor_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 request_key VARCHAR(100) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, request_hash CHAR(64) NOT NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), UNIQUE(tenant_id,id), UNIQUE(tenant_id,request_key),
 FOREIGN KEY(tenant_id,patient_id) REFERENCES patients(tenant_id,id), FOREIGN KEY(tenant_id,parent_id) REFERENCES finance_movements(tenant_id,id), FOREIGN KEY(actor_id) REFERENCES users(id), CHECK(amount_minor>0)
);
CREATE TABLE stock_lots (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 branch_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, name VARCHAR(160) NOT NULL, lot VARCHAR(100) NOT NULL,
 expiry DATE NOT NULL, quantity DECIMAL(14,3) NOT NULL DEFAULT 0, unit VARCHAR(30) NOT NULL,
 UNIQUE(tenant_id,id), UNIQUE(tenant_id,branch_id,name,lot,expiry), FOREIGN KEY(tenant_id,branch_id) REFERENCES branches(tenant_id,id), CHECK(quantity>=0)
);
CREATE TABLE stock_movements (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 lot_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, kind ENUM('RECEIVE','DISPENSE') NOT NULL,
 quantity DECIMAL(14,3) NOT NULL, patient_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NULL, prescription_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NULL,
 actor_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, request_key VARCHAR(100) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, request_hash CHAR(64) NOT NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), UNIQUE(tenant_id,id), UNIQUE(tenant_id,request_key),
 FOREIGN KEY(tenant_id,lot_id) REFERENCES stock_lots(tenant_id,id), FOREIGN KEY(tenant_id,patient_id) REFERENCES patients(tenant_id,id), FOREIGN KEY(tenant_id,prescription_id) REFERENCES clinical_entries(tenant_id,id), FOREIGN KEY(actor_id) REFERENCES users(id), CHECK(quantity>0)
);
CREATE TABLE stock_transfers (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 lot_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, destination_branch_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 quantity DECIMAL(14,3) NOT NULL, status ENUM('IN_TRANSIT','RECEIVED') NOT NULL, request_key VARCHAR(100) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, request_hash CHAR(64) NOT NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), received_at DATETIME(6) NULL,
 UNIQUE(tenant_id,id), UNIQUE(tenant_id,request_key), FOREIGN KEY(tenant_id,lot_id) REFERENCES stock_lots(tenant_id,id),
 FOREIGN KEY(tenant_id,destination_branch_id) REFERENCES branches(tenant_id,id), CHECK(quantity>0)
);
CREATE TABLE hospital_resources (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 branch_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, name VARCHAR(100) NOT NULL, kind ENUM('BED','CAGE') NOT NULL, active BOOLEAN NOT NULL DEFAULT TRUE,
 UNIQUE(tenant_id,id), UNIQUE(tenant_id,branch_id,name), FOREIGN KEY(tenant_id,branch_id) REFERENCES branches(tenant_id,id)
);
CREATE TABLE admissions (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 patient_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, resource_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 status ENUM('ADMITTED','DISCHARGED') NOT NULL, reason VARCHAR(1000) NOT NULL, revision INT NOT NULL DEFAULT 1,
 admitted_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), discharged_at DATETIME(6) NULL,
 occupied_resource CHAR(36) CHARACTER SET ascii COLLATE ascii_bin GENERATED ALWAYS AS (CASE WHEN status='ADMITTED' THEN resource_id ELSE NULL END) STORED,
 admitted_patient CHAR(36) CHARACTER SET ascii COLLATE ascii_bin GENERATED ALWAYS AS (CASE WHEN status='ADMITTED' THEN patient_id ELSE NULL END) STORED,
 UNIQUE(tenant_id,id), UNIQUE(tenant_id,occupied_resource), UNIQUE(tenant_id,admitted_patient),
 FOREIGN KEY(tenant_id,patient_id) REFERENCES patients(tenant_id,id), FOREIGN KEY(tenant_id,resource_id) REFERENCES hospital_resources(tenant_id,id)
);
CREATE TABLE workflow_cases (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 branch_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, patient_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NULL,
 type VARCHAR(60) NOT NULL, status VARCHAR(40) NOT NULL, title VARCHAR(200) NOT NULL, payload JSON NOT NULL,
 revision INT NOT NULL DEFAULT 1, actor_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 UNIQUE(tenant_id,id), FOREIGN KEY(tenant_id,branch_id) REFERENCES branches(tenant_id,id), FOREIGN KEY(tenant_id,patient_id) REFERENCES patients(tenant_id,id), FOREIGN KEY(actor_id) REFERENCES users(id)
);
CREATE TABLE workflow_history (
 id BIGINT AUTO_INCREMENT PRIMARY KEY, tenant_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 case_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, revision INT NOT NULL, status VARCHAR(40) NOT NULL,
 payload JSON NOT NULL, actor_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 UNIQUE(tenant_id,case_id,revision), FOREIGN KEY(tenant_id,case_id) REFERENCES workflow_cases(tenant_id,id), FOREIGN KEY(actor_id) REFERENCES users(id)
);
