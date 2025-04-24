# Requires -RunAsAdministrator
# Ce script télécharge le dépôt POST-OS.git et copie le fichier settings.json
# dans le répertoire de configuration de Terminal Windows de l'utilisateur.
# Cela écrasera le fichier settings.json existant.
# Nécessite des droits d'administrateur pour gérer les répertoires temporaires et potentiellement la destination.

Write-Host "=================================================="
Write-Host " Début du script de configuration de settings.json de Terminal Windows"
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
        Write-Host "Processus de relance démarré."
        Write-Host "L'instance actuelle va se terminer."
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

# >>> Chemin VERS le fichier settings.json *à l'intérieur* du DÉPÔT TÉLÉCHARGÉ <<<
# Si settings.json est à la racine du dépôt, mettez "".
# Si settings.json est dans un dossier "TerminalConfig/", mettez "TerminalConfig/".
$settingsSourceRepoFolder = "" # <<-- CONFIRMÉ : settings.json est à la racine, donc VIDE

# Nom du fichier settings.json dans le dépôt
$settingsFileName = "settings.json"

# Chemin de destination LOCAL pour settings.json de Terminal Windows
# C'est le chemin standard pour la version Store, adapté pour l'utilisateur actuel.
$terminalConfigDir = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$settingsDestinationPath = Join-Path $terminalConfigDir $settingsFileName

# --- Chemins temporaires ---
$tempDir = Join-Path $env:TEMP "WT_Settings_Download_Temp_$([System.Guid]::NewGuid().ToString("N"))"
$zipFileName = "$githubRepoBranch.zip"
$zipFilePath = Join-Path $tempDir $zipFileName
$extractPathTemp = Join-Path $tempDir "ExtractedRepo"

Write-Host "--- Démarrage du processus de configuration de settings.json ---"
Write-Host "Source Dépôt : $githubRepoUrlBase (branche : $githubRepoBranch)"
Write-Host "Chemin source de settings.json dans Dépôt : '$settingsSourceRepoFolder\$settingsFileName'" # Affiche ""\settings.json" si à la racine
Write-Host "Destination settings.json : $settingsDestinationPath"
Write-Host "Répertoire temporaire : $tempDir"
Write-Host ""

# --- Préparation des répertoires temporaires ---
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

