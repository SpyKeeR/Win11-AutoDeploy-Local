<#
.SYNOPSIS
Script de déploiement post-installation pour Windows 11.

.DESCRIPTION
Ce script automatise et optimise le processus de post-installation de Windows 11. Il réalise les étapes suivantes lors de l'ouverture de la première session admin :
- Fermeture automatique du menu démarrer.
- Désactivation des mises en veille et extinction de l'écran pendant le déploiement.
- Vérification du succès du déploiement et détermination des chemins vers les logiciels.
- Installation silencieuse de l'EDR.
- Installation silencieuse de Microsoft Office.
- Activation de Windows via KMS interne.
- Activation de Microsoft Office.
- Boucle de Windows Update avec gestion des redémarrages jusqu'à épuisement des mises à jour.
- Création d'une boîte de dialogue pour renseigner le nom du poste.
- Nettoyage des paquetages et scripts utilisés.
- Journalisation détaillée de chaque étape dans différents fichiers.
- Gestion avancée des exceptions.

.PARAMETER
Ce script ne prend aucun paramètre spécifique.

.EXAMPLE
powershell.exe -File .\PostInstall.ps1 -ExecutionPolicy Bypass

.NOTES
Auteur : Maxime C. 'SpyKeeR'
Date de création : Septembre 2025
Sources d'inspiration : IT-Connect, ITBros, Support & Learn Microsoft, Reddit, StackOverflow, GitHub Copilot (GPT-4.1 & Claude Sonnet 4)
Ce script est libre d'accès et de modification, réalisé dans le cadre d'un titre professionnel de Technicien supérieur système et réseau.
Il répond à un besoin rencontré en milieu professionnel avant la mise en place de solutions plus robustes telles que MDT ou MECM.
Version : 1.1.0 (Anonymisation du voucher EDR et du serveur KMS)
#>

# Ajout des assemblies nécessaires pour les boîtes de dialogue
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

# Définition des variables globales
$DeployRoot = "C:\Deploy"
$WithSecureDir = Join-Path $DeployRoot "WithSecure" # Dossier contenant l'EDR
$OfficeDir = Join-Path $DeployRoot "Office" # Dossier contenant Microsoft Office
$LogDir = "C:\Windows\Setup\Logs"
$ErrorActionPreference = 'SilentlyContinue'

# Serveur KMS interne
$kmsServer = ""  # Remplacer par le serveur KMS réel

# Voucher pour l'installation de l'EDR (WithSecure)
$VOUCHER = ""  # Remplacer par le voucher réel

# Fonction d'écriture dans le journal
Function Write-Log {
    param([string]$m)
    $t = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
    $line = "$t - $m"
    $line | Out-File -FilePath (Join-Path $LogDir "postinstall.log") -Append -Encoding UTF8
}

# Fonction pour exécuter un processus en toute sécurité avec journalisation
Function Start-Safely {
    param([string]$exe, [string]$arguments)
    if ($exe -eq "msiexec.exe") { Write-Log "EXECUTION -> $exe" }
    else { Write-Log "EXECUTION -> $exe $arguments" }
    $p = Start-Process -FilePath $exe -ArgumentList $arguments -Wait -PassThru -WindowStyle Maximized
    Write-Log "FIN -> $exe ExitCode=$($p.ExitCode)"
    return $p.ExitCode
}

# Fonction pour valider un nom d'hôte
function Test-ValidHostName($name) {
    if ([string]::IsNullOrWhiteSpace($name)) { return $false }
    if ($name.Length -lt 1 -or $name.Length -gt 63) { return $false }
    if ($name -match '^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$') { return $true }
    return $false
}

