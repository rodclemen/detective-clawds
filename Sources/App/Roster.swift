import Foundation

// The DC cast: 110 heroes and 97 villains. Any of them can lead a session (drawn large) or be an agent (small).
// Who they are, how they fight and how they move is a `Persona`, registered in one of the Art/*.swift files next to
// its drawing code; who lives where, who fights whom first and who gets picked up is decided here.
//
// Ids are stored in the status file: villains are `Leader.rawValue` (< 100), heroes 100 + `Companion.rawValue`.
// Only ever append cases, so running sessions keep their characters across an update.

enum Companion: Int, CaseIterable {
    // The Justice League
    case superman, batman, wonderWoman, flash, greenLantern, aquaman, cyborg, martianManhunter, greenArrow, blackCanary
    case shazam
    // The Bat-family and Gotham
    case robin, nightwing, batgirl, redHood, redRobin, catwoman, huntress, batwoman, orphan, spoiler
    case commissionerGordon
    // The Super-family and Metropolis
    case supergirl, superboy, powerGirl, steel, jonKent, loisLane, jimmyOlsen, alfred, luciusFox, krypto
    // The Green Lantern Corps and the Thanagarians
    case johnStewart, guyGardner, kyleRayner, jessicaCruz, simonBaz, kilowog, tomarRe, chP, adamStrange, hawkman
    case hawkgirl
    // Speedsters and the Teen Titans
    case wallyWest, jayGarrick, impulse, jesseQuick, raven, beastBoy, starfire, wonderGirl, aqualad, arsenal
    // The Justice Society
    case alanScott, doctorFate, hourman, stargirl, wildcat, atomSmasher, cyclone, doctorMidnite, sandman, mrTerrific
    // Justice League Dark
    case zatanna, constantine, swampThing, deadman, spectre, etrigan, madameXanadu, phantomStranger, ragman, dream
    // Justice League International and friends
    case blueBeetle, boosterGold, theAtom, firestorm, plasticMan, elongatedMan, vixen, blackLightning, theQuestion, metamorpho
    case redTornado, captainAtom
    // Amazons, Atlanteans, New Gods and more
    case mera, artemis, donnaTroy, nubia, hippolyta, steveTrevor, mrMiracle, bigBarda, orion, animalMan
    case katana
    // The Suicide Squad, the Legion, the Wonder Twins and the pets
    case peacemaker, bloodsport, ratcatcher2, kingShark, polkaDotMan, saturnGirl, cosmicBoy, lightningLad, zan, jayna
    case aceTheBatHound, streaky, gleek, beppo

    var persona: Persona { heroPersonas[self] ?? Persona.missing(String(describing: self)) }
    var name: String { persona.name }
    var weapon: Weapon { persona.weapon }
    var headTop: Int { persona.headTop }
    var canSit: Bool { persona.canSit }
    var muzzle: (x: Double, y: Double) { persona.muzzle }
}

enum Leader: Int, CaseIterable {
    // Batman's rogues
    case joker, harleyQuinn, penguin, riddler, twoFace, scarecrow, poisonIvy, mrFreeze, bane, killerCroc
    case rasAlGhul
    // More of Gotham's worst
    case talia, deathstroke, madHatter, clayface, hush, zsasz, firefly, manBat, ventriloquist, talon
    case calendarMan, jokerGoon
    // Superman's rogues
    case lexLuthor, generalZod, ursa, brainiac, doomsday, bizarro, metallo, parasite, toyman, mrMxyzptlk
    case livewire
    // Apokolips and the cosmic tyrants
    case darkseid, steppenwolf, desaad, grannyGoodness, kalibak, parademon, lobo, mongul, trigon, antiMonitor
    // The other Corps, androids and alien conquerors
    case sinestro, atrocitus, larfleeze, parallax, manhunter, dexStarr, amazo, starro, despero, eclipso
    // The Flash's Rogues and the evil speedsters
    case reverseFlash, zoom, captainCold, heatWave, mirrorMaster, gorillaGrodd, weatherWizard, captainBoomerang, trickster, savitar
    case goldenGlider
    // Wonder Woman's and Aquaman's foes
    case cheetah, ares, circe, maxwellLord, doctorPoison, giganta, silverSwan, blackManta, oceanMaster, trench
    // Shazam, the Titans, the JSA and the Legion of Doom
    case blackAdam, doctorSivana, mrMind, brotherBlood, solomonGrundy, vandalSavage, felixFaust, klarion, monsieurMallah, gentlemanGhost
    case blackMask
    // The Squad, the assassins and the ring-wielders
    case deadshot, killerFrost, amandaWaller, enchantress, copperhead, cheshire, blackHand, cyborgSuperman, leagueAssassin, kobraAgent
    case starSapphire

