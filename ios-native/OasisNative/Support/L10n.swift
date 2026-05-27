import Foundation
import SwiftUI

enum L10n {
    static func string(_ resource: LocalizedStringResource) -> String {
        String(localized: resource)
    }

    static func timerOptionLabel(minutes: Int?) -> String {
        switch minutes {
        case nil:
            return string(Header.off)
        case 15:
            return string(Timer.option15)
        case 30:
            return string(Timer.option30)
        case 60:
            return string(Timer.option60)
        case 120:
            return string(Timer.option120)
        case let value?:
            return "\(value) min"
        }
    }

    enum App {
        static let title = LocalizedStringResource(
            "app.title",
            defaultValue: "Oasis",
            bundle: .main,
            comment: "App title and fallback brand label when the logo image is unavailable."
        )

        static let nowPlayingArtist = LocalizedStringResource(
            "audio.nowPlaying.artist",
            defaultValue: "Nature soundscapes",
            bundle: .main,
            comment: "Artist line shown in iOS Now Playing for the app audio session."
        )
    }

    enum Header {
        static let timer = LocalizedStringResource(
            "header.timer",
            defaultValue: "Timer",
            bundle: .main,
            comment: "Short label for the timer control in the home header."
        )

        static let immersive = LocalizedStringResource(
            "header.immersive",
            defaultValue: "Immersive",
            bundle: .main,
            comment: "Short label for the immersive audio toggle in the home header."
        )

        static let immersiveSound = LocalizedStringResource(
            "header.immersive.sound",
            defaultValue: "Immersive sound",
            bundle: .main,
            comment: "Visible label shown next to the immersive audio toggle when enabled."
        )

        static let immersiveEnabled = LocalizedStringResource(
            "header.immersive.enabled",
            defaultValue: "On",
            bundle: .main,
            comment: "Accessibility value when immersive audio is enabled."
        )

        static let immersiveDisabled = LocalizedStringResource(
            "header.immersive.disabled",
            defaultValue: "Off",
            bundle: .main,
            comment: "Accessibility value when immersive audio is disabled."
        )

        static let off = LocalizedStringResource(
            "header.off",
            defaultValue: "Off",
            bundle: .main,
            comment: "Menu action that disables the timer."
        )

        static let activeFilter = LocalizedStringResource(
            "header.activeFilter",
            defaultValue: "Show only active sounds",
            bundle: .main,
            comment: "Accessibility label for the toolbar button that filters the mixer to active sounds."
        )

        static let activeFilterOn = LocalizedStringResource(
            "header.activeFilter.on",
            defaultValue: "Filtering active sounds",
            bundle: .main,
            comment: "Accessibility value when the active-sounds filter is enabled."
        )

        static let activeFilterOff = LocalizedStringResource(
            "header.activeFilter.off",
            defaultValue: "Showing all sounds",
            bundle: .main,
            comment: "Accessibility value when the active-sounds filter is disabled."
        )
    }

    enum Mac {
        static let mixer = LocalizedStringResource(
            "mac.section.mixer",
            defaultValue: "Mixer",
            bundle: .main,
            comment: "macOS panel section title for the ambient sound mixer."
        )

        static let spatial = LocalizedStringResource(
            "mac.section.spatial",
            defaultValue: "Placement",
            bundle: .main,
            comment: "macOS panel section title for spatial placement controls."
        )

        static let activeSoundsCount = LocalizedStringResource(
            "mac.header.activeSounds",
            defaultValue: "active sounds",
            bundle: .main,
            comment: "Lowercase suffix after the number of active sounds in the macOS header."
        )

        static let searchSounds = LocalizedStringResource(
            "mac.mixer.search",
            defaultValue: "Search sounds",
            bundle: .main,
            comment: "Placeholder for the macOS mixer sound search field."
        )

        static let allSounds = LocalizedStringResource(
            "mac.mixer.allSounds",
            defaultValue: "All sounds",
            bundle: .main,
            comment: "Toggle label that shows every sound in the macOS mixer."
        )

        static let activeOnly = LocalizedStringResource(
            "mac.mixer.activeOnly",
            defaultValue: "Active only",
            bundle: .main,
            comment: "Toggle label that filters the macOS mixer to active sounds."
        )

        static let quit = LocalizedStringResource(
            "mac.command.quit",
            defaultValue: "Quit Oasis",
            bundle: .main,
            comment: "macOS panel command that quits the app."
        )

        static let savePresetPlaceholder = LocalizedStringResource(
            "mac.presets.savePlaceholder",
            defaultValue: "New mix name",
            bundle: .main,
            comment: "Placeholder in the macOS preset save text field."
        )

        static let emptySearch = LocalizedStringResource(
            "mac.mixer.emptySearch",
            defaultValue: "No sounds match this search.",
            bundle: .main,
            comment: "Empty state when the macOS sound search has no results."
        )

        static let selectSound = LocalizedStringResource(
            "mac.spatial.selectSound",
            defaultValue: "Select a sound",
            bundle: .main,
            comment: "Label for the macOS spatial sound picker."
        )

        static let premiumUnlocked = LocalizedStringResource(
            "mac.premium.unlocked",
            defaultValue: "Premium unlocked",
            bundle: .main,
            comment: "Status label in the macOS panel when premium is active."
        )
    }

    enum HomeControls {
        static let shuffle = LocalizedStringResource(
            "home.controls.shuffle",
            defaultValue: "Random mix",
            bundle: .main,
            comment: "Accessibility label for the home bottom shuffle button."
        )

        static let compose = LocalizedStringResource(
            "home.controls.compose",
            defaultValue: "Open routines",
            bundle: .main,
            comment: "Accessibility label for the home bottom button that opens guided routines."
        )

        static let activeRitual = LocalizedStringResource(
            "home.controls.activeRitual",
            defaultValue: "Open active ritual",
            bundle: .main,
            comment: "Accessibility label for the home bottom compose button while a ritual is active."
        )

        static let presets = LocalizedStringResource(
            "home.controls.presets",
            defaultValue: "Saved mixes",
            bundle: .main,
            comment: "Accessibility label for the home bottom presets button."
        )

        static let play = LocalizedStringResource(
            "home.controls.play",
            defaultValue: "Play",
            bundle: .main,
            comment: "Accessibility label for the home bottom playback button when playback is stopped."
        )

        static let pause = LocalizedStringResource(
            "home.controls.pause",
            defaultValue: "Pause",
            bundle: .main,
            comment: "Accessibility label for the home bottom playback button when playback is active."
        )

        static let binaural = LocalizedStringResource(
            "home.controls.binaural",
            defaultValue: "Binaural modes",
            bundle: .main,
            comment: "Accessibility label for the home bottom binaural modes button."
        )

        static let routePicker = LocalizedStringResource(
            "home.controls.routePicker",
            defaultValue: "Audio output",
            bundle: .main,
            comment: "Accessibility label for the home bottom audio route picker."
        )
    }

    enum HomeActive {
        static let activeRoutine = LocalizedStringResource(
            "home.routine.active",
            defaultValue: "Routine active",
            bundle: .main,
            comment: "Small status label shown on Home while a guided routine is active."
        )

        static let stopRoutine = LocalizedStringResource(
            "home.routine.stop",
            defaultValue: "Stop routine",
            bundle: .main,
            comment: "Button that stops the active guided routine and returns Home to normal mixing mode."
        )

        static let routineRestTitle = LocalizedStringResource(
            "home.routine.rest.title",
            defaultValue: "You can put the iPhone down",
            bundle: .main,
            comment: "Quiet footer title shown after guided routine rows on Home."
        )

        static let routineRestSubtitle = LocalizedStringResource(
            "home.routine.rest.subtitle",
            defaultValue: "Oasis keeps the layers steady and fades out at the end.",
            bundle: .main,
            comment: "Quiet footer subtitle shown after guided routine rows on Home."
        )

        static let routineSupportingLayers = LocalizedStringResource(
            "home.routine.supportingLayers",
            defaultValue: "Softer layers",
            bundle: .main,
            comment: "Compact label for guided routine layers that are playing in the background."
        )

