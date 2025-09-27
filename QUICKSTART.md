# Guide de démarrage rapide - Win11-AutoDeploy-Local

## 🚀 Démarrage en 4 étapes simples

### 📥 1. Préparation (10 minutes)

1. **Téléchargez une ISO Windows 11** officielle (22H2+)
2. **Créez une clé USB bootable** avec Media Creation Tool ou Rufus
3. **Téléchargez ce projet** et extrayez-le

### ⚙️ 2. Configuration obligatoire (15 minutes)

#### **Personnalisez `Deployment-Files/autounattend.xml` :**

```xml
<!-- REMPLACEZ ces valeurs (2 endroits dans le fichier) -->
<Key>YOURWINDOWSPRODUCTKEY</Key>  → Votre clé Windows 11

<!-- Compte admin local -->
<Name>YOURLOCALADMIN-ACCOUNTNAME</Name>  → Nom de votre admin (ex: admin)

<!-- Mot de passe admin (encodé UTF-16LE + Base64 OU en clair) -->
<Value>YQBkAG0AaQBuAFAAYQBzAHMAdwBvAHIAZAA=</Value>  → Votre mot de passe encodé
<PlainText>false</PlainText>  → true si mot de passe en clair
```

**💡 Encoder votre mot de passe :**
```powershell
$Text = "VotreMotDePassePassword"    # IMPORTANT : Suffixer avec "Password"
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($Text)
$EncodedText = [Convert]::ToBase64String($Bytes)
$EncodedText
```

#### **Personnalisez `Deployment-Files/sources/$OEM$/$1/Deploy/PostInstall.ps1` :**

```powershell
# Ligne ~35 : Serveur KMS (ou laissez vide si pas de KMS)
$kmsServer = "votre-serveur-kms.local"

# Ligne ~38 : Licence WithSecure (ou laissez vide si pas d'EDR)
$VOUCHER = "XXXX-XXXX-XXXX-XXXX-XXXX"
```

#### **WiFi automatique (optionnel) :**

Si vous voulez une connexion WiFi automatique, configurez **`Deployment-Files/sources/$OEM$/$1/Deploy/Wifi.xml`** :

```xml
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
  <name>YOURWIFINAME</name>           <!-- Nom affiché dans Windows -->
  <SSIDConfig>
    <SSID>
      <hex>SSIDINHEXADECIMAL</hex>    <!-- SSID converti en hex -->
      <name>YOURWIFISSID</name>       <!-- Nom réel du réseau WiFi -->
    </SSID>
  </SSIDConfig>
  <keyMaterial>YOURWIFIPASSWORDINCLEAR</keyMaterial>  <!-- Mot de passe WiFi -->
</WLANProfile>
```
Il est aussi possible d'exporter un profil WiFi depuis une machine Windows déjà connectée :
```powershell
netsh wlan export profile name="YOURWIFINAME" folder="C:\Path\To\Deployment-Files\sources\$OEM$\$1\Deploy\" key=clear
```

