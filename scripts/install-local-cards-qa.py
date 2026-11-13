"""Install the reviewed SQL sources only in Health Project's dedicated Docker QA DB.
Two fresh transactions: full rollback rehearsal, then commit. Never touches Somee.
SQLcmd reads a file, avoiding its interactive stdin line buffer. Source files stay intact.
"""
from pathlib import Path
import importlib.util,subprocess,json,hashlib,sys,uuid,time

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('hp_docker',ROOT/'scripts/health-sqlserver-docker-qa.py')
M=importlib.util.module_from_spec(spec);sys.modules[spec.name]=M;spec.loader.exec_module(M)
DB=M.DATABASE

def main():
 if sys.argv[1:] not in (['--apply'],['--diagnose-v14'],['--diagnose-v15']):raise SystemExit('Use --apply or --diagnose-v14 for isolated local QA only.')
 folder=ROOT/'tmp'/('cards-sql-install-'+uuid.uuid4().hex);folder.mkdir()
 def run(args,name):
  result=subprocess.run([str(M.CLI),'--context',M.CONTEXT,*args],capture_output=True,timeout=240)
  (folder/(name+'.stdout')).write_bytes(result.stdout);(folder/(name+'.stderr')).write_bytes(result.stderr)
  if result.returncode:raise RuntimeError(name+' failed; native output in '+str(folder))
  return result.stdout
 target=json.loads(run(['inspect','--format',M.CONTAINER_FORMAT,M.NAME],'container'))
 if target['hostname']!=M.NAME or target['labels'].get(M.LABEL)!=M.LABEL_VALUE or target['image']!=M.IMAGE_ID:raise RuntimeError('Unexpected Docker target')
 if not target['running']:
  run(['start',M.NAME],'start-owned-container');time.sleep(15)
 def sql(payload,name):
  path=folder/(name+'.sql');path.write_bytes(payload);inner='/tmp/health-cards-'+folder.name+'-'+name+'.sql'
  run(['cp',str(path),M.NAME+':'+inner],name+'-copy')
  actual=run(['exec',M.NAME,'sha256sum',inner],name+'-sha').decode().split()[0]
  if actual!=hashlib.sha256(payload).hexdigest():raise RuntimeError('SQL transport changed')
  args=['exec',M.NAME,'sh','-c',M.SQL_SHELL,'hp-sql','-S','tcp:127.0.0.1,1433','-U','sa','-d',DB,'-C','-b','-V11','-r1','-f65001','-y0','-w65535','-x','-X1','-l30','-t180','-i',inner]
  return run(args,name)
 guards=M.engine_guard(DB)+M.configured_guard()
 pre=(':On Error exit\n'+guards+M.empty_guard()+"SELECT N'EMPTY_QA_DATABASE' state;\n").encode()
 sql(pre,'pre')
 sources=sorted((ROOT/'backend/src/main/resources/db/sqlserver').glob('V*.sql'),key=lambda p:int(p.name.split('__')[0][1:]))
 if [int(p.name.split('__')[0][1:]) for p in sources]!=list(range(1,19)):raise RuntimeError('Expected V1 through V18 exactly')
 (folder/'sources.json').write_text(json.dumps({p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sources},indent=2))
 body=b'\n'.join(p.read_bytes().removeprefix(b'\xef\xbb\xbf') for p in sources)
 opening=(':On Error exit\n'+guards+M.empty_guard()+'BEGIN TRANSACTION;\nGO\n').encode()
 if sys.argv[1:] in (['--diagnose-v14'],['--diagnose-v15']):
  boundary=14 if sys.argv[1:] == ['--diagnose-v14'] else 15
  v14=sources[boundary-1].read_text(encoding='utf-8-sig');declaration=v14[v14.index('DECLARE @modules TABLE'):v14.index('IF EXISTS(SELECT 1 FROM @modules')]
  query="SELECT e.name,e.full_hash,e.statement_hash,CONVERT(char(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),TRIM(N' '+NCHAR(9)+NCHAR(10)+NCHAR(13) FROM REPLACE(REPLACE(m.definition,NCHAR(13)+NCHAR(10),NCHAR(10)),NCHAR(13),NCHAR(10))))),2) actual_hash,m.uses_ansi_nulls,m.uses_quoted_identifier,m.is_schema_bound,m.is_recompiled,m.execute_as_principal_id,CONVERT(varchar(max),CONVERT(varbinary(max),m.definition),2) definition_hex FROM @modules e JOIN sys.sql_modules m ON m.object_id=OBJECT_ID(N'dbo.'+e.name) FOR JSON PATH;\nROLLBACK TRANSACTION;\n"
  sql(opening+b'\n'.join(p.read_bytes().removeprefix(b'\xef\xbb\xbf') for p in sources[:boundary-1])+b'\n'+declaration.encode()+query.encode(),'diagnose-v14');print('Rollback diagnostic: '+str(folder));return
 checks=b"\nIF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 59999,'Migration transaction lost',1;\nIF COL_LENGTH('dbo.tenants','ruc') IS NULL OR OBJECT_ID('dbo.usp_consultation_add','P') IS NULL THROW 59999,'Missing cards schema',1;\n"
 sql(opening+body+checks+b'ROLLBACK TRANSACTION;\nSELECT N\'REHEARSAL_PASSED\' state;\n','rehearsal')
 sql(pre,'after-rehearsal')
 sql(opening+body+checks+b"EXEC sys.sp_addextendedproperty @name=N'health_schema_version',@value=N'18';\nCOMMIT TRANSACTION;\nSELECT N'INSTALLED_V18' state;\n",'install')
 verify=(':On Error exit\n'+guards+"SELECT (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0) tables,(SELECT COUNT(*) FROM sys.procedures WHERE is_ms_shipped=0) procedures,(SELECT COUNT(*) FROM dbo.specialties WHERE ISJSON(profile,OBJECT)=1) profiles;\n").encode()
 sql(verify,'verify');print('V1–V16 rehearsal, empty postcheck, install and fresh verification passed. Evidence: '+str(folder))

if __name__=='__main__':main()
