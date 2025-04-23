#  █████╗ ██╗     ██╗ █████╗ ███████╗
# ██╔══██╗██║     ██║██╔══██╗██╔════╝
# ███████║██║     ██║███████║███████╗
# ██╔══██║██║     ██║██╔══██║╚════██║
# ██║  ██║███████╗██║██║  ██║███████║
# ╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═╝╚══════╝
Set-Alias c clear
Set-Alias -Name vlc -Value "C:\Users\Pooueto\Documents\PowerShell\Scripts\BetterVLC.ps1"
Set-Alias -Name speedtest -Value "C:\Users\Pooueto\Documents\PowerShell\Scripts\SpeedtestLauncherTERM.ps1"
Set-Alias -Name yt -Value "C:\Users\Pooueto\Documents\PowerShell\Scripts\YTtoDL.ps1"
Set-Alias -Name imgConverter -Value "C:\Users\Pooueto\Documents\PowerShell\Scripts\imgConverter.ps1"
Set-Alias -Name videoCompress -Value "C:\Users\Pooueto\Documents\PowerShell\Scripts\videoCompress"
Set-Alias -Name ajouterPochetteGUI -Value "C:\Users\Pooueto\Documents\PowerShell\Scripts\ajouterPochetteGUI.ps1"
Set-Alias -Name alldebrid -Value "C:\Users\Pooueto\Documents\PowerShell\Scripts\BetterAlldebrid.ps1"
Set-Alias -Name q -Value "exit"

#  ██████╗ ██╗  ██╗      ███╗   ███╗██╗   ██╗     ██████╗  ██████╗ ███████╗██╗  ██╗
# ██╔═══██╗██║  ██║      ████╗ ████║╚██╗ ██╔╝     ██╔══██╗██╔═══██╗██╔════╝██║  ██║
# ██║   ██║███████║█████╗██╔████╔██║ ╚████╔╝█████╗██████╔╝██║   ██║███████╗███████║
# ██║   ██║██╔══██║╚════╝██║╚██╔╝██║  ╚██╔╝ ╚════╝██╔═══╝ ██║   ██║╚════██║██╔══██║
# ╚██████╔╝██║  ██║      ██║ ╚═╝ ██║   ██║        ██║     ╚██████╔╝███████║██║  ██║
#  ╚═════╝ ╚═╝  ╚═╝      ╚═╝     ╚═╝   ╚═╝        ╚═╝      ╚═════╝ ╚══════╝╚═╝  ╚═╝
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\emodipt-extend.omp.json" | Invoke-Expression


# ██╗ ██████╗ ██████╗ ███╗   ██╗███████╗    ███╗   ███╗ ██████╗ ██████╗ ██╗   ██╗██╗     ███████╗███████╗
# ██║██╔════╝██╔═══██╗████╗  ██║██╔════╝    ████╗ ████║██╔═══██╗██╔══██╗██║   ██║██║     ██╔════╝██╔════╝
# ██║██║     ██║   ██║██╔██╗ ██║███████╗    ██╔████╔██║██║   ██║██║  ██║██║   ██║██║     █████╗  ███████╗
# ██║██║     ██║   ██║██║╚██╗██║╚════██║    ██║╚██╔╝██║██║   ██║██║  ██║██║   ██║██║     ██╔══╝  ╚════██║
# ██║╚██████╗╚██████╔╝██║ ╚████║███████║    ██║ ╚═╝ ██║╚██████╔╝██████╔╝╚██████╔╝███████╗███████╗███████║
# ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝    ╚═╝     ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚══════╝╚══════╝╚══════╝
Import-Module -Name Terminal-Icons


# ███████╗ █████╗ ███████╗████████╗███████╗███████╗████████╗ ██████╗██╗  ██╗     ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗ 
# ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔════╝██║  ██║    ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝ 
# █████╗  ███████║███████╗   ██║   █████╗  █████╗     ██║   ██║     ███████║    ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗
# ██╔══╝  ██╔══██║╚════██║   ██║   ██╔══╝  ██╔══╝     ██║   ██║     ██╔══██║    ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║
# ██║     ██║  ██║███████║   ██║   ██║     ███████╗   ██║   ╚██████╗██║  ██║    ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝
# ╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝     ╚══════╝   ╚═╝    ╚═════╝╚═╝  ╚═╝     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝ 
#fastfetch --config "C:\Users\Pooueto\Documents\config.jsonc" --logo C:\Users\Pooueto\.config\fastfetch\logo.txt --logo-color-1 black
#fastfetch --config "C:\Users\Pooueto\Documents\config.jsonc" --logo C:\Users\Pooueto\.config\fastfetch\logoURSS.txt --logo-color-1 red

# Choisit aléatoirement entre les deux lignes Fastfetch
$logo = Get-Random -InputObject ("C:\Users\Pooueto\.config\fastfetch\logo.txt", "C:\Users\Pooueto\.config\fastfetch\logoURSS.txt", "C:\Users\Pooueto\.config\fastfetch\logoTheFuck.txt", "C:\Users\Pooueto\.config\fastfetch\logoSalutN.txt")

# Exécute Fastfetch avec le choix aléatoire
fastfetch --logo "$logo" --logo-color-1 black --config "C:\Users\Pooueto\Documents\config.jsonc"
#fastfetch --logo "$logo" --logo-color-1 black --config "‪C:\Users\Pooueto\.config\fastfetch\config.jsonc"


#  ██████╗██╗  ██╗ ██████╗  ██████╗ ██████╗ 
# ██╔════╝██║  ██║██╔═══██╗██╔════╝██╔═══██╗
# ██║     ███████║██║   ██║██║     ██║   ██║
# ██║     ██╔══██║██║   ██║██║     ██║   ██║
# ╚██████╗██║  ██║╚██████╔╝╚██████╗╚██████╔╝
#  ╚═════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═════╝ 
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
