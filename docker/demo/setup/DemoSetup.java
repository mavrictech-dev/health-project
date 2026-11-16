import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.MessageDigest;
import java.sql.*;
import java.time.Instant;
import java.util.*;
import com.microsoft.sqlserver.jdbc.SQLServerDataSource;
import com.mavric.health.persistence.sqlserver.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import tools.jackson.databind.ObjectMapper;

/** Local meeting installer only: never wired into the backend application. */
public final class DemoSetup {
    static final String DB="health_meeting_demo", SCOPE="health-meeting-demo-v1";
    static final String SAD="a1000000-0000-4000-8000-000000000001", OWNER="a1000000-0000-4000-8000-000000000002", PRO="a1000000-0000-4000-8000-000000000003";
    static final String TENANT="a2000000-0000-4000-8000-000000000001", BRANCH="a3000000-0000-4000-8000-000000000001", BRANCH2="a3000000-0000-4000-8000-000000000002", PATIENT="a4000000-0000-4000-8000-000000000001";
    static final String RUC="20000000001", SPECIALTY="H_GENERAL_MEDICINE";
    static final ObjectMapper JSON=new ObjectMapper();
    static String stage="offline", batch="none";
    static boolean commitAttempted=false;
    record Source(String name,String hash,String sql) { }
    static String sha(byte[] bytes)throws Exception{return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));}
    static void need(boolean value,String safeCode){if(!value)throw new IllegalStateException(safeCode);}
    static String secret(String name){String value=System.getenv(name);need(value!=null&&value.length()>=16&&value.length()<=100,"MISSING_LOCAL_INPUT");return value;}
    static SQLServerDataSource data(String database,String user,String password){var d=new SQLServerDataSource();d.setServerName("sql");d.setPortNumber(1433);d.setDatabaseName(database);d.setUser(user);d.setPassword(password);d.setEncrypt("true");d.setTrustServerCertificate(true);d.setLoginTimeout(10);return d;}
    static void exec(Connection c,String sql)throws SQLException{try(var s=c.createStatement()){s.setQueryTimeout(90);boolean result=s.execute(sql);while(true){if(result){try(var r=s.getResultSet()){while(r.next()){/* Drain every result without logging content. */}}}else if(s.getUpdateCount()==-1)break;result=s.getMoreResults(Statement.CLOSE_CURRENT_RESULT);}}}
    static String one(Connection c,String sql)throws SQLException{try(var s=c.createStatement();var r=s.executeQuery(sql)){need(r.next(),"METADATA_RECEIPT_MISSING");return r.getString(1);}}
    static String property(Connection c,String name)throws SQLException{try(var s=c.prepareStatement("SELECT CONVERT(nvarchar(4000),value) FROM sys.extended_properties WHERE class=0 AND name=?")){s.setNString(1,name);try(var r=s.executeQuery()){return r.next()?r.getString(1):null;}}}
    static void property(Connection c,String name,String value)throws SQLException{try(var s=c.prepareCall("{call sys.sp_addextendedproperty(?,?)}")){s.setNString(1,name);s.setNString(2,value);s.execute();}}
    static List<Source> sources(Path directory)throws Exception{
        var rows=new ArrayList<Source>();
        for(String line:Files.readAllLines(directory.resolve("migrations.sha256"))){if(line.isBlank())continue;String[] p=line.split("  ",2);need(p.length==2&&p[0].matches("[a-f0-9]{64}")&&p[1].matches("V[0-9]+__[A-Za-z0-9_]+\\.sql"),"MANIFEST_INVALID");byte[] bytes=Files.readAllBytes(directory.resolve("sql").resolve(p[1]));need(sha(bytes).equals(p[0]),"CANONICAL_SOURCE_HASH_MISMATCH");String sql=new String(bytes,StandardCharsets.UTF_8);if(sql.startsWith("\ufeff"))sql=sql.substring(1);rows.add(new Source(p[1],p[0],sql));}
        need(rows.size()==19,"MIGRATION_COUNT");for(int i=0;i<19;i++)need(rows.get(i).name().startsWith("V"+(i+1)+"__"),"MIGRATION_ORDER");return rows;
    }
    /** GO is recognized only on its own line in normal lexical state. No SQL text is rewritten. */
    static List<String> split(String sql){
        var out=new ArrayList<String>();var b=new StringBuilder();int state=0,depth=0;
        for(String line:sql.split("(?<=\\n)",-1)){
            if(state==0&&line.trim().equalsIgnoreCase("GO")){if(!b.toString().isBlank())out.add(b.toString());b.setLength(0);continue;}
            b.append(line);
            for(int i=0;i<line.length();i++){char x=line.charAt(i),n=i+1<line.length()?line.charAt(i+1):0;
                if(state==4){if(x=='/'&&n=='*'){depth++;i++;}else if(x=='*'&&n=='/'){if(--depth==0)state=0;i++;}continue;}
                if(state==1){if(x=='\''&&n=='\''){i++;}else if(x=='\'')state=0;continue;}
                if(state==2){if(x=='"'&&n=='"'){i++;}else if(x=='"')state=0;continue;}
                if(state==3){if(x==']'&&n==']'){i++;}else if(x==']')state=0;continue;}
                if(x=='-'&&n=='-')break;if(x=='/'&&n=='*'){state=4;depth=1;i++;}else if(x=='\'')state=1;else if(x=='"')state=2;else if(x=='[')state=3;
            }
        }
        need(state==0,"UNTERMINATED_SQL_SOURCE");if(!b.toString().isBlank())out.add(b.toString());return out;
    }
    static void offline(Path directory)throws Exception{
        var all=sources(directory);int count=0;for(var source:all)count+=split(source.sql()).size();
        String sample="SELECT N'line1\nGO\nline2''x';\nGO\n/* nested /* GO */\nGO\n*/ SELECT [GO],\"GO\";\nGO\n";
        need(split(sample).size()==2&&split(sample).getFirst().contains("\nGO\nline2"),"LEXER_SELF_TEST");
        System.out.println(JSON.writeValueAsString(Map.of("offline","PASS","canonicalSources",all.size(),"batches",count,"sqlExecuted",false)));
    }
    static String manifest(List<Source> all)throws Exception{return sha((all.stream().map(s->s.name()+":"+s.hash()).reduce("fixtures-v1",(a,b)->a+"\n"+b)).getBytes(StandardCharsets.UTF_8));}
    static void scope(Connection c)throws SQLException{need(DB.equals(c.getCatalog())&&SCOPE.equals(property(c,"health_project_scope")),"DATABASE_SCOPE_MISMATCH");}
    static String catalog(Connection c)throws Exception{
        var b=new StringBuilder();
        for(String sql:List.of(
          "SELECT o.type,o.name,COALESCE(m.definition,N'') FROM sys.objects o LEFT JOIN sys.sql_modules m ON m.object_id=o.object_id WHERE o.schema_id=SCHEMA_ID('dbo') AND o.is_ms_shipped=0 ORDER BY o.type,o.name",
          "SELECT OBJECT_NAME(object_id),column_id,name,user_type_id,max_length,precision,scale,is_nullable,COALESCE(collation_name,'') FROM sys.columns WHERE OBJECT_SCHEMA_NAME(object_id)='dbo' ORDER BY OBJECT_NAME(object_id),column_id",
          "SELECT USER_NAME(grantee_principal_id),class,major_id,minor_id,permission_name,state FROM sys.database_permissions ORDER BY grantee_principal_id,class,major_id,minor_id,permission_name",
          "SELECT USER_NAME(role_principal_id),USER_NAME(member_principal_id) FROM sys.database_role_members ORDER BY role_principal_id,member_principal_id")){
            try(var s=c.createStatement();var r=s.executeQuery(sql)){int cols=r.getMetaData().getColumnCount();while(r.next()){for(int i=1;i<=cols;i++){String v=Objects.toString(r.getObject(i),"<null>");b.append(v.length()).append(':').append(v).append('|');}b.append('\n');}}
        }
        need("43".equals(one(c,"SELECT COUNT(*) FROM sys.tables WHERE schema_id=SCHEMA_ID('dbo')")),"TABLE_COUNT");
        need("152".equals(one(c,"SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID('dbo')")),"PROCEDURE_COUNT");
        need("34".equals(one(c,"SELECT COUNT(*) FROM sys.triggers WHERE parent_class=1")),"TRIGGER_COUNT");
        return sha(b.toString().getBytes(StandardCharsets.UTF_8));
    }
    static void login(Connection master,String name,String password)throws SQLException{
        need(name.matches("hp_meeting_(runtime|bootstrap)"),"PRINCIPAL_NAME");
        try(var p=master.prepareStatement("IF SUSER_ID(?) IS NOT NULL THROW 59999,'Meeting login collision',1; DECLARE @p nvarchar(100)=?; DECLARE @s nvarchar(max)=N'CREATE LOGIN ["+name+"] WITH PASSWORD='+QUOTENAME(@p,CHAR(39))+N',CHECK_POLICY=ON,CHECK_EXPIRATION=OFF'; EXEC(@s);")){p.setNString(1,name);p.setNString(2,password);p.execute();}
    }
    static SqlServerContext context(String actor,List<String> roles,String tenant,String token,SqlServerContext.Scope scope){return new SqlServerContext(UUID.randomUUID().toString(),"POST","/local-demo/setup","127.0.0.1","Synthetic meeting setup",actor,roles,tenant,token,scope);}
    static SqlServerExecutor executor(SQLServerDataSource d,boolean bootstrap){return new SqlServerExecutor(new JdbcTemplate(d),JSON,bootstrap?SqlServerExecutor.Purpose.BOOTSTRAP:SqlServerExecutor.Purpose.RUNTIME);}
    static TransactionTemplate transaction(SQLServerDataSource d){return new TransactionTemplate(new DataSourceTransactionManager(d));}
    static void fixtures()throws Exception{
        var bcrypt=new BCryptPasswordEncoder(12);String appPassword=secret("DEMO_APP_PASSWORD");
        var boot=data(DB,"hp_meeting_bootstrap",secret("DEMO_BOOTSTRAP_PASSWORD"));var bootExecutor=executor(boot,true);
        transaction(boot).execute(tx->{bootExecutor.execute(SqlServerProcedure.BOOTSTRAP_CREATE,context(null,null,null,null,SqlServerContext.Scope.BOOTSTRAP),SAD,"plataforma@example.test",bcrypt.encode(appPassword));return null;});
        var runtime=data(DB,"hp_meeting_runtime",secret("DEMO_RUNTIME_PASSWORD"));var e=executor(runtime,false);
        String sadToken=UUID.randomUUID().toString().replace("-","")+UUID.randomUUID().toString().replace("-","");
        String tenantToken=UUID.randomUUID().toString().replace("-","")+UUID.randomUUID().toString().replace("-","");
        var sad=context(SAD,List.of("SAD"),null,sadToken,SqlServerContext.Scope.REQUEST);
        var pro=context(PRO,List.of("PRO","REC"),TENANT,tenantToken,SqlServerContext.Scope.REQUEST);
        String ownerHash=bcrypt.encode(appPassword),proHash=bcrypt.encode(appPassword);
        transaction(runtime).execute(tx->{
            e.execute(SqlServerProcedure.SESSION_SAVE,context(null,null,null,null,SqlServerContext.Scope.IDENTITY),sadToken,SAD,Instant.now().plusSeconds(600));
            e.execute(SqlServerProcedure.USER_CREATE,sad,OWNER,"Administración de ejemplo","admin@example.test",ownerHash,"HUMAN",null);
            e.execute(SqlServerProcedure.USER_CREATE,sad,PRO,"Profesional de reunión","profesional@example.test",proHash,"HUMAN","DEMO-NO-ASISTENCIAL");
            var tenant=Map.of("name","Clínica ficticia · reunión","ruc",RUC,"slug","reunion","kind","CLINIC","domain","HUMAN","timezone","America/Lima","branchName","Sede principal · ejemplo","address","Dirección ficticia","specialties",List.of(SPECIALTY),"subscription",Map.of("planId","00000000-0000-0000-0000-000000000002","cycle","MONTHLY","branchQuota",2,"professionalQuota",5,"specialtyQuota",1));
            e.execute(SqlServerProcedure.SAAS_TENANT_CREATE,sad,TENANT,BRANCH,OWNER,JSON.writeValueAsString(tenant));
            e.execute(SqlServerProcedure.ORGANIZATION_BRANCH_SAVE,sad,TENANT,BRANCH2,JSON.writeValueAsString(Map.of("name","Segunda sede · ejemplo","address","Dirección ficticia","external",false,"active",true)),true);
            e.execute(SqlServerProcedure.ORGANIZATION_MEMBER_SAVE,sad,TENANT,PRO,JSON.writeValueAsString(Map.of("roles",List.of("PRO","REC"),"status","ACTIVE","branches",List.of(BRANCH,BRANCH2),"specialties",List.of(SPECIALTY))));
            e.execute(SqlServerProcedure.TENANT_SESSION_SAVE,context(null,null,TENANT,null,SqlServerContext.Scope.IDENTITY),tenantToken,PRO,Instant.now().plusSeconds(600),RUC);
            var patient=new LinkedHashMap<String,Object>();patient.put("name","Paciente ficticio de reunión");patient.put("domain","HUMAN");patient.put("identifier","DEMO-001");patient.put("birthDate","1992-05-12");patient.put("species",null);patient.put("contact",Map.of("firstName","Paciente ficticio","lastName","de reunión"));patient.put("allergies",List.of());
            e.execute(SqlServerProcedure.PATIENT_SAVE,pro,PATIENT,JSON.writeValueAsString(patient),0);
            e.execute(SqlServerProcedure.SESSION_REVOKE,pro,(Object)null);e.execute(SqlServerProcedure.SESSION_REVOKE,sad,(Object)null);return null;
        });
    }
    static void runtimeChecks()throws Exception{
        var runtime=data(DB,"hp_meeting_runtime",secret("DEMO_RUNTIME_PASSWORD"));var e=executor(runtime,false);
        transaction(runtime).execute(tx->{e.execute(SqlServerProcedure.HEALTH_READY,SqlServerContext.empty());var result=e.execute(SqlServerProcedure.IDENTITY_CREDENTIALS,context(null,null,null,null,SqlServerContext.Scope.IDENTITY),"profesional@example.test");need(result.resultSets().size()==1&&result.resultSets().getFirst().size()==1,"FIXTURE_IDENTITY_MISSING");var row=result.resultSets().getFirst().getFirst();need(PRO.equals(row.get("id"))&&new BCryptPasswordEncoder().matches(secret("DEMO_APP_PASSWORD"),(String)row.get("passwordHash")),"FIXTURE_PASSWORD_CHANGED");return null;});
        int denied=0;for(String sql:List.of("SELECT TOP(1) id FROM dbo.patients","CREATE TABLE dbo.meeting_forbidden_probe(id int)","EXEC dbo.usp_bootstrap_exists","EXEC dbo.usp_require_actor")){
            try(var c=runtime.getConnection()){try{exec(c,sql);throw new IllegalStateException("RUNTIME_PERMISSION_ESCAPE");}catch(SQLException fail){need(fail.getErrorCode()==229||fail.getErrorCode()==262,"UNEXPECTED_PERMISSION_ERROR");denied++;}}
        }
        need(denied==4,"NEGATIVE_PERMISSION_COUNT");
    }
    static void install(Path directory,boolean verifyOnly)throws Exception{
        need(SCOPE.equals(System.getenv("DEMO_STACK_SCOPE")),"STACK_SCOPE_INPUT");var all=sources(directory);String manifest=manifest(all);
        var setup=data("master","sa",secret("DEMO_SQL_SA_PASSWORD"));stage="server-metadata";
        boolean exists;try(var master=setup.getConnection()){need("16".equals(one(master,"SELECT CONVERT(varchar(4),SERVERPROPERTY('ProductMajorVersion'))")),"SQL_SERVER_VERSION");exists="1".equals(one(master,"SELECT CASE WHEN DB_ID('"+DB+"') IS NULL THEN 0 ELSE 1 END"));
            if(!exists){need(!verifyOnly,"DATABASE_ABSENT");stage="create-new-database";exec(master,"CREATE DATABASE ["+DB+"] COLLATE Latin1_General_100_CI_AS_SC;");}
        }
        setup.setDatabaseName(DB);
        try(var c=setup.getConnection()){
            if(exists){scope(c);need("COMPLETE".equals(property(c,"meeting_state")),"INCOMPLETE_INSTALLATION_REQUIRES_READONLY_RECONCILIATION");need(manifest.equals(property(c,"meeting_manifest")),"UNEXPECTED_SOURCE_VERSION");need(catalog(c).equals(property(c,"meeting_catalog")),"CATALOG_CHANGED");stage="runtime-verification";runtimeChecks();System.out.println(JSON.writeValueAsString(Map.of("status","ALREADY_COMPLETE","canonicalSources",19,"database",DB,"fixturesRepeated",false,"runtimePermissionDenials",4)));return;}
            need(!verifyOnly&&"0".equals(one(c,"SELECT COUNT(*) FROM sys.objects WHERE is_ms_shipped=0")),"NONEMPTY_DATABASE_NO_REAPPLY");
            property(c,"health_project_scope",SCOPE);property(c,"meeting_state","INSTALLING");exec(c,"ALTER DATABASE ["+DB+"] SET COMPATIBILITY_LEVEL=160;");
            stage="canonical-migrations";exec(c,"SET IMPLICIT_TRANSACTIONS OFF; BEGIN TRANSACTION;");
            try{for(var source:all){int i=0;for(String sql:split(source.sql())){batch=source.name()+":"+(++i);need("1".equals(one(c,"SELECT @@TRANCOUNT")),"OUTER_TRANSACTION_COUNT");exec(c,sql);}}batch="commit-migrations";commitAttempted=true;exec(c,"COMMIT TRANSACTION;");commitAttempted=false;}
            catch(Exception failure){if(!commitAttempted)try{exec(c,"IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;");}catch(Exception ignored){}throw failure;}
        }
        stage="separate-principals";setup.setDatabaseName("master");try(var master=setup.getConnection()){login(master,"hp_meeting_runtime",secret("DEMO_RUNTIME_PASSWORD"));login(master,"hp_meeting_bootstrap",secret("DEMO_BOOTSTRAP_PASSWORD"));}
        setup.setDatabaseName(DB);try(var c=setup.getConnection()){scope(c);exec(c,"CREATE USER hp_meeting_runtime FOR LOGIN hp_meeting_runtime; ALTER ROLE hp_runtime_executor ADD MEMBER hp_meeting_runtime; CREATE USER hp_meeting_bootstrap FOR LOGIN hp_meeting_bootstrap; ALTER ROLE hp_bootstrap_executor ADD MEMBER hp_meeting_bootstrap;");}
        stage="fixtures-through-approved-procedures";fixtures();stage="runtime-verification";runtimeChecks();
        stage="final-marker";try(var c=setup.getConnection()){scope(c);String fingerprint=catalog(c);exec(c,"SET IMPLICIT_TRANSACTIONS OFF; BEGIN TRANSACTION;");property(c,"meeting_manifest",manifest);property(c,"meeting_catalog",fingerprint);exec(c,"EXEC sys.sp_updateextendedproperty @name=N'meeting_state',@value=N'COMPLETE';");commitAttempted=true;exec(c,"COMMIT TRANSACTION;");commitAttempted=false;}
        System.out.println(JSON.writeValueAsString(Map.of("status","INSTALLED","canonicalSources",19,"database",DB,"runtimePermissionDenials",4,"fixtures","SYNTHETIC_ONLY","hostRuntimeDependencies",false)));
    }
    public static void main(String[] args){try{Path directory=args.length>1?Path.of(args[1]):Path.of("/opt/demo/data");if(args.length>0&&args[0].equals("--self-test")){offline(directory);return;}install(directory,args.length>0&&args[0].equals("--verify"));}
        catch(Throwable failure){int code=0;long line=0;for(Throwable t=failure;t!=null;t=t.getCause())if(t instanceof SQLException e){code=e.getErrorCode();if(e instanceof com.microsoft.sqlserver.jdbc.SQLServerException s&&s.getSQLServerError()!=null)line=s.getSQLServerError().getLineNumber();}
            String safe=failure instanceof IllegalStateException?failure.getMessage():"SETUP_FAILED";if(safe==null||!safe.matches("[A-Z_]+"))safe="SETUP_FAILED";
            System.err.println("DEMO_SETUP_ERROR stage="+stage+" batch="+batch+" sqlCode="+code+" line="+line+" code="+safe+" ambiguousCommit="+commitAttempted+"; preserve volume and reconcile readonly, never auto-reapply");System.exit(1);}}
}
