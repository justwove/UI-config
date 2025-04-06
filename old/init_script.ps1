# ============================================
# Script d'installation environnement Dev & Pentest - Windows
# Auteur : Sebou
# Description : Automatisation via Scoop + config
# ============================================

# Fonction utilitaire pour afficher les étapes
function Write-Step($message) {
    Write-Host "`n==> $message" -ForegroundColor Cyan
}

function Add-StartupTask {
    param (
        [Parameter(Mandatory)]
        [string]$TaskName,

        [Parameter(Mandatory)]
        [string]$ExecutablePath,

        [string]$Arguments = "",

        [switch]$RunAsAdmin
    )

    if (-not (Test-Path $ExecutablePath)) {
        Write-Error "❌ Le fichier '$ExecutablePath' est introuvable."
        return
    }

    Write-Host "⏳ Création de la tâche planifiée : $TaskName" -ForegroundColor Cyan

    $action = New-ScheduledTaskAction -Execute $ExecutablePath -Argument $Arguments
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $principal = if ($RunAsAdmin) {
        New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
    } else {
        New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
    }
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    try {
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
        Write-Host "✅ Tâche '$TaskName' ajoutée avec succès." -ForegroundColor Green
    } catch {
        Write-Error "❌ Erreur lors de la création de la tâche '$TaskName': $_"
    }
}

function Enable-WSL {
    Write-Host "🔧 Activation des fonctionnalités Windows nécessaires..." -ForegroundColor Cyan
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -ErrorAction Stop
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -ErrorAction Stop
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -ErrorAction Stop
}

function Install-WSL2-Kernel {
    Write-Host "⬇️ Téléchargement du kernel WSL2..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -OutFile "$env:TEMP\wsl2.msi"
    Start-Process msiexec.exe -ArgumentList "/i `"$env:TEMP\wsl2.msi`" /quiet /norestart" -Wait
}

function Install-Debian-WSL {
    Write-Host "📦 Installation de Debian via WSL..." -ForegroundColor Cyan
    wsl --install -d Debian
}

function Install-DockerDesktop {
    Write-Host "🐳 Téléchargement de Docker Desktop..." -ForegroundColor Cyan
    $dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
    Invoke-WebRequest -Uri "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" -OutFile $dockerInstaller

    Write-Host "⚙️ Installation de Docker Desktop..." -ForegroundColor Cyan
    Start-Process -FilePath $dockerInstaller -ArgumentList "--quiet" -Wait
}

function Configure-DockerWSL {
    Write-Host "🔧 Configuration de Docker Desktop pour WSL2..." -ForegroundColor Cyan

    $settingsPath = "$env:APPDATA\Docker\settings.json"
    if (-Not (Test-Path $settingsPath)) {
        Write-Warning "⚠️ Docker Desktop ne semble pas lancé une première fois. Lancer manuellement une fois pour générer le fichier settings.json."
        return
    }

    # Chargement et modification du fichier JSON
    $settings = Get-Content $settingsPath | ConvertFrom-Json
    $settings.wslEngineEnabled = $true
    $settings.autoStart = $true
    $settings.integratedWslDistros = @("Debian")
    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath

    Write-Host "✅ Docker Desktop configuré pour WSL2 avec intégration Debian." -ForegroundColor Green
}

function Check-WSLg {
    Write-Host "🔎 Vérification de WSLg..." -ForegroundColor Cyan
    $hasWSLg = wsl --system | Select-String "wslg"

    if ($hasWSLg) {
        Write-Host "✅ WSLg est présent sur ce système." -ForegroundColor Green
    } else {
        Write-Warning "⚠️ WSLg ne semble pas installé. Il nécessite Windows 11 et WSLg intégré."
    }
}

# Sécurité : S'assurer qu'on est en mode RemoteSigned
Write-Step "Configuration de la politique d'exécution PowerShell"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Installer Scoop (si non déjà installé)
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Step "Installation de Scoop"
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
} else {
    Write-Step "Scoop est déjà installé"
}

# Ajouter les buckets nécessaires
Write-Step "Ajout des buckets Scoop"
scoop bucket add extras
scoop install git
scoop bucket add nerd-fonts

# Installer les outils de base
$packages = @(
    "python",
    "vscode",
    "komorebi",
    "extras/yasb",
    "pipx"
)

foreach ($pkg in $packages) {
    Write-Step "Installation de $pkg"
    scoop install $pkg
}

# Enregistrement de Python dans le registre (pour l'intégration avec d'autres outils)
$pythonReg = "$env:USERPROFILE\scoop\apps\python\current\install-pep-514.reg"
if (Test-Path $pythonReg) {
    Write-Step "Définition du Python dans le registre Windows (PEP 514)"
    # On utilise Start-Process pour exécuter reg.exe avec les droits d'administrateur
    Start-Process reg -ArgumentList "import `"$pythonReg`"" -Wait -Verb RunAs
}

# Ajout de VSCode au registre (associations, context menu, etc.)
$vscodePath = "$env:USERPROFILE\scoop\apps\vscode\current"
$regFiles = @(
    "install-context.reg",
    "install-associations.reg",
    "install-github-integration.reg"
)

foreach ($file in $regFiles) {
    $regPath = Join-Path $vscodePath $file
    if (Test-Path $regPath) {
        Write-Step "Import du fichier registre $file pour VSCode"
        Start-Process reg -ArgumentList "import `"$regPath`"" -Wait -Verb RunAs
    }
}

# Activer les chemins longs dans Windows
Write-Step "Activation du support des chemins longs"
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -Force


# Ajouter une tâche planifiée pour le démarrage de Komorebi (si installé)
Write-Step "Ajout de Komorebi au démarrage Windows"
$komorebicExe = "$env:USERPROFILE\scoop\apps\komorebi\current\komorebic.exe"
Add-StartupTask -TaskName "Komorebi Startup" -ExecutablePath $komorebicExe -Arguments "start --whkd" # -RunAsAdmin


# Prochaines étapes (TODO)
Write-Step "À faire manuellement ou à intégrer : installer 'Everything', config réseau, outils pentest..."

Write-Host "`nInstallation terminée." -ForegroundColor Green