        static let listening = LocalizedStringResource(
            "home.active.listening",
            defaultValue: "Now playing",
            bundle: .main,
            comment: "Small status label on the Home active scene card while audio is playing."
        )

        static let paused = LocalizedStringResource(
            "home.active.paused",
            defaultValue: "Paused",
            bundle: .main,
            comment: "Small status label on the Home active scene card while audio is paused."
        )

        static let adjust = LocalizedStringResource(
            "home.active.adjust",
            defaultValue: "Adjust",
            bundle: .main,
            comment: "Accessibility hint for opening the active scene controls from Home."
        )

        static let addTimer = LocalizedStringResource(
            "home.active.addTimer",
            defaultValue: "Set 30 min timer",
            bundle: .main,
            comment: "Accessibility label for adding a 30 minute timer from the active Home scene card."
        )

        static let clearTimer = LocalizedStringResource(
            "home.active.clearTimer",
            defaultValue: "Clear timer",
            bundle: .main,
            comment: "Accessibility label for clearing the timer from the active Home scene card."
        )
    }

    enum Compose {
        static let title = LocalizedStringResource(
            "compose.title",
            defaultValue: "Routines",
            bundle: .main,
            comment: "Title of the simplified guided ambience panel."
        )

        static let subtitle = LocalizedStringResource(
            "compose.subtitle",
            defaultValue: "Pick a need, preview the mix, then start.",
            bundle: .main,
            comment: "Subtitle of the simplified guided ambience panel."
        )

        static let routinePlan = LocalizedStringResource(
            "compose.routine.plan",
            defaultValue: "What will happen",
            bundle: .main,
            comment: "Heading above the short explanation of what a guided routine will start."
        )

        static let routineContext = LocalizedStringResource(
            "compose.routine.context",
            defaultValue: "Oasis prepares this mix, then starts it together.",
            bundle: .main,
            comment: "Short explanatory sentence in the routine detail card."
        )

        static let routineLayerAmbience = LocalizedStringResource(
            "compose.routine.layer.ambience",
            defaultValue: "Ambience",
            bundle: .main,
            comment: "Label for the nature sound layer in the routine detail card."
        )

        static let routineLayerMask = LocalizedStringResource(
            "compose.routine.layer.mask",
            defaultValue: "Masking",
            bundle: .main,
            comment: "Label for the noise and binaural masking layer in the routine detail card."
        )

        static let routineLayerEnd = LocalizedStringResource(
            "compose.routine.layer.end",
            defaultValue: "Fade out",
            bundle: .main,
            comment: "Label for the automatic end timer in the routine detail card."
        )

        static let routineStart = LocalizedStringResource(
            "compose.routine.start",
            defaultValue: "Start routine",
            bundle: .main,
            comment: "Primary button that starts the selected guided routine."
        )

        static let routineCurrent = LocalizedStringResource(
            "compose.routine.current",
            defaultValue: "Routine in progress",
            bundle: .main,
            comment: "Disabled primary button label when the selected guided routine is already running."
        )

        static let routineReplace = LocalizedStringResource(
            "compose.routine.replace",
            defaultValue: "Replace routine",
            bundle: .main,
            comment: "Primary button label when launching the selected guided routine will replace the current one."
        )

        static let routineNapTitle = LocalizedStringResource("compose.routine.nap.title", defaultValue: "Short nap", bundle: .main, comment: "Guided routine title for a short free nap mix.")
        static let routineNapSubtitle = LocalizedStringResource("compose.routine.nap.subtitle", defaultValue: "A 15 minute landing: gentle waves, light wind, birds and warm brown noise.", bundle: .main, comment: "Guided routine subtitle for a short free nap mix.")
        static let routineResetTitle = LocalizedStringResource("compose.routine.reset.title", defaultValue: "Soft reset", bundle: .main, comment: "Guided routine title for a free reset mix.")
        static let routineResetSubtitle = LocalizedStringResource("compose.routine.reset.subtitle", defaultValue: "A clear free mix for stepping away: shore, air, birds and a quiet white-noise veil.", bundle: .main, comment: "Guided routine subtitle for a free reset mix.")
        static let routineDeepSleepTitle = LocalizedStringResource("compose.routine.deepSleep.title", defaultValue: "Deep sleep", bundle: .main, comment: "Guided premium routine title for a longer sleep mix.")
        static let routineDeepSleepSubtitle = LocalizedStringResource("compose.routine.deepSleep.subtitle", defaultValue: "A longer night blend with window rain, dark forest air and a low, steady floor.", bundle: .main, comment: "Guided premium routine subtitle for a longer sleep mix.")
        static let routineDeepWorkTitle = LocalizedStringResource("compose.routine.deepWork.title", defaultValue: "Deep work", bundle: .main, comment: "Guided premium routine title for focus work.")
        static let routineDeepWorkSubtitle = LocalizedStringResource("compose.routine.deepWork.subtitle", defaultValue: "A focused room with cafe hush, river detail and a steady green-noise floor.", bundle: .main, comment: "Guided premium routine subtitle for focus work.")
        static let routineNoisyHotelTitle = LocalizedStringResource("compose.routine.noisyHotel.title", defaultValue: "Noisy hotel", bundle: .main, comment: "Guided premium routine title for hotel and transport masking.")
        static let routineNoisyHotelSubtitle = LocalizedStringResource("compose.routine.noisyHotel.subtitle", defaultValue: "A dense offline cover for rooms, trains and planes, with fan and aircraft layers.", bundle: .main, comment: "Guided premium routine subtitle for hotel and transport masking.")
        static let routineReadingTitle = LocalizedStringResource("compose.routine.reading.title", defaultValue: "Evening reading", bundle: .main, comment: "Guided premium routine title for reading.")
        static let routineReadingSubtitle = LocalizedStringResource("compose.routine.reading.subtitle", defaultValue: "A warm corner for books: fire, lake, forest air, soft chimes and stable calm.", bundle: .main, comment: "Guided premium routine subtitle for reading.")
        static let routineRainCabinTitle = LocalizedStringResource("compose.routine.rainCabin.title", defaultValue: "Rain cabin", bundle: .main, comment: "Guided premium routine title for a sheltered rain mix.")
        static let routineRainCabinSubtitle = LocalizedStringResource("compose.routine.rainCabin.subtitle", defaultValue: "A sheltered storm mix with cabin rain, forest rain, distant thunder and a low brown floor.", bundle: .main, comment: "Guided premium routine subtitle for a sheltered rain mix.")
        static let routineMorningTitle = LocalizedStringResource("compose.routine.morning.title", defaultValue: "Gentle morning", bundle: .main, comment: "Guided premium routine title for a bright morning mix.")
        static let routineMorningSubtitle = LocalizedStringResource("compose.routine.morning.subtitle", defaultValue: "A bright start with jungle dawn, birds, lake air and light chimes.", bundle: .main, comment: "Guided premium routine subtitle for a bright morning mix.")

