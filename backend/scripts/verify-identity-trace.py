"""Local integration: verified signup, cookie/CSRF, recovery, support, trace, monitor."""
import datetime as dt
import hashlib
import http.client
import json
from pathlib import Path
import re
import secrets
import subprocess
import time
import urllib.request
import os
from urllib.parse import urlsplit
from qa_config import load_config

ROOT=Path(__file__).resolve().parents[2]
CONFIG=load_config(ROOT)
BASE=CONFIG.get('HEALTH_BASE_DOMAIN','health.localhost')
URL=urlsplit(os.getenv('HEALTH_TEST_URL','http://127.0.0.1:8080'))
MAIL_URL=os.getenv('HEALTH_MAILPIT_URL','http://127.0.0.1:8025').rstrip('/')
RUN=secrets.token_hex(5)
PW='Identity-QA-'+secrets.token_hex(10)
RESULT=[]
def check(ok,label):
    assert ok,label
    RESULT.append(label)

def request(method,path,body=None,host=BASE,cookie=None,csrf=None,bearer=None,expect=200,headers=None):
    connection=http.client.HTTPSConnection if URL.scheme=='https' else http.client.HTTPConnection
    conn=connection(URL.hostname,URL.port,timeout=30)
    h={'Host':host,'Content-Type':'application/json','User-Agent':'HealthProject-Identity-QA'}
    if cookie:h['Cookie']=cookie
    if csrf:h['X-CSRF-Token']=csrf
    if bearer:h['Authorization']='Bearer '+bearer
    h.update(headers or {})
    conn.request(method,URL.path.rstrip('/')+path,None if body is None else json.dumps(body),h)
    res=conn.getresponse();raw=res.read();response_headers=dict(res.getheaders());status=res.status;conn.close()
    data=json.loads(raw) if raw else None
    assert status==expect,f'{method} {path}: {status}, expected {expect}: '+str(data.get('detail','') if isinstance(data,dict) else '')
    RESULT.append(f'{method} {path} -> {status}')
    return data,response_headers

def login(email,password,host):
    data,headers=request('POST','/api/auth/browser/login',{'email':email,'password':password},host)
    check('accessToken' not in data,'browser login does not expose bearer token')
    cookie=headers['Set-Cookie'];check('HttpOnly' in cookie and 'SameSite=Strict' in cookie and 'Domain=' not in cookie,'cookie HttpOnly, SameSite, host-only')
    return cookie.split(';')[0],data['csrfToken']

def mail_token(email,purpose):
    opener=urllib.request.build_opener(urllib.request.ProxyHandler({}))
    for _ in range(30):
        with opener.open(MAIL_URL+'/api/v1/messages',timeout=10) as res:messages=json.load(res)['messages']
        for message in messages:
            if not any(person['Address']==email for person in message.get('To',[])):continue
            with opener.open(MAIL_URL+'/api/v1/message/'+message['ID'],timeout=10) as res:detail=json.load(res)
            if ('/verificar/' if purpose=='VERIFY' else '/restablecer/') not in detail.get('Text',''):continue
            match=re.search(r'https?://([^/]+)/[^\s]+#token=([A-Za-z0-9_-]+)',detail['Text'])
            if match:return match.group(1).split(':')[0],match.group(2)
        time.sleep(.5)
    raise AssertionError('verification/recovery email not delivered to local mailbox')

