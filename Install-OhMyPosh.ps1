# Requires -RunAsAdministrator
# Ce script nécessite des droits d'administrateur pour installer Oh My Posh via Chocolatey.

Write-Host "=================================================="
Write-Host " Début du script d'installation de Oh My Posh (via Chocolatey)"
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

# --- Vérifier si Oh My Posh est déjà installé ---
Write-Host "--- Vérification de l'installation existante de Oh My Posh ---"
# On vérifie si la commande 'oh-my-posh' est disponible dans le PATH
try {
    $ompVersion = oh-my-posh version -ErrorAction Stop
    Write-Host "Oh My Posh est déjà installé (version : $($ompVersion.Trim()))."
    Write-Host "L'installation n'est pas nécessaire. Le script va se terminer."
    Write-Host ""
    Write-Host "=================================================="
    Write-Host " Script d'installation de Oh My Posh terminé (déjà installé)!"
    Write-Host "=================================================="
    Exit 0 # Sortie réussie car déjà installé
}
catch {
    Write-Host "Oh My Posh n'a pas été détecté. L'installation va commencer via Chocolatey."
}
Write-Host ""

# --- Vérifier si Chocolatey est disponible ---
Write-Host "--- Vérification de la disponibilité de Chocolatey ---"
try {
    # Vérifie si choco.exe existe dans le PATH
    $chocoPath = Get-Command choco.exe -ErrorAction Stop | Select-Object -ExpandProperty Source
    Write-Host "choco trouvé à : $chocoPath"
}
catch {
    Write-Error "La commande 'choco' n'a pas été trouvée."
    Write-Error "Chocolatey n'est pas installé ou n'est pas dans le PATH de cette session."
    Write-Host "Veuillez d'abord exécuter le script 'Install-Chocolatey.ps1'."
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1 # Quitte si choco n'est pas disponible
}
Write-Host ""

# --- Lancer l'installation via Chocolatey ---
Write-Host "--- Lancement de l'installation de Oh My Posh via Chocolatey ---"
Write-Host "Exécution de la commande : choco install oh-my-posh -y"
Write-Host "Ceci peut prendre quelques instants..."

try {
    # Exécute la commande choco install
    # -y : Accepte automatiquement les invites
    # -ErrorAction Stop : Permet au catch de capturer l'erreur si choco install échoue
    $process = Start-Process -FilePath choco.exe -ArgumentList "install oh-my-posh -y" -Wait -PassThru -ErrorAction Stop

    if ($process.ExitCode -eq 0) {
        Write-Host "Installation de Oh My Posh via Chocolatey terminée avec succès !"
        Write-Host "Vous devrez peut-être ouvrir une nouvelle session PowerShell/Terminal pour que la commande 'oh-my-posh' soit reconnue."
    } elseif ($process.ExitCode -eq 1641 -or $process.ExitCode -eq 3010) {
         Write-Warning "Installation de Oh My Posh terminée, mais un redémarrage est nécessaire (Code de sortie : $($process.ExitCode))."
         Write-Warning "Veuillez redémarrer votre ordinateur dès que possible pour finaliser l'installation."
         Write-Host "La commande 'oh-my-posh' pourrait ne pas être disponible avant le redémarrage."
    }
    else {
        Write-Error "Chocolatey a signalé un problème lors de l'installation de Oh My Posh (Code de sortie : $($process.ExitCode))."
        Write-Error "L'installation via Chocolatey a échoué."
        Write-Host "Vérifiez la sortie de la commande choco pour plus de détails sur l'erreur."
         Read-Host "Appuyez sur Entrée pour quitter."
        Exit 1 # Quitte si choco install échoue
    }

}
catch {
    Write-Error "Échec lors de l'exécution de la commande 'choco install oh-my-posh -y'."
    Write-Error "Erreur : $($_.Exception.Message)"
    Write-Host "Vérifiez que Chocolatey est correctement installé et dans le PATH."
     Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1 # Quitte si Start-Process échoue
}
Write-Host ""

# --- Vérification finale après installation ---
Write-Host "--- Vérification finale après installation ---"
# Tente de voir si la commande oh-my-posh est maintenant disponible (peut nécessiter un redémarrage de session si code 3010)
try {
    oh-my-posh version -ErrorAction Stop | Out-Null
    Write-Host "La commande 'oh-my-posh' est maintenant reconnue dans cette session."
}
catch {
     Write-Warning "La commande 'oh-my-posh' n'est pas encore reconnue dans cette session."
     Write-Warning "C'est normal, surtout si un redémarrage est nécessaire. Vous devrez ouvrir une nouvelle session PowerShell ou une nouvelle fenêtre Terminal après le redémarrage pour qu'elle soit ajoutée à votre PATH."
}
Write-Host ""


Write-Host "=================================================="
Write-Host " Script d'installation de Oh My Posh terminé !"
Write-Host "=================================================="
Write-Host "Maintenant que Oh My Posh est installé (via Chocolatey),"
Write-Host "vous devrez configurer votre profil PowerShell pour l'activer et choisir un thème (script de configuration du profil)."
Write-Host "N'oubliez pas d'installer une police compatible (Nerd Font) pour afficher correctement le thème."
Write-Host ""