# Requires -RunAsAdministrator
# Ce script installe une liste de logiciels en utilisant le gestionnaire de paquets Chocolatey.
# Nécessite Chocolatey installé et accessible dans le PATH.
# Nécessite des droits d'administrateur pour exécuter choco install.

Write-Host "=================================================="
Write-Host " Début du script d'installation de la liste de logiciels (Chocolatey)"
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

# --- Liste des paquets à installer ---
# Définissez ici la liste de tous les noms de paquets Chocolatey que vous souhaitez installer.
# Les noms de paquets correspondent aux logiciels de votre liste.
$packagesToInstall = @(
    "cheatengine",
    "deezer",
    "discord",
    "epicgameslauncher",
    "filezilla",
    "git",
    "goggalaxy",
    "temurin", # Pour OpenJDK (Java)
    "jdownloader",
    "notepadplusplus",
    "neovim",
    "python", # Dernière version stable
    "steam",
    "translucenttb",
    "vlc", # Le lecteur multimédia complet, pas seulement le CLI
    "vscode",
    "winrar",
    "windirstat"
)

Write-Host "--- Lancement de l'installation des logiciels listés ---"
Write-Host "$($packagesToInstall.Count) paquets au total à vérifier/installer."
Write-Host ""

# --- Boucle d'installation ---
$installedCount = 0
$skippedCount = 0
$failedPackages = @()

foreach ($package in $packagesToInstall) {
    Write-Host "--------------------------------------------------"
    Write-Host "Traitement du paquet : $package"
    
    # Vérifier si le paquet est déjà installé
    try {
        $installedPackages = choco list --localonly $package -ErrorAction Stop
        if ($installedPackages -like "*$package*") {
            Write-Host "$package est déjà installé. Ignoré."
            $skippedCount++
        } else {
            Write-Host "$package n'est pas installé. Lancement de l'installation..."
            
            # Installer le paquet
            try {
                # choco install avec -y pour accepter automatiquement les invites
                # -ErrorAction Stop pour que les erreurs d'installation soient capturées
                choco install $package -y -ErrorAction Stop

                Write-Host "Installation de $package terminée avec succès."
                $installedCount++

            }
            catch {
                Write-Error "Échec de l'installation de $package :"
                Write-Error "Erreur : $($_.Exception.Message)"
                $failedPackages += $package
                Write-Host "L'installation de $package a échoué. Continuation avec le prochain paquet."
            }
        }
    }
    catch {
        # Si choco list --localonly échoue pour une raison (rare)
        Write-Warning "Impossible de vérifier l'installation de $package via 'choco list'. Tentative d'installation directe."
        try {
             choco install $package -y -ErrorAction Stop
             Write-Host "Installation de $package terminée avec succès (via tentative directe)."
             $installedCount++
        }
         catch {
            Write-Error "Échec de l'installation de $package (tentative directe) :"
            Write-Error "Erreur : $($_.Exception.Message)"
            $failedPackages += $package
            Write-Host "L'installation de $package a échoué. Continuation avec le prochain paquet."
         }
    }
    Write-Host "" # Ligne vide pour séparer les installations
}

# --- Résumé final ---
Write-Host "=================================================="
Write-Host " Processus d'installation de la liste de logiciels terminé !"
Write-Host "=================================================="
Write-Host "Résumé :"
Write-Host "  Paquets traités : $($packagesToInstall.Count)"
Write-Host "  Installations réussies : $installedCount"
Write-Host "  Paquets déjà installés : $skippedCount"
Write-Host "  Échecs d'installation : $($failedPackages.Count)"

if ($failedPackages.Count -gt 0) {
    Write-Host ""
    Write-Error "Les installations ont échoué pour les paquets suivants :"
    $failedPackages | ForEach-Object { Write-Error " - $_" }
    Write-Host ""
    Write-Host "Veuillez vérifier les messages d'erreur ci-dessus pour ces paquets et tenter de les installer manuellement (choco install [nom_du_paquet]) si nécessaire."
}

Write-Host ""
Write-Host "Pour que les commandes des logiciels installés soient disponibles dans le PATH,"
Write-Host "vous devrez peut-être fermer et rouvrir vos sessions PowerShell ou Terminal."
Write-Host ""