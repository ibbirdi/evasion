# Oasis - Générateur d'ambiances sonores immersives

## Présentation

Oasis est une application iOS native en **SwiftUI**, pensée pour créer un fond sonore continu, organique et très immersif. L'app est orientée bien-être, écoute longue durée et contrôle fin du mix audio, avec une intégration native de l'audio, du background playback et de RevenueCat.

L'app est **offline-first**: tous les sons, les effets binauraux et les assets UI sont embarqués dans le bundle. Aucun backend applicatif n'est nécessaire pour lire, mixer ou restaurer les achats.

## Version Gratuite et Premium

| Fonctionnalité | Version gratuite | Version premium |
| --- | --- | --- |
| Canaux audio | 3 canaux: Oiseaux, Vent, Plage | 20 canaux: tous les sons du catalogue |
| Mixeur | Volume, mute, auto-variation sur les 3 canaux gratuits | Contrôle complet sur tous les canaux |
| Mix aléatoire | Oui, mais limité aux canaux gratuits | Oui, sur toute la bibliothèque |
| Audio spatial | Oui sur les canaux gratuits | Oui sur tous les canaux accessibles |
| Binaural | Delta uniquement | Delta, Theta, Alpha, Beta |
| Timer de sommeil | Non | Oui, 15 min, 30 min, 1 h, 2 h |
| Presets | Non accessible depuis l'UI | Création, chargement, suppression, réorganisation |
| Achat | Aucun | Achat unique à vie via RevenueCat |
| Restauration | Sans objet | Oui |

Le paywall est conçu comme un achat unique, sans abonnement. L'accès premium débloque surtout trois blocs fonctionnels:

- la bibliothèque complète des sons,
- les fonctions d'organisation du mix, comme les presets,
- les outils de confort premium, comme le timer et les pistes binaurales avancées.

## Stack Technique

- **UI**: SwiftUI, `@Observable`, `@Environment`, `NavigationStack`, sheets, full-screen covers et animations `smooth`.
- **Design system**: effets `glassEffect`, gradients dédiés, composants réutilisables pour les panneaux, boutons et cartes.
- **Audio principal**: `AVAudioEngine`, `AVAudioEnvironmentNode` et `AVAudioPlayerNode` pour les ambiances longues et le positionnement spatial.
- **Audio binaural**: `AVAudioPlayer` pour les pistes Delta, Theta, Alpha et Beta.
- **Session audio**: `AVAudioSession` configurée en mode playback avec support AirPlay et Bluetooth A2DP.
- **Contrôles système**: `MPRemoteCommandCenter` pour la lecture pause/play depuis l'écran verrouillé ou les écouteurs.
- **Routes audio**: `RoutePickerView` pour le routage vers AirPlay / Bluetooth.
- **Monétisation**: RevenueCat iOS SDK avec entitlement `premium`.
- **Persistance**: `UserDefaults` + `JSONEncoder` / `JSONDecoder` pour l'état du mixeur et les presets.
- **Test et automatisation**: UI tests Xcode, snapshots, et overrides de premium pour les captures.
- **Assets**: sons `.m4a`, logo et ressources embarqués dans le bundle.

Le moteur audio repose sur un graphe distinct pour les ambiances naturelles, avec:

- un `AVAudioEnvironmentNode` pour l'espace et l'atténuation,
- des `AVAudioPlayerNode` pour les sons d'ambiance en boucle,
- des `AVAudioPlayer` séparés pour les pistes binaurales,
- des fades de transition pour éviter les coupures sèches,
- une synchronisation avec les commandes de lecture système.

## Architecture Applicative

- `AppModel` centralise l'état global de l'application.
- `AudioMixerEngine` pilote le moteur audio, les fades, les lectures en boucle, l'audio spatial et les commandes système.
- `PaywallOverlay` récupère les `offerings` RevenueCat, lance les achats et restaure les achats.
- `HomeView` orchestre les panneaux principaux: presets, binaural, spatial et paywall.
- `AppCopy` fournit les textes localisés pour l'UI, le paywall et les libellés de fonctionnalités.
- `AppConfiguration` regroupe les clés, les flags de test, l'identifiant d'entitlement et les helpers de configuration.