        static let composer = LocalizedStringResource("compose.tab.composer", defaultValue: "Composer", bundle: .main, comment: "Segment title for the composer tab.")
        static let rituals = LocalizedStringResource("compose.tab.rituals", defaultValue: "Rituals", bundle: .main, comment: "Segment title for the rituals tab.")
        static let noise = LocalizedStringResource("compose.tab.noise", defaultValue: "Noise", bundle: .main, comment: "Segment title for the noise lab tab.")
        static let promptPlaceholder = LocalizedStringResource("compose.prompt.placeholder", defaultValue: "Hotel noise, deep work, rain for reading...", bundle: .main, comment: "Placeholder for the local ambience prompt.")
        static let suggestionHotelTitle = LocalizedStringResource("compose.suggestion.hotel.title", defaultValue: "Noisy hotel", bundle: .main, comment: "Composer prompt suggestion chip for noisy hotel rooms.")
        static let suggestionHotelPrompt = LocalizedStringResource("compose.suggestion.hotel.prompt", defaultValue: "Noisy hotel, steady travel mask, no sharp sounds", bundle: .main, comment: "Prompt inserted by the noisy hotel composer suggestion.")
        static let suggestionWorkTitle = LocalizedStringResource("compose.suggestion.work.title", defaultValue: "Deep work", bundle: .main, comment: "Composer prompt suggestion chip for focus work.")
        static let suggestionWorkPrompt = LocalizedStringResource("compose.suggestion.work.prompt", defaultValue: "Deep work, steady noise, cafe hush", bundle: .main, comment: "Prompt inserted by the deep work composer suggestion.")
        static let suggestionReadingTitle = LocalizedStringResource("compose.suggestion.reading.title", defaultValue: "Quiet reading", bundle: .main, comment: "Composer prompt suggestion chip for quiet reading.")
        static let suggestionReadingPrompt = LocalizedStringResource("compose.suggestion.reading.prompt", defaultValue: "Quiet reading, warm room, no thunder", bundle: .main, comment: "Prompt inserted by the quiet reading composer suggestion.")
        static let suggestionNapTitle = LocalizedStringResource("compose.suggestion.nap.title", defaultValue: "Short nap", bundle: .main, comment: "Composer prompt suggestion chip for a short nap.")
        static let suggestionNapPrompt = LocalizedStringResource("compose.suggestion.nap.prompt", defaultValue: "Short nap, brown noise, gentle waves", bundle: .main, comment: "Prompt inserted by the short nap composer suggestion.")
        static let generate = LocalizedStringResource("compose.generate", defaultValue: "Compose", bundle: .main, comment: "Button that generates an ambience recipe.")
        static let surprise = LocalizedStringResource("compose.surprise", defaultValue: "Surprise me", bundle: .main, comment: "Button that generates a random ambience.")
        static let apply = LocalizedStringResource("compose.apply", defaultValue: "Apply & play", bundle: .main, comment: "Button that applies a generated ambience and starts playback.")
        static let start = LocalizedStringResource("compose.start", defaultValue: "Start", bundle: .main, comment: "Button that starts a ritual.")
        static let stopRitual = LocalizedStringResource("compose.stopRitual", defaultValue: "Stop ritual", bundle: .main, comment: "Button that stops the active ritual while leaving audio as-is.")
        static let stopRitualConfirmationTitle = LocalizedStringResource("compose.stopRitual.confirmation.title", defaultValue: "Stop this ritual?", bundle: .main, comment: "Title of the confirmation alert before stopping an active ritual.")
        static let stopRitualConfirmationMessage = LocalizedStringResource("compose.stopRitual.confirmation.message", defaultValue: "Your current sound mix will keep playing, but the ritual timeline will end.", bundle: .main, comment: "Message of the confirmation alert before stopping an active ritual.")
        static let pauseRitual = LocalizedStringResource("compose.pauseRitual", defaultValue: "Pause ritual", bundle: .main, comment: "Button that pauses the active ritual.")
        static let resumeRitual = LocalizedStringResource("compose.resumeRitual", defaultValue: "Resume ritual", bundle: .main, comment: "Button that resumes the active ritual.")
        static let activeRitual = LocalizedStringResource("compose.activeRitual", defaultValue: "Active ritual", bundle: .main, comment: "Label shown above the currently running ritual.")
        static let pausedRitual = LocalizedStringResource("compose.pausedRitual", defaultValue: "Paused", bundle: .main, comment: "Short status shown when an active ritual is paused.")
        static let nextPhase = LocalizedStringResource("compose.nextPhase", defaultValue: "Next", bundle: .main, comment: "Short label that introduces the next phase in an active ritual.")
        static let advancePhase = LocalizedStringResource("compose.advancePhase", defaultValue: "Skip", bundle: .main, comment: "Compact button title that advances an active ritual to the next phase.")
        static let free = LocalizedStringResource("compose.free", defaultValue: "Free", bundle: .main, comment: "Badge for a free composer item.")
        static let premium = LocalizedStringResource("compose.premium", defaultValue: "Premium", bundle: .main, comment: "Badge for a premium composer item.")
        static let intentSleep = LocalizedStringResource("compose.intent.sleep", defaultValue: "Sleep", bundle: .main, comment: "Composer sleep intent.")
        static let intentFocus = LocalizedStringResource("compose.intent.focus", defaultValue: "Focus", bundle: .main, comment: "Composer focus intent.")
        static let intentTravel = LocalizedStringResource("compose.intent.travel", defaultValue: "Travel", bundle: .main, comment: "Composer travel intent.")
        static let intentReading = LocalizedStringResource("compose.intent.reading", defaultValue: "Reading", bundle: .main, comment: "Composer reading intent.")
        static let intentReset = LocalizedStringResource("compose.intent.reset", defaultValue: "Reset", bundle: .main, comment: "Composer reset intent.")
        static let sleepCocoonTitle = LocalizedStringResource("compose.recipe.sleep.title", defaultValue: "Sleep cocoon", bundle: .main, comment: "Generated sleep recipe title.")
        static let focusCocoonTitle = LocalizedStringResource("compose.recipe.focus.title", defaultValue: "Focus bubble", bundle: .main, comment: "Generated focus recipe title.")
        static let travelShieldTitle = LocalizedStringResource("compose.recipe.travel.title", defaultValue: "Travel shield", bundle: .main, comment: "Generated travel recipe title.")
        static let readingRoomTitle = LocalizedStringResource("compose.recipe.reading.title", defaultValue: "Reading room", bundle: .main, comment: "Generated reading recipe title.")
        static let resetTitle = LocalizedStringResource("compose.recipe.reset.title", defaultValue: "Oasis reset", bundle: .main, comment: "Generated reset recipe title.")
        static let sleepSubtitle = LocalizedStringResource("compose.recipe.sleep.subtitle", defaultValue: "Real waves, night air and a warm brown-noise floor.", bundle: .main, comment: "Generated premium sleep recipe subtitle.")
        static let focusSubtitle = LocalizedStringResource("compose.recipe.focus.subtitle", defaultValue: "A steady work bed for staying in flow.", bundle: .main, comment: "Generated focus recipe subtitle.")
        static let travelSubtitle = LocalizedStringResource("compose.recipe.travel.subtitle", defaultValue: "A denser offline mask for hotel rooms and transport.", bundle: .main, comment: "Generated premium travel recipe subtitle.")
        static let readingSubtitle = LocalizedStringResource("compose.recipe.reading.subtitle", defaultValue: "A warm room for books, journaling and evening calm.", bundle: .main, comment: "Generated premium reading recipe subtitle.")
        static let resetSubtitle = LocalizedStringResource("compose.recipe.reset.subtitle", defaultValue: "The simple Oasis starter mix, cleaned up and ready.", bundle: .main, comment: "Generated reset recipe subtitle.")
        static let ritualSleepTitle = LocalizedStringResource("compose.ritual.sleep.title", defaultValue: "Sleep Descent", bundle: .main, comment: "Sleep ritual title.")
        static let ritualSleepSubtitle = LocalizedStringResource("compose.ritual.sleep.subtitle", defaultValue: "A 30 min wind-down that slowly darkens into waves and brown noise.", bundle: .main, comment: "Sleep ritual subtitle.")
        static let ritualFocusTitle = LocalizedStringResource("compose.ritual.focus.title", defaultValue: "Deep Work", bundle: .main, comment: "Focus ritual title.")
        static let ritualFocusSubtitle = LocalizedStringResource("compose.ritual.focus.subtitle", defaultValue: "A 50 min focus block with cafe air, green noise and Beta support.", bundle: .main, comment: "Focus ritual subtitle.")
        static let ritualTravelTitle = LocalizedStringResource("compose.ritual.travel.title", defaultValue: "Travel Shield", bundle: .main, comment: "Travel ritual title.")
        static let ritualTravelSubtitle = LocalizedStringResource("compose.ritual.travel.subtitle", defaultValue: "A 45 min offline mask for hotel rooms, trains and planes.", bundle: .main, comment: "Travel ritual subtitle.")
        static let ritualReadingTitle = LocalizedStringResource("compose.ritual.reading.title", defaultValue: "Reading Room", bundle: .main, comment: "Reading ritual title.")
        static let ritualReadingSubtitle = LocalizedStringResource("compose.ritual.reading.subtitle", defaultValue: "A 35 min quiet room for books, journaling and evening calm.", bundle: .main, comment: "Reading ritual subtitle.")
        static let ritualSleepPhaseSettleTitle = LocalizedStringResource("compose.ritual.sleep.phase.settle.title", defaultValue: "Settle", bundle: .main, comment: "Sleep ritual first phase title.")
        static let ritualSleepPhaseSettleSubtitle = LocalizedStringResource("compose.ritual.sleep.phase.settle.subtitle", defaultValue: "Birds, wind and a soft shoreline.", bundle: .main, comment: "Sleep ritual first phase subtitle.")
        static let ritualSleepPhaseDriftTitle = LocalizedStringResource("compose.ritual.sleep.phase.drift.title", defaultValue: "Drift", bundle: .main, comment: "Sleep ritual middle phase title.")
        static let ritualSleepPhaseDriftSubtitle = LocalizedStringResource("compose.ritual.sleep.phase.drift.subtitle", defaultValue: "Brown noise takes the edges off the room.", bundle: .main, comment: "Sleep ritual middle phase subtitle.")
        static let ritualSleepPhaseFadeTitle = LocalizedStringResource("compose.ritual.sleep.phase.fade.title", defaultValue: "Fade", bundle: .main, comment: "Sleep ritual final phase title.")
        static let ritualSleepPhaseFadeSubtitle = LocalizedStringResource("compose.ritual.sleep.phase.fade.subtitle", defaultValue: "A quieter bed for the final minutes.", bundle: .main, comment: "Sleep ritual final phase subtitle.")
        static let ritualFocusPhaseEnterTitle = LocalizedStringResource("compose.ritual.focus.phase.enter.title", defaultValue: "Enter", bundle: .main, comment: "Focus ritual first phase title.")
        static let ritualFocusPhaseEnterSubtitle = LocalizedStringResource("compose.ritual.focus.phase.enter.subtitle", defaultValue: "Low cafe room, wind and a steady focus bed.", bundle: .main, comment: "Focus ritual first phase subtitle.")
        static let ritualFocusPhaseFlowTitle = LocalizedStringResource("compose.ritual.focus.phase.flow.title", defaultValue: "Flow", bundle: .main, comment: "Focus ritual middle phase title.")
        static let ritualFocusPhaseFlowSubtitle = LocalizedStringResource("compose.ritual.focus.phase.flow.subtitle", defaultValue: "Green noise and Beta sit under the room.", bundle: .main, comment: "Focus ritual middle phase subtitle.")
        static let ritualFocusPhaseReturnTitle = LocalizedStringResource("compose.ritual.focus.phase.return.title", defaultValue: "Return", bundle: .main, comment: "Focus ritual final phase title.")
        static let ritualFocusPhaseReturnSubtitle = LocalizedStringResource("compose.ritual.focus.phase.return.subtitle", defaultValue: "The scene lightens before the timer ends.", bundle: .main, comment: "Focus ritual final phase subtitle.")
        static let ritualTravelPhaseCoverTitle = LocalizedStringResource("compose.ritual.travel.phase.cover.title", defaultValue: "Cover", bundle: .main, comment: "Travel ritual first phase title.")
        static let ritualTravelPhaseCoverSubtitle = LocalizedStringResource("compose.ritual.travel.phase.cover.subtitle", defaultValue: "Aircraft hush, wind and distant water.", bundle: .main, comment: "Travel ritual first phase subtitle.")
        static let ritualTravelPhaseHoldTitle = LocalizedStringResource("compose.ritual.travel.phase.hold.title", defaultValue: "Hold", bundle: .main, comment: "Travel ritual middle phase title.")
        static let ritualTravelPhaseHoldSubtitle = LocalizedStringResource("compose.ritual.travel.phase.hold.subtitle", defaultValue: "A steadier shield for unpredictable rooms.", bundle: .main, comment: "Travel ritual middle phase subtitle.")
        static let ritualTravelPhaseSoftenTitle = LocalizedStringResource("compose.ritual.travel.phase.soften.title", defaultValue: "Soften", bundle: .main, comment: "Travel ritual final phase title.")
        static let ritualTravelPhaseSoftenSubtitle = LocalizedStringResource("compose.ritual.travel.phase.soften.subtitle", defaultValue: "Less low end before the session closes.", bundle: .main, comment: "Travel ritual final phase subtitle.")
        static let ritualReadingPhaseOpenTitle = LocalizedStringResource("compose.ritual.reading.phase.open.title", defaultValue: "Open", bundle: .main, comment: "Reading ritual first phase title.")
        static let ritualReadingPhaseOpenSubtitle = LocalizedStringResource("compose.ritual.reading.phase.open.subtitle", defaultValue: "Campfire, forest air and a little wind.", bundle: .main, comment: "Reading ritual first phase subtitle.")
        static let ritualReadingPhaseReadTitle = LocalizedStringResource("compose.ritual.reading.phase.read.title", defaultValue: "Read", bundle: .main, comment: "Reading ritual middle phase title.")
        static let ritualReadingPhaseReadSubtitle = LocalizedStringResource("compose.ritual.reading.phase.read.subtitle", defaultValue: "Warm texture with a soft noise floor.", bundle: .main, comment: "Reading ritual middle phase subtitle.")
        static let ritualReadingPhaseCloseTitle = LocalizedStringResource("compose.ritual.reading.phase.close.title", defaultValue: "Close", bundle: .main, comment: "Reading ritual final phase title.")
        static let ritualReadingPhaseCloseSubtitle = LocalizedStringResource("compose.ritual.reading.phase.close.subtitle", defaultValue: "The room gets smaller and quieter.", bundle: .main, comment: "Reading ritual final phase subtitle.")
    }

