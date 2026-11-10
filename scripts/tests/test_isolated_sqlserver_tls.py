"""Offline PowerShell 5.1 tests. Every OS observation/effect in Apply is mocked.

Run: python -B -m unittest discover -s scripts/tests -p test_isolated_sqlserver_tls.py -v
No CLI -Apply, elevation, certificate/registry/ACL/service/network effects.
"""
import base64
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[2]
TOOL = ROOT / "scripts/configure-isolated-sqlserver-tls.ps1"
HELPER = ROOT / "scripts/configure-isolated-sqlserver-qa.ps1"
POWERSHELL = shutil.which("powershell.exe")

# Safety traps are installed before dot-sourcing. The approved helper only defines
# functions; all its OS-facing observations are replaced by TLS wrappers below.
FIXTURE = r"""
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false)
$script:events=[Collections.Generic.List[string]]::new()
$script:writes=[Collections.Generic.List[object]]::new()
$script:certArgs=[Collections.Generic.List[object]]::new()
$script:registryWrites=[Collections.Generic.List[object]]::new()
$script:aclRules=[Collections.Generic.List[object]]::new()
$script:openPaths=[Collections.Generic.List[string]]::new()
$script:exports=[Collections.Generic.List[object]]::new()
$script:existing=@{}
$script:failStage=''
$script:journalStage=''
$script:bound=''
$script:force=0
$script:admin=$true
$script:protected=('a'*64)
$script:helperHash='3FBC605A36A6BE720B4D87E3F50D64163E167D5BA96C2C621C3B672B3A2BD831'
$script:collisions=@()
$script:reparse=$false
$script:result=$null
function Assert($Condition,[string]$Message='assertion') { if(-not $Condition){throw "TEST_FAILED:$Message"} }
function Effect([string]$Name) {
    $script:events.Add('effect:'+$Name)
    if($script:failStage -ceq $Name){throw 'SIMULATED_PRIVATE_ERROR:must-not-serialize'}
}
# Unexpected direct calls are stopped, including helper paths that must not run.
function Get-CimInstance { throw 'TEST_UNMOCKED_CIM' }
function Get-NetTCPConnection { throw 'TEST_UNMOCKED_NETWORK' }
function Get-AuthenticodeSignature { throw 'TEST_UNMOCKED_SIGNATURE' }
function Start-Process { throw 'TEST_FORBIDDEN_PROCESS' }
function Start-Service { throw 'TEST_FORBIDDEN_START' }
function Stop-Service { throw 'TEST_FORBIDDEN_STOP' }
function Remove-Item { throw 'TEST_FORBIDDEN_DELETE' }
function Import-Certificate { throw 'TEST_FORBIDDEN_TRUST' }
function Export-PfxCertificate { throw 'TEST_FORBIDDEN_PFX' }
function Invoke-WebRequest { throw 'TEST_FORBIDDEN_HTTP' }
function Set-Content { throw 'TEST_UNMOCKED_WRITE' }
function Add-Content { throw 'TEST_UNMOCKED_WRITE' }
function Test-Path { [CmdletBinding()] param($LiteralPath,$PathType) return ($script:existing.ContainsKey($LiteralPath) -or $LiteralPath -like '*\MachineKeys\new_leaf_key') }
function Get-Item { [CmdletBinding()]
    param($LiteralPath,[switch]$Force)
    [pscustomobject]@{Attributes=if($script:reparse){[IO.FileAttributes]::ReparsePoint}else{[IO.FileAttributes]::Directory};Parent=$null}
}
function Get-FileHash { [CmdletBinding()] param($LiteralPath,$Algorithm) [pscustomobject]@{Hash=$script:helperHash} }
function Get-ChildItem { [CmdletBinding()] param($LiteralPath) Assert ($LiteralPath -ceq 'Cert:\LocalMachine\My') 'store'; $script:collisions }
function Get-ItemProperty { [CmdletBinding()] param($LiteralPath) Assert ($LiteralPath -ceq (Get-TlsSpec).Registry) 'registry-read'; [pscustomobject]@{Certificate=$script:bound;ForceEncryption=$script:force} }
function Set-ItemProperty { [CmdletBinding()]
    param($LiteralPath,$Name,$Value)
    Assert ($LiteralPath -ceq (Get-TlsSpec).Registry) 'registry-write-target'
    $script:registryWrites.Add(@{path=$LiteralPath;name=$Name;value=$Value})
    Effect $(if($Name -ceq 'Certificate'){'bind-certificate'}else{'force-encryption'})
    if($Name -ceq 'Certificate'){$script:bound=$Value}else{$script:force=$Value}
}
function New-Item { [CmdletBinding()] param($ItemType,$Path) Assert ($ItemType -ceq 'Directory') 'directory'; Effect 'reserve-evidence';$script:existing[$Path]=$true;[pscustomobject]@{} }
function New-SelfSignedCertificate { [CmdletBinding()]
    param($Type,$Subject,$FriendlyName,$CertStoreLocation,$KeyAlgorithm,$KeyLength,$HashAlgorithm,$KeyExportPolicy,$KeyUsage,$TextExtension,$NotAfter,$Signer,$KeySpec,$Provider)
    $script:certArgs.Add(@{}+$PSBoundParameters)
    $isRoot=$FriendlyName.EndsWith(' Root')
    Effect $(if($isRoot){'create-ca'}else{'create-leaf'})
    [pscustomobject]@{Thumbprint=if($isRoot){'1'*40}else{'2'*40};FriendlyName=$FriendlyName;HasPrivateKey=$true
        PrivateKey=[pscustomobject]@{CspKeyContainerInfo=[pscustomobject]@{KeyNumber='Exchange';MachineKeyStore=$true;Exportable=$false;UniqueKeyContainerName='new_leaf_key'}}}
}
function Get-Acl { [CmdletBinding()]
    param($LiteralPath)
    $acl=[pscustomobject]@{Original='preserved';Rules=[Collections.Generic.List[object]]::new()}
    $acl | Add-Member ScriptMethod AddAccessRule {param($Rule) $this.Rules.Add($Rule)}
    $acl
}
function Set-Acl { [CmdletBinding()]
    param($LiteralPath,$AclObject)
    Assert ($LiteralPath.EndsWith('\MachineKeys\new_leaf_key')) 'only-leaf-key'
    Assert ($AclObject.Original -ceq 'preserved') 'existing-acl-preserved'
    $script:aclRules.Add($AclObject.Rules[0]);Effect 'private-key-acl'
}
function Export-Certificate { [CmdletBinding()] param($Cert,$FilePath,$Type) $script:exports.Add(@{path=$FilePath;type=$Type});Effect $(if($FilePath.EndsWith('qa-root.cer')){'export-ca-public'}else{'export-leaf-public'}) }
function Restart-Service { [CmdletBinding()] param($Name,[switch]$Force) Assert ($Name -ceq 'MSSQL$HEALTHPROJECTQA' -and -not $Force) 'closed-restart';Effect 'restart-qa' }
function Get-Service { [CmdletBinding()]
    param($Name)
    Assert ($Name -ceq 'MSSQL$HEALTHPROJECTQA') 'service'
    $svc=[pscustomobject]@{DependentServices=$script:dependents}
    $svc | Add-Member ScriptMethod WaitForStatus {param($State,$Timeout) Assert ($State -ceq 'Running') 'running-wait'}
    $svc
}
$script:dependents=@()
. '__TOOL__'
$script:realHostNames=${function:Get-TlsHostNames}
function Get-TlsToolRoot { 'D:\Mavric\Health Project' }
function Get-TlsHelperPath { '__HELPER__' }
function Test-TlsAdmin { $script:admin }
function Get-TlsProtected { $script:protected }
function Get-TlsObservation { $script:observation }
function Get-TlsListeners { param($ProcessId) $script:listeners }
function Get-TlsHostNames { [pscustomobject]@{Short='TESTHOST';Names=@('TESTHOST','testhost.example.test','localhost','health.localhost')} }
function New-TlsReadRule { param($Principal,$Rights,$AccessType) [pscustomobject]@{Principal=$Principal;Rights=$Rights.ToString();AccessType=$AccessType.ToString()} }
# Real journal/result serialization writes only to this in-memory stream facade.
function Open-TlsFile {
    param($Path)
    if($script:existing.ContainsKey($Path)){throw 'TEST_EXCLUSIVE_COLLISION'}
    $script:existing[$Path]=$true;$script:openPaths.Add($Path)
    $stream=[pscustomobject]@{Path=$Path}
    $stream | Add-Member ScriptMethod Write {
        param($Bytes,$Offset,$Count)
        $entry=[Text.Encoding]::UTF8.GetString($Bytes,$Offset,$Count)|ConvertFrom-Json
        $script:writes.Add($entry)
        if($this.Path.EndsWith('.jsonl')){
            $script:journalStage=$entry.stage;$script:events.Add('journal:'+$entry.stage)
            if($script:failStage -ceq ('journal-'+$entry.stage)){throw 'SIMULATED_JOURNAL_IO'}
        }elseif($this.Path.EndsWith('tls-operation.json')){Effect 'initialize-evidence'}
        else{$script:result=$entry;Effect 'record-result'}
    }
    $stream | Add-Member ScriptMethod Flush {param($Durable) Assert $Durable 'durable-write';$script:events.Add('flush')}
    $stream | Add-Member ScriptMethod Dispose {
        $script:events.Add('dispose')
        if($this.Path.EndsWith('.jsonl') -and $script:failStage -ceq 'close-journal'){throw 'SIMULATED_PRIVATE_CLOSE_ERROR'}
    }
    $stream
}
# Full accepted helper observation shape. Its REAL target/network validators run.
$script:observation=[pscustomobject]@{
    Instance='HEALTHPROJECTQA';InstanceId='MSSQL16.HEALTHPROJECTQA'
    Service=[pscustomobject]@{Name='MSSQL$HEALTHPROJECTQA';PathName='"C:\Program Files\Microsoft SQL Server\MSSQL16.HEALTHPROJECTQA\MSSQL\Binn\sqlservr.exe" -sHEALTHPROJECTQA';StartMode='Manual';State='Running';ProcessId=123}
    Binary='C:\Program Files\Microsoft SQL Server\MSSQL16.HEALTHPROJECTQA\MSSQL\Binn\sqlservr.exe'
    MicrosoftSigned=$true;Version='16.0.1000.6';Reparse=$false;Master='D:\HealthProject-QA\SqlServer\DATA\master.mdf';LoginMode=2;LoginKind='DWord'
    Protocols=@([pscustomobject]@{ProtocolName='Tcp';InstanceName='HEALTHPROJECTQA';Enabled=$true},[pscustomobject]@{ProtocolName='Np';InstanceName='HEALTHPROJECTQA';Enabled=$false})
    Properties=@()
}
foreach($entry in @(@('','ListenOnAllIPs',0,0,''),@('IP1','IpAddress',1,0,'127.0.0.1'),@('IP1','Enabled',0,1,''),@('IP1','TcpPort',1,0,'14335'),@('IP1','TcpDynamicPorts',1,0,''),@('IPAll','TcpPort',1,0,'14335'),@('IPAll','TcpDynamicPorts',1,0,''))){
    $script:observation.Properties += [pscustomobject]@{InstanceName='HEALTHPROJECTQA';ProtocolName='Tcp';IPAddressName=$entry[0];PropertyName=$entry[1];PropertyType=$entry[2];PropertyNumVal=$entry[3];PropertyStrVal=$entry[4]}
}
$script:listeners=@([pscustomobject]@{LocalAddress='127.0.0.1';LocalPort=14335;OwningProcess=123})
$script:directory='D:\Mavric\Health Project\tmp\tls-a69-20261110-test001'
$script:id='a69-20261110-test001'
function Run { Invoke-TlsTool $true ('a'*64) $script:directory $script:id }
"""


