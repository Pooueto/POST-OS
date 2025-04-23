# Requires -RunAsAdministrator
# Ce script télécharge le dépôt POST-OS.git et copie les fichiers
# de configuration Fastfetch (config.jsonc et logos) vers C:\ProgramData\fastfetch.
# Nécessite des droits d'administrateur pour accéder à C:\ProgramData.

Write-Host "=================================================="
Write-Host " Début du script de configuration des fichiers Fastfetch"
Write-Host "(Téléchargement depuis POST-OS.git vers C:\ProgramData\fastfetch)"
Write-Host "=================================================="
Write-Host ""

# --- Vérification et élévation des droits d'administrateur ---
Write-Host "Vérification des droits d'administrateur actuels..."
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Droits d'administrateur non détectés dans cette session. Tentative d'élévation..."
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = "-File ""{0}""" -f $scriptPath
    try {
        Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList $arguments -PassThru | Out-Null
        Write-Host "Processus de relance démarré. L'instance actuelle va se terminer."
        Start-Sleep -Seconds 1
        Exit
    }
    catch {
        Write-Error "Échec critique lors de la tentative de relance en tant qu'administrateur : $($_.Exception.Message)"
        Read-Host "Appuyez sur Entrée pour quitter."
        Exit 1
    }
}
Write-Host "Droits d'administrateur vérifiés/obtenus. Le script continue."
Write-Host ""

# --- Configuration du Dépôt et des Chemins ---

# URL de base du dépôt POST-OS.git (sans le .git final)
$githubRepoUrlBase = "https://github.com/Pooueto/POST-OS"

# Nom de la branche principale
$githubRepoBranch = "main" # <<-- VÉRIFIEZ ET MODIFIEZ SI NÉCESSAIRE

# >> Configuration source (dans le dépôt téléchargé) <<
# Nom du dossier à la racine du dépôt qui contient config.jsonc et les logos Fastfetch
$fastfetchSourceRepoFolder = "fastfetch" # <<-- CONFIRMÉ : C'EST LE DOSSIER 'fastfetch' À LA RACINE DU DÉPÔT

# >> Configuration destination (sur le PC local) <<
# Chemin local où TOUS les fichiers Fastfetch (config et logos) doivent être copiés
$destinationPath = "C:\ProgramData\fastfetch" # <<-- CONFIRMÉ : C'EST LE DOSSIER C:\ProgramData\fastfetch

# --- Chemins temporaires ---
$tempDir = Join-Path $env:TEMP "Fastfetch_Config_Download_Temp_$([System.Guid]::NewGuid().ToString("N"))" # Ajout d'un GUID pour éviter les conflits
$zipFileName = "$githubRepoBranch.zip"
$zipFilePath = Join-Path $tempDir $zipFileName
$extractPathTemp = Join-Path $tempDir "ExtractedRepo"

Write-Host "--- Démarrage du processus Fastfetch Config ---"
Write-Host "Source Dépôt : $githubRepoUrlBase (branche : $githubRepoBranch)"
Write-Host "Dossier source Dépôt pour Fastfetch : '$fastfetchSourceRepoFolder'"
Write-Host "Destination de TOUS les fichiers Fastfetch : $destinationPath"
Write-Host "Répertoire temporaire : $tempDir"
Write-Host ""

