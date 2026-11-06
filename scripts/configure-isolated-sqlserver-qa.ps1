# Windows PowerShell 5.1. Dot-source to test functions without running the CLI.
[CmdletBinding()]
param([string]$Mode = 'Plan')

function Stop-Qa([string]$Code) { throw [InvalidOperationException]::new($Code) }

function Test-QaAccessDenied($Exception) {
    # PowerShell can wrap registry access errors in MethodInvocationException.
    # Inspect types only; never serialize exception text, values or causes.
    for ($depth = 0; $depth -lt 8 -and $null -ne $Exception; $depth++) {
        if ($Exception -is [Security.SecurityException] -or $Exception -is [UnauthorizedAccessException]) { return $true }
        $Exception = $Exception.InnerException
    }
    $false
}

function Get-QaSpec {
    [pscustomobject]@{
        Instance = 'HEALTHPROJECTQA'; InstanceId = 'MSSQL16.HEALTHPROJECTQA'
        Service = 'MSSQL$HEALTHPROJECTQA'; Address = '127.0.0.1'; Port = 14335
        Root = 'D:\HealthProject-QA\SqlServer'
        Binary = 'C:\Program Files\Microsoft SQL Server\MSSQL16.HEALTHPROJECTQA\MSSQL\Binn\sqlservr.exe'
        Namespace = 'root/Microsoft/SqlServer/ComputerManagement16'
        Key = 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.HEALTHPROJECTQA\MSSQLServer'
    }
}

