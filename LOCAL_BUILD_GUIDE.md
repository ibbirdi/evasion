# Guide : Build Complet en Local (EAS Expo)

Ce guide explique comment réaliser des builds iOS et Android directement sur votre machine pour contourner les quotas EAS Cloud.

## 1. Prérequis

Assurez-vous d'avoir les outils suivants installés :

### Général

- **EAS CLI** : `npm install -g eas-cli`
- **Expo CLI** : `npm install -g expo-cli`

### iOS (Mac uniquement)

- **Xcode** : Installé depuis l'App Store.
- **Xcode Command Line Tools** : Lancez `xcode-select --install` dans le terminal.
- **CocoaPods** : `brew install cocoapods`

### Android

- **Android Studio** : Installé et configuré avec le SDK.
- **Java (JDK)** : Version 17 recommandée.

---

## 2. Connexion

Avant de commencer, vérifiez que vous êtes connecté à votre compte Expo :

```bash
eas login
```

---

## 3. Build iOS (Local)

Pour générer un fichier `.ipa` (Production) :

```bash
eas build --platform ios --profile production --local
```

> [!IMPORTANT]
> EAS vous demandera de gérer les certificats lors du premier build. Répondez "Yes" pour l'automatisation.

---

## 4. Build Android (Local)

Pour générer un fichier `.aab` (Play Store) :

```bash
eas build --platform android --profile production --local
```

### Pour générer un APK (Test direct)

Si vous voulez un `.apk` au lieu d'un `.aab`, ajoutez ce profil dans votre `eas.json` :

```json
"production_apk": {
  "android": {
    "buildType": "apk"
  }
}
```

Puis lancez :

```bash
eas build --platform android --profile production_apk --local
```

---

## 5. Conseils

- **Espace Disque** : Les builds locaux (surtout iOS) consomment beaucoup d'espace (cache Xcode).
- **Ressources** : Fermez les applications lourdes pendant le build pour éviter les ralentissements ou échecs.
- **Localisation** : Les fichiers générés se trouveront à la racine de votre projet une fois le build terminé.
