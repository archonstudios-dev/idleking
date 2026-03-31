# Idle King: Ground Zero - Game Design Document

## 1. Project Summary

**Project Name:** Idle King: Ground Zero  
**Platform:** Android mobile  
**Engine:** Godot 4  
**Language:** GDScript only  
**Orientation:** Portrait locked  
**Target Resolution:** 1080x1920  
**Genre:** Idle tap game with side-view combat  
**Core Fantasy:** The player is a King defending his castle while building power through tapping, upgrades, hero summons, and pets.

Idle King: Ground Zero is a portrait-first idle battler where the player actively taps for early income and gradually scales into passive combat and collection systems. The experience should feel fast to read, rewarding to interact with in short mobile sessions, and expandable over time through heroes, pets, events, and monetization systems.

## 2. Vision Statement

Build a mobile-first idle combat game with a strong medieval identity, clean one-thumb navigation, and constant visible progression. The player should always have something meaningful to do:

- Tap for immediate gain
- Spend on upgrades
- Watch combat progress
- Summon heroes and pets
- Improve their King and roster over many sessions

The game should begin simple and readable, then layer in automation, collection, and economy depth without losing clarity.

## 3. Design Pillars

1. **Mobile readability first**  
All important information must be legible in portrait mode on Android devices.

2. **Visible progression at all times**  
Gold gain, damage growth, wave growth, and roster growth should always be felt.

3. **Active-to-idle transition**  
Early taps matter. Midgame upgrades and companions reduce reliance on constant tapping.

4. **Medieval dark-fantasy tone**  
UI chrome should feel regal and battle-worn, using dark navy, brown, and gold accents rather than bright arcade colors.

5. **Modular Godot architecture**  
Systems should be loosely coupled, editor-friendly, and organized for phased delivery.

## 4. Audience

- Players who enjoy idle and incremental games
- Mobile users who prefer short, repeatable sessions
- Players motivated by visible stat growth, summons, and collection systems
- Casual RPG fans who like medieval fantasy themes

## 5. Core Gameplay Loop

### Moment-to-moment loop

1. Tap to generate gold or trigger the main TAP action
2. Spend currency on upgrades and progression systems
3. Watch the King and allied units attack enemies automatically
4. Defeat enemies to earn rewards and advance waves
5. Summon heroes and pets for passive bonuses
6. Strengthen the account and repeat

### Session loop

1. Launch game
2. Collect idle/active value through tapping and combat
3. Spend currencies efficiently
4. Check summons, units, and temporary rewards
5. Push to higher waves and bosses

### Long-term loop

1. Unlock stronger progression layers
2. Improve passive earning and combat performance
3. Build a better hero and pet lineup
4. Participate in events and monetized reward loops

## 6. Game Flow

### Phase 0 flow

0. Studio branding splash screen
1. Title Screen
2. Start button
3. Name Input Screen
4. Save King name
5. Transition into Main Game scene

### Ongoing runtime flow

1. Player enters main battle screen
2. Currency and combat information are always visible
3. Bottom navigation opens future feature panels
4. Tapping always provides a meaningful response in early game
5. Systems unlock and deepen through phased development

## 7. Theme and Visual Direction

### Tone

- Regal
- Defensive
- Heroic
- Dark medieval
- Slightly stylized rather than realistic

### Palette

- Primary UI chrome: dark navy
- Secondary chrome: deep brown / wood
- Accents: gold / amber
- Background support: muted gray-blue, stone, parchment, iron
- Avoid: green-led UI themes

### UI reference alignment

The provided `Assets/UI-Reference.png` establishes the intended composition:

- Short medieval title bar at the top
- Resource row directly beneath
- Large combat space taking roughly half the screen
- Hero card row under combat
- Selected unit panel above bottom navigation
- Bottom navigation with 5 buttons and a larger center TAP button

The final Phase 1 layout should preserve this composition while shifting the current bright mockup into a darker navy/brown/gold presentation.

### Current implementation direction

The live build currently targets:

- A studio branding splash before the title screen
- A dark navy, brown, and gold medieval HUD
- Larger mobile-first font and button sizing
- A portrait combat frame with castle background, central castle, and side-view fighters
- Lightweight feedback such as floating numbers, hit sparks, short flashes, subtle shake, and tap-button feedback
- A low-volume music layer with a universal mute toggle

## 8. Screen List

### Title Screen

- Game title
- Background art
- Start button
- Optional version label

### Name Input Screen

- Prompt to name the King
- Text input field
- Confirm button
- Basic validation

### Main Game Screen

- Top title bar
- Currency/resource bar
- Main combat viewport
- Hero slot row
- Selected unit panel
- Bottom navigation

### Future overlay/panel screens

- Gacha panel
- Upgrades panel
- Roster panel
- Events panel
- Settings panel

