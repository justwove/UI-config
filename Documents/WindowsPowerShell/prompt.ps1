# Compteur de ligne global
$global:lineCount = 0

# Fonction prompt modifiée avec compteur de lignes
function prompt { 
    $time = Get-Date -Format "HH:mm:ss"
    $username = $env:UserName
    $location = Get-Location

    # Incrémenter le compteur de ligne
    $global:lineCount++

    # Affichage du prompt personnalisé
    Write-Host ("[$global:lineCount]") -NoNewLine -ForegroundColor Yellow
    Write-Host (" $time") -NoNewLine -ForegroundColor Cyan
    Write-Host (" $username") -NoNewLine -ForegroundColor Green
    Write-Host (" $location") -NoNewLine -ForegroundColor Magenta
    Write-Host (" >") -NoNewLine -ForegroundColor Red

    return " "
}
