package com.mavric.health.persistence.sqlserver;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.*;
import java.util.stream.Stream;
import javax.sql.DataSource;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import tools.jackson.databind.ObjectMapper;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/** Offline, independent SQL-resource contracts. This parser does NOT validate T-SQL bodies or a real engine. */
class SqlServerProcedureContractTest {
    private static final String ROOT="/db/sqlserver/";
    private static final List<String> SOURCES=List.of(
            "V3__identity_infrastructure_procedures.sql", "V4__saas_organization_procedures.sql",
            "V5__clinical_procedures.sql", "V6__operations_procedures.sql");

    record SqlParameter(String name, String sqlType, int length, int scale, String defaultLiteral, boolean output) {
        JDBCType jdbcType() {
            return switch (sqlType) {
                case "char" -> JDBCType.CHAR;
                case "varchar" -> JDBCType.VARCHAR;
                case "nvarchar" -> JDBCType.NVARCHAR;
                case "bit" -> JDBCType.BIT;
                case "int" -> JDBCType.INTEGER;
                case "bigint" -> JDBCType.BIGINT;
                case "datetime2" -> JDBCType.TIMESTAMP;
                default -> throw new IllegalArgumentException("Not a public adapter type: "+sqlType);
            };
        }
    }
    record Contract(String name, List<SqlParameter> parameters) {}
    record Snapshot(Map<String,Contract> procedures, Map<String,String> access) {}

    private static String resource(String name) throws IOException {
        try (var in=SqlServerProcedureContractTest.class.getResourceAsStream(ROOT+name)) {
            assertNotNull(in, "Missing immutable SQL resource "+name);
            return new String(in.readAllBytes(),StandardCharsets.UTF_8);
        }
    }

    private static Snapshot snapshot() throws IOException {
        Map<String,Contract> contracts=new LinkedHashMap<>();
        for (String source:SOURCES) {
            for (Contract contract:procedures(resource(source)).values())
                assertNull(contracts.put(contract.name(),contract),"Duplicate SQL procedure "+contract.name());
        }
        Map<String,String> access=permissions(resource("V8__execution_permissions.sql"));
        assertEquals(133,contracts.size());
        assertEquals(contracts.keySet(),access.keySet(),"V8 must classify ALL and ONLY V3-V6 procedures");
        assertEquals(107,access.values().stream().filter("runtime"::equals).count());
        assertEquals(2,access.values().stream().filter("bootstrap"::equals).count());
        assertEquals(24,access.values().stream().filter("private"::equals).count());
        return new Snapshot(contracts,access);
    }

    private static Set<String> publicNames(Snapshot snapshot) {
        Set<String> names=new TreeSet<>();
        snapshot.access().forEach((name,access)-> {
            if (!access.equals("private") && !name.equals("usp_request_context")) names.add(name);
        });
        return names;
    }
    private static String name(SqlServerProcedure procedure) {
        String call=procedure.call();
        assertTrue(call.startsWith("{call dbo.usp_") && call.endsWith(")}"));
        return call.substring("{call dbo.".length(),call.indexOf('('));
    }

