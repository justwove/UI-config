. "$PSScriptRoot\utils.ps1"

Write-Step "Lancement du setup complet..."

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
scoop install git
scoop bucket add extras
scoop bucket add nerd-fonts

# Installer les outils de base
$packages = @(
    "python",
    "vscode",
    "komorebi",
    "extras/yasb",
    "pipx",
    "everything",
    "whkd",
    "nerd-fonts/JetBrainsMono-NF-Mono",
    "nerd-fonts/JetBrainsMono-NF-Propo",
    "nerd-fonts/JetBrainsMono-NF"
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

$everythingPath = "$env:USERPROFILE\scoop\apps\everything\current"
$regFiles = "install-context.reg"
$regPath = Join-Path $everythingPath $file
if (Test-Path $regPath) {
    Write-Step "Import du fichier registre $file pour Everything"
    Start-Process reg -ArgumentList "import `"$regPath`"" -Wait -Verb RunAs
}

# Activer les chemins longs dans Windows
Write-Step "Activation du support des chemins longs"
$PSCommand = "Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -Force" 
Start-Process powershell "$PSCommand" -Verb RunAs


# Ajouter une tâche planifiée pour le démarrage de Komorebi (si installé)
Write-Step "Ajout de Komorebi au démarrage Windows"
$komorebicExe = "$env:USERPROFILE\komorebi.ps1"
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutPath = Join-Path $startupFolder "Komorebic.lnk"
$wshShell = New-Object -ComObject WScript.Shell
$shortcut = $wshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $komorebicExe -Parent
$shortcut.WorkingDirectory = Split-Path $komorebicExe -Parent
$shortcut.Save()

Write-Step "Installation de .NET Desktop Runtime 6.0.36"
$installerPath = "$env:TEMP\windowsdesktop-runtime-6.0.36-win-x64.exe" 
$dotnetUrl = "https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/6.0.36/windowsdesktop-runtime-6.0.36-win-x64.exe"
Start-BitsTransfer -Source $dotnetUrl -Destination $installerPath
Start-Process -FilePath $installerPath -ArgumentList "/install", "/quiet", "/norestart" -Wait -Verb RunAs

Write-Step "Installation de WinLaunch"
$installerPath = "$env:TEMP\WinLaunch.exe"
$winlaunchUri = "https://netix.dl.sourceforge.net/project/winlaunch/WinLaunchInstaller.exe?viasf=1"
Start-BitsTransfer -Source $winlaunchUri -Destination $installerPath
# Start-Process -FilePath $installerPath -Wait -Verb RunAs
Write-Step "Va executer l'installation de Winlaunch, il est téléchargé ici : $installerPath"


$ScriptFullPath = $MyInvocation.MyCommand.Path
$ScriptPath = $ScriptFullPath.Replace("install.ps1", "user")
Copy-Item -Path "$ScriptPath\*" -Destination "$env:USERPROFILE" -Recurse -Force
echo ". $env:USERPROFILE\Documents\WindowsPowerShell\prompt.ps1" >> $PROFILE
echo ". $env:USERPROFILE\Documents\WindowsPowerShell\auto-complete.ps1" >> $PROFILE

Write-Step "Pour isntaller Sudo, je te propose de suivre : https://learn.microsoft.com/fr-fr/windows/sudo/"

# . "$PSScriptRoot\install-core.ps1"
# . "$PSScriptRoot\install-docker.ps1"


