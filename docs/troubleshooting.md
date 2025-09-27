# Guide de dépannage - Win11-AutoDeploy-Local

## Problèmes courants et solutions

### 1. L'installation ne démarre pas automatiquement

#### **Symptômes :**
- L'installation Windows démarre normalement (avec interactions)
- Le fichier `autounattend.xml` semble ignoré

#### **Causes possibles :**
- `autounattend.xml` pas à la racine du support
- Fichier XML malformé ou encodage incorrect
- Support mal préparé

#### **Solutions :**
```powershell
# Vérifier la syntaxe XML
[xml]$xml = Get-Content "autounattend.xml"
# Si erreur : corriger la syntaxe XML

# Vérifier l'encodage (doit être UTF-8)
Get-Content "autounattend.xml" -Encoding UTF8 | Set-Content "autounattend_fixed.xml" -Encoding UTF8
```

### 2. Erreur de clé de produit Windows
```powershell
# Vérification TPM 2.0
Get-Tpm

# Vérification UEFI
$env:firmware_type

# Vérification Secure Boot
Confirm-SecureBootUEFI
```

## ❌ Problèmes d'installation

### Problème : L'installation ne démarre pas automatiquement

#### Symptômes
- Windows démarre normalement sans utiliser autounattend.xml
- Écran de sélection de langue apparaît

#### Causes possibles
1. **Fichier autounattend.xml mal placé ou corrompu**
2. **Encodage incorrect du fichier XML**
3. **Syntaxe XML invalide**

#### Solutions

**Solution 1 : Vérification de l'emplacement**
```cmd
# Le fichier doit être EXACTEMENT à la racine de la clé USB
dir X:\autounattend.xml
```

**Solution 2 : Vérification de l'encodage**
```powershell
# Le fichier doit être en UTF-8 sans BOM
$content = Get-Content "X:\autounattend.xml" -Raw -Encoding UTF8
$content | Set-Content "X:\autounattend.xml" -Encoding UTF8
```

**Solution 3 : Validation XML**
```powershell
try {
    [xml]$xml = Get-Content "X:\autounattend.xml"
    Write-Host "XML valide" -ForegroundColor Green
} catch {
    Write-Host "Erreur XML : $($_.Exception.Message)" -ForegroundColor Red
}
```

### Problème : Installation s'arrête pendant la copie de fichiers

#### Symptômes
- Installation s'arrête entre 20-40%
- Message d'erreur sur les pilotes

#### Causes possibles
1. **Pilotes manquants ou incompatibles**
2. **Problème de lecture de la clé USB**
3. **Matériel non supporté**

#### Solutions

**Solution 1 : Vérification des pilotes**
```powershell
# Lister les périphériques sans pilotes
Get-WmiObject -Class Win32_PnPEntity | Where-Object {$_.ConfigManagerErrorCode -ne 0}
```

**Solution 2 : Test de la clé USB**
```cmd
# Test de lecture/écriture
chkdsk X: /f /r
```

### Problème : Écran bleu (BSOD) pendant l'installation

#### Codes d'erreur courants
- **0x000000F4** : CRITICAL_OBJECT_TERMINATION
- **0x0000007B** : INACCESSIBLE_BOOT_DEVICE
- **0x000000A5** : ACPI_BIOS_ERROR

#### Solutions

**Pour 0x0000007B :**
```
1. Vérifier le mode SATA dans le BIOS (AHCI vs IDE)
2. Ajouter les pilotes de stockage dans $OEMDrivers$
3. Désactiver temporairement Secure Boot
```

**Pour 0x000000A5 :**
```
1. Mettre à jour le BIOS
2. Vérifier la compatibilité UEFI
3. Réinitialiser les paramètres BIOS aux valeurs par défaut
```

## 🔄 Problèmes de post-installation

### Problème : PostInstall.ps1 ne s'exécute pas

#### Symptômes
- Premier démarrage normal mais pas de déploiement automatique
- Aucun log dans C:\Windows\Setup\Logs\

#### Diagnostic
```powershell
# Vérification de la politique d'exécution
Get-ExecutionPolicy -List

# Vérification de la présence du script
Test-Path "C:\Deploy\PostInstall.ps1"

# Vérification des tâches planifiées
Get-ScheduledTask | Where-Object {$_.TaskName -like "*Office*"}
```

#### Solutions

**Solution 1 : Politique d'exécution**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force
```

**Solution 2 : Lancement manuel pour test**
```powershell
cd C:\Deploy
.\PostInstall.ps1 -Verbose
```

**Solution 3 : Vérification des permissions**
```powershell
$acl = Get-Acl "C:\Deploy\PostInstall.ps1"
$acl.Access
```

### Problème : Échec d'activation Windows/Office

#### Symptômes
- Messages "Windows n'est pas activé"
- Office demande une activation

#### Diagnostic
```powershell
# Statut d'activation Windows
slmgr /dlv

# Statut d'activation Office
cd "C:\Program Files\Microsoft Office\Office16"
cscript OSPP.VBS /dstatus