@unittest.skipUnless(POWERSHELL, "Windows PowerShell 5.1 required")
class IsolatedTlsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # The fixture executes ONLY this accepted readonly helper's definitions.
        if hashlib.sha256(HELPER.read_bytes()).hexdigest().upper() != "3FBC605A36A6BE720B4D87E3F50D64163E167D5BA96C2C621C3B672B3A2BD831":
            raise AssertionError("Approved helper fixture changed")

    def ps(self, body, fixture=True):
        prefix = FIXTURE.replace("__TOOL__", str(TOOL).replace("'", "''")).replace("__HELPER__", str(HELPER).replace("'", "''")) if fixture else ""
        code = "$ProgressPreference='SilentlyContinue'\n" + prefix + "\n" + body
        encoded = base64.b64encode(code.encode("utf-16-le")).decode("ascii")
        result = subprocess.run([POWERSHELL, "-NoProfile", "-NonInteractive", "-EncodedCommand", encoded],
                                capture_output=True, timeout=45)
        self.assertEqual(result.returncode, 0, result.stderr.decode("utf-8", "replace"))
        self.assertFalse(result.stderr.strip(), result.stderr.decode("utf-8", "replace"))
        return result.stdout.decode("utf-8-sig").strip()

    def test_parser_and_plan_cli(self):
        tool = str(TOOL).replace("'", "''")
        result = self.ps(r"""
$ErrorActionPreference='Stop';[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false)
$errors=$null;$tokens=$null
[Management.Automation.Language.Parser]::ParseFile('__PATH__',[ref]$tokens,[ref]$errors)|Out-Null
if($errors.Count){throw 'PARSER_ERRORS'}
& '__PATH__'
""".replace("__PATH__", tool), fixture=False)
        plan = json.loads(result)
        self.assertEqual(plan["status"], "planned")
        self.assertFalse(plan["apply"] or plan["chainValidated"])

    def test_dot_source_and_plan_have_no_observation_or_effects(self):
        self.ps(r"""
function Get-TlsPinnedHelper {throw 'PLAN_MUST_NOT_IMPORT'}
function Get-TlsProtected {throw 'PLAN_MUST_NOT_INSPECT'}
$r=Invoke-TlsTool $false '' '' ''
Assert ($r.status -ceq 'planned' -and $script:events.Count -eq 0 -and $script:openPaths.Count -eq 0) 'readonly-plan'
""")

    def test_success_real_commands_and_write_ahead_order(self):
        self.ps(r"""
$r=Run
Assert ($r.status -ceq 'bound') ($r|ConvertTo-Json -Compress)
Assert (-not $r.chainValidated -and -not $r.privateKeysExported -and -not $r.osRootTrustChanged) 'not-chain-proof'
Assert ($script:certArgs.Count -eq 2 -and $script:registryWrites.Count -eq 2 -and $script:aclRules.Count -eq 1) 'effects-count'
foreach($a in $script:certArgs){Assert ($a.CertStoreLocation -ceq 'Cert:\LocalMachine\My' -and $a.KeyAlgorithm -ceq 'RSA' -and $a.KeyExportPolicy -ceq 'NonExportable') 'cert-arguments'}
$ca=$script:certArgs[0];$leaf=$script:certArgs[1]
Assert ($ca.KeyLength -eq 3072 -and 'CertSign' -cin $ca.KeyUsage -and $ca.TextExtension[0] -like '*ca=1&pathlength=0') 'ca-arguments'
Assert ($leaf.KeySpec -ceq 'KeyExchange' -and $leaf.Provider -ceq 'Microsoft RSA SChannel Cryptographic Provider' -and $leaf.Signer.Thumbprint -ceq ('1'*40)) 'leaf-key'
Assert ($leaf.TextExtension[0] -ceq '2.5.29.37={text}1.3.6.1.5.5.7.3.1' -and $leaf.TextExtension[1] -like '*DNS=localhost*IPAddress=127.0.0.1') 'EKU-SAN'
$rule=$script:aclRules[0]
Assert ($rule.Principal -ceq 'NT SERVICE\MSSQL$HEALTHPROJECTQA' -and $rule.Rights -ceq 'Read' -and $rule.AccessType -ceq 'Allow') 'precise-leaf-ACE'
foreach($e in $script:exports){Assert ($e.type -ceq 'CERT' -and $e.path.StartsWith($script:directory+'\') -and $e.path.EndsWith('.cer')) 'public-export'}
$effects=@($script:events|Where-Object {$_ -like 'effect:*'})
Assert (($effects -join ',') -ceq 'effect:reserve-evidence,effect:initialize-evidence,effect:create-ca,effect:create-leaf,effect:private-key-acl,effect:export-ca-public,effect:export-leaf-public,effect:bind-certificate,effect:force-encryption,effect:restart-qa,effect:record-result') 'closed-effects'
foreach($e in $effects){$name=$e.Substring(7);$j=$script:events.IndexOf('journal:'+$name);$m=$script:events.IndexOf($e);Assert ($j -ge 0 -and $j -lt $m -and $script:events[$j+1] -ceq 'flush') ('write-ahead-'+$name)}
Assert ($script:openPaths[0].EndsWith('healthprojectqa-tls-operation.jsonl') -and $script:result.status -ceq 'bound') 'journal-result'
""")

    def test_request_guards(self):
        self.ps(r"""
$cases=@(@('','D:\Mavric\Health Project\tmp\tls-a69-20261110-test001','a69-20261110-test001','EXPLICIT_FINGERPRINT_REQUIRED'),@(('a'*63),$script:directory,$script:id,'EXPLICIT_FINGERPRINT_REQUIRED'),@(('g'*64),$script:directory,$script:id,'EXPLICIT_FINGERPRINT_REQUIRED'),@(('a'*64),'D:\elsewhere',$script:id,'EVIDENCE_PATH_INVALID'),@(('a'*64),'D:\Mavric\Health Project\tmp\..\tls-a69-20261110-test001',$script:id,'EVIDENCE_PATH_INVALID'),@(('a'*64),($script:directory+':stream'),$script:id,'EVIDENCE_PATH_INVALID'),@(('a'*64),$script:directory,'a69-20260230-test001','OPERATION_ID_INVALID'),@(('a'*64),$script:directory,'../evil','OPERATION_ID_INVALID'),@(('a'*64),($script:directory+'\nested'),$script:id,'EVIDENCE_PATH_INVALID'))
foreach($c in $cases){$r=Invoke-TlsTool $true $c[0] $c[1] $c[2];Assert ($r.code -ceq $c[3] -and $script:events.Count -eq 0) ($r|ConvertTo-Json -Compress)}
function Get-TlsToolRoot {'C:\wrong'}
$r=Run;Assert ($r.code -ceq 'HEALTH_PROJECT_ROOT_REQUIRED') 'root'
""")

    def test_reparse_existing_evidence_and_global_reservation(self):
        self.ps(r"""
$script:reparse=$true;$r=Run;Assert ($r.code -ceq 'REPARSE_PATH') 'reparse'
$script:reparse=$false;$script:existing[$script:directory]=$true;$r=Run;Assert ($r.code -ceq 'EXISTING_EVIDENCE_REQUIRES_REVIEW') 'evidence'
$script:existing=@{};$script:existing['D:\Mavric\Health Project\tmp\healthprojectqa-tls-operation.jsonl']=$true
$r=Run;Assert ($r.code -ceq 'PRIOR_OPERATION_REQUIRES_REVIEW' -and $script:events.Count -eq 0) 'global-lock'
""")

    def test_helper_admin_fingerprint_before_effects(self):
        self.ps(r"""
$script:helperHash='0'*64;$r=Run;Assert ($r.code -ceq 'HELPER_PIN_MISMATCH') 'pin'
$script:helperHash='3FBC605A36A6BE720B4D87E3F50D64163E167D5BA96C2C621C3B672B3A2BD831'
$script:admin=$false;$r=Run;Assert ($r.code -ceq 'ELEVATION_REQUIRED') 'admin'
$script:admin=$true;$script:protected='b'*64;$r=Run
Assert ($r.code -ceq 'PROTECTED_BASELINE_CHANGED' -and $script:events.Count -eq 0) 'fingerprint'
""")

    def test_strict_hash_length_and_synthetic_host_validation(self):
        self.ps(r"""
$r=Invoke-TlsTool $true (('a'*64)+"`n") $script:directory $script:id
Assert ($r.code -ceq 'EXPLICIT_FINGERPRINT_REQUIRED' -and $script:events.Count -eq 0) 'hash-newline'
function Get-TlsDnsHost {'testhost.example.test'}
$env:COMPUTERNAME='TESTHOST'
$hosts=& $script:realHostNames
Assert ('localhost' -cin $hosts.Names -and 'TESTHOST' -cin $hosts.Names) 'host-SANs'
foreach($name in @('bad&IPAddress=1.2.3.4','bad..name',"bad`n",'-bad','bad.-label')){
    $env:COMPUTERNAME=$name
    try{& $script:realHostNames;throw 'TEST_NO_HOST_GUARD'}catch{Assert ($_.Exception.Message -ceq 'HOST_NAME_INVALID') 'bad-host'}
}
""")

    def test_target_binary_state_network_with_real_helper_validators(self):
        self.ps(r"""
$o=$script:observation
$o.Instance='OTHER';$r=Run;Assert ($r.code -ceq 'TARGET_MISMATCH') 'instance';$o.Instance='HEALTHPROJECTQA'
$o.Service.State='Stopped';$r=Run;Assert ($r.code -ceq 'QA_RUNNING_REQUIRED') 'running';$o.Service.State='Running'
$o.Service.StartMode='Auto';$r=Run;Assert ($r.code -ceq 'SERVICE_START_MODE_INVALID') 'manual';$o.Service.StartMode='Manual'
$o.MicrosoftSigned=$false;$r=Run;Assert ($r.code -ceq 'ENGINE_IDENTITY_INVALID') 'signed';$o.MicrosoftSigned=$true
$o.Binary='C:\wrong.exe';$r=Run;Assert ($r.code -ceq 'BINARY_PATH_INVALID') 'binary';$o.Binary='C:\Program Files\Microsoft SQL Server\MSSQL16.HEALTHPROJECTQA\MSSQL\Binn\sqlservr.exe'
$o.Master='C:\elsewhere\master.mdf';$r=Run;Assert ($r.code -ceq 'PATH_INVALID') 'master';$o.Master='D:\HealthProject-QA\SqlServer\DATA\master.mdf'
$o.Properties[0].PropertyNumVal=1;$r=Run;Assert ($r.code -ceq 'QA_CONFIGURATION_PENDING') 'network';$o.Properties[0].PropertyNumVal=0
$script:listeners[0].LocalAddress='0.0.0.0';$r=Run;Assert ($r.code -ceq 'EXTERNAL_LISTENER' -and $script:events.Count -eq 0) 'listener'
""")

    def test_tls_state_and_real_store_collision_checks(self):
        self.ps(r"""
$script:bound='f'*40;$r=Run;Assert ($r.code -ceq 'UNEXPECTED_TLS_CONFIGURATION') 'bound'
$script:bound='';$script:force=1;$r=Run;Assert ($r.code -ceq 'UNEXPECTED_TLS_CONFIGURATION') 'force'
$script:force='0';$r=Run;Assert ($r.code -ceq 'UNEXPECTED_TLS_CONFIGURATION') 'type'
$script:force=0;$script:collisions=@([pscustomobject]@{FriendlyName='Health Project isolated QA TLS 20261106 Root';Subject='CN=old'})
$r=Run;Assert ($r.code -ceq 'CERTIFICATE_COLLISION_REQUIRES_REVIEW' -and $script:events.Count -eq 0) 'historical-collision'
""")

    def test_each_effect_failure_retains_stage_and_blocks_new_id(self):
        # Separate fresh offline fixtures: no automatic retries of a real operation.
        for stage in ("reserve-evidence", "initialize-evidence", "create-ca", "create-leaf", "private-key-acl", "export-ca-public",
                      "export-leaf-public", "bind-certificate", "force-encryption", "restart-qa", "record-result"):
            with self.subTest(stage=stage):
                self.ps(r"""
$script:failStage='__STAGE__';$r=Run
Assert ($r.status -ceq 'unverified' -and $r.stage -ceq '__STAGE__' -and -not $r.automaticRetry -and -not $r.chainValidated) ($r|ConvertTo-Json -Compress)
Assert ($r.code -ceq 'TLS_INSPECTION_OR_ACTION_FAILED') 'safe-code'
Assert (($r|ConvertTo-Json -Compress) -notlike '*SIMULATED_PRIVATE_ERROR*') 'no-private-message'
Assert (@($script:events|Where-Object {$_ -ceq 'effect:__STAGE__'}).Count -eq 1) 'no-retry'
if('__STAGE__' -cin @('reserve-evidence','initialize-evidence')){Assert ($script:certArgs.Count -eq 0) 'evidence-writable-before-keys'}
$count=$script:events.Count;$script:directory='D:\Mavric\Health Project\tmp\tls-a69-20261110-other001';$script:id='a69-20261110-other001'
$blocked=Run;Assert ($blocked.code -ceq 'PRIOR_OPERATION_REQUIRES_REVIEW' -and $script:events.Count -eq $count) 'uncertain-global-block'
""".replace("__STAGE__", stage))

    def test_journal_failure_prevents_next_effect_and_keeps_reservation(self):
        self.ps(r"""
$script:failStage='journal-create-ca';$r=Run
Assert ($r.status -ceq 'unverified' -and $r.stage -ceq 'create-ca' -and $script:certArgs.Count -eq 0) 'journal-before-certificate'
Assert ($script:existing.ContainsKey('D:\Mavric\Health Project\tmp\healthprojectqa-tls-operation.jsonl')) 'reservation-remains'
""")

    def test_journal_close_failure_is_safe_and_never_bound(self):
        self.ps(r"""
$script:failStage='close-journal';$r=Run
Assert ($r.status -ceq 'unverified' -and $r.code -ceq 'JOURNAL_CLOSE_FAILED' -and $r.reviewRequired -and -not $r.chainValidated) 'close-failure'
Assert (($r|ConvertTo-Json -Compress) -notlike '*SIMULATED_PRIVATE_CLOSE_ERROR*') 'safe-close-error'
$script:directory='D:\Mavric\Health Project\tmp\tls-a69-20261110-other001';$script:id='a69-20261110-other001'
$blocked=Run;Assert ($blocked.code -ceq 'PRIOR_OPERATION_REQUIRES_REVIEW') 'close-reservation'
""")

    def test_leaf_key_guards_and_service_dependents(self):
        self.ps(r"""
$request=[pscustomobject]@{Friendly='test';Id=$script:id}
$leaf=New-TlsLeaf $request ([pscustomobject]@{}) (Get-TlsHostNames)
$leaf.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName='..\other-key'
try{Grant-TlsLeafRead $leaf;throw 'TEST_NO_GUARD'}catch{Assert ($_.Exception.Message -ceq 'SQL_KEY_EXCHANGE_REQUIRED') 'key-traversal'}
$leaf.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName='new_leaf_key';$leaf.PrivateKey.CspKeyContainerInfo.Exportable=$true
try{Grant-TlsLeafRead $leaf;throw 'TEST_NO_GUARD'}catch{Assert ($_.Exception.Message -ceq 'SQL_KEY_EXCHANGE_REQUIRED') 'key-export'}
$script:dependents=@([pscustomobject]@{Status='Running'})
try{Restart-TlsQA;throw 'TEST_NO_GUARD'}catch{Assert ($_.Exception.Message -ceq 'SERVICE_DEPENDENTS_RUNNING') 'dependents'}
Assert (@($script:events|Where-Object {$_ -ceq 'effect:restart-qa'}).Count -eq 0) 'no-force-restart'
""")

    def test_post_binding_or_fingerprint_mismatch_never_bound(self):
        self.ps(r"""
function Wait-TlsQA { $script:protected='b'*64 }
$r=Run
Assert ($r.status -ceq 'unverified' -and $r.code -ceq 'PROTECTED_BASELINE_CHANGED' -and $r.bindingMayHaveChanged -and -not $r.chainValidated) 'post-fingerprint'
""")

    def test_post_binding_not_verified_and_exclusive_factory(self):
        self.ps(r"""
function Wait-TlsQA { $script:bound='0'*40 }
$r=Run
Assert ($r.status -ceq 'unverified' -and $r.code -ceq 'TLS_BINDING_NOT_VERIFIED' -and -not $r.chainValidated) 'post-binding'
# Observe the actual file factory's AST: it must use the exclusive .NET overload,
# never a path-overwriting shell command. Apply tests replace only this boundary.
$tokens=$null;$errors=$null
$originalAst=[Management.Automation.Language.Parser]::ParseFile('__TOOL__',[ref]$tokens,[ref]$errors)
$factory=$originalAst.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Open-TlsFile'},$true)
$calls=@($factory.FindAll({param($n) $n -is [Management.Automation.Language.InvokeMemberExpressionAst]},$true))
Assert ($calls.Count -eq 1 -and $calls[0].Expression.TypeName.FullName -ceq 'IO.FileStream' -and $calls[0].Arguments[1].Member.Value -ceq 'CreateNew') 'exclusive-file-factory'
""".replace("__TOOL__", str(TOOL).replace("'", "''")))


if __name__ == "__main__":
    unittest.main()
