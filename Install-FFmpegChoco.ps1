# Requires -RunAsAdministrator
# Ce script installe FFmpeg en utilisant le gestionnaire de paquets Chocolatey.
# Nécessite Chocolatey installé et accessible dans le PATH.
# Nécessite des droits d'administrateur pour exécuter choco install.

Write-Host "=================================================="
Write-Host " Début du script d'installation de FFmpeg (Chocolatey)"
Write-Host "=================================================="
Write-Host ""

# --- Vérification et élévation des droits d'administrateur ---
Write-Host "Vérification des droits d'administrateur actuels..."
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.BuiltInRole]::Administrator)

if (-not $currentUser.IsInRole([Security.Principal.BuiltInRole]::Administrator)) {
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

# --- Vérifier si Chocolatey est installé ---
Write-Host "--- Vérification de l'installation de Chocolatey ---"
try {
    # Tente d'obtenir le chemin de la commande choco. Throws error if not found.
    $chocoPath = Get-Command choco.exe -ErrorAction Stop | Select-Object -ExpandProperty Source
    Write-Host "Chocolatey trouvé à : $chocoPath"
}
catch {
    Write-Error "Chocolatey n'est pas installé ou n'est pas accessible dans le PATH."
    Write-Error "Veuillez installer Chocolatey en exécutant le script 'Install-Chocolatey.ps1' en premier."
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Vérifier si FFmpeg est déjà installé ---
Write-Host "--- Vérification de l'installation existante de FFmpeg ---"
$packageName = "ffmpeg-full"
try {
    # Utilise choco list pour vérifier si le paquet est déjà installé localement
    $installedPackages = choco list --localonly $packageName -ErrorAction Stop
    if ($installedPackages -like "*$packageName*") {
        Write-Host "$packageName est déjà installé."
        # Vérifie aussi si la commande ffmpeg est reconnue
        try {
            Get-Command ffmpeg.exe -ErrorAction Stop | Out-Null
            Write-Host "La commande 'ffmpeg' est reconnue."
        } catch {
             Write-Warning "Le paquet $packageName est installé, mais la commande 'ffmpeg' n'est pas immédiatement reconnue dans cette session."
             Write-Warning "Ceci est normal. Vous devrez ouvrir une nouvelle session PowerShell/Terminal pour que les commandes soient reconnues via le PATH."
        }
        Write-Host "L'installation n'est pas nécessaire. Le script va se terminer."
        Write-Host ""
        Write-Host "=================================================="
        Write-Host " Script d'installation de FFmpeg terminé (déjà installé)!"
        Write-Host "=================================================="
        Exit 0 # Sortie réussie car déjà installé
    } else {
        Write-Host "$packageName n'est pas encore installé."
    }
}
catch {
    # Si choco list échoue (peut arriver si Chocolatey est mal installé ou si le paquet n'existe pas pour une raison bizarre)
    Write-Warning "Impossible de vérifier l'installation de $packageName via 'choco list'."
    Write-Warning "Une tentative d'installation va être effectuée."
    # On ne quitte pas, on continue pour tenter l'installation au cas où
}
Write-Host ""

# --- Installation de FFmpeg via Chocolatey ---
Write-Host "--- Lancement de l'installation de $packageName via Chocolatey ---"
Write-Host "Exécution de la commande : choco install $packageName -y"
Write-Host "Ceci peut prendre quelques instants..."

try {
    # Exécute la commande d'installation. Le -y accepte automatiquement les invites.
    # Utilise -ErrorAction Stop pour capturer les erreurs d'installation.
    choco install $packageName -y -ErrorAction Stop

    Write-Host "Installation de $packageName initiée."
    Write-Host "Vérification de la reconnaissance de la commande 'ffmpeg'..."

    Start-Sleep -Seconds 5 # Laisser un peu de temps pour que le PATH se mette à jour dans certains environnements

     try {
        Get-Command ffmpeg.exe -ErrorAction Stop | Out-Null
        Write-Host "La commande 'ffmpeg' est maintenant reconnue dans cette session (ou le sera après un redémarrage de session)."
    } catch {
         Write-Warning "Le paquet $packageName a été installé, mais la commande 'ffmpeg' n'est pas immédiatement reconnue dans cette session."
         Write-Warning "Ceci est normal. Vous devrez ouvrir une nouvelle session PowerShell ou une nouvelle fenêtre Terminal"
         Write-Warning "pour que la commande 'ffmpeg' soit ajoutée à votre PATH et reconnue."
         Write-Host "Vérifiez l'installation en ouvrant un nouveau Terminal et en tapant 'ffmpeg -version'."
    }


}
catch {
    Write-Error "Échec lors de l'installation de $packageName via Chocolatey :"
    Write-Error "Erreur : $($_.Exception.Message)"
    Write-Host "L'installation a échoué. Vérifiez votre connexion internet et les messages d'erreur ci-dessus."
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

Write-Host "=================================================="
Write-Host " Script d'installation de FFmpeg terminé !"
Write-Host "=================================================="
Write-Host "$packageName a été installé avec succès."
Write-Host "Ouvrez une nouvelle session PowerShell/Terminal pour utiliser 'ffmpeg'."
Write-Host ""