# Audit ASO & App Store — Oasis 1.4.1

> Audit complet de la fiche App Store d'**Oasis** (6 langues : `en-US`, `fr-FR`, `de-DE`, `es-ES`, `it`, `pt-BR`), avec un plan d'action priorisé pour augmenter les téléchargements organiques et les achats premium (lifetime).
>
> Périmètre : metadata `fastlane/`, screenshots `figma-pro/`, code de paywall et d'onboarding. Pas d'accès direct à App Store Connect — les hypothèses sur les performances sont signalées et les écrans ASC à m'ouvrir pour aller plus loin sont listés en §9.

---

## 0. Positionnement stratégique — préalable

Oasis n'est pas une app sleep aid de plus. C'est un **mixeur d'ambiances sonores naturelles personnalisables**, dont le sommeil n'est qu'un cas d'usage parmi d'autres : sieste, focus / deep work, lecture, méditation, masquage de bruit en open-space, voyage. Ce positionnement est honnête vis-à-vis du produit (le moteur 3D, les binaurals Alpha/Beta, le mixeur multi-canaux ne servent pas qu'à dormir) et c'est aussi un angle de différenciation réel face à Calm, Headspace, Endel, Portal, Sleep Cycle qui se présentent tous comme des sleep apps mono-usage.

**Tension à arbitrer en permanence dans les recommandations.** Selon Sensor Tower / Mobile Action (benchmarks publics 2025-2026), les requêtes contenant "sleep / sommeil / schlaf / sueño / sonno / sono" représentent 60-70 % du volume de recherche du segment. Si Oasis cède ce trafic, il perd une majorité d'impressions. La bonne stratégie n'est donc pas de retirer les keywords sleep, mais de :

- **Garder les keywords sleep dans le champ keywords** (ils captent le trafic de recherche sans s'afficher sur la fiche).
- **Repositionner titre, sous-titre, hero screenshot, première ligne de description** sur l'angle "mixeur d'ambiances multi-usage" (forge la différenciation au moment de la conversion).
- **Pousser quatre cas d'usage explicitement** dans les sous-titres et la description : *sommeil, sieste, focus, lecture/calme*. Travail / étude / méditation viennent en bénéfices secondaires.

Cette V2 du document remplace les recommandations sleep-led de la première version. Le bilan ASO §2 et le diagnostic technique §3.2 restent valides ; les §1, §3.4, §4, §5.1 et §5.3 ont été réécrits.

---

## 1. Résumé exécutif (TL;DR)

Oasis a un produit propre, une narrative cohérente (lifetime, pas d'abo, hors ligne) et un set d'assets visuels au-dessus de la moyenne de la catégorie. Le dispositif d'acquisition est sous-optimisé sur quatre axes mesurables :

D'abord, **le positionnement actuel est sleep-led** alors que le produit est un mixeur d'ambiances multi-usage (cf. §0). Le titre EN "Oasis: Sleep Sounds, Nature 3D" enferme l'app dans la catégorie sleep aid où elle se bat contre Calm/Headspace/Endel — une bataille qu'elle n'a pas à mener seule, et où sa différenciation (mixage 3D, achat unique, multi-usage) est invisible.

Ensuite, le **keyword field** est rempli de mots dupliqués avec le titre/sous-titre et de termes faibles (`ASMR`, `cafe`, `lernen`) qui consomment le budget de 100 caractères au détriment de termes haute-volume du segment (`ambient`, `mixer`, `ocean`, `fan`, `study`, `meditation`, `timer`). Apple n'indexe chaque mot qu'**une seule fois** entre nom + sous-titre + keywords ; chaque répétition est une opportunité ratée. Estimation de gain : **+20 à +35 % d'impressions** organiques sur les 6 langues, sans toucher au produit.

Le **Slide 01** (la capture qui pèse 60-70 % de la décision d'install) porte un headline ("Craft your perfect ambience") qui est sur le bon angle stratégique (création / mixage / personnalisation) mais qui n'est ni reinforcé par un eyebrow textuel, ni accompagné d'un sous-titre qui montre la *variété* des usages. L'angle est bon, l'exécution est à muscler.

Enfin, **aucune vidéo App Preview** n'est publiée et **aucune Custom Product Page** n'est utilisée. Les deux sont gratuits, débloquent du test d'attribution propre, et permettent de tester plusieurs personae (sommeil, focus, voyage) sans diluer la fiche principale.

Le **funnel in-app** (paywall contextuel, preview signature, banner premium, request review après 5 min ou N sessions, anchor "prix d'un café à Paris") est en revanche *bien* construit. Les recommandations §6 sont incrémentales.

**Top 5 quick wins (Semaine 1, ~6h de travail au total) :**

1. Repositionner les **titres** des 6 langues en mode "mixeur" (cf. §4) — sortir du carcan sleep aid, capter les requêtes mixer/ambient/nature qui ne sont aujourd'hui pas indexées.
2. Réécrire les **sous-titres** pour lister 4 cas d'usage (sommeil, sieste, focus, lecture/calme) — la variété est la différenciation.
3. Réécrire le **keyword field** dans les 6 langues — garde les termes sleep haute-volume (ils captent le trafic), supprime les doublons et les termes faibles, ajoute 8-10 termes neufs par locale.
4. Activer **les sous-catégories App Store** ("Mind & Body" sous Health & Fitness, "Travel" comme tertiaire éventuel) — slot de discovery gratuit.
5. Renforcer **eyebrow + sous-titre du Slide 01** — garder "Craft your perfect ambience" et ajouter eyebrow "FOR SLEEP, FOCUS OR FLOW" + sous-titre listant 4 usages.

**Impact cumulé estimé :** +30 à +50 % de Page Views organiques et +5 à +10 pts de taux de conversion install→trial sur 60 jours, en partant des assumptions standard du segment Audio Wellness iOS (Sensor Tower, Mobile Action benchmarks 2025-2026). À mesurer dans App Store Connect → Analytics.

---

## 2. Diagnostic actuel — métadonnées

### 2.1 Inventaire par langue

Le tableau ci-dessous donne l'état présent dans `fastlane/metadata/<locale>/` au 2026-04-26 (dernière modification du dossier). Les comptages incluent les espaces.

| Locale | Nom | car. | Sous-titre | car. | Keywords | car. |
|---|---|---:|---|---:|---|---:|
| en-US | Oasis: Sleep Sounds, Nature 3D | 30/30 | Focus, relax. No subscription. | 30/30 | white,noise,brown,pink,rain,thunder,wind,binaural,sleep,focus,calm,insomnia,tinnitus,ASMR,cafe | 93/100 |
| fr-FR | Oasis : Sons 3D pour Dormir | 27/30 | Sommeil, concentration, calme. | 30/30 | bruit,blanc,brun,rose,pluie,orage,vent,binaural,sommeil,meditation,concentration,ASMR,cafe,foret | 95/100 |
| de-DE | Oasis: Schlafklänge & Fokus 3D | 30/30 | Schlaf, Fokus, Entspannung. | 27/30 | rauschen,weiss,braun,rosa,regen,gewitter,wind,binaural,schlaf,fokus,entspannung,tinnitus,ASMR,lernen | 99/100 |
| es-ES | Oasis: Sonidos 3D para Dormir | 29/30 | Sueño, concentración, calma. | 28/30 | ruido,blanco,marron,rosa,lluvia,viento,binaural,sueno,concentracion,relajacion,tinnitus,ASMR,cafe | 96/100 |
| it | Oasis: Suoni 3D per Dormire | 27/30 | Sonno, concentrazione, relax. | 29/30 | rumore,bianco,marrone,rosa,pioggia,temporale,vento,binaurale,sonno,concentrazione,relax,tinnito,ASMR | 99/100 |
| pt-BR | Oasis: Sons 3D para Dormir | 26/30 | Sono, foco, relaxamento. | 24/30 | ruido,branco,marrom,rosa,chuva,trovao,vento,binaural,sono,foco,concentracao,relaxamento,ASMR,cafe | 96/100 |

Catégories App Store : `Health & Fitness` (primaire), `Lifestyle` (secondaire). **Aucune sous-catégorie n'est définie** (`primary_first_sub_category.txt` et suivants sont vides). Le copyright est également vide.

### 2.2 Sept problèmes ASO concrets

**a) Doublons titre/sous-titre/keywords.** Apple tokenise les trois zones en un seul index. Répéter `sleep` dans le keyword field alors que `Sleep Sounds` est dans le titre ne fait qu'occuper de la place. EN gaspille `sleep`, `focus` ; FR gaspille `sommeil`, `concentration` ; DE gaspille `schlaf`, `fokus` ; ES gaspille `sueno`, `concentracion` ; IT gaspille `sonno`, `concentrazione` ; PT gaspille `sono`, `foco`, `concentracao`. Au cumulé sur les 6 langues, c'est ~80 caractères perdus.

**b) Keywords faibles.** `ASMR` (off-brand : Oasis n'est pas une app ASMR), `cafe` (single word, pas de valeur sans "noise"), `lernen` (très généraliste), `foret` (rang faible, redondant avec la description), `wind`/`vent`/`viento` (volume modeste comparé à `rain`/`pluie`/`lluvia`).

**c) Termes haute-volume manquants.** Aucune des 6 fiches n'inclut `ambient`/`ambiance`/`ambient`/`ambiente`, `mixer`/`mixage`/`mixer`/`mezclador`, `ocean`/`océan`/`ozean`/`océano`, `fan`/`ventilateur`/`ventilator`/`ventilador`, `study`/`étude`/`studie`/`estudio`, `meditation`/`méditation`/`meditation`/`meditación`, `timer`/`minuteur`/`timer`/`temporizador`, `music`/`musique`/`musik`/`música`. Ce sont les top-10 du segment Audio Wellness iOS (sommeil + focus + ambient) selon les outils ASO publics (Sensor Tower, Mobile Action Q1 2026) — précisément les requêtes que la stratégie multi-usage §0 vise à capter en plus du trafic sleep.

**d) Aucune URL marketing/privacy** dans `fastlane/metadata/`. Le code (`AppConfiguration.supportURL`) pointe vers une page Notion. Bien — mais ASC réclame une *Privacy Policy URL* obligatoire pour les apps qui utilisent RevenueCat (donc Oasis). Si elle n'est pas remplie côté ASC, c'est un risque de rejet et un signal négatif pour l'utilisateur sur la fiche.

