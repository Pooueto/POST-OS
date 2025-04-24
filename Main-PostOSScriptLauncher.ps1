# Requires -RunAsAdministrator
# Ce script sert de menu principal pour lancer les différents scripts d'automatisation post-installation.
# Il nécessite des droits d'administrateur car de nombreux scripts enfants en ont besoin.

Write-Host "=================================================="
Write-Host " Bienvenue dans l'Utilitaire d'Automatisation Post-Installation"
Write-Host "=================================================="
Write-Host ""

# --- Vérification et élévation des droits d'administrateur ---
Write-Host "Vérification des droits d'administrateur actuels..."
$currentUser = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.BuiltInRole]::Administrator)

if (-not $currentUser.IsInRole([System.Security.Principal.BuiltInRole]::Administrator)) {
    Write-Host "Droits d'administrateur non détectés dans cette session. Tentative d'élévation..."
    $scriptPath = $MyInvocation.MyCommand.Path
    try {
        # Relance le script actuel avec des droits admin
        # Utilise -NoProfile et -ExecutionPolicy Bypass pour minimiser les problèmes de configuration initiale
        Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File ""$scriptPath""" -PassThru | Out-Null
        Write-Host "Processus de relance démarré. L'instance actuelle (non-admin) va maintenant se terminer."
        Start-Sleep -Seconds 1
        Exit
    }
    catch {
        Write-Error "Échec critique lors de la tentative de relance en tant qu'administrateur : $($_.Exception.Message)"
        Write-Host "Veuillez exécuter ce script en tant qu'administrateur manuellement si l'élévation automatique échoue."
        Read-Host "Appuyez sur Entrée pour quitter."
        Exit 1
    }
}
Write-Host "Droits d'administrateur vérifiés/obtenus. Le script principal continue."
Write-Host ""

# --- Fonction pour afficher le menu principal ---
function Show-MainMenu {
    Clear-Host # Nettoie l'écran avant d'afficher le menu

    Write-Host "=================================================="
    Write-Host " Menu Principal d'Automatisation Post-Installation"
    Write-Host "=================================================="
    Write-Host ""
    Write-Host "Sélectionnez une option en tapant le numéro ou la lettre, puis appuyez sur Entrée :"
    Write-Host ""

    # Options du menu principal basées sur les groupes de scripts
    Write-Host "1. Installer les Essentiels (Chocolatey, Scoop, PowerShell 7, Terminal-Icons)"
    Write-Host "2. Installer les Dépendances Logicielles (FFmpeg, MediaInfo CLI, ImageMagick, Speedtest CLI, Oh My Posh)"
    Write-Host "3. Installer la Liste Complète de Logiciels (Chrome, Discord, Steam, etc. via Chocolatey)"
    Write-Host "4. Télécharger & Placer Fichiers Personnels/Configuration (Scripts, Configs, Nerd Font ZIP)"
    Write-Host "5. Configuration Finale (Profil PowerShell, Terminal Windows settings.json)"
    Write-Host "6. Outils Utilitaires (Ajout au PATH interactif)"
    Write-Host ""
    Write-Host "Q. Quitter"
    Write-Host ""
}

# --- Fonction pour exécuter un script enfant et gérer les messages ---
function Run-Script {
    param(
        [string]$ScriptPath,
        [string]$Description = "le script" # Description utilisée dans les messages
    )

    # Construit le chemin complet du script enfant en supposant qu'il est dans le même répertoire que le script principal
    $fullScriptPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) $ScriptPath

    Write-Host "--- Lancement de $Description ($ScriptPath) ---"
    Write-Host "Ceci peut prendre quelques instants et peut ouvrir une nouvelle fenêtre si le script s'élève..."
    Write-Host ""

    # Vérifie si le fichier script enfant existe
    if (-not (Test-Path -Path $fullScriptPath -PathType Leaf)) {
        Write-Error "Le fichier script n'a pas été trouvé : $fullScriptPath"
        Write-Error "Assurez-vous que tous les scripts sont dans le même dossier que le lanceur principal."
        Write-Host ""
         Write-Error "--- Exécution de $Description échouée (script introuvable). ---" -ForegroundColor Red
         Write-Host ""
         Write-Host "Appuyez sur Entrée pour revenir au menu principal..."
         $null = Read-Host
         return # Sort de la fonction Run-Script
    }

    # Exécute le script enfant dans un nouveau processus PowerShell et attend sa fin.
    # -NoNewWindow $false permet au script enfant de gérer sa propre fenêtre ou élévation si nécessaire.
    try {
        $process = Start-Process -FilePath powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File ""$fullScriptPath""" -Wait -PassThru -NoNewWindow $false

        # Vérifie le code de sortie du processus enfant
        if ($process.ExitCode -eq 0) {
            Write-Host ""
            Write-Host "--- Exécution de $Description terminée avec succès. ---" -ForegroundColor Green
        } else {
            Write-Host ""
            # Affiche le code de sortie s'il n'est pas 0
            Write-Error "--- Exécution de $Description terminée avec un code d'erreur ($($process.ExitCode)). ---" -ForegroundColor Red
        }
    }
    catch {
        # Capture les erreurs lors du lancement du processus Start-Process lui-même
        Write-Error "Une erreur s'est produite lors du lancement de $Description (via Start-Process) :"
        Write-Error "Erreur : $($_.Exception.Message)"
        Write-Host ""
        Write-Error "--- Exécution de $Description échouée. ---" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "Appuyez sur Entrée pour revenir au menu principal..."
    $null = Read-Host # Marque une pause avant de revenir au menu
}

# --- Fonction pour gérer le choix de l'utilisateur et lancer les actions correspondantes ---
function Handle-MenuOption {
    param(
        [string]$Option
    )

    # Convertit l'option en majuscule pour simplifier la comparaison
    $upperOption = $Option.ToUpper()

    switch ($upperOption) {
        "1" { # Installations Essentielles (Lancement séquentiel des scripts)
            Write-Host ""
            Write-Host "--- Lancement des Installations Essentielles ---" -ForegroundColor Yellow
            Run-Script -ScriptPath "Install-Chocolatey.ps1" -Description "l'installation de Chocolatey"
            Run-Script -ScriptPath "Install-Scoop.ps1" -Description "l'installation de Scoop"
            Run-Script -ScriptPath "Install-PowerShell7.ps1" -Description "l'installation de PowerShell 7"
            Run-Script -ScriptPath "Install-TerminalIcons.ps1" -Description "l'installation du module Terminal-Icons"
            Write-Host "--- Fin des Installations Essentielles ---" -ForegroundColor Yellow
        }
        "2" { # Installations des Dépendances Logicielles (Lancement séquentiel)
             Write-Host ""
             Write-Host "--- Lancement des Installations des Dépendances Logicielles ---" -ForegroundColor Yellow
            # Les installations via Choco gèrent la vérification d'existence en interne.
            Run-Script -ScriptPath "Install-FFmpegChoco.ps1" -Description "l'installation de FFmpeg (Choco)"
            Run-Script -ScriptPath "Download-MediaInfoCLI.ps1" -Description "le téléchargement et placement de MediaInfo CLI"
            # NOTE IMPORTANTE pour MediaInfo CLI : Rappeler d'ajouter au PATH
            Write-Host "--------------------------------------------------"
            Write-Warning "Rappel : Pour MediaInfo CLI ($($executionPath = Split-Path -Parent $MyInvocation.MyCommand.Definition)\Download-MediaInfoCLI.ps1),"
            Write-Warning "vous devez MANUELLEMENT ajouter le répertoire où mediainfo.exe a été copié (probablement C:\Program Files\MediaInfoCLI)"
            Write-Warning "à la variable d'environnement PATH système, idéalement via l'option 6 du menu principal ('Add-ToSystemPath_Interactive.ps1')."
            Write-Host "--------------------------------------------------"
            Run-Script -ScriptPath "Install-ImageMagickChoco.ps1" -Description "l'installation d'ImageMagick (Choco)"
            Run-Script -ScriptPath "Install-SpeedtestChoco.ps1" -Description "l'installation de Speedtest CLI (Choco)"
            Run-Script -ScriptPath "Install-OhMyPosh.ps1" -Description "l'installation d'Oh My Posh (Choco)"
            # yt-dlp est installé avec la liste complète de logiciels (Option 3)
             Write-Host "--- Fin des Installations des Dépendances Logicielles ---" -ForegroundColor Yellow
        }
         "3" { # Installer la Liste Complète de Logiciels (Lancement d'un script unique)
             Write-Host ""
             Write-Host "--- Lancement de l'installation de la liste complète de logiciels via Chocolatey ---" -ForegroundColor Yellow
             Write-Warning "Ce processus peut prendre du temps car il installe de nombreux logiciels. Soyez patient."
             Read-Host "Appuyez sur Entrée pour lancer l'installation de la liste complète..."
             Run-Script -ScriptPath "Install-SoftwareListChoco.ps1" -Description "l'installation de la liste complète de logiciels"
             Write-Host "--- Fin de l'installation de la liste complète de logiciels ---" -ForegroundColor Yellow
         }
        "4" { # Sous-menu pour Téléchargement & Placement de Fichiers
            Write-Host ""
            Write-Host "=================================================="
            Write-Host " Menu : Téléchargement & Placement de Fichiers"
            Write-Host "=================================================="
            Write-Host ""
             Write-Host "Cette section lance les scripts pour télécharger vos fichiers personnalisés et de configuration."
             Write-Warning "Note Importante :"
             Write-Warning "  - Le script Download-PersonalScripts.ps1 (options 41 et 42) DOIT être configuré AVANT son exécution (URL source, chemin destination)."
             Write-Warning "  - Le script Install-NerdFont.ps1 (option 43) nécessite une action MANUELLE de votre part après le téléchargement."
             Write-Host ""
            Write-Host "  41. Télécharger vos scripts personnels (via Download-PersonalScripts.ps1)"
            Write-Host "  42. Télécharger la configuration Fastfetch (via Download-PersonalScripts.ps1)"
            Write-Host "  43. Télécharger la Nerd Font (via Install-NerdFont.ps1 - nécessite installation manuelle)"
            Write-Host ""
            Write-Host "  B. Retour au Menu Principal"
            Write-Host ""

            $subChoice = Read-Host "Votre choix pour le Téléchargement/Placement"
            switch ($subChoice.ToUpper()) {
                "41" {
                     Write-Host ""
                     Write-Warning "CONFIRMEZ que '$githubRepoUrlBase' et '$destinationPath' dans 'Download-PersonalScripts.ps1' sont configurés pour vos scripts personnels AVANT de lancer !"
                     Read-Host "Appuyez sur Entrée pour lancer le script de téléchargement de scripts personnels..."
                     Run-Script -ScriptPath "Download-PersonalScripts.ps1" -Description "le téléchargement de scripts personnels"
                }
                "42" {
                     Write-Host ""
                      Write-Warning "CONFIRMEZ que '$githubRepoUrlBase' et '$destinationPath' dans 'Download-PersonalScripts.ps1' sont configurés pour la config Fastfetch AVANT de lancer !"
                      Write-Warning "Le chemin de destination devrait être 'C:\ProgramData\fastfetch' et le chemin source le dossier 'fastfetch' dans votre dépôt POST-OS.git."
                      Read-Host "Appuyez sur Entrée pour lancer le script de téléchargement de la config Fastfetch..."
                     Run-Script -ScriptPath "Download-PersonalScripts.ps1" -Description "le téléchargement de la configuration Fastfetch"
                }
                "43" {
                    Write-Host ""
                    Write-Warning "Le script 'Install-NerdFont.ps1' nécessite une action MANUELLE de votre part APRES le téléchargement pour l'installation de la police."
                     Read-Host "Appuyez sur Entrée pour lancer le script Install-NerdFont.ps1..."
                     Run-Script -ScriptPath "Install-NerdFont.ps1" -Description "le script de téléchargement de la Nerd Font"
                }
                "B" {
                    # Retour au menu principal (la boucle while s'en charge)
                }
                default {
                    Write-Warning "Option invalide pour le Téléchargement/Placement. Retour au menu principal."
                    Start-Sleep -Seconds 1
                }
            }
        }
        "5" { # Sous-menu pour Configuration Finale
             Write-Host ""
             Write-Host "=================================================="
             Write-Host " Menu : Configuration Finale"
             Write-Host "=================================================="
             Write-Host ""
             Write-Host "Cette section lance les scripts qui configurent votre environnement final."
             Write-Warning "Assurez-vous que TOUTES les INSTALLATIONS et TOUS les TÉLÉCHARGEMENTS nécessaires sont terminés AVANT de lancer ces scripts."
             Write-Host ""
            Write-Host "  51. Appliquer la configuration settings.json de Terminal Windows"
            Write-Host "  52. Configurer le Profil PowerShell (\$PROFILE)"
            Write-Host ""
            Write-Host "  B. Retour au Menu Principal"
            Write-Host ""

            $subChoice = Read-Host "Votre choix pour la Configuration Finale"
             switch ($subChoice.ToUpper()) {
                 "51" {
                      Write-Host ""
                      Write-Warning "FERMEZ Terminal Windows AVANT de continuer pour éviter les problèmes de fichier verrouillé !"
                      Read-Host "Appuyez sur Entrée pour lancer le script d'application de settings.json..."
                      Run-Script -ScriptPath "Apply-TerminalSettings.ps1" -Description "l'application de settings.json de Terminal Windows"
                 }
                 "52" {
                     Write-Host ""
                      Write-Warning "CONFIRMEZ que les chemins dans 'Configure-PowerShellProfile.ps1' (notamment pour Fastfetch et vos alias) sont corrects AVANT de continuer !"
                     Read-Host "Appuyez sur Entrée pour lancer le script de configuration du Profil PowerShell..."
                     Run-Script -ScriptPath "Configure-PowerShellProfile.ps1" -Description "la configuration du Profil PowerShell"
                 }
                 "B" {
                     # Retour au menu principal (la boucle while s'en charge)
                 }
                 default {
                     Write-Warning "Option invalide pour la Configuration Finale. Retour au menu principal."
                     Start-Sleep -Seconds 1
                 }
             }
        }
        "6" { # Outils Utilitaires (Lancement d'un script unique)
             Write-Host ""
             Write-Host "--- Lancement de l'Outil Utilitaire ---" -ForegroundColor Yellow
             Write-Host "Ce script vous permettra d'ajouter interactivement un dossier à la variable d'environnement PATH système."
             Write-Host "Ceci est utile si une installation ne l'a pas fait automatiquement (par exemple après avoir téléchargé MediaInfo CLI)."
             Read-Host "Appuyez sur Entrée pour lancer l'outil d'ajout au PATH..."
             Run-Script -ScriptPath "Add-ToSystemPath_Interactive.ps1" -Description "l'outil d'ajout au PATH système"
             Write-Host "--- Fin de l'Outil Utilitaire ---" -ForegroundColor Yellow
        }
        "Q" { # Quitter le script principal
            Write-Host ""
            Write-Host "Quitter l'Utilitaire d'Automatisation Post-Installation." -ForegroundColor Cyan
            Exit 0 # Termine l'exécution du script principal
        }
        default { # Option invalide
            Write-Warning "Option '$Option' invalide. Veuillez choisir un numéro ou 'Q' pour quitter."
            Start-Sleep -Seconds 2 # Laisse le message d'avertissement visible
        }
    }
}

# --- Boucle principale qui affiche le menu et gère les choix ---
while ($true) {
    Show-MainMenu # Affiche le menu principal
    $choice = Read-Host "Entrez votre choix" # Demande à l'utilisateur de faire un choix
    Handle-MenuOption -Option $choice # Traite le choix de l'utilisateur
}