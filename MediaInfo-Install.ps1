# Requires -RunAsAdministrator
# Ce script télécharge l'archive ZIP de MediaInfo CLI, extrait mediainfo.exe
# et le copie dans un répertoire système dédié.
# Nécessite des droits d'administrateur pour écrire dans les répertoires système.

Write-Host "=================================================="
Write-Host " Début du script de téléchargement et placement de MediaInfo CLI"
Write-Host "=================================================="
Write-Host ""

# --- Vérification et élévation des droits d'administrateur ---
Write-Host "Vérification des droits d'administrateur actuels..."
$currentUser = New-Object Security.Principal.WindowsPrincipal([System.Security.Principal.BuiltInRole]::Administrator)

if (-not $currentUser.IsInRole([System.Security.Principal.BuiltInRole]::Administrator)) {
    Write-Host "Droits d'administrateur non détectés dans cette session. Tentative d'élévation..."
    $scriptPath = $MyInvocation.MyCommand.Path
    try {
        Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File ""$scriptPath""" -PassThru | Out-Null
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

# --- Configuration ---

# URL de téléchargement de l'archive ZIP de MediaInfo CLI
$mediaInfoZipUrl = "https://mediaarea.net/download/binary/mediainfo/25.03/MediaInfo_CLI_25.03_Windows_x64.zip"

# Répertoire de destination pour l'exécutable MediaInfo CLI
# Nous le plaçons dans Program Files pour faciliter l'ajout au PATH système
$destinationDir = Join-Path $env:ProgramFiles "MediaInfoCLI"

# Nom de l'exécutable principal à extraire
$executableName = "mediainfo.exe"

# Chemins temporaires
$tempDir = Join-Path $env:TEMP "MediaInfo_Download_Temp_$([System.Guid]::NewGuid().ToString("N"))"
$zipFileName = Split-Path $mediaInfoZipUrl -Leaf
$zipFilePath = Join-Path $tempDir $zipFileName
$extractPathTemp = Join-Path $tempDir "ExtractedMediaInfoCLI"


Write-Host "--- Téléchargement et placement de MediaInfo CLI ---"
Write-Host "URL de téléchargement : $mediaInfoZipUrl"
Write-Host "Répertoire de destination : $destinationDir"
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

Write-Host "Vérification et création du répertoire de destination : $destinationDir (nécessite Admin)"
try {
    if (-not (Test-Path -Path $destinationDir -PathType Container)) {
         Write-Host "Le répertoire de destination n'existe pas. Création..."
         New-Item -ItemType Directory -Path $destinationDir -Force -ErrorAction Stop | Out-Null
         Write-Host "Répertoire de destination créé."
    } else {
         Write-Host "Répertoire de destination déjà existant."
    }
}
catch {
    Write-Error "Échec de la vérification/création du répertoire de destination : $($_.Exception.Message)"
    Write-Host "Assurez-vous d'avoir les permissions d'écriture pour créer ou accéder à : $destinationDir"
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Téléchargement de l'archive ZIP de MediaInfo CLI ---
Write-Host "--- Lancement du téléchargement de l'archive ZIP ---"
Write-Host "Téléchargement en cours depuis : $mediaInfoZipUrl"
Write-Host "Ceci peut prendre quelques instants..."

try {
    Invoke-WebRequest -Uri $mediaInfoZipUrl -OutFile $zipFilePath -UseBasicParsing -ErrorAction Stop
    Write-Host "Téléchargement terminé avec succès !"
    Write-Host "Fichier ZIP téléchargé : $zipFilePath"
}
catch {
    Write-Error "Échec du téléchargement de l'archive MediaInfo CLI :"
    Write-Error "URL : $mediaInfoZipUrl"
    Write-Error "Erreur : $($_.Exception.Message)"
    Write-Host "Vérifiez l'URL de téléchargement et votre connexion internet."
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""


# --- Extraction de l'archive ---
Write-Host "--- Lancement de l'extraction de l'archive ---"
Write-Host "Extraction du contenu de : $zipFilePath"
Write-Host "Vers un dossier temporaire : $extractPathTemp"

try {
     New-Item -ItemType Directory -Path $extractPathTemp -Force -ErrorAction Stop | Out-Null
     Write-Host "Répertoire d'extraction temporaire créé : $extractPathTemp"

    Expand-Archive -Path $zipFilePath -DestinationPath $extractPathTemp -Force -ErrorAction Stop
    Write-Host "Extraction terminée avec succès dans : $extractPathTemp"

}
catch {
    Write-Error "Échec de l'extraction de l'archive MediaInfo CLI :"
    Write-Error "Erreur : $($_.Exception.Message)"
     Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Trouver et copier mediainfo.exe ---
Write-Host "--- Recherche et copie de $executableName ---"
Write-Host "Recherche de '$executableName' dans le répertoire extrait..."

try {
    # Recherche récursive de l'exécutable dans le dossier d'extraction
    $executableFile = Get-ChildItem -Path $extractPathTemp -Recurse -Include $executableName -ErrorAction Stop | Select-Object -First 1

    if (-not $executableFile) {
        Write-Error "L'exécutable '$executableName' n'a pas été trouvé dans l'archive extraite."
        Write-Host "La structure de l'archive n'est peut-être pas celle attendue."
         Read-Host "Appuyez sur Entrée pour quitter."
        Exit 1
    }
    Write-Host "Exécutable '$executableName' trouvé : $($executableFile.FullName)"

    # Copie l'exécutable vers le répertoire de destination
    $destinationFile = Join-Path $destinationDir $executableName
    Write-Host "Copie de '$executableName' vers '$destinationDir'..."

    # Utilise -Force pour écraser si le fichier existe déjà
    Copy-Item -Path $executableFile.FullName -Destination $destinationFile -Force -ErrorAction Stop
    Write-Host "'$executableName' copié avec succès vers : $destinationFile"

}
catch {
    Write-Error "Échec lors de la recherche ou de la copie de l'exécutable '$executableName' :"
    Write-Error "Erreur : $($_.Exception.Message)"
    Write-Host "Assurez-vous que le répertoire de destination '$destinationDir' est accessible en écriture (nécessite Admin)."
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
Write-Host " Script de téléchargement et placement de MediaInfo CLI terminé !"
Write-Host "=================================================="
Write-Host "L'exécutable 'mediainfo.exe' a été copié vers :"
Write-Host $destinationDir
Write-Host ""
Write-Host ">>> ÉTAPE SUIVANTE IMPORTANTE : <<<"
Write-Host "Pour que la commande 'mediainfo' soit reconnue par vos scripts et dans n'importe quelle session PowerShell/Terminal,"
Write-Host "vous devez ajouter le répertoire '$destinationDir' à la variable d'environnement PATH système."
Write-Host "Vous pouvez utiliser le script 'Add-ToSystemPath_Interactive.ps1' pour cela, en lui fournissant ce chemin."
Write-Host ""