# Test de connectivité KMS
Test-NetConnection -ComputerName "votre-kms-server" -Port 1688
```

#### Solutions

**Solution 1 : Problème réseau**
```powershell
# Vérification DNS
nslookup votre-kms-server

# Test de connectivité
telnet votre-kms-server 1688
```

**Solution 2 : Configuration KMS incorrecte**
```powershell
# Réinitialisation de l'activation Windows
slmgr /ipk VOTRE-CLE-WINDOWS
slmgr /skms votre-kms-server
slmgr /ato

# Réinitialisation de l'activation Office
cd "C:\Program Files\Microsoft Office\Office16"
cscript OSPP.VBS /inpkey:VOTRE-CLE-OFFICE
cscript OSPP.VBS /sethst:votre-kms-server
cscript OSPP.VBS /act
```

### Problème : Windows Update ne fonctionne pas

#### Symptômes
- Échec de recherche des mises à jour
- Erreurs lors de l'installation des .msu

#### Diagnostic
```powershell
# Vérification du service Windows Update
Get-Service -Name wuauserv

# Vérification de l'agent Windows Update
Get-WmiObject -Class Win32_QuickFixEngineering | Sort-Object InstalledOn -Descending | Select-Object -First 10

# Test du module PSWindowsUpdate
Import-Module PSWindowsUpdate
Get-WUList
```

#### Solutions

**Solution 1 : Réinitialisation Windows Update**
```powershell
Stop-Service -Name wuauserv, cryptsvc, bits, msiserver -Force
Remove-Item -Path "$env:WINDIR\SoftwareDistribution" -Recurse -Force
Remove-Item -Path "$env:WINDIR\System32\catroot2" -Recurse -Force
Start-Service -Name wuauserv, cryptsvc, bits, msiserver
```

**Solution 2 : Installation manuelle des .msu**
```powershell
$MSUFiles = Get-ChildItem "C:\Deploy\WindowsUpdates\*.msu"
ForEach ($MSU in $MSUFiles) {
    Write-Host "Installation de $($MSU.Name)..."
    $Result = Start-Process -FilePath "wusa.exe" -ArgumentList "$($MSU.FullName)", "/quiet", "/norestart" -Wait -PassThru
    if ($Result.ExitCode -eq 0) {
        Write-Host "Succès" -ForegroundColor Green
    } else {
        Write-Host "Échec (Code: $($Result.ExitCode))" -ForegroundColor Red
    }
}
```

## 🌐 Problèmes réseau

### Problème : Pas de connectivité WiFi

#### Symptômes
- Aucun adaptateur WiFi détecté
- Impossible de se connecter au réseau WiFi configuré

#### Diagnostic
```powershell
# Lister les adaptateurs réseau
Get-NetAdapter

# Vérifier les pilotes WiFi
Get-WmiObject -Class Win32_NetworkAdapter | Where-Object {$_.Name -like "*Wireless*" -or $_.Name -like "*WiFi*"}

# Vérifier les profils WiFi
netsh wlan show profiles
```

#### Solutions

**Solution 1 : Installation manuelle des pilotes**
```powershell
# Identifier le matériel WiFi
Get-WmiObject -Class Win32_PnPEntity | Where-Object {$_.Name -like "*Wireless*" -and $_.ConfigManagerErrorCode -ne 0}

# Installation forcée depuis $OEMDrivers$
pnputil.exe /add-driver "X:\$OEMDrivers$\Network\Intel\*.inf" /subdirs /install
```

**Solution 2 : Configuration manuelle du profil WiFi**
```powershell
# Suppression de l'ancien profil
netsh wlan delete profile name="VOTRE-SSID"

# Ajout du nouveau profil
$ProfileXML = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>VOTRE-SSID</name>
    <SSIDConfig>
        <SSID>
            <name>VOTRE-SSID</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>VOTRE-MOT-DE-PASSE</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>
"@

$ProfileXML | Out-File -FilePath "$env:TEMP\wifi.xml" -Encoding UTF8
netsh wlan add profile filename="$env:TEMP\wifi.xml"
netsh wlan connect ssid="VOTRE-SSID"
```

## 📱 Problèmes d'applications

### Problème : Office ne s'installe pas

#### Symptômes
- Installation d'Office échoue silencieusement
- Office partiellement installé

#### Diagnostic
```powershell
# Vérification de l'installation Office
Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*Office*"}

# Vérification de l'espace disque
Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, @{Name="Size(GB)";Expression={[math]::Round($_.Size/1GB,2)}}, @{Name="FreeSpace(GB)";Expression={[math]::Round($_.FreeSpace/1GB,2)}}
```

#### Solutions

**Solution 1 : Installation manuelle**
```powershell
cd "C:\Deploy\Office"
.\setup.exe /configure configuration.xml
```

**Solution 2.1 : Nettoyage et réinstallation Office Click-2-Run**
```powershell
# Suppression complète d'Office
cd "C:\Deploy\Office"
.\setup.exe /configure uninstall.xml

# Nettoyage du registre
Remove-Item "HKLM:\SOFTWARE\Microsoft\Office" -Recurse -Force -ErrorAction SilentlyContinue

