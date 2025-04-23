# Requires -RunAsAdministrator
# Ce script nécessite des droits d'administrateur pour installer Fastfetch via Chocolatey.

Write-Host "=================================================="
Write-Host " Début du script d'installation de Fastfetch (via Chocolatey)"
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

# --- Vérifier si Fastfetch est déjà installé ---
Write-Host "--- Vérification de l'installation existante de Fastfetch ---"
# On vérifie si la commande 'fastfetch' est disponible dans le PATH
try {
    $ffVersion = fastfetch --version -ErrorAction Stop
    Write-Host "Fastfetch est déjà installé (version : $($ffVersion.Trim()))."
    Write-Host "L'installation n'est pas nécessaire. Le script va se terminer."
    Write-Host ""
    Write-Host "=================================================="
    Write-Host " Script d'installation de Fastfetch terminé (déjà installé)!"
    Write-Host "=================================================="
    Exit 0 # Sortie réussie car déjà installé
}
catch {
    Write-Host "Fastfetch n'a pas été détecté. L'installation va commencer via Chocolatey."
}
Write-Host ""

# --- Vérifier si Chocolatey est disponible ---
Write-Host "--- Vérification de la disponibilité de Chocolatey ---"
try {
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
Write-Host "--- Lancement de l'installation de Fastfetch via Chocolatey ---"
Write-Host "Exécution de la commande : choco install fastfetch -y"
Write-Host "Ceci peut prendre quelques instants..."

try {
    # Exécute la commande choco install
    $process = Start-Process -FilePath choco.exe -ArgumentList "install fastfetch -y" -Wait -PassThru -ErrorAction Stop

     if ($process.ExitCode -eq 0) {
        Write-Host "Installation de Fastfetch via Chocolatey terminée avec succès !"
        Write-Host "Vous devrez peut-être ouvrir une nouvelle session PowerShell/Terminal pour que la commande 'fastfetch' soit reconnue."
    } elseif ($process.ExitCode -eq 1641 -or $process.ExitCode -eq 3010) {
         Write-Warning "Installation de Fastfetch terminée, mais un redémarrage est nécessaire (Code de sortie : $($process.ExitCode))."
         Write-Warning "Veuillez redémarrer votre ordinateur dès que possible pour finaliser l'installation."
         Write-Host "La commande 'fastfetch' pourrait ne pas être disponible avant le redémarrage."
    }
    else {
        Write-Error "Chocolatey a signalé un problème lors de l'installation de Fastfetch (Code de sortie : $($process.ExitCode))."
        Write-Error "L'installation via Chocolatey a échoué."
        Write-Host "Vérifiez la sortie de la commande choco pour plus de détails sur l'erreur."
         Read-Host "Appuyez sur Entrée pour quitter."
        Exit 1 # Quitte si choco install échoue
    }

}
catch {
    Write-Error "Échec lors de l'exécution de la commande 'choco install fastfetch -y'."
    Write-Error "Erreur : $($_.Exception.Message)"
    Write-Host "Vérifiez que Chocolatey est correctement installé et dans le PATH."
     Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1 # Quitte si Start-Process échoue
}
Write-Host ""

# --- Vérification finale après installation ---
Write-Host "--- Vérification finale après installation ---"
# Tente de voir si la commande fastfetch est maintenant disponible (peut nécessiter un redémarrage de session si code 3010)
try {
    fastfetch --version -ErrorAction Stop | Out-Null
    Write-Host "La commande 'fastfetch' est maintenant reconnue dans cette session."
}
catch {
     Write-Warning "La commande 'fastfetch' n'est pas encore reconnue dans cette session."
     Write-Warning "C'est normal, surtout si un redémarrage est nécessaire. Vous devrez ouvrir une nouvelle session PowerShell ou une nouvelle fenêtre Terminal après le redémarrage pour qu'elle soit ajoutée à votre PATH."
}
Write-Host ""


Write-Host "=================================================="
Write-Host " Script d'installation de Fastfetch terminé !"
Write-Host "=================================================="
Write-Host "Fastfetch est maintenant installé (via Chocolatey)."
Write-Host "Pour qu'il fonctionne avec vos configurations personnalisées et logos (comme dans votre profil PowerShell),"
Write-Host "vous devrez vous assurer que ces fichiers sont présents sur le système."
Write-Host "Le script de téléchargement de vos fichiers GitHub aidera pour cela."
Write-Host ""