    enum NoiseLab {
        static let title = LocalizedStringResource("noise.title", defaultValue: "Noise Lab", bundle: .main, comment: "Title of the procedural noise tab.")
        static let subtitle = LocalizedStringResource("noise.subtitle", defaultValue: "Local procedural layers for masking, focus and travel. No downloads.", bundle: .main, comment: "Subtitle for the procedural noise tab.")
        static let volume = LocalizedStringResource("noise.volume", defaultValue: "Noise volume", bundle: .main, comment: "Accessibility label for procedural noise volume sliders.")
        static let sleepBlendTitle = LocalizedStringResource("noise.blend.sleep.title", defaultValue: "Sleep mask", bundle: .main, comment: "One-tap Noise Lab blend for sleep masking.")
        static let sleepBlendSubtitle = LocalizedStringResource("noise.blend.sleep.subtitle", defaultValue: "Warm room cover", bundle: .main, comment: "Subtitle for the sleep noise blend.")
        static let focusBlendTitle = LocalizedStringResource("noise.blend.focus.title", defaultValue: "Focus floor", bundle: .main, comment: "One-tap Noise Lab blend for focus.")
        static let focusBlendSubtitle = LocalizedStringResource("noise.blend.focus.subtitle", defaultValue: "Steady edge softener", bundle: .main, comment: "Subtitle for the focus noise blend.")
        static let travelBlendTitle = LocalizedStringResource("noise.blend.travel.title", defaultValue: "Travel hush", bundle: .main, comment: "One-tap Noise Lab blend for travel masking.")
        static let travelBlendSubtitle = LocalizedStringResource("noise.blend.travel.subtitle", defaultValue: "Cabin-like cover", bundle: .main, comment: "Subtitle for the travel noise blend.")
        static let white = LocalizedStringResource("noise.white", defaultValue: "White", bundle: .main, comment: "White noise title.")
        static let brown = LocalizedStringResource("noise.brown", defaultValue: "Brown", bundle: .main, comment: "Brown noise title.")
        static let pink = LocalizedStringResource("noise.pink", defaultValue: "Pink", bundle: .main, comment: "Pink noise title.")
        static let green = LocalizedStringResource("noise.green", defaultValue: "Green", bundle: .main, comment: "Green noise title.")
        static let fan = LocalizedStringResource("noise.fan", defaultValue: "Fan", bundle: .main, comment: "Fan noise title.")
        static let aircraft = LocalizedStringResource("noise.aircraft", defaultValue: "Aircraft", bundle: .main, comment: "Aircraft cabin noise title.")
        static let whiteSubtitle = LocalizedStringResource("noise.white.subtitle", defaultValue: "Bright full-spectrum masking", bundle: .main, comment: "White noise subtitle.")
        static let brownSubtitle = LocalizedStringResource("noise.brown.subtitle", defaultValue: "Warm low-end room cover", bundle: .main, comment: "Brown noise subtitle.")
        static let pinkSubtitle = LocalizedStringResource("noise.pink.subtitle", defaultValue: "Balanced rain-like texture", bundle: .main, comment: "Pink noise subtitle.")
        static let greenSubtitle = LocalizedStringResource("noise.green.subtitle", defaultValue: "Mid-band focus softness", bundle: .main, comment: "Green noise subtitle.")
        static let fanSubtitle = LocalizedStringResource("noise.fan.subtitle", defaultValue: "Mechanical room hush", bundle: .main, comment: "Fan noise subtitle.")
        static let aircraftSubtitle = LocalizedStringResource("noise.aircraft.subtitle", defaultValue: "Cabin rumble for travel", bundle: .main, comment: "Aircraft cabin noise subtitle.")
    }

