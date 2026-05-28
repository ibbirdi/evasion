# Plan de screenshots App Store FR

Objectif : produire une serie francaise qui vend Oasis comme un outil calme et premium pour dormir, se concentrer et se creer un refuge sonore, sans retomber dans le vocabulaire interne de l'app. Chaque capture doit prouver une promesse visible a l'ecran.

## Narrative

| Ordre App Store | Capture source | Role client | Element a mettre en avant | Copy FR prevue |
| --- | --- | --- | --- | --- |
| 1 | `01_hero` | Accroche principale : comprendre Oasis en 2 secondes. | Home en lecture, mix actif, controle central. | `SOMMEIL · CONCENTRATION · CALME` / `Votre refuge sonore, en quelques gestes.` / `35 vrais sons de nature. Hors ligne. Sans abonnement.` |
| 2 | `02_library` | Montrer la profondeur du catalogue. | Liste de sons active avec provenance visible. | `35 SONS DE NATURE` / `Composez l'ambiance exacte qu'il vous faut.` / `Pluie, foret, mer, feu de camp, oiseaux, orage... tout se dose finement.` |
| 3 | `03_ambiences` (`06_ambiences` source) | Mettre en avant la nouveaute cle : des ambiances sur mesure. | Sheet Mes ambiances avec capsules imagees mises en avant. | `MES AMBIANCES` / `Des ambiances sur mesure, jamais figees.` / `Le moteur audio fait varier volumes, nuances et placement a chaque ecoute.` |
| 4 | `07_timer` | Repondre au cas sommeil. | Menu minuteur ouvert. | `MINUTEUR` / `Laissez Oasis s'eteindre doucement.` / `15 min, 30 min, 1 h ou 2 h, selon votre rythme.` |
| 5 | `05_spatial` | Differencier Oasis des apps de sons standard. | Panneau de placement sonore. | `PLACEMENT SONORE` / `Installez la pluie ici, la foret la.` / `Placez chaque son autour de vous pour une scene plus naturelle.` |
| 6 | `08_free_home` | Rassurer : l'app est essayable gratuitement. | Home free avec sons inclus actifs. | `GRATUIT POUR COMMENCER` / `Demarrez sans compte.` / `3 sons inclus, minuteur et placement sonore.` |
| 7 | `03_detail_sheet` | Prouver la qualite des sons. | Detail d'un son avec carte/source. | `PRISES REELLES` / `Chaque son vient d'un vrai paysage.` / `Lieu, contexte et source restent visibles, pour une ambiance qui sonne juste.` |
| 8 | `04_binaural` | Ajouter une raison premium claire. | Selecteur binaural avec les 4 modes. | `ONDES BINAURALES` / `Trouvez votre rythme.` / `Delta, Theta, Alpha ou Beta pour dormir, souffler ou vous concentrer.` |
| 9 | `09_noise` | Ajouter une raison Premium claire. | Labo bruit avec lignes Vert et Ventilateur mises en avant. | `MASQUAGE SONORE` / `Chaque bruit cible une plage de frequences.` / `Bruit rose, bruit vert, ventilateur et cabine d'avion aident a lisser les sons irreguliers autour de vous.` |
| 10 | `10_paywall` | Conclure sur la confiance prix. | Paywall lifetime, CTA achat unique. | `PREMIUM A VIE` / `Un achat. Zero abonnement.` / `32 sons et 4 bruits en plus, modes binauraux et ambiances sauvegardees.` |

## Generation strategy

1. Capturer uniquement `fr-FR` avec le pipeline fastlane, pour eviter de figer les autres langues avant validation.
2. Composer les JPEGs via `scripts/generate_store_screenshot_comps.swift --lang fr-FR`.
3. Controler chaque sortie sur quatre axes : lisibilite miniature, exactitude produit, absence de vocabulaire obsolete, cadrage du telephone/pop-out.
4. Iterer sur `scripts/screenshot_content.json`, les scenarios XCTest ou le compositor jusqu'a obtenir une serie francaise validable.
5. Apres validation humaine, adapter la copy dans les cinq autres langues puis regenerer les 60 assets. Fait le 2026-05-28.

## Review FR 2026-05-28