## Début du script principal
Try {
    Write-Log "=== Début du déploiement PostInstall - Execution en tant que $(whoami) ==="
    # Gestion de l'alimentation pour éviter les interruptions
    powercfg -change -standby-timeout-ac 0
    powercfg -change -monitor-timeout-ac 0
    powercfg -change -disk-timeout-ac 0
    Write-Log "Paramètres d'alimentation modifiés pour désactiver veille et extinction écran."

    # Vérification de la présence du dossier de déploiement
    if (-not (Test-Path $DeployRoot)) {
        Write-Log "ERREUR: Dossier de déploiement $DeployRoot introuvable. Abandon."
        exit 3
    }
    Write-Log "Dossier de déploiement présent : $DeployRoot"

    # Installation de l'EDR (WithSecure)
    if (Test-Path $WithSecureDir) {
        Write-Log "Scan de $WithSecureDir pour les installateurs MSI..."
        $avMsi = Get-ChildItem -Path $WithSecureDir -Filter "*.msi" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($avMsi) {
            Write-Log "MSI trouvé : $($avMsi.FullName). Installation (silencieuse)..."
            $msiArgs = "/i $($avMsi.FullName) /qn VOUCHER=$VOUCHER LANGUAGE=fr"
            $rc = Start-Safely -exe "msiexec.exe" -arguments $msiArgs
            if ($rc -ne 0) { Write-Log "Warning: msiexec returned $rc for AV" }
        } else {
            Write-Log "Aucun MSI trouvé dans $WithSecureDir"
        }
    } else {
        Write-Log "Dossier $WithSecureDir non présent - installation AV ignorée."
    }

    # Fermeture du menu démarrer
    Start-Sleep -Seconds 20
    [System.Windows.Forms.SendKeys]::SendWait("{ESC}")

    # Installation de Microsoft Office
    if (Test-Path $OfficeDir) {
        Write-Log "Dossier Office trouvé : $OfficeDir"

        # Recherche de l'installateur Office (setup.exe) et du fichier de configuration ODT
        $odtSetup = Get-ChildItem -Path $OfficeDir -Filter "setup.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        $odtConfig = Get-ChildItem -Path $OfficeDir -Filter "config*.xml" -ErrorAction SilentlyContinue | Select-Object -First 1
        $mspConfig = Get-ChildItem -Path $OfficeDir -Filter "*.MSP" -ErrorAction SilentlyContinue | Select-Object -First 1

        # Installation d'Office via ODT si les deux fichiers sont présents
        if ($odtSetup -and $odtConfig) {
            Write-Log "Installateur Office : $($odtSetup.FullName) utilisant la configuration ODT $($odtConfig.FullName)"
            $odtArgs = "/configure $($odtConfig.FullName)"
            $rc = Start-Safely -exe $odtSetup.FullName -arguments $odtArgs
            if ($rc -ne 0) { Write-Log "Attention: ODT a échoué avec le code $rc" }
            else { 
                Write-Log "Installation d'Office terminée avec succès."
                reg add "HKLM\SOFTWARE\Microsoft\Office\16.0\Common\OfficeUpdate" /v EnableAutomaticUpdates /t REG_DWORD /d 1 /f
            }

            # Si ODT n'est pas disponible, tentative d'installation silencieuse avec MSP
        } else {
            if ($odtSetup -and $mspConfig) {
                Write-Log "Installateur Office : $($odtSetup.FullName). Tentative d'installation silencieuse avec MSP..."
                $mspArgs = "/adminfile $($mspConfig.FullName)"
                $rc = Start-Safely -exe $odtSetup.FullName -arguments $mspArgs
                if ($rc -ne 0) { Write-Log "Attention: Office setup a échoué avec le code $rc" }
                else { 
                    Write-Log "Installation d'Office terminée avec succès."
                    reg add "HKLM\SOFTWARE\Microsoft\Office\16.0\Common\OfficeUpdate" /v EnableAutomaticUpdates /t REG_DWORD /d 1 /f
                }
            } else {
                Write-Log "Aucun installateur Office trouvé dans $OfficeDir"
            }
        }
    } else {
        Write-Log "Dossier $OfficeDir non présent - installation Office ignorée."
    }

     # Fermeture du menu démarrer
    Start-Sleep -Seconds 10
    [System.Windows.Forms.SendKeys]::SendWait("{ESC}")

    # Activation de Windows
    if (-not [string]::IsNullOrWhiteSpace($kmsServer)) {
    # Activation de Windows via KMS
    Write-Log "Choix du type d'activation (KMS)"
    $rc = Start-Safely -exe "cscript.exe" -arguments "$env:SystemRoot\System32\slmgr.vbs /act-type 2"
    if ($rc -ne 0) { Write-Log "Attention : Slmgr /act-type a retourné $rc" }
    Start-Sleep -Seconds 3
    Write-Log "Nettoyage des serveurs KMS précédents"
    $rc = Start-Safely -exe "cscript.exe" -arguments "$env:SystemRoot\System32\slmgr.vbs /ckms"
    if ($rc -ne 0) { Write-Log "Attention : Slmgr /ckms a retourné $rc" }
    Start-Sleep -Seconds 3
    Write-Log "Configuration du serveur KMS: $kmsServer"
    $rc = Start-Safely -exe "cscript.exe" -arguments "$env:SystemRoot\System32\slmgr.vbs /skms $kmsServer"
    if ($rc -ne 0) { Write-Log "Attention : Slmgr /skms a retourné $rc" }
    } else {
        Write-Log "Aucun serveur KMS configuré - activation locale uniquement"
    }
    Start-Sleep -Seconds 3
    Write-Log "Tentative d'activation Windows"
    $rc = Start-Safely -exe "cscript.exe" -arguments "$env:SystemRoot\System32\slmgr.vbs /ato"
    if ($rc -ne 0) { Write-Log "Attention : Slmgr /ato a retourné $rc" }
    Write-Log "Activation de Windows tentée"

     # Fermeture du menu démarrer
    Start-Sleep -Seconds 10
    [System.Windows.Forms.SendKeys]::SendWait("{ESC}")

    # Activation de Microsoft Office via script dédié et tâche planifiée
    $activateScript = "C:\Deploy\ActivateOffice.ps1"
    $taskName = "ActivateOfficeOnce"
    $taskCmd = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File $activateScript"
    $schtasksCmd = "schtasks /Create /TN `"$taskName`" /TR `"$taskCmd`" /SC ONLOGON /RL HIGHEST /F /RU informatique"
    Invoke-Expression $schtasksCmd
    Write-Log "Activation Office programmée via tâche planifiée auto-suppressive."

    # Installation des mises à jour Windows (Offline) et collecte des KB
    $updateDir = "C:\Deploy\WindowsUpdates"
    $updates = Get-ChildItem -Path $updateDir -Filter *.msu -ErrorAction SilentlyContinue
    $installedKBs = @()
    
    if ($updates.Count -eq 0) {
        Write-Log "Aucune mise à jour MSU trouvée dans $updateDir"
    } else {
        Write-Log "Mises à jour MSU trouvées dans $updateDir : $($updates.Count)"
        foreach ($update in $updates) {
            Write-Log "Installation de $($update.Name)..."
            
            # Extraction du numéro KB depuis le nom de fichier
            if ($update.Name -match 'kb(\d+)') {
                $kbNumber = "KB$($matches[1])"
                $installedKBs += $kbNumber
                Write-Log "KB extrait du fichier $($update.Name): $kbNumber"
            }
            
            $rc = Start-Safely -exe "wusa.exe" -arguments "$($update.FullName) /quiet /norestart"
            if ($rc -ne 0) { Write-Log "Attention : Windows Update a retourné $rc pour $($update.Name)" }
        }
    }

    Write-Log "Installation des mises à jour hors ligne terminée. KBs installés: $($installedKBs -join ', ')"
    
    # Boucle de Windows Update avec PSWindowsUpdate
    Write-Log "Recherche et installation des mises à jour Windows via PSWindowsUpdate (2 passes)"
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
    Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue -Force

    # Préparation de la liste d'exclusion des KB déjà installés
    $excludeKBs = $installedKBs | Select-Object -Unique
    Write-Log "KBs à exclure de Windows Update: $($excludeKBs -join ', ')"

    # Boucle de 2 passes pour les mises à jour
    for ($pass = 1; $pass -le 2; $pass++) {
        Write-Log "Passe Windows Update $pass/2: Recherche des mises à jour"
        
        # Recherche avec exclusion des KBs déjà installés
        if ($excludeKBs.Count -gt 0) {
            $updates = Get-WindowsUpdate -AcceptAll -IgnoreReboot -NotKBArticleID $excludeKBs -Confirm:$false
        } else {
            $updates = Get-WindowsUpdate -AcceptAll -IgnoreReboot -Confirm:$false
        }
        
        Write-Log "Mises à jour trouvées (Passe $pass): $($updates.Count)"
        if ($updates.Count -gt 0) {
            # Installation des mises à jour trouvées
            Write-Log "Installation des mises à jour (Passe $pass)"
            if ($excludeKBs.Count -gt 0) {
                Install-WindowsUpdate -NotKBArticleID $excludeKBs -AcceptAll -IgnoreReboot -AutoReboot:$false | Out-Null
            } else {
                Install-WindowsUpdate -AcceptAll -IgnoreReboot -AutoReboot:$false | Out-Null
            }
            Write-Log "Installation des mises à jour terminée (Passe $pass)."
        } else {
            Write-Log "Aucune mise à jour à installer (Passe $pass)."
        }
        Start-Sleep -Seconds 10
    }
    Write-Log "Boucle Windows Update terminée. Poursuite du script."

    # Renommage de l'ordinateur avec interaction utilisateur
    Start-Sleep -Seconds 5
    Write-Log "Démarrage du renommage de l'ordinateur en tant que $(whoami)."

    # Vérification des droits administratifs
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        [System.Windows.Forms.MessageBox]::Show("Pour renommer l'ordinateur, vous devez être connecté en tant qu'administrateur.","Renommage requis",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        Write-Log "Utilisateur $(whoami) n'est pas admin; abandon du renommage interactif."
        break 2
    }

    # Boucle de tentatives pour le renommage
    $renameSucceeded = $false
    $maxAttempts = 3
    $restartWanted = $null
    for ($i = 1; $i -le $maxAttempts; $i++) {        
        $newName = [Microsoft.VisualBasic.Interaction]::InputBox(
        "Entrez le nouveau nom de l'ordinateur (Pattern: ADM-PO-XX):",
        "Renommage de l'ordinateur",
        "INF-PC-$((Get-Random -Minimum 0 -Maximum 99))"
        )
        Write-Log "Tentative de renommage N°$i : '$newName'"

        # Gestion des entrées vides ou annulées
        if ([string]::IsNullOrWhiteSpace($newName)) {
            $res = [System.Windows.Forms.MessageBox]::Show(
            "Vous n'avez rien saisi. Voulez-vous réessayer ?",
            "Annuler ou réessayer",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
            )
            if ($res -eq [System.Windows.Forms.DialogResult]::No) {
                Write-Log "Annulation de l'entrée utilisateur (vide). Sortie de la boucle des tentatives."
                break
            } else {
                Write-Log "L'utilisateur a choisi de réessayer après une entrée vide."
                continue
            }
        }

        # Vérification de la validité du nom d'hôte
        if (-not (Test-ValidHostName $newName)) {
            [System.Windows.Forms.MessageBox]::Show(
            "Le nom renseigné est invalide. Utilisez uniquement lettres, chiffres et '-', ne commencez/finissez pas par '-' et respecter une longueur inférieure à 63 caractères.",
            "Nom invalide",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
            Write-Log "Nom invalide tenté : '$newName'"
            continue
        }

        # Application du nouveau nom
        try {
            Write-Log "Essai de redéfinition du nom d'hôte '$newName'"
            Rename-Computer -NewName $newName -Force -ErrorAction Stop -PassThru | Out-Null
            Write-Log "Renommage réussi en '$newName'"
            $renameSucceeded = $true
            
            # Confirmation et demande de redémarrage
            $mb = [System.Windows.Forms.MessageBox]::Show(
            "Le nom a été appliqué : $newName`nSouhaitez-vous redémarrer après le déploiement pour appliquer ce changement ?",
            "Redémarrage requis",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
            )

            # Gestion de la réponse utilisateur
            if ($mb -eq [System.Windows.Forms.DialogResult]::Yes) {
                Write-Log "L'utilisateur a choisi un redémarrage. Planification du redémarrage à la fin du script"
                $restartWanted = $true
                Write-Log "Redémarrage planifié en fin de déploiement."
            } else {
                $restartWanted = $false
                Write-Log "L'utilisateur a choisi de ne pas redémarrer maintenant. Poursuite des étapes restantes."
            }
            break    
        } catch {
            # Gestion des erreurs de renommage
            Write-Log "ERREUR renommage échoué : $($_.Exception.Message) ; tentative $i"
            [System.Windows.Forms.MessageBox]::Show(
            "Erreur lors du renommage : $($_.Exception.Message)",
            "Erreur",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
            continue
        }
    }

    # Gestion de l'échec après le nombre maximal de tentatives
    if (-not $renameSucceeded) {
        [System.Windows.Forms.MessageBox]::Show(
        "Nombre maximal de tentatives atteint (ou opération annulée). Le renommage n'a pas été effectué.",
        "Echec",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Stop
        ) | Out-Null
        Write-Log "Nombre maximal de tentatives atteint ou opération annulée - renommage non appliqué."
    }

    # Gestion du redémarrage
    if ($restartWanted) {
        $comment = "Redemarrage dans 5 secondes pour finaliser le deploiement."
        $shutdownArgs = "/r /t 5 /c `"$comment`""
        $rc = Start-Safely -exe (Join-Path $env:SystemRoot "system32\shutdown.exe") -arguments $shutdownArgs
        if ($rc -ne 0) { Write-Log "Attention : le redemarrage a echoue avec le code $rc" }
    } else {
        Write-Log "Aucun redemarrage planifié. Le renommage (si effectué) sera appliqué au prochain redémarrage manuel."
    }

    # Restauration des paramètres d'alimentation
    powercfg -change -standby-timeout-ac 30
    powercfg -change -monitor-timeout-ac 10
    powercfg -change -disk-timeout-ac 20
    Write-Log "=== Fin du déploiement PostInstall avec succès ==="
    exit 0
} Catch {
    # Gestion des exceptions globales
    Write-Log "ERREUR: $($_.Exception.Message)"
    Write-Log "STACKTRACE: $($_.Exception.StackTrace)"
    Write-Log "=== Fin du déploiement PostInstall avec des erreurs ==="
    exit 20
}