    enum Presets {
        static let defaultStarter = LocalizedStringResource(
            "presets.default.starter",
            defaultValue: "Sea Breeze",
            bundle: .main,
            comment: "Name of the first default ambience."
        )

        static let defaultCalm = LocalizedStringResource(
            "presets.default.calm",
            defaultValue: "Quiet Forest",
            bundle: .main,
            comment: "Name of the second default ambience."
        )

        static let defaultStorm = LocalizedStringResource(
            "presets.default.storm",
            defaultValue: "Distant Storm",
            bundle: .main,
            comment: "Name of the third default ambience."
        )

        static let afterTheRain = LocalizedStringResource(
            "presets.default.afterRain",
            defaultValue: "After the Rain",
            bundle: .main,
            comment: "Public name of the featured preview ambience that keeps the preset_signature_oasis internal identifier."
        )

        static let panelTitle = LocalizedStringResource(
            "presets.panel.title",
            defaultValue: "Mixes",
            bundle: .main,
            comment: "Short title of the presets panel and inactive presets chip."
        )

        static let panelSubtitle = LocalizedStringResource(
            "presets.panel.subtitle",
            defaultValue: "Open a saved mix or save the one you're shaping now.",
            bundle: .main,
            comment: "Subtitle in the presets panel explaining that the user can reopen or save mixes."
        )

        static let namePrompt = LocalizedStringResource(
            "presets.name.prompt",
            defaultValue: "Name this mix",
            bundle: .main,
            comment: "Placeholder in the text field used to save a new mix."
        )

        static let close = LocalizedStringResource(
            "presets.close",
            defaultValue: "Close",
            bundle: .main,
            comment: "Accessibility label for the presets full-screen panel close button."
        )

        static let saveSectionTitle = LocalizedStringResource(
            "presets.save.section.title",
            defaultValue: "Save this ambience",
            bundle: .main,
            comment: "Title of the popup used to save the current ambient scene as a preset."
        )

        static let saveSectionSubtitle = LocalizedStringResource(
            "presets.save.section.subtitle",
            defaultValue: "Name the ambience you're shaping now.",
            bundle: .main,
            comment: "Short helper text above the controls used to save the current ambient mix as a preset."
        )

        static let saveAction = LocalizedStringResource(
            "presets.save.action",
            defaultValue: "Save",
            bundle: .main,
            comment: "Button label that saves the current ambient mix as a preset."
        )

        static let listSectionTitle = LocalizedStringResource(
            "presets.list.section.title",
            defaultValue: "Saved mixes",
            bundle: .main,
            comment: "Section title above the list of available presets."
        )

        static let manage = LocalizedStringResource(
            "presets.manage",
            defaultValue: "Manage",
            bundle: .main,
            comment: "Button title that reveals preset reorder and delete controls."
        )

        static let doneManaging = LocalizedStringResource(
            "presets.manage.done",
            defaultValue: "Done",
            bundle: .main,
            comment: "Button title that hides preset reorder and delete controls."
        )

        static let statusActive = LocalizedStringResource(
            "presets.status.active",
            defaultValue: "Active",
            bundle: .main,
            comment: "Small status badge for the preset currently loaded in the mixer."
        )

        static let statusSaved = LocalizedStringResource(
            "presets.status.saved",
            defaultValue: "Saved",
            bundle: .main,
            comment: "Small status badge for user-created presets."
        )

        static let statusOasis = LocalizedStringResource(
            "presets.status.oasis",
            defaultValue: "Oasis",
            bundle: .main,
            comment: "Small status badge for built-in Oasis presets."
        )

        static let deleteAction = LocalizedStringResource(
            "presets.delete.action",
            defaultValue: "Delete",
            bundle: .main,
            comment: "Accessibility label for the preset delete button."
        )

        static let reorderAction = LocalizedStringResource(
            "presets.reorder.action",
            defaultValue: "Reorder",
            bundle: .main,
            comment: "Accessibility label for the preset reorder handle."
        )

        static let showSave = LocalizedStringResource(
            "presets.save.show",
            defaultValue: "Save this ambience",
            bundle: .main,
            comment: "Button title that opens the preset save popup."
        )

        static let nameFieldAccessibility = LocalizedStringResource(
            "presets.name.accessibility",
            defaultValue: "Mix name",
            bundle: .main,
            comment: "Accessibility label for the text field used to name a saved mix."
        )

        static let confirmDeleteTitle = LocalizedStringResource(
            "presets.delete.confirm.title",
            defaultValue: "Delete this mix?",
            bundle: .main,
            comment: "Confirmation dialog title shown before deleting a saved mix."
        )

        static let confirmDeleteMessage = LocalizedStringResource(
            "presets.delete.confirm.message",
            defaultValue: "This saved mix will be removed from Oasis.",
            bundle: .main,
            comment: "Confirmation dialog message shown before deleting a saved mix."
        )

        static let cancel = LocalizedStringResource(
            "presets.cancel",
            defaultValue: "Cancel",
            bundle: .main,
            comment: "Generic cancel action used in the presets panel."
        )
    }

    enum Paywall {
        static let titleGeneric = LocalizedStringResource(
            "paywall.title.generic",
            defaultValue: "Unlock Premium",
            bundle: .main,
            comment: "Generic paywall title when no specific premium entry point needs to be highlighted."
        )

        static let titleSounds = LocalizedStringResource(
            "paywall.title.sounds",
            defaultValue: "Unlock 32 more sounds",
            bundle: .main,
            comment: "Paywall title when triggered from a locked sound or spatial control."
        )

        static let titleTimer = LocalizedStringResource(
            "paywall.title.timer",
            defaultValue: "1 hr and 2 hr timers",
            bundle: .main,
            comment: "Paywall title when the user wants the premium timer."
        )

        static let titlePresets = LocalizedStringResource(
            "paywall.title.presets",
            defaultValue: "Keep more mixes",
            bundle: .main,
            comment: "Paywall title when the user wants premium preset features."
        )

        static let titleBinaural = LocalizedStringResource(
            "paywall.title.binaural",
            defaultValue: "Binaural modes",
            bundle: .main,
            comment: "Paywall title when the user taps a locked binaural mode."
        )

        static let titlePreview = LocalizedStringResource(
            "paywall.title.preview",
            defaultValue: "Unlock this mix",
            bundle: .main,
            comment: "Paywall title shown after the featured ambience preview has ended."
        )

        static let titleComposer = LocalizedStringResource(
            "paywall.title.composer",
            defaultValue: "Unlock the full composer",
            bundle: .main,
            comment: "Paywall title when the user taps premium composer, ritual, or noise features."
        )