## 9. Main Screen Layout Spec

### Top title bar

- Height should be modest and non-dominant
- Medieval framing with crown and sword motifs
- Title text centered
- Decorative only, not a large gameplay area consumer

### Resource bar

- Gold icon + amount on left
- Gem icon + amount near center-left or center
- Settings button on right
- Real-time updates
- Readable at a glance

### Combat area

- Occupies about 50% of vertical screen
- Side-view battlefield
- King on the left
- Enemy on the right
- HP bars above both units
- Castle backdrop behind the King side
- Tap feedback indicator or callout
- Placeholder art accepted until final art pass

### Hero slots row

- 3 slot cards horizontally aligned
- Each card should communicate occupied/unoccupied state
- Designed to later support rarity color, portrait, and passive summary

### Selected unit panel

- Icon/portrait
- Name
- Level
- Upgrade button
- Defaults to King in early phases until hero interaction exists

### Bottom navigation

- 5 buttons: Gacha, Upgrades, TAP, Roster, Events
- TAP is centered and larger than the others
- All buttons must support icon + text
- Non-implemented buttons in Phase 1 can be visible but disabled or show placeholder feedback

## 10. Controls and Interaction

### Phase 0

- Tap Start button
- Enter King name with on-screen/mobile keyboard
- Confirm name and proceed

### Phase 1

- Tap center TAP button to gain gold
- Tap selected unit upgrade button placeholder
- Tap navigation buttons for placeholder panel messaging or disabled state
- Tap settings button placeholder

### Future phases

- Tap panels to upgrade, summon, manage roster, and use event systems

## 11. Economy Design

### Currencies

#### Gold

- Primary soft currency
- Earned from tapping in Phase 1
- Earned from enemy kills in Phase 2+
- Spent on upgrades in Phase 3+

#### Gems

- Premium currency
- Visible from Phase 1 even if not yet fully spendable
- Used for summons, packs, and premium actions later
- Earned from future rewards, ads, events, or IAP

### Early-game economy goals

- Taps should feel immediately rewarding
- Numbers should climb fast enough to create momentum
- Costs should be paced so Phase 1 feels responsive, not grindy

## 12. Combat Design

### Combat model

- Side-view idle combat
- King automatically attacks at a fixed rate
- Enemy occupies the opposing lane
- HP bars show immediate progress
- Animated character presentation with readable sprite scale
- Castle defense focal point centered in the battlefield
- Scenic `castle-bg` backdrop behind the defended castle
- Walk, run, and attack motion inside a grounded combat lane
- Combat backdrop should fill the arena frame cleanly, with only a narrow ground strip at the bottom
- Small, readable effects should be preferred over oversized slash visuals
- Characters should be visually separated from the background with clearer staging and readability treatment

### Combat goals

- Easy to understand visually in portrait mode
- Strong sense of impact from damage and enemy defeat
- Supports future heroes and pets without major layout changes
- Keep performance mobile-friendly by reusing lightweight feedback nodes where possible

### Wave structure

- Standard enemies for most waves
- Boss every 10th wave
- Each wave increases challenge

### Phase gating

- Combat automation begins in Phase 2
- Phase 1 only reserves the UI and architecture for it

## 13. Upgrade Design

### Planned upgrade categories

- Damage
- Attack speed
- Gold multiplier

### Upgrade behavior

- Costs scale progressively
- Upgrades provide small early gains and stronger long-term compounding
- Feedback must be instant and readable

## 14. Readability and Mobile UX Rules

- Core HUD text should stay readable on a portrait phone without zooming.
- Important text should use outline and shadow for contrast.
- Buttons should maintain comfortable mobile tap targets.
- Layout should stay container-driven and avoid cramped spacing.
- UI updates should stay signal-driven instead of frame-polled.
- Combat effects should be lightweight, pooled, and visually clear.

## 15. Hero System

### Summary

Heroes are collectible support units acquired via gacha. In early implementation they occupy slots and provide passive bonuses rather than full independent battlefield AI complexity.

### Hero slots

- 3 active hero slots visible on main screen
- Unlocked from the start for readability and anticipation

### Rarities

- Common
- Rare
- Epic
- Legendary

### Data structure

- Each hero stored as a Godot `Resource` in `.tres`
- Expected fields:
  - id
  - display_name
  - rarity
  - icon/portrait
  - passive_type
  - passive_value
  - description

## 16. Pet System

### Summary

Pets are a separate collectible pool with one active pet at a time. Pets provide passive benefits and visible battlefield companionship.

### Planned pet bonus types

- Attack bonus
- Gold bonus
- Shield bonus
- Speed bonus

### Duplicate behavior

- Duplicate pulls level up the pet

## 17. Monetization Design

### Planned monetization

