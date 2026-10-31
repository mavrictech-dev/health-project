"""Audited column allowlist. Do not regenerate an applied migration."""
from pathlib import Path
tables={
'users':'id name active clinical_domain platform_role email_verified',
'plans':'id name status current_version',
'plan_versions':'plan_id version base_minor branch_minor professional_minor included_branches included_professionals max_branches max_professionals max_specialties modules',
'tenants':'id name slug kind domain status owner_user_id timezone',
'subscriptions':'tenant_id plan_id plan_version cycle branch_quota professional_quota specialty_quota renewal_date',
'tenant_specialties':'tenant_id specialty_code',
'branches':'id tenant_id name external active',
'areas':'id tenant_id branch_id name specialties',
'memberships':'tenant_id user_id roles status owner',
'membership_branches':'tenant_id user_id branch_id',
'membership_specialties':'tenant_id user_id specialty_code',
'patients':'id tenant_id domain revision',
'patient_links':'tenant_id patient_id user_id relationship active scopes',
'appointments':'id tenant_id patient_id branch_id professional_id specialty_code starts_at ends_at status revision',
'encounters':'id tenant_id patient_id branch_id professional_id specialty_code status revision finalized_at',
'clinical_entries':'id tenant_id encounter_id kind actor_id',
'documents':'id tenant_id patient_id encounter_id type status revision original_id signer_id signed_at content_hash published withdrawn',
'finance_movements':'id tenant_id patient_id kind amount_minor currency parent_id actor_id',
'saas_invoices':'id tenant_id amount_minor currency cycle status paid_at',
'stock_lots':'id tenant_id branch_id name lot expiry quantity unit',
'stock_movements':'id tenant_id lot_id kind quantity patient_id prescription_id actor_id',
'stock_transfers':'id tenant_id lot_id destination_branch_id quantity status received_at',
'hospital_resources':'id tenant_id branch_id name kind active',
'admissions':'id tenant_id patient_id resource_id status revision admitted_at discharged_at',
'workflow_cases':'id tenant_id branch_id patient_id type status revision actor_id',
'workflow_history':'id tenant_id case_id revision status actor_id',
'support_tickets':'id tenant_id actor_id reference status priority revision',
'support_comments':'id ticket_id actor_id',
'application_state':'id mode message revision',
}
extra={'encounters':['note'],'clinical_entries':['payload','profile_snapshot'],'documents':['content'],'patients':['name','identifier','birth_date','species','contact','allergies'],'users':['password_hash'],'appointments':['note'],'workflow_cases':['payload'],'workflow_history':['payload'],'support_tickets':['message'],'support_comments':['message']}
output=['-- Business changes are part of the same transaction. Sensitive values are hashed.','DELIMITER $$']
for table,fields in tables.items():
    cols=fields.split()
    def snapshot(prefix):
        pairs=[f"'{col}',{prefix}.{col}" for col in cols]
        pairs += [f"'{col}_sha256',SHA2(CAST({prefix}.{col} AS CHAR),256)" for col in extra.get(table,[])]
        return 'JSON_OBJECT('+','.join(pairs)+')'
    for operation in ['INSERT','UPDATE','DELETE']:
        ref='OLD' if operation=='DELETE' else 'NEW'
        tenant=f'{ref}.tenant_id' if 'tenant_id' in cols else 'NULL'
        target=f'{ref}.id' if 'id' in cols else f'{ref}.'+('user_id' if 'user_id' in cols else 'plan_id' if 'plan_id' in cols else 'tenant_id')
        before='NULL' if operation=='INSERT' else snapshot('OLD')
        after='NULL' if operation=='DELETE' else snapshot('NEW')
        condition='' if operation!='UPDATE' else f'IF NOT ({before}<=>{after}) THEN '
        close='' if operation!='UPDATE' else ' END IF;'
        output.append(f'CREATE TRIGGER trace_{table}_{operation.lower()} AFTER {operation} ON {table} FOR EACH ROW BEGIN {condition}CALL sp_audit_change({tenant},\'{table}\',{target},\'{operation}\',{before},{after});{close} END$$')
output.append('DELIMITER ;')
Path('backend/src/main/resources/db/migration/V10__business_change_triggers.sql').write_text('\n'.join(output)+'\n',encoding='utf-8')
print(len(tables),'business tables with INSERT/UPDATE/DELETE trace triggers')
