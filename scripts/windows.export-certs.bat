@@:: This prolog allows a PowerShell script to be embedded in a .CMD file.


@@:: Any non-PowerShell content must be preceeded by "@@"


@@setlocal


@@set POWERSHELL_BAT_ARGS=%*


@@if defined POWERSHELL_BAT_ARGS set POWERSHELL_BAT_ARGS=%POWERSHELL_BAT_ARGS:"=\"%


@@PowerShell -Command Invoke-Expression $('$args=@(^&{$args} %POWERSHELL_BAT_ARGS%);'+[String]::Join(';',$((Get-Content '%~f0') -notmatch '^^@@'))) & goto :EOF

Set-ExecutionPolicy Bypass -Scope Process -Force
$bySubject = $ARGS[0]
$dest =  If ($ARGS[1]) {$ARGS[1]} Else {"C:\temp"}
$checkfile = $ARGS[2]
If ($checkfile){
    If ((Test-Path $checkfile)) {
        EXIT;
    } 
}
$type = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert
$stores = @("Root", "CA")
foreach($store in $stores){
	if ($bySubject) {
		$certs = $(get-childitem -path cert:\LocalMachine\$store | Where-Object { $_.Subject -match $bySubject } )
	}else{
		$certs = get-childitem -path cert:\LocalMachine\$store
	}
	foreach($cert in $certs){

    "Exporting cert with subject $($cert.Subject) to $dest"
	$DestCertName=$cert.Subject.ToString().Replace("CN=","");
    If ($DestCertName -match ',') {
    	$DestCertName = $DestCertName.Substring(0, $DestCertName.IndexOf(","))
    }
    $DestCertName = $DestCertName.replace('=','_')
    $destpath = Join-Path $dest "$($DestCertName).der"
    "Writing $destpath"
    [System.IO.File]::WriteAllBytes($destpath, $cert.export($type) ) 
	}
}	