"""Integration against the running Docker stack. Creates fictional QA tenants.

Python standard library only; secrets are read from .env and never printed.
Run from workspace: python backend/scripts/verify-api.py
"""
import concurrent.futures
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import secrets
import subprocess
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
CONFIG = dict(line.split("=", 1) for line in (ROOT / ".env").read_text(encoding="utf-8-sig").splitlines() if "=" in line and not line.startswith("#"))
BASE = CONFIG.get("HEALTH_BASE_DOMAIN", "health.localhost")
URL = os.getenv("HEALTH_TEST_URL", "http://127.0.0.1:8080")
RUN = secrets.token_hex(5)
PASSWORD = "Health-QA-" + secrets.token_hex(12)
REPORT = []
HTTP = urllib.request.build_opener(urllib.request.ProxyHandler({}))


def check(condition, label):
    if not condition:
        raise AssertionError(label)
    REPORT.append(label)


def api(method, path, body=None, host=BASE, token=None, key=None, expected=200, extra=None):
    headers = {"Host": host, "Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    if key:
        headers["Idempotency-Key"] = key
    headers.update(extra or {})
    req = urllib.request.Request(URL + path, data=None if body is None else json.dumps(body).encode(), headers=headers, method=method)
    try:
        with HTTP.open(req, timeout=30) as res:
            status, raw = res.status, res.read()
    except urllib.error.HTTPError as e:
        status, raw = e.code, e.read()
    try:
        data = json.loads(raw) if raw else None
    except ValueError:
        data = {"detail": "non-JSON response"}
    if expected is not None and status != expected:
        raise AssertionError(f"{method} {path}: expected {expected}, got {status}; {data.get('detail', '') if isinstance(data, dict) else ''}")
    if expected is not None:
        REPORT.append(f"{method} {path} -> {status}")
    return (status, data) if expected is None else data


def login(email, host=BASE):
    password = CONFIG["BOOTSTRAP_ADMIN_PASSWORD"] if email == CONFIG["BOOTSTRAP_ADMIN_EMAIL"] else PASSWORD
    return api("POST", "/api/auth/login", {"email": email, "password": password}, host=host)["accessToken"]


def user(name, domain=None):
    return {"name": "QA " + name, "email": name + "." + RUN + "@example.test", "password": PASSWORD, "domain": domain, "credential": "QA-" + RUN}


def member(host, admin, branch, name, roles, specialty=None, existing=None, status="ACTIVE"):
    body = {"roles": roles, "status": status, "branches": [branch], "specialties": [specialty] if specialty else []}
    body["userId" if existing else "user"] = existing or user(name, "HUMAN" if "PRO" in roles else None)
    return api("PUT", "/api/tenant/members", body, host, admin)


def race(action, label):
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(action, range(2)))
    check(sorted(r[0] for r in results) == [200, 409], label)
    return next(r[1] for r in results if r[0] == 200)


