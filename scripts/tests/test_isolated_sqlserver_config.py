"""Offline contracts; one fresh-process regression reads fixed service Name/Status."""
import base64
import json
import os
from pathlib import Path
import shutil
import subprocess
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "configure-isolated-sqlserver-qa.ps1"
POWERSHELL = shutil.which("powershell.exe")

FIXTURE = r"""
function New-Fixture([bool]$Final = $false) {
    $s = Get-QaSpec
    $properties = [Collections.Generic.List[object]]::new()
    function Add-Property($IP, $Name, $Type, $Number, $Text) {
        $properties.Add([pscustomobject]@{ InstanceName='HEALTHPROJECTQA'; ProtocolName='Tcp'; IPAddressName=$IP; PropertyName=$Name; PropertyType=$Type; PropertyNumVal=$Number; PropertyStrVal=$Text })
    }
    Add-Property '' 'ListenOnAllIPs' 0 $(if ($Final) {0} else {1}) $null
    foreach ($slot in @('IP2','IP17','IP30')) {
        $loop = $slot -eq 'IP17'
        $address = switch ($slot) { 'IP2' {'192.0.2.20'} 'IP17' {'127.0.0.1'} 'IP30' {'::1'} }
        Add-Property $slot 'IpAddress' 1 $null $address
        Add-Property $slot 'Enabled' 0 $(if ($Final -and $loop) {1} elseif ($Final -or $loop) {0} else {1}) $null
        Add-Property $slot 'TcpPort' 1 $null $(if ($Final -and $loop) {'14335'} else {''})
        Add-Property $slot 'TcpDynamicPorts' 1 $null $(if ($Final -and $loop) {''} else {'0'})
    }
    Add-Property 'IPAll' 'TcpPort' 1 $null $(if ($Final) {'14335'} else {''})
    Add-Property 'IPAll' 'TcpDynamicPorts' 1 $null $(if ($Final) {''} else {'0'})
    [pscustomobject]@{
        Instance=$s.Instance; InstanceId=$s.InstanceId
        Service=[pscustomobject]@{Name=$s.Service; PathName=('"' + $s.Binary + '" -sHEALTHPROJECTQA'); StartMode='Manual'; State=$(if ($Final) {'Running'} else {'Stopped'}); ProcessId=$(if ($Final) {1234} else {0})}
        Master='D:\HealthProject-QA\SqlServer\DATA\master.mdf'; Binary=$s.Binary
        MicrosoftSigned=$true; Version='16.0.1000.6'; Reparse=$false
        LoginMode=$(if ($Final) {2} else {1}); LoginKind='DWord'
        Protocols=@([pscustomobject]@{InstanceName=$s.Instance; ProtocolName='Tcp'; Enabled=$Final},[pscustomobject]@{InstanceName=$s.Instance; ProtocolName='Np'; Enabled=$false})
        Properties=$properties.ToArray()
    }
}
function Expect-Code($Work, [string]$Expected) {
    try { & $Work; throw 'NO_FAILURE' }
    catch { if ($_.Exception.Message -cne $Expected) { throw 'WRONG_SAFE_ERROR' } }
}
"""

SERVICE_FIXTURE = r"""
function New-ServiceFixture {
    $controller=[pscustomobject]@{DependentServices=@(); FailWait=$false}
    $controller | Add-Member ScriptMethod Start {
        if ($args.Count -ne 0) {throw 'FORCE_OR_ARGUMENTS_NOT_ALLOWED'}
        $script:serviceEvents.Add('Start')
    }
    $controller | Add-Member ScriptMethod Stop {
        if ($args.Count -ne 0) {throw 'FORCE_OR_ARGUMENTS_NOT_ALLOWED'}
        $script:serviceEvents.Add('Stop')
    }
    $controller | Add-Member ScriptMethod WaitForStatus {
        param($Status,$Timeout)
        if ($Status -isnot [System.ServiceProcess.ServiceControllerStatus] -or
            $Timeout -isnot [TimeSpan] -or $Timeout.TotalSeconds -le 0 -or $Timeout.TotalSeconds -gt 45) {throw 'INVALID_WAIT_CONTRACT'}
        $script:serviceEvents.Add('Wait:'+$Status.ToString())
        $script:waitBudgets.Add($Timeout.TotalSeconds)
        if ($this.FailWait) {throw 'FIXTURE_TIMEOUT'}
        [Threading.Thread]::Sleep(15)
    }
    $controller | Add-Member ScriptMethod Dispose { $script:serviceEvents.Add('Dispose') }
    $controller
}
function Reset-ServiceFixture {
    $script:serviceEvents=[Collections.Generic.List[string]]::new()
    $script:waitBudgets=[Collections.Generic.List[double]]::new()
    $script:controller=New-ServiceFixture
}
"""