    var persona: Persona { villainPersonas[self] ?? Persona.missing(String(describing: self)) }
    var name: String { persona.name }
    var weapon: Weapon { persona.weapon }
    var headTop: Int { persona.headTop }
    var canSit: Bool { persona.canSit }
    var armoured: Bool { persona.armoured }
    var weaponPivot: (x: Double, y: Double) { persona.pivot }
    var muzzle: (x: Int, y: Int) { (Int(persona.muzzle.x), Int(persona.muzzle.y)) }

    init(index: Int) { self = Leader(rawValue: index % Leader.allCases.count) ?? .joker }
}

// MARK: - Personas

/// How a character fights:
/// - `melee`: up close, fists, swords, staffs, maces, tridents, bo staffs. Deflects shots, blocks magic.
/// - `ranged`: at range, heat vision, arrows, bullets, cold guns, fire, batarangs… (`Persona.shot` says which).
/// - `lightning`: magic and energy streams, sorcery, telepathy, power rings (`Persona.magic` says how it looks).
/// - `none`: stays out of it.
enum Weapon { case melee, ranged, magic, none }

/// How a character gets about when it moves along the line.
enum Motion {
    case walk
    case fly       // takes off to travel and lands where it's going (Superman, Wonder Woman, the Lanterns…)
    case hover     // never quite touches the ground (Doctor Fate, Raven, Brainiac…)
    case swing     // swings on a grapnel line (Batman, Nightwing, Batgirl)
}

/// What a ranged character's shots look like.
enum ShotStyle {
    case energy(core: Px, glow: Px)   // a glowing streak: ring blasts, starbolts, ray guns
    case beam(core: Px, glow: Px)     // a continuous ray from the muzzle: heat vision, Omega Beams
    case bullet                       // a small hot tracer
    case arrow                        // a feathered arrow
    case fire                         // a fireball
    case ice                          // a frosty stream
    case thrown(Px)                   // something spinning: boomerangs, batarangs, toys
}

/// What a magic or energy stream looks like.
struct Magic {
    var core: Px
    var glow: Px
    var jagged = true                 // forked like lightning; false: a steady, wavering ray
    static let lightning = Magic(core: C(0xF4F8FF), glow: C(0x7FB2FF))
}

/// One character: who it is and how it's drawn. Registered in an Art/*.swift file next to its drawing function.
struct Persona {
    let name: String
    var weapon: Weapon = .none
    var motion: Motion = .walk
    /// Ranged characters: what the shots look like.
    var shot: ShotStyle = .energy(core: C(0xFFE0E0), glow: C(0xFF2A2A))
    /// Magic characters: what the stream looks like.
    var magic: Magic = .lightning
    /// Shots ricochet off it (armour, metal, rock).
    var armoured = false
    /// Sits down when its session has been idle a while.
    var canSit = true
    /// Where shots leave from, canvas pixels, facing right.
    var muzzle: (x: Double, y: Double) = (52, 32)
    /// Where its melee weapon swings from, or where magic leaves its hand.
    var pivot: (x: Double, y: Double) = Sprite.hand
    /// Its ranged weapon is held in the hand (so it raises it to check it, idle). False when it's built in:
    /// heat vision, Cyborg's arm cannon, starbolts.
    var handGun = true
    /// How many pixels further forward than plain Clawd its body reaches (Doomsday, Kilowog…): duels stand
    /// that much further apart so the other's weapon doesn't go through its face.
    var bulk = 0.0
    /// Top row of the head/helmet/hair on the canvas, for placing its label (the drawn sprite is measured too).
    var headTop = 21
    /// Length in seconds of its idle signature move, if it has one (`Pose.signature` runs 0…1 through it).
    var signature: Double? = nil
    /// What it says now and then while leading a session.
    var callout: String? = nil
    /// Draws it facing right on the 72×52 canvas.
    let draw: (PixelCanvas, Pose) -> Void

