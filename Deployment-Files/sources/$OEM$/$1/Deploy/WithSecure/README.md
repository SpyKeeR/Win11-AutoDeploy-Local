# 📁 Dossier WithSecure

Ce dossier contient l'agent EDR (Endpoint Detection and Response) WithSecure pour la sécurité des postes.

## 🛡️ À propos de WithSecure

WithSecure (anciennement F-Secure Business) est une solution EDR qui protège les postes contre :
- 🦠 **Malwares et ransomwares** avancés
- 🔍 **Détection comportementale** des menaces
- 🛡️ **Protection en temps réel** des processus
- 📊 **Monitoring et reporting** centralisés

## 📦 Fichiers attendus

### Pour WithSecure :
```
WithSecure/
├── fsaua.exe                    # Installateur WithSecure (si disponible en .exe)
└── [ou]
├── WithSecure-Agent.msi         # Installateur WithSecure (si disponible en .msi)
└── license.txt                  # Informations de licence (optionnel)
```

## 🔑 Configuration requise

Dans le fichier `PostInstall.ps1`, configurez votre voucher/licence :

```powershell
# Ligne ~38 dans PostInstall.ps1
$VOUCHER = "XXXX-XXXX-XXXX-XXXX-XXXX"  # Remplacer par votre vraie licence WithSecure
```

## 🔧 Adaptation pour un autre EDR

Si vous utilisez un autre EDR que WithSecure, modifiez le bloc d'installation dans `PostInstall.ps1` (lignes 94-108) :

### Exemple pour Crowdstrike :
```powershell
# Recherche de l'installateur Crowdstrike
$crowdstrikeDir = Join-Path $DeployRoot "Crowdstrike"
if (Test-Path $crowdstrikeDir) {
    $csInstaller = Get-ChildItem -Path $crowdstrikeDir -Filter "*.exe" -Recurse | Select-Object -First 1
    if ($csInstaller) {
        $arguments = "/install /quiet /norestart CID=YOUR-CUSTOMER-ID"
        $rc = Start-Safely -exe $csInstaller.FullName -arguments $arguments
    }
}
```

### Exemple pour SentinelOne :
```powershell
# Recherche de l'installateur SentinelOne
$sentinelDir = Join-Path $DeployRoot "SentinelOne"
if (Test-Path $sentinelDir) {
    $s1Installer = Get-ChildItem -Path $sentinelDir -Filter "*.msi" -Recurse | Select-Object -First 1
    if ($s1Installer) {
        $arguments = "/quiet SITE_TOKEN=YOUR-SITE-TOKEN"
        $rc = Start-Safely -exe "msiexec.exe" -arguments "/i `"$($s1Installer.FullName)`" $arguments"
    }
}
```

## 🔄 Fonctionnement automatique

Le script `PostInstall.ps1` :

1. **Scanne ce dossier** pour les fichiers .msi ou .exe
2. **Installe automatiquement** l'agent EDR trouvé
3. **Utilise le voucher** configuré dans le script
4. **Journalise l'installation** dans les logs
5. **Vérifie le démarrage** du service après installation

## 📋 Journal d'installation

L'installation est journalisée dans :
- `C:\Windows\Setup\Logs\postinstall.log`

Exemple de log :
```
25-09-2025 14:15:30 - Scan de C:\Deploy\WithSecure pour les installateurs MSI...
25-09-2025 14:15:31 - Installateur EDR trouvé : fsaua.exe
25-09-2025 14:15:32 - EXECUTION -> C:\Deploy\WithSecure\fsaua.exe /VERYSILENT /VOUCHER=XXXX-XXXX
25-09-2025 14:18:45 - FIN -> fsaua.exe ExitCode=0
25-09-2025 14:18:46 - Agent EDR installé avec succès
```

## 🔍 Vérification post-installation

Pour vérifier l'installation de l'agent :

```powershell
# Vérifier les services WithSecure
Get-Service -Name "*secure*" -ErrorAction SilentlyContinue

# Vérifier les processus WithSecure
Get-Process -Name "*secure*" -ErrorAction SilentlyContinue

# Vérifier l'installation via le registre
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object {$_.DisplayName -like "*WithSecure*"}
```

## ⚠️ Important

### ✅ Prérequis :
- **Licence valide** WithSecure ou autre EDR
- **Connectivité réseau** vers les serveurs de management
- **Droits administrateurs** pour l'installation

### 🔧 Personnalisation :
- Adaptez le dossier et le script selon votre solution EDR
- Modifiez les arguments d'installation selon votre EDR
- Configurez les paramètres de politique si nécessaire

### 🛡️ Sécurité :
- Ne committez jamais les vraies licences dans le code
- Utilisez des variables d'environnement ou fichiers de config séparés
- Anonymisez les informations sensibles avant partage

---

**💡 Conseil** : Testez l'installation manuelle de votre agent EDR avant de l'automatiser dans le script.