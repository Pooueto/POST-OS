# Requires -RunAsAdministrator
# Ce script nécessite des droits d'administrateur pour installer des modules PowerShell globalement.

Write-Host "=================================================="
Write-Host " Début du script d'installation du module Terminal-Icons"
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

# --- Installation du module Terminal-Icons (avec Force) ---
Write-Host "--- Lancement de l'installation (ou mise à jour forcée) du module Terminal-Icons ---"
Write-Host "Cela nécessite l'accès au PowerShell Gallery (psgallery.org)."
Write-Host "Utilisation du paramètre -Force pour assurer l'installation même si le module semble déjà présent."
Write-Host "Si vous y accédez pour la première fois, il pourrait vous demander de faire confiance au dépôt."
Write-Host ""

try {
    # Installe le module pour tous les utilisateurs (nécessite Admin)
    # -Force : Force la réinstallation/mise à jour.
    # -AllowClobber : Supprime/remplace les commandes qui pourraient avoir le même nom.
    # -Scope AllUsers : Installe dans un chemin global (C:\Program Files\PowerShell\Modules par défaut)
    Install-Module -Name Terminal-Icons -Scope AllUsers -Force -AllowClobber -ErrorAction Stop -Verbose # Ajoutez -Verbose pour plus de détails

    Write-Host "" # Ligne vide après la sortie potentiellement détaillée de -Verbose
    Write-Host "Installation ou mise à jour forcée du module Terminal-Icons terminée avec succès !"
    Write-Host "Le module sera disponible dans vos sessions PowerShell après redémarrage ou ouverture d'une nouvelle session."
    Write-Host "Vous pouvez vérifier sa présence avec : Get-Module -ListAvailable -Name Terminal-Icons"


}
catch {
    Write-Error "Échec lors de l'installation du module Terminal-Icons :"
    Write-Error "Erreur : $($_.Exception.Message)"
    Write-Host "Vérifiez votre connexion internet et l'accès au PowerShell Gallery (psgallery.org)."
    Write-Host "Assurez-vous que les modules PowerShellGet et PackageManagement sont fonctionnels sur votre système."
    Write-Host "Assurez-vous d'avoir accepté de faire confiance au dépôt PSGallery si cela a été demandé précédemment."
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1 # Quitte si l'installation échoue
}
Write-Host ""

# --- Vérification finale après installation ---
Write-Host "--- Vérification finale après installation ---"
# Tente de trouver le module pour confirmer l'installation
try {
    $installedModule = Get-Module -ListAvailable -Name Terminal-Icons -ErrorAction Stop
    Write-Host "Le module Terminal-Icons a été trouvé dans les chemins d'installation disponibles."
    Write-Host "Version installée : $($installedModule.Version)"
    Write-Host "Installé à : $($installedModule.Path)"
}
catch {
     Write-Warning "Le module Terminal-Icons n'est toujours pas détecté après la tentative d'installation."
     Write-Warning "L'installation a peut-être échoué silencieusement ou il y a un problème avec les chemins de modules."
}
Write-Host ""

Write-Host "=================================================="
Write-Host " Script d'installation du module Terminal-Icons terminé !"
Write-Host "=================================================="
Write-Host "Pour que le module soit utilisé, il devra être importé dans votre profil PowerShell (le script de configuration du profil le fera)."
Write-Host "Ouvrez une nouvelle session PowerShell/Terminal pour voir si le module est détecté."
Write-Host ""