# Requires -RunAsAdministrator
# Ce script nécessite des droits d'administrateur pour installer Windows Terminal.

Set-ExecutionPolicy Unrestricted

Write-Host "=================================================="
Write-Host " Début du script d'installation de Windows Terminal"
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
    # Utilisons .Path ici, parfois plus direct que .Definition
    $scriptPath = $MyInvocation.MyCommand.Path 
    Write-Host "Chemin du script pour la relance : $scriptPath" # Diagnostic : affiche le chemin utilisé
    
    # Construit la liste d'arguments pour le nouveau processus PowerShell
    # Utilise -f pour un formatage de chaîne robuste avec le chemin
    $arguments = "-File ""{0}""" -f $scriptPath

    Write-Host "Arguments pour la relance : $arguments" # Diagnostic : affiche les arguments passés
    
    try {
        # Relance le script actuel avec des droits d'administrateur
        $process = Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList $arguments -PassThru
        Write-Host "Processus de relance démarré (PID : $($process.Id))." # Diagnostic

        # Quitte l'instance actuelle du script (qui n'a pas les droits admin)
        Write-Host "L'instance actuelle (non-admin) va maintenant se terminer." # Diagnostic
        Start-Sleep -Seconds 1 # Petit délai optionnel pour s'assurer que le nouveau processus démarre
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
# Recherchez le lien de téléchargement le plus récent sur la page GitHub officielle de Windows Terminal :
# https://github.com/microsoft/terminal/releases
# Cherchez le fichier avec l'extension .msixbundle
# Copiez l'URL du téléchargement et mettez à jour la variable ci-dessous.
# Exemple pour la version 1.19.10573.0 (à remplacer par la version la plus récente !)
$windowsTerminalBundleUrl = "https://github.com/microsoft/terminal/releases/download/v1.19.10573.0/Microsoft.WindowsTerminal_1.19.10573.0_8wekyb3d8bbwe.msixbundle" # <<-- METTRE À JOUR CE LIEN !

$downloadPath = Join-Path $env:TEMP "WT_Install_Download"
$wtBundleFileName = Split-Path $windowsTerminalBundleUrl -Leaf
$wtBundleFilePath = Join-Path $downloadPath $wtBundleFileName

Write-Host "--- Préparation du téléchargement ---"
Write-Host "Cible du téléchargement : $wtBundleFileName"
Write-Host "Répertoire temporaire : $downloadPath"
Write-Host ""

# --- Création du répertoire de téléchargement ---
Write-Host "Création du répertoire temporaire..."
try {
    # Utilise -ErrorAction Stop pour que les erreurs soient capturées par le catch
    New-Item -ItemType Directory -Path $downloadPath -Force -ErrorAction Stop | Out-Null
    Write-Host "Répertoire créé ou déjà existant."
}
catch {
    Write-Error "Échec de la création du répertoire temporaire : $($_.Exception.Message)"
    Write-Host "Impossible de procéder sans un répertoire de téléchargement."
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1 # Quitte si la création du répertoire échoue
}
Write-Host ""

# --- Téléchargement de Windows Terminal ---
Write-Host "--- Lancement du téléchargement ---"
Write-Host "Téléchargement en cours depuis :"
Write-Host $windowsTerminalBundleUrl
Write-Host "Ceci peut prendre quelques instants..."

try {
    # Utilise -ErrorAction Stop pour que les erreurs soient capturées par le catch
    Invoke-WebRequest -Uri $windowsTerminalBundleUrl -OutFile $wtBundleFilePath -UseBasicParsing -ErrorAction Stop
    Write-Host "Téléchargement terminé avec succès !"
}
catch {
    Write-Error "Échec du téléchargement de Windows Terminal :"
    Write-Error "URL : $windowsTerminalBundleUrl"
    Write-Error "Erreur : $($_.Exception.Message)"
    Write-Host "Vérifiez l'URL et votre connexion internet. Assurez-vous que le fichier peut être écrit dans le répertoire temporaire."
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1 # Quitte si le téléchargement échoue
}
Write-Host ""

# --- Installation de Windows Terminal ---
Write-Host "--- Lancement de l'installation ---"
Write-Host "Installation de Windows Terminal à partir du fichier :"
Write-Host $wtBundleFilePath
Write-Host "Ceci peut prendre quelques instants..."

# L'installation MSIX nécessite la fonctionnalité AppX.
# Sur certaines versions très allégées de reviOS, cela pourrait échouer si cette fonctionnalité a été supprimée.
try {
    # Utilise -ErrorAction Stop pour que les erreurs soient capturées par le catch
    # Ajoutez -Verbose si vous voulez voir plus de détails de l'installation AppX
    Add-AppxPackage -Path $wtBundleFilePath -ErrorAction Stop # -Verbose
    Write-Host "Installation de Windows Terminal terminée avec succès !"
    Write-Host "Vous devriez trouver 'Terminal' dans le menu Démarrer."
}
catch {
    Write-Error "Échec de l'installation de Windows Terminal."
    Write-Error "Cause possible : L'infrastructure AppX est peut-être désactivée ou retirée sur cette version de reviOS."
    Write-Error "Message d'erreur détaillé : $($_.Exception.Message)"
    Write-Host "Vous pourriez devoir rechercher une méthode d'installation alternative pour cette version de Windows."
    Write-Host "Le fichier de téléchargement ($wtBundleFilePath) sera conservé pour inspection."
    Read-Host "Appuyez sur Entrée pour quitter."
    # On ne nettoie pas le fichier de téléchargement ici pour permettre l'inspection
    Exit 1 # Quitte si l'installation échoue
}
Write-Host ""

# --- Nettoyage (Optionnel) ---
Write-Host "--- Nettoyage ---"
Write-Host "Suppression du fichier de téléchargement temporaire : $wtBundleFilePath"
try {
    # On utilise -ErrorAction SilentlyContinue car le fichier pourrait ne pas exister si le téléchargement a échoué plus tôt
    Remove-Item -Path $wtBundleFilePath -Force -ErrorAction SilentlyContinue
    Write-Host "Nettoyage terminé."
}
catch {
    Write-Warning "Impossible de nettoyer le fichier de téléchargement : $($_.Exception.Message)"
}
Write-Host ""

Write-Host "=================================================="
Write-Host " Script d'installation de Windows Terminal terminé !"
Write-Host "=================================================="