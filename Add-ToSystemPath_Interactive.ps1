# Requires -RunAsAdministrator
# Ce script nécessite des droits d'administrateur pour modifier la variable d'environnement PATH système.

Write-Host "==============================================="
Write-Host " Début du script d'ajout de chemin au PATH système"
Write-Host "==============================================="
Write-Host ""

# --- Vérification et élévation des droits d'administrateur ---
Write-Host "Vérification des droits d'administrateur actuels..."
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Droits d'administrateur non détectés dans cette session."
    Write-Host "Tentative d'élévation (affichage de l'invite UAC)..."

    # Récupère le chemin complet du script actuel
    $scriptPath = $MyInvocation.MyCommand.Path
    Write-Host "Chemin du script pour la relance : $scriptPath" # Diagnostic

    # Construit la liste d'arguments pour le nouveau processus PowerShell
    $arguments = "-File ""{0}""" -f $scriptPath

    Write-Host "Arguments pour la relance : $arguments" # Diagnostic

    try {
        # Relance le script actuel avec des droits d'administrateur
        $process = Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList $arguments -PassThru
        Write-Host "Processus de relance démarré (PID : $($process.Id))." # Diagnostic

        # Quitte l'instance actuelle du script (qui n'a pas les droits admin)
        Write-Host "L'instance actuelle (non-admin) va maintenant se terminer." # Diagnostic
        Start-Sleep -Seconds 1 # Petit délai optionnel
        Exit
    }
    catch {
        Write-Error "Échec critique lors de la tentative de relance en tant qu'administrateur."
        Write-Error "Erreur : $($_.Exception.Message)"
        Write-Host "Veuillez vérifier que le chemin du script ($scriptPath) est valide et accessible."
        Read-Host "Appuyez sur Entrée pour quitter."
        Exit 1 # Quitte si la relance échoue
    }
}

# Si le script arrive ici, c'est qu'il est déjà admin OU qu'il vient d'être relancé avec succès
Write-Host "Droits d'administrateur vérifiés/obtenus. Le script continue son exécution..."
Write-Host "" # Ligne vide pour la lisibilité après le bloc d'élévation


# --- Saisie interactive du chemin ---
$pathToAddToPath = ""
do {
    Write-Host "--- Saisie du chemin à ajouter ---"
    $pathToAddToPath = Read-Host "Veuillez entrer le chemin complet du dossier à ajouter au PATH système (ex: C:\MonApp\Bin)"

    # Nettoie les espaces blancs autour du chemin saisi
    $pathToAddToPath = $pathToAddToPath.Trim()

    if ([string]::IsNullOrEmpty($pathToAddToPath)) {
        Write-Warning "Aucun chemin n'a été saisi. Veuillez entrer un chemin valide."
        Write-Host ""
    } elseif (-not (Test-Path -Path $pathToAddToPath -PathType Container)) {
        Write-Warning "Le chemin spécifié n'existe pas ou n'est pas un dossier valide : $pathToAddToPath"
        Write-Host "Veuillez vérifier le chemin et réessayer."
        Write-Host ""
    }

} while ([string]::IsNullOrEmpty($pathToAddToPath) -or (-not (Test-Path -Path $pathToAddToPath -PathType Container)))

Write-Host "Chemin valide saisi : $pathToAddToPath"
Write-Host ""


# --- Récupérer le PATH actuel ---
Write-Host "--- Gestion du PATH système ---"
Write-Host "Récupération de la variable PATH système actuelle..."
try {
    # 'Machine' cible la variable d'environnement système (globale)
    $currentPath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
    Write-Host "PATH système actuel récupéré."
    # Write-Host "Valeur : $currentPath" # Décommenter pour afficher la valeur complète (peut être longue)
}
catch {
    Write-Error "Échec de la récupération de la variable PATH système : $($_.Exception.Message)"
    Read-Host "Appuyez sur Entrée pour quitter."
    Exit 1
}
Write-Host ""

# --- Vérifier si le chemin existe déjà ---
Write-Host "Vérification si '$pathToAddToPath' existe déjà dans le PATH..."
# Divise le PATH actuel en chemins individuels et nettoie les espaces/entrées vides
$pathParts = $currentPath -split ';' | Where-Object { -not [string]::IsNullOrEmpty($_.Trim()) } | ForEach-Object { $_.Trim() }

# Vérifie si le chemin à ajouter (ignoré la casse) est déjà dans la liste
$pathAlreadyExists = $pathParts -contains $pathToAddToPath

if ($pathAlreadyExists) {
    Write-Host "Le chemin '$pathToAddToPath' existe déjà dans le PATH système."
    Write-Host "Aucune modification nécessaire."
} else {
    # --- Ajouter le chemin si non existant ---
    Write-Host "Le chemin '$pathToAddToPath' n'a pas été trouvé dans le PATH."
    Write-Host "Ajout du chemin..."

    # Construit le nouveau PATH en ajoutant le chemin.
    # S'assure qu'il y a un point-virgule si le PATH actuel n'est pas vide et ne finit pas déjà par un point-virgule.
    $newPath = $currentPath
    if (-not [string]::IsNullOrEmpty($currentPath) -and -not $currentPath.EndsWith(';')) {
        $newPath += ';'
    }
    $newPath += $pathToAddToPath # On a déjà trimé le chemin saisi plus tôt

    Write-Host "Nouvelle valeur du PATH système (partielle) : $($newPath -replace ';', ' ; ')..." # Affiche une version plus lisible

    # --- Définir le nouveau PATH ---
    Write-Host "Définition de la nouvelle variable PATH système..."
    try {
        [Environment]::SetEnvironmentVariable('PATH', $newPath, 'Machine')
        Write-Host "La variable PATH système a été mise à jour avec succès !"
    }
    catch {
         Write-Error "Échec de la mise à jour de la variable PATH système : $($_.Exception.Message)"
         Write-Host "La variable PATH n'a PAS été modifiée."
         Read-Host "Appuyez sur Entrée pour quitter."
         Exit 1
    }
}
Write-Host ""

Write-Host "==============================================="
Write-Host " Script d'ajout de chemin au PATH système terminé !"
Write-Host "==============================================="
Write-Host "Note : Les changements de PATH peuvent nécessiter l'ouverture d'une nouvelle fenêtre"
Write-Host "      de ligne de commande ou un redémarrage pour prendre effet dans toutes les applications."
Write-Host ""