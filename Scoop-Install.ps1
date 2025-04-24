# Requires -RunAsAdministrator
# Ce script peut nécessiter des droits d'administrateur pour ajuster la stratégie d'exécution
# de PowerShell, même si l'installation de Scoop se fait par défaut dans le répertoire utilisateur.

Write-Host "=================================================="
Write-Host " Début du script d'installation de Scoop"
Write-Host " INSTALLATION IMPOSSIBLE SI DROIT ADMIN"
Write-Host "=================================================="
Write-Host ""

# --- Vérifier si Scoop est déjà installé ---
Write-Host "--- Vérification de l'installation existante de Scoop ---"
# Scoop définit une variable d'environnement $env:SCOOP
if (Test-Path -Path "$env:SCOOP\shims\scoop.ps1" -PathType Leaf) {
    Write-Host "Scoop semble déjà installé."
    # Tente d'obtenir la version pour confirmer
    try {
        $scoopVersion = scoop status -ErrorAction Stop | Select-String -Pattern "Version:"
        if ($scoopVersion) {
             Write-Host "Scoop est déjà installé."
        } else {
             Write-Host "Scoop semble installé mais la commande 'scoop status' n'a pas retourné la version."
        }
    }
    catch {
        Write-Warning "Scoop semble installé, mais la commande 'scoop' n'est pas immédiatement reconnue dans cette session."
        Write-Warning "C'est normal, vous devrez peut-être ouvrir une nouvelle session PowerShell/Terminal."
    }
    
    Write-Host "L'installation n'est pas nécessaire. Le script va se terminer."
    Write-Host ""
    Write-Host "=================================================="
    Write-Host " Script d'installation de Scoop terminé (déjà installé)!"
    Write-Host "=================================================="
    Exit 0 # Sortie réussie car déjà installé

} else {
    Write-Host "Scoop n'a pas été détecté. L'installation va commencer."
}
Write-Host ""

# --- Prérequis : Stratégie d'exécution ---
Write-Host "--- Configuration de la stratégie d'exécution PowerShell ---"
Write-Host "Vérification de la stratégie d'exécution actuelle pour l'utilisateur courant..."
# Utilise -Scope CurrentUser car Scoop est installé par défaut pour l'utilisateur
$currentExecutionPolicy = Get-ExecutionPolicy -Scope CurrentUser
Write-Host "Stratégie actuelle pour l'utilisateur courant : $currentExecutionPolicy"

# Scoop nécessite au moins RemoteSigned pour télécharger et exécuter le script d'installation.
# Si la stratégie est Restricted ou AllSigned, on la change temporairement pour l'utilisateur courant.
# Note: Modifier la stratégie pour CurrentUser ne nécessite généralement pas Admin si c'est une stratégie plus permissive.
# On peut aussi utiliser -Scope Process, mais Scope CurrentUser est recommandé par Scoop pour que ça persiste.
if ($currentExecutionPolicy -eq 'Restricted') { # 'AllSigned' pourrait aussi poser problème si le script d'installation n'est pas signé
    Write-Host "Définition de la stratégie sur 'RemoteSigned' pour l'utilisateur courant afin de permettre le téléchargement/exécution du script d'installation Scoop..."
    try {
        # Tente de définir RemoteSigned pour l'utilisateur courant
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
        Write-Host "Stratégie définie sur 'RemoteSigned' pour l'utilisateur courant."
    }
    catch {
        Write-Error "Échec de la définition de la stratégie d'exécution RemoteSigned pour l'utilisateur courant : $($_.Exception.Message)"
        Write-Warning "Tentative de définition de 'Bypass' pour la portée Process uniquement..."
        try {
            # Si CurrentUser échoue (ex: GPO l'interdit), essaie Bypass pour le processus actuel
             Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop
             Write-Host "Stratégie définie sur 'Bypass' pour cette session (portée Process)."
        }
        catch {
            Write-Error "Échec de la définition de la stratégie d'exécution même pour la portée Process : $($_.Exception.Message)"
            Write-Host "Impossible de continuer l'installation de Scoop car la stratégie d'exécution empêche l'exécution de scripts téléchargés."
            Read-Host "Appuyez sur Entrée pour quitter."
            Exit 1
        }
    }
    Write-Host "Stratégie d'exécution configurée pour l'installation."

} elseif ($currentExecutionPolicy -eq 'AllSigned') {
    # Si AllSigned, le script d'installation Scoop risque de ne pas être signé. On le gère.
    Write-Warning "La stratégie d'exécution est 'AllSigned'."
    Write-Warning "Le script d'installation de Scoop n'est peut-être pas signé et l'installation pourrait échouer."
    Write-Host "Tentative de définition de 'Bypass' pour la portée Process uniquement pour l'installation..."
     try {
         Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop
         Write-Host "Stratégie définie sur 'Bypass' pour cette session (portée Process)."
     }
     catch {
         Write-Error "Échec de la définition de la stratégie d'exécution Bypass pour la portée Process : $($_.Exception.Message)"
         Write-Host "Impossible de continuer l'installation de Scoop car la stratégie d'exécution 'AllSigned' empêche l'exécution du script non signé."
         Read-Host "Appuyez sur Entrée pour quitter."
         Exit 1
     }
     Write-Host "Stratégie d'exécution configurée pour l'installation."

} else {
    Write-Host "La stratégie d'exécution ('$currentExecutionPolicy') est suffisante (RemoteSigned ou moins restrictive)."
}
Write-Host ""