function Test-QaAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    try { ([Security.Principal.WindowsPrincipal]::new($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
    finally { $id.Dispose() }
}

function Assert-QaPath([string]$Path, [string]$Root) {
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -match '[\x00-\x1f]' -or
        $Path -match '(^|[\\/])\.{1,2}([\\/]|$)' -or $Path -notmatch '^[A-Za-z]:[\\/]') { Stop-Qa 'PATH_INVALID' }
    $full = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $prefix = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    if (-not ($full.Equals($prefix, [StringComparison]::OrdinalIgnoreCase) -or
        $full.StartsWith($prefix + '\', [StringComparison]::OrdinalIgnoreCase))) { Stop-Qa 'PATH_INVALID' }
    if ($full.Substring(2).Contains(':')) { Stop-Qa 'PATH_INVALID' }
}

function Assert-QaNoReparse([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    while ($null -ne $item) {
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { Stop-Qa 'REPARSE_PATH' }
        if ($item -is [IO.FileInfo]) { $item = $item.Directory } else { $item = $item.Parent }
    }
}

function Open-QaRegistry {
    [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
}

# Only the default instance network/auth settings and two service configurations
# enter this protection fingerprint. No accounts, credentials or business data.
function Get-QaProtectedBaseline {
    $base = Open-QaRegistry
    try {
        $names = $base.OpenSubKey('SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL', $false)
        try { $defaultId = if ($names) { $names.GetValue('MSSQLSERVER') } else { $null } } finally { if ($names) { $names.Dispose() } }
        if ($defaultId -ne 'MSSQL16.MSSQLSERVER') { Stop-Qa 'PROTECTED_BASELINE_UNKNOWN' }
        $auth = $base.OpenSubKey('SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQLServer', $false)
        try { $login = $auth.GetValue('LoginMode'); $kind = $auth.GetValueKind('LoginMode').ToString() } finally { if ($auth) { $auth.Dispose() } }
        $network = [Collections.Generic.List[object]]::new()
        function Read-QaNetworkKey($Parent, [string]$Relative) {
            $key = $Parent.OpenSubKey($Relative, $false)
            try {
                if (-not $key) { Stop-Qa 'PROTECTED_BASELINE_UNKNOWN' }
                foreach ($name in @($key.GetValueNames() | Sort-Object)) {
                    $network.Add([ordered]@{ key = $Relative; name = $name; kind = $key.GetValueKind($name).ToString(); value = $key.GetValue($name) })
                }
                foreach ($child in @($key.GetSubKeyNames() | Sort-Object)) { Read-QaNetworkKey $Parent ($Relative + '\' + $child) }
            } finally { if ($key) { $key.Dispose() } }
        }
        Read-QaNetworkKey $base 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQLServer\SuperSocketNetLib'
        $services = @(foreach ($name in @('MSSQLSERVER', 'SQLBrowser')) {
            $svc = @(Get-CimInstance Win32_Service -Filter ("Name='" + $name + "'") -ErrorAction Stop)
            if ($svc.Count -ne 1) { Stop-Qa 'PROTECTED_BASELINE_UNKNOWN' }
            $svc[0] | Select-Object Name, PathName, StartMode, State, ProcessId
        })
        $json = [ordered]@{ login = $login; loginKind = $kind; network = @($network.ToArray()); services = $services } | ConvertTo-Json -Depth 15 -Compress
        $sha = [Security.Cryptography.SHA256]::Create()
        try { -join ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($json)) | ForEach-Object { $_.ToString('x2') }) } finally { $sha.Dispose() }
    } finally { $base.Dispose() }
}

function Get-QaObservation {
    $s = Get-QaSpec
    $base = Open-QaRegistry
    try {
        $names = $base.OpenSubKey('SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL', $false)
        try { $id = if ($names) { $names.GetValue($s.Instance) } else { $null } } finally { if ($names) { $names.Dispose() } }
        $svc = @(Get-CimInstance Win32_Service -Filter 'Name=''MSSQL$HEALTHPROJECTQA''' -ErrorAction Stop)
        if (-not $id -and $svc.Count -eq 0) { Stop-Qa 'INSTALLATION_PENDING' }
        if (-not $id -or $svc.Count -ne 1) { Stop-Qa 'INSTALLATION_PARTIAL' }
        if ($id -cne $s.InstanceId) { Stop-Qa 'TARGET_MISMATCH' }
        $server = $base.OpenSubKey($s.Key, $false)
        try {
            if (-not $server) { Stop-Qa 'INSTALLATION_PARTIAL' }
            $login = $server.GetValue('LoginMode'); $loginKind = $server.GetValueKind('LoginMode').ToString()
        } finally { if ($server) { $server.Dispose() } }
        $parameters = $base.OpenSubKey($s.Key + '\Parameters', $false)
        try {
            if (-not $parameters) { Stop-Qa 'INSTALLATION_PARTIAL' }
            $master = @($parameters.GetValueNames() | Where-Object { $_ -match '^SQLArg[0-9]+$' } |
                ForEach-Object { $parameters.GetValue($_) } | Where-Object { $_ -is [string] -and $_.StartsWith('-d') })
            if ($master.Count -ne 1) { Stop-Qa 'MASTER_PATH_INVALID' }
            $masterPath = $master[0].Substring(2)
        } finally { if ($parameters) { $parameters.Dispose() } }
    } finally { $base.Dispose() }
    Assert-QaPath $masterPath $s.Root
    if ([IO.Path]::GetFileName($masterPath) -ine 'master.mdf') { Stop-Qa 'MASTER_PATH_INVALID' }
    Assert-QaNoReparse $masterPath
    Assert-QaNoReparse $s.Binary
    $binary = Get-Item -LiteralPath $s.Binary -ErrorAction Stop
    $signature = Get-AuthenticodeSignature -LiteralPath $s.Binary -ErrorAction Stop
    $signed = $signature.Status -eq 'Valid' -and $null -ne $signature.SignerCertificate -and
        $signature.SignerCertificate.Subject -match '(^|,\s*)O=Microsoft Corporation(,|$)'
    $protocols = @(Get-CimInstance -Namespace $s.Namespace -ClassName ServerNetworkProtocol -Filter "InstanceName='HEALTHPROJECTQA'" -ErrorAction Stop)
    $properties = @(Get-CimInstance -Namespace $s.Namespace -ClassName ServerNetworkProtocolProperty -Filter "InstanceName='HEALTHPROJECTQA' AND ProtocolName='Tcp'" -ErrorAction Stop)
    [pscustomobject]@{ Instance = $s.Instance; InstanceId = $id; Service = $svc[0]; Master = $masterPath
        Binary = $s.Binary; MicrosoftSigned = [bool]$signed; Version = $binary.VersionInfo.ProductVersion
        Reparse = $false; LoginMode = $login; LoginKind = $loginKind; Protocols = $protocols; Properties = $properties }
}

function Get-QaProperty($Observation, [string]$IP, [string]$Name) {
    $rows = @($Observation.Properties | Where-Object { $_.IPAddressName -ceq $IP -and $_.PropertyName -ceq $Name })
    if ($rows.Count -ne 1) { Stop-Qa 'NETWORK_SHAPE_INVALID' }
    $rows[0]
}

function Assert-QaObservation($O) {
    $s = Get-QaSpec
    if ($O.Instance -cne $s.Instance -or $O.InstanceId -cne $s.InstanceId -or $O.Service.Name -cne $s.Service) { Stop-Qa 'TARGET_MISMATCH' }
    $expected = '^"' + [regex]::Escape($s.Binary) + '" -s(?:\s*)HEALTHPROJECTQA$'
    if ($O.Binary -ine $s.Binary -or $O.Service.PathName -cnotmatch $expected) { Stop-Qa 'BINARY_PATH_INVALID' }
    if ($O.MicrosoftSigned -isnot [bool] -or -not $O.MicrosoftSigned -or $O.Version -notmatch '^16\.0\.\d+\.\d+$') { Stop-Qa 'ENGINE_IDENTITY_INVALID' }
    if ($O.Reparse -isnot [bool] -or $O.Reparse) { Stop-Qa 'REPARSE_PATH' }
    Assert-QaPath $O.Master $s.Root
    if ([IO.Path]::GetFileName($O.Master) -ine 'master.mdf') { Stop-Qa 'MASTER_PATH_INVALID' }
    if ($O.Service.StartMode -cne 'Manual') { Stop-Qa 'SERVICE_START_MODE_INVALID' }
    if ($O.Service.State -cnotin @('Running', 'Stopped')) { Stop-Qa 'SERVICE_TRANSITION_PENDING' }
    if ($O.LoginKind -cne 'DWord' -or $O.LoginMode -notin @(1, 2) -or $O.LoginMode -is [string]) { Stop-Qa 'AUTH_MODE_INVALID' }
    foreach ($name in @('Tcp', 'Np')) {
        $p = @($O.Protocols | Where-Object { $_.ProtocolName -ceq $name })
        if ($p.Count -ne 1 -or $p[0].InstanceName -cne $s.Instance -or $p[0].Enabled -isnot [bool]) { Stop-Qa 'NETWORK_SHAPE_INVALID' }
    }
    foreach ($p in $O.Properties) {
        if ($p.InstanceName -cne $s.Instance -or $p.ProtocolName -cne 'Tcp' -or $p.IPAddressName -cnotmatch '^(|IP[1-9][0-9]*|IPAll)$') { Stop-Qa 'NETWORK_SHAPE_INVALID' }
    }
    $listen = Get-QaProperty $O '' 'ListenOnAllIPs'
    if ($listen.PropertyType -ne 0 -or $listen.PropertyNumVal -is [string] -or $null -eq $listen.PropertyNumVal -or $listen.PropertyNumVal -notin @(0, 1)) { Stop-Qa 'NETWORK_SHAPE_INVALID' }
    $ips = @($O.Properties | Where-Object { $_.PropertyName -ceq 'IpAddress' })
    if ($ips.Count -eq 0) { Stop-Qa 'NETWORK_SHAPE_INVALID' }
    $seen = @{}
    foreach ($ip in $ips) {
        if ($ip.IPAddressName -cnotmatch '^IP[1-9][0-9]*$' -or $seen.ContainsKey($ip.IPAddressName)) { Stop-Qa 'NETWORK_SHAPE_INVALID' }
        $seen[$ip.IPAddressName] = $true
        $parsed = $null
        if (-not [Net.IPAddress]::TryParse($ip.PropertyStrVal, [ref]$parsed)) { Stop-Qa 'NETWORK_SHAPE_INVALID' }
        $enabled = Get-QaProperty $O $ip.IPAddressName 'Enabled'
        if ($enabled.PropertyType -ne 0 -or $enabled.PropertyNumVal -is [string] -or $null -eq $enabled.PropertyNumVal -or $enabled.PropertyNumVal -notin @(0, 1)) { Stop-Qa 'NETWORK_SHAPE_INVALID' }
        foreach ($field in @('TcpPort', 'TcpDynamicPorts')) {
            $prop = Get-QaProperty $O $ip.IPAddressName $field
            if ($prop.PropertyType -ne 1 -or $prop.PropertyStrVal -isnot [string]) { Stop-Qa 'NETWORK_SHAPE_INVALID' }
        }
    }
    foreach ($p in $O.Properties) {
        if ($p.IPAddressName -cmatch '^IP[1-9][0-9]*$' -and -not $seen.ContainsKey($p.IPAddressName)) { Stop-Qa 'NETWORK_SHAPE_INVALID' }
    }
    if (@($ips | Where-Object { $_.PropertyStrVal -ceq '127.0.0.1' }).Count -ne 1) { Stop-Qa 'LOOPBACK_NOT_UNIQUE' }
    foreach ($field in @('TcpPort', 'TcpDynamicPorts')) {
        $prop = Get-QaProperty $O 'IPAll' $field
        if ($prop.PropertyType -ne 1 -or $prop.PropertyStrVal -isnot [string]) { Stop-Qa 'NETWORK_SHAPE_INVALID' }
    }
}

function New-QaAction([string]$Kind, [string]$IP = '', [string]$Property = '', $Value = $null) {
    [pscustomobject]@{ kind = $Kind; ip = $IP; property = $Property; value = $Value }
}

function Get-QaPlan($O) {
    Assert-QaObservation $O
    $actions = [Collections.Generic.List[object]]::new()
    if ($O.LoginMode -ne 2) { $actions.Add((New-QaAction 'LoginMode' '' '' 2)) }
    if ((Get-QaProperty $O '' 'ListenOnAllIPs').PropertyNumVal -ne 0) { $actions.Add((New-QaAction 'Flag' '' 'ListenOnAllIPs' $false)) }
    $ips = @($O.Properties | Where-Object { $_.PropertyName -ceq 'IpAddress' })
    foreach ($ip in $ips) {
        $loop = $ip.PropertyStrVal -ceq '127.0.0.1'
        if ([bool](Get-QaProperty $O $ip.IPAddressName 'Enabled').PropertyNumVal -ne $loop) {
            $actions.Add((New-QaAction 'Flag' $ip.IPAddressName 'Enabled' $loop))
        }
        if ($loop) {
            if ((Get-QaProperty $O $ip.IPAddressName 'TcpPort').PropertyStrVal -cne '14335') { $actions.Add((New-QaAction 'String' $ip.IPAddressName 'TcpPort' '14335')) }
            if ((Get-QaProperty $O $ip.IPAddressName 'TcpDynamicPorts').PropertyStrVal -cne '') { $actions.Add((New-QaAction 'String' $ip.IPAddressName 'TcpDynamicPorts' '')) }
        }
    }
    foreach ($field in @('TcpPort', 'TcpDynamicPorts')) {
        $wanted = if ($field -eq 'TcpPort') { '14335' } else { '' }
        if ((Get-QaProperty $O 'IPAll' $field).PropertyStrVal -cne $wanted) { $actions.Add((New-QaAction 'String' 'IPAll' $field $wanted)) }
    }
    $tcp = @($O.Protocols | Where-Object { $_.ProtocolName -ceq 'Tcp' })[0]
    $np = @($O.Protocols | Where-Object { $_.ProtocolName -ceq 'Np' })[0]
    if ($np.Enabled) { $actions.Add((New-QaAction 'DisableNp')) }
    # Do not leave a live, externally bound TCP protocol enabled while editing it.
    if ($tcp.Enabled -and $actions.Count -gt 0) { $actions.Insert(0, (New-QaAction 'DisableTcp')) }
    if (-not $tcp.Enabled -or $actions.Count -gt 0) { $actions.Add((New-QaAction 'EnableTcp')) }
    if ($actions.Count -gt 0 -and $O.Service.State -eq 'Running') { $actions.Add((New-QaAction 'Restart')) }
    elseif ($O.Service.State -eq 'Stopped') { $actions.Add((New-QaAction 'Start')) }
    @($actions.ToArray())
}

function Assert-QaCimResult($Result) {
    if ($null -eq $Result -or ($Result.ReturnValue -isnot [uint32] -and $Result.ReturnValue -isnot [int]) -or $Result.ReturnValue -ne 0) { Stop-Qa 'CIM_MUTATION_FAILED' }
}

function New-QaServiceController {
    [System.ServiceProcess.ServiceController]::new('MSSQL$HEALTHPROJECTQA')
}

function Invoke-QaService([string]$Action) {
    if ($Action -cnotin @('Start', 'Restart')) { Stop-Qa 'ACTION_NOT_ALLOWED' }
    # A fresh Windows PowerShell 5.1 process has not necessarily loaded this
    # assembly. Do not rely on Get-Service or another module loading it first.
    Add-Type -AssemblyName System.ServiceProcess -ErrorAction Stop
    $service = New-QaServiceController
    $deadline = [DateTime]::UtcNow.AddSeconds(45)
    try {
        if ($Action -ceq 'Restart') {
            if (@($service.DependentServices | Where-Object { $_.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Stopped }).Count -ne 0) { Stop-Qa 'SERVICE_DEPENDENTS_RUNNING' }
            $service.Stop()
            $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Stopped, ($deadline - [DateTime]::UtcNow))
        }
        $service.Start()
        $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Running, ($deadline - [DateTime]::UtcNow))
    } finally { $service.Dispose() }
}

function Invoke-QaAction($Action, $Observation) {
    if (-not (Test-QaAdmin)) { Stop-Qa 'ELEVATION_REQUIRED' }
    # Accept only an action freshly derived from the validated fixed target.
    $serialized = $Action | ConvertTo-Json -Compress
    $allowed = @(Get-QaPlan $Observation | ForEach-Object { $_ | ConvertTo-Json -Compress })
    if ($serialized -cnotin $allowed) { Stop-Qa 'ACTION_NOT_ALLOWED' }
    $s = Get-QaSpec
    if ($Action.kind -eq 'LoginMode') {
        $base = Open-QaRegistry
        try {
            $key = $base.OpenSubKey($s.Key, $true)
            try {
                if ($key.GetValueKind('LoginMode') -ne [Microsoft.Win32.RegistryValueKind]::DWord -or $key.GetValue('LoginMode') -notin @(1, 2)) { Stop-Qa 'AUTH_MODE_INVALID' }
                $key.SetValue('LoginMode', 2, [Microsoft.Win32.RegistryValueKind]::DWord)
            } finally { if ($key) { $key.Dispose() } }
        } finally { $base.Dispose() }
        return
    }
    if ($Action.kind -in @('Start', 'Restart')) {
        Invoke-QaService $Action.kind
        return
    }
    if ($Action.kind -in @('DisableNp', 'DisableTcp', 'EnableTcp')) {
        $protocol = if ($Action.kind -eq 'DisableNp') { 'Np' } else { 'Tcp' }
        $rows = @(Get-CimInstance -Namespace $s.Namespace -ClassName ServerNetworkProtocol -Filter ("InstanceName='HEALTHPROJECTQA' AND ProtocolName='" + $protocol + "'") -ErrorAction Stop)
        if ($rows.Count -ne 1 -or $rows[0].InstanceName -cne $s.Instance) { Stop-Qa 'NETWORK_SHAPE_INVALID' }
        $method = if ($Action.kind -eq 'EnableTcp') { 'SetEnable' } else { 'SetDisable' }
        Assert-QaCimResult (Invoke-CimMethod -InputObject $rows[0] -MethodName $method -ErrorAction Stop)
        return
    }
    $rows = @(Get-CimInstance -Namespace $s.Namespace -ClassName ServerNetworkProtocolProperty -Filter "InstanceName='HEALTHPROJECTQA' AND ProtocolName='Tcp'" -ErrorAction Stop |
        Where-Object { $_.IPAddressName -ceq $Action.ip -and $_.PropertyName -ceq $Action.property })
    if ($rows.Count -ne 1 -or $rows[0].InstanceName -cne $s.Instance) { Stop-Qa 'NETWORK_SHAPE_INVALID' }
    if ($Action.kind -eq 'Flag') { $method = 'SetFlag'; $arguments = @{ BoolValue = [bool]$Action.value } }
    elseif ($Action.kind -eq 'String') { $method = 'SetStringValue'; $arguments = @{ StrValue = [string]$Action.value } }
    else { Stop-Qa 'ACTION_NOT_ALLOWED' }
    Assert-QaCimResult (Invoke-CimMethod -InputObject $rows[0] -MethodName $method -Arguments $arguments -ErrorAction Stop)
}

function Assert-QaListeners($Listeners, [int]$ServicePid) {
    if ($ServicePid -le 0 -or @($Listeners).Count -eq 0) { Stop-Qa 'LISTENER_MISSING' }
    $primary = 0
    foreach ($l in $Listeners) {
        if ($l.OwningProcess -ne $ServicePid -or $l.LocalAddress -cnotin @('127.0.0.1', '::1')) { Stop-Qa 'EXTERNAL_LISTENER' }
        if ($l.LocalPort -eq 14335 -and $l.LocalAddress -ceq '127.0.0.1') { $primary++ }
    }
    if ($primary -ne 1) { Stop-Qa 'LISTENER_MISSING' }
}

function Assert-QaSqlResponse($Row) {
    $keys = @($Row.PSObject.Properties.Name | Sort-Object)
    if (($keys -join ',') -cne 'instanceName,productVersion,saDisabled,windowsOnly') { Stop-Qa 'SQL_RESPONSE_INVALID' }
    if ($Row.instanceName -cne 'HEALTHPROJECTQA' -or $Row.productVersion -notmatch '^16\.0\.\d+\.\d+$' -or
        $Row.windowsOnly -isnot [int] -or $Row.windowsOnly -ne 0 -or $Row.saDisabled -isnot [int] -or $Row.saDisabled -ne 1) { Stop-Qa 'SQL_TARGET_NOT_VERIFIED' }
}

function Assert-QaSqlTransport($RawExit, $Stderr) {
    if ($Stderr -isnot [string]) { Stop-Qa 'SQLCMD_FAILED' }
    if ($Stderr -match '(?im)^\s*Timeout[\t ]+expired\s*$') { Stop-Qa 'SQLCMD_TIMEOUT' }
    if (-not [string]::IsNullOrWhiteSpace($Stderr) -or $RawExit -isnot [int] -or $RawExit -ne 0) { Stop-Qa 'SQLCMD_FAILED' }
}

function Get-QaSqlVerifyArguments {
    $query = "SET NOCOUNT ON; IF ISNULL(CONVERT(nvarchar(128),SERVERPROPERTY('InstanceName')),N'') COLLATE Latin1_General_100_BIN2 <> N'HEALTHPROJECTQA' BEGIN; THROW 51000,N'QA SQL target not verified.',1; END; SELECT CONVERT(nvarchar(128),SERVERPROPERTY('InstanceName')) AS instanceName,CONVERT(varchar(30),SERVERPROPERTY('ProductVersion')) AS productVersion,CONVERT(int,SERVERPROPERTY('IsIntegratedSecurityOnly')) AS windowsOnly,CONVERT(int,(SELECT is_disabled FROM sys.server_principals WHERE name=N'sa' AND principal_id=1)) AS saDisabled FOR JSON PATH,WITHOUT_ARRAY_WRAPPER;"
    @('-S','tcp:127.0.0.1,14335','-E','-C','-b','-X1','-x','-l','5','-t','10','-f','65001','-y','0','-w','65535','-r1','-d','master','-Q',$query)
}

function Invoke-QaSqlVerify {
    # No application credentials, SQLCMDINI, SQLCMDPASSWORD or inherited app env.
    $command = Get-Command sqlcmd.exe -CommandType Application -ErrorAction Stop
    $argv = @(Get-QaSqlVerifyArguments)
    # ProcessStartInfo.ArgumentList is unavailable in Windows PowerShell 5.1.
    # These are fixed internal args, escaped with the Windows CommandLineToArgvW rule.
    $quoted = @($argv | ForEach-Object { '"' + ([regex]::Replace(([regex]::Replace($_, '(\\*)"', '$1$1\"')), '(\\+)$', '$1$1')) + '"' })
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $command.Source; $start.Arguments = $quoted -join ' '
    $start.UseShellExecute = $false; $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
    $start.StandardOutputEncoding = [Text.Encoding]::UTF8; $start.StandardErrorEncoding = [Text.Encoding]::UTF8
    $start.EnvironmentVariables.Clear()
    foreach ($key in @('SystemRoot','WINDIR','SystemDrive','TEMP','TMP','PATH','COMSPEC','PATHEXT')) {
        $value = [Environment]::GetEnvironmentVariable($key, 'Process')
        if ($null -ne $value) { $start.EnvironmentVariables[$key] = $value }
    }
    $process = [Diagnostics.Process]::new(); $process.StartInfo = $start
    try {
        if (-not $process.Start()) { Stop-Qa 'SQLCMD_FAILED' }
        $stdout = $process.StandardOutput.ReadToEndAsync(); $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(20000)) { $process.Kill(); $process.WaitForExit(); Stop-Qa 'SQLCMD_TIMEOUT' }
        Assert-QaSqlTransport $process.ExitCode $stderr.Result
        try { $row = $stdout.Result.Trim() | ConvertFrom-Json -ErrorAction Stop } catch { Stop-Qa 'SQL_RESPONSE_INVALID' }
        Assert-QaSqlResponse $row
        $row
    } finally { $process.Dispose() }
}

function Invoke-QaTool([string]$RequestedMode) {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $before = $null; $result = $null; $attempted = $false
    try {
        if ($RequestedMode -cnotin @('Plan','Apply','Verify')) { Stop-Qa 'MODE_INVALID' }
        if ($RequestedMode -ceq 'Apply' -and -not (Test-QaAdmin)) { Stop-Qa 'ELEVATION_REQUIRED' }
        $before = Get-QaProtectedBaseline
        $observation = Get-QaObservation
        $actions = @(Get-QaPlan $observation)
        if ($RequestedMode -ceq 'Apply') {
            foreach ($action in $actions) { $attempted = $true; Invoke-QaAction $action $observation }
            $remaining = @(Get-QaPlan (Get-QaObservation))
            if ($remaining.Count -ne 0) { Stop-Qa 'CONFIGURATION_NOT_CONVERGED' }
            $result = [ordered]@{ status = 'configured'; code = 'SQL_VERIFY_REQUIRED'; actions = $actions; sql_verified = $false }
        } elseif ($RequestedMode -ceq 'Verify') {
            if ($actions.Count -ne 0) { Stop-Qa 'CONFIGURATION_PENDING' }
            $pidValue = [int]$observation.Service.ProcessId
            $listeners = @(Get-NetTCPConnection -State Listen -OwningProcess $pidValue -ErrorAction Stop)
            Assert-QaListeners $listeners $pidValue
            Assert-QaSqlResponse (Invoke-QaSqlVerify)
            $result = [ordered]@{ status = 'verified'; code = 'INSTANCE_VERIFIED'; sql_verified = $true; listeners = @($listeners | Select-Object LocalAddress, LocalPort) }
        } else { $result = [ordered]@{ status = 'planned'; code = 'REVIEW_BEFORE_APPLY'; actions = $actions; sql_verified = $false } }
    } catch {
        $known = @('MODE_INVALID','ELEVATION_REQUIRED','INSTALLATION_PENDING','INSTALLATION_PARTIAL','TARGET_MISMATCH','PATH_INVALID','REPARSE_PATH','MASTER_PATH_INVALID','BINARY_PATH_INVALID','ENGINE_IDENTITY_INVALID','SERVICE_START_MODE_INVALID','SERVICE_TRANSITION_PENDING','SERVICE_DEPENDENTS_RUNNING','AUTH_MODE_INVALID','NETWORK_SHAPE_INVALID','LOOPBACK_NOT_UNIQUE','ACTION_NOT_ALLOWED','CIM_MUTATION_FAILED','CONFIGURATION_NOT_CONVERGED','CONFIGURATION_PENDING','LISTENER_MISSING','EXTERNAL_LISTENER','SQL_RESPONSE_INVALID','SQL_TARGET_NOT_VERIFIED','SQLCMD_TIMEOUT','SQLCMD_FAILED','PROTECTED_BASELINE_UNKNOWN')
        $code = if ($_.Exception.Message -cin $known) { $_.Exception.Message } elseif (Test-QaAccessDenied $_.Exception) { 'INSPECTION_ACCESS_DENIED' } else { 'INSPECTION_OR_ACTION_FAILED' }
        $status = if (-not $attempted -and $code -in @('INSTALLATION_PENDING','INSTALLATION_PARTIAL','ELEVATION_REQUIRED','INSPECTION_ACCESS_DENIED','SERVICE_TRANSITION_PENDING','CONFIGURATION_PENDING')) { 'blocked' } else { 'error' }
        $result = [ordered]@{ status = $status; code = $code; sql_verified = $false; mutation_attempted = $attempted }
    } finally {
        if ($null -ne $before) {
            try {
                $after = Get-QaProtectedBaseline
                $result.protected_before = $before; $result.protected_after = $after
                $result.protected_unchanged = $before -ceq $after
                if ($before -cne $after) { $result.status = 'error'; $result.code = 'PROTECTED_BASELINE_CHANGED' }
            } catch { $result.status = 'error'; $result.code = 'PROTECTED_BASELINE_UNVERIFIED'; $result.protected_unchanged = $false }
        }
    }
    $result.instance = 'HEALTHPROJECTQA'; $result.endpoint = '127.0.0.1:14335'
    $result.jdbc_positive_validated = $false
    $result.message = 'Dedicated QA only. No runtime login, TLS, JDBC, grants or application validation. Apply requires elevated review; run Verify separately as the original SQL administrator.'
    [pscustomobject]$result
}

if ($MyInvocation.InvocationName -ne '.') {
    $result = Invoke-QaTool $Mode
    $result | ConvertTo-Json -Depth 12
    if ($result.status -in @('planned','configured','verified')) { exit 0 }
    if ($result.status -eq 'blocked') { exit 2 }
    exit 1
}