**e) Pas de sous-catégorie.** ASC permet jusqu'à 2 sous-catégories sous chaque catégorie. Pour Health & Fitness, "Mind & Body" est l'évidence. Sous Lifestyle, "Travel" peut surprendre mais cible le persona "voyage / chambre d'hôtel bruyante". Activer ces deux slots ne coûte rien et augmente la visibilité dans le browse.

**f) Promotional Text peu exploité.** Apple autorise 170 caractères, modifiable sans review (= testable rapidement). Toutes les langues sont en-deçà (143-160 car.). C'est l'endroit idéal pour pousser un message saisonnier, une mise à jour récente, ou un "social proof" si tu en as.

**g) Le nom DE pèse 30 octets en UTF-8** (`Oasis: Schlafklänge & Fokus 3D`) avec le `ä` qui compte double en bytes mais simple en caractères. ASC compte en caractères, donc c'est OK — vérifier néanmoins lors du prochain upload que fastlane n'envoie pas une longueur en bytes. Aucun risque opérationnel à ce jour, juste une note.

### 2.3 Description et release notes

Les 6 descriptions sont **bien structurées** (Pourquoi → Gratuit → Premium → Cas d'usage → Outro) et cohérentes entre langues. La phrase d'ouverture "Drift off faster. Focus deeper. Without a subscription." est forte (le problème + le moat en deux lignes). Le seul angle mort : l'absence de "**social proof**" dans les 5 premières lignes (avant le *more* qu'Apple plie sur la fiche). Dès que tu as un volume de notes, ajouter "Loved by 10k+ sleepers" ou "Featured by Apple" serait un upgrade immédiat — à conditionner à de la donnée réelle, pas à inventer.

Les release notes 1.4.1 sont génériques ("performance optimizations, bug fixes"). Ce champ est lu : un utilisateur hésitant qui voit "Bug fixes" assume une app pas finie. Passer à un ton "ce qu'on a amélioré pour ton sommeil" convertit mieux.

---

## 3. Diagnostic actuel — screenshots

### 3.1 Inventaire

Chaque locale dispose de **10 captures finales** sous `fastlane/screenshots/<locale>/figma-pro/01_hero.jpg` à `10_paywall.jpg`, plus les captures brutes `iPhone 17 Pro Max-XX.png`. C'est le contenu uploadé à ASC via le lane `appstore_release` (Fastfile §122). Format 1320×2868, JPEG ~500 ko/pièce. Dimensions et taille conformes à la spec App Store 6.9″.

