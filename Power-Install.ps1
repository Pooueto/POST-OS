# Requires -RunAsAdministrator
# Ce script nécessite des droits d'administrateur pour installer PowerShell 7.x.

Write-Host "=================================================="
Write-Host " Début du script d'installation de PowerShell 7.x"
Write-Host "=================================================="
Write-Host ""

# --- Vérification et élévation des droits d'administrateur ---
Write-Host "Vérification des droits d'administrateur actuels..."
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Droits d'administrateur non détectés dans cette session."
    Write-Host "Tentative d'élévation (affichage de l'invite UAC)..."

    # Récupère le chemin complet du script actuel
    $scriptPath = $MyInvocation.MyCommand.Path
    Write-Host "Chemin du script pour la relance : $scriptPath" # Diagnostic

    # Construit la liste d'arguments pour le nouveau processus PowerShell
    $arguments = "-File ""{0}""" -f $scriptPath

    Write-Host "Arguments pour la relance : $arguments" # Diagnostic

    try {
        # Relance le script actuel avec des droits d'administrateur
        $process = Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList $arguments -PassThru
        Write-Host "Processus de relance démarré (PID : $($process.Id))." # Diagnostic

        # Quitte l'instance actuelle du script (qui n'a pas les droits admin)
        Write-Host "L'instance actuelle (non-admin) va maintenant se terminer." # Diagnostic
        Start-Sleep -Seconds 1 # Petit délai optionnel
        Exit
    }
    catch {
        Write-Error "Échec critique lors de la tentative de relance en tant qu'administrateur."
        Write-Error "Erreur : $($_.Exception.Message)"
        Write-Host "Veuillez vérifier que le chemin du script ($scriptPath) est valide et accessible."
        Read-Host "Appuyez sur Entrée pour quitter."
        Exit 1 # Quitte si la relance échoue
    }
}

# Si le script arrive ici, c'est qu'il est déjà admin OU qu'il vient d'être relancé avec succès
Write-Host "Droits d'administrateur vérifiés/obtenus. Le script continue son exécution..."
Write-Host "" # Ligne vide pour la lisibilité après le bloc d'élévation

# --- Configuration ---
# Recherchez le lien de téléchargement pour la DERNIÈRE version stable LTS (Long Term Servicing)
# sur la page GitHub des releases de PowerShell :
# https://github.com/PowerShell/PowerShell/releases
# Cherchez le fichier .msi pour Windows x64.
# Exemple pour la version 7.4.2 (à remplacer par la version stable la plus récente si besoin !)
$powerShellMsiUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.5.0/PowerShell-7.5.0-win-x64.msi" # <<-- METTRE À JOUR CE LIEN !

$downloadPath = Join-Path $env:TEMP "PS7_Install_Download"
$psMsiFileName = Split-Path $powerShellMsiUrl -Leaf
$psMsiFilePath = Join-Path $downloadPath $psMsiFileName

Write-Host "--- Préparation du téléchargement ---"
Write-Host "Cible du téléchargement : $psMsiFileName"
Write-Host "Répertoire temporaire : $downloadPath"
Write-Host ""

# --- Création du répertoire de téléchargement ---
Write-Host "Création du répertoire temporaire..."
try {
    New-Item -ItemType Directory -Path $downloadPath -Force -ErrorAction Stop | Out-Null
    Write-Host "Répertoire créé ou déjà existant."
}
catch {
    Write-Error "Échec de la création du répertoire temporaire : $($_.Exception.Message)"
    Write-Host "Impossible de procéder sans un répertoire de téléchargement."
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Téléchargement de PowerShell 7.x MSI ---
Write-Host "--- Lancement du téléchargement ---"
Write-Host "Téléchargement en cours depuis :"
Write-Host $powerShellMsiUrl
Write-Host "Ceci peut prendre quelques instants..."

try {
    Invoke-WebRequest -Uri $powerShellMsiUrl -OutFile $psMsiFilePath -UseBasicParsing -ErrorAction Stop
    Write-Host "Téléchargement terminé avec succès !"
    Write-Host "Fichier téléchargé : $psMsiFilePath"
}
catch {
    Write-Error "Échec du téléchargement de PowerShell 7.x :"
    Write-Error "URL : $powerShellMsiUrl"
    Write-Error "Erreur : $($_.Exception.Message)"
    Write-Host "Vérifiez l'URL, votre connexion internet et les droits d'écriture dans le répertoire temporaire."
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Installation de PowerShell 7.x ---
Write-Host "--- Lancement de l'installation ---"
Write-Host "Installation de PowerShell 7.x à partir du fichier :"
Write-Host $psMsiFilePath
Write-Host "L'installation est silencieuse (sans fenêtre d'installation). Ceci peut prendre quelques instants..."

try {
    # Utilise msiexec avec les arguments pour installation silencieuse (/qn) et sans redémarrage (/norestart)
    $process = Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$psMsiFilePath`" /qn /norestart" -Wait -PassThru -ErrorAction Stop

    Write-Host "Installation de msiexec.exe terminée (le programme d'installation a fini de s'exécuter)."
    Write-Host "Code de sortie de l'installation MSI : $($process.ExitCode)"

    if ($process.ExitCode -eq 0) {
        Write-Host "Installation de PowerShell 7.x terminée avec succès."
    } elseif ($process.ExitCode -eq 3010) {
        Write-Host "Installation de PowerShell 7.x terminée avec succès, mais un REDÉMARRAGE est nécessaire pour que l'installation soit complète."
        Write-Host "Veuillez redémarrer votre ordinateur dès que possible."
    } else {
        Write-Error "L'installation de PowerShell 7.x a signalé une erreur imprévue."
        Write-Error "Code de sortie : $($process.ExitCode)"
        Write-Host "Consultez la documentation de msiexec.exe pour l'interprétation des codes de sortie."
        # On ne nettoie pas le fichier MSI ici pour permettre l'inspection
        Read-Host "Appuyez sur Entrée pour quitter."
        Exit 1 # Quitte en cas d'erreur d'installation non gérée (pas 0 ou 3010)
    }
}
catch {
    Write-Error "Échec lors du lancement de l'installation de PowerShell 7.x via msiexec.exe."
    Write-Error "Erreur : $($_.Exception.Message)"
     # On ne nettoie pas le fichier MSI ici
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1 # Quitte si Start-Process échoue
}
Write-Host ""

# --- Nettoyage (Optionnel) ---
Write-Host "--- Nettoyage ---"
Write-Host "Suppression du fichier de téléchargement temporaire : $psMsiFilePath"
try {
    # On utilise -ErrorAction SilentlyContinue car le fichier pourrait ne pas exister si le téléchargement a échoué
    Remove-Item -Path $psMsiFilePath -Force -ErrorAction SilentlyContinue
    Write-Host "Nettoyage terminé."
}
catch {
    Write-Warning "Impossible de nettoyer le fichier de téléchargement : $($_.Exception.Message)"
}
Write-Host ""

Write-Host "=================================================="
Write-Host " Script d'installation de PowerShell 7.x terminé !"
Write-Host "=================================================="
Write-Host "Pour vérifier l'installation, ouvrez une nouvelle instance de Windows Terminal"
Write-Host "et tapez 'pwsh' puis Entrée."