    /// A placeholder for a character whose persona isn't registered (shouldn't happen).
    static func missing(_ name: String) -> Persona {
        Persona(name: name, draw: { c, p in drawStandIn(c, p, body: C(0x8A8A96), trim: C(0x5A5A66)) })
    }
}

let heroPersonas: [Companion: Persona] = heroes1.merging(heroes2) { a, _ in a }.merging(heroes3) { a, _ in a }
    .merging(heroes4) { a, _ in a }
    .merging(heroes5) { a, _ in a }.merging(heroes6) { a, _ in a }.merging(heroes7) { a, _ in a }
    .merging(heroes8) { a, _ in a }.merging(heroes9) { a, _ in a }
    .merging(heroes10) { a, _ in a }
let villainPersonas: [Leader: Persona] = villains1.merging(villains2) { a, _ in a }.merging(villains3) { a, _ in a }
    .merging(villains4) { a, _ in a }
    .merging(villains5) { a, _ in a }.merging(villains6) { a, _ in a }.merging(villains7) { a, _ in a }
    .merging(villains8) { a, _ in a }.merging(villains9) { a, _ in a }

// MARK: - Homes

extension Location {
    static func home(of leader: Leader) -> Location {
        switch leader {
        case .joker, .jokerGoon: return .aceChemicals
        case .harleyQuinn, .riddler, .scarecrow, .poisonIvy, .mrFreeze, .killerCroc, .madHatter, .zsasz, .calendarMan: return .arkham
        case .penguin, .twoFace, .bane, .clayface, .hush, .firefly, .manBat, .ventriloquist, .blackMask: return .gotham
        case .rasAlGhul, .talia, .cheshire, .leagueAssassin: return .nandaParbat
        case .deathstroke, .trigon, .brotherBlood: return .titansTower
        case .talon: return .wayneManor
        case .lexLuthor, .doctorPoison: return .lexCorp
        case .generalZod, .ursa: return .phantomZone
        case .brainiac: return .kandor
        case .doomsday: return .krypton
        case .bizarro, .mrMxyzptlk, .livewire: return .metropolis
        case .metallo, .parasite, .toyman: return .strykersIsland
        case .darkseid, .steppenwolf, .desaad, .grannyGoodness, .kalibak, .parademon: return .apokolips
        case .lobo, .mongul, .despero, .cyborgSuperman: return .warworld
        case .antiMonitor, .parallax, .manhunter: return .oa
        case .sinestro, .atrocitus, .larfleeze, .dexStarr: return .korugar
        case .amazo, .eclipso, .giganta, .vandalSavage, .monsieurMallah, .copperhead: return .hallOfDoom
        case .starro, .maxwellLord: return .watchtower
        case .reverseFlash, .zoom, .savitar: return .speedForce
        case .captainCold, .heatWave, .mirrorMaster, .weatherWizard, .trickster: return .ironHeights
        case .gorillaGrodd: return .gorillaCity
        case .captainBoomerang, .deadshot, .amandaWaller, .enchantress: return .belleReve
        case .goldenGlider: return .centralCity
        case .cheetah, .ares, .circe, .silverSwan: return .themyscira
        case .blackManta, .oceanMaster, .trench: return .atlantis
        case .blackAdam, .kobraAgent: return .kahndaq
        case .doctorSivana, .mrMind: return .fawcettCity
        case .solomonGrundy, .gentlemanGhost: return .bayou
        case .felixFaust, .klarion: return .houseOfMystery
        case .killerFrost: return .starLabs
        case .blackHand, .starSapphire: return .coastCity
        }
    }