def main():
    api("GET", "/api/public/context")
    sad = login(CONFIG["BOOTSTRAP_ADMIN_EMAIL"])
    plans = api("GET", "/api/platform/plans", token=sad)
    check(len(plans) >= 4, "four configurable seeded plans")
    catalog = api("GET", "/api/platform/specialties", token=sad)
    check(len(catalog) == 241, "241 specialty profiles available")
    human = next(s["code"] for s in catalog if s["domain"] == "HUMAN" and not s["dental"])
    dental = next(s["code"] for s in catalog if s["domain"] == "HUMAN" and s["dental"] and "HUMAN_DENTAL" in s["profile"]["componentFamilies"])
    animal = next(s["code"] for s in catalog if s["domain"] == "ANIMAL" and not s["dental"])
    plan_id = "00000000-0000-0000-0000-000000000003"
    contract = {"planId": plan_id, "cycle": "MONTHLY", "branchQuota": 3, "professionalQuota": 20, "specialtyQuota": 30}
    tenants = []
    for suffix, kind, domain, spec in [("a", "HOSPITAL", "HUMAN", human), ("b", "HOSPITAL", "HUMAN", human), ("v", "VETERINARY", "ANIMAL", animal)]:
        body = {"name": "QA " + suffix + " " + RUN, "slug": "qa-" + RUN + "-" + suffix, "kind": kind, "domain": domain, "owner": user("owner-" + suffix), "timezone": "America/Lima", "branchName": "Central", "address": "Datos ficticios", "specialties": [spec] + ([dental] if domain == "HUMAN" else []), "subscription": contract}
        tenant = api("POST", "/api/platform/tenants", body, token=sad)
        host = tenant["hostname"]
        check(host == body["slug"] + "." + BASE, "tenant subdomain created at onboarding")
        owner = login(body["owner"]["email"], host)
        cfg = api("GET", "/api/tenant/configuration", host=host, token=owner)
        tenants.append((tenant, host, owner, cfg["branches"][0]["id"], body))
    tenant_a, host, admin, branch, body = tenants[0]
    tenant_b, host_b, admin_b, branch_b, _ = tenants[1]
    _, host_v, admin_v, branch_v, _ = tenants[2]
    api("POST", "/api/platform/tenants", dict(body, owner=user("duplicate")), token=sad, expected=409)
    api("POST", "/api/platform/tenants", dict(body, slug="admin", owner=user("reserved")), token=sad, expected=400)
    check(not any(u["email"] == user("duplicate")["email"] for u in api("GET", "/api/platform/users?limit=200", token=sad)), "failed onboarding rolls back newly created owner")
    api("GET", "/api/tenant/configuration", host=host_b, token=admin, expected=401)
    api("GET", "/api/tenant/configuration", host=host, token=sad, expected=401)
    api("GET", "/api/platform/tenants", host=host, token=admin, expected=403)
    api("GET", "/api/public/context", host="absent-" + RUN + "." + BASE, expected=404)
    context = api("GET", "/api/public/context", host=host, extra={"X-Tenant-ID": tenant_b["id"], "X-Forwarded-Host": host_b})
    check(context["id"] == tenant_a["id"], "forged tenant and forwarded host ignored")

    pro = member(host, admin, branch, "doctor", ["PRO"], human)
    pro_token = login(user("doctor")["email"], host)
    member(host_b, admin_b, branch_b, "unused", ["PRO"], human, existing=pro["id"])
    pro_b = login(user("doctor")["email"], host_b)
    reception = member(host, admin, branch, "reception", ["REC"])
    rec = login(user("reception")["email"], host)
    cashier = member(host, admin, branch, "cashier", ["CAJ"])
    cash = login(user("cashier")["email"], host)
    warehouse = member(host, admin, branch, "warehouse", ["ALM", "FAR"])
    stock = login(user("warehouse")["email"], host)
    invited = member(host, admin, branch, "invited", ["PRO"], human, status="INVITED")
    api("POST", "/api/auth/login", {"email": user("invited")["email"], "password": PASSWORD}, host, expected=401)
    invitation = api("POST", "/api/auth/invitations/accept", {"email": user("invited")["email"], "password": PASSWORD}, host)
    api("GET", "/api/auth/me", host=host, token=invitation["accessToken"])
    branch2 = api("POST", "/api/tenant/branches", {"name": "Segunda", "address": "QA", "external": False, "active": True}, host, admin)["id"]
    branch3 = api("POST", "/api/tenant/branches", {"name": "Tercera", "address": "QA", "external": False, "active": True}, host, admin)["id"]
    api("POST", "/api/tenant/branches", {"name": "Fuera del cupo", "address": "QA", "external": False, "active": True}, host, admin, expected=409)
    api("PUT", "/api/tenant/subscription", dict(contract, branchQuota=2), host, admin, expected=409)
    for identity, roles, specs in [(pro["id"], ["PRO"], [human, dental]), (warehouse["id"], ["ALM", "FAR"], [])]:
        api("PUT", "/api/tenant/members", {"userId": identity, "roles": roles, "status": "ACTIVE", "branches": [branch, branch2, branch3], "specialties": specs}, host, admin)

    def patient(identifier, domain="HUMAN"):
        return {"name": "Paciente ficticio " + identifier, "domain": domain, "identifier": identifier, "birthDate": "2001-01-01", "species": "CANINE" if domain == "ANIMAL" else None, "contact": {}, "allergies": []}
    patient_a = api("POST", "/api/patients", patient("qa-a-" + RUN), host, rec)
    patient_a2 = api("POST", "/api/patients", patient("qa-a2-" + RUN), host, rec)
    patient_b = api("POST", "/api/patients", patient("qa-b-" + RUN), host_b, pro_b)
    patient_v = api("POST", "/api/patients", patient("qa-v-" + RUN, "ANIMAL"), host_v, admin_v)
    api("POST", "/api/patients", patient("wrong-domain-" + RUN), host_v, admin_v, expected=400)
    api("GET", "/api/patients/" + patient_b["id"], host=host, token=pro_token, expected=404)
    api("POST", "/api/patients", dict(patient("tamper"), tenantId=tenant_b["id"]), host, rec, expected=400)
    api("PUT", "/api/patients/" + patient_a["id"], {"expectedRevision": 1, "patient": patient("qa-a-" + RUN)}, host, rec)
    api("PUT", "/api/patients/" + patient_a["id"], {"expectedRevision": 1, "patient": patient("qa-a-" + RUN)}, host, rec, expected=409)
    api("GET", "/api/patients/" + patient_a["id"] + "/history", host=host, token=admin, expected=403)

    start = dt.datetime.now(dt.timezone.utc) + dt.timedelta(days=2)
    stamp = lambda x: x.isoformat().replace("+00:00", "Z")
    booking = {"patientId": patient_a["id"], "branchId": branch, "professionalId": pro["id"], "specialtyCode": human, "startsAt": stamp(start), "endsAt": stamp(start + dt.timedelta(minutes=30)), "status": "RESERVED", "service": "Consulta", "note": "QA"}
    appointment = race(lambda i: api("POST", "/api/appointments", booking, host, rec, key=RUN + "-race-" + str(i), expected=None), "concurrent professional bookings: one winner")
    api("POST", "/api/appointments", dict(booking, patientId=patient_b["id"], branchId=branch_b), host_b, pro_b, key=RUN + "-cross", expected=409)
    api("PUT", "/api/appointments/" + appointment["id"], {"expectedRevision": 1, "status": "CANCELLED"}, host, rec)
    booking["startsAt"], booking["endsAt"] = stamp(start + dt.timedelta(hours=2)), stamp(start + dt.timedelta(hours=3))
    reserved = api("POST", "/api/appointments", booking, host, rec, key=RUN + "-booking")
    repeat = api("POST", "/api/appointments", booking, host, rec, key=RUN + "-booking")
    check(reserved["id"] == repeat["id"], "appointment idempotence returns same record")
    api("POST", "/api/appointments", dict(booking, service="Changed"), host, rec, key=RUN + "-booking", expected=409)

    visit = api("POST", "/api/encounters", {"patientId": patient_a["id"], "branchId": branch, "specialtyCode": human}, host, pro_token)
    check(visit["profileSnapshot"]["code"] == human, "encounter stores specialty profile snapshot")
    api("POST", "/api/encounters", {"patientId": patient_a["id"], "branchId": branch, "specialtyCode": human}, host, pro_token, expected=409)
    api("POST", "/api/encounters/" + visit["id"] + "/entries", {"kind": "ANNOTATION", "payload": {"component": "HUMAN_DENTAL", "structure": "11", "condition": "QA"}}, host, pro_token, expected=400)
    measurement = api("POST", "/api/encounters/" + visit["id"] + "/entries", {"kind": "OBSERVATION", "payload": {"parameter": "Pulso", "value": 72, "unit": "bpm"}}, host, pro_token)
    prescription = api("POST", "/api/encounters/" + visit["id"] + "/entries", {"kind": "PRESCRIPTION", "payload": {"medication": "QA medicamento", "dose": "1 unidad", "route": "ORAL", "frequency": "QA", "unit": "tableta", "quantity": 10}}, host, pro_token)
    api("PUT", "/api/encounters/" + visit["id"] + "/note", {"expectedRevision": 1, "note": "Resumen ficticio"}, host, pro_token)
    api("POST", "/api/encounters/" + visit["id"] + "/finalize", {"expectedRevision": 2, "note": "Resumen ficticio final"}, host, pro_token)
    api("PUT", "/api/encounters/" + visit["id"] + "/note", {"expectedRevision": 3, "note": "Cambio tardío"}, host, pro_token, expected=409)
    api("POST", "/api/encounters/" + visit["id"] + "/entries", {"kind": "OBSERVATION", "payload": {"parameter": "Pulso", "value": 70, "unit": "bpm"}}, host, pro_token, expected=409)
    history = api("GET", "/api/patients/" + patient_a["id"] + "/history", host=host, token=pro_token)
    check(len(history["entries"]) == 2, "shared history includes captured measurements and prescription")
    branch_visit = api("POST", "/api/encounters", {"patientId": patient_a["id"], "branchId": branch2, "specialtyCode": human}, host, pro_token)
    check(len(api("GET", "/api/patients/" + patient_a["id"] + "/history", host=host, token=pro_token)["encounters"]) == 2, "same tenant history spans branches")
    api("POST", "/api/encounters/" + branch_visit["id"] + "/finalize", {"expectedRevision": 1, "note": "Consulta ficticia en segunda sede"}, host, pro_token)
    dental_visit = api("POST", "/api/encounters", {"patientId": patient_a2["id"], "branchId": branch, "specialtyCode": dental}, host, pro_token)
    api("POST", "/api/encounters/" + dental_visit["id"] + "/entries", {"kind": "ANNOTATION", "payload": {"component": "HUMAN_DENTAL", "structure": "11", "condition": "QA", "surface": "OCCLUSAL"}}, host, pro_token)
    api("POST", "/api/encounters/" + dental_visit["id"] + "/finalize", {"expectedRevision": 1, "note": "Registro odontológico ficticio"}, host, pro_token)
    vet = api("PUT", "/api/tenant/members", {"user": user("veterinarian", "ANIMAL"), "roles": ["PRO"], "status": "ACTIVE", "branches": [branch_v], "specialties": [animal]}, host_v, admin_v)
    vet_token = login(user("veterinarian")["email"], host_v)
    animal_visit = api("POST", "/api/encounters", {"patientId": patient_v["id"], "branchId": branch_v, "specialtyCode": animal}, host_v, vet_token)
    check(animal_visit["profileSnapshot"]["patientDomain"] == "ANIMAL", "veterinary encounter uses animal profile")
    api("POST", "/api/encounters/" + animal_visit["id"] + "/finalize", {"expectedRevision": 1, "note": "Consulta veterinaria ficticia"}, host_v, vet_token)

    portal_user = member(host, admin, branch, "portal", ["PAC"])
    portal = login(user("portal")["email"], host)
    link = {"userId": portal_user["id"], "relationship": "TITULAR", "active": True, "scopes": ["DOCUMENTS", "APPOINTMENTS", "BILLING"]}
    api("PUT", "/api/patients/" + patient_a["id"] + "/links", link, host, rec)
    api("GET", "/api/patients", host=host, token=portal, expected=403)
    api("GET", "/api/portal/patients/" + patient_a2["id"] + "/documents", host=host, token=portal, expected=404)
    document = api("POST", "/api/documents", {"patientId": patient_a["id"], "encounterId": visit["id"], "title": "Informe QA", "type": "REPORT", "content": "Contenido ficticio"}, host, pro_token)
    signed = api("PUT", "/api/documents/" + document["id"], {"expectedRevision": 1, "operation": "SIGN"}, host, pro_token)
    check(signed["contentHash"] == hashlib.sha256("Contenido ficticio".encode()).hexdigest(), "signed document hash matches stored content")
    api("PUT", "/api/documents/" + document["id"], {"expectedRevision": 2, "operation": "SAVE", "content": "Mutación"}, host, pro_token, expected=409)
    api("PUT", "/api/documents/" + document["id"], {"expectedRevision": 2, "operation": "PUBLISH"}, host, pro_token)
    check(len(api("GET", "/api/portal/patients/" + patient_a["id"] + "/documents", host=host, token=portal)) == 1, "portal receives signed published documents")
    api("POST", "/api/documents", {"patientId": patient_a["id"], "originalId": document["id"], "title": "Adenda QA", "type": "ADDENDUM", "content": "Aclaración ficticia"}, host, pro_token)
    api("PUT", "/api/patients/" + patient_a["id"] + "/links", dict(link, active=False), host, rec)
    api("GET", "/api/portal/patients/" + patient_a["id"] + "/documents", host=host, token=portal, expected=404)
    api("PUT", "/api/auth/password", {"currentPassword": PASSWORD, "newPassword": "short"}, host, portal, expected=400)
    api("PUT", "/api/auth/password", {"currentPassword": PASSWORD, "newPassword": "Changed-" + PASSWORD}, host, portal)
    api("GET", "/api/auth/me", host=host, token=portal, expected=401)

    charge = {"patientId": patient_a["id"], "kind": "CHARGE", "amountMinor": 10000, "title": "Consulta QA"}
    posted = api("POST", "/api/finance/movements", charge, host, cash, key=RUN + "-charge")
    check(api("POST", "/api/finance/movements", charge, host, cash, key=RUN + "-charge")["id"] == posted["id"], "charge idempotence")
    payment = api("POST", "/api/finance/movements", dict(charge, kind="PAYMENT", amountMinor=8000), host, cash, key=RUN + "-payment")
    api("POST", "/api/finance/movements", dict(charge, kind="PAYMENT", amountMinor=3000), host, cash, key=RUN + "-excess-payment", expected=409)
    refund = race(lambda i: api("POST", "/api/finance/movements", dict(charge, kind="REFUND", amountMinor=6000, parentId=payment["id"]), host, cash, key=RUN + "-refund-" + str(i), expected=None), "concurrent refunds cannot exceed original payment")
    check(api("GET", "/api/finance/patients/" + patient_a["id"], host=host, token=cash)["balanceMinor"] == 8000, "clinical cash balance is accurate")

    lot = api("POST", "/api/inventory/lots", {"branchId": branch, "name": "QA medicamento", "lot": RUN, "expiry": "2035-12-31", "unit": "tableta"}, host, stock)
    receive = {"lotId": lot["id"], "kind": "RECEIVE", "quantity": 20}
    api("POST", "/api/inventory/movements", receive, host, stock, key=RUN + "-receive")
    api("POST", "/api/inventory/movements", receive, host, stock, key=RUN + "-receive")
    dispense = {"lotId": lot["id"], "kind": "DISPENSE", "quantity": 6, "patientId": patient_a["id"], "prescriptionId": prescription["id"]}
    race(lambda i: api("POST", "/api/inventory/movements", dispense, host, stock, key=RUN + "-dispense-" + str(i), expected=None), "concurrent dispensing cannot exceed prescription")
    transfer = api("POST", "/api/inventory/transfers", {"lotId": lot["id"], "destinationBranchId": branch2, "quantity": 5}, host, stock, key=RUN + "-transfer")
    api("POST", "/api/inventory/transfers/" + transfer["id"] + "/receive", host=host, token=stock)
    api("POST", "/api/inventory/transfers/" + transfer["id"] + "/receive", host=host, token=stock)
    lots = api("GET", "/api/inventory/lots", host=host, token=stock)
    check(sum(float(x["quantity"]) for x in lots if x["lot"] == RUN) == 14, "stock and transfer conserve quantities; retries do not duplicate stock")

    resource = api("POST", "/api/hospital/resources", {"branchId": branch, "name": "Cama QA", "kind": "BED"}, host, admin)
    stay = race(lambda i: api("POST", "/api/hospital/admissions", {"patientId": [patient_a["id"], patient_a2["id"]][i], "resourceId": resource["id"], "reason": "QA"}, host, pro_token, expected=None), "concurrent admissions: one occupant per bed")
    api("POST", "/api/hospital/admissions/" + stay["id"] + "/discharge", {"expectedRevision": 1}, host, pro_token)
    api("POST", "/api/hospital/admissions/" + stay["id"] + "/discharge", {"expectedRevision": 1}, host, pro_token, expected=409)
    api("POST", "/api/hospital/resources", {"branchId": branch_v, "name": "Jaula QA", "kind": "CAGE"}, host_v, admin_v)
    api("POST", "/api/hospital/resources", {"branchId": branch_v, "name": "Cama incorrecta", "kind": "BED"}, host_v, admin_v, expected=400)

    workflow = api("POST", "/api/workflows", {"type": "LAB_ORDER", "branchId": branch, "patientId": patient_a["id"], "title": "Orden QA", "payload": {"study": "QA"}}, host, pro_token)
    diagnostic = member(host, admin, branch, "diagnostic", ["DIA"])
    dia = login(user("diagnostic")["email"], host)
    api("POST", "/api/workflows/" + workflow["id"] + "/steps", {"expectedRevision": 1, "status": "COMPLETED", "payload": {}}, host, dia, expected=409)
    api("POST", "/api/workflows/" + workflow["id"] + "/steps", {"expectedRevision": 1, "status": "SUBMITTED", "payload": {}}, host, pro_token)
    api("POST", "/api/workflows/" + workflow["id"] + "/steps", {"expectedRevision": 1, "status": "COLLECTED", "payload": {}}, host, dia, expected=409)
    check(len(api("GET", "/api/workflows/" + workflow["id"], host=host, token=pro_token)["history"]) == 2, "workflow revisions preserve history")
    api("POST", "/api/workflows", {"type": "VET_POPULATION", "branchId": branch, "title": "Wrong domain", "payload": {}}, host, pro_token, expected=403)

    api("PUT", "/api/platform/tenants/" + tenant_a["id"] + "/status", {"status": "SUSPENDED", "reason": "QA"}, token=sad)
    api("POST", "/api/patients", patient("suspended-" + RUN), host, rec, expected=403)
    api("GET", "/api/patients/" + patient_a["id"] + "/history", host=host, token=pro_token)
    api("PUT", "/api/platform/tenants/" + tenant_a["id"] + "/status", {"status": "ACTIVE", "reason": "QA restored"}, token=sad)
    member(host, admin, branch, "unused", ["REC"], existing=reception["id"], status="INACTIVE")
    api("GET", "/api/patients", host=host, token=rec, expected=401)
    api("DELETE", "/api/auth/session", host=host_b, token=pro_b)
    api("GET", "/api/auth/me", host=host_b, token=pro_b, expected=401)
    check(len(api("GET", "/api/audit", host=host, token=admin)) > 20, "tenant audit records metadata for mutations")

    price_plan = {k: next(p for p in plans if p["planId"] == plan_id)[k] for k in ["name", "description", "status", "baseMinor", "branchMinor", "professionalMinor", "includedBranches", "includedProfessionals", "includedSpecialties", "maxBranches", "maxProfessionals", "maxSpecialties", "annualDiscount", "kinds", "domains", "modules"]}
    price_plan["name"] = "QA contract " + RUN
    new_plan = api("POST", "/api/platform/plans", price_plan, token=sad)
    new_contract = dict(contract, planId=new_plan["planId"])
    cfg = api("PUT", "/api/tenant/subscription", new_contract, host, admin)
    check(cfg["planVersion"] == 1, "subscription binds published plan version")
    changed_plan = dict(price_plan, baseMinor=price_plan["baseMinor"] + 10000)
    api("PUT", "/api/platform/plans/" + new_plan["planId"], changed_plan, token=sad)
    cfg = api("GET", "/api/tenant/configuration", host=host, token=admin)
    check(cfg["planVersion"] == 1 and cfg["baseMinor"] == price_plan["baseMinor"], "editing catalog preserves contracted version and price")
    api("PUT", "/api/platform/plans/" + new_plan["planId"], dict(changed_plan, name=plans[0]["name"]), token=sad, expected=409)
    cfg = api("PUT", "/api/tenant/subscription", new_contract, host, admin)
    check(cfg["planVersion"] == 2, "explicit contract update selects latest published version")
    invoice = cfg["invoices"][0]
    api("POST", "/api/platform/tenants/" + tenant_a["id"] + "/invoices/" + invoice["id"] + "/payment", token=sad)
    api("POST", "/api/platform/tenants/" + tenant_a["id"] + "/invoices/" + invoice["id"] + "/payment", token=sad)
    check(api("GET", "/api/finance/patients/" + patient_a["id"], host=host, token=cash)["balanceMinor"] == 8000, "SaaS invoice payments do not enter clinical cash ledger")

    independent_body = {"name": "QA independiente " + RUN, "slug": "qa-" + RUN + "-doctor", "kind": "DOCTOR", "domain": "ANIMAL", "owner": user("independent", "ANIMAL"), "timezone": "America/Lima", "branchName": "Consulta propia", "address": "QA", "specialties": [animal], "subscription": {"planId": "00000000-0000-0000-0000-000000000001", "cycle": "MONTHLY", "branchQuota": 1, "professionalQuota": 1, "specialtyQuota": 5}}
    independent = api("POST", "/api/platform/tenants", independent_body, token=sad)
    independent_token = login(user("independent")["email"], independent["hostname"])
    independent_cfg = api("GET", "/api/tenant/configuration", host=independent["hostname"], token=independent_token)
    check("PRO" in independent_cfg["members"][0]["roles"], "independent owner has one clinical identity")
    external = api("POST", "/api/tenant/branches", {"name": "Clínica visitada", "address": "QA", "external": True, "active": True}, independent["hostname"], independent_token)
    check(external["external"], "independent may register external places without consuming owned branch quota")
    api("PUT", "/api/tenant/members", {"user": user("second-independent", "ANIMAL"), "roles": ["PRO"], "status": "INVITED", "branches": [independent_cfg["branches"][0]["id"]], "specialties": [animal]}, independent["hostname"], independent_token, expected=409)
    api("POST", "/api/hospital/resources", {"branchId": independent_cfg["branches"][0]["id"], "name": "No incluido", "kind": "CAGE"}, independent["hostname"], independent_token, expected=403)

    quota_plan = dict(price_plan, name="QA capacity " + RUN, includedBranches=1, includedProfessionals=1, includedSpecialties=1, maxBranches=1, maxProfessionals=1, maxSpecialties=2, kinds=["CLINIC"])
    quota = api("POST", "/api/platform/plans", quota_plan, token=sad)
    quota_tenant = api("POST", "/api/platform/tenants", {"name": "QA quota " + RUN, "slug": "qa-" + RUN + "-quota", "kind": "CLINIC", "domain": "HUMAN", "owner": user("quota-owner"), "timezone": "America/Lima", "branchName": "Central", "address": "QA", "specialties": [human], "subscription": {"planId": quota["planId"], "cycle": "MONTHLY", "branchQuota": 1, "professionalQuota": 1, "specialtyQuota": 1}}, token=sad)
    quota_host = quota_tenant["hostname"]
    quota_admin = login(user("quota-owner")["email"], quota_host)
    quota_branch = api("GET", "/api/tenant/configuration", host=quota_host, token=quota_admin)["branches"][0]["id"]
    race(lambda i: api("PUT", "/api/tenant/members", {"user": user("quota-pro-" + str(i), "HUMAN"), "roles": ["PRO"], "status": "INVITED", "branches": [quota_branch], "specialties": [human]}, quota_host, quota_admin, expected=None), "concurrent invitations cannot exceed professional quota")
    tenants.extend([(independent, None, None, None, None), (quota_tenant, None, None, None, None)])

    cmd = ["docker", "compose", "exec", "-T", "mysql", "sh", "-c", 'MYSQL_PWD="$MYSQL_PASSWORD" mysql -uhealth_app health_project']
    result = subprocess.run(cmd, input="START TRANSACTION; INSERT INTO users(id,name,email,password_hash) VALUES(UUID(),'Unauthorized','blocked@example.test','x'); ROLLBACK;", cwd=ROOT, capture_output=True, text=True, timeout=30)
    check(result.returncode != 0 and "INSERT command denied" in result.stderr, "application DB user cannot write tables directly")
    summary = {"run": RUN, "passed": len(REPORT), "timestamp": dt.datetime.now(dt.timezone.utc).isoformat(), "tenants": [x[0]["id"] for x in tenants], "checks": REPORT}
    output = ROOT / "backend/test-results/api-integration.json"
    output.parent.mkdir(exist_ok=True)
    output.write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"PASS: {len(REPORT)} API assertions; QA run {RUN}")


if __name__ == "__main__":
    main()