    @Test void catalogIsExactV8PublicAllowlistWithTwoBootstrapEntriesAndNoInfrastructureOrHelpers() throws Exception {
        Snapshot snapshot=snapshot();
        Map<String,SqlServerProcedure> catalog=new TreeMap<>();
        for (SqlServerProcedure procedure:SqlServerProcedure.values())
            assertNull(catalog.put(name(procedure),procedure),"Duplicate descriptor");
        assertEquals(127,catalog.size());
        for(String delta:List.of("usp_agenda_context","usp_agenda_list","usp_agenda_collection_save","usp_agenda_collection_summary"))assertNotNull(catalog.remove(delta),"Explicit V19 delta");
        for(String delta:List.of("usp_medical_services","usp_medical_agreements","usp_medical_catalog_save"))assertNotNull(catalog.remove(delta),"Explicit V17 delta");
        for(String delta:procedures(resource("V16__patient_antecedents_consultations.sql")).keySet())assertNotNull(catalog.remove(delta),"Explicit V16 delta");
        for(String delta:List.of("usp_identity_tenant_ruc_lock","usp_tenant_space_resolve","usp_tenant_profile_save","usp_tenant_session_save"))assertNotNull(catalog.remove(delta),"Explicit V15 delta");
        assertNotNull(catalog.remove("usp_patient_links_list"),"Explicit V13 delta");
        assertNotNull(catalog.remove("usp_patient_link_edit_get"),"Only explicit V14 management delta");
        assertEquals(publicNames(snapshot),catalog.keySet());
        assertFalse(catalog.containsKey("usp_request_context"));
        assertEquals(2,catalog.values().stream().filter(SqlServerProcedure::bootstrap).count());
        assertTrue(SqlServerProcedure.class.isEnum(),"Cannot construct arbitrary descriptors");
        assertEquals(0,SqlServerProcedure.class.getConstructors().length);
    }

    @TestFactory Stream<DynamicTest> eachPublicSignatureMatchesOrderTypeLengthNameAndDefaultFromSqlResources() throws Exception {
        Snapshot snapshot=snapshot();
        return Arrays.stream(SqlServerProcedure.values()).filter(p->p!=SqlServerProcedure.PATIENT_LINKS_LIST && p!=SqlServerProcedure.PATIENT_LINK_EDIT_GET && !Set.of(SqlServerProcedure.IDENTITY_TENANT_RUC_LOCK,SqlServerProcedure.TENANT_SPACE_RESOLVE,SqlServerProcedure.TENANT_PROFILE_SAVE,SqlServerProcedure.TENANT_SESSION_SAVE).contains(p)).map(procedure -> DynamicTest.dynamicTest(name(procedure),()-> {
            Contract contract=snapshot.procedures().get(name(procedure));
            if(contract==null)contract=procedures(resource("V16__patient_antecedents_consultations.sql")).get(name(procedure));
            if(contract==null)contract=procedures(resource("V17__clinical_catalog.sql")).get(name(procedure));
            if(contract==null)contract=procedures(resource("V19__agenda_collections.sql")).get(name(procedure));
            assertNotNull(contract);
            assertEquals("bootstrap".equals(snapshot.access().get(contract.name())),procedure.bootstrap());
            assertEquals(contract.parameters().size(),procedure.parameters().size(),"Explicit defaults may not be omitted");
            assertEquals("{call dbo."+contract.name()+"("+String.join(",",
                    Collections.nCopies(contract.parameters().size(),"?"))+")}",procedure.call());
            for (int i=0;i<contract.parameters().size();i++) {
                SqlParameter sql=contract.parameters().get(i);
                SqlServerProcedure.Parameter java=procedure.parameters().get(i);
                String location=contract.name()+" parameter "+(i+1);
                assertFalse(sql.output(),location+" public OUTPUT forbidden");
                assertEquals(sql.name(),java.sqlName(),location+" name/order");
                assertEquals(sql.jdbcType(),java.type(),location+" type");
                assertEquals(sql.length(),java.length(),location+" length/MAX/precision");
                assertEquals(0,sql.scale(),location+" unexpected numeric scale");
                assertEquals(sql.defaultLiteral(),java.defaultLiteral(),location+" default");
                assertEquals(Set.of("char","varchar").contains(sql.sqlType()),java.ascii(),location+" ASCII policy");
            }
        }));
    }

