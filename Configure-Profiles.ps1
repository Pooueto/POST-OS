# Requires -RunAsAdministrator
# Ce script crée ou met à jour le fichier de profil PowerShell utilisateur
# avec la configuration personnalisée (alias, modules, Oh My Posh, Fastfetch).
# Nécessite potentiellement des droits d'administrateur pour créer le répertoire du profil
# si l'utilisateur n'a pas les permissions nécessaires dans son dossier Documents.

Write-Host "=================================================="
Write-Host " Début du script de configuration du profil PowerShell"
Write-Host "=================================================="
Write-Host ""

# --- Vérification et élévation des droits d'administrateur ---
Write-Host "Vérification des droits d'administrateur actuels..."
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Droits d'administrateur non détectés dans cette session."
    Write-Host "Tentative d'élévation (affichage de l'invite UAC)..."

    $scriptPath = $MyInvocation.MyCommand.Path
    Write-Host "Chemin du script pour la relance : $scriptPath" # Diagnostic
    $arguments = "-File ""{0}""" -f $scriptPath
    Write-Host "Arguments pour la relance : $arguments" # Diagnostic

    try {
        Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList $arguments -PassThru | Out-Null
        Write-Host "Processus de relance démarré."
        Write-Host "L'instance actuelle (non-admin) va maintenant se terminer."
        Start-Sleep -Seconds 1
        Exit
    }
    catch {
        Write-Error "Échec critique lors de la tentative de relance en tant qu'administrateur."
        Write-Error "Erreur : $($_.Exception.Message)"
        Write-Host "Veuillez vérifier que le chemin du script ($scriptPath) est valide et accessible."
        Read-Host "Appuyez sur Entrée pour quitter."
        Exit 1
    }
}

Write-Host "Droits d'administrateur vérifiés/obtenus. Le script continue son exécution..."
Write-Host ""

# --- Configuration du chemin du fichier de profil ---

# $PROFILE est une variable automatique qui pointe vers le fichier de profil
# pour l'hôte PowerShell actuel et l'utilisateur courant.
$profilePath = $PROFILE
$profileDir = Split-Path -Path $profilePath -Parent

Write-Host "--- Configuration du fichier de profil ---"
Write-Host "Le fichier de profil ciblé est : $profilePath"
Write-Host "Son répertoire parent est : $profileDir"
Write-Host ""

