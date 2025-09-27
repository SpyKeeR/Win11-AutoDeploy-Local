# 📁 Dossier WindowsUpdates

Ce dossier peut contenir des fichiers de mises à jour Windows (.msu) pour accélérer le déploiement et économiser la bande passante.

## 🎯 Objectif

Les mises à jour placées ici seront installées **AVANT** la boucle Windows Update automatique, permettant de :
- ⚡ **Accélérer le déploiement** en évitant les téléchargements
- 🌐 **Économiser la bande passante** réseau
- 🎯 **Installer en priorité** les mises à jour critiques
- 🔄 **Éviter les doublons** (exclusion automatique de Windows Update)

## 📦 Types de fichiers supportés

### Fichiers .msu (Microsoft Update Standalone Package)
```
WindowsUpdates/
├── windows11-kb5028185-x64.msu     # Mise à jour cumulative
├── windows11-kb5028166-x64.msu     # Mise à jour de sécurité  
├── windows11-kb5027303-x64.msu     # Mise à jour des fonctionnalités
└── [autres fichiers .msu]
```

## 🔍 Où trouver les mises à jour

### Catalogue Microsoft Update
1. Visitez **[Microsoft Update Catalog](https://www.catalog.update.microsoft.com/)**
2. Recherchez les mises à jour pour **Windows 11**
3. Téléchargez les fichiers **.msu** appropriés
4. Placez-les dans ce dossier

### Mises à jour recommandées
- **Mises à jour cumulatives** mensuelles (plus gros fichiers)
- **Mises à jour de sécurité** critiques
- **Mises à jour des fonctionnalités** spécifiques à votre environnement
- **Mises à jour de .NET Framework** si nécessaire

## 🔧 Fonctionnement automatique

Le script `PostInstall.ps1` :

1. **Scanne ce dossier** au démarrage
2. **Installe chaque fichier .msu** avec `wusa.exe /quiet /norestart`
3. **Collecte les numéros KB** installés
4. **Exclut ces KB** de la boucle Windows Update suivante
5. **Supprime les fichiers** après installation (nettoyage automatique)

## 📋 Journal d'installation

Les installations sont journalisées dans :
- `C:\Windows\Setup\Logs\postinstall.log`

Exemple de log :
```
25-09-2025 14:32:10 - Installation de windows11-kb5028185-x64.msu...
25-09-2025 14:35:22 - Mise à jour KB5028185 installée avec succès
25-09-2025 14:35:23 - KBs à exclure de Windows Update: KB5028185, KB5028166
```

## ⚠️ Conseils d'utilisation

### ✅ À faire :
- Téléchargez uniquement les mises à jour **compatibles avec votre version** de Windows 11
- Privilégiez les **gros packages** (mises à jour cumulatives) pour maximiser le gain
- Vérifiez la **date des mises à jour** pour éviter les anciennes versions

### ❌ À éviter :
- Ne mélangez pas les architectures (x64/x86)
- N'ajoutez pas trop de petites mises à jour (gain minime)
- Ne déployez pas de mises à jour en version bêta

## 🔍 Vérification

Pour vérifier les installations :
```powershell
# Voir les mises à jour installées
Get-HotFix | Sort-Object InstalledOn -Descending

# Voir les KB spécifiques
Get-HotFix -Id KB5028185
```

---

**💡 Conseil** : Concentrez-vous sur les mises à jour cumulatives mensuelles qui représentent le plus gros gain en bande passante.