    @Test void v13AddsOnlyPinnedRuntimeLinksReadWithExactSignatureAndObjectPermissions() throws Exception {
        String sql=resource("V13__patient_links_read.sql");
        assertEquals("667D8C0731557625C662285DC0E56C885B57E50E7AFA5AF63EBEA2030E3ACF51",
                HexFormat.of().withUpperCase().formatHex(java.security.MessageDigest.getInstance("SHA-256").digest(sql.getBytes(StandardCharsets.UTF_8))));
        var parsed=procedures(sql);
        assertEquals(Set.of("usp_patient_links_list"),parsed.keySet());
        var contract=parsed.get("usp_patient_links_list");var procedure=SqlServerProcedure.PATIENT_LINKS_LIST;
        assertFalse(procedure.bootstrap());assertEquals("{call dbo.usp_patient_links_list(?,?,?)}",procedure.call());
        assertEquals(List.of(new SqlParameter("patient_id","char",36,0,null,false),new SqlParameter("limit","int",0,0,"50",false),new SqlParameter("offset","int",0,0,"0",false)),contract.parameters());
        assertEquals(3,procedure.parameters().size());
        for(int i=0;i<3;i++){var expected=contract.parameters().get(i);var actual=procedure.parameters().get(i);assertEquals(expected.name(),actual.sqlName());assertEquals(expected.jdbcType(),actual.type());assertEquals(expected.length(),actual.length());assertEquals(expected.defaultLiteral(),actual.defaultLiteral());assertEquals(i==0,actual.ascii());}
        var tokens=lex(sql);var permissions=new ArrayList<List<String>>();
        for(int i=0;i<tokens.size();i++)if(is(tokens.get(i),"GRANT") || is(tokens.get(i),"DENY") || is(tokens.get(i),"REVOKE")){
            var cursor=new Cursor(tokens,i);var statement=new ArrayList<String>();do{statement.add(cursor.take());}while(!statement.getLast().equals(";"));permissions.add(statement);
        }
        assertEquals(List.of(List.of("GRANT","EXECUTE","ON","OBJECT",":",":","dbo",".","usp_patient_links_list","TO","hp_runtime_executor",";"),List.of("DENY","EXECUTE","ON","OBJECT",":",":","dbo",".","usp_patient_links_list","TO","hp_bootstrap_executor",";")),permissions);
    }

    @Test void v14FinalR1IsPinnedAndOnlyAddsEditReaderWithoutRelaxingHistoricParser() throws Exception {
        String sql=resource("V14__patient_link_revision.sql");
        assertEquals("418B1C1B864DE9A6E7AC20E0F641630422A8D2451B3D42F7E9B97FB835B0EA9A",HexFormat.of().withUpperCase().formatHex(java.security.MessageDigest.getInstance("SHA-256").digest(sql.getBytes(StandardCharsets.UTF_8))));
        var parsed=procedures(sql);assertEquals(Set.of("usp_patient_link_edit_get"),parsed.keySet());
        assertEquals(List.of(new SqlParameter("patient_id","char",36,0,null,false),new SqlParameter("user_id","char",36,0,null,false)),parsed.get("usp_patient_link_edit_get").parameters());
        var descriptor=SqlServerProcedure.PATIENT_LINK_EDIT_GET;assertFalse(descriptor.bootstrap());assertEquals("{call dbo.usp_patient_link_edit_get(?,?)}",descriptor.call());
        for(int i=0;i<2;i++){var actual=descriptor.parameters().get(i);assertEquals(i==0?"patient_id":"user_id",actual.sqlName());assertEquals(JDBCType.CHAR,actual.type());assertEquals(36,actual.length());assertTrue(actual.ascii());assertNull(actual.defaultLiteral());}
        var tokens=lex(sql);int alters=0;var acl=new ArrayList<List<String>>();
        for(int i=0;i<tokens.size()-1;i++){
            if(is(tokens.get(i),"ALTER") && is(tokens.get(i+1),"PROCEDURE")){
                alters++;var c=new Cursor(tokens,i);for(String token:List.of("ALTER","PROCEDURE","dbo",".","usp_patient_link_save","@patient_id","char","(","36",")",",","@input","nvarchar","(","max",")","AS"))c.expect(token);
            }
            if(is(tokens.get(i),"GRANT") || is(tokens.get(i),"DENY") || is(tokens.get(i),"REVOKE")){
                var c=new Cursor(tokens,i);var statement=new ArrayList<String>();do{statement.add(c.take());}while(!statement.getLast().equals(";"));acl.add(statement);
            }
        }
        assertEquals(1,alters);assertEquals(List.of(List.of("GRANT","EXECUTE","ON","OBJECT",":",":","dbo",".","usp_patient_link_edit_get","TO","hp_runtime_executor",";"),List.of("DENY","EXECUTE","ON","OBJECT",":",":","dbo",".","usp_patient_link_edit_get","TO","hp_bootstrap_executor",";")),acl);
        assertEquals(List.of("patient_id","input"),SqlServerProcedure.PATIENT_LINK_SAVE.parameters().stream().map(SqlServerProcedure.Parameter::sqlName).toList());
    }