**📋 À remplacer :**
- `YOURWIFINAME` → Nom affiché (ex: "Bureau")
- `SSIDINHEXADECIMAL` → SSID en hexadécimal ([convertisseur en ligne](https://string-functions.com/string-hex.aspx))
- `YOURWIFISSID` → Nom du réseau WiFi réel
- `YOURWIFIPASSWORDINCLEAR` → Mot de passe WiFi en clair

**⚠️ Important :** Dans `autounattend.xml` ligne 343, le nom doit correspondre exactement à celui de `Wifi.xml`

### 📂 3. Alimentation des dossiers (optionnel)

**Ajoutez vos logiciels dans `Deployment-Files/sources/$OEM$/$1/Deploy/` :**

- **📁 Office/** : Installation Office 2016/365 (voir README du dossier)
- **📁 WindowsUpdates/** : Fichiers .msu du catalogue Microsoft
- **📁 WithSecure/** : Agent EDR (voir README du dossier)

### 🚀 4. Déploiement - Deux méthodes

#### **Méthode 1 : Clé USB** (Recommandée - Plus simple)

1. **Copiez TOUT le contenu** de `Deployment-Files/` à la **racine** de votre clé USB
2. **Vérifiez** que `autounattend.xml` est bien à la racine de la clé
3. **Bootez** sur la clé USB
4. **L'installation démarre automatiquement** ✨

#### **Méthode 2 : ISO personnalisée** (Avancée)

1. **Installer Windows ADK**
   ```powershell
   # Téléchargez Windows ADK depuis Microsoft
   # Installez au minimum "Deployment Tools"
   ```

2. **Extraire l'ISO Windows 11**
   ```powershell
   # Montez l'ISO et copiez vers dossier temporaire
   Mount-DiskImage -ImagePath "C:\chemin\Windows11.iso"
   Copy-Item E:\* C:\Temp\Win11Source\ -Recurse -Force
   ```

3. **Intégrer le projet**
   ```DOS
   # Copiez 'Deployment-Files/' dans 'C:\Temp\Win11Source\'
   # Personnalisez selon checklist ci-dessus
   ```

4. **Créer la nouvelle ISO**
   ```DOS
   # Depuis invite admin avec Windows ADK installé
   oscdimg.exe -m -o -u2 -udfver102 ^
   -bootdata:2#p0,e,b"C:\Temp\Win11Source\boot\etfsboot.com"#pEF,e,b"C:\Temp\Win11Source\efi\microsoft\boot\efisys.bin" ^
   "C:\Temp\Win11Source" "C:\AutoDeploy-Win11.iso"
   ```

## ⏱️ Déroulement automatique

| Étape | Durée | Description |
|-------|-------|-------------|
| 🔄 Installation Windows | 15-20 min | Partitionnement + installation automatique |
| 🧹 Optimisation système | 5 min | Suppression apps inutiles, nettoyage |
| 📦 Installation logiciels | 10-15 min | Office, EDR, pilotes WiFi |
| 🔐 Activation Windows | 2-3 min | Windows via KMS |
| 🔄 Windows Update | 15-30 min | Mises à jour automatiques |
| 💻 Nom du poste | 1 min | **SEULE INTERACTION** : saisie du nom et redémarrage |
| 🔐 Activation Office | 2-3 min | Office via KMS/MAK |
| 🧹 Nettoyage final | 2 min | Suppression des fichiers temporaires |

**⏱️ Durée totale : 45-75 minutes selon le matériel**

## ✅ Vérification rapide

Après déploiement, vérifiez :

```powershell
# Activation Windows
slmgr /xpr

# Services en cours
Get-Service -Name "*secure*"  # EDR
Get-Service -Name "*office*"  # Office

# Logs de déploiement
Get-Content "C:\Windows\Setup\Logs\postinstall.log"
```

## 📋 Structure finale sur la clé USB

```
USB:\ (Racine de la clé)
├── autounattend.xml              ← OBLIGATOIRE à la racine
├── bootmgr, setup.exe, etc.     ← Fichiers Windows existants
├── $WinPEDriver$/                ← Pilotes WiFi
├── efi/microsoft/boot/           ← Boot sans prompt
│   ├── efisys.bin               ← Remplace l'original
│   └── cdboot.efi               ← Remplace l'original  
└── sources/
    ├── install.wim, etc.        ← Fichiers Windows existants
    └── $OEM$/$1/Deploy/         ← Scripts et logiciels
```

## 🆘 Dépannage express

| Problème | Solution |
|----------|----------|
| **L'installation ne démarre pas** | Vérifiez que `autounattend.xml` est à la racine |
| **Erreur de clé Windows** | Vérifiez la clé dans autounattend.xml (2 endroits) |
| **Pas de WiFi** | Vérifiez les pilotes dans `$WinPEDriver$/Wifi/` |
| **Office ne s'installe pas** | Vérifiez le contenu du dossier `Office/` |
| **EDR ne s'installe pas** | Vérifiez le voucher dans PostInstall.ps1 et le log de PostInstall |

## ✅ Validation avant déploiement

### 📋 Checklist finale :
- [ ] **autounattend.xml** personnalisé et à la racine de la clé USB
- [ ] **PostInstall.ps1** avec vos paramètres KMS/EDR
- [ ] **Dossiers logiciels** alimentés selon vos besoins (Office, Updates, EDR)
- [ ] **WiFi configuré** si nécessaire
- [ ] **Test sur machine de développement** effectué

## 📞 Support complet

- ❌ **Dépannage complet** : [docs/troubleshooting.md](docs/troubleshooting.md) 
- ❓ **Questions fréquentes** : [docs/faq.md](docs/faq.md)

---

**🎉 Votre solution Win11-AutoDeploy-Local est prête !**  
**⏱️ Temps de déploiement : 45-75 minutes selon matériel**