def main():
    admin_cookie,admin_csrf=login(CONFIG['BOOTSTRAP_ADMIN_EMAIL'],CONFIG['BOOTSTRAP_ADMIN_PASSWORD'],BASE)
    request('GET','/api/monitor',expect=401)
    monitor,_=request('GET','/api/monitor',cookie=admin_cookie)
    check(monitor['database']['status']=='UP','monitor reports database UP')
    options,_=request('GET','/api/public/registration')
    plan=next(p for p in options['plans'] if 'DOCTOR' in p['kinds'])
    specialty=next(s for s in options['specialties'] if s['domain']=='HUMAN' and not s['dental'])
    email='identity-'+RUN+'@example.test';slug='identity-'+RUN
    body={'name':'Identity QA','email':email,'password':PW,'kind':'DOCTOR','domain':'HUMAN','organizationName':'Identity QA '+RUN,'slug':slug,'planId':plan['id'],'specialtyCode':specialty['code'],'acceptTerms':True}
    request('POST','/api/auth/register',body,expect=202)
    host=slug+'.'+BASE
    request('POST','/api/auth/browser/login',{'email':email,'password':PW},host,expect=403)
    token_host,token=mail_token(email,'VERIFY');check(token_host==host,'verification link targets tenant host')
    request('POST','/api/auth/verify/complete',{'token':token},expect=400)
    request('POST','/api/auth/verify/complete',{'token':token},host)
    request('POST','/api/auth/verify/complete',{'token':token},host,expect=400)
    cookie,csrf=login(email,PW,host)
    session,_=request('GET','/api/auth/browser/session',host=host,cookie=cookie)
    check('ADM' in session['user']['roles'] and 'SAD' not in session['user']['roles'],'self signup never creates platform privilege')
    request('GET','/api/auth/browser/session',cookie=cookie,expect=401)
    request('PUT','/api/tenant/branches',{},host,cookie,expect=403)
    request('POST','/api/public/support',{'email':email,'subject':'QA '+RUN,'message':'Trace support scenario','priority':'NORMAL'},host,cookie,csrf,headers={'Origin':'https://evil.example'},expect=403)
    ticket,headers=request('POST','/api/public/support',{'email':email,'subject':'QA '+RUN,'message':'Trace support scenario','priority':'NORMAL'},host,cookie,csrf)
    check(ticket['website']=='https://mavrictec.com' and ticket['provider']=='Mavric Technologies','support uses corrected brand and URL')
    requests,_=request('GET','/api/trace/requests',host=host,cookie=cookie)
    correlation=headers['X-Request-Id'];check(any(r['id']==correlation for r in requests),'support request has persisted correlation')
    journey,_=request('GET','/api/trace/requests/'+correlation,host=host,cookie=cookie)
    check(len(journey['steps'])>=2 and all(e['requestId']==correlation for e in journey['steps']),'journey includes intent and database changes')
    change=next(e for e in journey['steps'] if e['resourceType']=='support_tickets')
    check(change['createdAt'].endswith('Z') and journey['createdAt'].endswith('Z'),'audit timestamps carry an explicit UTC timezone')
    check(change['actorId']==session['user']['id'] and change['afterState']['status']=='OPEN','change contains actor and recorded state')
    check('Trace support scenario' not in json.dumps(journey),'trace excludes raw support message')
    tickets,_=request('GET','/api/support',host=host,cookie=cookie)
    own=next(t for t in tickets if t['reference']==ticket['reference'])
    request('POST','/api/support/'+own['id']+'/steps',{'expectedRevision':1,'status':'RESOLVED','priority':'NORMAL','message':'illegal customer change'},host,cookie,csrf,expect=403)
    updated,_=request('POST','/api/support/'+own['id']+'/steps',{'expectedRevision':1,'status':'IN_PROGRESS','priority':'HIGH','message':'Review started'},cookie=admin_cookie,csrf=admin_csrf)
    check(updated['revision']==2,'support transition increments revision')
    request('POST','/api/support/'+own['id']+'/steps',{'expectedRevision':1,'status':'RESOLVED','priority':'HIGH','message':'stale'},cookie=admin_cookie,csrf=admin_csrf,expect=409)
    status,_=request('GET','/api/public/status')
    request('PUT','/api/monitor/mode',{'expectedRevision':status['revision'],'mode':'READ_ONLY','message':'QA readonly'},cookie=admin_cookie,csrf=admin_csrf)
    try:
        request('POST','/api/patients',{},host,cookie,csrf,expect=503)
        request('GET','/api/monitor',host=host,cookie=cookie)
    finally:
        current,_=request('GET','/api/public/status')
        request('PUT','/api/monitor/mode',{'expectedRevision':current['revision'],'mode':'OPEN','message':'Todos los servicios disponibles'},cookie=admin_cookie,csrf=admin_csrf)
    request('POST','/api/auth/recovery/request',{'email':email},host)
    reset_host,reset=mail_token(email,'RESET');check(reset_host==host,'recovery link targets tenant host')
    request('POST','/api/auth/recovery/complete',{'token':reset,'password':'short'},host,expect=400)
    new_password='Changed-'+PW
    request('POST','/api/auth/recovery/complete',{'token':reset,'password':new_password},host)
    request('POST','/api/auth/recovery/complete',{'token':reset,'password':new_password},host,expect=400)
    request('GET','/api/auth/browser/session',host=host,cookie=cookie,expect=401)
    cookie,csrf=login(email,new_password,host)
    request('POST','/api/auth/browser/login',{'email':email,'password':'wrong-password'},host,expect=401)
    events,_=request('GET','/api/trace/events?query=LOGIN_FAILED',host=host,cookie=cookie)
    check(bool(events['items']),'failed login audit survives failed request transaction')
    sessions,_=request('GET','/api/auth/sessions',host=host,cookie=cookie)
    current=next(s for s in sessions if s['current'])
    check('tokenHash' not in current and 'csrfToken' not in current,'session list does not expose credentials')
    request('DELETE','/api/auth/sessions/'+current['id'],host=host,cookie=cookie,csrf=csrf)
    request('GET','/api/auth/browser/session',host=host,cookie=cookie,expect=401)
    request('DELETE','/api/auth/browser/session',cookie=admin_cookie,csrf=admin_csrf)
    request('GET','/api/auth/browser/session',cookie=admin_cookie,expect=401)
    output=ROOT/'backend/test-results/identity-trace.json';output.parent.mkdir(exist_ok=True)
    output.write_text(json.dumps({'run':RUN,'passed':len(RESULT),'checks':RESULT,'timestamp':dt.datetime.now(dt.timezone.utc).isoformat()},indent=2),encoding='utf-8')
    print('PASS:',len(RESULT),'identity, trace, support and monitoring assertions')

if __name__=='__main__':main()