L'identité visuelle est cohérente avec le brief `DESIGN_BRIEF_APP_STORE_SCREENSHOTS.md` (gradient 2-stops par slide, couleur d'humeur par scénario, headline centré, device frame iPhone 17 Pro Max, pas de halo / pas de grain). Le rendu actuel est **plus chaleureux** (tons crème/sable) que le brief original (gradients très saturés type Endel) — ce n'est pas un problème, juste un choix d'exécution à conscientiser pour rester cohérent dans les futures itérations.

### 3.2 Critique du Slide 01 (le plus important)

C'est la capture qui pilote 60 à 70 % de la décision d'install (la barre horizontale du Search affiche les 3 premières en pleine largeur, le Browse n'en montre qu'une).

Le headline actuel "**Craft your perfect ambience**" est sur le **bon angle stratégique** (création, mixage, personnalisation — la différenciation §0) et ne doit pas être remplacé par un message sleep-led. Ce qu'il manque pour que cet angle convertisse : un eyebrow qui le contextualise (pour qui, pour quoi), un sous-titre qui prouve la variété des usages (pas trois claims diluants), et une icône eyebrow qui dépasse le simple ornement.

| Élément | État actuel (en-US) | Diagnostic | Recommandation |
|---|---|---|---|
| Eyebrow | Petite icône lune+étoiles seule | Aucun message verbal — l'icône lune renforce involontairement le positionnement sleep-only | Eyebrow textuel multi-usage : **"FOR SLEEP, FOCUS OR FLOW"**. Garder une icône mais plus neutre (sparkles ou waves) |
| Headline | "Craft your perfect ambience." | **Bon angle, garder.** C'est la vraie différenciation d'Oasis et Apple ne pénalise pas un headline sans keyword sleep si keywords + subtitle en portent | Garder ou décliner légèrement : "Build your perfect ambience." / "Craft an ambience for any mood." |
| Subhead | "Mix 20 immersive sounds. Offline. No subscription." | Trois claims dans une phrase — diluant. "Immersive" n'est pas un signal de recherche | **"20 sounds. For sleep, focus, work or rest."** — montre la variété, prouve qu'Oasis n'est pas mono-usage |
| Device | Capture du home avec mix premium 10 canaux actif | OK | OK |
| Background | Gradient orange-sable | Peu de saturation comparé aux refs — peu distinctif au thumbnail | Ne pas changer, mais tester un B-variant gradient violet (focus canon) ou cyan (multi-usage neutre) |

Le problème central : le slide 01 d'aujourd'hui *dit ce que l'app fait* (mix d'ambiances) mais ne *prouve pas la variété des contextes d'usage*. La proposition ci-dessus garde l'angle créateur et ajoute la preuve multi-usage en eyebrow + subhead.

### 3.3 Critique du flux 01→10

L'ordre actuel suit la logique produit (hero → library → detail → binaural → spatial → presets → timer → free home → library teaser → paywall). C'est cohérent narrativement mais sous-optimal pour un scrolleur impatient. Apple n'affiche que **3 captures** dans le Search horizontal et **5** dans le Today/Browse. Donc les slides 01-03 portent l'essentiel.

Aujourd'hui : 01 hero, 02 library (signal d'abondance), 03 detail (preuve d'authenticité). Bon trio. Mais **04 binaural** (un panneau technique avec 4 modes) est probablement sous-converti pour un user grand public qui ne sait pas ce qu'est un binaural beat. Le déplacer plus loin et remonter **07 timer** ou **08 free home** ferait monter la "promesse simple" plus vite.

Recommandation d'ordre A/B : `01 hero → 02 library → 07 timer → 05 spatial → 08 free home → 03 detail → 04 binaural → 06 presets → 09 library teaser → 10 paywall`. À tester via Custom Product Pages (gratuit, jusqu'à 35 par app).

### 3.4 Cohérence multilingue — proposition par langue

Les 6 versions du Slide 01 partagent la même structure et les mêmes couleurs — bonne hygiène. Le headline existant est déjà sur l'angle "création / mixage / ambiance" dans les 6 langues, ce qui est cohérent avec le positionnement §0. On garde donc l'esprit, on ajoute eyebrow + sous-titre multi-usage.

| Locale | Eyebrow proposé (24pt UC) | Headline (garder ou décliner) | Subhead proposé |
|---|---|---|---|
| en-US | FOR SLEEP, FOCUS OR FLOW | Craft your perfect ambience. | 20 sounds. For sleep, focus, work or rest. |
| fr-FR | POUR DORMIR, BOSSER, RESPIRER | Créez votre ambiance idéale. | 20 sons. Sommeil, focus, sieste, lecture. |
| de-DE | ZUM SCHLAFEN, FOKUS, AUSRUHEN | Gestalte deine Klangwelt. | 20 Klänge. Schlaf, Fokus, Pause, Lesen. |
| es-ES | DORMIR, CONCENTRARSE, RESPIRAR | Crea tu ambiente ideal. | 20 sonidos. Sueño, foco, siesta, lectura. |
| it | DORMIRE, CONCENTRARSI, RIPOSARE | Crea la tua atmosfera. | 20 suoni. Sonno, focus, pausa, lettura. |
| pt-BR | DORMIR, FOCAR, DESCANSAR | Crie seu ambiente ideal. | 20 sons. Sono, foco, soneca, leitura. |

(Headlines existants vérifiés sur EN et FR — à confirmer pour les autres locales en regardant directement chaque `figma-pro/01_hero.jpg`.)

### 3.5 App Preview vidéo : absente

ASC accepte jusqu'à **3 vidéos par locale** (15-30s, format portrait 886×1920 ou 1080×1920). Aujourd'hui, aucune locale n'en a. C'est une opportunité significative : selon Apple's own data (WWDC 2023), une App Preview augmente le taux de conversion de 15 à 30 % en moyenne, avec des pics au-delà de 40 % sur les apps "expérience" (audio, jeu, méditation).

Pour Oasis : 20 secondes suffisent. Plan-séquence sur le mixeur, doigt qui pousse les sliders, audio "rain + thunder + birds" en fond, transition vers le spatial panel qui montre la 3D, fade vers le paywall avec "Pay once. Yours forever." en surimpression. **Pas de voix off** = pas de retravail i18n, une seule vidéo pour les 6 marchés.

