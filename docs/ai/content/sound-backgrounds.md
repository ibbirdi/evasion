---
title: Sound Backgrounds
status: stable
last_updated: 2026-05-22
tracks:
  - "ios-native/OasisNative/Assets.xcassets/SoundBackgrounds/**"
  - "ios-native/OasisNative/Models/SoundChannelMetadata.swift"
related:
  - "sounds-catalog.md"
  - "../architecture/ui.md"
  - "../codebase/conventions.md"
---

# Sound Backgrounds

Every ambient and binaural track has a subtle photo watermark in `Assets.xcassets/SoundBackgrounds`. Runtime mapping is in `SoundChannel.backdrop` and `BinauralTrack.backdrop`.

All shipped photos were downloaded from Pexels at `1200×800` using:

```
https://images.pexels.com/photos/<id>/pexels-photo-<id>.jpeg?auto=compress&cs=tinysrgb&w=1200&h=800&fit=crop
```

Pexels photos are free for commercial use under the Pexels license; attribution is not required, but source IDs are kept here for traceability. Keep replacements landscape-friendly, low-contrast at row scale, and representative of the recording place when the source location is known.

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

## Binaural tracks

| Track | Asset | Pexels ID | Visual brief |
| --- | --- | --- | --- |
| `delta` | `binaural_delta_background` | `17086452` | Star field for sleep. |
| `theta` | `binaural_theta_background` | `35523768` | Still sunrise water for meditation. |
| `alpha` | `binaural_alpha_background` | `33130681` | Warm sea glow for relaxation. |
| `beta` | `binaural_beta_background` | `35235742` | Crisp mountain valley for focus. |