En pratique, le verrouillage premium est appliqué à plusieurs endroits:

- les canaux non libres déclenchent le paywall depuis le mixeur,
- les pistes binaurales avancées sont verrouillées tant que l'entitlement `premium` n'est pas actif,
- le timer n'est accessible que côté premium,
- le panneau des presets est réservé au premium,
- `AppModel` réapplique l'état effectif à la lecture de `CustomerInfo` RevenueCat et à chaque changement d'entitlement.

## Fonctionnalités

### Mixeur audio

- 20 canaux audio intégrés: Oiseaux, Vent, Plage, Goélands, Forêt, Pluie, Orage, Cigales, Grillons, Tente, Rivière, Village, Voiture, Train, Feu de camp, Café, Lac, Savane, Jungle d'Amérique, Jungle d'Asie.
- Lecture en arrière-plan avec reprise native sur iPhone.
- Contrôle de volume par canal.
- Auto-variation pour faire évoluer automatiquement certains volumes dans le temps.
- Mix aléatoire pour générer rapidement une ambiance différente.
- Audio spatial par canal avec panneau dédié.

### Binaural

- 4 pistes binaurales: Delta, Theta, Alpha, Beta.
- Volume binaural indépendant.
- Activation / désactivation du moteur binaural.
- Sélection de la piste depuis un panneau dédié.
- Accès premium sur les pistes au-delà de Delta.

### Presets et minuterie

- Presets personnalisés sauvegardés localement.
- Presets par défaut inclus.
- Réorganisation, suppression et chargement de presets.
- Timer premium avec durées 15 min, 30 min, 1 h et 2 h.

### Paywall et premium

- Paywall SwiftUI dédié.
- Achat unique à vie via RevenueCat.
- Restauration des achats.
- Déverrouillage basé sur l'entitlement RevenueCat `premium`.

## Configuration RevenueCat

La configuration actuelle attend:

- `RevenueCatAPIKey` dans `Info.plist`
- `RevenueCatEntitlementID = premium`
- Une offering RevenueCat définie comme offering courant

Dans la configuration actuelle RevenueCat, le produit affiché sur la capture est:

- Offering: `RCpremium`
- Package: `$rc_lifetime`
- Produit App Store: `premium`

Le code ne dépend pas du nom `RCpremium` en dur, mais il dépend bien du fait que l'offering courante soit renseignée et que l'entitlement débloqué s'appelle `premium`.

## Structure Du Projet

- `ios-native/OasisNative/Views/` : écrans, overlays et composants SwiftUI.
- `ios-native/OasisNative/Services/` : moteur audio, état applicatif et logique de synchro.
- `ios-native/OasisNative/Models/` : données métier, traductions et types de l'app.
- `ios-native/OasisNative/Support/` : configuration, Info.plist, helpers système.
- `ios-native/OasisNativeUITests/` : UI tests et captures d'écran automatisées.

## Build Local

Le projet Xcode s'ouvre dans `ios-native/OasisNative.xcodeproj`.

Pour un build local en ligne de commande:

```bash
xcodebuild -scheme OasisNative -project "ios-native/OasisNative.xcodeproj" -configuration Debug -sdk iphonesimulator -destination "generic/platform=iOS Simulator" build CODE_SIGNING_ALLOWED=NO
```

## Notes Produit

- L'app reste orientée bien-être / immersion sonore.
- Tous les sons sont lus localement, sans streaming.
- Les achats sont gérés via RevenueCat plutôt que par une logique d'achat maison.
- Les identifiants de premium utilisés par l'app sont `premium` côté entitlement, avec un produit lifetime dans RevenueCat.
