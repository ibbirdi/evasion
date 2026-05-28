---
title: Sound Backgrounds
status: stable
last_updated: 2026-05-28
tracks:
  - "ios-native/OasisNative/Assets.xcassets/SoundBackgrounds/**"
  - "ios-native/OasisNative/Assets.xcassets/OrganicBackgrounds/**"
  - "ios-native/OasisNative/Assets.xcassets/RoutineBackgrounds/**"
  - "ios-native/OasisNative/Models/SoundChannelMetadata.swift"
  - "ios-native/OasisNative/Views/Overlays/ComposePanel.swift"
related:
  - "sounds-catalog.md"
  - "../architecture/ui.md"
  - "../codebase/conventions.md"
---

# Sound Backgrounds

Ambient tracks use subtle place-photo watermarks from `Assets.xcassets/SoundBackgrounds`, mapped by `SoundChannel.backdrop`.

Non-place surfaces use the abstract texture family in `Assets.xcassets/OrganicBackgrounds`, mapped by `OrganicBackdrop` and usually rendered through `OrganicBackdropImage`. This includes Composer suggestion cards, ritual launch cards, Noise Lab blend cards, and binaural track cards. My Ambiences hero titles use shadow over imagery, and detail/plan row backgrounds must be clipped to the same rounded shape as their border so tint overlays never leak square corners. Keep the split strict: real field recordings can show representative places; abstract use cases should use organic textures instead of place photography.

`Assets.xcassets/RoutineBackgrounds` stores extra Pexels photos that are not tied to a specific sound. `AmbienceBackdropLibrary` exposes organic textures, ambient sound backdrops, binaural background assets, and these extra ambience photos to the My Ambiences save picker. User presets persist the selected asset name as `Preset.backdropAssetName`; older presets fall back to the strongest audible channel background. The save/edit background picker must show these assets in equal-size tiles and crop each image within its tile instead of letting source aspect ratios affect the grid. Every My Ambiences selector pill should be image-led, omit the leading glyph, and use a strong dark title shadow over the selected background. The shipped default ambiences should use unique background assets so the selector grid does not repeat base artwork, and the model should refresh built-in backdrop names from `Array.defaultPresets()` when loading persisted state. Intent glyphs remain appropriate in detail cards, plan rows, and other explanatory UI outside the selector capsule.

Most shipped photos were downloaded from Pexels at `1200×800` using:

```
https://images.pexels.com/photos/<id>/pexels-photo-<id>.jpeg?auto=compress&cs=tinysrgb&w=1200&h=800&fit=crop
```

Pexels photos are free for commercial use under the Pexels license; attribution is not required, but source IDs are kept here for traceability. Keep ambient replacements landscape-friendly, low-contrast at row scale, and representative of the recording place when the source location is known. Keep organic replacements abstract, dark-mode compatible, and visually quiet under tint overlays.

Wide organic hero textures may keep their cinematic aspect ratio, but resample the long edge to roughly `2200 px` or less and inspect them in-app before shipping.

## Ambient channels

| Track | Asset | Pexels ID | Visual brief |
| --- | --- | --- | --- |
| `oiseaux` | `sound_oiseaux_background` | `17636872` | Breton countryside meadow and stream for Nivillac/Morbihan birds. |
| `vent` | `sound_vent_background` | `34470645` | Open Occitanie mountain landscape for Perpignan wind. |
| `plage` | `sound_plage_background` | `4407294` | Cold Scottish waves for the Shetland shore. |
| `goelands` | `sound_goelands_background` | `34584311` | Seagulls on a harbor wall for the Brittany harbor recording. |
| `foret` | `sound_foret_background` | `12200797` | Foggy Dutch forest road for Kampina woodland. |
| `pluie` | `sound_pluie_background` | `19963614` | Rainy Italian street atmosphere for Voghera/Pavia rain. |
| `tonnerre` | `sound_tonnerre_background` | `15171911` | Dark storm front over fields for the Azillanet plain storm. |
| `cigales` | `sound_cigales_background` | `37089565` | Sun-warmed Sicilian stone house and garden for Lampedusa cicadas. |
| `grillons` | `sound_grillons_background` | `21591430` | Quiet rural dusk sky for countryside night crickets. |
| `tente` | `sound_tente_background` | `17664146` | Wet forest stream and campsite mood for Bornholm tent rain. |
| `riviere` | `sound_riviere_background` | `19023738` | Green mountain river valley for the Taoyuan stream. |
| `village` | `sound_village_background` | `35646293` | Warm Chinese pedestrian street for Liuzhou ambience. |
| `mer` | `sound_mer_background` | `33070810` | Calm Greek Mediterranean horizon for Epitalio sea. |
| `orageMontagne` | `sound_orage_montagne_background` | `16012655` | Lake Garda mountain waterline for distant thunder. |
| `campfire` | `sound_campfire_background` | `1416901` | Close riverside firelight for St. Marys River campfire. |
| `cafe` | `sound_cafe_background` | `33163961` | Quiet cafe seating for Sao Paulo cafe ambience. |
| `lac` | `sound_lac_background` | `17460020` | Reedy lake at sunset for Fritton Lake. |
| `savane` | `sound_savane_background` | `13410103` | Sparse savanna tree line for KwaZulu-Natal. |
| `jungleAmerique` | `sound_jungle_amerique_background` | `16791628` | Tropical waterfall and canopy for Los Tuxtlas. |
| `jungleAsie` | `sound_jungle_asie_background` | `23515065` | Dense green jungle light for Chiang Mai. |
| `pluieFenetre` | `sound_pluie_fenetre_background` | `14530325` | Soft rain on glass for Chiswick window rain. |
| `pluieForet` | `sound_pluie_foret_background` | `1488402` | Misty wet forest for Saxony forest rain. |
| `fortePluie` | `sound_forte_pluie_background` | `13686776` | Rural rainy field for heavy rain on land. |
| `ventNuit` | `sound_vent_nuit_background` | `30443709` | Portuguese coast at night for Cabo Raso wind. |
| `foretNuit` | `sound_foret_nuit_background` | `9901425` | Dark trees under stars for night forest ambience. |
| `crueMontagne` | `sound_crue_montagne_background` | `36204288` | Guilin karst river valley for mountain floodwater. |
| `cascade` | `sound_cascade_background` | `21301190` | Vertical waterfall veil for Graz/Styria waterfall. |
| `neigeVille` | `sound_neige_ville_background` | `30392002` | Snowy suburban night for Warren, Michigan snowflakes. |
| `pluieCabane` | `sound_pluie_cabane_background` | `35038000` | Snow/rain cabin silhouette for Axelfors cabin roof. |
| `foretChiloe` | `sound_foret_chiloe_background` | `32755115` | Southern Chile forest creek for Chiloé. |
| `aubeJungle` | `sound_aube_jungle_background` | `11635487` | Mangrove sunrise for Sian Ka'an jungle dawn. |
| `port` | `sound_port_background` | `32919319` | Turkish coastal beacon/harbor mood for Pazar/Rize. |
| `chevres` | `sound_chevres_background` | `9145817` | Goat herd at dusk for Montargil bells. |
| `carillons` | `sound_carillons_background` | `12181261` | Garden wind chime close-up for Santa Fe-style chimes. |
| `cloches` | `sound_cloches_background` | `18241108` | Hanover church tower street view for church bells. |