    static func home(of hero: Companion) -> Location {
        switch hero {
        case .superman, .krypto, .beppo: return .fortressOfSolitude
        case .batman, .robin, .orphan, .aceTheBatHound: return .batcave
        case .wonderWoman, .artemis, .donnaTroy, .nubia, .hippolyta, .steveTrevor: return .themyscira
        case .flash, .jesseQuick, .elongatedMan: return .centralCity
        case .greenLantern: return .coastCity
        case .aquaman, .aqualad, .mera: return .atlantis
        case .cyborg, .firestorm: return .starLabs
        case .martianManhunter, .simonBaz, .adamStrange, .redTornado, .captainAtom: return .watchtower
        case .greenArrow, .blackCanary, .arsenal: return .starCity
        case .shazam, .phantomStranger: return .rockOfEternity
        case .nightwing: return .bludhaven
        case .batgirl, .redHood, .catwoman, .huntress, .batwoman, .spoiler, .commissionerGordon, .ragman: return .gotham
        case .redRobin, .raven, .beastBoy, .starfire, .wonderGirl: return .titansTower
        case .supergirl: return .kandor
        case .superboy, .jonKent, .streaky: return .smallville
        case .powerGirl, .steel, .loisLane, .jimmyOlsen, .blackLightning: return .metropolis
        case .alfred, .luciusFox: return .wayneManor
        case .johnStewart, .guyGardner, .kyleRayner, .jessicaCruz, .kilowog, .tomarRe, .chP: return .oa
        case .hawkman, .hawkgirl: return .thanagar
        case .wallyWest, .impulse: return .speedForce
        case .jayGarrick, .alanScott, .doctorFate, .hourman, .stargirl, .wildcat, .atomSmasher, .cyclone, .sandman: return .jsaHQ
        case .doctorMidnite, .mrTerrific, .blueBeetle, .theAtom, .plasticMan, .vixen, .theQuestion, .metamorpho, .zan, .jayna, .gleek: return .hallOfJustice
        case .zatanna, .constantine, .spectre, .madameXanadu: return .houseOfMystery
        case .swampThing, .animalMan: return .bayou
        case .deadman, .katana: return .nandaParbat
        case .etrigan, .dream: return .theDreaming
        case .boosterGold, .saturnGirl, .cosmicBoy, .lightningLad: return .legionHQ
        case .mrMiracle, .bigBarda, .orion: return .newGenesis
        case .peacemaker, .bloodsport, .ratcatcher2, .kingShark, .polkaDotMan: return .belleReve
        }
    }
}

// MARK: - Rivalries and rides