---

## 4. Recommandations ASO — par langue

Dans cette section, chaque tableau propose une **variante prioritaire** (A) et une **variante de test** (B) pour permettre un A/B propre via Custom Product Pages (cf. §6.4). Les comptages sont vérifiés.

Règles appliquées :
- Aucun mot répété entre name, subtitle, et keywords (Apple n'indexe qu'une fois).
- Pas de stop words, pas d'espaces dans le keyword field.
- Mots haute-volume (selon Sensor Tower / Mobile Action benchmarks publics 2025-2026) priorisés.
- Termes faibles supprimés : `ASMR` (off-brand), `cafe`/`café` seul (pas indexable utilement sans pair), `wind`/`vent` (volume modeste vs `rain`).

### 4.1 EN-US

| Champ | Variante A (recommandée) | car. | Variante B (test) | car. |
|---|---|---:|---|---:|
| Name | Oasis: Nature Sound Mixer 3D | 28 | Oasis: Mix Nature for Any Mood | 30 |
| Subtitle | Sleep, focus, work, nap, calm. | 30 | For sleep, focus or deep work. | 30 |
| Keywords | rain,white,noise,brown,pink,ambient,ocean,fan,thunder,music,meditation,timer,insomnia,reading,yoga | 98 | rain,white,noise,brown,pink,ambient,ocean,fan,thunder,music,meditation,study,nap,reading | 92 |

*Rationale A* — repositionnement multi-usage : on sort le titre du carcan "sleep aid" pour le repositionner en "Nature Sound Mixer" (le terme exact que cherchent les utilisateurs avancés du segment ambient), avec "3D" qui signale la différenciation technique. Le sous-titre liste **5 cas d'usage** qui prouvent la variété et capturent autant de cohortes (sleep / focus / study / work / nap). Le keyword field garde les termes sleep haute-volume (`rain`, `insomnia`, `calm`) parce qu'ils captent du trafic search sans s'afficher sur la fiche — c'est la couche "ASO traffic", découplée de la couche "positionnement / conversion".

*Rationale B* — test "mood-led" : titre verbe d'action ("Mix Nature"), sous-titre focus/work-led pour aller chercher la cohorte productivity (qui ne se reconnaît pas dans une sleep app).

### 4.2 FR-FR

| Champ | Variante A (recommandée) | car. | Variante B (test) | car. |
|---|---|---:|---|---:|
| Name | Oasis : Mixeur de Sons Nature | 29 | Oasis : Sons Nature 3D, Focus | 29 |
| Subtitle | Sommeil, focus, sieste, calme. | 30 | Pour dormir, bosser, respirer. | 30 |
| Keywords | pluie,bruit,blanc,brun,ambiance,ocean,orage,musique,meditation,etude,acouphene,minuteur,lecture | 95 | pluie,bruit,blanc,brun,ambiance,ocean,orage,musique,meditation,etude,nuit,relax | 80 |

*Rationale A* — repositionnement multi-usage : titre "Mixeur de Sons Nature" capte la requête `mixeur sons` (terme exact des utilisateurs avancés FR) et signale immédiatement que c'est un outil de création, pas un sleep aid. Sous-titre énumère **4 cas d'usage** dont `sieste` (= nap, point spécifique de ta vision produit) et `calme` (= meditation/lecture/yoga implicites). Keywords garde les termes sleep haute-volume (`pluie`, `bruit`, `blanc`) sans les afficher.

*Rationale B* — test "lifestyle-led" : sous-titre "Pour dormir, bosser, respirer" — verbes d'action, ton plus humain, capte une cohorte plus large.

Note : le `:` français normé veut une espace insécable avant. Apple accepte les deux formes ; "Oasis :" avec espace est correct typographiquement.

### 4.3 DE-DE

| Champ | Variante A (recommandée) | car. | Variante B (test) | car. |
|---|---|---:|---|---:|
| Name | Oasis: Naturklang-Mixer 3D | 26 | Oasis: Klangmixer Alltag 3D | 27 |
| Subtitle | Schlaf, Fokus, Pause, Lesen. | 28 | Zum Schlafen, Fokus & Lesen. | 28 |
| Keywords | regen,weiss,rauschen,braun,ambient,ozean,ventilator,donner,musik,meditation,timer,tinnitus,arbeit | 97 | regen,weiss,rauschen,braun,rosa,ambient,ozean,ventilator,donner,musik,meditation,studie | 87 |

*Rationale A* — repositionnement multi-usage : titre "Naturklang-Mixer" capte la requête `naturklang mixer` (recherche d'utilisateurs avancés DE) et le terme `mixer` qui n'était pas indexé. Sous-titre énumère **4 cas d'usage** dont `Pause` (= power-nap allemand) et `Lesen` (= lecture, contexte calme/méditation). Keywords garde les termes sleep haute-volume (`regen`, `weiss`, `rauschen`) sans les afficher.

*Rationale B* — la variante "Klangmixer für jeden Tag" est trop longue (31), à raccourcir si tu veux la tester (ex. "Oasis: Klangmixer Alltag 3D" = 27).

Attention : DE compte les caractères composés (ä, ö, ü, ß) comme un caractère, **pas** deux. Vérifier dans ASC après upload (UI affiche le compteur).

### 4.4 ES-ES

| Champ | Variante A (recommandée) | car. | Variante B (test) | car. |
|---|---|---:|---|---:|
| Name | Oasis: Mezclador de Sonidos 3D | 30 | Oasis: Mezclador Naturaleza 3D | 30 |
| Subtitle | Sueño, foco, siesta, lectura. | 29 | Para dormir, trabajar, leer. | 28 |
| Keywords | lluvia,ruido,blanco,marron,rosa,ambiente,oceano,ventilador,trueno,musica,meditacion,estudio,insomnio | 100 | lluvia,ruido,blanco,marron,rosa,ambiente,oceano,ventilador,trueno,musica,meditacion,naturaleza | 94 |

*Rationale A* — repositionnement multi-usage : titre "Mezclador de Sonidos 3D" — `mezclador` est le terme exact de recherche en ES pour cette catégorie d'app, jamais utilisé jusqu'ici. Sous-titre énumère **4 cas d'usage** dont `siesta` (cas d'usage très espagnol, à privilégier) et `lectura`. Keywords garde les termes sleep haute-volume (`lluvia`, `ruido`, `blanco`).

*Rationale B* — verbes d'action ("Para dormir, trabajar, leer") qui parlent au persona productivité.