@unittest.skipUnless(POWERSHELL, "Windows PowerShell 5.1 required")
class IsolatedSqlServerConfigTest(unittest.TestCase):
    def ps(self, body):
        command = (
            "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; . '"
            + str(SCRIPT).replace("'", "''")
            + "';\n"
            + FIXTURE
            + "\n"
            + body
        )
        encoded = base64.b64encode(command.encode("utf-16-le")).decode("ascii")
        env = {k: v for k, v in os.environ.items() if k.upper() in {
            "SYSTEMROOT", "WINDIR", "SYSTEMDRIVE", "TEMP", "TMP", "PATH",
            "COMSPEC", "PATHEXT",
        }}
        proc = subprocess.run(
            [POWERSHELL, "-NoProfile", "-NonInteractive", "-EncodedCommand", encoded],
            capture_output=True, text=True, timeout=20, env=env,
            creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
        )
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(proc.stderr, "")
        return proc.stdout.strip()

    def test_syntax_and_dot_source_no_effects(self):
        self.assertEqual(self.ps(r"""
$tokens=$null; $errors=$null
$null=[Management.Automation.Language.Parser]::ParseFile($MyInvocation.MyCommand.Path,[ref]$tokens,[ref]$errors)
if (@($errors).Count -ne 0) {throw 'SYNTAX_INVALID'}
if (-not (Get-Command Invoke-QaTool)) {throw 'FUNCTION_MISSING'}
'OK'
""".replace("$MyInvocation.MyCommand.Path", "'" + str(SCRIPT).replace("'", "''") + "'")), "OK")

    def test_valid_plan_only_whitelisted_loopback_actions(self):
        actions = json.loads(self.ps("@(Get-QaPlan (New-Fixture)) | ConvertTo-Json -Depth 6 -Compress"))
        self.assertEqual(actions[-2]["kind"], "EnableTcp")
        self.assertEqual(actions[-1]["kind"], "Start")
        self.assertTrue({"kind": "Flag", "ip": "IP17", "property": "Enabled", "value": True} in actions)
        self.assertTrue({"kind": "Flag", "ip": "IP2", "property": "Enabled", "value": False} in actions)
        self.assertTrue({"kind": "Flag", "ip": "IP30", "property": "Enabled", "value": False} in actions)
        self.assertEqual({a["value"] for a in actions if a["property"] == "TcpPort"}, {"14335"})
        self.assertFalse(any(a["kind"] == "Restart" for a in actions))

    def test_final_state_no_restart_or_actions(self):
        self.assertEqual(self.ps("if (@(Get-QaPlan (New-Fixture $true)).Count -ne 0) {throw 'UNNECESSARY_RESTART'}; 'OK'"), "OK")

    def test_running_reconfiguration_disables_tcp_first_and_enables_last(self):
        kinds = json.loads(self.ps("$o=New-Fixture; $o.Service.State='Running'; $o.Protocols[0].Enabled=$true; @(Get-QaPlan $o | ForEach-Object {$_.kind}) | ConvertTo-Json -Compress"))
        self.assertEqual(kinds[0], "DisableTcp")
        self.assertEqual(kinds[-2:], ["EnableTcp", "Restart"])

    def test_target_path_identity_and_reparse_rejections(self):
        self.assertEqual(self.ps(r"""
foreach ($case in @(
    @('Instance','MSSQLSERVER','TARGET_MISMATCH'),
    @('InstanceId','MSSQL16.MSSQLSERVER','TARGET_MISMATCH'),
    @('Binary','C:\elsewhere\sqlservr.exe','BINARY_PATH_INVALID'),
    @('Master','D:\HealthProject-QA\SqlServer\..\elsewhere\master.mdf','PATH_INVALID'),
    @('Master','D:\elsewhere\master.mdf','PATH_INVALID'),
    @('Master','D:\HealthProject-QA\SqlServer\DATA\wrong.mdf','MASTER_PATH_INVALID'),
    @('Version','15.0.1.1','ENGINE_IDENTITY_INVALID'),
    @('MicrosoftSigned',$false,'ENGINE_IDENTITY_INVALID'),
    @('Reparse',$true,'REPARSE_PATH'),
    @('LoginKind','String','AUTH_MODE_INVALID'),
    @('LoginMode',3,'AUTH_MODE_INVALID')
)) { $o=New-Fixture; $o.($case[0])=$case[1]; Expect-Code {Get-QaPlan $o} $case[2] }
$o=New-Fixture; $o.Service.PathName='"C:\wrong\sqlservr.exe" -sHEALTHPROJECTQA'; Expect-Code {Get-QaPlan $o} 'BINARY_PATH_INVALID'
$o=New-Fixture; $o.Service.StartMode='Auto'; Expect-Code {Get-QaPlan $o} 'SERVICE_START_MODE_INVALID'
'OK'
"""), "OK")

    def test_network_shape_flags_and_loopback_must_be_known(self):
        self.assertEqual(self.ps(r"""
$o=New-Fixture; $o.Properties[0].PropertyNumVal=2; Expect-Code {Get-QaPlan $o} 'NETWORK_SHAPE_INVALID'
$o=New-Fixture; $o.Protocols[0].InstanceName='MSSQLSERVER'; Expect-Code {Get-QaPlan $o} 'NETWORK_SHAPE_INVALID'
$o=New-Fixture; (Get-QaProperty $o 'IP17' 'IpAddress').PropertyStrVal='127.0.0.2'; Expect-Code {Get-QaPlan $o} 'LOOPBACK_NOT_UNIQUE'
$o=New-Fixture; $o.Properties += $o.Properties[0]; Expect-Code {Get-QaPlan $o} 'NETWORK_SHAPE_INVALID'
'OK'
"""), "OK")

    def test_non_admin_apply_stops_before_any_inspection_or_write(self):
        result = json.loads(self.ps(r"""
function Test-QaAdmin { $false }
function Get-QaProtectedBaseline { throw 'MUST_NOT_READ' }
function Get-QaObservation { throw 'MUST_NOT_READ' }
function Invoke-QaAction { throw 'MUST_NOT_WRITE' }
Invoke-QaTool Apply | ConvertTo-Json -Compress
"""))
        self.assertEqual((result["status"], result["code"]), ("blocked", "ELEVATION_REQUIRED"))
        self.assertFalse(result["mutation_attempted"])

    def test_plan_readonly_and_pending_safe(self):
        result = json.loads(self.ps(r"""
function Get-QaProtectedBaseline {'baseline'}
function Get-QaObservation {New-Fixture}
function Invoke-QaAction {throw 'MUST_NOT_WRITE'}
function Invoke-QaSqlVerify {throw 'MUST_NOT_SQL'}
Invoke-QaTool Plan | ConvertTo-Json -Depth 8 -Compress
"""))
        self.assertEqual(result["status"], "planned")
        self.assertTrue(result["protected_unchanged"])
        self.assertFalse(result["jdbc_positive_validated"])
        blocked = json.loads(self.ps(r"""
function Get-QaProtectedBaseline {'baseline'}
function Get-QaObservation {Stop-Qa 'INSTALLATION_PENDING'}
function Invoke-QaAction {throw 'MUST_NOT_WRITE'}
Invoke-QaTool Plan | ConvertTo-Json -Compress
"""))
        self.assertEqual((blocked["status"], blocked["code"]), ("blocked", "INSTALLATION_PENDING"))

    def test_apply_model_converges_without_sql_and_final_state_no_effects(self):
        self.assertEqual(self.ps(r"""
$script:reads=0; $script:effects=@()
function Test-QaAdmin {$true}
function Get-QaProtectedBaseline {'baseline'}
function Get-QaObservation {$script:reads++; if ($script:reads -eq 1) {New-Fixture} else {New-Fixture $true}}
function Invoke-QaAction($Action,$Observation) {$script:effects += $Action.kind}
function Invoke-QaSqlVerify {throw 'MUST_NOT_SQL'}
$result=Invoke-QaTool Apply
if ($result.status -ne 'configured' -or $script:effects[-1] -ne 'Start' -or -not $result.protected_unchanged) {throw 'APPLY_MODEL_FAILED'}
$script:effects=@(); $script:reads=2
$result=Invoke-QaTool Apply
if ($result.status -ne 'configured' -or $script:effects.Count -ne 0) {throw 'UNNECESSARY_EFFECT'}
'OK'
"""), "OK")

    def test_baseline_change_fails_closed_even_after_configuration(self):
        result = json.loads(self.ps(r"""
$script:reads=0
function Get-QaProtectedBaseline {$script:reads++; if ($script:reads -eq 1) {'before'} else {'changed'}}
function Get-QaObservation {New-Fixture $true}
Invoke-QaTool Plan | ConvertTo-Json -Compress
"""))
        self.assertEqual((result["status"], result["code"]), ("error", "PROTECTED_BASELINE_CHANGED"))

    def test_listener_pid_and_external_addresses(self):
        self.assertEqual(self.ps(r"""
$good=[pscustomobject]@{OwningProcess=1234; LocalAddress='127.0.0.1'; LocalPort=14335}
Assert-QaListeners @($good,[pscustomobject]@{OwningProcess=1234; LocalAddress='::1'; LocalPort=14336}) 1234
foreach ($address in @('0.0.0.0','::','192.0.2.1')) {
 Expect-Code {Assert-QaListeners @([pscustomobject]@{OwningProcess=1234;LocalAddress=$address;LocalPort=14335}) 1234} 'EXTERNAL_LISTENER'
}
Expect-Code {Assert-QaListeners @($good) 99} 'EXTERNAL_LISTENER'
Expect-Code {Assert-QaListeners @() 1234} 'LISTENER_MISSING'
'OK'
"""), "OK")

    def test_sql_instance_auth_sa_shape_and_transport_errors(self):
        self.assertEqual(self.ps(r"""
function Good-Sql { [pscustomobject]@{instanceName='HEALTHPROJECTQA'; productVersion='16.0.1000.6'; windowsOnly=0; saDisabled=1} }
Assert-QaSqlResponse (Good-Sql)
foreach ($case in @(@('instanceName','MSSQLSERVER'),@('productVersion','15.0.1.2'),@('windowsOnly',1),@('saDisabled',0),@('saDisabled','1'))) {
 $row=Good-Sql; $row.($case[0])=$case[1]; Expect-Code {Assert-QaSqlResponse $row} 'SQL_TARGET_NOT_VERIFIED'
}
$row=Good-Sql; $row | Add-Member NoteProperty secret 'DO_NOT_ECHO'; Expect-Code {Assert-QaSqlResponse $row} 'SQL_RESPONSE_INVALID'
Assert-QaSqlTransport 0 " `r`n "
Expect-Code {Assert-QaSqlTransport 0 "Timeout expired`r`n"} 'SQLCMD_TIMEOUT'
Expect-Code {Assert-QaSqlTransport 1 'timeout expired'} 'SQLCMD_TIMEOUT'
Expect-Code {Assert-QaSqlTransport 0 'DO_NOT_ECHO'} 'SQLCMD_FAILED'
Expect-Code {Assert-QaSqlTransport 1 ''} 'SQLCMD_FAILED'
'OK'
"""), "OK")

    def test_effective_sqlcmd_arguments_and_pre_metadata_instance_guard(self):
        argv = json.loads(self.ps("@(Get-QaSqlVerifyArguments) | ConvertTo-Json -Compress"))
        self.assertEqual(argv[:-1], [
            "-S", "tcp:127.0.0.1,14335", "-E", "-C", "-b", "-X1", "-x",
            "-l", "5", "-t", "10", "-f", "65001", "-y", "0", "-w", "65535",
            "-r1", "-d", "master", "-Q",
        ])
        self.assertNotIn("-h", argv)
        self.assertNotIn("-W", argv)
        query = argv[-1]
        self.assertTrue(query.startswith("SET NOCOUNT ON; IF ISNULL("))
        self.assertIn("COLLATE Latin1_General_100_BIN2 <> N'HEALTHPROJECTQA'", query)
        self.assertLess(query.index("THROW 51000"), query.index("SELECT CONVERT"))
        self.assertLess(query.index("THROW 51000"), query.index("sys.server_principals"))
        self.assertIn("FOR JSON PATH,WITHOUT_ARRAY_WRAPPER", query)
        # The actual transport must obtain its argv from this tested supplier,
        # not retain an untested second literal array. No SQL is executed here.
        self.assertEqual(self.ps(r"""
$body=(Get-Command Invoke-QaSqlVerify).ScriptBlock.Ast
$calls=@($body.FindAll({param($node) $node -is [Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'Get-QaSqlVerifyArguments'},$true))
if ($calls.Count -ne 1) {throw 'REAL_TRANSPORT_NOT_USING_ARGUMENTS'}
$assignments=@($body.FindAll({param($node) $node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -eq '$argv'},$true))
if ($assignments.Count -ne 1 -or $assignments[0].Right.Extent.Text -ne '@(Get-QaSqlVerifyArguments)') {throw 'REAL_ARGV_NOT_COVERED'}
if ($body.Extent.Text -notmatch 'WaitForExit\(20000\)') {throw 'PROCESS_BUDGET_CHANGED'}
'OK'
"""), "OK")

    def test_installed_sqlcmd_accepts_effective_options_in_help_mode_offline(self):
        sqlcmd = shutil.which("sqlcmd.exe")
        self.assertIsNotNone(sqlcmd, "installed ODBC SQLcmd required for offline syntax regression")
        argv = json.loads(self.ps("@(Get-QaSqlVerifyArguments) | ConvertTo-Json -Compress"))
        env = {k: v for k, v in os.environ.items() if k.upper() in {
            "SYSTEMROOT", "WINDIR", "SYSTEMDRIVE", "TEMP", "TMP", "PATH",
            "COMSPEC", "PATHEXT",
        }}
        # -? requests local usage, never a connection or query. The exact argv
        # assertion above independently rejects -h/-W with -y0: help is not a
        # substitute for that assertion or for later real SQL verification.
        result = subprocess.run(
            [sqlcmd, *argv, "-?"], capture_output=True, text=True, timeout=20,
            env=env, creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
        )
        self.assertEqual(result.returncode, 0)
        self.assertFalse(result.stderr.strip())
        self.assertIn("SQL Server Command Line Tool", result.stdout)
        for option in ("[-d ", "[-w ", "[-y ", "[-r[0|1]", "[-? "):
            self.assertIn(option, result.stdout)

    def test_verify_requires_config_listeners_and_sql(self):
        result = json.loads(self.ps(r"""
function Get-QaProtectedBaseline {'baseline'}
function Get-QaObservation {New-Fixture $true}
function Get-NetTCPConnection { [pscustomobject]@{OwningProcess=1234;LocalAddress='127.0.0.1';LocalPort=14335} }
function Invoke-QaSqlVerify { [pscustomobject]@{instanceName='HEALTHPROJECTQA';productVersion='16.0.1000.6';windowsOnly=0;saDisabled=1} }
function Invoke-QaAction {throw 'MUST_NOT_WRITE'}
Invoke-QaTool Verify | ConvertTo-Json -Compress
"""))
        self.assertEqual(result["status"], "verified")
        self.assertTrue(result["sql_verified"])
        self.assertFalse(result["jdbc_positive_validated"])

    def test_verify_never_accepts_missing_sql_or_unconfigured_target(self):
        self.assertEqual(self.ps(r"""
function Get-QaProtectedBaseline {'baseline'}
function Get-QaObservation {New-Fixture}
function Get-NetTCPConnection {throw 'MUST_NOT_QUERY_LISTENERS'}
function Invoke-QaSqlVerify {throw 'MUST_NOT_SQL'}
$result=Invoke-QaTool Verify
if ($result.status -ne 'blocked' -or $result.code -ne 'CONFIGURATION_PENDING') {throw 'PENDING_WAS_ACCEPTED'}
function Get-QaObservation {New-Fixture $true}
function Get-NetTCPConnection {[pscustomobject]@{OwningProcess=1234;LocalAddress='127.0.0.1';LocalPort=14335}}
function Invoke-QaSqlVerify {Stop-Qa 'SQLCMD_TIMEOUT'}
$result=Invoke-QaTool Verify
if ($result.status -ne 'error' -or $result.code -ne 'SQLCMD_TIMEOUT' -or $result.sql_verified) {throw 'TIMEOUT_WAS_ACCEPTED'}
function Invoke-QaSqlVerify {[pscustomobject]@{instanceName='MSSQLSERVER';productVersion='16.0.1000.6';windowsOnly=0;saDisabled=1}}
$result=Invoke-QaTool Verify
if ($result.status -ne 'error' -or $result.code -ne 'SQL_TARGET_NOT_VERIFIED') {throw 'WRONG_SQL_WAS_ACCEPTED'}
'OK'
"""), "OK")

    def test_apply_stops_after_first_failed_effect_and_checks_baseline(self):
        self.assertEqual(self.ps(r"""
$script:effects=0; $script:baselines=0
function Test-QaAdmin {$true}
function Get-QaProtectedBaseline {$script:baselines++; 'baseline'}
function Get-QaObservation {New-Fixture}
function Invoke-QaAction {$script:effects++; Assert-QaCimResult ([pscustomobject]@{ReturnValue=[uint32]7})}
$result=Invoke-QaTool Apply
if ($result.status -ne 'error' -or $result.code -ne 'CIM_MUTATION_FAILED' -or $script:effects -ne 1 -or $script:baselines -ne 2 -or -not $result.mutation_attempted) {throw 'FAILED_MUTATION_CONTINUED'}
'OK'
"""), "OK")

    def test_cim_failure_and_forged_action_never_accepted(self):
        self.assertEqual(self.ps(r"""
Assert-QaCimResult ([pscustomobject]@{ReturnValue=[uint32]0})
Expect-Code {Assert-QaCimResult ([pscustomobject]@{ReturnValue=[uint32]5})} 'CIM_MUTATION_FAILED'
Expect-Code {Assert-QaCimResult $null} 'CIM_MUTATION_FAILED'
function Test-QaAdmin {$true}
function Get-CimInstance {throw 'MUST_NOT_REACH_OS'}
Expect-Code {Invoke-QaAction (New-QaAction 'String' 'IP17' 'TcpPort' '1433') (New-Fixture)} 'ACTION_NOT_ALLOWED'
Expect-Code {Invoke-QaAction (New-QaAction 'StartMSSQLSERVER') (New-Fixture)} 'ACTION_NOT_ALLOWED'
'OK'
"""), "OK")

    def test_fresh_ps51_loads_real_service_types_and_constructor_readonly(self):
        self.assertEqual(self.ps(SERVICE_FIXTURE + r"""
if ($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1) {throw 'PS51_REQUIRED'}
if (@(Get-Module Microsoft.PowerShell.Management).Count -ne 0) {throw 'MANAGEMENT_MODULE_PRELOADED'}
if (@([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object {$_.GetName().Name -eq 'System.ServiceProcess'}).Count -ne 0) {throw 'SERVICE_ASSEMBLY_PRELOADED'}
$script:realFactory=(Get-Command New-QaServiceController).ScriptBlock
$script:realStatus=$null
Reset-ServiceFixture
function New-QaServiceController {
    # Execute the actual production constructor after Invoke-QaService loads
    # its assembly, inspect only Name/Status and dispose. Effects use a fixture.
    $real=& $script:realFactory
    try {
        if ($real -isnot [System.ServiceProcess.ServiceController] -or $real.ServiceName -cne 'MSSQL$HEALTHPROJECTQA') {throw 'REAL_CONSTRUCTOR_WRONG_TARGET'}
        $script:realStatus=$real.Status
        if ($script:realStatus -isnot [System.ServiceProcess.ServiceControllerStatus]) {throw 'REAL_STATUS_TYPE_INVALID'}
    } finally {$real.Dispose()}
    $script:controller
}
Invoke-QaService Start
if (($script:serviceEvents -join ',') -cne 'Start,Wait:Running,Dispose') {throw 'REAL_SERVICE_ROUTE_NOT_EXECUTED'}
$again=& $script:realFactory
try {if ($again.Status -ne $script:realStatus) {throw 'REAL_SERVICE_STATUS_CHANGED'}} finally {$again.Dispose()}
'OK'
"""), "OK")

    def test_production_service_start_restart_deadline_and_disposal_with_fixture(self):
        self.assertEqual(self.ps(SERVICE_FIXTURE + r"""
function New-QaServiceController {$script:controller}
Reset-ServiceFixture
Invoke-QaService Start
if (($script:serviceEvents -join ',') -cne 'Start,Wait:Running,Dispose' -or $script:waitBudgets.Count -ne 1) {throw 'START_CONTRACT_FAILED'}
Reset-ServiceFixture
Invoke-QaService Restart
if (($script:serviceEvents -join ',') -cne 'Stop,Wait:Stopped,Start,Wait:Running,Dispose' -or $script:waitBudgets.Count -ne 2) {throw 'RESTART_CONTRACT_FAILED'}
if ($script:waitBudgets[1] -ge $script:waitBudgets[0]) {throw 'DEADLINE_WAS_RESET'}
# No Force or dependent-service operations are available on this fixture.
Reset-ServiceFixture
$script:controller.DependentServices=@([pscustomobject]@{Status=[System.ServiceProcess.ServiceControllerStatus]::Running})
Expect-Code {Invoke-QaService Restart} 'SERVICE_DEPENDENTS_RUNNING'
if (($script:serviceEvents -join ',') -cne 'Dispose') {throw 'DEPENDENT_WAS_TOUCHED'}
Reset-ServiceFixture
$script:controller.FailWait=$true
try {Invoke-QaService Restart; throw 'NO_TIMEOUT'} catch {if ($_.Exception.Message -notlike '*FIXTURE_TIMEOUT*') {throw 'WRONG_WAIT_FAILURE'}}
if (($script:serviceEvents -join ',') -cne 'Stop,Wait:Stopped,Dispose') {throw 'CONTINUED_AFTER_WAIT_FAILURE'}
Reset-ServiceFixture
Expect-Code {Invoke-QaService 'Force'} 'ACTION_NOT_ALLOWED'
if ($script:serviceEvents.Count -ne 0) {throw 'INVALID_SERVICE_ACTION'}
'OK'
"""), "OK")

    def test_actual_effect_dispatch_uses_exact_cim_target_and_method(self):
        self.assertEqual(self.ps(r"""
function Test-QaAdmin {$true}
$script:seen=@()
function Get-CimInstance($Namespace,$ClassName,$Filter) {
 if ($Namespace -ne 'root/Microsoft/SqlServer/ComputerManagement16' -or $Filter -notlike "InstanceName='HEALTHPROJECTQA'*") {throw 'WRONG_TARGET'}
 if ($ClassName -eq 'ServerNetworkProtocolProperty') {(New-Fixture).Properties}
 else {[pscustomobject]@{InstanceName='HEALTHPROJECTQA';ProtocolName='Tcp'}}
}
function Invoke-CimMethod($InputObject,$MethodName,$Arguments) {
 $script:seen += [pscustomobject]@{method=$MethodName;args=$Arguments}; [pscustomobject]@{ReturnValue=[uint32]0}
}
$o=New-Fixture
Invoke-QaAction (New-QaAction 'Flag' '' 'ListenOnAllIPs' $false) $o
Invoke-QaAction (New-QaAction 'String' 'IP17' 'TcpPort' '14335') $o
Invoke-QaAction (New-QaAction 'EnableTcp') $o
if ($script:seen[0].method -ne 'SetFlag' -or $script:seen[0].args.BoolValue -ne $false -or $script:seen[1].method -ne 'SetStringValue' -or $script:seen[1].args.StrValue -ne '14335' -or $script:seen[2].method -ne 'SetEnable') {throw 'WRONG_METHOD'}
'OK'
"""), "OK")

    def test_unexpected_error_is_safe_and_invalid_mode_does_not_inspect(self):
        result = self.ps(r"""
function Get-QaProtectedBaseline {throw 'CANARY_PRIVATE_CAUSE'}
Invoke-QaTool Plan | ConvertTo-Json -Compress
Invoke-QaTool 'CANARY_PRIVATE_MODE' | ConvertTo-Json -Compress
""" )
        self.assertNotIn("CANARY", result)
        rows = [json.loads(line) for line in result.splitlines()]
        self.assertEqual(rows[0]["code"], "INSPECTION_OR_ACTION_FAILED")
        self.assertEqual(rows[1]["code"], "MODE_INVALID")

    def test_registry_access_denied_wrapped_by_powershell_is_blocked_safely(self):
        output = self.ps(r"""
function Get-QaProtectedBaseline {'baseline'}
function Get-QaObservation {throw [InvalidOperationException]::new('CANARY_OUTER',[UnauthorizedAccessException]::new('CANARY_INNER'))}
Invoke-QaTool Plan | ConvertTo-Json -Compress
""")
        self.assertNotIn("CANARY", output)
        row = json.loads(output)
        self.assertEqual((row["status"], row["code"]), ("blocked", "INSPECTION_ACCESS_DENIED"))
        self.assertTrue(row["protected_unchanged"])


if __name__ == "__main__":
    unittest.main()
