. "$PSScriptRoot\utils.ps1"

& "C:\Program Files\Docker\Docker\Docker Desktop.exe"
Start-Sleep -Seconds 30

Write-Step "Configuration de Docker pour WSL2 + Debian"
$settingsPath = "$env:APPDATA\Docker\settings-store.json"

if (-not (Test-Path $settingsPath)) {
    Write-Warning "⚠️ settings-store.json non trouvé. Docker doit être lancé au moins une fois pour le générer."
    return
}

$settings = Get-Content $settingsPath | ConvertFrom-Json
$settings.wslEngineEnabled = $true
$settings.autoStart = $true
$settings.integratedWslDistros = @("Debian")
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath

Write-Host "✅ Docker Desktop configuré pour WSL2 avec Debian." -ForegroundColor Green

Write-Step "Vérification de WSLg"
$hasWSLg = wsl --system | Select-String "wslg"
if ($hasWSLg) {
    Write-Host "✅ WSLg est présent." -ForegroundColor Green
} else {
    Write-Warning "⚠️ WSLg non détecté. Requiert Windows 11."
}

Write-Step "Installation de exegol"
$pipxExe = "$env:USERPROFILE\scoop\shims\pipx.cmd"
if (Test-Path $pipxExe) {
    Write-Step "Installation de exegol"
    & $pipxExe install exegol
    Write-Step "Installation de argcomplete"
    & $pipxExe install argcomplete
    Write-Step "Vérification du PATH de pipx"
    & $pipxExe ensurepath

    $pipxPath = "$env:USERPROFILE\.local\bin"
    $env:PATH += ";$pipxPath"
    $exegolExe = Join-Path $pipxPath "exegol.exe"
    if (Test-Path $exegolExe) {
        & $exegolExe install full
        register-python-argcomplete --no-defaults --shell powershell exegol > $HOME\Documents\WindowsPowerShell\exegol_completion.psm1
        echo "Import-Module '$HOME\Documents\WindowsPowerShell\exegol_completion.psm1'" >> $PROFILE
    } else {
        Write-Warning "⚠️ exegol n'a pas été trouvé dans le répertoire pipx."
    }
} else {
    Write-Warning "⚠️ pipx non trouvé. Veuillez installer pipx."
}
