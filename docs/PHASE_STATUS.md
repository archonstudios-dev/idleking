# Idle King: Ground Zero Phase Status

## Completed

- Phase 0
  - Studio branding splash
  - Title screen
  - King naming flow
  - Saved king name and scene transitions
- Phase 1
  - Portrait HUD scaffold
  - Gold and gem resource bar
  - Tap-for-gold loop
  - Runtime and editor-generated UI scaffold
- Phase 2
  - Auto-battle loop
  - Wave progression
  - Boss wave cadence
  - Enemy rewards and combat HUD state
- Phase 3
  - Damage, speed, and gold upgrades
  - Upgrade overlay and scaling costs
  - Persistent upgrade progression

## Current Focus

- Combat presentation polish
  - Better sprite integration with the environment
  - Background and castle framing refinement
  - Cleaner grounded motion and animation variety
  - Smaller pooled hit sparks, floating numbers, and subtle shake
- UI polish
  - Larger mobile tap targets
  - Better panel slicing and spacing
  - More readable typography with stronger outline/shadow treatment
  - More final-looking icon choices
- Audio foundation
  - Low-volume music playback
  - Universal mute toggle

## Not Started

- Phase 4
  - Hero gacha
  - Hero data resources
  - Hero slot functionality
- Phase 5
  - Pet gacha
  - Active pet support
  - Duplicate-based pet leveling
- Phase 6
  - Full art pass integration
  - Combat/UI animation polish
  - Final visual cohesion pass
- Phase 7
  - Rewarded ads
  - Banner ads
  - Gem IAP packs
  - Daily login

## Expansion Suggestions

- Boss intro camera pulse and screen tint
- Tap impact particles and hit-stop on attacks
- Castle damage state visuals for later combat phases
- Dynamic music layers for normal waves vs boss waves
- Daily quests tied to tapping, waves, and summons
- Hero faction bonuses and set synergies
- Limited-time event raids and seasonal skins

## Optimization Notes

- UI is now meant to stay event-driven through autoload signals instead of frame-by-frame polling.
- Floating labels and hit sparks are intended to stay pooled and reused for mobile efficiency.
- Font and button sizing are being tuned for portrait-phone readability first.
