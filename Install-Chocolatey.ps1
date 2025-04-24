# Requires -RunAsAdministrator
# Ce script nécessite des droits d'administrateur pour installer Chocolatey et potentiellement créer le fichier de profil.

Write-Host "=================================================="
Write-Host " Début du script d'installation de Chocolatey"
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

# --- Vérifier et créer le fichier de profil PowerShell si nécessaire ---
Write-Host "--- Vérification du fichier de profil PowerShell utilisateur ---"
$profilePath = $PROFILE # Variable automatique pour le chemin du profil utilisateur
$profileDir = Split-Path -Path $profilePath -Parent

Write-Host "Chemin du fichier de profil attendu : $profilePath"

if (-not (Test-Path -Path $profilePath -PathType Leaf)) {
    Write-Host "Le fichier de profil n'existe pas. Création..."

    # Créer le répertoire du profil s'il n'existe pas
    Write-Host "Vérification et création du répertoire du profil : $profileDir"
    try {
        New-Item -ItemType Directory -Path $profileDir -Force -ErrorAction Stop | Out-Null
        Write-Host "Répertoire du profil créé ou déjà existant."
    }
    catch {
        Write-Error "Échec de la création du répertoire du profil : $($_.Exception.Message)"
        Write-Host "Certains warnings de Chocolatey pourraient s'afficher si le profil ne peut pas être créé."
        # On ne quitte pas ici, on essaie de continuer l'installation de Choco quand même.
    }

    # Créer le fichier de profil avec un contenu minimal
    Write-Host "Création du fichier de profil vide..."
    try {
        # Créer un fichier avec juste un commentaire
        Set-Content -Path $profilePath -Value "# Fichier de profil PowerShell utilisateur (créé temporairement par script)" -Force -Encoding UTF8 -ErrorAction Stop
        Write-Host "Fichier de profil créé : $profilePath"
    }
    catch {
         Write-Error "Échec de la création du fichier de profil : $($_.Exception.Message)"
         Write-Host "Certains warnings de Chocolatey pourraient s'afficher."
         # On ne quitte pas ici, on essaie de continuer l'installation de Choco quand même.
    }

} else {
    Write-Host "Le fichier de profil existe déjà."
}
Write-Host ""


# --- Vérifier si Chocolatey est déjà installé ---
Write-Host "--- Vérification de l'installation existante de Chocolatey ---"
try {
    $chocoVersion = choco --version -ErrorAction Stop
    Write-Host "Chocolatey est déjà installé (version : $($chocoVersion.Trim()))."
    Write-Host "L'installation n'est pas nécessaire. Le script va se terminer."
    Write-Host ""
    Write-Host "=================================================="
    Write-Host " Script d'installation de Chocolatey terminé (déjà installé)!"
    Write-Host "=================================================="
    Exit 0 # Sortie réussie car déjà installé

}
catch {
    Write-Host "Chocolatey n'a pas été détecté. L'installation va commencer."
}
Write-Host ""

# --- Prérequis : Stratégie d'exécution ---
Write-Host "--- Configuration de la stratégie d'exécution PowerShell ---"
Write-Host "Vérification de la stratégie d'exécution actuelle pour la portée Process..."
$currentExecutionPolicy = Get-ExecutionPolicy -Scope Process
Write-Host "Stratégie actuelle : $currentExecutionPolicy"

Write-Host "Définition de la stratégie sur 'Bypass' pour la portée Process..."
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop
    Write-Host "Stratégie définie sur 'Bypass' pour cette session."
}
catch {
    Write-Error "Échec de la définition de la stratégie d'exécution : $($_.Exception.Message)"
    Write-Host "Impossible de continuer l'installation de Chocolatey."
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""


# --- Installation de Chocolatey ---
Write-Host "--- Lancement de l'installation de Chocolatey ---"
Write-Host "Téléchargement et exécution du script d'installation depuis chocolatey.org..."
Write-Host "Ceci peut prendre quelques instants..."

$installCommand = @"
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
"@

try {
    Invoke-Expression $installCommand
    Write-Host "Installation de Chocolatey initiée. Vérification..."

    Start-Sleep -Seconds 10 # Laisser un peu de temps
    
    try {
         $chocoTest = choco --version -ErrorAction Stop
         Write-Host "Chocolatey (version $($chocoTest.Trim())) semble installé avec succès !"
    }
    catch {
         Write-Warning "Chocolatey a été installé, mais la commande 'choco' n'est pas immédiatement reconnue."
         Write-Warning "Ceci est normal. Vous devrez ouvrir une nouvelle session PowerShell ou une nouvelle fenêtre Terminal"
         Write-Warning "pour que la commande 'choco' soit ajoutée à votre PATH et reconnue."
         Write-Host "Vérifiez l'installation en ouvrant un nouveau Terminal et en tapant 'choco' ou 'choco --version'."
    }

}
catch {
    Write-Error "Échec critique lors de l'exécution du script d'installation de Chocolatey :"
    Write-Error "Erreur : $($_.Exception.Message)"
    Write-Host "L'installation de Chocolatey a échoué."
    Write-Host "Veuillez vérifier votre connexion internet, les paramètres de proxy, et les logiciels de sécurité."
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Rétablir la stratégie d'exécution (Optionnel mais recommandé) ---
Write-Host "--- Rétablissement de la stratégie d'exécution PowerShell ---"
Write-Host "La stratégie d'exécution 'Bypass' n'était définie que pour la portée 'Process' de ce script."
Write-Host "Votre stratégie d'exécution globale n'a pas été modifiée."
Write-Host ""

Write-Host "=================================================="
Write-Host " Script d'installation de Chocolatey terminé !"
Write-Host "=================================================="
Write-Host "Ouvrez une nouvelle session PowerShell ou un nouveau Terminal pour utiliser 'choco'."
Write-Host "N'oubliez pas d'exécuter le script de configuration du profil PowerShell complet plus tard."
Write-Host ""