        static let subtitleGeneric = LocalizedStringResource(
            "paywall.subtitle.generic",
            defaultValue: "Unlock 32 more sounds, 1 hr/2 hr timers and unlimited saved mixes. One purchase, no subscription.",
            bundle: .main,
            comment: "Generic paywall subtitle summarizing the full premium offer."
        )

        static let subtitleSounds = LocalizedStringResource(
            "paywall.subtitle.sounds",
            defaultValue: "Add rain, forest, thunder, river, sea and more sounds for sleep or focus.",
            bundle: .main,
            comment: "Paywall subtitle when the user wants more ambient sounds."
        )

        static let subtitleTimer = LocalizedStringResource(
            "paywall.subtitle.timer",
            defaultValue: "Let the audio stop after 1 hr or 2 hr, without playing all night.",
            bundle: .main,
            comment: "Paywall subtitle when the user wants to use the timer."
        )

        static let subtitlePresets = LocalizedStringResource(
            "paywall.subtitle.presets",
            defaultValue: "Save your favorite mixes and bring them back in one tap.",
            bundle: .main,
            comment: "Paywall subtitle when the user wants to save or reload mixes."
        )

        static let subtitleBinaural = LocalizedStringResource(
            "paywall.subtitle.binaural",
            defaultValue: "Theta, Alpha and Beta for relaxation, meditation and focus.",
            bundle: .main,
            comment: "Paywall subtitle when the user wants locked binaural modes."
        )

        static let subtitlePreview = LocalizedStringResource(
            "paywall.subtitle.preview",
            defaultValue: "Unlock Premium to come back to this mix anytime.",
            bundle: .main,
            comment: "Paywall subtitle shown after the featured ambience preview has finished."
        )

        static let subtitleComposer = LocalizedStringResource(
            "paywall.subtitle.composer",
            defaultValue: "Create richer soundscapes with premium sounds, rituals, focus modes and procedural noise layers.",
            bundle: .main,
            comment: "Paywall subtitle for premium composer and procedural noise features."
        )

        static let benefitSounds = LocalizedStringResource(
            "paywall.benefit.sounds",
            defaultValue: "11 extra sounds: rain, forest, thunder, river...",
            bundle: .main,
            comment: "First premium benefit row about the extra ambient library."
        )

        static let benefitPresets = LocalizedStringResource(
            "paywall.benefit.presets",
            defaultValue: "Unlimited saved mixes",
            bundle: .main,
            comment: "Premium benefit row about saved mixes."
        )

        static let benefitTimer = LocalizedStringResource(
            "paywall.benefit.timer",
            defaultValue: "1 hr and 2 hr timers",
            bundle: .main,
            comment: "Premium benefit row about the timer."
        )

        static let benefitBinaural = LocalizedStringResource(
            "paywall.benefit.binaural",
            defaultValue: "Delta, Theta, Alpha and Beta",
            bundle: .main,
            comment: "Premium benefit row about the binaural modes."
        )

        static let benefitUpdates = LocalizedStringResource(
            "paywall.benefit.updates",
            defaultValue: "Free updates",
            bundle: .main,
            comment: "Premium benefit row stating that future updates are free."
        )

        static let benefitComposer = LocalizedStringResource(
            "paywall.benefit.composer",
            defaultValue: "Composer recipes for sleep, travel, reading and focus",
            bundle: .main,
            comment: "Premium benefit row for the ambience composer."
        )

        static let benefitNoiseLab = LocalizedStringResource(
            "paywall.benefit.noiseLab",
            defaultValue: "Procedural noise layers for masking and deep work",
            bundle: .main,
            comment: "Premium benefit row for the procedural noise lab."
        )

        static let noSubscription = LocalizedStringResource(
            "paywall.trust.noSubscription",
            defaultValue: "One purchase. Lifetime access. No subscription.",
            bundle: .main,
            comment: "Trust line below the paywall benefits clarifying that premium is a one-time purchase."
        )

        static let primaryTitle = LocalizedStringResource(
            "paywall.cta.title",
            defaultValue: "Unlock for life",
            bundle: .main,
            comment: "Main paywall call to action above the localized price."
        )

        static let loading = LocalizedStringResource(
            "paywall.state.loading",
            defaultValue: "Loading price...",
            bundle: .main,
            comment: "Paywall loading state while RevenueCat offerings are fetched."
        )

        static let retry = LocalizedStringResource(
            "paywall.state.retry",
            defaultValue: "Try again",
            bundle: .main,
            comment: "Retry button shown when the paywall fails to load."
        )

        static let unavailable = LocalizedStringResource(
            "paywall.state.unavailable",
            defaultValue: "Purchase is temporarily unavailable.",
            bundle: .main,
            comment: "Error message shown when the paywall has no available product."
        )

        static let restore = LocalizedStringResource(
            "paywall.footer.restore",
            defaultValue: "Restore",
            bundle: .main,
            comment: "Paywall footer button that restores previous purchases."
        )

        static let restoring = LocalizedStringResource(
            "paywall.footer.restoring",
            defaultValue: "Restoring...",
            bundle: .main,
            comment: "Temporary paywall footer label shown while purchases are being restored."
        )

        static let support = LocalizedStringResource(
            "paywall.footer.support",
            defaultValue: "Support",
            bundle: .main,
            comment: "Paywall footer button that opens the support URL."
        )

        static let dailyPrice = LocalizedStringResource(
            "paywall.anchor.dailyPrice",
            defaultValue: "The price of a coffee in Paris",
            bundle: .main,
            comment: "Price-anchoring tagline shown below the CTA. Uses a coffee-price metaphor (Paris kept across all locales — only the city name is grammatically adapted, e.g. 'Parigi' in IT, 'París' in ES) instead of an explicit per-day cost."
        )
    }

    enum Premium {
        static let bannerTitle = LocalizedStringResource(
            "premium.banner.title",
            defaultValue: "Need rain or thunder?",
            bundle: .main,
            comment: "Title of the subtle premium banner shown on the home screen."
        )

        static let bannerSubtitle = LocalizedStringResource(
            "premium.banner.subtitle",
            defaultValue: "Unlock 32 more sounds, 1 hr/2 hr timers and unlimited saved mixes.",
            bundle: .main,
            comment: "Short explanatory line in the premium home banner."
        )

        static let bannerCTA = LocalizedStringResource(
            "premium.banner.cta",
            defaultValue: "See Premium",
            bundle: .main,
            comment: "Call to action in the premium home banner."
        )

        static let libraryTitle = LocalizedStringResource(
            "premium.library.title",
            defaultValue: "32 more sounds",
            bundle: .main,
            comment: "Title of the home teaser card for the locked sound library."
        )

        static let libraryBadgeSuffix = LocalizedStringResource(
            "premium.library.badgeSuffix",
            defaultValue: "available",
            bundle: .main,
            comment: "Suffix used after the locked sound count in the home teaser badge, for example '11 more sounds'."
        )

        static let librarySubtitle = LocalizedStringResource(
            "premium.library.subtitle",
            defaultValue: "Rain, forest, thunder, river and sea, all available offline.",
            bundle: .main,
            comment: "Body copy in the locked sound library teaser."
        )

        static let libraryCTA = LocalizedStringResource(
            "premium.library.cta",
            defaultValue: "See Premium",
            bundle: .main,
            comment: "Primary action of the locked sound library teaser."
        )

        static let libraryExpand = LocalizedStringResource(
            "premium.library.expand",
            defaultValue: "Show list",
            bundle: .main,
            comment: "Secondary action that expands the locked sound list in the home teaser."
        )

        static let libraryCollapse = LocalizedStringResource(
            "premium.library.collapse",
            defaultValue: "Hide list",
            bundle: .main,
            comment: "Secondary action that collapses the locked sound list in the home teaser."
        )

        static let inlinePresetTitle = LocalizedStringResource(
            "premium.inline.preset.title",
            defaultValue: "Keep more mixes",
            bundle: .main,
            comment: "Inline upsell title shown in the presets panel."
        )