# --- Préparation des répertoires ---
Write-Host "Création du répertoire temporaire : $tempDir"
try {
    New-Item -ItemType Directory -Path $tempDir -Force -ErrorAction Stop | Out-Null
    Write-Host "Répertoire temporaire créé ou déjà existant."
}
catch {
    Write-Error "Échec de la création du répertoire temporaire : $($_.Exception.Message)"
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

Write-Host "Vérification et création du répertoire de destination : $destinationPath (nécessite Admin)"
try {
    # S'assure que le chemin existe et est un conteneur (dossier)
    if (-not (Test-Path -Path $destinationPath -PathType Container)) {
         Write-Host "Le répertoire de destination n'existe pas. Création..."
         New-Item -ItemType Directory -Path $destinationPath -Force -ErrorAction Stop | Out-Null
         Write-Host "Répertoire de destination créé."
    } else {
         Write-Host "Répertoire de destination déjà existant."
    }
}
catch {
    Write-Error "Échec de la vérification/création du répertoire de destination : $($_.Exception.Message)"
    Write-Host "Assurez-vous d'avoir les permissions d'écriture pour créer ou accéder à : $destinationPath"
    Write-Host "(Chemin sous C:\ProgramData\fastfetch nécessite des droits Administrateur)."
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Téléchargement de l'archive ZIP du dépôt POST-OS ---
Write-Host "--- Lancement du téléchargement de l'archive ZIP ---"
Write-Host "Téléchargement en cours depuis : https://github.com/$githubRepoUrlBase/archive/refs/heads/$githubRepoBranch.zip" # Affichage complet de l'URL générée
Write-Host "Ceci peut prendre quelques instants..."

try {
    $fullZipUrl = "https://github.com/$($githubRepoUrlBase -replace 'https://github.com/', '')/archive/refs/heads/$githubRepoBranch.zip"
    Invoke-WebRequest -Uri $fullZipUrl -OutFile $zipFilePath -UseBasicParsing -ErrorAction Stop
    Write-Host "Téléchargement terminé avec succès !"
    Write-Host "Fichier ZIP téléchargé : $zipFilePath"
}
catch {
    Write-Error "Échec du téléchargement de l'archive GitHub POST-OS :"
    Write-Error "URL : $fullZipUrl"
    Write-Error "Erreur : $($_.Exception.Message)"
    Write-Host "Vérifiez l'URL du dépôt et de la branche, ainsi que votre connexion internet."
    Write-Host "Code de statut Web : $($_.Exception.Response.StatusCode) - Message : $($_.Exception.Response.StatusDescription)"
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Extraction de l'archive ---
Write-Host "--- Lancement de l'extraction de l'archive ---"
Write-Host "Extraction du contenu de : $zipFilePath"
Write-Host "Vers un dossier temporaire : $extractPathTemp"

try {
    Expand-Archive -Path $zipFilePath -DestinationPath $extractPathTemp -Force -ErrorAction Stop
    Write-Host "Extraction terminée avec succès dans : $extractPathTemp"

    # Trouve le dossier racine créé par GitHub dans l'archive extraite (ex: POST-OS-main)
    $extractedItems = Get-ChildItem -Path $extractPathTemp -ErrorAction Stop
    $repoRootFolder = $extractedItems | Where-Object { $_.PsIsContainer }

    if ($repoRootFolder -eq $null -or $repoRootFolder.Count -ne 1) {
         Write-Error "Impossible de trouver exactement un sous-dossier racine dans l'archive extraite."
         Write-Host "Contenu extrait : $($extractedItems.Name -join ', ')"
         Write-Error "Impossible de localiser le dossier source Fastfetch sans le dossier racine du dépôt."
         Read-Host "Appuyez sur Entrée pour quitter."
         Exit 1
    }
    $sourceRepoRootPath = $repoRootFolder.FullName
    Write-Host "Dossier racine du dépôt identifié : $sourceRepoRootPath"

    # Construit le chemin VERS le dossier Fastfetch *à l'intérieur* du dossier racine du dépôt téléchargé
    $fastfetchSourcePathInRepo = Join-Path $sourceRepoRootPath $fastfetchSourceRepoFolder
    Write-Host "Chemin source attendu pour le dossier Fastfetch dans le dépôt téléchargé : $fastfetchSourcePathInRepo"

    # Vérifie que le dossier source Fastfetch existe dans le dépôt téléchargé
    if (-not (Test-Path -Path $fastfetchSourcePathInRepo -PathType Container)) {
         Write-Error "Le dossier source spécifié pour les fichiers Fastfetch n'a pas été trouvé dans le dépôt téléchargé."
         Write-Error "Chemin vérifié : $fastfetchSourcePathInRepo"
         Write-Error "Veuillez vérifier la variable '$fastfetchSourceRepoFolder' dans le script et l'arborescence de votre dépôt POST-OS.git."
         Read-Host "Appuyez sur Entrée pour quitter."
         Exit 1
    }
    Write-Host "Dossier source Fastfetch trouvé dans le dépôt téléchargé."

}
catch {
    Write-Error "Échec de l'extraction de l'archive ou de l'identification du dossier source :"
    Write-Error "Erreur : $($_.Exception.Message)"
     Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Copie de TOUS les fichiers du dossier Fastfetch source vers la destination unique ---
Write-Host "--- Copie de TOUS les fichiers du dossier Fastfetch source vers : $destinationPath ---"

try {
    # On copie le CONTENU du dossier source Fastfetch (*.*) et les sous-dossiers (-Recurse si nécessaire)
    # en écrasant (-Force). Ici, on assume que FastfetchConfig/ contient directement les fichiers et non des sous-dossiers profonds.
    Copy-Item -Path (Join-Path $fastfetchSourcePathInRepo "*") -Destination $destinationPath -Force -ErrorAction Stop # Removed -Recurse assuming no subfolders needed in destination

    Write-Host "Contenu du dossier Fastfetch copié avec succès vers : $destinationPath"

}
catch {
    Write-Error "Échec de la copie des fichiers Fastfetch vers la destination finale :"
    Write-Error "Source : $fastfetchSourcePathInRepo\* --> Destination : $destinationPath"
    Write-Error "Erreur : $($_.Exception.Message)"
     Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Nettoyage ---
Write-Host "--- Nettoyage ---"
Write-Host "Suppression du répertoire temporaire complet : $tempDir"
try {
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Nettoyage terminé."
}
catch {
    Write-Warning "Impossible de nettoyer le répertoire temporaire : $($_.Exception.Message)"
}
Write-Host ""

Write-Host "=================================================="
Write-Host " Script de configuration des fichiers Fastfetch terminé !"
Write-Host "=================================================="
Write-Host "TOUS les fichiers du dossier Fastfetch du dépôt ont été copiés vers :"
Write-Host $destinationPath
Write-Host ""
Write-Host ">>> RAPPEL IMPORTANT POUR LE PROFIL POWERSHELL : <<<"
Write-Host "Votre script de profil (Configure-PowerShellProfile.ps1) référence Fastfetch."
Write-Host "Vous devez OBLIGATOIREMENT mettre à jour les chemins dans ce script de profil"
Write-Host "pour qu'ils pointent vers le nouvel emplacement : $destinationPath"
Write-Host "Cela inclut le chemin de config.jsonc et les chemins des fichiers de logos."
Write-Host "Exemple : '$env:USERPROFILE\Documents\config.jsonc' devient '$destinationPath\config.jsonc'"
Write-Host "Exemple : '$env:USERPROFILE\.config\fastfetch\logo.txt' devient '$destinationPath\logo.txt'"
Write-Host ""