- Rewarded ads for bonus gold and free summons
- Non-intrusive banner ads
- IAP gem packs
- Daily login rewards

### Monetization principles

- Rewarded ads should always feel optional and valuable
- Paid systems should accelerate, not replace, progression
- Ads should not obstruct combat readability or the bottom navigation

## 18. Technical Architecture

### Engine standards

- Godot 4 only
- GDScript only
- `Control` nodes for all UI
- Portrait mode locked
- Modular scene structure
- Loosely coupled scripts
- Comments in every script
- Use `gameFont.ttf` universally across the shipped UI, with readability tuning, larger sizing, and outline/smoothing treatment for mobile legibility
- Keep dense combat/status information out of the center action focal area

### Proposed folder structure

```
res://
  Assets/
  Scenes/
    Bootstrap/
    UI/
    Main/
    Combat/
  Scripts/
    Autoload/
    UI/
    Core/
    Data/
    Editor/
  Resources/
    Heroes/
    Pets/
  docs/
```

### Autoload candidates

- `GameState`
- `SaveManager`
- `SceneRouter`
- `CurrencyManager`

### Scene ownership plan

- Title scene handles entry flow only
- Name input scene handles naming only
- Main game scene owns layout composition
- Feature panels remain modular children or instanced scenes

## 19. Save Data Plan

### Early save fields

- player_king_name
- gold
- gems
- first_launch_complete

### Future save fields

- upgrades
- wave progress
- hero roster
- pet roster
- selected heroes
- selected pet
- daily login state
- monetization entitlements

### Save goals

- Lightweight JSON or Godot-native save approach
- Save on important state changes
- Support clean future expansion

## 20. Audio Direction

### Planned audio layers

- Title ambience
- Light battle ambience
- Tap SFX
- Reward pickup SFX
- Button UI SFX
- Enemy defeat SFX

Audio is not required for the first implementation pass but systems should remain compatible with future hooks.

## 21. Placeholder Asset Strategy

Phase 0 and Phase 1 should use placeholder sprites and available project art where possible. The repo scan shows suitable starting content in:

- `Assets/TitleScreen`
- `Assets/Art/Background`
- `Assets/Art/Castle`
- `Assets/Art/King`
- `Assets/Art/Enemies`
- `Assets/Art/Icons`
- `Assets/Art/UI`
- `Assets/Art/Fonts`

The UI reference image is useful for layout composition, not final color treatment. The actual implementation should reinterpret that structure using darker chrome and gold accents.

## 22. Asset Scan Summary

### Confirmed existing project assets

- `Assets/UI-Reference.png`
- `Assets/TitleScreen/titleScreen-idleking.png`
- `Assets/studioBranding/*`
- `Assets/Art/Castle/castle-bg.png`
- `Assets/Art/Castle/castle.png`
- `Assets/Art/Background/*`
- `Assets/Art/King/*`
- `Assets/Art/Enemies/*`
- `Assets/Art/GachaPool/*`
- `Assets/Art/PetGachaPool/*`
- `Assets/Art/Icons/IconPack/*`
- `Assets/Art/UI/*`
- `Assets/Art/Fonts/gameFont.ttf`

### Current implemented state

- Godot project scaffold exists
- Bootstrap scenes exist for studio branding, title, and naming flow
- Main gameplay scene is script-built at runtime/editor via builder scripts
- Autoload managers exist for save, game state, currency, combat, and upgrades
- Phase 0, Phase 1, Phase 2, and Phase 3 are implemented

## 23. Editor Script Strategy

Per request, each phase from Phase 1 onward should include an editor automation script so scene setup is not manual.

### Phase 1 editor tooling requirement

Create an editor script that can:

- Build the Phase 1 main screen scaffold
- Create the portrait UI structure
- Place title bar, resource bar, combat area, hero slots, selected unit panel, and bottom nav
- Hook named nodes for scripts to use consistently

### Future editor tooling direction

- Phase 2: combat scaffold builder
- Phase 3: upgrades panel builder
- Phase 4: hero gacha setup builder
- Phase 5: pet system scene builder
- Phase 6: art integration helper
- Phase 7: monetization UI hooks builder

These future scripts will not be implemented yet, but the Phase 1 system should establish a reusable pattern.

## 24. Full Phase Roadmap

### Phase 0 - Game Flow

- Studio branding splash before title
- Title screen with Start button
- Name input screen
- Save King name
- Scene transitions

### Phase 1 - Core Foundation + Basic UI

- Gold and Gem currency
- Basic UI layout aligned to reference
- Tap button generates gold
- Resource display updates in real time
- Main screen scaffold editor script
- Dark medieval UI treatment with improved panel/button rendering
- Improved typography scaling for readability

### Phase 2 - Combat