### 4.5 IT

| Champ | Variante A (recommandée) | car. | Variante B (test) | car. |
|---|---|---:|---|---:|
| Name | Oasis: Mixer Suoni Natura 3D | 28 | Oasis: Mixer di Suoni 3D | 24 |
| Subtitle | Sonno, focus, pausa, lettura. | 29 | Per dormire, studio, riposo. | 28 |
| Keywords | pioggia,rumore,bianco,marrone,rosa,ambiente,oceano,musica,meditazione,acufene,timer,studio,lavoro | 97 | pioggia,rumore,bianco,marrone,rosa,ambiente,oceano,ventilatore,musica,meditazione,timer,sonno | 92 |

*Rationale A* — repositionnement multi-usage : titre "Mixer Suoni Natura" — `mixer` est anglicisme courant en IT pour ce type d'app, signal différenciation immédiat. Sous-titre énumère **4 cas d'usage** dont `pausa` (= micro-sieste, contexte travail) et `lettura`. Keywords garde les termes sleep haute-volume (`pioggia`, `rumore`, `bianco`).

*Rationale B* — variante plus courte, laisse de la place dans le sous-titre pour le verbe d'action.

### 4.6 PT-BR

| Champ | Variante A (recommandée) | car. | Variante B (test) | car. |
|---|---|---:|---|---:|
| Name | Oasis: Mixer de Sons Natureza | 29 | Oasis: Mix de Sons 3D Foco | 26 |
| Subtitle | Sono, foco, soneca, leitura. | 28 | Para dormir, focar, relaxar. | 28 |
| Keywords | chuva,ruido,branco,marrom,rosa,ambiente,oceano,ventilador,trovao,musica,meditacao,estudo,zumbido | 96 | chuva,ruido,branco,marrom,rosa,ambiente,oceano,ventilador,trovao,musica,meditacao,estudo,timer | 94 |

*Rationale A* — repositionnement multi-usage : titre "Mixer de Sons Natureza" capte `mixer` + `sons` + `natureza` (3 termes haute-valeur PT). Sous-titre énumère **4 cas d'usage** dont `soneca` (= nap/sieste, très brésilien) et `leitura`. Keywords garde `chuva` (top 1 PT Sleep), `ruido`, `branco`, `zumbido` (= tinnitus PT).

*Rationale B* — alternative qui pousse `Foco` dans le titre pour la cohorte productivity.

### 4.7 Sous-catégories à activer

À remplir dans `fastlane/metadata/primary_first_sub_category.txt`, `primary_second_sub_category.txt`, `secondary_first_sub_category.txt`, `secondary_second_sub_category.txt` :

| Slot | Valeur recommandée |
|---|---|
| `primary_first_sub_category` | MIND_AND_BODY |
| `primary_second_sub_category` | (laisser vide ou : SLEEP, si Apple expose la sous-cat — vérifier dans l'UI ASC) |
| `secondary_first_sub_category` | TRAVEL |
| `secondary_second_sub_category` | (laisser vide) |

Ces slots déterminent les charts sectoriels où l'app peut apparaître. Sans eux, Oasis n'est listé que dans les charts globaux Health & Fitness où la concurrence est féroce.

---

## 5. Recommandations Screenshots & Description

### 5.1 Slide 01 — renforcer l'angle multi-usage existant

Le headline actuel "Craft your perfect ambience" (et ses traductions) est sur la bonne ligne stratégique : il porte la **création / mixage / personnalisation**, pas le sommeil. Il faut le **garder** et le renforcer avec :

- **Eyebrow textuel** (aujourd'hui une simple icône lune+étoiles qui suggère sleep-only). Format : 24pt SF Pro Text Semibold, uppercase, +12% letter-spacing, accent color du slide (`#F5A35E` pour le warm ember). Texte multi-usage (cf. tableau ci-dessous).
- **Subhead orienté multi-usage** au lieu du triple-claim actuel ("Mix 20 immersive sounds. Offline. No subscription."). Le nouveau subhead doit prouver la **variété d'usages** dans la phrase.

Eyebrow par langue (multi-usage) :

| Locale | Eyebrow proposé |
|---|---|
| en-US | FOR SLEEP, FOCUS OR FLOW |
| fr-FR | POUR DORMIR, BOSSER, RESPIRER |
| de-DE | ZUM SCHLAFEN, FOKUS, AUSRUHEN |
| es-ES | DORMIR, CONCENTRARSE, RESPIRAR |
| it | DORMIRE, CONCENTRARSI, RIPOSARE |
| pt-BR | DORMIR, FOCAR, DESCANSAR |

Subhead par langue (énumère 4 contextes) :

| Locale | Subhead proposé |
|---|---|
| en-US | 20 sounds. For sleep, focus, work or rest. |
| fr-FR | 20 sons. Sommeil, focus, sieste, lecture. |
| de-DE | 20 Klänge. Schlaf, Fokus, Pause, Lesen. |
| es-ES | 20 sonidos. Sueño, foco, siesta, lectura. |
| it | 20 suoni. Sonno, focus, pausa, lettura. |
| pt-BR | 20 sons. Sono, foco, soneca, leitura. |

L'eyebrow existant (icône lune+étoiles) doit être **remplacé** : la lune signale visuellement "sleep app", ce qui contredit la stratégie de différenciation. Une icône `sparkles` (ondes ou waveform) renforcerait l'angle "création". Si tu tiens à garder une icône au-dessus de l'eyebrow textuel, prendre la waveform plutôt que la lune.

L'eyebrow lifetime ("PAY ONCE. SLEEP FOREVER." — variante précédente) reste un bon message pour le **Slide 10 paywall**, où il est déjà en headline ("One payment. Yours for life."). Sur le Slide 01 hero, on privilégie la différenciation multi-usage.

### 5.2 Slide 04 (binaural) — descendre dans l'ordre

Le binaural est un feature techniquement riche mais opaque pour l'utilisateur grand public. En position 4, il consomme un slot premium (visible au-dessus de la fold sur le Today/Browse). Le déplacer en position 7 ou 8 et remonter le timer (slide 07) ou le free home (slide 08) ferait monter une promesse plus universelle plus tôt.

Ordre A/B à tester :
- **Variante A (actuelle)** : 01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10
- **Variante B (proposée)** : 01 → 02 → 07 (timer) → 05 (spatial) → 08 (free home) → 03 (detail) → 04 (binaural) → 06 (presets) → 09 (teaser) → 10 (paywall)

Cette refonte ne nécessite pas de retravail d'asset — c'est un simple réordonnancement dans ASC, ou via un Custom Product Page distinct si tu veux mesurer.

### 5.3 Description — repositionner sur l'angle multi-usage

La structure actuelle est sleep-led ("Drift off faster. Focus deeper. Without a subscription."). Quatre changements à apporter par locale pour aligner avec la stratégie §0 :

**a) Première ligne — repositionner sur la création.** Aujourd'hui (EN) : *"Drift off faster. Focus deeper. Without a subscription."* — la promesse principale est sleep, focus arrive en deuxième. Proposition :

> *"Build the ambience that fits your moment. Sleep, focus, work, rest — your call."*

Cette phrase pose immédiatement (i) la création comme acte central, (ii) la **variété de moments** comme bénéfice, (iii) le contrôle utilisateur ("your call") comme posture. Pas de mention du sommeil en premier — le sommeil arrive comme un usage parmi d'autres.

Adaptations par langue :
- FR : *"Composez l'ambiance qui colle à votre moment. Sommeil, focus, travail, repos — vous décidez."*
- DE : *"Gestalte die Atmosphäre, die zu deinem Moment passt. Schlaf, Fokus, Arbeit, Pause — du entscheidest."*
- ES : *"Construye el ambiente para tu momento. Sueño, foco, trabajo, descanso — tú decides."*
- IT : *"Costruisci l'atmosfera del tuo momento. Sonno, focus, lavoro, riposo — decidi tu."*
- PT : *"Construa a atmosfera do seu momento. Sono, foco, trabalho, descanso — você decide."*

**b) Bloc "WHY OASIS"** : les 4 lignes actuelles sont défensives (no subscription, no account, no tracking, no ads). Les passer en mode bénéfice positif :
- Au lieu de `One-time purchase. No subscription, ever.` → `Pay once, keep forever — including every future sound.`
- Au lieu de `100% offline — no streaming, no data drain.` → `Plays on a plane, in a tent, anywhere — no internet needed.`
- Au lieu de `No account, no tracking, no ads.` → garder tel quel (c'est devenu une attente baseline).

**c) Bloc "USE OASIS TO" — ré-équilibrer les usages.** Le bloc actuel est centré sur le sommeil ("Fall asleep faster", "Calm tinnitus") + une ligne focus ("deep work") + une ligne sociale ("Mask office chatter") + une ligne lecture. La proposition rééquilibre pour que **chaque usage majeur ait un poids visuel équivalent** :

