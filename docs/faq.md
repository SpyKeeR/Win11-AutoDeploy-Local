# FAQ - Win11-AutoDeploy-Local

## ❓ Questions fréquemment posées

### 🔧 Questions générales

#### **Q : Combien de temps prend le déploiement complet ?**
**R :** Entre 45 et 75 minutes selon le matériel :
- Installation Windows : 15-20 minutes
- Applications et configuration : 15-25 minutes  
- Windows Update : 15-30 minutes (selon les MAJ disponibles)

#### **Q : Quelle est la seule interaction utilisateur requise ?**
**R :** La saisie du nom du poste de travail dans une boîte de dialogue vers la fin du processus. Tout le reste est automatique.

#### **Q : Puis-je utiliser ce projet sans serveur KMS ?**
**R :** Oui, laissez simplement la variable `$kmsServer` vide dans PostInstall.ps1. Vous devrez activer Windows manuellement après l'installation.

#### **Q : Puis-je utiliser ce projet avec une version autre que Windows 11 ?**
**R :** Théoriquement oui, mais ce projet est optimisé pour Windows 11. Pour d'autres versions, des ajustements dans autounattend.xml et les scripts peuvent être nécessaires.

#### **Q : Puis-je faire évoluer ce projet avec un ISO de Windows 11 plus récent ?**
**R :** Oui, la procédure reste la même. Il suffira simplement de préparer un nouvel ISO ou clé USB en suivant les instructions du guide de démarrage rapide [QUICKSTART.md](../QUICKSTART.md) avec vos fichiers du projet configuré pour le précédent ISO.

### 🔑 Questions sur la configuration

#### **Q : Comment encoder mon mot de passe administrateur ?**
**R :** Deux méthodes :
```powershell
# Méthode PowerShell
$Text = "VotreMotDePasse"
$Bytes = [System.Text.Encoding]::Unicode.GetBytes($Text)
$EncodedText = [Convert]::ToBase64String($Bytes)
$EncodedText
```
Ou utilisez CyberChef : UTF-16LE puis Base64

#### **Q : Puis-je utiliser un mot de passe en clair ?**
**R :** Oui, dans autounattend.xml :
```xml
<Value>VotreMotDePasseEnClair</Value>
<PlainText>true</PlainText>
```

#### **Q : Comment convertir mon SSID WiFi en hexadécimal ?**
**R :** Utilisez PowerShell :
```powershell
$ssid = "MonReseauWiFi"
$hex = [System.Text.Encoding]::UTF8.GetBytes($ssid) | ForEach-Object { $_.ToString("X2") }
$hex -join ""
```
Ou un [convertisseur en ligne](https://string-functions.com/string-hex.aspx)

#### **Q : Comment exporter un profil WiFi depuis une machine Windows déjà connectée ?**
**R :** Utilisez la commande suivante dans PowerShell (en mode administrateur) :
```powershell
netsh wlan export profile name="YOURWIFINAME" folder="C:\Path\To\Deployment-Files\sources\$OEM$\$1\Deploy\" key=clear
```


### 📦 Questions sur les logiciels

#### **Q : Puis-je utiliser Office 365 au lieu d'Office 2016 ?**
**R :** Oui ! Utilisez l'Office Deployment Tool :
1. Générez un fichier `config*.xml` sur https://config.office.com
2. Téléchargez les sources avec `setup.exe /download config.xml`
3. Placez tout dans le dossier `Office/`

#### **Q : Comment adapter le script pour un autre EDR que WithSecure ?**
**R :** Modifiez le bloc lignes 94-108 dans PostInstall.ps1 :
```powershell
# Exemple pour CrowdStrike
$crowdstrikeDir = Join-Path $DeployRoot "CrowdStrike"
if (Test-Path $crowdstrikeDir) {
    $csInstaller = Get-ChildItem -Path $crowdstrikeDir -Filter "*.exe" -Recurse | Select-Object -First 1
    if ($csInstaller) {
        $arguments = "/install /quiet CID=VOTRE-CID"
        $rc = Start-Safely -exe $csInstaller.FullName -arguments $arguments
    }
}
```

#### **Q : Puis-je ajouter d'autres logiciels ?**
**R :** Oui, créez un dossier dans `Deploy/` et ajoutez la logique d'installation dans PostInstall.ps1 :
```powershell
# Exemple pour 7-Zip
$7zipInstaller = Get-ChildItem -Path "$DeployRoot\7Zip" -Filter "*.msi" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($7zipInstaller) {
    $rc = Start-Safely -exe "msiexec.exe" -arguments "/i `"$($7zipInstaller.FullName)`" /quiet"
}
```

### 🌐 Questions réseau

#### **Q : Le WiFi est-il obligatoire ?**
**R :** Non, mais recommandé pour :
- L'activation Windows via KMS
- Windows Update automatique
- Installation des logiciels nécessitant Internet
Bien sûr, une connexion filaire Ethernet fonctionne aussi.

#### **Q : Comment vérifier que ma connexion WiFi fonctionne ?**
**R :** Après installation :
```powershell
# Vérifier les adaptateurs WiFi
Get-NetAdapter | Where-Object {$_.InterfaceDescription -like "*wireless*"}