- King auto attacks
- Enemy spawn on right
- HP bars
- Enemy death rewards gold
- Wave system with boss every 10 waves
- Combat editor setup script
- Animated King and enemy combat presentation
- Center castle focal point using the standalone `castle.png` asset
- Castle background layer behind the defended castle
- Ground lane and shadow pass to keep combatants visually anchored
- Combat information shifted away from the middle of the action
- Combat frame composition should follow the square reference layout closely, with the castle dominating center stage

### Phase 3 - Upgrades

- Damage, speed, gold multiplier upgrades
- Upgrade panel UI
- Progressive cost scaling
- Upgrade editor setup script
- Gold multiplier applies to taps and combat rewards
- Upgrade overlay uses smooth fade transitions

### Phase 4 - Hero Gacha

- Summon system
- 3 hero slots
- Passive bonuses
- Rarity system
- Hero `.tres` resources
- Hero/gacha editor setup script

### Phase 5 - Pet System

- Separate pet gacha pool
- 1 active pet
- Duplicate-based pet leveling
- Pet battlefield presence
- Pet editor setup script

### Phase 6 - Art Pass

- Integrate project art folders
- Full polish pass
- Animation hookup
- Art integration editor support

### Phase 7 - Monetization

- Rewarded ads
- Banner ads
- IAP gem packs
- Daily login rewards
- Monetization editor/setup helpers

## 25. Immediate Build Scope After Approval

Once this GDD is approved, the implementation scope should be limited to:

### Build now

- Phase 0
- Phase 1
- Later approved: Phase 2
- Later approved: Phase 3

### Do not build yet

- Phase 2
- Phase 3
- Phase 4
- Phase 5
- Phase 6
- Phase 7

## 26. Phase 0 Deliverables

- Godot project bootstrap
- Studio branding splash scene
- Portrait configuration
- Title screen
- Name input screen
- Save/load for King name
- Scene transition flow into main scene

## 27. Phase 1 Deliverables

- Main game UI scene matching reference composition
- Gold and Gem resource model
- Live resource text updates
- Functional TAP button generating gold
- Placeholder hero slots
- Placeholder selected unit panel
- Bottom navigation shell
- Phase 1 editor automation script

## 28. Phase 2 Deliverables

- Auto-attacking King combat loop
- Animated enemy spawning and wave progression
- Boss waves every 10 waves
- Combat rewards tied into the currency system
- Combat scene automation script

## 29. Phase 3 Deliverables

- Damage, speed, and gold multiplier upgrades
- Upgrade overlay UI with live costs and affordability states
- Save-backed upgrade progression
- Upgrade effects applied to combat and gold gain
- Phase 3 scene automation script

## 30. Risks and Mitigations

### Risk: UI becomes too bright or too casual

Mitigation: Use the reference for layout only, and the dark palette for implementation.

### Risk: Portrait layout becomes cramped

Mitigation: Keep combat area visually dominant and use concise labels with reusable panels.

### Risk: Later systems require UI rework

Mitigation: Reserve future space now with placeholder cards, selected unit panel, and bottom nav.

### Risk: Tight coupling between systems

Mitigation: Use manager-style autoloads and clear node naming from Phase 1.

## 31. Success Criteria

### Phase 0 success

- Player can launch the game, press Start, enter a King name, and reach the main screen
- Name is saved and available for future sessions

### Phase 1 success

- Main screen visibly matches the requested portrait layout
- Gold and gems display correctly
- TAP button adds gold instantly
- UI feels coherent, readable, and medieval in tone
- Scene can be auto-generated or scaffolded through editor tooling

### Phase 2 success

- Combat feels active and visually readable in portrait mode
- Character sprites are clearly visible and animated
- The castle reads as the defended focal point
- Waves and boss progression are obvious to the player

### Phase 3 success

- Upgrade costs scale progressively
- Damage, speed, and gold upgrades have visible gameplay impact
- Upgrade UI is readable and fast to use
- Upgrade state persists between sessions

## 32. Build Notes For Implementation

- Prefer placeholder art and clean structure over premature polish
- Use available UI asset pack for buttons/panels where it fits the darker medieval theme
- Add comments to every script as requested
- Keep all non-implemented systems visible only as placeholders
- Keep the bundled game font on display text, not dense body text, to preserve readability

## 33. Current Status

Implemented now:

- Phase 0
- Phase 1
- Phase 2
- Phase 3

Not implemented yet:

- Phase 4
- Phase 5
- Phase 6
- Phase 7

## 34. Approval Checkpoint

This document defines the project vision and confirms the current implementation boundary:

- Proceed with **Phase 0**
- Proceed with **Phase 1**
- Phase 2 and Phase 3 were later approved and implemented
- Do **not** build Phase 4 or beyond yet unless newly approved
- Include a **Phase 1 editor script** that auto-builds the Phase 1 scene scaffold
