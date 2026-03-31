# Idle King: Ground Zero Mobile Optimization Notes

## Scope

This pass focuses on readability, responsiveness, clarity, and mobile efficiency without changing the core layout or adding new gameplay systems.

## Optimized Scene Structure

- `MainGameScreen`
- `GeneratedUI`
- `SafeArea`
- `MainColumn`
- `TitleBar`
- `ResourceBar`
- `CombatPanel`
- `CombatArena`
- `CombatSpriteLayer`
- `FeedbackLayer`
- `HeroSlotsPanel`
- `SelectedUnitPanel`
- `BottomBarPanel`
- `UpgradeOverlay`

This keeps the layout container-driven while isolating combat visuals and transient feedback in dedicated layers.

## UI Scaling Strategy

- Use larger portrait-first base font sizing.
- Keep most tap targets at roughly `64px+` height.
- Increase spacing between stacked panels to reduce accidental overlap.
- Keep text clipped within buttons and grow button heights instead of shrinking fonts too far.
- Avoid non-integer label motion for floating text where possible.

## Event-Driven UI Pattern

The UI should refresh from signals rather than `_process()`.

Current examples:

- `CurrencyManager.currencies_changed -> _refresh_currency_labels`
- `CombatManager.combat_state_changed -> _refresh_combat_state`
- `UpgradeManager.upgrades_changed -> _refresh_upgrade_state`
- `GameState.king_name_changed -> _refresh_king_panel`
- `AudioManager.mute_changed -> _refresh_audio_button`

## Lightweight Feedback

- Floating gold numbers are pooled and reused.
- Floating damage numbers are pooled and reused.
- Hit sparks are pooled and reused.
- Camera shake is subtle and short.
- Tap button uses a lightweight scale tween instead of heavy particles.

## Object Pooling Notes

Current pooled UI feedback lives in `MainGameScreen.gd`:

- Floating labels pool
- Hit spark pool

Benefits:

- Avoids repeated node instantiation during combat.
- Keeps peak GC pressure lower on mobile.
- Makes repeated attacks cheaper.

## Texture Import Checklist

Use these Godot import settings for pixel-art-heavy UI and sprites:

- Disable `Filter` for true pixel art sprites if the source is intended to stay crunchy.
- Enable `Filter` only for large painted backgrounds if aliasing is too harsh.
- Disable `Mipmaps` for UI textures.
- Keep `Repeat` off for UI and character sprites.
- Crop transparent padding from spritesheets where possible.
- Prefer imported resources over runtime image loading for final export builds.
- Keep large scenic backgrounds near the minimum resolution that still looks clean on device.
- Avoid stacking many large transparent textures across the same screen region.

## Current Completed Phases

- Phase 0: branding, title, naming flow
- Phase 1: economy HUD and tap loop
- Phase 2: combat loop, waves, bosses
- Phase 3: upgrades and progression panel

## Current Polish Focus

- combat readability
- font clarity
- mobile tap target size
- UI asset slicing
- low-cost feedback effects
- audio volume and mute support

## Future Phases

- Phase 4: hero gacha and hero resources
- Phase 5: pet system
- Phase 6: full art and animation pass
- Phase 7: monetization and retention systems

## Additional Expansion Suggestions

- boss-specific hit sparks and impact colors
- low-health castle warning overlay
- parallax background motion
- hero ultimate cut-in overlays
- accessibility font-size toggle
- quality settings preset for lower-end Android devices