# --- Vérification et création du répertoire de destination (Terminal Windows) ---
# Le répertoire de destination ($terminalConfigDir) devrait exister si Terminal Windows est installé via le Store.
Write-Host "Vérification du répertoire de destination de Terminal Windows : $terminalConfigDir"
try {
    if (-not (Test-Path -Path $terminalConfigDir -PathType Container)) {
         Write-Error "Le répertoire de configuration de Terminal Windows n'a pas été trouvé : $terminalConfigDir"
         Write-Error "Assurez-vous que Terminal Windows est installé via le Microsoft Store à l'emplacement standard."
         Read-Host "Appuyez sur Entrée pour quitter."
         Exit 1
    } else {
         Write-Host "Répertoire de configuration de Terminal Windows trouvé."
    }
}
catch {
    Write-Error "Échec de la vérification du répertoire de destination de Terminal Windows : $($_.Exception.Message)"
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""


# --- Téléchargement de l'archive ZIP du dépôt POST-OS ---
Write-Host "--- Lancement du téléchargement de l'archive ZIP ---"
Write-Host "Téléchargement en cours depuis : https://github.com/$githubRepoUrlBase/archive/refs/heads/$githubRepoBranch.zip"
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
         Write-Error "Impossible de localiser le fichier settings.json source sans le dossier racine du dépôt."
         Read-Host "Appuyez sur Entrée pour quitter."
         Exit 1
    }
    $sourceRepoRootPath = $repoRootFolder.FullName
    Write-Host "Dossier racine du dépôt identifié : $sourceRepoRootPath"

    # Construit le chemin VERS le fichier settings.json *à l'intérieur* du dossier racine du dépôt téléchargé
    # On utilise Join-Path pour gérer correctement le cas où $settingsSourceRepoFolder est vide.
    $settingsSourcePathInRepo = Join-Path $sourceRepoRootPath $settingsSourceRepoFolder $settingsFileName
    # Si $settingsSourceRepoFolder était vide, Join-Path pourrait donner un résultat incorrect si $settingsFileName
    # est aussi un chemin. Utilisons une approche plus robuste si $settingsSourceRepoFolder est vide.
    if ($settingsSourceRepoFolder -eq "") {
        $settingsSourcePathInRepo = Join-Path $sourceRepoRootPath $settingsFileName
    } else {
         $settingsSourcePathInRepo = Join-Path $sourceRepoRootPath $settingsSourceRepoFolder $settingsFileName
    }

    Write-Host "Chemin source attendu pour settings.json dans le dépôt téléchargé : $settingsSourcePathInRepo"

    # Vérifie que le fichier settings.json source existe dans le dépôt téléchargé
    if (-not (Test-Path -Path $settingsSourcePathInRepo -PathType Leaf)) {
         Write-Error "Le fichier settings.json source n'a PAS été trouvé dans le dépôt téléchargé au chemin spécifié."
         Write-Error "Chemin recherché : $settingsSourcePathInRepo"
         Write-Error "Veuillez vérifier la variable '$settingsSourceRepoFolder' dans le script et l'arborescence de votre dépôt POST-OS.git."
         Read-Host "Appuyez sur Entrée pour quitter."
         Exit 1
    }
    Write-Host "Fichier settings.json source trouvé dans le dépôt téléchargé."

}
catch {
    Write-Error "Échec de l'extraction de l'archive ou de l'identification du fichier source :"
    Write-Error "Erreur : $($_.Exception.Message)"
     Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Copie de settings.json vers la destination finale ---
Write-Host "--- Copie de settings.json vers : $settingsDestinationPath ---"
Write-Host "Ceci va ÉCRASER le fichier settings.json existant dans Terminal Windows."
Write-Host "Fermez Terminal Windows avant de continuer."

try {
    # Copie le fichier settings.json source vers la destination finale, en écrasant.
    # Assurez-vous que Terminal Windows est fermé !
    Copy-Item -Path $settingsSourcePathInRepo -Destination $settingsDestinationPath -Force -ErrorAction Stop

    Write-Host "Fichier settings.json copié avec succès vers : $settingsDestinationPath"
    Write-Host "Votre configuration Terminal Windows (thèmes, profils, etc.) devrait maintenant correspondre à celle de votre dépôt."

}
catch {
    Write-Error "Échec de la copie de settings.json vers la destination finale :"
    Write-Error "Source : $settingsSourcePathInRepo --> Destination : $settingsDestinationPath"
    Write-Error "Erreur : $($_.Exception.Message)"
     Write-Host "Vérifiez que vous avez les permissions d'écriture pour : $settingsDestinationPath"
     Write-Host "(Fermez Terminal Windows avant d'exécuter ce script)."
     Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Nettoyage ---
Write-Host "--- Nettoyage ---"
Write-Host "Suppression du répertoire temporaire complet : $tempDir"
try {
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Nettoyage terminé si possible. Si le dossier persiste, supprimez-le manuellement."
}
catch {
    Write-Warning "Impossible de nettoyer le répertoire temporaire : $($_.Exception.Message)"
    Write-Warning "Veuillez supprimer manuellement le dossier : $tempDir"
}
Write-Host ""

Write-Host "=================================================="
Write-Host " Script de configuration de settings.json terminé !"
Write-Host "=================================================="
Write-Host "Votre fichier settings.json de Terminal Windows a été remplacé par celui de votre dépôt."
Write-Host "Rouvrez Terminal Windows pour voir les changements."
Write-Host ""