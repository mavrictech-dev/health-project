param([switch]$Apply)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
# Closed local QA operation. No OS Root trust, firewall, other instance, export
# of private keys, account selection or application credentials are modified.
$project=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if($project -cne 'D:\Mavric\Health Project'){throw 'HEALTH_PROJECT_ROOT_REQUIRED'}
$job=Join-Path $project 'tmp\health-continuation-20261106'
$proof=Join-Path $job 'tls-server-result.json'
$registry='HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.HEALTHPROJECTQA\MSSQLServer\SuperSocketNetLib'
$service='MSSQL$HEALTHPROJECTQA'
$friendly='Health Project isolated QA TLS 20261106'
$expectedProtected='6217e698f4cd5b3523b96ecf8e56f699406ef26e4ebcc09f1f047a8437175e3d'
if(-not $Apply){[ordered]@{operation='local-private-CA-and-leaf';instance='HEALTHPROJECTQA';forceEncryption=1;osRootTrustChange=$false;privateKeyExport=$false;apply=$false}|ConvertTo-Json;exit 0}
. (Join-Path $PSScriptRoot 'configure-isolated-sqlserver-qa.ps1')
if(-not(Test-QaAdmin)){throw 'ELEVATION_REQUIRED'}
if(Test-Path -LiteralPath $proof){throw 'EXISTING_OUTCOME_REQUIRES_REVIEW'}
$before=Get-QaProtectedBaseline
if($before -cne $expectedProtected){throw 'PROTECTED_BASELINE_CHANGED'}
$observed=Get-QaObservation
Assert-QaObservation $observed
if($observed.Service.State -cne 'Running'){throw 'QA_RUNNING_REQUIRED'}
$prior=Get-ItemProperty -LiteralPath $registry
if($prior.Certificate -ne '' -or $prior.ForceEncryption -ne 0){throw 'UNEXPECTED_TLS_CONFIGURATION'}
if(@(Get-ChildItem Cert:\LocalMachine\My | Where-Object FriendlyName -Like "$friendly*").Count -ne 0){throw 'CERTIFICATE_COLLISION'}
$stage='create-ca';$rootCert=$null;$leaf=$null;$changed=$false
try {
 $rootCert=New-SelfSignedCertificate -Type Custom -Subject 'CN=Health Project isolated QA Root 20261106' -FriendlyName "$friendly Root" -CertStoreLocation Cert:\LocalMachine\My -KeyAlgorithm RSA -KeyLength 3072 -HashAlgorithm SHA256 -KeyExportPolicy NonExportable -KeyUsage CertSign,CRLSign,DigitalSignature -TextExtension @('2.5.29.19={critical}{text}ca=1&pathlength=0') -NotAfter (Get-Date).AddYears(2)
 $stage='create-leaf'
 $dns=[System.Net.Dns]::GetHostEntry('').HostName
 $san="2.5.29.17={text}DNS=$env:COMPUTERNAME&DNS=$dns&DNS=localhost&DNS=health.localhost&IPAddress=127.0.0.1"
 $leaf=New-SelfSignedCertificate -Type Custom -Subject "CN=$env:COMPUTERNAME" -FriendlyName "$friendly Server" -Signer $rootCert -CertStoreLocation Cert:\LocalMachine\My -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256 -KeySpec KeyExchange -Provider 'Microsoft RSA SChannel Cryptographic Provider' -KeyExportPolicy NonExportable -KeyUsage DigitalSignature,KeyEncipherment -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.1',$san) -NotAfter (Get-Date).AddYears(1)
 $stage='private-key-acl'
 $key=$leaf.PrivateKey.CspKeyContainerInfo
 if($key.KeyNumber -ne 'Exchange' -or -not $key.MachineKeyStore){throw 'SQL_KEY_EXCHANGE_REQUIRED'}
 $keys=[IO.Path]::GetFullPath((Join-Path $env:ProgramData 'Microsoft\Crypto\RSA\MachineKeys'))
 $file=[IO.Path]::GetFullPath((Join-Path $keys $key.UniqueKeyContainerName))
 if(-not $file.StartsWith($keys+'\') -or -not(Test-Path -LiteralPath $file -PathType Leaf)){throw 'PRIVATE_KEY_PATH_INVALID'}
 $acl=Get-Acl -LiteralPath $file
 $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new('NT SERVICE\MSSQL$HEALTHPROJECTQA','Read','Allow'))
 Set-Acl -LiteralPath $file -AclObject $acl
 Export-Certificate -Cert $rootCert -FilePath (Join-Path $job 'qa-root.cer') -Type CERT | Out-Null
 Export-Certificate -Cert $leaf -FilePath (Join-Path $job 'qa-server.cer') -Type CERT | Out-Null
 $stage='bind-qa-only'
 Set-ItemProperty -LiteralPath $registry -Name Certificate -Value $leaf.Thumbprint.ToLowerInvariant()
 Set-ItemProperty -LiteralPath $registry -Name ForceEncryption -Value 1
 $changed=$true
 $stage='restart-qa-only'
 Restart-Service -Name $service
 (Get-Service -Name $service).WaitForStatus('Running',[TimeSpan]::FromSeconds(30))
 $current=Get-QaObservation;Assert-QaObservation $current
 $listenerDeadline=[DateTime]::UtcNow.AddSeconds(30)
 do {
  $listeners=@(Get-NetTCPConnection -State Listen -OwningProcess ([int]$current.Service.ProcessId) -ErrorAction SilentlyContinue)
  if(@($listeners | Where-Object { $_.LocalAddress -ceq '127.0.0.1' -and $_.LocalPort -eq 14335 }).Count -eq 1){break}
  if([DateTime]::UtcNow -ge $listenerDeadline){throw 'QA_LISTENER_TIMEOUT'}
  Start-Sleep -Milliseconds 300
 } while($true)
 Assert-QaListeners $listeners ([int]$current.Service.ProcessId)
 $after=Get-QaProtectedBaseline
 if($before -cne $after){throw 'PROTECTED_BASELINE_CHANGED'}
 [ordered]@{status='bound';instance='HEALTHPROJECTQA';rootThumbprint=$rootCert.Thumbprint;leafThumbprint=$leaf.Thumbprint;leafSubject=$leaf.Subject;issuer=$leaf.Issuer;forceEncryption=1;certificateStore='LocalMachine/My';osRootTrustChanged=$false;privateKeysExported=$false;privateKeyReadPrincipal='NT SERVICE\MSSQL$HEALTHPROJECTQA';protectedBefore=$before;protectedAfter=$after;protectedUnchanged=$true;chainValidated=$false;completedUtc=[DateTime]::UtcNow.ToString('o')}|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $proof -Encoding UTF8
 exit 0
}catch{
 # Retain every artifact and exact stage. No blind rollback/reissue/retry.
 [ordered]@{status='unverified';stage=$stage;bindingChanged=$changed;rootThumbprint=if($rootCert){$rootCert.Thumbprint}else{$null};leafThumbprint=if($leaf){$leaf.Thumbprint}else{$null};errorType=$_.Exception.GetType().FullName;message=$_.Exception.Message;automaticRetry=$false;chainValidated=$false}|ConvertTo-Json|Set-Content -LiteralPath $proof -Encoding UTF8
 exit 1
}
