"""Restart only this Compose project's services and compare persisted row counts."""
from pathlib import Path
import importlib.util
import json
import subprocess
import time

ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('health_api_checks',Path(__file__).with_name('verify-api.py'))
api=importlib.util.module_from_spec(spec)
spec.loader.exec_module(api)


def command(args, **kwargs):
    result=subprocess.run(['docker','compose']+args,cwd=ROOT,capture_output=True,text=True,timeout=50,**kwargs)
    if result.returncode:
        raise RuntimeError('Compose operation failed: '+result.stderr[-1000:])
    return result.stdout


def snapshot():
    tables=['tenants','patients','encounters','clinical_entries','documents','finance_movements','stock_lots','stock_movements','stock_transfers','admissions','workflow_cases','workflow_history']
    sql='\n'.join("SELECT '"+table+"',COUNT(*) FROM "+table+';' for table in tables)
    output=command(['exec','-T','mysql','sh','-c','MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot -N health_project'],input=sql)
    return dict((line.split('\t')[0],int(line.split('\t')[1])) for line in output.splitlines())


before=snapshot()
command(['stop','backend','gateway'])
command(['restart','mysql'])
command(['up','-d','backend','gateway'])
for attempt in range(40):
    try:
        api.api('GET','/api/public/context')
        break
    except Exception:
        if attempt==39:
            raise
        time.sleep(1)
after=snapshot()
assert before==after, 'Persisted row counts changed during restart'
api.login(api.CONFIG['BOOTSTRAP_ADMIN_EMAIL'])
command(['run','--rm','migrate'])
output=ROOT/'backend/test-results/persistence.json'
output.write_text(json.dumps({'passed':True,'before':before,'after':after,'flywayValidation':True},indent=2),encoding='utf-8')
print('PASS: persisted counts unchanged across service restart; login and Flyway validation passed')