        static let inlinePresetSubtitle = LocalizedStringResource(
            "premium.inline.preset.subtitle",
            defaultValue: "The first one is free. Premium lets you save as many mixes as you want.",
            bundle: .main,
            comment: "Inline upsell message shown when the user wants premium preset features."
        )

        static let inlineBinauralTitle = LocalizedStringResource(
            "premium.inline.binaural.title",
            defaultValue: "More binaural modes",
            bundle: .main,
            comment: "Inline upsell title shown in the binaural panel."
        )

        static let inlineBinauralSubtitle = LocalizedStringResource(
            "premium.inline.binaural.subtitle",
            defaultValue: "Theta, Alpha and Beta for relaxation, meditation and focus.",
            bundle: .main,
            comment: "Inline upsell message shown when the user taps a locked binaural mode."
        )

        static let inlineUnlock = LocalizedStringResource(
            "premium.inline.unlock",
            defaultValue: "See Premium",
            bundle: .main,
            comment: "Primary call to action on inline premium cards."
        )

        static let inlineNotNow = LocalizedStringResource(
            "premium.inline.notNow",
            defaultValue: "Not now",
            bundle: .main,
            comment: "Dismissive secondary action on inline premium cards."
        )

        static let previewCTA = LocalizedStringResource(
            "premium.preview.cta",
            defaultValue: "Try a Premium mix",
            bundle: .main,
            comment: "Secondary inline upsell action that launches the featured ambience preview."
        )

        static let previewPlaying = LocalizedStringResource(
            "premium.preview.playing",
            defaultValue: "Preview playing",
            bundle: .main,
            comment: "Small status line shown while the featured ambience preview is playing."
        )

        static let previewLimit = LocalizedStringResource(
            "premium.preview.limit",
            defaultValue: "A new preview will be available next week.",
            bundle: .main,
            comment: "Footnote shown when the weekly ambience preview has already been used."
        )

        static let timerTitle = LocalizedStringResource(
            "premium.timer.title",
            defaultValue: "Longer timers",
            bundle: .main,
            comment: "Title of the timer unlock panel shown to free users."
        )

        static let timerSubtitle = LocalizedStringResource(
            "premium.timer.subtitle",
            defaultValue: "15 and 30 min are free. Premium adds 1 hr and 2 hr.",
            bundle: .main,
            comment: "Subtitle of the timer unlock panel shown to free users."
        )

        static let timerIncluded = LocalizedStringResource(
            "premium.timer.included",
            defaultValue: "One purchase, no subscription",
            bundle: .main,
            comment: "Small caption under the locked timer durations."
        )
    }

    enum Binaural {
        static let title = LocalizedStringResource(
            "binaural.title",
            defaultValue: "Binaural modes",
            bundle: .main,
            comment: "Title of the binaural panel."
        )

        static let headphonesHint = LocalizedStringResource(
            "binaural.headphones",
            defaultValue: "Headphones are recommended for the best effect.",
            bundle: .main,
            comment: "Helper line in the binaural panel encouraging headphone use."
        )

        static let deltaTitle = LocalizedStringResource(
            "binaural.delta.title",
            defaultValue: "Delta",
            bundle: .main,
            comment: "Name of the free delta binaural mode."
        )

        static let deltaFrequency = LocalizedStringResource(
            "binaural.delta.frequency",
            defaultValue: "Deep sleep • 4 Hz",
            bundle: .main,
            comment: "Short descriptive label for the delta binaural mode."
        )

        static let thetaTitle = LocalizedStringResource(
            "binaural.theta.title",
            defaultValue: "Theta",
            bundle: .main,
            comment: "Name of the theta binaural mode."
        )

        static let thetaFrequency = LocalizedStringResource(
            "binaural.theta.frequency",
            defaultValue: "Meditation • 6 Hz",
            bundle: .main,
            comment: "Short descriptive label for the theta binaural mode."
        )

        static let alphaTitle = LocalizedStringResource(
            "binaural.alpha.title",
            defaultValue: "Alpha",
            bundle: .main,
            comment: "Name of the alpha binaural mode."
        )

        static let alphaFrequency = LocalizedStringResource(
            "binaural.alpha.frequency",
            defaultValue: "Relaxation • 10 Hz",
            bundle: .main,
            comment: "Short descriptive label for the alpha binaural mode."
        )

        static let betaTitle = LocalizedStringResource(
            "binaural.beta.title",
            defaultValue: "Beta",
            bundle: .main,
            comment: "Name of the beta binaural mode."
        )

        static let betaFrequency = LocalizedStringResource(
            "binaural.beta.frequency",
            defaultValue: "Focus • 18 Hz",
            bundle: .main,
            comment: "Short descriptive label for the beta binaural mode."
        )

        static let volume = LocalizedStringResource(
            "binaural.volume",
            defaultValue: "Binaural volume",
            bundle: .main,
            comment: "Accessibility label for the binaural volume slider."
        )

        static let enabled = LocalizedStringResource(
            "binaural.enabled",
            defaultValue: "Binaural sound on",
            bundle: .main,
            comment: "Accessibility value when binaural playback is enabled."
        )

        static let disabled = LocalizedStringResource(
            "binaural.disabled",
            defaultValue: "Binaural sound off",
            bundle: .main,
            comment: "Accessibility value when binaural playback is disabled."
        )
    }

    enum Spatial {
        static let subtitle = LocalizedStringResource(
            "spatial.subtitle",
            defaultValue: "Place this sound around you.",
            bundle: .main,
            comment: "Subtitle in the spatial positioning panel."
        )

        static let front = LocalizedStringResource(
            "spatial.front",
            defaultValue: "Front",
            bundle: .main,
            comment: "Top label in the spatial positioning panel."
        )

        static let back = LocalizedStringResource(
            "spatial.back",
            defaultValue: "Back",
            bundle: .main,
            comment: "Bottom label in the spatial positioning panel."
        )

        static let left = LocalizedStringResource(
            "spatial.left",
            defaultValue: "Left",
            bundle: .main,
            comment: "Left label in the spatial positioning panel."
        )

        static let right = LocalizedStringResource(
            "spatial.right",
            defaultValue: "Right",
            bundle: .main,
            comment: "Right label in the spatial positioning panel."
        )

        static let center = LocalizedStringResource(
            "spatial.center",
            defaultValue: "Center",
            bundle: .main,
            comment: "Center preset button in the spatial positioning panel."
        )

        static let stageAccessibility = LocalizedStringResource(
            "spatial.stage.accessibility",
            defaultValue: "Sound placement area",
            bundle: .main,
            comment: "Accessibility label for the draggable spatial placement area."
        )

        static let stageHint = LocalizedStringResource(
            "spatial.stage.hint",
            defaultValue: "Drag in the area or use the placement buttons below.",
            bundle: .main,
            comment: "Accessibility hint for the spatial placement area."
        )

        static let positionCentered = LocalizedStringResource(
            "spatial.position.centered",
            defaultValue: "Centered",
            bundle: .main,
            comment: "Accessibility value when a sound is centered in the spatial panel."
        )
    }

    enum Onboarding {
        static let page1Title = LocalizedStringResource(
            "onboarding.page1.title",
            defaultValue: "Escape into real nature",
            bundle: .main,
            comment: "Onboarding page 1 title."
        )

        static let page1Subtitle = LocalizedStringResource(
            "onboarding.page1.subtitle",
            defaultValue: "Build a place around you with field recordings you can mix by hand.",
            bundle: .main,
            comment: "Onboarding page 1 subtitle."
        )

        static let page2Title = LocalizedStringResource(
            "onboarding.page2.title",
            defaultValue: "Offline, even locked",
            bundle: .main,
            comment: "Onboarding page 2 title."
        )

        static let page2Subtitle = LocalizedStringResource(
            "onboarding.page2.subtitle",
            defaultValue: "Start a sleep timer, lock your phone, and let Oasis fade out in the background.",
            bundle: .main,
            comment: "Onboarding page 2 subtitle."
        )

