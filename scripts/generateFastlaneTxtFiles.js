const fs = require("fs");
const path = require("path");

const metadata = {
  "fr-FR": {
    name: "Oasis - Sons pour Dormir",
    subtitle: "Bruit blanc, nature & sommeil",
    promotional_text:
      "Mixez 14 sons nature en audio 3D, lancez un minuteur et endormez-vous. Hors ligne, sans compte, sans abonnement — un seul achat.",
    keywords:
      "relaxation,concentration,etude,binaural,mix,pluie,brun,rose,orage,ocean,ambiance,acouphene,insomnie,coucher,vent,ventilateur,bruit,grillons,ASMR",
    release_notes: `Oasis 1.3.0 rend l'app plus simple à adopter :
• Audios optimisés : l'app prend beaucoup moins de place.
• Compatibilité iOS 18+.
• Minuteurs 15 et 30 min gratuits.
• Premium plus clair : 11 sons, mix illimités, minuteurs 1 h/2 h.
• Achat unique conservé, sans abonnement.`,
    description: `Quand la rue, les voisins ou les pensées qui tournent rendent le calme difficile, Oasis vous aide à créer un fond sonore stable pour dormir, lire ou travailler avec moins de distractions.

Choisissez des sons de la nature, ajustez chaque volume et placez-les autour de vous en audio 3D : vent à gauche, plage devant, oiseaux plus loin. Lancez un minuteur, verrouillez l'iPhone et laissez l'audio continuer en arrière-plan. Tout fonctionne hors ligne.

Inclus gratuitement :
• Oiseaux, vent et plage
• Audio 3D sur les sons gratuits
• Mode binaural Delta
• Shuffle
• Minuteurs 15 et 30 min
• 1 mix sauvegardé

Premium, en achat unique :
• 11 sons supplémentaires : pluie, forêt, orage, rivière, train...
• Mix favoris illimités
• Minuteurs 1 h et 2 h
• Modes binauraux Theta, Alpha et Beta
• Futures nouveautés Premium incluses

Oasis n'essaie pas de tout faire. Pas de catalogue infini, pas de compte à créer, pas d'abonnement : juste un outil audio pour dormir, lire, travailler ou masquer les bruits du quotidien.`,
  },
  "en-US": {
    name: "Oasis - Sleep Sounds 3D",
    subtitle: "White noise, nature & timer",
    promotional_text:
      "Mix 14 nature sounds in 3D, set a sleep timer, and drift off. Offline, no account, no subscription — one purchase, yours forever.",
    keywords:
      "relaxation,focus,study,binaural,mix,rain,brown,pink,thunder,ocean,soundscape,tinnitus,insomnia,bedtime,ambient,wind,fan,noise,crickets,ASMR",
    release_notes: `Oasis 1.3.0 makes the app easier to try and keep:
• Optimized audio: the app takes much less space.
• iOS 18+ support.
• Free 15 and 30 min timers.
• Clearer Premium: 11 sounds, unlimited mixes, 1 hr/2 hr timers.
• One-time purchase, still no subscription.`,
    description: `Street noise, neighbors or a busy mind can make quiet hard to find. Oasis helps you build a steady sound bed for sleep, reading or focused work with fewer distractions.

Choose nature sounds, adjust each volume and place them around you in 3D audio: wind to the left, beach ahead, birds further away. Start a timer, lock your iPhone and let playback continue in the background. Everything works offline.

Included for free:
• Birds, wind and beach
• 3D audio on free sounds
• Delta binaural mode
• Shuffle
• 15 and 30 min timers
• 1 saved mix

Premium, one-time purchase:
• 11 extra sounds: rain, forest, thunder, river, train...
• Unlimited saved mixes
• 1 hr and 2 hr timers
• Theta, Alpha and Beta binaural modes
• Future Premium additions included

Oasis stays focused. No endless catalog, no account to create, no subscription: just an audio tool for sleep, reading, work or masking everyday noise.`,
  },
  "de-DE": {
    name: "Oasis - Schlafklänge 3D",
    subtitle: "Weißes Rauschen & Natur",
    promotional_text:
      "14 Naturklänge in 3D mischen, Schlaf-Timer starten und einschlafen. Offline, kein Konto, kein Abo — ein Kauf, für immer.",
    keywords:
      "entspannung,fokus,lernen,binaural,mix,regen,braun,rosa,gewitter,meer,klanglandschaft,tinnitus,schlaflosigkeit,schlafzeit,ambient,wind,ventilator,rauschen,grillen,ASMR",
    release_notes: `Oasis 1.3.0 macht den Einstieg leichter:
• Optimierte Audiodateien: die App braucht deutlich weniger Speicher.
• Unterstützung ab iOS 18.
• Kostenlose Timer für 15 und 30 Min.
• Premium klarer erklärt: 11 Sounds, unbegrenzte Mixe, Timer für 1/2 Std.
• Einmalkauf bleibt, ohne Abo.`,
    description: `Straßenlärm, Nachbarn oder kreisende Gedanken machen Ruhe manchmal schwer. Oasis hilft dir, einen gleichmäßigen Klangteppich zum Einschlafen, Lesen oder konzentrierten Arbeiten zu erstellen.

Wähle Naturklänge, passe jede Lautstärke an und platziere die Sounds in 3D-Audio um dich herum: Wind links, Strand vorne, Vögel weiter weg. Starte einen Timer, sperre dein iPhone und lass die Wiedergabe im Hintergrund laufen. Alles funktioniert offline.

Kostenlos enthalten:
• Vögel, Wind und Strand
• 3D-Audio für kostenlose Sounds
• Delta-Binauralmodus
• Shuffle
• Timer für 15 und 30 Min.
• 1 gespeicherter Mix

Premium, als Einmalkauf:
• 11 zusätzliche Sounds: Regen, Wald, Donner, Fluss, Zug...
• Unbegrenzt gespeicherte Mixe
• Timer für 1 Std. und 2 Std.
• Theta-, Alpha- und Beta-Binauralmodi
• Zukünftige Premium-Neuheiten inklusive

Oasis bleibt bewusst fokussiert. Kein endloser Katalog, kein Konto, kein Abo: nur ein Audiowerkzeug zum Schlafen, Lesen, Arbeiten oder Ausblenden von Alltagsgeräuschen.`,
  },
  "es-ES": {
    name: "Oasis - Sonidos para Dormir",
    subtitle: "Ruido blanco y naturaleza",
    promotional_text:
      "Mezcla 14 sonidos naturales en 3D, activa un temporizador y descansa. Sin conexión, sin cuenta, sin suscripción — una sola compra.",
    keywords:
      "relajacion,concentracion,estudio,binaural,mezcla,lluvia,marron,rosa,tormenta,oceano,paisaje sonoro,tinnitus,insomnio,dormir,ambiente,viento,ventilador,ruido,grillos,ASMR",
    release_notes: `Oasis 1.3.0 hace que la app sea más fácil de probar y conservar:
• Audio optimizado: la app ocupa mucho menos espacio.
• Compatibilidad con iOS 18+.
• Temporizadores de 15 y 30 min gratis.
• Premium más claro: 11 sonidos, mezclas ilimitadas y temporizadores de 1/2 h.
• Compra única, sin suscripción.`,
    description: `El ruido de la calle, los vecinos o la mente acelerada pueden hacer que el silencio cueste. Oasis te ayuda a crear un fondo sonoro estable para dormir, leer o trabajar con menos distracciones.

Elige sonidos de la naturaleza, ajusta cada volumen y colócalos a tu alrededor en audio 3D: viento a la izquierda, playa delante, pájaros más lejos. Activa un temporizador, bloquea el iPhone y deja que el audio siga en segundo plano. Todo funciona sin conexión.

Incluido gratis:
• Pájaros, viento y playa
• Audio 3D en los sonidos gratis
• Modo binaural Delta
• Shuffle
• Temporizadores de 15 y 30 min
• 1 mezcla guardada

Premium, con una compra única:
• 11 sonidos adicionales: lluvia, bosque, trueno, río, tren...
• Mezclas guardadas ilimitadas
• Temporizadores de 1 h y 2 h
• Modos binaurales Theta, Alpha y Beta
• Futuras novedades Premium incluidas

Oasis se mantiene enfocada. Sin catálogo infinito, sin crear una cuenta, sin suscripción: solo una herramienta de audio para dormir, leer, trabajar o cubrir el ruido cotidiano.`,
  },
  it: {
    name: "Oasis - Suoni per Dormire",
    subtitle: "Rumore bianco e natura",
    promotional_text:
      "Mixa 14 suoni naturali in 3D, avvia un timer per dormire e rilassati. Offline, senza account, senza abbonamento — un solo acquisto.",
    keywords:
      "rilassamento,concentrazione,studio,binaurale,mix,pioggia,marrone,rosa,temporale,oceano,paesaggio sonoro,tinnito,insonnia,notte,ambiente,vento,ventola,rumore,grilli,ASMR",
    release_notes: `Oasis 1.3.0 rende l'app più facile da provare e tenere:
• Audio ottimizzati: l'app occupa molto meno spazio.
• Compatibilità iOS 18+.
• Timer da 15 e 30 min gratis.
• Premium più chiaro: 11 suoni, mix illimitati e timer da 1/2 h.
• Acquisto unico, senza abbonamento.`,
    description: `Rumori dalla strada, vicini o pensieri che girano possono rendere difficile trovare calma. Oasis ti aiuta a creare un sottofondo sonoro stabile per dormire, leggere o lavorare con meno distrazioni.

Scegli suoni della natura, regola ogni volume e posizionali intorno a te in audio 3D: vento a sinistra, spiaggia davanti, uccelli più lontani. Avvia un timer, blocca l'iPhone e lascia l'audio in background. Tutto funziona offline.

Incluso gratis:
• Uccelli, vento e spiaggia
• Audio 3D sui suoni gratuiti
• Modalità binaurale Delta
• Shuffle
• Timer 15 e 30 min
• 1 mix salvato

Premium, con acquisto unico:
• 11 suoni extra: pioggia, foresta, tuono, fiume, treno...
• Mix salvati illimitati
• Timer da 1 h e 2 h
• Modalità binaurali Theta, Alpha e Beta
• Future novità Premium incluse

Oasis resta concentrata. Niente catalogo infinito, nessun account da creare, nessun abbonamento: solo uno strumento audio per dormire, leggere, lavorare o coprire i rumori quotidiani.`,
  },
  "pt-BR": {
    name: "Oasis - Sons para Dormir",
    subtitle: "Ruído branco e natureza",
    promotional_text:
      "Mixe 14 sons da natureza em 3D, ative um timer e relaxe. Offline, sem conta, sem assinatura — uma única compra.",
    keywords:
      "relaxamento,foco,estudo,binaural,mix,chuva,marrom,rosa,trovao,oceano,paisagem sonora,zumbido,insonia,noite,ambiente,vento,ventilador,ruido,grilos,ASMR",
    release_notes: `Oasis 1.3.0 deixa o app mais fácil de experimentar e manter:
• Áudios otimizados: o app ocupa muito menos espaço.
• Compatível com iOS 18+.
• Timers de 15 e 30 min grátis.
• Premium mais claro: 11 sons, mixes ilimitados e timers de 1/2 h.
• Compra única, sem assinatura.`,
    description: `Barulho da rua, vizinhos ou pensamentos acelerados podem dificultar o silêncio. Oasis ajuda você a criar um som de fundo estável para dormir, ler ou trabalhar com menos distrações.

Escolha sons da natureza, ajuste cada volume e posicione tudo ao seu redor em áudio 3D: vento à esquerda, praia à frente, pássaros mais longe. Inicie um timer, bloqueie o iPhone e deixe o áudio continuar em segundo plano. Tudo funciona offline.

Incluído grátis:
• Pássaros, vento e praia
• Áudio 3D nos sons gratuitos
• Modo binaural Delta
• Shuffle
• Timers de 15 e 30 min
• 1 mix salvo

Premium, com compra única:
• 11 sons extras: chuva, floresta, trovão, rio, trem...
• Mixes salvos ilimitados
• Timers de 1 h e 2 h
• Modos binaurais Theta, Alpha e Beta
• Futuras novidades Premium incluídas

Oasis mantém o foco. Sem catálogo infinito, sem conta para criar, sem assinatura: só uma ferramenta de áudio para dormir, ler, trabalhar ou mascarar ruídos do dia a dia.`,
  },
};

const outputRoots = [
  path.join(__dirname, "..", "fastlane", "metadata"),
  path.join(__dirname, "fastlane", "metadata"),
];

for (const [locale, values] of Object.entries(metadata)) {
  for (const root of outputRoots) {
    const dir = path.join(root, locale);
    fs.mkdirSync(dir, { recursive: true });

    for (const [field, value] of Object.entries(values)) {
      fs.writeFileSync(path.join(dir, `${field}.txt`), `${value}\n`);
    }
  }

  console.log(`Generated Fastlane metadata for ${locale}`);
}