# Tester la connectivité
Test-NetConnection -ComputerName "8.8.8.8" -InformationLevel Quiet
```

### 🔍 Questions de dépannage

#### **Q : Où puis-je consulter les logs du déploiement ?**
**R :** Principaux logs :
- `C:\Windows\Setup\Logs\postinstall.log` - Log principal
- `C:\Windows\Setup\Logs\officeAct-CleanupDeploy.log` - Activation Office
- `C:\Windows\Panther\setupact.log` - Installation Windows

#### **Q : Comment vérifier si Windows est activé ?**
**R :** 
```powershell
# Commande rapide
slmgr /xpr

# Informations détaillées
slmgr /dli
```

#### **Q : Office demande une activation, que faire ?**
**R :** Vérifiez si le script d'activation s'est exécuté :
```powershell
# Aller dans le dossier Office
cd "C:\Program Files\Microsoft Office\Office16"

# Activation manuelle
cscript ospp.vbs /sethst:votre-serveur-kms.local
cscript ospp.vbs /act
```

### 🏗️ Questions techniques

#### **Q : Puis-je modifier le partitionnement des disques ?**
**R :** Oui, mais attention ! Le script utilise un partitionnement GPT optimisé :
- EFI : 300MB
- MSR : 16MB  
- Windows : Extensible
- Recovery : 1GB (en fin pour faciliter les redimensionnements)

#### **Q : Comment créer une ISO avec oscdimg ?**
**R :** Installez Windows ADK et utilisez :
```DOS
oscdimg.exe -m -o -u2 -udfver102 ^
-bootdata:2#p0,e,b"source\boot\etfsboot.com"#pEF,e,b"source\efi\microsoft\boot\efisys.bin" ^
"C:\Temp\Win11Source" "C:\AutoDeploy-Win11.iso"
```

#### **Q : Que font les fichiers efisys.bin et cdboot.efi ?**
**R :** Ce sont des versions modifiées qui éliminent les prompts "Appuyez sur une touche pour démarrer", permettant un boot 100% automatique.

### 📋 Questions sur la maintenance

#### **Q : Comment mettre à jour les pilotes WiFi ?**
**R :** Remplacez les fichiers dans `$WinPEDriver$/Wifi/` par les nouveaux pilotes et recréez votre support.

#### **Q : Comment ajouter des mises à jour Windows ?**
**R :** Téléchargez les .msu depuis le Catalogue Microsoft Update et placez-les dans `WindowsUpdates/`. Le script les installera automatiquement.

#### **Q : Puis-je réutiliser le même support pour plusieurs machines ?**
**R :** Absolument ! C'est tout l'intérêt. Seul le nom du poste sera demandé à chaque installation.

### 🔒 Questions de sécurité

#### **Q : Est-il sécurisé de laisser des mots de passe dans les scripts ?**
**R :** Pour un usage interne, oui, mais :
- Utilisez des comptes dédiés au déploiement
- Changez les mots de passe après déploiement
- Ne publiez jamais de vrais mots de passe sur GitHub

#### **Q : Comment anonymiser mon projet avant partage ?**
**R :** Remplacez par des variables génériques :
- Clés de licence → `VOTRE-CLE-WINDOWS`
- Serveurs → `votre-serveur.domaine.local`
- Mots de passe → `VOTRE-MOT-DE-PASSE`
- Licences EDR → `XXXX-XXXX-XXXX-XXXX`

### 📈 Questions d'optimisation

#### **Q : Comment accélérer le déploiement ?**
**R :** Plusieurs astuces :
- Ajoutez les grosses mises à jour dans `WindowsUpdates/`
- Utilisez un SSD rapide pour la clé USB
- Optimisez la configuration Office (excluez les apps non utilisées)
- Pré-téléchargez toutes les sources logicielles

#### **Q : Comment réduire l'utilisation de bande passante ?**
**R :** 
- Mettez les gros .msu dans `WindowsUpdates/`
- Téléchargez les sources Office complètes
- Utilisez un serveur KMS local
- Pré-configurez les profils WiFi pour éviter les téléchargements inutiles

---

## 💡 Conseils supplémentaires

### Pour les débutants :
1. **Commencez simple** : Testez d'abord sans logiciels supplémentaires
2. **Une machine à la fois** : Testez sur une VM avant production
3. **Gardez des sauvegardes** : Sauvegardez vos configurations fonctionnelles

### Pour les experts :
1. **Scriptez vos adaptations** : Créez des scripts de personnalisation
2. **Versionnez vos configurations** : Utilisez Git pour suivre les changements
3. **Automatisez la création d'ISO** : Scripter la génération avec oscdimg

---

**🤝 Questions non résolues ?** Créez una issue sur le dépôt GitHub avec tous les détails !