# --- Installation de Scoop ---
Write-Host "--- Lancement de l'installation de Scoop ---"
Write-Host "Téléchargement et exécution du script d'installation depuis get.scoop.sh..."
Write-Host "Ceci peut prendre quelques instants..."
Write-Host "(Scoop s'installera par défaut dans $($env:USERPROFILE)\scoop)"

try {
    # La commande d'installation officielle
    Invoke-RestMethod get.scoop.sh | Invoke-Expression -ErrorAction Stop

    Write-Host "Installation de Scoop initiée. Vérification..."

    # La commande 'scoop' devrait être ajoutée au PATH utilisateur (et non système).
    # Cela peut nécessiter l'ouverture d'une nouvelle session.
    Start-Sleep -Seconds 5 # Laisser un peu de temps pour que l'installation se termine

    # Tente de vérifier si scoop est maintenant accessible dans cette session
    try {
        $scoopTest = scoop status -ErrorAction Stop | Select-String -Pattern "Version:"
        if ($scoopTest) {
            Write-Host "Scoop semble installé avec succès !"
        } else {
             Write-Warning "Scoop a été installé, mais la commande 'scoop status' n'a pas retourné la version."
        }
    }
    catch {
         Write-Warning "Scoop a été installé, mais la commande 'scoop' n'est pas immédiatement reconnue dans cette session."
         Write-Warning "Ceci est normal. Vous devrez ouvrir une nouvelle session PowerShell ou une nouvelle fenêtre Terminal"
         Write-Warning "pour que la commande 'scoop' soit ajoutée à votre PATH utilisateur et reconnue."
         Write-Host "Vérifiez l'installation en ouvrant un nouveau Terminal et en tapant 'scoop' ou 'scoop status'."
    }


}
catch {
    Write-Error "Échec lors de l'exécution du script d'installation de Scoop :"
    Write-Error "Erreur : $($_.Exception.Message)"
    Write-Host "L'installation de Scoop a échoué."
    Write-Host "Vérifiez votre connexion internet et la stratégie d'exécution PowerShell."
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Installer le bucket 'extras' (Courant et utile) ---
Write-Host "--- Installation du bucket 'extras' de Scoop (Optionnel) ---"
Write-Host "Le bucket 'extras' contient de nombreux programmes utiles qui ne sont pas dans le bucket principal."
Write-Host "Ceci nécessite que la commande 'scoop' soit reconnue (nouvelle session si l'installation vient d'avoir lieu)."

# On utilise Start-Process car la commande 'scoop' pourrait ne pas être disponible dans la session actuelle
# si le PATH utilisateur n'est pas mis à jour. Lancer dans un nouveau process avec -NoProfile
# permet souvent de trouver la commande mise à jour. On attend sa fin.
try {
    Write-Host "Exécution de 'scoop bucket add extras'..."
    # Utilise cmd /c scoop pour s'assurer que le PATH utilisateur mis à jour est utilisé.
    # Ou directement scoop.ps1 si on connait le chemin exact ($env:SCOOP\shims\scoop.ps1 bucket add extras)
    # La méthode Start-Process powershell -Command "scoop bucket add extras" est plus robuste
    Start-Process -FilePath powershell.exe -ArgumentList "-NoProfile -Command ""scoop bucket add extras""" -Wait -ErrorAction Stop
    Write-Host "Le bucket 'extras' a été ajouté avec succès ou existait déjà."
}
catch {
    Write-Warning "Échec lors de l'ajout du bucket 'extras' Scoop."
    Write-Warning "Erreur : $($_.Exception.Message)"
    Write-Warning "Vous pourrez l'ajouter manuellement plus tard en ouvrant une nouvelle session PowerShell/Terminal et en exécutant : scoop bucket add extras"
}
Write-Host ""

# --- Rétablir la stratégie d'exécution (Optionnel) ---
Write-Host "--- Rétablissement potentiel de la stratégie d'exécution PowerShell ---"
# Si la stratégie a été changée pour CurrentUser ou Process, elle est soit permanente (CurrentUser) soit temporaire (Process).
# Le script d'installation de Scoop recommande de laisser RemoteSigned pour CurrentUser.
Write-Host "Si la stratégie d'exécution a été définie sur 'RemoteSigned' pour l'utilisateur courant, c'est le paramètre recommandé par Scoop."
Write-Host "Si 'Bypass' a été utilisé pour la portée Process, ce paramètre est temporaire pour cette session."
# Si vous voulez explicitement la remettre à une autre valeur (ex: Undefined) pour l'utilisateur courant :
# Set-ExecutionPolicy Undefined -Scope CurrentUser -Force -ErrorAction SilentlyContinue

Write-Host ""

Write-Host "=================================================="
Write-Host " Script d'installation de Scoop terminé !"
Write-Host "=================================================="
Write-Host "Ouvrez une nouvelle session PowerShell ou un nouveau Terminal pour utiliser 'scoop'."
Write-Host "Les paquets seront installés par défaut dans $($env:USERPROFILE)\scoop\apps"
Write-Host ""