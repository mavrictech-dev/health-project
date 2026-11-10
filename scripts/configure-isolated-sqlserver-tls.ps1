# Windows PowerShell 5.1. Dot-source defines functions only; no inspection or Apply.
[CmdletBinding()]
param([switch]$Apply, [string]$ExpectedProtectedFingerprint, [string]$EvidenceDirectory, [string]$OperationId)

function Stop-Tls([string]$Code) { throw [InvalidOperationException]::new($Code) }

function Get-TlsSpec {
    [pscustomobject]@{
        Project = 'D:\Mavric\Health Project'; Instance = 'HEALTHPROJECTQA'
        Service = 'MSSQL$HEALTHPROJECTQA'; Principal = 'NT SERVICE\MSSQL$HEALTHPROJECTQA'
        Registry = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.HEALTHPROJECTQA\MSSQLServer\SuperSocketNetLib'
        HelperSHA256 = '3FBC605A36A6BE720B4D87E3F50D64163E167D5BA96C2C621C3B672B3A2BD831'
        FriendlyPrefix = 'Health Project isolated QA TLS '
    }
}

function Get-TlsToolRoot { [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')) }

function Get-TlsPlan {
    $s = Get-TlsSpec
    [pscustomobject]@{ status = 'planned'; apply = $false; instance = $s.Instance
        service = $s.Service; endpoint = '127.0.0.1:14335'; operation = 'local-private-CA-and-leaf'
        requiredParameters = @('ExpectedProtectedFingerprint','EvidenceDirectory','OperationId')
        evidencePattern = ($s.Project + '\tmp\tls-a69-YYYYMMDD-uniqueid')
        certificateStore = 'LocalMachine/My'; forceEncryption = 1
        osRootTrustChanged = $false; privateKeysExported = $false; chainValidated = $false }
}

function Assert-TlsNoReparse([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    while ($null -ne $item) {
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { Stop-Tls 'REPARSE_PATH' }
        if ($item -is [IO.FileInfo]) { $item = $item.Directory } else { $item = $item.Parent }
    }
}

function Get-TlsRequest([string]$Fingerprint, [string]$Directory, [string]$Id) {
    $s = Get-TlsSpec
    if ((Get-TlsToolRoot) -cne $s.Project) { Stop-Tls 'HEALTH_PROJECT_ROOT_REQUIRED' }
    if ($Fingerprint -cnotmatch '\A[0-9a-fA-F]{64}\z') { Stop-Tls 'EXPLICIT_FINGERPRINT_REQUIRED' }
    if ($Id -cnotmatch '\Aa69-[0-9]{8}-[a-z0-9]{3,32}\z') { Stop-Tls 'OPERATION_ID_INVALID' }
    $date = [DateTime]::MinValue
    if (-not [DateTime]::TryParseExact($Id.Substring(4,8), 'yyyyMMdd', [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::None, [ref]$date)) { Stop-Tls 'OPERATION_ID_INVALID' }
    $parent = $s.Project + '\tmp'
    $wanted = $parent + '\tls-' + $Id
    if ([string]::IsNullOrWhiteSpace($Directory) -or $Directory -match '[\x00-\x1f]' -or
        $Directory -match '(^|[\\/])\.{1,2}([\\/]|$)' -or $Directory -notmatch '^[A-Za-z]:[\\/]' -or
        $Directory.Substring(2).Contains(':') -or
        -not [IO.Path]::GetFullPath($Directory).Equals($wanted, [StringComparison]::OrdinalIgnoreCase)) { Stop-Tls 'EVIDENCE_PATH_INVALID' }
    Assert-TlsNoReparse $parent
    if (Test-Path -LiteralPath $wanted) { Stop-Tls 'EXISTING_EVIDENCE_REQUIRES_REVIEW' }
    # One reservation across ALL operation IDs, including failures before a result.
    $journal = $parent + '\healthprojectqa-tls-operation.jsonl'
    if (Test-Path -LiteralPath $journal) { Stop-Tls 'PRIOR_OPERATION_REQUIRES_REVIEW' }
    [pscustomobject]@{ Fingerprint = $Fingerprint.ToLowerInvariant(); Directory = $wanted; Id = $Id
        Journal = $journal; Friendly = $s.FriendlyPrefix + $Id; Spec = $s }
}

function Get-TlsHelperPath { (Get-TlsSpec).Project + '\scripts\configure-isolated-sqlserver-qa.ps1' }
function Get-TlsPinnedHelper {
    $s = Get-TlsSpec
    $path = Get-TlsHelperPath
    Assert-TlsNoReparse $path
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash -cne $s.HelperSHA256) { Stop-Tls 'HELPER_PIN_MISMATCH' }
    $path
}

# The pinned QA helper is dot-sourced only inside Invoke-TlsTool, after request
# validation. These wrappers allow offline tests to replace every OS observation.
function Test-TlsAdmin { Test-QaAdmin }
function Get-TlsProtected { Get-QaProtectedBaseline }
function Get-TlsObservation { Get-QaObservation }
function Get-TlsListeners([int]$ProcessId) { @(Get-NetTCPConnection -State Listen -OwningProcess $ProcessId -ErrorAction Stop) }
function Assert-TlsObservation($Observation) {
    Assert-QaObservation $Observation
    if ($Observation.Service.State -cne 'Running') { Stop-Tls 'QA_RUNNING_REQUIRED' }
    if (@(Get-QaPlan $Observation).Count -ne 0) { Stop-Tls 'QA_CONFIGURATION_PENDING' }
}
function Get-TlsRegistry { Get-ItemProperty -LiteralPath (Get-TlsSpec).Registry -ErrorAction Stop }
function Assert-TlsUnbound($Registry) {
    if ($Registry.Certificate -isnot [string] -or $Registry.Certificate -cne '' -or
        $Registry.ForceEncryption -isnot [int] -or $Registry.ForceEncryption -ne 0) { Stop-Tls 'UNEXPECTED_TLS_CONFIGURATION' }
}
function Assert-TlsNoCertificates {
    $prefix = (Get-TlsSpec).FriendlyPrefix.TrimEnd()
    $collisions = @(Get-ChildItem -LiteralPath 'Cert:\LocalMachine\My' -ErrorAction Stop | Where-Object {
        $_.FriendlyName.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -or
        $_.Subject -like '*CN=Health Project isolated QA Root*'
    })
    if ($collisions.Count -ne 0) { Stop-Tls 'CERTIFICATE_COLLISION_REQUIRES_REVIEW' }
}
function Get-TlsDnsHost { [Net.Dns]::GetHostEntry('').HostName }
function Get-TlsHostNames {
    $short = $env:COMPUTERNAME
    $fqdn = Get-TlsDnsHost
    foreach ($name in @($short,$fqdn)) {
        if ($name -notmatch '\A(?=.{1,253}\z)[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*\z') { Stop-Tls 'HOST_NAME_INVALID' }
    }
    [pscustomobject]@{ Short = $short; Names = @($short,$fqdn,'localhost','health.localhost' | Select-Object -Unique) }
}

function Open-TlsFile([string]$Path) {
    # Exclusive creation also prevents racing another process or overwriting a result.
    [IO.FileStream]::new($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read,
        4096, [IO.FileOptions]::WriteThrough)
}
function Write-TlsJournal($Stream, $Entry) {
    $bytes = [Text.Encoding]::UTF8.GetBytes(($Entry | ConvertTo-Json -Depth 8 -Compress) + "`n")
    $Stream.Write($bytes,0,$bytes.Length)
    $Stream.Flush($true)
}
function Write-TlsResult([string]$Directory, $Result) {
    $stream = Open-TlsFile (Join-Path $Directory 'tls-server-result.json')
    try { Write-TlsJournal $stream $Result } finally { $stream.Dispose() }
}
function New-TlsEvidence([string]$Directory) {
    # Without -Force, an existing directory is a hard collision.
    New-Item -ItemType Directory -Path $Directory -ErrorAction Stop | Out-Null
    Assert-TlsNoReparse $Directory
}
function Initialize-TlsEvidence($Request, [string]$Before) {
    # Prove new evidence files are writable BEFORE generating any key. This file
    # is retained even if a later effect or final-result write fails.
    $stream = Open-TlsFile (Join-Path $Request.Directory 'tls-operation.json')
    try {
        Write-TlsJournal $stream @{operationId=$Request.Id;instance='HEALTHPROJECTQA';stage='prepared'
            journal=$Request.Journal;friendlyName=$Request.Friendly;protectedBefore=$Before;chainValidated=$false}
    } finally { $stream.Dispose() }
}
function New-TlsCA($Request) {
    New-SelfSignedCertificate -Type Custom -Subject ('CN=Health Project isolated QA Root ' + $Request.Id) `
        -FriendlyName ($Request.Friendly + ' Root') -CertStoreLocation 'Cert:\LocalMachine\My' `
        -KeyAlgorithm RSA -KeyLength 3072 -HashAlgorithm SHA256 -KeyExportPolicy NonExportable `
        -KeyUsage CertSign,CRLSign,DigitalSignature -TextExtension @('2.5.29.19={critical}{text}ca=1&pathlength=0') `
        -NotAfter (Get-Date).AddYears(2) -ErrorAction Stop
}
function New-TlsLeaf($Request, $RootCertificate, $Hosts) {
    $san = '2.5.29.17={text}' + (($Hosts.Names | ForEach-Object { 'DNS=' + $_ }) -join '&') + '&IPAddress=127.0.0.1'
    New-SelfSignedCertificate -Type Custom -Subject ('CN=' + $Hosts.Short) -FriendlyName ($Request.Friendly + ' Server') `
        -Signer $RootCertificate -CertStoreLocation 'Cert:\LocalMachine\My' -KeyAlgorithm RSA -KeyLength 2048 `
        -HashAlgorithm SHA256 -KeySpec KeyExchange -Provider 'Microsoft RSA SChannel Cryptographic Provider' `
        -KeyExportPolicy NonExportable -KeyUsage DigitalSignature,KeyEncipherment `
        -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.1',$san) -NotAfter (Get-Date).AddYears(1) -ErrorAction Stop
}
function Assert-TlsCertificate($Certificate, [string]$Friendly) {
    if ($null -eq $Certificate -or $Certificate.Thumbprint -cnotmatch '^[0-9A-Fa-f]{40}$' -or
        $Certificate.FriendlyName -cne $Friendly -or -not $Certificate.HasPrivateKey) { Stop-Tls 'NEW_CERTIFICATE_INVALID' }
}
function New-TlsReadRule([string]$Principal, $Rights, $AccessType) {
    [Security.AccessControl.FileSystemAccessRule]::new($Principal, $Rights, $AccessType)
}
function Grant-TlsLeafRead($Leaf) {
    $key = $Leaf.PrivateKey.CspKeyContainerInfo
    if ($key.KeyNumber.ToString() -cne 'Exchange' -or -not $key.MachineKeyStore -or $key.Exportable -or
        $key.UniqueKeyContainerName -cnotmatch '^[A-Za-z0-9_-]+$') { Stop-Tls 'SQL_KEY_EXCHANGE_REQUIRED' }
    $keys = [IO.Path]::GetFullPath((Join-Path $env:ProgramData 'Microsoft\Crypto\RSA\MachineKeys'))
    $file = [IO.Path]::GetFullPath((Join-Path $keys $key.UniqueKeyContainerName))
    if (-not $file.StartsWith($keys+'\', [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $file -PathType Leaf)) { Stop-Tls 'PRIVATE_KEY_PATH_INVALID' }
    Assert-TlsNoReparse $file
    # Read existing descriptor and ADD one Read ACE; never replace or broaden it.
    $acl = Get-Acl -LiteralPath $file -ErrorAction Stop
    $rule = New-TlsReadRule (Get-TlsSpec).Principal ([Security.AccessControl.FileSystemRights]::Read) ([Security.AccessControl.AccessControlType]::Allow)
    $acl.AddAccessRule($rule)
    Set-Acl -LiteralPath $file -AclObject $acl -ErrorAction Stop
}
function Export-TlsPublic($Certificate, [string]$File) {
    if (Test-Path -LiteralPath $File) { Stop-Tls 'EXPORT_COLLISION' }
    Export-Certificate -Cert $Certificate -FilePath $File -Type CERT -ErrorAction Stop | Out-Null
}
function Set-TlsBinding([string]$Thumbprint) {
    if ($Thumbprint -cnotmatch '^[0-9A-Fa-f]{40}$') { Stop-Tls 'NEW_CERTIFICATE_INVALID' }
    Set-ItemProperty -LiteralPath (Get-TlsSpec).Registry -Name Certificate -Value $Thumbprint.ToLowerInvariant() -ErrorAction Stop
}
function Set-TlsForceEncryption {
    Set-ItemProperty -LiteralPath (Get-TlsSpec).Registry -Name ForceEncryption -Value 1 -ErrorAction Stop
}
function Restart-TlsQA {
    $s = Get-TlsSpec
    $svc = Get-Service -Name $s.Service -ErrorAction Stop
    if (@($svc.DependentServices | Where-Object { $_.Status -ne 'Stopped' }).Count -ne 0) { Stop-Tls 'SERVICE_DEPENDENTS_RUNNING' }
    Restart-Service -Name $s.Service -ErrorAction Stop
    (Get-Service -Name $s.Service -ErrorAction Stop).WaitForStatus('Running',[TimeSpan]::FromSeconds(30))
}
function Wait-TlsQA {
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    do {
        $o = Get-TlsObservation
        Assert-TlsObservation $o
        $listeners = @(Get-TlsListeners ([int]$o.Service.ProcessId))
        if (@($listeners | Where-Object { $_.LocalAddress -ceq '127.0.0.1' -and $_.LocalPort -eq 14335 }).Count -eq 1) {
            Assert-QaListeners $listeners ([int]$o.Service.ProcessId)
            return
        }
        if ([DateTime]::UtcNow -ge $deadline) { Stop-Tls 'QA_LISTENER_TIMEOUT' }
        Start-Sleep -Milliseconds 300
    } while ($true)
}
function Get-TlsSafeCode($ErrorRecord) {
    $code = $ErrorRecord.Exception.Message
    $known = @('HEALTH_PROJECT_ROOT_REQUIRED','EXPLICIT_FINGERPRINT_REQUIRED','OPERATION_ID_INVALID','EVIDENCE_PATH_INVALID',
        'REPARSE_PATH','EXISTING_EVIDENCE_REQUIRES_REVIEW','PRIOR_OPERATION_REQUIRES_REVIEW','HELPER_PIN_MISMATCH',
        'ELEVATION_REQUIRED','PROTECTED_BASELINE_CHANGED','QA_RUNNING_REQUIRED','QA_CONFIGURATION_PENDING',
        'UNEXPECTED_TLS_CONFIGURATION','CERTIFICATE_COLLISION_REQUIRES_REVIEW','HOST_NAME_INVALID','NEW_CERTIFICATE_INVALID',
        'SQL_KEY_EXCHANGE_REQUIRED','PRIVATE_KEY_PATH_INVALID','EXPORT_COLLISION','SERVICE_DEPENDENTS_RUNNING',
        'QA_LISTENER_TIMEOUT','TLS_BINDING_NOT_VERIFIED','TARGET_MISMATCH','BINARY_PATH_INVALID','ENGINE_IDENTITY_INVALID',
        'MASTER_PATH_INVALID','SERVICE_START_MODE_INVALID','SERVICE_TRANSITION_PENDING','AUTH_MODE_INVALID',
        'NETWORK_SHAPE_INVALID','LOOPBACK_NOT_UNIQUE','LISTENER_MISSING','EXTERNAL_LISTENER','PATH_INVALID')
    if ($code -cin $known) { return $code }
    'TLS_INSPECTION_OR_ACTION_FAILED'
}

function Invoke-TlsTool([bool]$DoApply, [string]$Fingerprint, [string]$Directory, [string]$Id) {
    $ErrorActionPreference = 'Stop'
    if (-not $DoApply) { return Get-TlsPlan }
    $request = $null; $journal = $null; $stage = 'preflight'; $rootCert = $null; $leaf = $null
    $before = $null; $after = $null; $bindingAttempted = $false; $evidenceReady = $false
    try {
        $request = Get-TlsRequest $Fingerprint $Directory $Id
        . (Get-TlsPinnedHelper)
        if (-not (Test-TlsAdmin)) { Stop-Tls 'ELEVATION_REQUIRED' }
        $observedFingerprint = Get-TlsProtected
        if ($observedFingerprint -isnot [string] -or $observedFingerprint -cnotmatch '\A[0-9a-fA-F]{64}\z' -or
            $observedFingerprint.ToLowerInvariant() -cne $request.Fingerprint) { Stop-Tls 'PROTECTED_BASELINE_CHANGED' }
        $before = $observedFingerprint.ToLowerInvariant()
        $observation = Get-TlsObservation
        Assert-TlsObservation $observation
        Assert-QaListeners @(Get-TlsListeners ([int]$observation.Service.ProcessId)) ([int]$observation.Service.ProcessId)
        Assert-TlsUnbound (Get-TlsRegistry)
        Assert-TlsNoCertificates
        $hosts = Get-TlsHostNames
        # Exclusive durable journal is the reservation. Leave it in place even on
        # success: any reissue/new operation needs independent review of its state.
        $stage = 'reserve-evidence'
        $journal = Open-TlsFile $request.Journal
        Write-TlsJournal $journal ([ordered]@{stage=$stage;operationId=$Id;evidence=$request.Directory;protectedBefore=$before;utc=[DateTime]::UtcNow.ToString('o')})
        New-TlsEvidence $request.Directory
        $evidenceReady = $true
        $stage = 'initialize-evidence'
        Write-TlsJournal $journal @{stage=$stage;operationId=$Id}
        Initialize-TlsEvidence $request $before
        $stage = 'create-ca'
        Write-TlsJournal $journal @{stage=$stage;operationId=$Id}
        $rootCert = New-TlsCA $request
        Assert-TlsCertificate $rootCert ($request.Friendly + ' Root')
        $stage = 'create-leaf'
        Write-TlsJournal $journal @{stage=$stage;rootThumbprint=$rootCert.Thumbprint}
        $leaf = New-TlsLeaf $request $rootCert $hosts
        Assert-TlsCertificate $leaf ($request.Friendly + ' Server')
        if ($leaf.Thumbprint -ieq $rootCert.Thumbprint) { Stop-Tls 'NEW_CERTIFICATE_INVALID' }
        $stage = 'private-key-acl'
        Write-TlsJournal $journal @{stage=$stage;rootThumbprint=$rootCert.Thumbprint;leafThumbprint=$leaf.Thumbprint}
        Grant-TlsLeafRead $leaf
        $stage = 'export-ca-public'
        Write-TlsJournal $journal @{stage=$stage;leafThumbprint=$leaf.Thumbprint;rootThumbprint=$rootCert.Thumbprint}
        Export-TlsPublic $rootCert (Join-Path $request.Directory 'qa-root.cer')
        $stage = 'export-leaf-public'
        Write-TlsJournal $journal @{stage=$stage;leafThumbprint=$leaf.Thumbprint;rootThumbprint=$rootCert.Thumbprint}
        Export-TlsPublic $leaf (Join-Path $request.Directory 'qa-server.cer')
        # Reconcile binding again immediately before writing it, never trust an old artifact.
        Assert-TlsUnbound (Get-TlsRegistry)
        $stage = 'bind-certificate'
        Write-TlsJournal $journal @{stage=$stage;leafThumbprint=$leaf.Thumbprint;rootThumbprint=$rootCert.Thumbprint}
        $bindingAttempted = $true
        Set-TlsBinding $leaf.Thumbprint
        $stage = 'force-encryption'
        Write-TlsJournal $journal @{stage=$stage;bindingMayHaveChanged=$true;leafThumbprint=$leaf.Thumbprint;rootThumbprint=$rootCert.Thumbprint}
        Set-TlsForceEncryption
        $stage = 'restart-qa'
        Write-TlsJournal $journal @{stage=$stage;bindingMayHaveChanged=$true;leafThumbprint=$leaf.Thumbprint;rootThumbprint=$rootCert.Thumbprint}
        Restart-TlsQA
        $stage = 'verify-readiness'
        Write-TlsJournal $journal @{stage=$stage;bindingMayHaveChanged=$true;leafThumbprint=$leaf.Thumbprint;rootThumbprint=$rootCert.Thumbprint}
        Wait-TlsQA
        $current = Get-TlsRegistry
        if ($current.Certificate -ine $leaf.Thumbprint -or $current.ForceEncryption -isnot [int] -or $current.ForceEncryption -ne 1) { Stop-Tls 'TLS_BINDING_NOT_VERIFIED' }
        $observedFingerprint = Get-TlsProtected
        if ($observedFingerprint -isnot [string] -or $observedFingerprint -cnotmatch '\A[0-9a-fA-F]{64}\z') { Stop-Tls 'PROTECTED_BASELINE_CHANGED' }
        $after = $observedFingerprint.ToLowerInvariant()
        if ($before -cne $after) { Stop-Tls 'PROTECTED_BASELINE_CHANGED' }
        $result = [ordered]@{status='bound';operationId=$Id;instance='HEALTHPROJECTQA';rootThumbprint=$rootCert.Thumbprint;leafThumbprint=$leaf.Thumbprint
            forceEncryption=1;certificateStore='LocalMachine/My';privateKeyReadPrincipal=(Get-TlsSpec).Principal
            protectedBefore=$before;protectedAfter=$after;protectedUnchanged=$true;chainValidated=$false
            osRootTrustChanged=$false;privateKeysExported=$false;automaticRetry=$false;completedUtc=[DateTime]::UtcNow.ToString('o')}
        $stage = 'record-result'
        Write-TlsJournal $journal @{stage=$stage;status='bound';chainValidated=$false;rootThumbprint=$rootCert.Thumbprint;leafThumbprint=$leaf.Thumbprint}
        Write-TlsResult $request.Directory $result
        Write-TlsJournal $journal @{stage='completed';status='bound';chainValidated=$false;rootThumbprint=$rootCert.Thumbprint;leafThumbprint=$leaf.Thumbprint}
    } catch {
        # Never serialize exception messages/inner exceptions or retry/undo effects.
        $result = [ordered]@{status='unverified';stage=$stage;code=(Get-TlsSafeCode $_);operationId=if($request){$request.Id}else{$null}
            mutationMayHaveOccurred=($stage -cne 'preflight');bindingMayHaveChanged=$bindingAttempted
            rootThumbprint=if($rootCert){$rootCert.Thumbprint}else{$null};leafThumbprint=if($leaf){$leaf.Thumbprint}else{$null}
            protectedBefore=$before;protectedAfter=$after;chainValidated=$false;automaticRetry=$false;reviewRequired=$true}
        if ($null -ne $journal) {
            try { Write-TlsJournal $journal $result } catch { $result.journalWriteFailed=$true }
            if ($evidenceReady -and $stage -cne 'record-result') {
                try { Write-TlsResult $request.Directory $result } catch { $result.resultWriteFailed=$true }
            }
        }
    } finally {
        if ($null -ne $journal) {
            try { $journal.Dispose() } catch {
                $result.status='unverified'; $result.stage='close-journal'; $result.code='JOURNAL_CLOSE_FAILED'
                $result.journalCloseFailed=$true; $result.reviewRequired=$true
            }
        }
    }
    [pscustomobject]$result
}

if ($MyInvocation.InvocationName -ne '.') {
    $result = Invoke-TlsTool ([bool]$Apply) $ExpectedProtectedFingerprint $EvidenceDirectory $OperationId
    $result | ConvertTo-Json -Depth 10
    if ($result.status -in @('planned','bound')) { exit 0 }
    exit 1
}
