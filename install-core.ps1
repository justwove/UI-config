. "$PSScriptRoot\utils.ps1"

Write-Step "Activation de WSL & Hyper-V"
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart

Write-Step "Installation du kernel WSL2"
Invoke-WebRequest -Uri "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -OutFile "$env:TEMP\wsl2.msi"
Start-Process msiexec.exe -ArgumentList "/i `"$env:TEMP\wsl2.msi`" /quiet /norestart" -Wait

Write-Step "Installation de Debian WSL"
wsl --install --no-distribution
wsl --install -d Debian