> *Use Oasis to:*
> - *Drift off and stay asleep through the night*
> - *Take a real, restorative power-nap in 20 minutes*
> - *Hold focus through a long deep-work session*
> - *Mask open-office chatter or hotel-room traffic*
> - *Read or meditate without the silence pressing in*
> - *Calm racing thoughts before bed*

Six lignes, deux par grand contexte (sommeil, sieste, focus, masquage, calme, soirée). Ajoute aussi un usage **sieste / power-nap** explicite (qui manque aujourd'hui) — c'est un cas d'usage qui distingue Oasis des sleep aids classiques.

**d) Bloc "FREE / PREMIUM"** : conserver la structure mais adapter le ton — mentionner explicitement que la version gratuite suffit pour des usages courts (sieste, focus 30 min) et que Premium libère le long format (sommeil 2h, sessions deep work 2h). Cela rationalise l'achat sans pression.

### 5.4 Promotional Text — exploitation

Ce champ (170 car., modifiable sans review) est aujourd'hui sous-utilisé (143-160 car.). Trois usages que tu peux faire **tourner mensuellement** sans toucher au reste :

- Saisonnier ("Pour les nuits d'été : pluie tropicale et ventilateur. Sans abonnement.")
- Highlight de feature ("Nouveau : Audio 3D sur les 20 ambiances. Un achat à vie.")
- Social proof (quand tu as 4.5+ avec >100 reviews : "Note 4.7 ★ — un achat unique, pour toujours.")

Le champ est visible **au-dessus** de la description, c'est un endroit prime pour pousser un message timing-sensitive.

### 5.5 Release Notes — passage en mode produit

Actuel (1.4.1 EN) :
```
Oasis 1.4.1
• Redesigned interface
• Performance optimizations
• Bug fixes
• Audio quality improvements
One-time purchase. No subscription, no account, no ads — ever.
```

Proposition pour la prochaine version :
```
Oasis 1.5
• Smoother fades when you swap presets at night
• Cleaner mixer interface — easier to read in the dark
• Audio engine 30% lighter on battery
• Free updates included with your one-time purchase
```

Le ton "ce qu'on a fait pour ton expérience" convertit mieux que "performance optimizations" qui sonne générique.

---

## 6. Recommandations conversion in-app (bonus)

Tu n'as pas priorisé l'axe paywall/onboarding mais quelques observations valent le détour. Le funnel actuel est globalement solide (paywall contextuel, preview signature 1×/jour, banner discret, anchor "café à Paris", review prompt après 5 min ou N sessions). Trois leviers où je vois de la marge :

### 6.1 Onboarding — la page 3 est sous-employée

`OnboardingView.swift` page 3 ("20 sounds, one purchase / Start free with 3 sounds and 3D audio. Unlock 17 more...") est la dernière chose vue avant l'app. C'est l'endroit idéal pour proposer une **trial-purchase** (offrir le paywall à la fin de l'onboarding) — pas un paywall agressif, mais un bouton secondaire "See Premium" à côté du primaire "Start listening". Selon les data RevenueCat publiques, ce pattern convertit 4-7 % des utilisateurs *avant même d'utiliser l'app* (haute intention).

### 6.2 Preview signature — restreindre à 1×/semaine, pas 1×/jour

Aujourd'hui la preview "Try a Premium mix" est limitée à 1 fois par jour (cf. `signaturePreviewLastPlayedAt` + comparaison dans `AppModel`). C'est généreux. Le passage à 1×/semaine forcerait l'urgence et augmenterait l'effet de rareté. À A/B-tester si tu as un sample size suffisant.

### 6.3 Anchor "prix d'un café à Paris"

Très fort. Garder. Une variante à tester : **comparaison à un abonnement compétiteur** explicite ("Less than one month of Calm. For life."). Risqué juridiquement si on nomme le concurrent ; faisable si on dit "Less than one month of a subscription app. For life." 

