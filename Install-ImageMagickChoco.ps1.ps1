# Requires -RunAsAdministrator
# Ce script installe ImageMagick (version tool/portable) en utilisant le gestionnaire de paquets Chocolatey.
# Nécessite Chocolatey installé et accessible dans le PATH.
# Nécessite des droits d'administrateur pour exécuter choco install.

Write-Host "=================================================="
Write-Host " Début du script d'installation d'ImageMagick (Chocolatey)"
Write-Host "=================================================="
Write-Host ""

# --- Vérification et élévation des droits d'administrateur ---
Write-Host "Vérification des droits d'administrateur actuels..."
$currentUser = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.BuiltInRole]::Administrator)

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

# --- Vérifier si Chocolatey est installé ---
Write-Host "--- Vérification de l'installation de Chocolatey ---"
try {
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

# --- Vérifier si ImageMagick est déjà installé ---
Write-Host "--- Vérification de l'installation existante d'ImageMagick ---"
$packageName = "imagemagick.tool" # Utilisation du paquet pour la version portable/outil
try {
    $installedPackages = choco list --localonly $packageName -ErrorAction Stop
    if ($installedPackages -like "*$packageName*") {
        Write-Host "$packageName est déjà installé."
        try {
            Get-Command magick.exe -ErrorAction Stop | Out-Null
            Write-Host "La commande 'magick' est reconnue."
        } catch {
             Write-Warning "Le paquet $packageName est installé, mais la commande 'magick' n'est pas immédiatement reconnue dans cette session."
             Write-Warning "Ceci est normal. Vous devrez ouvrir une nouvelle session PowerShell/Terminal pour que les commandes soient reconnues via le PATH."
        }
        Write-Host "L'installation n'est pas nécessaire. Le script va se terminer."
        Write-Host ""
        Write-Host "=================================================="
        Write-Host " Script d'installation d'ImageMagick terminé (déjà installé)!"
        Write-Host "=================================================="
        Exit 0
    } else {
        Write-Host "$packageName n'est pas encore installé."
    }
}
catch {
    Write-Warning "Impossible de vérifier l'installation de $packageName via 'choco list'."
    Write-Warning "Une tentative d'installation va être effectuée."
}
Write-Host ""

# --- Installation d'ImageMagick via Chocolatey ---
Write-Host "--- Lancement de l'installation de $packageName via Chocolatey ---"
Write-Host "Exécution de la commande : choco install $packageName -y"
Write-Host "Ceci peut prendre quelques instants..."

try {
    choco install $packageName -y -ErrorAction Stop

    Write-Host "Installation de $packageName initiée."
    Write-Host "Vérification de la reconnaissance de la commande 'magick'..."

    Start-Sleep -Seconds 5

     try {
        Get-Command magick.exe -ErrorAction Stop | Out-Null
        Write-Host "La commande 'magick' est maintenant reconnue dans cette session (ou le sera après un redémarrage de session)."
    } catch {
         Write-Warning "Le paquet $packageName a été installé, mais la commande 'magick' n'est pas immédiatement reconnue dans cette session."
         Write-Warning "Ceci est normal. Vous devrez ouvrir une nouvelle session PowerShell ou une nouvelle fenêtre Terminal"
         Write-Warning "pour que la commande 'magick' soit ajoutée à votre PATH et reconnue."
         Write-Host "Vérifiez l'installation en ouvrant un nouveau Terminal et en tapant 'magick --version'."
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
Write-Host " Script d'installation d'ImageMagick terminé !"
Write-Host "=================================================="
Write-Host "$packageName a été installé avec succès."
Write-Host "Ouvrez une nouvelle session PowerShell/Terminal pour utiliser 'magick'."
Write-Host ""