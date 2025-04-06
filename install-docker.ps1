. "$PSScriptRoot\utils.ps1"

Write-Step "Téléchargement de Docker Desktop"
$dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
$dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"

Write-Host "⬇️ Téléchargement de Docker Desktop via BITS..." -ForegroundColor Cyan
Start-BitsTransfer -Source $dockerUrl -Destination $dockerInstaller

Write-Step "Installation silencieuse de Docker Desktop"
Start-Process -FilePath $dockerInstaller -Verb RunAs

$scriptFullPath = $MyInvocation.MyCommand.Path
$ScriptPath = $scriptFullPath.Replace(".ps1", "2.ps1")
if (-not (Test-Path $ScriptPath)) {
    Write-Error "❌ Le fichier $ScriptPath n'existe pas."
    return
}

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable
$TaskName = "DockerDesktopSetup"

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force

Write-Host "✅ Tâche '$TaskName' enregistrée pour exécution unique au prochain démarrage." -ForegroundColor Green