# Réinstallation
.\setup.exe /configure configuration.xml
```
**Solution 2.2 : Nettoyage et réinstallation Office MSI**
```powershell
# Suppression complète d'Office
cd "C:\Deploy\Office"
.\setup.exe /uninstall

# Nettoyage du registre
Remove-Item "HKLM:\SOFTWARE\Microsoft\Office" -Recurse -Force -ErrorAction SilentlyContinue

# Réinstallation
.\setup.exe /adminfile AutoInstallOffice.MSP
```

## 🔒 Problèmes de sécurité

### Problème : EDR ne s'installe pas

#### Symptômes
- Agent EDR absent du système
- Pas de protection en temps réel

#### Diagnostic
```powershell
# Vérification des services de sécurité
Get-Service | Where-Object {$_.Name -like "*Secure*" -or $_.Name -like "*Defend*"}

# Vérification des processus
Get-Process | Where-Object {$_.ProcessName -like "*fsaua*" -or $_.ProcessName -like "*WithSecure*"}
```

#### Solutions

**Solution 1 : Installation manuelle**
```powershell
cd "C:\Deploy\WithSecure"
.\ElementsAgentOfflineInstaller.msi /VOUCHER=XXXX-XXXX /quiet
```

**Solution 2 : Vérification des prérequis**
```powershell
# Vérification de .NET Framework
Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" -Name Release

# Installation des prérequis si nécessaire
# Télécharger et installer .NET Framework 4.8
```

## 🛠️ Outils de diagnostic

### Script de diagnostic complet

```powershell
# ===== DIAGNOSTIC AUTODEPLOY WIN11 =====

Function Get-DeploymentDiagnostic {
    $Diagnostic = @{}
    
    # Informations système
    $Diagnostic.System = @{
        ComputerName = $env:COMPUTERNAME
        OS = (Get-WmiObject -Class Win32_OperatingSystem).Caption
        Version = (Get-WmiObject -Class Win32_OperatingSystem).Version
        Architecture = (Get-WmiObject -Class Win32_OperatingSystem).OSArchitecture
        LastBootTime = (Get-WmiObject -Class Win32_OperatingSystem).ConvertToDateTime((Get-WmiObject -Class Win32_OperatingSystem).LastBootUpTime)
    }
    
    # Activation
    $Diagnostic.Activation = @{
        Windows = (Get-CimInstance -ClassName SoftwareLicensingProduct | Where-Object {$_.PartialProductKey}).LicenseStatus
        Office = "Non testé" # Nécessite Office installé
    }
    
    # Réseau
    $Diagnostic.Network = @{
        Adapters = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).Count
        InternetConnectivity = Test-NetConnection -ComputerName "8.8.8.8" -InformationLevel Quiet
        DNS = Test-NetConnection -ComputerName "google.com" -InformationLevel Quiet
    }
    
    # Applications
    $Diagnostic.Applications = @{
        Office = [bool](Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*Office*"})
        EDR = [bool](Get-Service | Where-Object {$_.Name -like "*Secure*" -and $_.Status -eq "Running"})
    }
    
    # Logs
    $Diagnostic.Logs = @{
        PostInstallExists = Test-Path "C:\Windows\Setup\Logs\PostInstall.log"
        LastLogEntry = if (Test-Path "C:\Windows\Setup\Logs\PostInstall.log") { 
            (Get-Content "C:\Windows\Setup\Logs\PostInstall.log" -Tail 1) 
        } else { 
            "Fichier de log non trouvé" 
        }
    }
    
    return $Diagnostic
}

# Exécution du diagnostic
$Results = Get-DeploymentDiagnostic
$Results | ConvertTo-Json -Depth 3 | Out-File "C:\Windows\Setup\Logs\Diagnostic.json"
Write-Output $Results
```

### Commandes de dépannage rapide

```powershell
# Réinitialisation rapide du déploiement
Function Reset-Deployment {
    Write-Host "Réinitialisation du déploiement..." -ForegroundColor Yellow
    
    # Arrêt des services liés
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    
    # Nettoyage des logs
    Remove-Item "C:\Windows\Setup\Logs\*" -Force -ErrorAction SilentlyContinue
    
    # Relance du script principal
    Set-Location "C:\Deploy"
    .\PostInstall.ps1 -Force
}

# Test de connectivité complet
Function Test-AllConnectivity {
    $Tests = @(
        @{Name="Internet"; Target="8.8.8.8"},
        @{Name="DNS"; Target="google.com"},
        @{Name="KMS"; Target="votre-kms-server"},
        @{Name="EDR"; Target="votre-serveur-edr.com"}
    )
    
    ForEach ($Test in $Tests) {
        $Result = Test-NetConnection -ComputerName $Test.Target -InformationLevel Quiet
        $Status = if ($Result) { "OK" } else { "ÉCHEC" }
        $Color = if ($Result) { "Green" } else { "Red" }
        Write-Host "$($Test.Name): $Status" -ForegroundColor $Color
    }
}
```

---

**⚠️ Important** : En cas de problème persistant, consultez les logs détaillés dans `C:\Windows\Setup\Logs\` et n'hésitez pas à ouvrir une issue sur le dépôt GitHub avec les informations de diagnostic.