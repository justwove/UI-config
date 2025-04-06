function Write-Step {
    param ([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Add-StartupTask {
    param (
        [Parameter(Mandatory)][string]$TaskName,
        [Parameter(Mandatory)][string]$ExecutablePath,
        [string]$Arguments = "",
        [switch]$RunAsAdmin
    )

    if (-not (Test-Path $ExecutablePath)) {
        Write-Error "❌ Le fichier '$ExecutablePath' est introuvable."
        return
    }

    $action = New-ScheduledTaskAction -Execute $ExecutablePath -Argument $Arguments
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $principal = if ($RunAsAdmin) {
        New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
    } else {
        New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
    }
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
    Write-Host "✅ Tâche planifiée '$TaskName' créée." -ForegroundColor Green
}