# --- Créer le répertoire du profil si nécessaire ---
Write-Host "Vérification et création du répertoire du profil : $profileDir"
try {
    # Crée le répertoire du profil si inexistant. -Force permet de ne pas échouer s'il existe.
    New-Item -ItemType Directory -Path $profileDir -Force -ErrorAction Stop | Out-Null
    Write-Host "Répertoire du profil créé ou déjà existant."
}
catch {
    Write-Error "Échec de la création du répertoire du profil : $($_.Exception.Message)"
    Write-Host "Impossible de créer ou d'accéder au répertoire nécessaire pour le profil."
    Write-Host "Veuillez vérifier vos permissions sur ce chemin."
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Contenu du fichier de profil ---
# Ce bloc de texte contient le code qui sera écrit dans votre fichier de profil.
# >>> ADAPTEZ LES CHEMINS UTILISATEUR DANS CE BLOC SI NÉCESSAIRE <<<
# Les chemins vers vos scripts personnels et la configuration Fastfetch doivent être corrects.

$profileContent = @'
# Profil PowerShell utilisateur (Microsoft.PowerShell_profile.ps1) généré par script d'automatisation.
# Ce script s'exécute à chaque démarrage d'une session PowerShell.

# --- Alias personnalisés ---
# Assurez-vous que les chemins vers vos scripts personnels sont corrects.
# Par défaut, ils sont supposés se trouver dans %USERPROFILE%\Documents\PowerShell\Scripts\
Set-Alias c clear # Alias standard pour effacer l'écran
Set-Alias -Name vlc -Value "$env:USERPROFILE\Documents\PowerShell\Scripts\BetterVLC.ps1" # <-- Vérifiez/Adaptez ce chemin
Set-Alias -Name speedtest -Value "$env:USERPROFILE\Documents\PowerShell\Scripts\SpeedtestLauncherTERM.ps1" # <-- Vérifiez/Adaptez ce chemin
Set-Alias -Name yt -Value "$env:USERPROFILE\Documents\PowerShell\Scripts\YTtoDL.ps1" # <-- Vérifiez/Adaptez ce chemin
Set-Alias -Name imgConverter -Value "$env:USERPROFILE\Documents\PowerShell\Scripts\imgConverter.ps1" # <-- Vérifiez/Adaptez ce chemin
Set-Alias -Name videoCompress -Value "$env:USERPROFILE\Documents\PowerShell\Scripts\videoCompress" # <-- Vérifiez/Adaptez ce chemin
Set-Alias -Name ajouterPochetteGUI -Value "$env:USERPROFILE\Documents\PowerShell\Scripts\ajouterPochetteGUI.ps1" # <-- Vérifiez/Adaptez ce chemin
Set-Alias -Name alldebrid -Value "$env:USERPROFILE\Documents\PowerShell\Scripts\BetterAlldebrid.ps1" # <-- Vérifiez/Adaptez ce chemin
Set-Alias -Name q -Value "exit" # Alias pour quitter

# --- Oh My Posh ---
# Nécessite Oh My Posh installé séparément (via choco install oh-my-posh -y).
# Nécessite une police compatible (Nerd Font) installée dans Windows.
# Assurez-vous que le chemin du thème est correct. $env:POSH_THEMES_PATH est généralement défini par l'installation d'Oh My Posh.
# Le fichier de thème "emodipt-extend.omp.json" doit être présent dans ce répertoire de thèmes.
# Si vous utilisez un thème personnalisé stocké ailleurs (ex: dans vos fichiers GitHub), adaptez le chemin.
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\emodipt-extend.omp.json" | Invoke-Expression

# --- Terminal-Icons ---
# Nécessite le module Terminal-Icons installé séparément (Install-Module Terminal-Icons -Scope AllUsers).
# Utilise -ErrorAction SilentlyContinue pour éviter de faire planter le profil si le module n'est pas encore installé.
Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue

# --- Fastfetch (avec sélection aléatoire de logo) ---
# Nécessite fastfetch installé séparément (via choco install fastfetch -y).
# Nécessite les fichiers de configuration (.jsonc) et de logos (.txt).
# >>> IMPORTANT : CES CHEMINS DOIVENT MAINTENANT POINTER VERS C:\ProgramData\fastfetch\ <<<
# car c'est là que le script Download-FastfetchConfig.ps1 les a copiés.

# Chemin de config.jsonc dans C:\ProgramData\fastfetch\
$fastfetchConfigPath = "C:\ProgramData\fastfetch\config.jsonc" # <-- NOUVEAU CHEMIN

# Liste des chemins vers les fichiers de logos dans C:\ProgramData\fastfetch\
# Assurez-vous que les noms de fichiers correspondent à ceux que vous avez dans votre dépôt.
$fastfetchLogosPaths = @(
    "C:\ProgramData\fastfetch\logo.txt", # <-- NOUVEAU CHEMIN
    "C:\ProgramData\fastfetch\logoURSS.txt", # <-- NOUVEAU CHEMIN
    "C:\ProgramData\fastfetch\logoTheFuck.txt", # <-- NOUVEAU CHEMIN
    "C:\ProgramData\fastfetch\logoSalutN.txt" # <-- NOUVEAU CHEMIN
    # Ajoutez d'autres logos si nécessaire
)

# Vérifie si la commande fastfetch existe ET si au moins un fichier de logo spécifié existe avant de tenter de l'exécuter
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    $existingLogos = $fastfetchLogosPaths | Where-Object { Test-Path $_ }
    if ($existingLogos.Count -gt 0) {
         # Choisit aléatoirement un logo parmi ceux qui existent réellement
         $logo = Get-Random -InputObject $existingLogos
        Write-Verbose "Utilisation du logo Fastfetch : $logo"
        # Exécute Fastfetch. Utilise le chemin de config.jsonc défini ci-dessus.
        if (Test-Path $fastfetchConfigPath) {
            fastfetch --logo "$logo" --logo-color-1 black --config "$fastfetchConfigPath"
        } else {
            Write-Warning "Fichier de configuration Fastfetch introuvable : $fastfetchConfigPath. Exécution sans config spécifiée."
             fastfetch --logo "$logo" --logo-color-1 black # Exécute Fastfetch avec logo mais sans config spécifique
        }
    } else {
         Write-Warning "Aucun fichier de logo Fastfetch spécifié n'a été trouvé dans C:\ProgramData\fastfetch\. Fastfetch ne sera pas exécuté avec un logo aléatoire via le profil."
    }
} else {
    # Message si Fastfetch n'est pas installé ou non trouvé dans le PATH
    Write-Warning "La commande 'fastfetch' n'est pas reconnue. Fastfetch ne sera pas exécuté au démarrage via le profil."
}

# --- Chocolatey Profile ---
# Nécessite Chocolatey installé séparément (via Install-Chocolatey.ps1).
# Importe un module spécifique à Chocolatey si présent.
# Utilise -ErrorAction SilentlyContinue pour éviter de faire planter le profil si Chocolatey n'est pas là.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile" -ErrorAction SilentlyContinue
} else {
    Write-Warning "Le module ChocolateyProfile.psm1 est introuvable. Vérifiez que Chocolatey est correctement installé."
}

# --- Fin du contenu du profil ---
'@

# --- Écriture du contenu dans le fichier de profil ---
Write-Host "Écriture du contenu dans le fichier de profil : $profilePath"
try {
    # Utilisez Set-Content pour remplacer le contenu existant ou créer le fichier.
    # Cela va écraser tout contenu précédent dans ce fichier de profil.
    $profileContent | Set-Content -Path $profilePath -Force -Encoding UTF8 -ErrorAction Stop
    Write-Host "Contenu du profil écrit avec succès."
    Write-Host "Le fichier de profil '$profilePath' a été créé ou mis à jour avec votre configuration."
}
catch {
    Write-Error "Échec de l'écriture dans le fichier de profil : $($_.Exception.Message)"
    Write-Host "Vérifiez les permissions sur le répertoire : $profileDir"
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

Write-Host "=================================================="
Write-Host " Script de configuration du profil PowerShell terminé !"
Write-Host "=================================================="
Write-Host "Le nouveau profil prendra effet lors de l'ouverture de la prochaine session PowerShell."
Write-Host "Assurez-vous que TOUS les prérequis (logiciels, modules, scripts personnels, fichiers Fastfetch) sont installés/téléchargés"
Write-Host "ET que les chemins spécifiés DANS ce script de profil ($profilePath)"
Write-Host "correspondent aux emplacements réels de ces fichiers sur votre machine."
Write-Host ""