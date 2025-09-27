# Win11-AutoDeploy-Local 🚀

**Solution de déploiement automatisé de postes Windows 11 sans infrastructure distribuée**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Windows 11](https://img.shields.io/badge/Windows-11-blue.svg)](https://www.microsoft.com/windows/windows-11)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)

## 📖 Description

Win11-AutoDeploy-Local est une solution complète de déploiement automatisé de postes Windows 11 développée dans le cadre d'un stage de formation TSSR. Cette solution répond au besoin de déploiement de masse sans infrastructure distribuée (MECM/SCCM/WDS/MDT), en utilisant des fichiers de réponses Windows et des scripts PowerShell pour automatiser l'ensemble du processus d'installation et de configuration.

### 🎯 Problématique résolue

- **Déploiement manuel chronophage** : Élimination du processus d'onboarding/préparation de poste manuel
- **Contraintes budgétaires** : Alternative aux solutions distribuées coûteuses comme MDT ou MECM
- **Évolutivité** : Maintien et évolution faciles de l'ISO d'installation selon les builds Windows 11
- **Standardisation** : Uniformisation des configurations de postes sans infrastructure serveur

## 🚀 Démarrage rapide

**👉 [Guide de démarrage rapide (QUICKSTART.md)](QUICKSTART.md)** - Déployez votre première machine en 15 minutes de configuration !

### ⚡ En bref :
1. **Personnalisez** `Deployment-Files/autounattend.xml` et `PostInstall.ps1`
2. **Copiez** le contenu de `Deployment-Files/` sur votre clé USB Windows 11
3. **Bootez** et patientez 45-75 minutes ⏱️

## ✨ Fonctionnalités principales

### 🎯 Déploiement entièrement automatisé
- **Installation Windows 11 zéro-touch** avec partitionnement GPT optimisé
- **Optimisation système** : Suppression bloatwares, configuration sécurisée
- **Connectivité** : WiFi automatique + pilotes modernes (WiFi 6E)

### 📦 Déploiement logiciel intelligent  
- **Microsoft Office** 2016/365 avec activation automatique
- **Agent EDR** (WithSecure ou adaptable)
- **Mises à jour** prioritaires offline + Windows Update automatisé

### 🔐 Activation et sécurité
- **KMS automatique** Windows + Office
- **Journalisation complète** de toutes les opérations

## 📁 Structure du projet

```
Win11-AutoDeploy-Local/
├── 📁 Deployment-Files/             # 🔥 DOSSIER PRINCIPAL À COPIER DANS L'ISO/USB
│   ├── 📄 autounattend.xml          # Fichier de réponses Windows (À PERSONNALISER)
│   ├── 📁 $WinPEDriver$/            # Pilotes pour l'installation Windows
│   │   └── 📁 Wifi/                 # Pilotes WiFi Intel et Realtek (WiFi 6E inclus)
│   ├── 📁 efi/microsoft/boot/       # Fichiers boot EFI sans prompt utilisateur
│   │   ├── 📄 efisys.bin
│   │   └── 📄 cdboot.efi
│   └── 📁 sources/$OEM$/            # Structure Microsoft OEM officielle
│       └── 📁 $1/
│           ├── 📁 Deploy/           # Paquetages de déploiement
│           │   ├── 📄 PostInstall.ps1      # Script principal (À PERSONNALISER)
│           │   ├── 📄 ActivateOffice.ps1   # Script d'activation Office
│           │   ├── 📄 Wifi.xml             # Profil WiFi (À PERSONNALISER)
│           │   ├── 📁 Office/              # Installation Office (vide - à alimenter)
│           │   ├── 📁 WindowsUpdates/      # Packages .msu (vide - à alimenter)
│           │   └── 📁 WithSecure/          # Agent EDR (vide - à alimenter)
│           └── 📁 Program Files/WindowsPowerShell/Modules/
│               └── 📁 PSWindowsUpdate/     # Module Windows Update (inclus)
├── 📁 docs/                         # Documentation technique complète
└── 📄 README.md, LICENSE, etc.      # Documentation du projet
```

### 🎯 Dossier principal : `Deployment-Files/`

Le dossier **`Deployment-Files/`** contient **l'architecture complète** de la solution de déploiement. C'est ce contenu qui doit être copié et personnalisé dans votre ISO ou clé USB Windows 11.

## 📖 Navigation de la documentation

### 🚀 **[QUICKSTART.md](QUICKSTART.md)** - Guide pratique complet
- Configuration détaillée des fichiers
- Méthodes de déploiement (USB/ISO)
- Alimentation des dossiers logiciels
- Validation et dépannage

### 📚 **Documentation technique :**
- **[docs/troubleshooting.md](docs/troubleshooting.md)** - Résolution de problèmes
- **[docs/faq.md](docs/faq.md)** - Questions fréquentes

## 🔍 Logs et débogage

Les logs de déploiement sont générés dans : `C:\Windows\Setup\Logs\` 
Plusieurs fichiers de log en fonction des étapes d'installation et de post-installation.

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- Signaler des bugs via les Issues
- Proposer des améliorations
- Partager vos adaptations pour d'autres environnements

## 📄 Licence

Ce projet est sous licence MIT. Vous êtes libre de :
- ✅ Utiliser commercialement
- ✅ Modifier et redistribuer
- ✅ Utiliser en privé

**Obligation** : Conserver la notice de copyright et la licence dans toute copie.

Voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

**🔧 Développé avec ❤️ pour simplifier le déploiement de postes Windows 11**