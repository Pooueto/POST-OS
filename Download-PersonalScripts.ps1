# Requires -RunAsAdministrator
# Ce script nécessite des droits d'administrateur pour créer des dossiers et écrire des fichiers dans les répertoires utilisateurs si nécessaire.

Write-Host "=================================================="
Write-Host " Début du script de téléchargement des scripts personnels GitHub"
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
# URL de base du dépôt GitHub
$githubRepoUrlBase = "https://github.com/Pooueto/Powershell"
# Nom de la branche principale (généralement main ou master)
# Vérifiez sur GitHub si votre branche principale s'appelle différemment
$githubRepoBranch = "main" # <<-- VERIFIEZ ET MODIFIEZ SI VOTRE BRANCHE PRINCIPALE N'EST PAS 'main'

# URL de l'archive ZIP du dépôt pour la branche principale
$githubZipUrl = "$githubRepoUrlBase/archive/refs/heads/$githubRepoBranch.zip"

# Chemin local où les scripts doivent être téléchargés et extraits
# Correspond au chemin dans vos alias : C:\Users\VotreNom\Documents\PowerShell\Scripts
$destinationPath = Join-Path $env:USERPROFILE "Documents\PowerShell\Scripts" # <-- MODIFIEZ SI VOUS RANGEZ VOS SCRIPTS AILLEURS

# Chemins temporaires
$tempDir = Join-Path $env:TEMP "GitHub_Download_Temp"
$zipFilePath = Join-Path $tempDir "repo.zip"

Write-Host "--- Téléchargement des scripts GitHub ---"
Write-Host "Dépôt GitHub : $githubRepoUrlBase (branche : $githubRepoBranch)"
Write-Host "URL ZIP : $githubZipUrl"
Write-Host "Répertoire de destination local : $destinationPath"
Write-Host "Répertoire temporaire : $tempDir"
Write-Host ""


# --- Préparation des répertoires ---
Write-Host "Création du répertoire temporaire : $tempDir"
try {
    New-Item -ItemType Directory -Path $tempDir -Force -ErrorAction Stop | Out-Null # <--- Vérifiez cette ligne
    Write-Host "Répertoire temporaire créé ou déjà existant."
}
catch {
    Write-Error "Échec de la création du répertoire temporaire : $($_.Exception.Message)"
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

Write-Host "Création du répertoire de destination : $destinationPath"
try {
    New-Item -ItemType Directory -Path $destinationPath -Force -ErrorAction Stop | Out-Null # <--- Vérifiez cette ligne
    Write-Host "Répertoire de destination créé ou déjà existant."
}
catch {
    Write-Error "Échec de la création du répertoire de destination : $($_.Exception.Message)"
    Write-Host "Assurez-vous d'avoir les permissions d'écriture dans votre dossier Documents."
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Téléchargement de l'archive ZIP ---
Write-Host "--- Lancement du téléchargement de l'archive ZIP ---"
Write-Host "Téléchargement en cours depuis : $githubZipUrl"
Write-Host "Ceci peut prendre quelques instants..."

try {
    Invoke-WebRequest -Uri $githubZipUrl -OutFile $zipFilePath -UseBasicParsing -ErrorAction Stop
    Write-Host "Téléchargement terminé avec succès !"
    Write-Host "Fichier ZIP téléchargé : $zipFilePath"
}
catch {
    Write-Error "Échec du téléchargement de l'archive GitHub :"
    Write-Error "URL : $githubZipUrl"
    Write-Error "Erreur : $($_.Exception.Message)"
    Write-Host "Vérifiez l'URL du dépôt et de la branche, ainsi que votre connexion internet."
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Extraction de l'archive ---
Write-Host "--- Lancement de l'extraction de l'archive ---"
Write-Host "Extraction du contenu de : $zipFilePath"
Write-Host "Vers un dossier temporaire..."

# Les archives ZIP de GitHub ont un dossier racine (ex: Powershell-main)
# On extrait dans un dossier temporaire pour ensuite copier le contenu.
$extractPathTemp = Join-Path $tempDir "ExtractedRepo"
try {
    # Crée le dossier temporaire pour l'extraction
    New-Item -ItemType Directory -Path $extractPathTemp -Force -ErrorAction Stop | Out-Null # <--- Vérifiez cette ligne
    Write-Host "Répertoire d'extraction temporaire créé : $extractPathTemp"

    # Extrait l'archive
    Expand-Archive -Path $zipFilePath -DestinationPath $extractPathTemp -Force -ErrorAction Stop
    Write-Host "Extraction terminée avec succès."

    # Trouve le dossier racine créé par GitHub dans l'archive (ex: Powershell-main)
    # Il devrait être le seul dossier direct après extraction
    $repoRootFolder = Get-ChildItem -Path $extractPathTemp -Directory -ErrorAction Stop
    if ($repoRootFolder -eq $null) {
        Write-Error "Impossible de trouver le dossier racine extrait du dépôt. La structure de l'archive est peut-être inattendue."
         Read-Host "Appuyez sur Entrée pour quitter."
        Exit 1
    }
    Write-Host "Dossier racine trouvé dans l'archive : $($repoRootFolder.Name)"

    # Copie le CONTENU de ce dossier racine vers le répertoire de destination final
    Write-Host "Copie du contenu du dépôt vers : $destinationPath"
    # On copie le contenu (*.*) et les sous-dossiers (-Recurse) en écrasant (-Force)
    Copy-Item -Path (Join-Path $repoRootFolder.FullName "*") -Destination $destinationPath -Recurse -Force -ErrorAction Stop
    Write-Host "Contenu copié avec succès vers le répertoire de destination."

}
catch {
    Write-Error "Échec de l'extraction de l'archive ou de la copie des fichiers :"
    Write-Error "Erreur : $($_.Exception.Message)"
    Write-Host "Vérifiez que le fichier ZIP a été correctement téléchargé et qu'il contient bien le contenu du dépôt."
     Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1 # Quitte si l'extraction ou la copie échoue
}
Write-Host ""


# --- Nettoyage ---
Write-Host "--- Nettoyage ---"
Write-Host "Suppression du répertoire temporaire de téléchargement et d'extraction : $tempDir"
try {
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Nettoyage terminé."
}
catch {
    Write-Warning "Impossible de nettoyer le répertoire temporaire : $($_.Exception.Message)"
}
Write-Host ""

Write-Host "=================================================="
Write-Host " Script de téléchargement des scripts personnels terminé !"
Write-Host "=================================================="
Write-Host "Vos scripts personnels devraient maintenant se trouver dans le dossier :"
Write-Host $destinationPath
Write-Host "Le script de configuration du profil PowerShell (Configure-PowerShellProfile.ps1)"
Write-Host "utilisera ces scripts via les alias définis."
Write-Host ""