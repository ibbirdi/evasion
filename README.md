# É V A S I O N - Générateur d'Ambiances Sonores Immersives

## 1. Présentation du Projet

**Concept** : Évasion est une application mobile premium permettant de générer un fond sonore continu, organique et profondément immersif. Elle mixe de façon dynamique et personnalisée de multiples pistes audio issues de la nature.

**Objectif & Philosophie** : Offrir une expérience d'évasion mentale instantanée et luxueuse. L'application se distingue par son exigence absolue sur la qualité sonore : chaque piste provient d'un **enregistrement réel et continu de très haute qualité binaurale**, capturé dans le monde entier. Il ne s'agit en aucun cas de courtes boucles artificielles, de synthétiseurs ou de simples bruitages de quelques secondes répétés mécaniquement. L'auditeur est littéralement plongé au cœur d'un paysage sonore vaste et vivant. L'interface utilisateur (UI/UX) est minimaliste, extrêmement ergonomique et d'une grande qualité esthétique, favorisant le repos visuel et mental dès l'ouverture de l'application.

**Plateformes cibles** : iOS (priorité) et Android.

## 2. Moteur Audio & Fonctionnalités (MVP Atteint)

Le développement repose sur une architecture moderne de pointe, construite en React Native et Expo (expo-audio, reanimated, skia) garantissant des performances natives irréprochables et des animations fluides.

### A. Une Bibliothèque Sonore Authentique et Haute Fidélité

- **Environnements immersifs profonds** : De vrais enregistrements de terrain prolongés.
- **Pistes intégrées au MVP** : Oiseaux, Vent, Plage, Goélands, Forêt, Pluie, Orage, Cigales, Grillons, Ville, Voiture, Train.
- **Variations Dynamiques Centralisées** : Chaque "Piste" (ex: "Plage") n'est pas limitée à un seul enregistrement monotone. Le moteur audio est architecturé pour piocher dynamiquement et aléatoirement parmi plusieurs dizaines d'enregistrements différents (Fichiers Audio) pour le même environnement, garantissant ainsi qu'aucune session d'écoute ne puisse être exactement identique.
- **100% Hors-ligne** : Tous les éléments sonores haute qualité sont embarqués localement. L'immersion se lance instantanément à l'ouverture de l'application sans latence réseau, de manière totalement confidentielle, et fonctionne partout (vol long-courrier, connexion faible, retraites dans la nature etc.).

### B. Moteur d'Illusion, Intelligence et Playback

- **Générateur d'Aléatoire Temporel (Offset)** : À chaque _Play_, toutes les pistes sélectionnées vont démarrer la lecture de leurs très longs fichiers à un point (offset temporel) **totalement aléatoire**. Combiné aux boucles, ce mécanisme garantit que l'utilisateur n'entendra jamais le même "mélange" de sons se répéter, créant une illusion auditive d'une richesse infinie par de simples mathématiques probabilistes.
- **Audio en Arrière-plan Ininterrompu** : Intégration totale avec l'OS mobile (UIBackgroundModes) ; la symphonie continue lorsque l'appareil est verrouillé ou manipulé, avec accès aux contrôles sur le Lockscreen iOS / Android.
- **Écosystème Vivant (Auto-Variation)** : L'une des fonctionnalités phares du projet. Si activée sur un canal, l'application prend le contrôle du volume de cet environnement et le fait vivre (augmenter et diminuer) de façon aléatoire et extrêmement lente dans le temps. C'est l'intelligence de l'app qui "soulève" le vent, "éloigne" un orage, en simulant la nature, libérant totalement la charge mentale de l'utilisateur.

### C. Le Mixeur Avancé & Les Presets

- **Smart Shuffle (Mix Aléatoire)** : Algorithme génératif sélectionnant entre 2 et 4 pistes au hasard avec des niveaux minutieusement calculés. Un seul tap déclenche instantanément une toute nouvelle ambiance inédite.
- **Minuterie de Sommeil (Timer)** : Moteur d'extinction programmé pour l'endormissement (15m, 30m, 1h, 2h).
- **Enregistrement de Presets** : Création et sauvegarde illimitée de "Paysages Sonores" dans la mémoire interne du dispositif. (Pistes, Volume, et paramètres d'Auto-Variation mémorisés).
- **Presets Signatures Inclus** : Collections par défaut offertes dès la première utilisation pour les néophytes.

## 3. Interface Utilisateur (UI) / Expérience (UX) Épurée et Premium

L'application a été conçue pour offrir un sentiment de luxe feutré et de détente instantanée.

- **Contrôles "Liquid Glass"** : Un travail acharné de design interactif pour réinventer les potentiomètres. Les curseurs de volume ne sont pas de simples barres ; ils adoptent un design "verre liquide" semi-transparent, aux réactions gestuelles fluides (60fps), teintés par un dégradé arc-en-ciel élégant et apaisant.
- **Ergonomie "One-Tap" & Accessibilité** : Tout le pilotage (Play, Aleatoire, Presets, Cast, Sleep Timer) est condensé élégamment à portée de pouce sur l'écran d'accueil sans navigation ardue.
- **AirPlay & Cast** : Bouton d'ancrage rapide pour transférer le mixage sur des moniteurs, enceintes Home-Cinéma haute-fidélité, ou écouteurs Bluetooth en un instant.

---

_Ce document acte qu'au delà des spécifications techniques validées, la MVP offre une expérience et une valeur perçue exceptionnelles. Ses mécanismes invisibles (Offset aléatoire, Auto-Variation, Binaural Field Recording) la positionne d'ores et déjà comme un produit très prometteur pour les futures stratégies commerciales (Abonnement Premium, B2B Santé/Bien-Être) sur les magasins d'applications mondiaux._
