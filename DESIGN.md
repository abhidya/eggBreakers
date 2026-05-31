# Design

## Source of truth

- **Status:** Draft, active for story/UI/UX decisions
- **Last refreshed:** 2026-05-30
- **Primary product surfaces:** Roblox in-world survival loop, species selection/player visual, survival HUD, mobile controls, food/water waypoint/sense UX, combat feedback, nesting/home loop, biome discovery.
- **Evidence reviewed:** `eggBreakers_Master_Plan.md`, `eggBreakers_World_and_Gameplay_Design.md`, `eggBreakers_Asset_Ledger_and_Build_Sequence.md`, `eggBreakers_STATUS.md`, `docs/AssetSourcing.md`, `docs/StoryModeStoryboard.md`, `src/ReplicatedStorage/Shared/SpeciesConfig.lua`, `src/ServerScriptService/Services/MapLayoutService.lua`, `src/StarterPlayer/StarterPlayerScripts/ClientControllers/*`.

## Brand

- **Personality:** natural, dangerous, readable, kid-accessible, prehistoric survival with light mystery.
- **Trust signals:** real dinosaur silhouettes, clear food/water affordances, honest Creator Store provenance, reviewed imported scripts, visible cause/effect for every stat change.
- **Avoid:** default Roblox avatar as dinosaur, primitive/CSG placeholder creatures, ball food, square water, misleading waypoint arrows, unreviewed imported scripts/sounds, generic quest-giver UI.

## Product goals

- **Goals:** make the player feel like a dinosaur; make food/water/combat/growth readable without developer labels; turn each biome into a story beat backed by visual/mechanical/UI/UX assets.
- **Non-goals:** dialogue-heavy quest mode, shipping unreviewed free-model behavior scripts, counting catalog-only assets as release-ready, replacing every system before story/asset quality is proven.
- **Success signals:** screenshots clearly show dino identity, real food/water, biome identity, combat feedback, nest/home ownership, and city mystery.

## Personas and jobs

- **Primary personas:** young Roblox survival players; dinosaur fans; players who prefer visual discovery over text quests.
- **User jobs:** choose species, survive needs, find valid food/water, grow, fight/flee, explore safer-to-riskier biomes, claim a nest/home, discover Old Eden/city mystery.
- **Key contexts of use:** desktop and mobile; short sessions; players need readable targets quickly.

## Information architecture

- **Primary navigation:** in-world movement through biomes rather than menus.
- **Core screens:** Hatch/species reveal, MainHUD, MobileControls, SpeciesInfoPanel, Group/Call feedback, Death/Respawn, CityDiscoveryPopup, Nest/Home prompt.
- **Content hierarchy:** immediate survival needs first; threat/combat second; growth/progression third; world mystery last.

## Design principles

1. **The world is the quest-giver:** story appears through ecology, landmarks, carcasses, nests, ruins, fossils, and sound.
2. **Every asset earns its job:** visual beauty is not enough; each asset must carry mechanical, UI, or UX value.
3. **Readable before realistic:** silhouettes and affordances must be obvious before detail or decoration.
4. **Creator assets are raw material, not game logic:** keep mesh/rig/VFX/audio only after sanitization; behavior comes from repo services.

## Visual language

- **Color:** natural greens/browns in Nursery/Fern/Jungle; muddy desaturated Swamp; warm red/orange Canyon; cold grey/green overgrown City.
- **Typography:** simple, high-contrast Roblox-readable text; avoid lore paragraphs during action.
- **Spacing/layout rhythm:** compact HUD; mobile thumb controls must not overlap stat bars.
- **Shape/radius/elevation:** rounded kid-friendly panels; diegetic indicators over hard-edged debug labels.
- **Motion:** short pulses for needs, scent/target hints, calls, growth; avoid constant noisy animations.
- **Imagery/iconography:** heart/meat/water/bolt/growth icons; dinosaur-claw cursor is a thematic optional improvement.

## Components

- **Existing components to reuse:** `HUDController`, `MobileControlsController`, `UIFactory`, `ClientBootstrap` target finding/hints, RemoteEvents in shared contracts.
- **New/changed components:** story-mode scent/sense indicator; threat/roar directional pulse; nest/home marker; city discovery popup; asset approval screenshot board.
- **Variants and states:** hunger low, thirst low, invalid food, food nearby, water nearby, threat near, oxygen active, growth ready, nest claimed, home under threat.
- **Token/component ownership:** keep UI in existing client controllers unless a repeated pattern needs extraction.

## Accessibility

- **Target standard:** readable at Roblox default camera distances on desktop/mobile.
- **Keyboard/focus behavior:** actions available through keyboard and mobile buttons.
- **Contrast/readability:** status bars and prompts must contrast against jungle/swamp/city backgrounds.
- **Screen-reader semantics:** not currently established; keep text labels where icon-only state could confuse.
- **Reduced motion/sensory:** avoid looped/autoplay imported sounds and heavy flashing VFX.

## Responsive behavior

- **Supported devices:** desktop keyboard/mouse and mobile touch.
- **Layout adaptations:** mobile buttons use icon-first layout; optional Flight/Swim hidden unless relevant.
- **Touch/hover differences:** target hint and context button must work without mouse hover.

## Interaction states

- **Loading:** Hatch/species reveal should hide raw world load where possible.
- **Empty:** if no valid food/water exists, show calm “search farther” cue, not broken arrow.
- **Error:** invalid diet target explains with icon/color, not long text.
- **Success:** bite/slurp audio, bar fill, growth sparkle, small toast.
- **Disabled:** unavailable Flight/Swim hidden or subdued with reason.
- **Offline/slow network:** not applicable for current local Roblox prototype.

## Content voice

- **Tone:** simple, sensory, survival-focused.
- **Terminology:** use species names, diet, growth stage, nest/home, scent, threat, Old Eden.
- **Microcopy rules:** prefer verbs: “Eat fern,” “Drink,” “Hide,” “Call,” “Claim nest,” “Fossil found.”

## Implementation constraints

- **Framework/styling system:** Roblox Luau, Rojo-managed source, existing client controllers and services.
- **Design-token constraints:** existing `UIFactory` colors/buttons unless refreshed deliberately.
- **Performance constraints:** imported executable scripts may ship only after review, ownership assignment, authority/sandbox checks, and focused tests; strip or rewrite uncontrolled looped/autoplay audio; avoid excessive particles.
- **Compatibility constraints:** Creator Store assets must be sanitized, tagged, provenance-tracked, and screenshot-proven.
- **Test/screenshot expectations:** story-mode acceptance requires screenshots of visual target plus UI affordance, not just passing code tests.

## Open questions

- [ ] Which Creator Store assets are actually high-rated/favorited? Local repo metadata does not include ratings.
- [ ] Which staged `Workspace.dinosaur` species have source provenance and rig/animation compatibility?
- [ ] Should “Velociraptor” remain the starter if the staged library lacks a true velociraptor mesh?
- [ ] What is the final tone for Old Eden: mysterious, scary, hopeful, or pure survival landmark?