    @Test void contextRemainsInternalAndAllTenParametersAreBoundAndClearedFromIndependentSqlTypes() throws Exception {
        Contract context=snapshot().procedures().get("usp_request_context");
        assertEquals(List.of("request_id","method","route","source_ip","user_agent","actor_id",
                "actor_roles","tenant_id","token_hash","scope"),
                context.parameters().stream().map(SqlParameter::name).toList());
        assertEquals("'REQUEST'",context.parameters().get(9).defaultLiteral());
        assertEquals(-1,context.parameters().get(6).length(),"SQL declares roles MAX; V3 body independently caps context bytes");
        DataSource ds=mock(DataSource.class);
        Connection connection=mock(Connection.class);
        when(ds.getConnection()).thenReturn(connection);
        CallableStatement before=emptyStatement(),business=emptyStatement(),after=emptyStatement();
        String contextCall="{call dbo.usp_request_context("+String.join(",",Collections.nCopies(10,"?"))+")}";
        when(connection.prepareCall(contextCall)).thenReturn(before,after);
        when(connection.prepareCall("{call dbo.usp_health_ready()}")).thenReturn(business);
        new SqlServerExecutor(new JdbcTemplate(ds),new ObjectMapper(),SqlServerExecutor.Purpose.RUNTIME)
                .execute(SqlServerProcedure.HEALTH_READY,SqlServerContext.empty());
        for (CallableStatement statement:List.of(before,after)) {
            for (int i=0;i<9;i++) verify(statement).setNull(i+1,context.parameters().get(i).jdbcType().getVendorTypeNumber());
            verify(statement).setString(10,"REQUEST");
            verify(statement,never()).getParameterMetaData();
            verify(statement).close();
        }
        verify(connection,times(3)).prepareCall(anyString());
    }