### 6.4 Custom Product Pages — activer maintenant

ASC permet jusqu'à **35 Custom Product Pages** par app, chacune avec ses propres screenshots/promo text/preview vidéo. C'est gratuit, ça permet :
- D'attribuer le trafic par campagne (URL différente par source : Reddit, Instagram, blog, etc.)
- D'A/B-tester le slide 01 sans impacter la fiche principale
- De cibler des personae distincts (la version "sleep" vs "focus" vs "travel")

Recommandation initiale :
- Page principale : variante A (cf. §4)
- CPP 1 — "Sleep First" : slide 01 hero replacé par une variante "Drift off in 4 minutes." + screenshots dans l'ordre 01→07→08→… (timer en position 3)
- CPP 2 — "Focus" : hero "Stay focused for hours." + screenshots commence par 04 binaural et 05 spatial

Ne pas démarrer plus de 2-3 CPP au début — sinon tu dilues le sample size et tu ne peux rien conclure.

---

## 7. Plan d'action priorisé

### 7.1 Quick wins — Semaine 1 (~7h de travail)

| # | Action | Fichiers | Effort | Impact estimé |
|---|---|---|---:|---|
| 1 | Réécrire **titres** 6 langues — variante A (repositionnement multi-usage cf. §4) | `fastlane/metadata/<locale>/name.txt` | 30min | Impossible à isoler, mais déverrouille la stratégie complète |
| 2 | Réécrire **sous-titres** 6 langues — variante A (énumération 4 cas d'usage) | `fastlane/metadata/<locale>/subtitle.txt` | 1h | +5-15 % conversion impression→tap, capte cohortes focus/work |
| 3 | Réécrire **keyword field** 6 langues — variante A | `fastlane/metadata/<locale>/keywords.txt` | 1h | +20-35 % impressions organiques (garde sleep traffic) |
| 4 | Activer sous-catégories Mind & Body + Travel | `fastlane/metadata/primary_first_sub_category.txt` etc. | 5min | +5-10 % discovery via charts sectoriels |
| 5 | Réécrire promo_text avec message saisonnier multi-usage | `fastlane/metadata/<locale>/promotional_text.txt` | 30min | Aucun impact direct mesuré, mais permet itération mensuelle |
| 6 | Réécrire release notes (mode produit) | `fastlane/metadata/<locale>/release_notes.txt` | 30min | Marginal — utile sur les utilisateurs hésitants |
| 7 | Slide 01 — eyebrow textuel multi-usage + nouveau subhead 4 cas d'usage (re-export 6 langues) | `fastlane/screenshots/<locale>/figma-pro/01_hero.jpg` | 2h | +10-25 % conversion install — c'est la pièce la plus à fort impact |
| 8 | Réécrire première ligne description (positionnement création) — 6 langues | `fastlane/metadata/<locale>/description.txt` | 1h | +2-5 % conversion ; cohérence avec nouveau positionnement |
| 9 | Push via fastlane (`appstore_metadata` puis `appstore_release`) | — | 30min | — |

Total : ~7h. Aucun changement de code app. Le titre + sous-titre forcent une **nouvelle review Apple** (chaque changement de name/subtitle déclenche une review obligatoire — typiquement 24-48h). Les keywords, promo_text et release notes passent sans review. Les sous-catégories peuvent demander une review selon la version d'ASC.

### 7.2 Court terme — Mois 1 (~2 jours de travail)

| # | Action | Effort | Impact estimé |
|---|---|---:|---|
| 1 | Tourner App Preview vidéo 20s (silencieuse, universelle 6 marchés) | 1 jour | +15-30 % conversion install |
| 2 | Configurer 2 Custom Product Pages (Sleep First / Focus) | 4h | Permet A/B testing propre |
| 3 | Tester ordre B des screenshots (04 binaural en position 7) sur la page principale | 30min + 30 jours d'observation | +3-8 % conversion (à mesurer) |
| 4 | Refaire la première ligne des descriptions (cf. §5.3.a) sur les 6 langues | 1h | +2-5 % conversion |
| 5 | Activer App Store Connect Analytics — paramétrer les events Sources de trafic / Pays / Conversion | 30min | Mesure |

### 7.3 Moyen terme — Trimestre 1 (~5 jours de travail)

| # | Action | Effort | Impact estimé |
|---|---|---:|---|
| 1 | Test paywall post-onboarding (page 3 → CTA secondaire "See Premium") | 1 jour code + 60 jours mesure | +4-7 % premium conversion |
| 2 | Refonte des 9 autres screenshots dans la veine du Slide 01 v2 (uniformiser headlines orientés bénéfice) | 2 jours design + export | +5-15 % conversion install |
| 3 | Tester réduction de la fréquence du Premium Preview à 1×/semaine | 30min code + 60 jours mesure | À mesurer (peut être négatif si trop agressif) |
| 4 | Ajout d'une 6e use-case "Hotel/Travel" dans la description | 30min | +2-5 % conversion sur le persona voyage |
| 5 | Test variante de CTA paywall ("Unlock for life" → "Get Oasis forever") | 30min code + 60 jours mesure | +1-3 % conversion |

---

## 8. Mesure & itération

### 8.1 Métriques à suivre dans App Store Connect (hebdo)

App Store Connect → Analytics → Métriques :

- **Impressions** (par source : App Store Search, App Store Browse, Web Referer, App Referer) — la base de l'ASO. Une hausse sur Search atteste que les keywords fonctionnent.
- **Product Page Views** — qualité de la fiche (titre/sous-titre/icône). Conversion impression → page view = signal de "do I want to know more".
- **Conversion Rate (Page View → Install)** — qualité des screenshots + description. C'est ici que les efforts §3 et §5 doivent payer.
- **Searches** (terme par terme) si tu actives "App Store Search" — montre les queries qui te ramènent du trafic.

Les 4 ensemble forment le funnel ASO : *Searches → Impressions → Page Views → Installs*.

### 8.2 Métriques in-app (RevenueCat + TelemetryDeck)

Le code instrumente déjà via `PremiumAnalytics` et `TelemetryDeckAnalyticsSink` — donc on a accès à :
- `paywall_shown` par source (sound, timer, preset, binaural, spatial, preview, manual)
- `paywall_dismissed` par source
- `purchase_succeeded` (côté RevenueCat)
- `preview_started` / `preview_finished`
- `inline_shown` par source
- `listened_60s` / `listened_5m` (engagement)
- `review_prompt_requested`

À monitorer dans TelemetryDeck dashboard hebdo :
- **Free→Trial→Paid funnel** (install → première lecture → paywall vu → purchase) — typique du segment Sleep ~3-6 % paid.
- **Conversion par paywall source** — quelle entrée convertit le mieux. Si `binaural` ou `preset` est faible, retravailler ces upsells inline.
- **Time to first purchase** — médiane à mesurer ; si > 7 jours, l'utilisateur a oublié l'app.

### 8.3 Tests A/B à prioriser

Ordre conseillé (un seul test à la fois pour éviter le confounding) :

1. **Slide 01 v2 vs v1** sur Custom Product Page — 30 jours, variation principale = headline + eyebrow.
2. **Subtitle ASO-first vs no-sub-first** sur la page principale — basculer §4.1 variante A et observer 30 jours.
3. **Ordre screenshots B vs A** — déplacer binaural en position 7.
4. **Paywall post-onboarding ON vs OFF** — RevenueCat Experiments si tu as l'add-on, sinon flag manuel.
5. **CTA paywall** — "Unlock for life" vs "Get Oasis forever".

---

## 9. Pour aller plus loin — accès à me fournir

J'ai travaillé sur le seul périmètre que j'avais (codebase + metadata fastlane + screenshots locaux). Pour affiner les recommandations avec de la donnée réelle, ouvrir dans Safari les écrans suivants en plein écran et me donner accès — je peux les lire par capture d'écran :

| Écran ASC | URL | Pourquoi |
|---|---|---|
| App Analytics → Métriques (90 derniers jours, par locale) | appstoreconnect.apple.com → My Apps → Oasis → Analytics → Metrics | Conversion actuelle, sources de trafic, impressions par locale |
| App Analytics → Sources (Search, Browse, Web, App) | idem → Sources | Identifier le canal le plus rentable |
| App Analytics → Searches (Top search terms, par store) | idem → Search | Quelles requêtes te ramènent du trafic *aujourd'hui* — ground truth |
| Sales & Trends → Sales (90j, par locale) | Sales & Trends → Sales | Volumes installs vs purchases premium par marché |
| Sales & Trends → Subscribers (si applicable) | Sales & Trends → Subscribers | Cohortes, mais probablement vide vu le modèle lifetime |

Une fois ces données récupérées, on pourra :
- Reprioriser les locales en fonction de la rentabilité réelle (peut-être que DE convertit beaucoup mieux que IT — alors on focalise les efforts sur DE)
- Calibrer les keywords sur les requêtes réelles (App Store Search te dit *exactement* sur quoi tu rankes)
- Mesurer l'impact post-déploiement des recommandations §7

Pour l'instant, les recommandations §4-§7 sont basées sur des bonnes pratiques publiques (Sensor Tower, Mobile Action, App Store Connect Help) et l'analyse statique de ta fiche, sans baseline de performance. Elles sont solides directionnellement mais à recalibrer dès qu'on a les chiffres réels.

---

## 10. Annexes

### 10.1 Caractères restants sur les variantes A (vérifiés via `wc -m`, V2 multi-usage)

| Locale | Name (cap 30) | Subtitle (cap 30) | Keywords (cap 100) |
|---|---:|---:|---:|
| en-US | 2 | 0 | 2 |
| fr-FR | 1 | 0 | 5 |
| de-DE | 4 | 2 | 3 |
| es-ES | 0 | 1 | 0 |
| it | 2 | 1 | 3 |
| pt-BR | 1 | 2 | 4 |

Tous les champs respectent les limites Apple. ES-ES keywords est à la limite (100/100), à surveiller si Apple change le compteur.

### 10.2 Mots cibles par marché — segment Audio Wellness iOS (2025-2026)

Liste indicative des keywords haute-volume du segment, qui est dominé par les requêtes "sleep". L'enjeu de la stratégie multi-usage §0 est de capter le trafic sleep (via le keyword field) **tout en gagnant aussi** les requêtes focus / mixer / ambient / nap qui sont moins compétitives. À recouper avec App Store Search réel quand on aura accès aux données ASC.

| Marché | Top 5 sleep (à capter via keywords) | Top 5 multi-usage (à capter via title/subtitle) |
|---|---|---|
| EN-US | sleep, rain, white noise, insomnia, calm | nature mixer, ambient, focus, study, nap |
| FR-FR | sommeil, pluie, bruit blanc, méditation, acouphène | mixeur sons, ambiance, focus, sieste, lecture |
| DE-DE | schlaf, regen, weißes rauschen, einschlafen, tinnitus | naturklang mixer, ambient, fokus, lernen, pause |
| ES-ES | sueño, lluvia, ruido blanco, insomnio, meditación | mezclador sonidos, ambiente, foco, siesta, estudio |
| IT | sonno, pioggia, rumore bianco, insonnia, meditazione | mixer suoni, ambiente, focus, studio, pausa |
| PT-BR | sono, chuva, ruído branco, insônia, zumbido | mixer sons, ambiente, foco, soneca, leitura |

### 10.3 Liste des fichiers à modifier (si tu pousses la variante A intégrale, V2 multi-usage)

```
fastlane/metadata/en-US/name.txt           (modifié — repositionnement)
fastlane/metadata/en-US/subtitle.txt       (modifié — multi-usage)
fastlane/metadata/en-US/keywords.txt       (modifié — garde sleep traffic)
fastlane/metadata/en-US/promotional_text.txt   (modifié — saisonnier)
fastlane/metadata/en-US/release_notes.txt  (modifié — mode produit)
fastlane/metadata/en-US/description.txt    (modifié — première ligne)
fastlane/metadata/fr-FR/...                (idem ×6 locales)
fastlane/metadata/primary_first_sub_category.txt   (créé : MIND_AND_BODY)
fastlane/metadata/secondary_first_sub_category.txt (créé : TRAVEL)
fastlane/screenshots/<locale>/figma-pro/01_hero.jpg (×6 — re-export Figma avec eyebrow + subhead V2)
```

Puis :
```bash
cd fastlane
bundle exec fastlane appstore_metadata    # push metadata sans screenshots
bundle exec fastlane appstore_release     # push metadata + screenshots
```

---

*Audit produit le 2 mai 2026 sur la base de la version 1.4.1 et de la dernière modification du dossier `fastlane/metadata` au 26 avril 2026. À recalibrer dès accès aux stats App Store Connect.*
