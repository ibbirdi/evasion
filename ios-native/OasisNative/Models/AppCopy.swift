import Foundation

struct AppStrings {
    struct Header {
        var title: String
        var timer: String
    }

    struct Channels {
        var oiseaux: String
        var vent: String
        var plage: String
        var goelands: String
        var foret: String
        var pluie: String
        var tonnerre: String
        var cigales: String
        var grillons: String
        var tente: String
        var riviere: String
        var village: String
        var voiture: String
        var train: String

        subscript(channel: SoundChannel) -> String {
            switch channel {
            case .oiseaux: return oiseaux
            case .vent: return vent
            case .plage: return plage
            case .goelands: return goelands
            case .foret: return foret
            case .pluie: return pluie
            case .tonnerre: return tonnerre
            case .cigales: return cigales
            case .grillons: return grillons
            case .tente: return tente
            case .riviere: return riviere
            case .village: return village
            case .voiture: return voiture
            case .train: return train
            }
        }
    }

    struct Presets {
        var defaultCalm: String
        var defaultStorm: String
    }

    struct Modal {
        var title: String
        var defaultPresets: String
        var yourPresets: String
        var saveNew: String
        var presetName: String
        var save: String
        var cancel: String
        var noPresets: String
    }

    struct Paywall {
        var title: String
        var benefit1: String
        var benefit2: String
        var benefit3: String
        var benefit4: String
        var noSub: String
        var cta: String
        var restore: String
        var terms: String
    }

    struct Binaural {
        var title: String
        var delta: String
        var deltaFreq: String
        var theta: String
        var thetaFreq: String
        var alpha: String
        var alphaFreq: String
        var beta: String
        var betaFreq: String
        var headphonesHint: String

        subscript(track: BinauralTrack) -> String {
            switch track {
            case .delta: return delta
            case .theta: return theta
            case .alpha: return alpha
            case .beta: return beta
            }
        }

        func frequencyLabel(for track: BinauralTrack) -> String {
            switch track {
            case .delta: return deltaFreq
            case .theta: return thetaFreq
            case .alpha: return alphaFreq
            case .beta: return betaFreq
            }
        }
    }

    struct Mixer {
        var autoVariation: String
    }

    var header: Header
    var channels: Channels
    var presets: Presets
    var modal: Modal
    var paywall: Paywall
    var binaural: Binaural
    var mixer: Mixer
}