## Organic conceptual backgrounds

| Asset | Pexels ID | Photographer | Used for | Visual brief |
| --- | --- | --- | --- | --- |
| `organic_dark_water` | `32505829` | Valeriia Miller | Brown-noise masks, fallback sleep texture | Dark water ripples with enough contour to feel organic without reading as a specific place. |
| `organic_dark_satin` | `13946140` | Steve Johnson | Sleep-leaning ambience cards | Sculptural satin ribbon on a black field; chosen after visual inspection because it feels calmer and more premium than the old dark water crop. |
| `organic_warm_fabric` | `30263578` | Gulsum Haydaroglu | Reading, focus support, Theta/Alpha binaural | Warm folded fabric, used sparingly under tint so it reads tactile rather than muddy. |
| `organic_blue_fabric` | `23338914` | Efl-E-Sun | Beta binaural fallback | Blue-black textile folds with a cooler, cleaner technical mood. |
| `organic_blue_flow` | `29586677` | Steve Johnson | Focus-leaning ambience cards | Soft blue fabric flow with generous negative space; kept because it adds colour without reading as a place photo. |

## Binaural tracks

| Track | Runtime backdrop | Visual brief |
| --- | --- | --- |
| `delta` | `organic_dark_water` | Sleep-oriented, dark, low-motion texture. |
| `theta` | `organic_warm_fabric` | Meditation/rest texture with warm softness. |
| `alpha` | `organic_warm_fabric` | Relaxation texture, shared with Theta for calmer visual load. |
| `beta` | `organic_blue_fabric` | Focus texture with cooler contrast. |

## Extra ambience backgrounds

| Asset | Pexels ID | Photographer | Visual brief |
| --- | --- | --- | --- |
| `ambience_soft_hues` | `33706966` | Landiva Weber | Brighter pink/green organic shapes for Soft reset / Retour au calme. |
| `ambience_colorful_shapes` | `33500208` | Zeynep Sude Emek | Starry forest night for Deep sleep / Nuit profonde, replacing the harsh abstract shapes. |
| `ambience_colorful_fabric` | `36147547` | Rafael Minguet Delgado | Multicolour fabric texture for Travel cocoon, lighter and more varied than the old blue-black fabric. |
| `ambience_warm_fluid` | `31646205` | Jin He | Warm bedside bedroom for Evening reading / Lecture du soir, replacing the fluid-art crop. |
| `ambience_forest_cabin` | `37242869` | Matt Baker | Forest cabin exterior for Rain cabin / Cabane sous la pluie, more literal than the old abstract fabric. |
| `routine_misty_forest` | `14701776` | Diego Benjamín | Dense green forest mist for sleep/calm ambiences. |
| `routine_dark_ocean` | `34155534` | Kris Møklebust | Dark ocean ripples for low-motion night ambience cards. |
| `routine_rain_window` | `6632182` | Zeinab Ghassemi | Rain droplets and soft city blur for rainy saved mixes. |
| `routine_starry_lake` | `12249381` | Josh Hild | Lake reflection under stars for quiet night scenes. |
| `routine_aurora_lake` | `16747789` | Stijn Dijkstra | Aurora reflected on water for premium-feeling deep night scenes. |
| `routine_night_cabin` | `9179968` | Людмила Ульянова | Warm cabin in dark woods for sheltered reading/sleep ambiences. |
| `routine_night_waves` | `15979121` | Allan Carvalho | Moody wave motion for ocean-heavy ambiences. |
| `routine_twilight_water` | `9585883` | Lada Rezantseva | Soft twilight water texture for calm saved ambiences. |
| `routine_foggy_trees` | `30205488` | Ali Berke GÜL | Foggy leafless forest for darker focus/sleep moods. |
| `routine_aurora_mountains` | `2113567` | Tobias Bjørkli | Aurora over snow and mountains for expansive night ambience cards. |