        static let page3Title = LocalizedStringResource(
            "onboarding.page3.title",
            defaultValue: "Start free, own it for life",
            bundle: .main,
            comment: "Onboarding page 3 title."
        )

        static let page3Subtitle = LocalizedStringResource(
            "onboarding.page3.subtitle",
            defaultValue: "Try 3 sounds, Delta waves and timers. Unlock the full library once — no subscription.",
            bundle: .main,
            comment: "Onboarding page 3 subtitle."
        )

        static let ctaStart = LocalizedStringResource(
            "onboarding.cta.start",
            defaultValue: "Unlock for life",
            bundle: .main,
            comment: "Primary onboarding final page CTA that opens the lifetime purchase paywall."
        )

        static let ctaStartFree = LocalizedStringResource(
            "onboarding.cta.startFree",
            defaultValue: "Start free",
            bundle: .main,
            comment: "Secondary onboarding final page CTA that enters the free tier without opening the paywall."
        )

        static let ctaNext = LocalizedStringResource(
            "onboarding.cta.next",
            defaultValue: "Next",
            bundle: .main,
            comment: "Onboarding next page button."
        )

        static let ctaSkip = LocalizedStringResource(
            "onboarding.cta.skip",
            defaultValue: "Skip",
            bundle: .main,
            comment: "Onboarding skip button."
        )
    }

    enum GentleReminder {
        static let title = LocalizedStringResource(
            "notifications.gentleReminder.title",
            defaultValue: "Oasis",
            bundle: .main,
            comment: "Title of the gentle local notification that invites inactive users back to the app."
        )

        static let body = LocalizedStringResource(
            "notifications.gentleReminder.body",
            defaultValue: "Escape for a few minutes. You need it.",
            bundle: .main,
            comment: "Body of the gentle local notification scheduled after several days without reopening the app."
        )
    }

    enum Mixer {
        static let statusPremium = LocalizedStringResource(
            "mixer.status.premium",
            defaultValue: "PREMIUM",
            bundle: .main,
            comment: "Small uppercase status label shown on locked premium rows."
        )

        static let statusMuted = LocalizedStringResource(
            "mixer.status.muted",
            defaultValue: "MUTED",
            bundle: .main,
            comment: "Small uppercase status label shown on muted sound rows."
        )

        static let statusAuto = LocalizedStringResource(
            "mixer.status.auto",
            defaultValue: "AUTO",
            bundle: .main,
            comment: "Small uppercase status label shown when automatic variation is enabled."
        )

        static let soundOn = LocalizedStringResource(
            "mixer.accessibility.soundOn",
            defaultValue: "Sound on",
            bundle: .main,
            comment: "Accessibility value for an active sound row control."
        )

        static let soundOff = LocalizedStringResource(
            "mixer.accessibility.soundOff",
            defaultValue: "Sound off",
            bundle: .main,
            comment: "Accessibility value for a muted sound row control."
        )

        static let locked = LocalizedStringResource(
            "mixer.accessibility.locked",
            defaultValue: "Locked",
            bundle: .main,
            comment: "Accessibility value for a locked premium sound."
        )

        static let toggleSoundHint = LocalizedStringResource(
            "mixer.accessibility.toggleSoundHint",
            defaultValue: "Turns this sound on or off.",
            bundle: .main,
            comment: "Accessibility hint for the per-sound mute/play button."
        )

        static let soundDetailsHint = LocalizedStringResource(
            "mixer.accessibility.soundDetailsHint",
            defaultValue: "Opens details about this sound.",
            bundle: .main,
            comment: "Accessibility hint for opening the sound detail sheet from a mixer row."
        )

        static let volume = LocalizedStringResource(
            "mixer.accessibility.volume",
            defaultValue: "Volume",
            bundle: .main,
            comment: "Accessibility label for a per-sound volume slider."
        )

        static let autoRange = LocalizedStringResource(
            "mixer.accessibility.autoRange",
            defaultValue: "Automatic volume range",
            bundle: .main,
            comment: "Accessibility label for a per-sound automatic volume range slider."
        )

        static let autoRangeHint = LocalizedStringResource(
            "mixer.accessibility.autoRangeHint",
            defaultValue: "Use the available actions to adjust the automatic volume interval.",
            bundle: .main,
            comment: "Accessibility hint for the automatic volume range slider."
        )

        static let increaseMinimum = LocalizedStringResource(
            "mixer.accessibility.increaseMinimum",
            defaultValue: "Increase minimum volume",
            bundle: .main,
            comment: "Accessibility custom action for increasing the lower bound of the automatic volume range."
        )

        static let decreaseMinimum = LocalizedStringResource(
            "mixer.accessibility.decreaseMinimum",
            defaultValue: "Decrease minimum volume",
            bundle: .main,
            comment: "Accessibility custom action for decreasing the lower bound of the automatic volume range."
        )

        static let increaseMaximum = LocalizedStringResource(
            "mixer.accessibility.increaseMaximum",
            defaultValue: "Increase maximum volume",
            bundle: .main,
            comment: "Accessibility custom action for increasing the upper bound of the automatic volume range."
        )

        static let decreaseMaximum = LocalizedStringResource(
            "mixer.accessibility.decreaseMaximum",
            defaultValue: "Decrease maximum volume",
            bundle: .main,
            comment: "Accessibility custom action for decreasing the upper bound of the automatic volume range."
        )

        static let soundPlacement = LocalizedStringResource(
            "mixer.accessibility.soundPlacement",
            defaultValue: "Sound placement",
            bundle: .main,
            comment: "Accessibility label for the per-sound spatial placement button."
        )

        static let soundPlacementHint = LocalizedStringResource(
            "mixer.accessibility.soundPlacementHint",
            defaultValue: "Opens placement controls for this sound.",
            bundle: .main,
            comment: "Accessibility hint for the per-sound spatial placement button."
        )

        static let autoVariation = LocalizedStringResource(
            "mixer.accessibility.autoVariation",
            defaultValue: "Automatic variation",
            bundle: .main,
            comment: "Accessibility label for the per-sound automatic variation button."
        )

        static let enabled = LocalizedStringResource(
            "mixer.accessibility.enabled",
            defaultValue: "On",
            bundle: .main,
            comment: "Generic accessibility value for enabled controls."
        )

        static let disabled = LocalizedStringResource(
            "mixer.accessibility.disabled",
            defaultValue: "Off",
            bundle: .main,
            comment: "Generic accessibility value for disabled controls."
        )
    }

    enum Timer {
        static let option15 = LocalizedStringResource(
            "timer.option.15",
            defaultValue: "15 min",
            bundle: .main,
            comment: "15 minute duration label in timer controls."
        )

        static let option30 = LocalizedStringResource(
            "timer.option.30",
            defaultValue: "30 min",
            bundle: .main,
            comment: "30 minute duration label in timer controls."
        )

        static let option60 = LocalizedStringResource(
            "timer.option.60",
            defaultValue: "1 hr",
            bundle: .main,
            comment: "1 hour duration label in timer controls."
        )

        static let option120 = LocalizedStringResource(
            "timer.option.120",
            defaultValue: "2 hr",
            bundle: .main,
            comment: "2 hour duration label in timer controls."
        )
    }
}

// `SoundChannel` localized names are defined alongside the rest of the per-channel metadata in
// `SoundChannelMetadata.swift`.

extension BinauralTrack {
    var localizedTitle: String {
        switch self {
        case .delta:
            return L10n.string(L10n.Binaural.deltaTitle)
        case .theta:
            return L10n.string(L10n.Binaural.thetaTitle)
        case .alpha:
            return L10n.string(L10n.Binaural.alphaTitle)
        case .beta:
            return L10n.string(L10n.Binaural.betaTitle)
        }
    }

    var localizedFrequencyLabel: String {
        switch self {
        case .delta:
            return L10n.string(L10n.Binaural.deltaFrequency)
        case .theta:
            return L10n.string(L10n.Binaural.thetaFrequency)
        case .alpha:
            return L10n.string(L10n.Binaural.alphaFrequency)
        case .beta:
            return L10n.string(L10n.Binaural.betaFrequency)
        }
    }
}