    @Test void v15RucHasClosedDescriptorsObjectAclAndPreDdlLegacyGate() throws Exception {
        String sql=resource("V15__tenant_ruc.sql");var parsed=procedures(sql);
        Map<String,SqlServerProcedure> expected=Map.of("usp_identity_tenant_ruc_lock",SqlServerProcedure.IDENTITY_TENANT_RUC_LOCK,
            "usp_tenant_space_resolve",SqlServerProcedure.TENANT_SPACE_RESOLVE,"usp_tenant_profile_save",SqlServerProcedure.TENANT_PROFILE_SAVE,"usp_tenant_session_save",SqlServerProcedure.TENANT_SESSION_SAVE);
        assertEquals(expected.keySet(),parsed.keySet());
        for(var entry:expected.entrySet()){
            var signature=parsed.get(entry.getKey()).parameters();var descriptor=entry.getValue();assertFalse(descriptor.bootstrap());assertEquals(signature.size(),descriptor.parameters().size());
            for(int i=0;i<signature.size();i++){var s=signature.get(i);var j=descriptor.parameters().get(i);assertEquals(s.name(),j.sqlName());assertEquals(s.jdbcType(),j.type());assertEquals(s.length(),j.length());assertEquals(s.defaultLiteral(),j.defaultLiteral());assertEquals(Set.of("char","varchar").contains(s.sqlType()),j.ascii());}
        }
        assertEquals(3,SqlServerProcedure.SESSION_SAVE.parameters().size(),"Platform signature stays compatible; tenant entry is explicit V15");
        assertEquals(List.of("token_hash","user_id","expires_at","ruc"),SqlServerProcedure.TENANT_SESSION_SAVE.parameters().stream().map(SqlServerProcedure.Parameter::sqlName).toList());
        var tokens=lex(sql);var permissions=new ArrayList<List<String>>();var alters=new HashSet<String>();
        for(int i=0;i<tokens.size()-4;i++){
            if(is(tokens.get(i),"ALTER")&&is(tokens.get(i+1),"PROCEDURE")){var c=new Cursor(tokens,i);c.expect("ALTER");c.expect("PROCEDURE");c.expect("dbo");c.expect(".");alters.add(c.take());}
            if(is(tokens.get(i),"GRANT")||is(tokens.get(i),"DENY")||is(tokens.get(i),"REVOKE")){var c=new Cursor(tokens,i);var statement=new ArrayList<String>();do{statement.add(c.take());}while(!statement.getLast().equals(";"));permissions.add(statement);}
        }
        assertEquals(Set.of("usp_tenant_by_slug","usp_platform_tenants","usp_saas_tenant_create","usp_platform_audit","usp_session_save"),alters);
        var acl=new ArrayList<List<String>>();for(String name:List.of("usp_tenant_session_save","usp_identity_tenant_ruc_lock","usp_tenant_space_resolve","usp_tenant_profile_save")){
            acl.add(List.of("GRANT","EXECUTE","ON","OBJECT",":",":","dbo",".",name,"TO","hp_runtime_executor",";"));acl.add(List.of("DENY","EXECUTE","ON","OBJECT",":",":","dbo",".",name,"TO","hp_bootstrap_executor",";"));
        }
        assertEquals(acl,permissions);assertTrue(sql.indexOf("THROW 51003,N'HP_CONFLICT:BACKFILL_REQUIRED")<sql.indexOf("ALTER TABLE dbo.tenants ADD ruc"));
        assertTrue(sql.contains("WITH(UPDLOCK,HOLDLOCK,INDEX(UQ_tenants_ruc))"));assertTrue(sql.contains("profile_revision=profile_revision+1"));
        assertTrue(sql.contains("TENANT_PROFILE_UPDATED"));assertTrue(sql.contains("Tenant login requires the RUC session entry"));
    }

    private static CallableStatement emptyStatement() throws SQLException {
        CallableStatement statement=mock(CallableStatement.class);
        when(statement.getUpdateCount()).thenReturn(-1);
        return statement;
    }

    @Test void parserConsumesMultilineDefaultsQuotedCommasCommentsAndExactDatetime2Precision() {
        var contracts=procedures("""
                -- CREATE PROCEDURE dbo.usp_not_real AS
                /* nested /* CREATE PROCEDURE */ comments */
                CREATE PROCEDURE dbo.usp_example
                 @from datetime2(6)=NULL,
                 @payload nvarchar(max)=N'a,b''c AS', -- comma is inside a literal
                 @count int=100, @enabled bit=0
                AS BEGIN SELECT N'CREATE PROCEDURE dbo.usp_fake AS'; END;
                """);
        assertEquals(Set.of("usp_example"),contracts.keySet());
        List<SqlParameter> parameters=contracts.get("usp_example").parameters();
        assertEquals(4,parameters.size());
        assertEquals(new SqlParameter("from","datetime2",6,0,"NULL",false),parameters.get(0));
        assertEquals(new SqlParameter("payload","nvarchar",-1,0,"N'a,b''c AS'",false),parameters.get(1));
        assertEquals("100",parameters.get(2).defaultLiteral());
    }

