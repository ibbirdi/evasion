const fs = require("fs");
const path = require("path");

// Base de données des 6 langues traduites et optimisées pour l'ASO avec les noms localisés
const metadata = {
  "fr-FR": {
    name: "Évasion - Sons Binauraux",
    subtitle: "Sommeil & Focus Premium",
    promotional_text:
      "L'immersion absolue par la nature. De véritables enregistrements audio, avec un achat unique et zéro abonnement.",
    keywords:
      "sommeil,binaural,nature,pluie,orage,méditation,concentration,relax,sans abonnement,bruit blanc",
    description: `Bienvenue dans Évasion, votre nouveau sanctuaire sonore.

Oubliez les boucles artificielles de quelques secondes : Évasion utilise exclusivement de véritables enregistrements de terrain continus et de très haute qualité binaurale, capturés à travers le monde. Plongez instantanément dans un paysage sonore vaste, vivant et profondément immersif.

UNE EXPÉRIENCE AUDIO VIVANTE
Notre moteur audio intelligent garantit que vous n'entendrez jamais exactement le même mixage se répéter. Grâce au générateur d'aléatoire temporel et à la fonction d'Auto-Variation, l'application fait évoluer le volume des environnements naturels de façon aléatoire et très lente dans le temps, libérant totalement votre charge mentale.

ONDES CÉRÉBRALES & STÉRÉO BINAURALE
Évasion intègre un mixeur hybride de fréquences pures pour synchroniser vos ondes cérébrales avec 4 modes spécifiquement conçus (casque stéréo recommandé) :
- Delta (Sommeil) : Favorise l'endormissement et un sommeil profond réparateur.
- Theta (Relaxation) : Idéal pour la méditation profonde et la réduction du stress.
- Alpha (Concentration) : Pour la mémorisation, l'apprentissage et le travail créatif.
- Beta (Éveil) : Stimule la vigilance et les capacités cognitives.

UN OUTIL PREMIUM, SANS ABONNEMENT
Nous refusons la fatigue des abonnements. L'application propose une version gratuite sans limite de temps incluant 3 sons de la nature (Oiseaux, Vent, Plage) et l'onde Delta pour le sommeil.

Passez à la version Premium avec un PAIEMENT UNIQUE À VIE pour débloquer le plein potentiel de l'application :
- La bibliothèque complète de 14 environnements sonores haute fidélité.
- Les 4 modes d'ondes cérébrales (Delta, Theta, Alpha, Beta).
- La sauvegarde illimitée de vos propres mixages.
- La minuterie de sommeil programmable (15m, 30m, 1h, 2h).
- L'Auto-Variation intelligente de l'environnement.

100% HORS-LIGNE & RESPECT DE LA VIE PRIVÉE
Tous les éléments sonores sont embarqués localement dans votre appareil. L'immersion se lance instantanément, sans aucune latence réseau, de manière totalement confidentielle. L'application continue de jouer en arrière-plan avec une intégration totale à votre système, même lorsque l'écran est verrouillé.`,
  },
  "en-US": {
    name: "Drift - Binaural Beats",
    subtitle: "Premium Sleep & Focus",
    promotional_text:
      "Absolute immersion through nature. True continuous audio recordings, with a one-time purchase and zero subscriptions.",
    keywords:
      "sleep,binaural,nature,rain,storm,meditation,concentration,relax,no subscription,white noise",
    description: `Welcome to Drift, your new sonic sanctuary.

Forget artificial loops of a few seconds: Drift exclusively uses continuous, real field recordings of very high binaural quality, captured around the world. Dive instantly into a vast, living, and deeply immersive soundscape.

A LIVING AUDIO EXPERIENCE
Our intelligent audio engine ensures you will never hear the exact same mix repeat. Thanks to the temporal random generator and the Auto-Variation feature, the app slowly and randomly evolves the volume of natural environments over time, completely freeing your mental load.

BRAINWAVES & BINAURAL STEREO
Drift integrates a hybrid mixer of pure frequencies to synchronize your brainwaves with 4 specifically designed modes (stereo headphones recommended):
- Delta (Sleep): Promotes falling asleep and deep restorative sleep.
- Theta (Relaxation): Ideal for deep meditation and stress reduction.
- Alpha (Focus): For memory, learning, and creative work.
- Beta (Awake): Stimulates alertness and cognitive abilities.

A PREMIUM TOOL, NO SUBSCRIPTION
We reject subscription fatigue. The app offers a free version with no time limit including 3 nature sounds (Birds, Wind, Beach) and the Delta wave for sleep.

Upgrade to the Premium version with a ONE-TIME LIFETIME PAYMENT to unlock the app's full potential:
- The complete library of 14 high-fidelity sound environments.
- The 4 brainwave modes (Delta, Theta, Alpha, Beta).
- Unlimited saving of your own mixes.
- Programmable sleep timer (15m, 30m, 1h, 2h).
- Intelligent Auto-Variation of the environment.

100% OFFLINE & PRIVACY RESPECTED
All sound elements are embedded locally on your device. Immersion launches instantly, without any network latency, in complete confidentiality. The app continues to play in the background with full system integration, even when the screen is locked.`,
  },
  "es-ES": {
    name: "Oasis - Sonidos Binaurales",
    subtitle: "Sueño y Enfoque Premium",
    promotional_text:
      "Inmersión absoluta en la naturaleza. Grabaciones de audio reales y continuas, con un pago único y sin suscripciones.",
    keywords:
      "sueño,binaural,naturaleza,lluvia,tormenta,meditación,concentración,relax,sin suscripción,ruido blanco",
    description: `Bienvenido a Oasis, tu nuevo santuario sonoro.

Olvídate de los bucles artificiales de unos pocos segundos: Oasis utiliza exclusivamente verdaderas grabaciones de campo continuas de muy alta calidad binaural, capturadas en todo el mundo. Sumérgete al instante en un paisaje sonoro vasto, vivo y profundamente inmersivo.

UNA EXPERIENCIA DE AUDIO VIVA
Nuestro motor de audio inteligente garantiza que nunca escucharás la misma mezcla repetirse exactamente. Gracias al generador aleatorio temporal y a la función de Autovariación, la aplicación hace evolucionar el volumen de los entornos naturales de forma aleatoria y muy lenta en el tiempo, liberando totalmente tu carga mental.

ONDAS CEREBRALES Y ESTÉREO BINAURAL
Oasis integra un mezclador híbrido de frecuencias puras para sincronizar tus ondas cerebrales con 4 modos diseñados específicamente (se recomiendan auriculares estéreo):
- Delta (Sueño): Favorece la conciliación del sueño y un sueño profundo reparador.
- Theta (Relajación): Ideal para la meditación profunda y la reducción del estrés.
- Alpha (Concentración): Para la memorización, el aprendizaje y el trabajo creativo.
- Beta (Despertar): Estimula la vigilancia y las capacidades cognitivas.

UNA HERRAMIENTA PREMIUM, SIN SUSCRIPCIÓN
Rechazamos la fatiga de las suscripciones. La aplicación ofrece una versión gratuita sin límite de tiempo que incluye 3 sonidos de la naturaleza (Pájaros, Viento, Playa) y la onda Delta para dormir.

Pásate a la versión Premium con un PAGO ÚNICO DE POR VIDA para desbloquear todo el potencial de la aplicación:
- La biblioteca completa de 14 entornos sonoros de alta fidelidad.
- Los 4 modos de ondas cerebrales (Delta, Theta, Alpha, Beta).
- Guardado ilimitado de tus propias mezclas.
- Temporizador de sueño programable (15m, 30m, 1h, 2h).
- Autovariación inteligente del entorno.

100% OFFLINE Y RESPETO A LA PRIVACIDAD
Todos los elementos sonoros están integrados localmente en tu dispositivo. La inmersión se lanza al instante, sin latencia de red, con total confidencialidad. La aplicación sigue reproduciéndose en segundo plano con total integración en tu sistema, incluso con la pantalla bloqueada.`,
  },
  "de-DE": {
    name: "Drift - Binaurale Beats",
    subtitle: "Premium Schlaf & Fokus",
    promotional_text:
      "Absolute Immersion durch die Natur. Echte, kontinuierliche Audioaufnahmen, mit einem Einmalkauf und ohne Abonnements.",
    keywords:
      "schlaf,binaural,natur,regen,sturm,meditation,konzentration,entspannung,kein abo,weißes rauschen",
    description: `Willkommen bei Drift, deinem neuen klanglichen Heiligtum.

Vergiss künstliche Schleifen von wenigen Sekunden: Drift verwendet ausschließlich echte, kontinuierliche Feldaufnahmen in sehr hoher binauraler Qualität, die auf der ganzen Welt aufgenommen wurden. Tauche sofort in eine weite, lebendige und tief immersive Klanglandschaft ein.

EIN LEBENDIGES AUDIOERLEBNIS
Unsere intelligente Audio-Engine sorgt dafür, dass du niemals genau dieselbe Mischung zweimal hörst. Dank des temporalen Zufallsgenerators und der Auto-Variation-Funktion verändert die App die Lautstärke natürlicher Umgebungen im Laufe der Zeit zufällig und sehr langsam, wodurch deine mentale Belastung vollständig befreit wird.

GEHIRNWELLEN & BINAURALES STEREO
Drift integriert einen hybriden Mixer reiner Frequenzen, um deine Gehirnwellen mit 4 speziell entwickelten Modi zu synchronisieren (Stereokopfhörer empfohlen):
- Delta (Schlaf): Fördert das Einschlafen und einen tiefen, erholsamen Schlaf.
- Theta (Entspannung): Ideal für tiefe Meditation und Stressabbau.
- Alpha (Fokus): Für Gedächtnis, Lernen und kreative Arbeit.
- Beta (Wach): Stimuliert Wachsamkeit und kognitive Fähigkeiten.

EIN PREMIUM-TOOL, KEIN ABONNEMENT
Wir lehnen die Abo-Müdigkeit ab. Die App bietet eine kostenlose Version ohne Zeitlimit mit 3 Naturgeräuschen (Vögel, Wind, Strand) und der Delta-Welle für den Schlaf.

Wechsle zur Premium-Version mit einer EINMALIGEN LEBENSLANGEN ZAHLUNG, um das volle Potenzial der App freizuschalten:
- Die komplette Bibliothek mit 14 High-Fidelity-Klangumgebungen.
- Die 4 Gehirnwellen-Modi (Delta, Theta, Alpha, Beta).
- Unbegrenztes Speichern deiner eigenen Mixe.
- Programmierbarer Sleep-Timer (15m, 30m, 1h, 2h).
- Intelligente Auto-Variation der Umgebung.

100% OFFLINE & DATENSCHUTZ RESPEKTIERT
Alle Klangelemente sind lokal auf deinem Gerät eingebettet. Die Immersion startet sofort, ohne Netzwerklatenz, in völliger Vertraulichkeit. Die App spielt im Hintergrund mit voller Systemintegration weiter, auch wenn der Bildschirm gesperrt ist.`,
  },
  "it-IT": {
    name: "Oasi - Suoni Binaurali",
    subtitle: "Sonno e Focus Premium",
    promotional_text:
      "Immersione assoluta nella natura. Vere registrazioni audio continue, con un acquisto unico e zero abbonamenti.",
    keywords:
      "sonno,binaurale,natura,pioggia,tempesta,meditazione,concentrazione,relax,nessun abbonamento,rumore bianco",
    description: `Benvenuto in Oasi, il tuo nuovo santuario sonoro.

Dimentica i loop artificiali di pochi secondi: Oasi utilizza esclusivamente vere registrazioni sul campo continue di altissima qualità binaurale, catturate in tutto il mondo. Immergiti istantaneamente in un paesaggio sonoro vasto, vivo e profondamente immersivo.

UN'ESPERIENZA AUDIO VIVA
Il nostro motore audio intelligente garantisce che non ascolterai mai lo stesso mix ripetersi. Grazie al generatore casuale temporale e alla funzione di Auto-Variazione, l'app fa evolvere il volume degli ambienti naturali in modo casuale e molto lento nel tempo, liberando totalmente il tuo carico mentale.

ONDE CEREBRALI E STEREO BINAURALE
Oasi integra un mixer ibrido di frequenze pure per sincronizzare le tue onde cerebrali con 4 modalità specificamente progettate (si consigliano cuffie stereo):
- Delta (Sonno): Favorisce l'addormentamento e un sonno profondo e ristoratore.
- Theta (Rilassamento): Ideale per la meditazione profonda e la riduzione dello stress.
- Alpha (Concentrazione): Per la memorizzazione, l'apprendimento e il lavoro creativo.
- Beta (Risveglio): Stimola la vigilanza e le capacità cognitive.

UNO STRUMENTO PREMIUM, NESSUN ABBONAMENTO
Rifiutiamo l'affaticamento da abbonamento. L'app offre una versione gratuita senza limiti di tempo che include 3 suoni della natura (Uccelli, Vento, Spiaggia) e l'onda Delta per il sonno.

Passa alla versione Premium con un PAGAMENTO UNICO A VITA per sbloccare tutto il potenziale dell'app:
- La libreria completa di 14 ambienti sonori ad alta fedeltà.
- Le 4 modalità di onde cerebrali (Delta, Theta, Alpha, Beta).
- Il salvataggio illimitato dei tuoi mix.
- Il timer di spegnimento programmabile (15m, 30m, 1h, 2h).
- L'Auto-Variazione intelligente dell'ambiente.

100% OFFLINE E RISPETTO DELLA PRIVACY
Tutti gli elementi sonori sono incorporati localmente nel tuo dispositivo. L'immersione si avvia istantaneamente, senza latenza di rete, in totale riservatezza. L'app continua a riprodurre in background con un'integrazione totale nel tuo sistema, anche a schermo bloccato.`,
  },
  "pt-BR": {
    name: "Refúgio - Sons Binaurais",
    subtitle: "Sono e Foco Premium",
    promotional_text:
      "Imersão absoluta na natureza. Verdadeiras gravações de áudio contínuas, com uma compra única e zero assinaturas.",
    keywords:
      "sono,binaural,natureza,chuva,tempestade,meditação,concentração,relaxar,sem assinatura,ruído branco",
    description: `Bem-vindo ao Refúgio, o seu novo santuário sonoro.

Esqueça os loops artificiais de alguns segundos: Refúgio utiliza exclusivamente verdadeiras gravações de campo contínuas e de altíssima qualidade binaural, capturadas em todo o mundo. Mergulhe instantaneamente numa paisagem sonora vasta, viva e profundamente imersiva.

UMA EXPERIÊNCIA DE ÁUDIO VIVA
O nosso motor de áudio inteligente garante que nunca ouvirá exatamente a mesma mistura repetir-se. Graças ao gerador aleatório temporal e à função de Autovariação, a aplicação faz evoluir o volume dos ambientes naturais de forma aleatória e muito lenta no tempo, libertando totalmente a sua carga mental.

ONDAS CEREBRAIS E ESTÉREO BINAURAL
Refúgio integra um misturador híbrido de frequências puras para sincronizar as suas ondas cerebrais com 4 modos especificamente concebidos (recomendam-se auscultadores estéreo):
- Delta (Sono): Favorece o adormecimento e um sono profundo e reparador.
- Theta (Relaxamento): Ideal para a meditação profunda e a redução do stress.
- Alpha (Concentração): Para a memorização, a aprendizagem e o trabalho criativo.
- Beta (Despertar): Estimula a vigilância e as capacidades cognitivas.

UMA FERRAMENTA PREMIUM, SEM ASSINATURA
Rejeitamos a fadiga das assinaturas. A aplicação oferece uma versão gratuita sem limite de tempo que inclui 3 sons da natureza (Pássaros, Vento, Praia) e a onda Delta para o sono.

Mude para a versão Premium com um PAGAMENTO ÚNICO VITALÍCIO para desbloquear todo o potencial da aplicação:
- A biblioteca completa de 14 ambientes sonoros de alta fidelidade.
- Os 4 modos de ondas cerebrais (Delta, Theta, Alpha, Beta).
- Gravação ilimitada das suas próprias misturas.
- Temporizador de sono programável (15m, 30m, 1h, 2h).
- Autovariação inteligente do ambiente.

100% OFFLINE E RESPEITO PELA PRIVACIDADE
Todos os elementos sonoros estão incorporados localmente no seu dispositivo. A imersão arranca instantaneamente, sem latência de rede, com total confidencialidade. A aplicação continua a tocar em segundo plano com integração total no seu sistema, mesmo quando o ecrã está bloqueado.`,
  },
};

// Exécution de la génération
Object.keys(metadata).forEach((locale) => {
  const dir = path.join(__dirname, "fastlane", "metadata", locale);

  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

  fs.writeFileSync(path.join(dir, "name.txt"), metadata[locale].name);
  fs.writeFileSync(path.join(dir, "subtitle.txt"), metadata[locale].subtitle);
  fs.writeFileSync(
    path.join(dir, "description.txt"),
    metadata[locale].description,
  );
  fs.writeFileSync(path.join(dir, "keywords.txt"), metadata[locale].keywords);
  fs.writeFileSync(
    path.join(dir, "promotional_text.txt"),
    metadata[locale].promotional_text,
  );

  console.log(`✅ Dossier et fichiers Fastlane créés pour : ${locale}`);
});

console.log(
  "🚀 Terminé ! Tu peux maintenant vérifier tes dossiers Fastlane et lancer 'fastlane deliver'.",
);
