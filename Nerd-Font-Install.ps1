# Requires -RunAsAdministrator
# Ce script télécharge une Nerd Font et guide l'utilisateur pour l'installation manuelle.
# Nécessite des droits d'administrateur pour créer le répertoire temporaire si nécessaire.

Write-Host "=================================================="
Write-Host " Début du script de téléchargement de Nerd Font"
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

# --- Configuration ---

# URL de téléchargement de l'archive ZIP de la police
$fontZipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip"

# Répertoire de destination pour le téléchargement temporaire
$tempDir = Join-Path $env:TEMP "NerdFont_Download_Temp_$([System.Guid]::NewGuid().ToString("N"))"
$zipFileName = Split-Path $fontZipUrl -Leaf
$zipFilePath = Join-Path $tempDir $zipFileName

Write-Host "--- Téléchargement de la police ---"
Write-Host "URL de téléchargement : $fontZipUrl"
Write-Host "Répertoire de téléchargement temporaire : $tempDir"
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


# --- Téléchargement de l'archive ZIP de la police ---
Write-Host "--- Lancement du téléchargement de l'archive ZIP ---"
Write-Host "Téléchargement en cours depuis : $fontZipUrl"
Write-Host "Ceci peut prendre quelques instants..."

try {
    Invoke-WebRequest -Uri $fontZipUrl -OutFile $zipFilePath -UseBasicParsing -ErrorAction Stop
    Write-Host "Téléchargement terminé avec succès !"
    Write-Host "Fichier ZIP téléchargé : $zipFilePath"
}
catch {
    Write-Error "Échec du téléchargement de l'archive de police :"
    Write-Error "URL : $fontZipUrl"
    Write-Error "Erreur : $($_.Exception.Message)"
    Write-Host "Vérifiez l'URL de téléchargement et votre connexion internet."
    Read-Host "Appuyez sur Entrée pour quitter."
    # On ne nettoie pas le dossier temporaire en cas d'échec du téléchargement,
    # pour permettre à l'utilisateur de vérifier s'il y a un fichier partiel.
    Exit 1
}
Write-Host ""


# --- Ouvrir le répertoire et guider l'utilisateur ---
Write-Host "--- Installation manuelle requise ---"
Write-Host "Le fichier de la police a été téléchargé avec succès dans le répertoire temporaire."
Write-Host "Emplacement du fichier ZIP : $zipFilePath"
Write-Host ""
Write-Host "Ouverture du répertoire de téléchargement dans l'Explorateur de fichiers..."

try {
    # Ouvre le répertoire où le fichier ZIP a été téléchargé
    Invoke-Item -Path $tempDir -ErrorAction Stop
    Write-Host "Répertoire temporaire ouvert."
}
catch {
    Write-Warning "Impossible d'ouvrir automatiquement le répertoire de téléchargement."
    Write-Host "Veuillez naviguer manuellement vers : $tempDir"
}
Write-Host ""

Write-Host ">>> ÉTAPES POUR L'INSTALLATION MANUELLE DE LA POLICE : <<<"
Write-Host "1. Dans l'Explorateur de fichiers qui vient de s'ouvrir, DOUBLE-CLIQUEZ sur le fichier ZIP téléchargé : $($zipFileName)"
Write-Host "2. Ouvrez le dossier qui contient les fichiers de police (.ttf ou .otf). Souvent, ils sont dans un dossier 'ttf' à l'intérieur du ZIP."
Write-Host "3. Sélectionnez TOUS les fichiers .ttf et .otf que vous souhaitez installer."
Write-Host "4. FAITES UN CLIC DROIT sur les fichiers sélectionnés."
Write-Host "5. Sélectionnez 'Installer pour tous les utilisateurs'."
Write-Host ""
Write-Host "Une fois l'installation terminée, la police devrait être disponible dans Windows."
Write-Host "Vous devrez peut-être redémarrer les applications (comme Terminal Windows) ou votre PC pour qu'elle apparaisse."
Write-Host ""

Read-Host "Appuyez sur Entrée APRÈS avoir effectué l'installation manuelle pour fermer ce script."

# --- Nettoyage ---
Write-Host "--- Nettoyage ---"
Write-Host "Tentative de suppression du répertoire temporaire : $tempDir"
try {
    # Donne un petit délai pour s'assurer que l'Explorateur a fini d'accéder au dossier si Invoke-Item a été rapide
    Start-Sleep -Seconds 2
    # Utilise -ErrorAction SilentlyContinue car le dossier temp pourrait être verrouillé si l'utilisateur l'utilise toujours
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Nettoyage terminé si possible. Si le dossier persiste, supprimez-le manuellement."
}
catch {
    Write-Warning "Impossible de nettoyer le répertoire temporaire : $($_.Exception.Message)"
    Write-Warning "Veuillez supprimer manuellement le dossier : $tempDir"
}
Write-Host ""


Write-Host "=================================================="
Write-Host " Script de téléchargement de Nerd Font terminé !"
Write-Host "=================================================="
Write-Host "N'oubliez pas de sélectionner JetBrainsMono Nerd Font dans les paramètres de votre profil Terminal Windows."
Write-Host ""