package com.mavric.healthcards;

import java.time.*;
import java.util.*;
import jakarta.servlet.http.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.ResponseCookie;
import org.springframework.web.bind.annotation.*;
import com.mavric.health.identity.*;
import com.mavric.health.persistence.sqlserver.*;
import com.mavric.health.shared.*;
import com.mavric.health.tenancy.*;
import com.mavric.health.audit.TraceContext;

@RestController @RequestMapping("/api/v1")
public class BranchAuthController {
    private final IdentityService identity;private final Access access;private final SqlServerCardsStore store;private final BranchTokens tokens;private final Settings settings;
    public BranchAuthController(IdentityService identity,Access access,SqlServerCardsStore store,BranchTokens tokens,Settings settings){this.identity=identity;this.access=access;this.store=store;this.tokens=tokens;this.settings=settings;}
    @PostMapping("/auth/login") public Object login(@Valid @RequestBody RucRequests.Login input,HttpServletRequest req,HttpServletResponse res){
        if(!(req.getAttribute("health.tenant") instanceof TenantRef tenant))throw ApiException.forbidden();
        var login=identity.loginBrowser(input.ruc(),input.email(),input.password(),tenant,TraceContext.address(req));
        var actor=new Actor(login.user().id(),login.user().name(),login.user().email(),tenant.id(),login.user().roles(),Checks.hash(login.token()));
        req.setAttribute("health.actor",actor);
        var branches=store.rows(req,SqlServerProcedure.LOGIN_BRANCHES,Ruc.require(input.ruc()));
        String branch=branches.size()==1?(String)branches.getFirst().get("id"):null;
        cookie(res,branch==null?login.token():tokens.issue(login.token(),actor,branch,login.expiresAt()),login.expiresAt());
        var body=new LinkedHashMap<String,Object>();body.put("user",user(actor));body.put("csrfToken",login.csrfToken());body.put("expiresAt",login.expiresAt());body.put("branches",branches);body.put("branchId",branch);body.put("requiresBranchSelection",branches.size()>1);return body;
    }
    @GetMapping("/negocios/{ruc}/sucursales") public Object branches(@PathVariable String ruc,HttpServletRequest req){access.tenant();return store.rows(req,SqlServerProcedure.LOGIN_BRANCHES,Ruc.require(ruc));}
    public record Selection(@NotBlank String branchId){}
    @PostMapping("/auth/sucursal") public Object select(@Valid @RequestBody Selection input,HttpServletRequest req,HttpServletResponse res){
        var actor=access.actor();var tenant=access.tenant();Checks.id(input.branchId());
        var branches=store.rows(req,SqlServerProcedure.LOGIN_BRANCHES,tenant.ruc());
        if(branches.stream().noneMatch(row->input.branchId().equals(row.get("id"))))throw ApiException.forbidden();
        String sid=rawSession(req);Instant expiry=Instant.parse(store.one(req,SqlServerProcedure.SESSION_CURRENT).get("expiresAt").toString());
        cookie(res,tokens.issue(sid,actor,input.branchId(),expiry),expiry);return Map.of("branchId",input.branchId(),"permissions",actor.roles());
    }
    private String rawSession(HttpServletRequest req){String h=req.getHeader("Authorization"),token=null;if(h!=null&&h.startsWith("Bearer "))token=h.substring(7);else if(req.getCookies()!=null)for(var cookie:req.getCookies())if(cookie.getName().equals("health_session"))token=cookie.getValue();if(token!=null&&token.contains("."))token=tokens.verify(token).sid();if(token==null||!token.matches("[A-Za-z0-9_-]{43}"))throw ApiException.forbidden();return token;}
    private void cookie(HttpServletResponse res,String token,Instant expires){res.addHeader("Set-Cookie",ResponseCookie.from("health_session",token).httpOnly(true).secure(settings.publicOrigin().startsWith("https:")).sameSite("Strict").path("/api").maxAge(Duration.between(Instant.now(),expires)).build().toString());}
    private static Map<String,Object> user(Actor a){return Map.of("id",a.id(),"name",a.name(),"email",a.email(),"tenantId",a.tenantId(),"roles",a.roles());}
}
