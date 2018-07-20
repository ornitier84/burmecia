@@:: This prolog allows a PowerShell script to be embedded in a .CMD file.


@@:: Any non-PowerShell content must be preceeded by "@@"


@@setlocal


@@set POWERSHELL_BAT_ARGS=%*


@@if defined POWERSHELL_BAT_ARGS set POWERSHELL_BAT_ARGS=%POWERSHELL_BAT_ARGS:"=\"%


@@PowerShell -Command Invoke-Expression $('$args=@(^&{$args} %POWERSHELL_BAT_ARGS%);'+[String]::Join(';',$((Get-Content '%~f0') -notmatch '^^@@'))) & pause & goto :EOF

Set-ExecutionPolicy Bypass -Scope Process -Force
"Installing chocolatey windows package manager ..."
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
"Installing python"
choco install python -y
"Installing git"
choco install git.install -y
"Installing packer"
choco install packer -y
"Installing virtualbox"
choco install virtualbox -y
"Installing vagrant"
choco install vagrant -y
"Installing required vagrant plugins"
if ( (test-path c:\HashiCorp\Vagrant\embedded\mingw64\bin\ruby.exe) ) {
	&c:\HashiCorp\Vagrant\embedded\mingw64\bin\ruby.exe c:\HashiCorp\Vagrant\embedded\mingw64\bin\rake init
} else {
   "Couldn't find the vagrant embedded ruby executable"
   "You'll have to install the required vagrant plugins manually"
}
"Done. You can close this window now."
