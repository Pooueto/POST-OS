# Requires -RunAsAdministrator
# Ce script nécessite des droits d'administrateur pour installer winget (App Installer).

Write-Host "=================================================="
Write-Host " Début du script d'installation de winget (App Installer)"
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

# --- Vérifier si winget est déjà installé ---
Write-Host "--- Vérification de l'installation existante de winget ---"
# On vérifie si la commande 'winget' est disponible dans le PATH
try {
    $wingetPathTest = Get-Command winget.exe -ErrorAction Stop | Select-Object -ExpandProperty Source
    Write-Host "winget est déjà installé (trouvé à : $wingetPathTest)."
    Write-Host "L'installation n'est pas nécessaire. Le script va se terminer."
    Write-Host ""
    Write-Host "=================================================="
    Write-Host " Script d'installation de winget terminé (déjà installé)!"
    Write-Host "=================================================="
    Exit 0 # Sortie réussie car déjà installé
}
catch {
    Write-Host "winget n'a pas été détecté. L'installation va commencer."
}
Write-Host ""

# --- Configuration ---
# URL pour le dernier release stable de Microsoft.DesktopAppInstaller (.msixbundle)
# Cette URL aka.ms redirige vers le dernier release stable sur GitHub.
$wingetBundleUrl = "https://aka.ms/getwinget" # URL courte officielle

$downloadPath = Join-Path $env:TEMP "Winget_Install_Download"
$wingetBundleFileName = "Microsoft.DesktopAppInstaller.msixbundle" # Nom de fichier attendu
$wingetBundleFilePath = Join-Path $downloadPath $wingetBundleFileName

Write-Host "--- Préparation du téléchargement ---"
Write-Host "Cible du téléchargement : $wingetBundleFileName"
Write-Host "Répertoire temporaire : $downloadPath"
Write-Host "URL de téléchargement : $wingetBundleUrl"
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

# --- Téléchargement de winget MSIX Bundle ---
Write-Host "--- Lancement du téléchargement ---"
Write-Host "Téléchargement en cours..."
Write-Host "Ceci peut prendre quelques instants car le fichier est assez volumineux (~80-100 Mo)."

try {
    # Utilise -UseBasicParsing car Invoke-WebRequest peut échouer sans ça dans certains environnements minimalistes
    Invoke-WebRequest -Uri $wingetBundleUrl -OutFile $wingetBundleFilePath -UseBasicParsing -ErrorAction Stop
    Write-Host "Téléchargement terminé avec succès !"
    Write-Host "Fichier téléchargé : $wingetBundleFilePath"
}
catch {
    Write-Error "Échec du téléchargement de winget (App Installer) :"
    Write-Error "URL : $wingetBundleUrl"
    Write-Error "Erreur : $($_.Exception.Message)"
    Write-Host "Vérifiez l'URL de téléchargement et votre connexion internet."
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Installation de winget (App Installer) ---
Write-Host "--- Lancement de l'installation ---"
Write-Host "Installation de winget à partir du fichier MSIX bundle :"
Write-Host $wingetBundleFilePath
Write-Host "Ceci peut prendre quelques instants..."

# L'installation MSIX nécessite la fonctionnalité AppX/Desktop Bridge.
# Sur certaines versions très allégées de reviOS, cela pourrait échouer si cette fonctionnalité a été supprimée.
try {
    # Ajoutez -Verbose si vous voulez voir plus de détails de l'installation AppX
    # L'installation peut aussi nécessiter des dépendances VCLibs et UI.Xaml,
    # mais aka.ms/getwinget est censé fournir un bundle qui les inclut.
    Add-AppxPackage -Path $wingetBundleFilePath -ErrorAction Stop # -Verbose

    Write-Host "Installation de winget (App Installer) terminée avec succès !"
    Write-Host "La commande 'winget' pourrait ne pas être immédiatement disponible dans cette session."

}
catch {
    Write-Error "Échec de l'installation de winget (App Installer)."
    Write-Error "Cause possible : L'infrastructure AppX/Desktop Bridge est peut-être désactivée ou retirée sur cette version de reviOS, ou des dépendances sont manquantes."
    Write-Error "Message d'erreur détaillé : $($_.Exception.Message)"
    Write-Host "Le fichier de téléchargement ($wingetBundleFilePath) sera conservé pour inspection."
    Read-Host "Appuyez sur Entrée pour quitter."
    # On ne nettoie pas le fichier de téléchargement ici pour permettre l'inspection
    Exit 1 # Quitte si l'installation échoue
}
Write-Host ""

# --- Nettoyage (Optionnel) ---
Write-Host "--- Nettoyage ---"
Write-Host "Suppression du fichier de téléchargement temporaire : $wingetBundleFilePath"
try {
    # On utilise -ErrorAction SilentlyContinue car le fichier pourrait ne pas exister si le téléchargement a échoué plus tôt
    Remove-Item -Path $wingetBundleFilePath -Force -ErrorAction SilentlyContinue
    Write-Host "Nettoyage terminé."
}
catch {
    Write-Warning "Impossible de nettoyer le fichier de téléchargement : $($_.Exception.Message)"
}
Write-Host ""

# --- Vérification finale (nécessite potentiellement nouvelle session) ---
Write-Host "--- Vérification finale de la commande winget ---"
Write-Host "La commande 'winget' pourrait ne pas être reconnue immédiatement."
Write-Host "Veuillez ouvrir une nouvelle session PowerShell ou un nouveau Terminal et tapez 'winget --version' pour vérifier."
Write-Host "Le PATH peut prendre un instant pour être mis à jour."
Write-Host ""

Write-Host "=================================================="
Write-Host " Script d'installation de winget terminé !"
Write-Host "=================================================="
Write-Host "Une fois que vous avez vérifié que 'winget' fonctionne dans un nouveau Terminal,"
Write-Host "vous pouvez exécuter à nouveau le script d'installation de Oh My Posh"
Write-Host "(après que nous l'aurons modifié pour prioriser winget) et les autres scripts qui l'utilisent."
Write-Host ""