extension Cast {
    /// Arch-enemies: whenever both are fighting, they're paired with each other first, wherever they are in the line.
    static let nemeses: [(Companion, Leader)] = [
        (.superman, .lexLuthor), (.superman, .doomsday), (.superman, .generalZod), (.superman, .brainiac),
        (.superman, .darkseid), (.superman, .bizarro), (.superman, .metallo), (.superman, .parasite),
        (.batman, .joker), (.batman, .bane), (.batman, .rasAlGhul), (.batman, .riddler), (.batman, .twoFace),
        (.batman, .scarecrow), (.batman, .hush), (.batman, .penguin), (.batman, .mrFreeze), (.batman, .killerCroc),
        (.wonderWoman, .cheetah), (.wonderWoman, .ares), (.wonderWoman, .circe), (.wonderWoman, .maxwellLord),
        (.flash, .reverseFlash), (.flash, .captainCold), (.flash, .gorillaGrodd), (.flash, .mirrorMaster), (.flash, .savitar),
        (.wallyWest, .zoom), (.impulse, .zoom), (.flash, .heatWave), (.flash, .weatherWizard), (.flash, .trickster),
        (.greenLantern, .sinestro), (.greenLantern, .parallax), (.greenLantern, .blackHand), (.greenLantern, .starSapphire),
        (.johnStewart, .sinestro), (.guyGardner, .atrocitus), (.kyleRayner, .parallax), (.jessicaCruz, .larfleeze),
        (.kilowog, .manhunter), (.simonBaz, .blackHand), (.aquaman, .blackManta), (.aquaman, .oceanMaster),
        (.mera, .trench), (.aqualad, .blackManta), (.cyborg, .darkseid), (.cyborg, .steppenwolf), (.cyborg, .parademon),
        (.martianManhunter, .despero), (.greenArrow, .deathstroke), (.arsenal, .cheshire), (.blackCanary, .copperhead),
        (.shazam, .blackAdam), (.shazam, .doctorSivana), (.shazam, .mrMind), (.robin, .talia), (.robin, .leagueAssassin),
        (.nightwing, .deathstroke), (.nightwing, .blackMask), (.redHood, .joker), (.redRobin, .talon), (.batgirl, .killerCroc),
        (.batwoman, .madHatter), (.spoiler, .blackMask), (.orphan, .cheshire), (.commissionerGordon, .joker),
        (.huntress, .zsasz), (.catwoman, .penguin), (.supergirl, .ursa), (.supergirl, .cyborgSuperman),
        (.superboy, .lexLuthor), (.steel, .toyman), (.powerGirl, .mrMxyzptlk), (.jonKent, .livewire),
        (.hawkman, .vandalSavage), (.hawkman, .gentlemanGhost), (.hawkgirl, .gentlemanGhost), (.raven, .trigon),
        (.beastBoy, .brotherBlood), (.starfire, .brotherBlood), (.wonderGirl, .giganta), (.alanScott, .solomonGrundy),
        (.doctorFate, .klarion), (.zatanna, .felixFaust), (.constantine, .felixFaust), (.spectre, .eclipso),
        (.swampThing, .solomonGrundy), (.mrMiracle, .grannyGoodness), (.bigBarda, .grannyGoodness), (.orion, .darkseid),
        (.orion, .kalibak), (.boosterGold, .maxwellLord), (.blueBeetle, .maxwellLord), (.firestorm, .killerFrost),
        (.blackLightning, .livewire), (.katana, .leagueAssassin), (.hippolyta, .ares), (.steveTrevor, .doctorPoison),
        (.artemis, .cheetah), (.donnaTroy, .silverSwan), (.peacemaker, .amandaWaller), (.bloodsport, .deadshot),
        (.kingShark, .trench), (.redTornado, .amazo), (.captainAtom, .eclipso), (.adamStrange, .starro),
        (.martianManhunter, .starro), (.theQuestion, .vandalSavage), (.elongatedMan, .goldenGlider),
        (.lightningLad, .weatherWizard), (.dream, .desaad), (.jayGarrick, .savitar), (.kyleRayner, .mongul),
        (.superman, .mongul), (.greenLantern, .antiMonitor), (.jesseQuick, .captainBoomerang), (.atomSmasher, .giganta),
        (.cyclone, .weatherWizard), (.stargirl, .solomonGrundy), (.wildcat, .monsieurMallah), (.vixen, .copperhead),
        (.animalMan, .manBat), (.ragman, .clayface), (.mrTerrific, .lexLuthor), (.theAtom, .lobo),
    ]

    func isNemesis(of other: Cast) -> Bool {
        switch (self, other) {
        case (.hero(let h), .villain(let v)), (.villain(let v), .hero(let h)): return Self.nemeses.contains { $0 == (h, v) }
        default: return false
        }
    }

    /// When this one's agent is done, its ship comes to pick it up instead of it just fading out.
    var ride: Ride? {
        switch self {
        case .hero(.greenArrow), .hero(.blackCanary), .hero(.vixen), .hero(.theQuestion), .hero(.mrTerrific),
             .hero(.steveTrevor), .hero(.blackLightning), .hero(.elongatedMan), .hero(.plasticMan), .hero(.zan),
             .hero(.jayna): return .javelin
        case .hero(.batman), .hero(.robin), .hero(.nightwing), .hero(.batgirl), .hero(.redRobin), .hero(.batwoman),
             .hero(.orphan), .hero(.spoiler), .hero(.redHood), .hero(.huntress): return .batwing
        default: return nil
        }
    }
}

enum Ride { case javelin, batwing }