    @Test void parserRejectsUnknownPartialTypesOutputsInPublicMappingAndUnconsumedSignatureTokens() {
        for (String declaration:List.of("@x datetime(6)","@x datetime2(6) garbage",
                "@x datetime2","@x datetime2(7)","@x nvarchar","@x nvarchar(garbage)",
                "@x int = 0 + 1","@x int,","@x int @y bigint","@x bit READONLY")) {
            assertThrows(IllegalArgumentException.class,()->procedures("CREATE PROCEDURE dbo.usp_bad "+declaration+" AS BEGIN END"),declaration);
        }
        var output=procedures("CREATE PROCEDURE dbo.usp_private @x decimal(14,3) OUTPUT AS BEGIN END")
                .get("usp_private").parameters().get(0);
        assertTrue(output.output());
        assertThrows(IllegalArgumentException.class,output::jdbcType,"Private decimal OUTPUT is not a public runtime type");
        assertThrows(IllegalArgumentException.class,()->procedures("CREATE PROCEDURE dbo.usp_bad @x int"));
        assertThrows(IllegalArgumentException.class,()->procedures("/* unterminated"));
        assertThrows(IllegalArgumentException.class,()->procedures("CREATE PROCEDURE dbo.usp_bad @x nvarchar(max)=N'unterminated"));
    }

    @Test void permissionParserRejectsDuplicatesUnknownClassesAndExtraTupleFields() {
        for (String values:List.of("(N'usp_x',N'other')","(N'usp_x',N'runtime',N'extra')",
                "(N'usp_x',N'runtime'),(N'usp_x',N'private')")) {
            assertThrows(IllegalArgumentException.class,()->permissions(
                    "INSERT @procedures(name,access_class) VALUES "+values+";"));
        }
    }

    /** Tokenize SQL with comments/escaped strings intact: a signature must be consumed through AS,
     *  not partially matched by a permissive regex. Procedure bodies are deliberately not interpreted. */
    private static Map<String,Contract> procedures(String text) {
        List<String> tokens=lex(text);
        Map<String,Contract> contracts=new LinkedHashMap<>();
        for (int i=0;i+1<tokens.size();i++) {
            if (!is(tokens.get(i),"CREATE") || !is(tokens.get(i+1),"PROCEDURE")) continue;
            Cursor cursor=new Cursor(tokens,i+2);
            cursor.expect("dbo"); cursor.expect(".");
            String name=cursor.take();
            require(name.matches("usp_[a-z_]+"),"Unexpected procedure name");
            List<SqlParameter> parameters=new ArrayList<>();
            Set<String> names=new HashSet<>();
            if (!cursor.at("AS")) {
                do {
                    String parameter=cursor.take();
                    require(parameter.matches("@[a-z_]+") && names.add(parameter),"Invalid or duplicate parameter");
                    String type=cursor.take().toLowerCase(Locale.ROOT);
                    int length=0,scale=0;
                    switch (type) {
                        case "char","varchar","nvarchar" -> {
                            cursor.expect("(");
                            String size=cursor.take();
                            length=is(size,"max") ? -1 : positive(size);
                            require(length!=-1 || type.equals("nvarchar"),"Unexpected MAX type");
                            cursor.expect(")");
                        }
                        case "datetime2" -> {
                            cursor.expect("("); length=positive(cursor.take()); cursor.expect(")");
                            require(length==6,"Unexpected DATETIME2 precision");
                        }
                        case "decimal" -> {
                            cursor.expect("("); length=positive(cursor.take()); cursor.expect(",");
                            scale=positive(cursor.take()); cursor.expect(")");
                        }
                        case "bit","int","bigint" -> { }
                        default -> throw new IllegalArgumentException("Unknown parameter SQL type: "+type);
                    }
                    String defaultLiteral=null;
                    if (cursor.accept("=")) {
                        defaultLiteral=cursor.take();
                        if (defaultLiteral.equals("-")) defaultLiteral+=cursor.take();
                        require(is(defaultLiteral,"NULL") || defaultLiteral.matches("-?[0-9]+")
                                || defaultLiteral.startsWith("'") || defaultLiteral.startsWith("N'"),"Unsupported default");
                    }
                    boolean output=cursor.accept("OUTPUT");
                    parameters.add(new SqlParameter(parameter.substring(1),type,length,scale,defaultLiteral,output));
                } while (cursor.accept(","));
            }
            cursor.expect("AS");
            require(contracts.put(name,new Contract(name,List.copyOf(parameters)))==null,"Duplicate procedure");
            i=cursor.position-1;
        }
        return contracts;
    }

