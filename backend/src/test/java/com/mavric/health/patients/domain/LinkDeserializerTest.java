package com.mavric.health.patients.domain;

import java.util.*;
import java.util.stream.Stream;
import org.junit.jupiter.api.*;
import tools.jackson.databind.ObjectMapper;
import com.mavric.health.patients.domain.Requests.Link;
import static org.junit.jupiter.api.Assertions.*;

class LinkDeserializerTest {
    static final String U="dd000000-0000-4000-8000-000000000001";
    final ObjectMapper mapper=new ObjectMapper();
    String body(String revision,String active){return "{\"userId\":\""+U+"\",\"expectedRevision\":"+revision+",\"active\":"+active+",\"relationship\":\"Tutor\",\"scopes\":[\"BILLING\",\"DOCUMENTS\"]}";}
    @Test void orderedScopesAndAllIntegerBoundariesAreExplicit(){
        for(String revision:List.of("0","1","2147483647")){
            var link=mapper.readValue(body(revision,"true"),Link.class);assertTrue(link.valid());assertEquals(Integer.valueOf(revision),link.expectedRevision());assertEquals(List.of("BILLING","DOCUMENTS"),link.scopes());
            assertThrows(UnsupportedOperationException.class,()->link.scopes().clear());
        }
        var off=mapper.readValue("{\"active\":false,\"expectedRevision\":2,\"userId\":\""+U+"\"}",Link.class);
        assertFalse(off.active());assertNull(off.relationship());assertNull(off.scopes());assertEquals(2,off.expectedRevision());
    }
    @TestFactory Stream<DynamicTest> rejectsLexicalNumericCoercion(){
        return Stream.of("-0","-1","1.0","1e0","1E+0","2147483648","999999999999999999999","\"1\"","true","false","null","[]","{}","01","+1")
                .map(v->DynamicTest.dynamicTest("revision "+v,()->assertThrows(Exception.class,()->mapper.readValue(body(v,"true"),Link.class))));
    }
    @TestFactory Stream<DynamicTest> rejectsDuplicateMissingExtraAndWrongTypesBeforeCollapse(){
        String good=body("0","true");
        var cases=new ArrayList<String>(List.of("null","[]","true","{}",good+" {}",good+" null",good+" garbage",good.replace("\"active\":true","\"active\":true,\"active\":false"),good.replace("\"active\":true","\"active\":true,\"act\\u0069ve\":true"),good.replace("\"active\":true","\"Active\":true"),good.replace("\"active\":true","\"active \":true"),good.replace("\"active\":true,",""),good.replace("\"scopes\"","\"tenantId\""),good.replace("\"userId\":\""+U+"\"","\"userId\":123"),good.replace(U,U+"suffix"),good.replace(U,U.toUpperCase(Locale.ROOT)),good.replace("\"Tutor\"","null"),good.replace("\"Tutor\"","1"),good.replace("[\"BILLING\",\"DOCUMENTS\"]","[\"DOCUMENTS\",\"DOCUMENTS\"]")));
        for(String value:List.of("null","0","\"true\"","{}","[]"))cases.add(body("0",value));
        for(String scopes:List.of("[]","null","{}","\"DOCUMENTS\"","[null]","[1]","[{}]","[true]","[\"documents\"]","[\"DOCUMENTS \"]","[\"UNKNOWN\"]"))cases.add(good.replace("[\"BILLING\",\"DOCUMENTS\"]",scopes));
        String off="{\"userId\":\""+U+"\",\"expectedRevision\":1,\"active\":false";
        cases.add(off+",\"relationship\":null}");cases.add(off+",\"scopes\":null}");cases.add(off+",\"extra\":1}");
        return cases.stream().map(v->DynamicTest.dynamicTest(v,()->assertThrows(Exception.class,()->mapper.readValue(v,Link.class))));
    }
    @Test void whitespaceUtf16AndUntrimmedValuesMatchV14(){
        String whitespace=" \t\n\u000b\f\r\u00a0\u1680\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u2028\u2029\u202f\u205f\u3000";
        for(int c:whitespace.chars().toArray())assertFalse(new Link(U,0,String.valueOf((char)c),true,List.of("DOCUMENTS")).valid(),"space "+c);
        for(String relation:List.of("x".repeat(78)+"  ","🦷".repeat(40),"\u00a0Tutor\u00a0")){
            var values=new LinkedHashMap<String,Object>();values.put("userId",U);values.put("expectedRevision",0);values.put("active",true);values.put("relationship",relation);values.put("scopes",List.of("DOCUMENTS"));
            assertEquals(relation,mapper.readValue(mapper.writeValueAsString(values),Link.class).relationship());
        }
        assertFalse(new Link(U,0,"🦷".repeat(40)+" ",true,List.of("DOCUMENTS")).valid());
        assertFalse(new Link(U,null,null,false,null).valid());assertFalse(new Link(U,1,null,null,null).valid());
        assertFalse(new Link(U,1,"",false,null).valid());assertFalse(new Link(U,1,null,false,List.of()).valid());
        var scopes=new ArrayList<>(List.of("DOCUMENTS"));var link=new Link(U,0,"Tutor",true,scopes);scopes.clear();assertEquals(List.of("DOCUMENTS"),link.scopes());
    }
    @Test void decoderDoesNotChangeOtherMapperRoutes(){assertEquals(2,mapper.readValue("{\"active\":1,\"active\":2}",Map.class).get("active"));}
}
