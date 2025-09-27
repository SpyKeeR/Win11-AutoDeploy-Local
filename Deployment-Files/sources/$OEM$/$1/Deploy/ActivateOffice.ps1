<#
.SYNOPSIS
Active Microsoft Office 2016 par différents moyens (KMS/MAK) et automatise le nettoyage post-déploiement.

.DESCRIPTION
Ce script permet d'activer Microsoft Office 2016 en utilisant soit une clé KMS, soit une clé MAK. Il offre également la possibilité de créer une tâche planifiée qui s'exécutera pour supprimer le script lui-même ainsi que les fichiers résiduels du déploiement initial et le cache de Windows Update, assurant ainsi un environnement propre après l'activation.

.PARAMETER <ParameterName>
Spécifie les paramètres nécessaires pour choisir la méthode d'activation (KMS ou MAK), fournir la clé, et configurer la suppression automatique.

.EXAMPLE
.\powershell.exe -ExecutionPolicy Bypass -File ActivateOffice.ps1

.NOTES
Auteur : Maxime C. 'SpyKeeR'
Date : Septembre 2025
Version : 1.0
#>

# Configuration du script
$LogDir = "C:\Windows\Setup\Logs"
$ErrorActionPreference = "SilentlyContinue"

# Fonction de journalisation
Function Write-LogActOffice {
    param([string]$m)
    $t = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
    $line = "$t - $m"
    $line | Out-File -FilePath (Join-Path $LogDir "officeAct-CleanupDeploy.log") -Append -Encoding UTF8
}

# Attendre 30 secondes pour s'assurer que le contexte utilisateur et installation MAJ soit bien en place
Start-Sleep -Seconds 30

# Ouvre Word en arrière-plan pour initialiser les services Office
if (Test-Path "$env:ProgramFiles\Microsoft Office\Office16\WINWORD.EXE") {
    $wordProc = Start-Process "$env:ProgramFiles\Microsoft Office\Office16\WINWORD.EXE" -WindowStyle Hidden -PassThru
    Start-Sleep -Seconds 10
    # Ferme Word proprement
    Stop-Process -Id $wordProc.Id -Force
}

# Début du script
Write-LogActOffice "=== Début de l'activation d'Office ==="

# Recherche du script ospp.vbs
$osppPaths = @(
"$env:ProgramFiles\Microsoft Office\Office16\ospp.vbs",
"$env:ProgramFiles(x86)\Microsoft Office\Office16\ospp.vbs"
)
$ospp = $null
foreach ($p in $osppPaths) {
    if (Test-Path $p) { $ospp = $p; break }
}

# Tentative d'activation
if ($ospp) {
    Write-LogActOffice "Ospp trouvé à $ospp - tentative d'activation Office MAK"
    Write-LogActOffice "Activation de la clé de produit Office via ospp.vbs"
    cscript.exe $ospp /act
    Write-LogActOffice "Essai d'activation Office terminé"
} else {
    Write-LogActOffice "ospp.vbs n'as pas été trouvé - Office est peut-être Click-to-Run ou pas encore installé"
}

# Suppression de la tâche ActivateOfficeOnce
Start-Process -FilePath "schtasks.exe" -ArgumentList "/Delete", "/TN", "ActivateOfficeOnce", "/F" -NoNewWindow
Write-LogActOffice "Tâche ActivateOfficeOnce supprimée."

# Nettoyage Windows Update
Start-Process -FilePath "Dism.exe" -ArgumentList "/Online", "/Cleanup-Image", "/StartComponentCleanup", "/ResetBase" -WindowStyle Normal
Write-LogActOffice "Nettoyage du cache Windows Update terminé."

# Analyse et réparation des fichiers système
Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -WindowStyle Normal
Write-LogActOffice "Analyse SFC terminée."

# Création de la tâche planifiée pour exécuter le script de nettoyage
schtasks /Create /TN "CleanupPostInstall" /TR "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"C:\Windows\Setup\Scripts\CleanupPostInstall.ps1`"" /SC ONCE /ST $(Get-Date -Format "HH:mm" | ForEach-Object { (Get-Date).AddMinutes(1).ToString("HH:mm") }) /RL HIGHEST /F /RU informatique
Write-LogActOffice "Tâche planifiée CleanupPostInstall créée pour exécution dans 1 minute."
Write-LogActOffice "=== Fin du post-deploiement et Nettoyage ==="