    private static Map<String,String> permissions(String text) {
        List<String> tokens=lex(text);
        Cursor cursor=null;
        for (int i=0;i+1<tokens.size();i++) {
            if (is(tokens.get(i),"INSERT") && is(tokens.get(i+1),"@procedures")) {
                require(cursor==null,"Multiple permission matrices");
                cursor=new Cursor(tokens,i+2);
            }
        }
        require(cursor!=null,"Missing V8 permission matrix");
        cursor.expect("(");cursor.expect("name");cursor.expect(",");cursor.expect("access_class");cursor.expect(")");cursor.expect("VALUES");
        Map<String,String> access=new LinkedHashMap<>();
        do {
            cursor.expect("(");
            String name=unquote(cursor.take());cursor.expect(",");
            String group=unquote(cursor.take());cursor.expect(")");
            require(name.matches("usp_[a-z_]+") && Set.of("runtime","bootstrap","private").contains(group),"Unknown matrix entry");
            require(access.put(name,group)==null,"Duplicate permission entry");
        } while (cursor.accept(","));
        cursor.expect(";");
        return access;
    }

    private static String unquote(String value) {
        require(value.startsWith("N'") && value.endsWith("'"),"Expected Unicode SQL literal");
        return value.substring(2,value.length()-1).replace("''","'");
    }
    private static int positive(String value) {
        require(value.matches("[1-9][0-9]*"),"Invalid type modifier");
        return Integer.parseInt(value);
    }
    private static boolean is(String actual,String expected) { return actual.equalsIgnoreCase(expected); }
    private static void require(boolean valid,String message) { if (!valid) throw new IllegalArgumentException(message); }

    private static final class Cursor {
        final List<String> tokens;
        int position;
        Cursor(List<String> tokens,int start) { this.tokens=tokens;position=start; }
        String take() {
            require(position<tokens.size(),"Incomplete signature");
            return tokens.get(position++);
        }
        boolean at(String token) { return position<tokens.size() && is(tokens.get(position),token); }
        boolean accept(String token) { if (!at(token)) return false;position++;return true; }
        void expect(String token) { require(accept(token),"Expected "+token+" in signature"); }
    }

    private static List<String> lex(String text) {
        List<String> tokens=new ArrayList<>();
        int i=0;
        while (i<text.length()) {
            char ch=text.charAt(i);
            if (Character.isWhitespace(ch)) { i++;continue; }
            if (text.startsWith("--",i)) {
                while(i<text.length() && text.charAt(i)!='\n') i++;
                continue;
            }
            if (text.startsWith("/*",i)) {
                int depth=1;i+=2;
                while(i<text.length() && depth>0) {
                    if (text.startsWith("/*",i)) { depth++;i+=2; }
                    else if (text.startsWith("*/",i)) { depth--;i+=2; }
                    else i++;
                }
                require(depth==0,"Unterminated comment");continue;
            }
            int start=i;
            if (ch=='\'' || (ch=='N' && i+1<text.length() && text.charAt(i+1)=='\'')) {
                if (ch=='N') i++;
                i++;boolean closed=false;
                while(i<text.length()) {
                    if (text.charAt(i++)=='\'') {
                        if (i<text.length() && text.charAt(i)=='\'') { i++;continue; }
                        closed=true;break;
                    }
                }
                require(closed,"Unterminated literal");
            } else if (ch=='[') {
                i++;boolean closed=false;
                while(i<text.length()) {
                    if (text.charAt(i++)==']') {
                        if (i<text.length() && text.charAt(i)==']') { i++;continue; }
                        closed=true;break;
                    }
                }
                require(closed,"Unterminated identifier");
            } else if (Character.isLetterOrDigit(ch) || ch=='_' || ch=='@') {
                while(i<text.length() && (Character.isLetterOrDigit(text.charAt(i)) || "_@".indexOf(text.charAt(i))>=0)) i++;
            } else i++;
            tokens.add(text.substring(start,i));
        }
        return tokens;
    }
}
