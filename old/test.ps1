# scoop install 
cd C:\
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
# Sccop app Path: $env:USERPROFILE\scoop\shims\

#Scoop Package install
scoop install git
scoop bucket add nerd-fonts
scoop bucket add extras   

# Python
scoop install python
C:\Users\Sebou\scoop\apps\python\current\install-pep-514.reg

# Tiling Window Manager
scoop install extras/yasb
scoop install komorebi

# vscode 
scoop install vscode
reg import "C:\Users\Sebou\scoop\apps\vscode\current\install-context.reg"
reg import "C:\Users\Sebou\scoop\apps\vscode\current\install-associations.reg"
reg import "C:\Users\Sebou\scoop\apps\vscode\current\install-github-integration.reg"

# Admin
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1

# Todo 
# Install Everything 