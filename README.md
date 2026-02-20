CAHIER DES CHARGES : APPLICATION GÉNÉRATRICE D'AMBIANCES SONORES

1. Présentation du Projet
   Concept : Application mobile permettant de générer un fond sonore continu et immersif de nature, en mixant plusieurs pistes audio de façon personnalisée ou automatique.

Objectif : Offrir une expérience d'évasion instantanée avec des sons réels. L'UX et l'UI doivent être minimalistes, extrêmement ergonomiques et d'une très grande qualité esthétique.

Plateformes cibles : iOS (en priorité) et Android.

2. Spécifications Techniques & Architecture
   Le développement doit être réalisé strictement en React Native et Expo pur, sans éjection.

Moteur Audio : Utilisation de la nouvelle API expo-audio (successeur de l'ancien expo-av) pour garantir les meilleures performances en 2026.

Gestion de l'Arrière-plan (Background Audio) : C'est une fonctionnalité critique. L'application doit configurer les UIBackgroundModes ("audio") via les plugins d'Expo pour que la lecture continue lorsque l'écran est verrouillé, et s'intégrer aux contrôles multimédias de l'OS (Lockscreen).

Gestion des Assets Audio : \* Les fichiers sonores seront des enregistrements réels, stockés localement dans un répertoire de l'application pour garantir un fonctionnement 100 % hors-ligne.

Note au développeur : Bien que le répertoire initial puisse contenir des fichiers .mp3, le lecteur devra impérativement supporter des formats de compression sans perte de début/fin de piste (comme le .m4a / AAC ou .ogg) afin de garantir un bouclage (gapless loop) parfait sans le "clic" caractéristique du MP3.

Gestion d'État : Utilisation recommandée de Zustand pour gérer efficacement l'état du mixeur (volumes, toggles, presets) sans re-rendus inutiles de l'interface.

3. Interface Utilisateur (UI) et Expérience (UX)
   L'impression générale doit être extrêmement soignée, épurée, élégante et sobre.

Arrière-plan (Background) : Le fond de l'application sera généré et animé via @shopify/react-native-skia. Il s'agira d'une couleur sable, avec un grain visible, animée de façon douce et subtile (similaire au rendu de l'application EMDR Flow).

Le Mixeur (Channels) : Empilement vertical de 9 canaux : Oiseaux, Vent, Mer, Rivière, Forêt, Pluie, Tonnerre, Insectes (cigales/criquets), Ville.

Chaque canal dispose d'un label textuel (nom du son), prévu pour être potentiellement remplacé par des icônes lors d'une V2.

Sliders "Liquid Glass" : Chaque canal possède son propre slider de volume avec un effet visuel de type "verre liquide".

Colorimétrie : Chaque slider arborera une couleur pastel unique. L'empilement de tous les sliders devra former visuellement un dégradé arc-en-ciel pastel harmonieux.

Contrôles par canal : À côté du slider, un "Toggle" d'activation/désactivation (Mute), et un second bouton pour activer la variation automatique du volume.

Contrôles Globaux (Haut de l'écran) :

Bouton Lecture/Stop instantané (One-tap play).

Bouton "Mix Aléatoire" (Active des canaux et assigne des volumes au hasard).

Diffusion Externe : Intégration d'un accès rapide au menu AirPlay (iOS) et Bluetooth natif du système depuis l'interface principale.

4. Logique Métier & Fonctionnalités
   Lecture et Bouclage (Le Moteur d'Illusion) : \* Lors du lancement, chaque piste audio activée démarre simultanément.

Règle d'or : Pour éviter la monotonie, chaque piste doit démarrer à un offset de temps aléatoire (ex: pour une piste de 30 min, la lecture commence à 12m04s).

Chaque piste est lue en boucle infinie (looping) indépendamment de sa durée, jusqu'à l'arrêt manuel ou la fin du timer.

Variation Automatique du Volume : Si l'utilisateur active le bouton dédié sur un canal, le volume de ce canal variera automatiquement et très lentement dans le temps (pour simuler, par exemple, le vent qui se lève et retombe).

Contrainte technique pour Antigravity : Cette variation devant fonctionner en arrière-plan (quand le thread JS est potentiellement suspendu par iOS), l'animation des volumes devra idéalement s'appuyer sur des Worklets (via react-native-reanimated) ou une implémentation native légère.

Système de Timer : Une interface simple proposant 4 durées : 15 min, 30 min, 1h, 2h. Le moteur audio s'arrête net à la fin du délai.

Système de Presets (Sauvegardes) : \* Un Preset enregistre : les canaux activés, le volume de chaque canal, et l'état du bouton de variation automatique.

L'application inclura une liste de presets par défaut.

L'utilisateur pourra éditer ces presets et créer/sauvegarder les siens.

À l'ouverture de l'application, les derniers réglages utilisés lors de la session précédente sont chargés automatiquement (ou le preset par défaut lors du tout premier lancement).