| Asset stage | Verdict | Notes |
| --- | --- | --- |
| `01_hero` | Pret pour validation | Bonne accroche multi-usage, promesse claire "hors ligne / sans abonnement", home lisible et vivant. Retouche appliquee : "35 vrais sons de nature" plutot que "sons reels" pour une formulation plus naturelle. |
| `02_library` | Pret pour validation | Montre la profondeur du catalogue et le dosage. Le texte reste concret, sans jargon. Le pop-out Riviere donne un bon signal de controle fin. |
| `03_ambiences` | Pret pour validation | Remontee juste apres la bibliotheque. Le highlight borderless vise deux capsules d'ambiance, pas le minuteur, et la copy insiste sur le sur-mesure rendu vivant par le moteur audio. |
| `04_timer` | Pret pour validation | Promesse sommeil simple et visible. Le menu systeme prouve les durees sans ajouter d'explication lourde. |
| `05_spatial` | Pret pour validation | Differenciation forte : le screenshot montre immediatement la scene spatiale. Copy volontairement imagée avec pluie / foret. |
| `06_free_home` | Pret pour validation | Corrige pour rester exact : "3 sons inclus" plutot que "3 ambiances". L'absence de compte est un bon levier confiance. |
| `07_detail_sheet` | Pret pour validation | La carte et la fiche son donnent une preuve de qualite/source. Le message evite les claims flous type "studio quality". |
| `08_binaural` | Pret pour validation | Headline raccourcie apres controle visuel : "Trouvez votre rythme." est plus lisible en miniature et plus memorisable. |
| `09_noise` | Pret pour validation | Remplace l'ancienne slide teaser. La promesse Premium est plus preuve/science : les bruits sont presentes comme des plages de frequences utiles au masquage sonore, avec deux lignes visibles et actives. Les highlights sont arrondis et ombres, mais sans bordure blanche. |
| `10_paywall` | Pret pour validation | Cloture claire sur l'achat unique. Le paywall utilise le background plage Pexels de Pok Rie et une palette sable/eau douce, sans revenir a l'ancien design vert aurora/mint. Le CTA "Debloquer a vie" reste visible, et le paywall mentionne les 4 bruits en plus. |

## Technical QA FR

- `SCREENSHOT_LANGUAGES=fr-FR bundle exec fastlane screenshots` : 10 captures live, 0 echec.
- `swift scripts/generate_store_screenshot_comps.swift --lang fr-FR` : 10 composites generes avec noms finaux (`03_ambiences.jpg`, pas `06_ambiences.jpg`).
- `bundle exec fastlane stage_appstore_assets` : 10 fichiers stagés dans `fastlane/appstore-upload/fr-FR`.
- Tous les JPG FR controles sont en `1320x2868`, RGB, inferieurs a 2 MB.
- Les titres utilisent la nouvelle echelle plus visible du compositor, avec sous-titres reduits et blocs texte plus larges pour la lecture miniature.
- Le dossier d'upload FR suit l'ordre App Store : hero, library, ambiences, timer, spatial, free, detail, binaural, noise, paywall.
- La planche grande revue est `fastlane/screenshots/fr-FR/review-contact-sheet.jpg`.
- La planche miniature App Store est `fastlane/screenshots/fr-FR/review-thumbnail-sheet.jpg`.
- La planche d'ordre upload est `fastlane/appstore-upload/review-upload-sheet.jpg`.
- La metadata FR a ete relue pour rester coherente avec les screenshots : plus de promesse de sauvegarde gratuite, release notes alignees sur Mes ambiances.

## Technical QA all locales 2026-05-28

- `bundle exec fastlane screenshots` : 6 locales capturees sur iPhone 17 Pro Max (`en-US`, `fr-FR`, `de-DE`, `es-ES`, `it`, `pt-BR`), 0 echec.
- `swift scripts/generate_store_screenshot_comps.swift` : 60 composites generes avec noms finaux.
- `bundle exec fastlane stage_appstore_assets` : 60 fichiers stages dans `fastlane/appstore-upload/<locale>`.
- Audit mecanique : chaque locale contient les 10 JPG attendus en ordre App Store, `1320x2868`, RGB, tous inferieurs a 2 MB.
- Planches de revue par locale : `fastlane/appstore-upload/<locale>/review-contact-sheet.jpg`.
- Planche de revue globale : `fastlane/appstore-upload/review-upload-sheet-all-locales.jpg`.
- Les textes non francais ont ete adaptes par langue, pas calques mot a mot, en conservant les promesses produit validees : sons reels, Mes ambiances sur mesure, masquage sonore, Premium a vie sans abonnement.

## Upload manifest FR

| Fichier upload | Source | Poids | Hash court |
| --- | --- | --- | --- |
| `01_hero.jpg` | `01_hero` | 745 KB | `4b442db68c9a` |
| `02_library.jpg` | `02_library` | 655 KB | `1f604469c073` |
| `03_ambiences.jpg` | `06_ambiences` | 778 KB | `510b18bc6583` |
| `04_timer.jpg` | `07_timer` | 680 KB | `ef6d2155875d` |
| `05_spatial.jpg` | `05_spatial` | 593 KB | `ccab7196a54f` |
| `06_free_home.jpg` | `08_free_home` | 654 KB | `9fcb486831f0` |
| `07_detail_sheet.jpg` | `03_detail_sheet` | 628 KB | `5774a3926523` |
| `08_binaural.jpg` | `04_binaural` | 613 KB | `9a9f29f26556` |
| `09_noise.jpg` | `09_noise` | 638 KB | `101f1a200631` |
| `10_paywall.jpg` | `10_paywall` | 613 KB | `b9ba36e1ea65` |