enum AppTranslations {
    static let all: [AppLanguage: AppStrings] = [
        .en: AppStrings(
            header: .init(title: "Oasis", timer: "Timer"),
            channels: .init(
                oiseaux: "Birds",
                vent: "Wind",
                plage: "Beach",
                goelands: "Seagulls",
                foret: "Forest",
                pluie: "Rain",
                tonnerre: "Thunder",
                cigales: "Cicadas",
                grillons: "Crickets",
                tente: "Tent",
                riviere: "River",
                village: "Village",
                voiture: "Car Ride",
                train: "Train"
            ),
            presets: .init(defaultCalm: "Calm Forest", defaultStorm: "Distant Storm"),
            modal: .init(
                title: "My Oasis",
                defaultPresets: "Default Presets",
                yourPresets: "Your Presets",
                saveNew: "Save new preset",
                presetName: "Preset name...",
                save: "Save",
                cancel: "Cancel",
                noPresets: "No custom presets yet."
            ),
            paywall: .init(
                title: "Unlock the Full Experience",
                benefit1: "Unlimited access to all 14 premium sounds",
                benefit2: "Sleep and focus timer",
                benefit3: "Save your custom mixes",
                benefit4: "Exclusive high-fidelity mixing",
                noSub: "Pay once. Yours forever. No subscriptions.",
                cta: "Unlock Lifetime - ",
                restore: "Restore Purchases",
                terms: "Terms of Use"
            ),
            binaural: .init(
                title: "BINAURAL BEATS",
                delta: "Sleep",
                deltaFreq: "Delta (3 Hz)",
                theta: "Relax",
                thetaFreq: "Theta (6 Hz)",
                alpha: "Focus",
                alphaFreq: "Alpha (10 Hz)",
                beta: "Awake",
                betaFreq: "Beta (15 Hz)",
                headphonesHint: "Stereo headphones recommended"
            ),
            mixer: .init(autoVariation: "AUTO VARIATION")
        ),
        .fr: AppStrings(
            header: .init(title: "Oasis", timer: "Timer"),
            channels: .init(
                oiseaux: "Oiseaux",
                vent: "Vent",
                plage: "Plage",
                goelands: "Goélands",
                foret: "Forêt",
                pluie: "Pluie",
                tonnerre: "Orage",
                cigales: "Cigales",
                grillons: "Grillons",
                tente: "Tente",
                riviere: "Rivière",
                village: "Village",
                voiture: "Voiture",
                train: "Train"
            ),
            presets: .init(defaultCalm: "Calme en forêt", defaultStorm: "Orage lointain"),
            modal: .init(
                title: "Mes Oasis",
                defaultPresets: "Presets par défaut",
                yourPresets: "Vos presets",
                saveNew: "Nouveau preset",
                presetName: "Nom...",
                save: "Enregistrer",
                cancel: "Annuler",
                noPresets: "Aucun preset personnalisé."
            ),
            paywall: .init(
                title: "Débloquez l'expérience complète",
                benefit1: "Accès illimité aux 14 sons premium",
                benefit2: "Minuteur de sommeil et concentration",
                benefit3: "Sauvegardez vos mix personnalisés",
                benefit4: "Mixage exclusif haute fidélité",
                noSub: "Paiement unique. Zéro abonnement.",
                cta: "Débloquer à vie - ",
                restore: "Restaurer les achats",
                terms: "Conditions d'utilisation"
            ),
            binaural: .init(
                title: "SONS BINAURAUX",
                delta: "Sommeil",
                deltaFreq: "Delta (3 Hz)",
                theta: "Relaxation",
                thetaFreq: "Theta (6 Hz)",
                alpha: "Concentration",
                alphaFreq: "Alpha (10 Hz)",
                beta: "Éveil",
                betaFreq: "Beta (15 Hz)",
                headphonesHint: "Casque stéréo recommandé"
            ),
            mixer: .init(autoVariation: "VARIATION AUTO")
        ),
        .es: AppStrings(
            header: .init(title: "Oasis", timer: "Temp"),
            channels: .init(
                oiseaux: "Pájaros",
                vent: "Viento",
                plage: "Playa",
                goelands: "Gaviotas",
                foret: "Bosque",
                pluie: "Lluvia",
                tonnerre: "Truenos",
                cigales: "Cigarras",
                grillons: "Grillos",
                tente: "Tienda",
                riviere: "Río",
                village: "Pueblo",
                voiture: "Coche",
                train: "Tren"
            ),
            presets: .init(defaultCalm: "Bosque Trancuilo", defaultStorm: "Tormenta Lejana"),
            modal: .init(
                title: "Mis oasis",
                defaultPresets: "Presets por defecto",
                yourPresets: "Tus presets",
                saveNew: "Guardar nuevo",
                presetName: "Nombre...",
                save: "Guardar",
                cancel: "Cancelar",
                noPresets: "Aún no hay preajustes personalizados."
            ),
            paywall: .init(
                title: "Desbloquea la experiencia completa",
                benefit1: "Acceso ilimitado a los 14 sonidos premium",
                benefit2: "Temporizador de sueño y concentración",
                benefit3: "Guarda tus mezclas personalizadas",
                benefit4: "Mezcla exclusiva de alta fidelidad",
                noSub: "Pago único. Tuyo para siempre. Sin suscripciones.",
                cta: "Desbloquear de por vida - ",
                restore: "Restaurar compras",
                terms: "Términos de uso"
            ),
            binaural: .init(
                title: "SONIDOS BINAURALES",
                delta: "Sueño",
                deltaFreq: "Delta (3 Hz)",
                theta: "Relajación",
                thetaFreq: "Theta (6 Hz)",
                alpha: "Enfoque",
                alphaFreq: "Alpha (10 Hz)",
                beta: "Despierto",
                betaFreq: "Beta (15 Hz)",
                headphonesHint: "Auriculares estéreo recomendados"
            ),
            mixer: .init(autoVariation: "VARIACIÓN AUTO")
        ),
        .de: AppStrings(
            header: .init(title: "Oasis", timer: "Timer"),
            channels: .init(
                oiseaux: "Vögel",
                vent: "Wind",
                plage: "Strand",
                goelands: "Möwen",
                foret: "Wald",
                pluie: "Regen",
                tonnerre: "Donner",
                cigales: "Zikaden",
                grillons: "Grillen",
                tente: "Zelt",
                riviere: "Fluss",
                village: "Dorf",
                voiture: "Autofahrt",
                train: "Zug"
            ),
            presets: .init(defaultCalm: "Ruhiger Wald", defaultStorm: "Fernes Gewitter"),
            modal: .init(
                title: "Meine Oasis",
                defaultPresets: "Standard Presets",
                yourPresets: "Deine Presets",
                saveNew: "Neues Preset speichern",
                presetName: "Name...",
                save: "Speichern",
                cancel: "Abbrechen",
                noPresets: "Noch keine eigenen Presets."
            ),
            paywall: .init(
                title: "Schalten Sie das volle Erlebnis frei",
                benefit1: "Unbegrenzter Zugang zu allen 14 Premium-Klängen",
                benefit2: "Schlaf- und Fokus-Timer",
                benefit3: "Speichern Sie Ihre eigenen Mixe",
                benefit4: "Exklusives High-Fidelity-Mixing",
                noSub: "Einmalig zahlen. Für immer Ihnen. Kein Abo.",
                cta: "Lebenslang freischalten - ",
                restore: "Käufe wiederherstellen",
                terms: "Nutzungsbedingungen"
            ),
            binaural: .init(
                title: "BINAURALE BEATS",
                delta: "Schlaf",
                deltaFreq: "Delta (3 Hz)",
                theta: "Entspannen",
                thetaFreq: "Theta (6 Hz)",
                alpha: "Fokus",
                alphaFreq: "Alpha (10 Hz)",
                beta: "Wach",
                betaFreq: "Beta (15 Hz)",
                headphonesHint: "Stereokopfhörer empfohlen"
            ),
            mixer: .init(autoVariation: "AUTO-VARIATION")
        ),
        .it: AppStrings(
            header: .init(title: "Oasi", timer: "Timer"),
            channels: .init(
                oiseaux: "Uccelli",
                vent: "Vento",
                plage: "Spiaggia",
                goelands: "Gabbiani",
                foret: "Foresta",
                pluie: "Pioggia",
                tonnerre: "Tuono",
                cigales: "Cicale",
                grillons: "Grilli",
                tente: "Tenda",
                riviere: "Fiume",
                village: "Villaggio",
                voiture: "Auto",
                train: "Treno"
            ),
            presets: .init(defaultCalm: "Foresta Calma", defaultStorm: "Tempesta Lontana"),
            modal: .init(
                title: "Le mie oasi",
                defaultPresets: "Preset Predefiniti",
                yourPresets: "I tuoi Preset",
                saveNew: "Salva nuovo",
                presetName: "Nome...",
                save: "Salva",
                cancel: "Annulla",
                noPresets: "Nessun preset personalizzato ancora."
            ),
            paywall: .init(
                title: "Sblocca l'esperienza completa",
                benefit1: "Accesso illimitato a tutti i 14 suoni premium",
                benefit2: "Timer per il sonno e la concentrazione",
                benefit3: "Salva i tuoi mix personalizzati",
                benefit4: "Mixaggio esclusivo ad alta fedeltà",
                noSub: "Paghi una volta. Tuo per sempre. Nessun abbonamento.",
                cta: "Sblocca a vita - ",
                restore: "Ripristina acquisti",
                terms: "Termini di utilizzo"
            ),
            binaural: .init(
                title: "SUONI BINAURALI",
                delta: "Sonno",
                deltaFreq: "Delta (3 Hz)",
                theta: "Relax",
                thetaFreq: "Theta (6 Hz)",
                alpha: "Focus",
                alphaFreq: "Alpha (10 Hz)",
                beta: "Sveglio",
                betaFreq: "Beta (15 Hz)",
                headphonesHint: "Cuffie stereo consigliate"
            ),
            mixer: .init(autoVariation: "VARIAZIONE AUTO")
        ),
        .pt: AppStrings(
            header: .init(title: "Oasis", timer: "Timer"),
            channels: .init(
                oiseaux: "Pássaros",
                vent: "Vento",
                plage: "Praia",
                goelands: "Gaivotas",
                foret: "Floresta",
                pluie: "Chuva",
                tonnerre: "Trovão",
                cigales: "Cigarras",
                grillons: "Grilos",
                tente: "Tenda",
                riviere: "Rio",
                village: "Aldeia",
                voiture: "Carro",
                train: "Trem"
            ),
            presets: .init(defaultCalm: "Floresta Calma", defaultStorm: "Tempestade Distante"),
            modal: .init(
                title: "Meus Oasis",
                defaultPresets: "Padrão",
                yourPresets: "Seus Presets",
                saveNew: "Salvar novo",
                presetName: "Nome...",
                save: "Salvar",
                cancel: "Cancelar",
                noPresets: "Nenhum preset personalizado ainda."
            ),
            paywall: .init(
                title: "Desbloqueie a experiência completa",
                benefit1: "Acesso ilimitado a todos os 14 sons premium",
                benefit2: "Timer de sono e concentração",
                benefit3: "Salve suas mixagens personalizadas",
                benefit4: "Mixagem exclusiva de alta fidelidade",
                noSub: "Pague uma vez. Seu para sempre. Sem assinaturas.",
                cta: "Desbloqueio vitalício - ",
                restore: "Restaurar compras",
                terms: "Termos de uso"
            ),
            binaural: .init(
                title: "SONS BINAURAIS",
                delta: "Sono",
                deltaFreq: "Delta (3 Hz)",
                theta: "Relaxar",
                thetaFreq: "Theta (6 Hz)",
                alpha: "Foco",
                alphaFreq: "Alpha (10 Hz)",
                beta: "Desperto",
                betaFreq: "Beta (15 Hz)",
                headphonesHint: "Fones estéreo recomendados"
            ),
            mixer: .init(autoVariation: "VARIAÇÃO AUTO")
        )
    ]
}
