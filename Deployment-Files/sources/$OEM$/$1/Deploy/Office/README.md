# 📁 Dossier Office

Ce dossier doit contenir les fichiers d'installation de Microsoft Office selon votre version.

## 📦 Pour Office 2016

### Structure recommandée :
```
Office/
├── setup.exe                    # Programme d'installation Office 2016
├── votre-package.msp            # Package de personnalisation (généré avec setup.exe /admin)
├── config.xml                   # Fichier de configuration (optionnel)
├── updates/                     # Dossier pour les mises à jour offline
│   ├── kb123456.msp
│   └── kb789012.msp
└── [autres fichiers Office 2016]
```

### Instructions :
1. **Déployez l'installation complète** d'Office 2016
2. **Générez un package MSP** :
   ```bash
   # Exécutez depuis le dossier Office
   setup.exe /admin
   ```
3. **Sauvegardez le fichier .msp** généré dans ce dossier
4. **Ajoutez les mises à jour** dans le sous-dossier `updates/`

## 🌐 Pour Office 365 / Office Click-to-Run

### Structure recommandée :
```
Office/
├── setup.exe                    # Office Deployment Tool
├── config-install.xml           # Fichier de configuration (OBLIGATOIRE)
├── Office/                      # Dossier des sources téléchargées
│   └── Data/
└── [autres fichiers ODT]
```

### Instructions :
1. **Téléchargez l'Office Deployment Tool** depuis Microsoft
2. **Générez votre configuration** sur https://config.office.com/deploymentsettings
3. **Nommez le fichier** : `config-*.xml` (commence par "config" et finit par ".xml")
4. **Téléchargez les sources** :
   ```bash
   # Depuis ce dossier
   setup.exe /download config-install.xml
   ```

### Exemple de fichier config-install.xml :
```xml
<Configuration>
  <Add SourcePath="." OfficeClientEdition="64" Channel="Current">
    <Product ID="O365ProPlusRetail">
      <Language ID="fr-fr" />
      <ExcludeApp ID="Groove" />  <!-- Exclure OneDrive -->
      <ExcludeApp ID="Teams" />   <!-- Exclure Teams -->
    </Product>
  </Add>
  <Display Level="None" AcceptEULA="TRUE" />
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
  <Property Name="SharedComputerLicensing" Value="0" />
</Configuration>
```

## 🔍 Détection automatique

Le script `PostInstall.ps1` détecte automatiquement :
- Les fichiers **.msp** pour Office 2016
- Les fichiers **config*.xml** pour Office moderne
- Adapte l'installation en conséquence

## ⚠️ Important

- **Office 2016** : Le script cherche les fichiers .msp dans ce dossier
- **Office moderne** : Le script cherche les fichiers config*.xml
- **Activation** : L'activation se fait automatiquement via `ActivateOffice.ps1`

---

**💡 Conseil** : Testez votre configuration Office sur une machine de développement avant déploiement.