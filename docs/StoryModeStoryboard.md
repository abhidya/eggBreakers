# eggBreakers — Story Mode Storyboard & Asset Value Matrix

**Status:** Draft v0.3
**Last refreshed:** 2026-05-31
**Scope:** Story, storyboard beats, and asset/UI/UX value only. This is not an implementation plan and does not claim assets are already placed or wired.

## Source of truth and evidence reviewed

- `eggBreakers_Master_Plan.md` — current production goals, blockers, and 2026-05-30 authoritative snapshot.
- `eggBreakers_World_and_Gameplay_Design.md` — world fantasy, biome order, story beats, and fine-grained asset catalog.
- `eggBreakers_Asset_Ledger_and_Build_Sequence.md` — asset disposition and build sequencing.
- `docs/AssetSourcing.md` — antigravity/Gemini verified Creator Store search IDs and sourcing quality filter.
- `src/ReplicatedStorage/Shared/AssetManifest.lua` — 500 cataloged `SourceAssetId` entries with creator/query/script metadata.
- `src/ReplicatedStorage/Shared/SpeciesConfig.lua` and `src/ReplicatedStorage/Shared/SpeciesRoster.lua` — configured species roles, diets, movement modes, growth stats, abilities, and animation slots.
- `src/ServerScriptService/Services/StarterSpeciesService.lua` and `src/StarterPlayer/StarterPlayerScripts/ClientControllers/HatchUIController.lua` — current curated starter order: `coelophysis`, `parasaurolophus`, `utahraptor`, `citipati`.
- `src/ReplicatedStorage/Shared/StagedMeshLibrary.lua` — staged mesh mappings for the four curated starters plus the broader staged roster.
- `src/ServerScriptService/Services/SurvivalService.lua` — hatch progress, movement flags, needs/eating growth, rest/sleep, age, dying, respawn, and Alpha state.
- `src/ServerScriptService/Services/WorldDressingService.lua` — additive biome dressing insertion/scatter/grounding pipeline; not wired as proof that every biome is already dressed.
- `src/ServerScriptService/Services/MapLayoutService.lua` — current biome layout, food/water placements, and food metadata.
- `src/StarterPlayer/StarterPlayerScripts/ClientControllers/*` — current HUD/mobile/waypoint affordance evidence.
- `docs/G027_AssetBackedStoryBatch.md` — live inserted Beat 0 nest/egg, Beat 1 plant pack, and HUD icon source batch; still requires Studio save/reopen persistence.
- `src/ServerScriptService/Tests/E2E/E2E_HatchToFirstFood.lua` — hatch/select/first-food regression coverage for the playable opening loop.
- `src/ServerScriptService/Tests/E2E/E2E_PlayableLoopClosure.lua` — server-authoritative hatch, eat/drink, growth, rest/age, fight, city/fossil, dying, and respawn loop coverage.
- `src/ServerScriptService/Tests/Placement/StoryboardBeatValidation.lua` — source assertions for storyboard Beats 0-8, including imported egg source id `8895193`, readable starter food/carcass visuals, growth scale, fish/water, apex/city/nest hooks.
- `src/StarterPlayer/StarterPlayerScripts/Tests/HatchUITests.client.lua` — client selector rendering and selected-option coverage.
- `src/StarterPlayer/StarterPlayerScripts/Tests/ClientHUDTests.client.lua` — client HUD coverage for growth, role, story cue, rest/sleep, age, oxygen, threat, and dying readability.
- Live Studio read-only audit, 2026-05-30 — `Workspace.dinosaur` is a staged mesh dino library; `Workspace.Map` remains mostly primitive placeholders.

## Validation language

Use these labels consistently:

- **Validated catalog asset** — present in `AssetManifest.lua` with `SourceAssetId`, name, creator, search query, and script metadata.
- **Validated search reference** — present in `docs/AssetSourcing.md` as a verified Studio MCP Creator Store `searchId`, but not necessarily inserted/placed.
- **Validated staged asset** — observed in live Studio under `Workspace.dinosaur`; good visual candidate but not release-tagged or gameplay-wired.
- **Needs rating lookup** — current local evidence does not include Creator Store ratings/favorites/trust; do not call these “high rated” until searched externally or inspected in Studio.
- **Reject / placeholder** — primitive, generated, ball/square, CSG fallback, AI-generated slop, or asset with no clear visual/mechanical/UI/UX job.

## Swarm audit additions — 2026-05-31

- **Lane priority override from mobile evidence:** iPhone portrait and landscape are currently not playable because UI cards obstruct the play space. Fix mobile playability before adding new story polish. Required proof: live iPhone-sized portrait and landscape captures where hatch/species cards, HUD, context action, and mobile controls leave the dinosaur, food/water target, threat, and path visible and tappable.
- Visible quality is now part of every story gate: screenshots must prove the player sees a real dinosaur, readable food, drinkable water, combat response, carcass/bone remains, and unobstructed mobile controls without developer labels.
- G018 live proof must use one naming contract: `US27LiveProofPassed` through `US36LiveProofPassed` on `ReplicatedStorage.G018FinalGateProof`. Older `G018US01LiveProofPassed` style names are stale.
- NPC ecosystem proof must show CPU-bounded brains, not all-NPC full scans forever. Live captures should include `BrainCycleBudget`, `BrainCycleTotal`, and no frozen/teleport-only static models.
- Predator social proof now needs a pack/regroup beat before idle wandering; prey social proof still needs herd cohesion; omnivore proof needs plant plus carcass paths; future nest story proof needs a real mating/nesting beat, not only spawned props.
- Asset search candidates remain references until previewed and inserted with reviewed scripts. Low-favorite foliage/nest results may be useful as kitbash material, but placeholder plates/blocks still fail this storyboard.

## Asset-first import queue -- 2026-05-31

Direct helper used: `node tools/roblox_search_direct.js search_assets '{"query":"...", "max_results":5}'`, followed by `preview_asset` on shortlisted IDs. Scripted assets are allowed and should be quarantined, read, and adapted to the story systems before being wired.

| Priority | SourceAssetId | Candidate | Storyboard job | Script review stance |
|---|---:|---|---|---|
| 1 | `10301700052` | `Dinosaur NPCS Pack REMASTERED` | Strongest current 50+ dinosaur roster lead for player/NPC mesh-backed bodies. | High risk; huge model, import to quarantine first, audit rig/scripts/collisions before gameplay wiring. |
| 2 | `9784445039` | `Dinosaur npc pack` | Backup 50+ dinosaur roster if the remaster pack is too noisy or brittle. | High risk; large alternate pack, inspect nested scripts/constraints before insertion. |
| 3 | `95133385212578` | `Pathfinding npcs AI Follow Navigate Enemy Script` | Behavior reference for predator chase, prey pathing, ambush, and apex threat. | High risk; read scripts and port cadence/aggro ideas into owned `NPCService`, do not raw-wire. |
| 4 | `5643011147` | `Animal Flock` | Herd/flocking reference for prey/background life. | Medium-high risk; inspect descendants and adapt only CPU-budgeted behavior. |
| 5 | `136851548154128` | `Attacking NPC Punch Faceless Robot Android` | Combat behavior reference for attack cooldowns, hit reaction, and aggro response. | High risk; behavior reference only until scripts are reviewed and rewritten to the dino story contract. |
| 6 | `95482576700075` | `Food Boxes Variety Pack Grocery Fruits Veggies` | Food variety for herbivore/omnivore forage gates and dressing density. | Medium risk; inspect pickup/eat scripts if present and adapt only fitting food prompt logic. |
| 7 | `2915526744` | `Low Poly Plant Pack` | Vegetation density candidate for nursery, jungle, swamp, and nest/home beats. | Medium-low risk; visual-first, still inspect collision and hidden scripts. |
| 8 | `82422796413615` | `Pond Pond Lily Rocks Reflection Peaceful Water Koi` | Drinkable-water visual candidate with pond/lily/shoreline read. | Medium-low risk; wire drinkability through owned `WaterService` volumes. |
| 9 | `131340001261404` | `Hydration GUI Script Thirst Water Drinkable UI` | Make drinkable-water interaction visible and teach thirst clearly on mobile. | High risk; import to quarantine, read `Script`/`LocalScript`, keep only reviewed logic/visuals that fit `WaterService`/HUD contracts. |
| 10 | `110801640375836` | `Monochrome White UI Icon Pack` | Replace emoji-heavy survival HUD/context affordances with readable mobile icons. | Low risk; visual pack, no direct script surfaced. |
| 11 | `128301661731715` | `Simple Health Bar GUI Display Vitality Meter Statu` | Compact HUD reference for health/growth/needs readability. | Low-medium risk; adapt visual patterns into owned HUD controllers. |
| 12 | `123830443378354` | `Dead Bacon Pork Meat Food Props 3D Model` | Meat/carcass prop reference for carnivore readability. | Low-medium risk; verify it reads as food/carcass, not novelty filler. |
| 13 | `5663348866` | `Visitor Center Fossils` | Bones/fossils/canyon dressing and post-eaten remains reference. | Medium risk; large decor pack, inspect collisions and hidden scripts. |

## Story/user-story gate audit — 2026-05-31

| Requested gate | Current source coverage | Remaining acceptance gap |
|---|---|---|
| 50+ random dino option | `StarterSpeciesSelectionTests.lua` asserts the random hatch pool stays at 50+ playable species; `HatchUITests.client.lua` renders four curated starters plus the random full-roster option and highlights the server-rolled species. | Needs live hatch proof that a random-roll species uses a renderable mesh path before exposing it in a release session. |
| Mesh-backed dino visuals, not Lego blocks | `StoryboardBeatValidation.lua`, `CharacterVisualServiceTests.lua`, and `StagedMeshMatrixTests.lua` assert staged/imported MeshPart visuals, invisible helper roots, asset-pack mesh resolution, and rejection of part-only mappings. | Live `Workspace.NPCs` still need screenshot/save proof that gameplay spawns are using those mesh-backed paths, not primitive placeholder bodies. |
| NPCs react to food/fights/mating/death | `E2E_PlayableLoopClosure.lua` covers food, fight, mating, and death reactions. `NPCServiceTests.lua` covers food/fight/mating social intent, pack regroup, herd behavior, fight-back, `DeathSignal`, prey fleeing death, hungry predators seeking carcasses, death settle, carcass creation, carcass eating, and bones state. | Live proof still needs visible NPCs reacting around a real mesh-backed death/carcass beat instead of static block stand-ins. |
| Drinkable water | `E2E_PlayableLoopClosure.lua` asserts shallow tagged water becomes drinkable and deep swim water is rejected as a drink target; Beat 5 placement/source tests keep fish inside valid swim water. | Live proof still needs terrain/quality mesh water with visible shoreline/depth, not just Part-based source tests. |
| Carcasses fall/remain/eaten to bones | `NPCServiceTests.lua` covers death settling/unanchoring, prey carcass creation, edible carcass tags, predator/player eating, consumed state, food tag removal, and bones replacement. `E2E_PlayableLoopClosure.lua` covers player-killed NPC carcass eating and readable bone remains. | Needs live capture of the fall/settle beat and the same carcass remaining long enough to be eaten in normal play. |
| Mobile UI portrait/landscape | `HatchUITests.client.lua`, `ClientHUDTests.client.lua`, and `MobileControlsTests.client.lua` cover compact scaling and basic phone layout; controls currently have a landscape phone geometry gate and hatch covers both orientations. | Still missing a combined portrait + landscape live proof where hatch cards, HUD, context action, and controls all coexist without blocking the dinosaur, food/water, threat, or traversal path. |

### Concrete remaining test gates — 2026-05-31

These are the missing gates after the current source-test audit. They should be added as behavior tests only when the underlying behavior is present, or as live-proof/storyboard gates when the blocker is visual acceptance.

| Gap | Required gate | Current stop condition |
|---|---|---|
| Death reaction live proof | Nearby mesh-backed NPCs visibly receive `DeathSignal`; prey flee and hungry carnivores scavenge the carcass in normal play. | Source E2E and integration gates now cover the behavior; live visual proof remains required. |
| Random 50+ hatch visual readiness | Server random-roll path proves the rolled species has a renderable mesh/staged asset before hatching in a release session. | Source tests prove the 50+ pool and predicate gate; live/staged proof must close the visual claim. |
| Mobile combined playability | One phone portrait and one phone landscape proof frame show hatch selector/HUD/action controls leaving the dinosaur, food/water target, threat cue, and traversal path visible and tappable. | Client geometry tests are necessary but not sufficient; live screenshots remain the release gate. |
| Asset-first NPC population | `Workspace.NPCs` live proof shows gameplay-spawned NPCs using reviewed mesh-backed dinosaur assets with CPU-bounded brain attributes. | Existing source gates reject block-only mappings; live spawn screenshots and save/reopen proof are still required. |
| Carcass fall/settle persistence | Normal combat capture shows the same defeated NPC falling/settling, remaining edible, then switching to bones after consumption. | Source tests cover settle/carcass/eat/bones state; visual timing persistence needs live capture. |

## Playable-loop E2E story gate

`src/ServerScriptService/Tests/E2E/E2E_PlayableLoopClosure.lua` is the source E2E gate for the first-session survival spine. It must stay aligned with this storyboard and prove these behaviors without relying on client-only labels:

| Story step | E2E gate |
|---|---|
| Hatch | Egg-state player cannot eat; repeated hatch input creates a hatched `utahraptor` state. |
| Movement | Egg-state player cannot sprint; hatched player can sprint, receives a faster `CurrentWalkSpeed`, then returns to awake ground movement after rest. |
| Eat/drink | Diet-valid food and validated shallow drinkable water restore hunger/thirst; swim/fish/deep water is rejected as a drink target; depleted food can respawn. |
| Sleep/rest | Resting sets a readable sleep state, advances age, restores stamina, and can return to awake. |
| Age/growth | Needs ticks advance `AgeSeconds`; growth reaches the next stage. |
| Death/respawn | Death records `DeathState="Dying"` and final age; respawn returns to an unhatched egg while preserving saved rewards. |
| NPC reactions | Prey flees the player; nearby NPCs stamp food/fight/mating/death reaction attributes; hostile NPCs fight back when the player is in range; hungry predators seek carcasses from death signals; player-killed NPCs leave edible carcasses that deplete to readable bone/carcass remains. |

Storyboard proof still needs screenshots, iPhone portrait/landscape playability captures, and saved-place persistence. The E2E gate is a behavior guard, not a substitute for visual acceptance.

## Story mode spine

The story is not quest-dialogue driven. The ecosystem is the quest-giver:

> Hatch alone → read hunger/thirst → learn safe food/water → grow → choose predator/prey behavior → survive living biomes → claim a nest/home → confront apex/city mystery → become a story-producing adult.

## Current starter identity contract

The first-session starter set is **Coelophysis, Parasaurolophus, Utahraptor, and Citipati**. Older Gallimimus/Triceratops/Velociraptor/Carnotaurus starter language is stale unless a doc is explicitly describing historical work.

| Starter | Diet/role read | First-session UX job |
|---|---|---|
| Coelophysis | Carnivore, fast small predator/scavenger | Teaches meat/carcass food, sprinting, and threat caution without apex fantasy. |
| Parasaurolophus | Herbivore, social grazer | Teaches safe foliage/water, herd safety, and readable non-combat survival. |
| Utahraptor | Carnivore, pack hunter | Teaches stalking, attack timing, stamina pressure, and predator/prey choice. |
| Citipati | Omnivore, nest-edge forager/scavenger | Teaches flexible food logic, scavenging, and the future nest/egg story vocabulary. |

All starter proof must show pre-hatch selection, post-hatch species continuity, correct diet icon, movement/role badge, and a real staged mesh or documented live-proof gap.

Every scene below must earn four kinds of value:

1. **Visual value:** what the player sees and remembers.
2. **Mechanical value:** what new action or rule the player learns.
3. **UI value:** what interface element makes the state legible.
4. **UX value:** what emotion/decision the player gets.

---

## Beat 0 — Egg wakeup in NurseryGrove

**Story purpose:** birth, vulnerability, first identity.  
**Player fantasy:** “I am a baby dinosaur, not a Roblox avatar.”

| Layer | Required value | Validated references |
|---|---|---|
| Visual | Egg shell, small dino body, warm protected grove, visible nest/home object. | G027 live insertion: `8895193` `G027_DinosaurNestEggs`, tagged/script-free/release-ready but live-only until saved. Search refs: `dinosaur egg` → `da5da35b-1cef-496f-a3be-ee2803d568e5`; `dinosaur egg nest` → `df69fe17-9e1c-4e69-bf24-bf7ed3f3c689`. Catalog clean candidates: `150068032` Scrambled Eggs in a Nest; `101855130` Egg Nest; `4630012038` EGG NEST; `151888976` Terrordactyl Egg Nest; `150059455` Nest and Eggs. |
| Mechanical | Hatch state, pre-hatch selection among Coelophysis/Parasaurolophus/Utahraptor/Citipati, starter safe zone, first growth stage. | `StarterSpeciesService.StarterOrder` and `HatchUIController.StarterSpecies` both use the current four-starter order; `SpeciesConfig.lua`/`SpeciesRoster.lua` provide Hatchling/Juvenile/SubAdult/Adult; `MapLayoutService.lua` has `NurseryGrove` and tutorial-safe food/water placements. |
| UI | Pre-hatch species selector, selected species card, diet badge, growth badge, compact hunger/thirst/stamina bars. | `HUDController.lua`; `HatchUIController.lua`; `MobileControlsController.lua`; `UIWireframeChecklist.md`; `HatchUITests.client.lua` covers selector options and selected-state highlight. |
| UX | Player chooses a dinosaur before cracking the shell, then immediately sees that exact selected hatchling replace the default avatar; player understands “eat/drink/grow” within 10 seconds. | Source proof exists for selection persistence and imported/staged egg/dino visuals. Live gap: screenshot/recorded proof for all four starters plus saved-place persistence of the G027 nest asset. |

**Storyboard frames**

1. **Black → choose:** shell view is muffled and calm; player sees starter dinosaur choices before the first crack.
2. **Select identity:** selected option shows species name, diet, and role cue clearly enough to distinguish Parasaurolophus foliage play, Citipati omnivore play, and Coelophysis/Utahraptor carnivore play before hatching.
3. **Crack:** tap/click/keyboard input cracks the selected egg; selector remains stable and does not obscure the prompt or meter.
4. **Reveal:** camera pulls back to the selected baby dino beside nest; species name and diet badge fade in and match the pre-hatch choice.
5. **Need pulse:** hunger/thirst bars gently pulse, not alarm-red.
6. **First goal:** food/water hint points to real fern/water or diet-valid meat, not a generic arrow or placeholder ball.

**Acceptance check:** live proof shows the pre-hatch selector, records the selected species, hatches without restart, and then proves the visible baby dino, species/diet UI, G027 or better nest/egg asset, readable safe food/water, and no default avatar all match that selection after save/reopen.

---

## Beat 1 — First food and water lesson

**Story purpose:** the body teaches the rules.  
**Player fantasy:** “I can tell what I can eat.”

| Layer | Required value | Validated references |
|---|---|---|
| Visual | Herbivore food is real fern/bush/fruit; carnivore food is visible carcass/bones; water is terrain water or convincing pond/shoreline. | G027 live insertion: `12630982706` `G027_PreHistoricPlantPack`, tagged/script-free/release-ready but live-only until saved. Search refs: `fern low poly` → `1d710ea1-f95e-4c6d-86d6-3e2674563392`; `animal carcass bones remains` → `98ad66c5-2481-4723-8ee0-85bd64bbf36d`; `dinosaur bone` → `8837548f-f8a2-4e15-ba67-be24558a2903`. Catalog clean fern candidates: `7979002756`, `117873391`, `6829786787`, `434184732`, `111535569365865`, `8773009280`, `14703400302`. Clean bone/fossil candidates include `137420276606883`, `83552391154369`, `14047690299`, `11573236999`. |
| Mechanical | Diet filtering; eat/drink restores stats and grants growth; invalid food gives readable denial. | `src/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua` diet target filtering; `MapLayoutService:ApplyFoodMetadata`; Food/Water service tests referenced in docs. |
| UI | “Snack/Drink” context button, distance text, diet-appropriate icon, depletion/respawn hint. | `MobileControlsController:BuildWaypointText`, `ClientBootstrap:FindNearestEatDrinkTarget`, `EatDrinkButton` behavior. |
| UX | Player sees the target itself and understands why it is valid. The sense cue is a diet-aware pulse/highlight/distance/icon, not an arrow-only waypoint. | G027 closes the catalog-only plant gap for a first forage source. Remaining live gaps: saved/persisted placement, carnivore carcass proof, water prop proof, and touch E2E across herbivore, carnivore, and omnivore starters. |

**Storyboard frames**

1. **Herbivore path:** baby Parasaurolophus approaches fern cluster with soft green shimmer.
2. **Carnivore path:** baby Coelophysis or Utahraptor approaches a small safe carcass cache; meat/bone silhouette is unmistakable.
3. **Omnivore path:** baby Citipati can read both foliage and safe scraps without weakening diet validation.
4. **Water path:** shoreline and reflection make drinkable water obvious before UI appears.
5. **Feedback:** bite/slurp audio + small growth sparkle + bar fill; no giant text spam.

**Acceptance check:** screenshot can be understood without developer labels: food looks like food, water looks like water, and UI confirms action.

---

## Beat 2 — First predator/prey choice in FernPlains

**Story purpose:** survival stops being tutorial and becomes ecology.  
**Player fantasy:** “I am hunted or I am hunting.”

| Layer | Required value | Validated references |
|---|---|---|
| Visual | Open plains, herds, readable predator silhouettes, real dino meshes instead of primitive blobs. | Validated staged assets: live `Workspace.dinosaur` has clean mesh groups for Herbivores/Carnivores/Omnivores/Aquatic. Search ref: `rigged dinosaur` → `ecb52c0b-842b-4101-bd90-246afe79029c`. Manifest clean dinosaur candidates: `18759347676` Rigged Dinosaur Models; `129426942556570` Rigged Dinosaur Models 2; `17490043673` Dinosaur; `5151489661` Dinosaur. |
| Mechanical | Sneak/flee/sprint/attack decision; stamina matters; pack/herd proximity matters. | Current starter contract: Coelophysis fast small carnivore, Parasaurolophus social herbivore, Utahraptor pack hunter, Citipati omnivore scavenger. |
| UI | Threat indicator, stamina warning, target health only after engagement, call button. | Current HUD/mobile controls include Attack, Sprint, Call, RestHide; story docs call for threat UI. |
| UX | Player learns “not every dino is safe” by sight and sound, not by surprise stat loss. | Needs roar/call audio and telegraphed lunge VFX. |

**Storyboard frames**

1. **Plains silhouette:** herbivore herd visible across grass, predator shadow at treeline.
2. **Choice:** sprint path to cover vs stalk path toward prey.
3. **Contact:** lunge telegraph, dust/impact burst, damage number.
4. **Aftermath:** downed prey becomes carcass food, not a disappearing model.

**Acceptance check:** one screenshot shows predator/prey readable at distance; one combat capture shows impact VFX + health feedback.

---

## Beat 3 — Growth moment and role reveal

**Story purpose:** survival pays off with visible change.  
**Player fantasy:** “I am becoming stronger and different.”

| Layer | Required value | Validated references |
|---|---|---|
| Visual | Scale-up, stronger posture, new body variant or clear size change. | `SpeciesConfig.lua` growth stages for all species; staged mesh library can supply species base meshes, but growth variants are not proven. |
| Mechanical | Stage-up changes stats, rest/sleep slows needs and restores stamina/health, age advances through the survival loop, ability affordance and diet/role stay clear. | `SpeciesConfig.lua` BaseStats and Abilities per species; `SurvivalService:SetResting` and `ApplyNeedsTick`; `E2E_PlayableLoopClosure.lua`. |
| UI | Growth badge, role card, rest/sleep cue, age cue, unlock toast, ability highlight. | `HUDController:BuildGrowthBadge`, `BuildRoleCard`, `BuildDietGuidance`, `BuildStoryCue`; `ClientHUDTests.client.lua`. |
| UX | Player feels earned progress, not just number inflation. | Needs animation/VFX/audio to sell transformation. |

**Storyboard frames**

1. **Rest after feeding:** player finds cover, sleep/rest cue appears, age continues to tick, and hunger/thirst slow instead of freezing.
2. **Body pulse:** camera low, body scales, new ability icon lights.
3. **World reaction:** nearby small prey flee or herd call responds.
4. **Bad ending clarity:** if the player dies, the story cue and server state say "Dying", record final age, and respawn returns to egg without losing account progress.

**Acceptance check:** before/after screenshots prove visual growth and UI state change; source E2E proves movement/needs/eating, rest/sleep recovery, age progression, dying state, death age, and respawn persistence.

---

## Beat 4 — JungleBasin ambush and pack call

**Story purpose:** dense terrain introduces uncertainty and sound.  
**Player fantasy:** “The world is alive around me.”

| Layer | Required value | Validated references |
|---|---|---|
| Visual | Dense canopy, vines/logs, partial occlusion, ambient small creatures. | Search refs: `low poly forest pack` → `bf9d61b5-b97f-4759-a0bc-c8c3d2fd80d4`; manifest fern/tree candidates; `jungle vine` entries in `UniqueImportPilotReport.lua`. |
| Mechanical | Calls reveal allies/threats; ambush risk; rest/hide has a reason. | `CallService.lua`; `RestHideButton`; `SpeciesConfig` CallSet. |
| UI | Directional sound pulse, call type label, low-noise proximity hint. | `ClientBootstrap:CreateLocalCallPulse`; `MobileControlsController` icon-first controls. |
| UX | Player uses sound and cover instead of a minimap. | Needs spatial audio and less-misleading waypoint/food direction. |

**Storyboard frames**

1. **Cover corridor:** camera sees only partial path through vines.
2. **Distant call:** pulse ring appears from offscreen direction.
3. **Ambush:** raptor silhouette emerges; player chooses hide/call/flee.

**Acceptance check:** capture shows dense environment plus directional call/alert UI without clutter.

---

## Beat 5 — SwampDelta swim, fish, and oxygen risk

**Story purpose:** water becomes a biome, not a square plate.  
**Player fantasy:** “Water is useful, scary, and species-specific.”

| Layer | Required value | Validated references |
|---|---|---|
| Visual | Muddy channels, lily pads, reeds, cypress, fish movement, Spinosaurus silhouette. | Search refs: swamp/water plant categories in docs; clean catalog candidates: `86198817809169` Lily Pad Frog Green Water Lily; `95359664633430` Koi Pond Bridge Water Rocks Lily Aesthetic; `12598461005` Realistic Southern Swamp Trees Pack; `18986634714` Swamp Trees. |
| Mechanical | Swim mode, oxygen drain/recovery, fish/carcass feeding, semi-aquatic advantage. | `SpeciesConfig.lua` Spinosaurus has `MovementModes.Swim=true`; `MapLayoutService.ShallowWater` defines swim/fish zones. |
| UI | Oxygen appears only when relevant; Swim button appears only for species/near water; danger pulse when submerged too long. | `HUDController` Oxygen behavior; `MobileControlsController` optional Swim. |
| UX | Non-swimmers fear deep water; Spinosaurus feels special. | Current docs say swim remains inert/needs proof. |

**Storyboard frames**

1. **Shoreline read:** reeds/lily pads tell player water is interactable.
2. **Entry:** Spinosaurus enters water, Swim button lights.
3. **Under-risk:** oxygen UI appears, fish target flashes subtly.
4. **Exit:** water trails/drip sound; successful fish catch feeds hunger.

**Acceptance check:** screenshot proves water is terrain/quality mesh, not square generated parts; UI shows oxygen only during swim/submerge.

---

## Beat 6 — RedstoneCanyon apex trial

**Story purpose:** player enters predator territory and learns respect.  
**Player fantasy:** “This is where apex dinos rule.”

| Layer | Required value | Validated references |
|---|---|---|
| Visual | Red cliffs, fossils, bones, dry scrub, high contrast silhouettes. | Catalog clean candidates: fossil/bone ids above; canyon/rock manifest entries include rock/cliff/boulder/red canyon/sandstone categories; source docs say Redstone needs refined queries. |
| Mechanical | Apex threat radius, heavy attacks, flee routes, fossil/DNA reward. | `SpeciesConfig.lua`: Tyrannosaurus Apex; Carnotaurus RedstoneCanyon; fossils/DNA in design docs. |
| UI | Apex warning, fossil discovery popup, damage/threat feedback. | Needs UI polish; current HUD can show survival stats but not full apex storytelling. |
| UX | Player feels small until grown; canyon is a skill gate. | Requires terrain verticality and sound cues. |

**Storyboard frames**

1. **Fossil reveal:** bones half-buried in red sand; pickup prompt appears.
2. **Roar:** apex warning UI trembles; distant T-Rex silhouette.
3. **Decision:** hide behind rock, flee to route, or challenge as adult.

**Acceptance check:** screenshot proves canyon identity and fossil prop; UX capture shows threat warning before damage.

---

## Beat 7 — ApocalypticCity mystery

**Story purpose:** world story payoff: nature reclaiming old human ruins.  
**Player fantasy:** “What happened here?”

| Layer | Required value | Validated references |
|---|---|---|
| Visual | Ruined buildings, wrecked cars, concrete barriers, overgrowth, fossil/lab hints. | Clean catalog candidates: `108178603114720` Destroyed Building Ruins; `99839530484936` Destroyed City Pack; `73556199661206` City Building Ruins; wrecked car clean candidates `8027653806`, `9213436305`, `126412586507734`, `103158815948907`, `128860103419474`. Search ref: `wrecked car` → `c05bf215-a3d4-47ed-88b7-3d1da14a7807`. |
| Mechanical | High-risk food, apex territory, fossil/DNA progression, endgame discovery. | `MapLayoutService` has OldEden/ApocalypticCity high-risk food; design docs describe fossils/DNA. |
| UI | City discovery popup, lore-light environmental label, danger state. | `StarterGui/README.md` requires CityDiscoveryPopup. |
| UX | Story through environment, not NPC dialogue. Player wants to explore but knows it is dangerous. | Needs placement density and horizon landmarks. |

**Storyboard frames**

1. **Approach:** skyline silhouette beyond grass/swamp boundary.
2. **Street crossing:** broken car, vines, concrete, bone pile.
3. **Discovery:** popup names “Old Eden” / city mystery, not a quest marker.
4. **Endgame:** apex predator patrols between ruins.

**Acceptance check:** screenshot shows recognizable city ruin story in one frame: wreck, wall, overgrowth, predator/fossil hook.

---

## Beat 8 — Nest, lineage, and alpha loop

**Story purpose:** turn survival into ownership and legacy.  
**Player fantasy:** “This is my territory/home.”

| Layer | Required value | Validated references |
|---|---|---|
| Visual | Nest object, egg, parent/offspring scale contrast, territory landmark. | G027 live insertion `8895193` supplies the current nest/egg candidate; egg/nest search refs and clean catalog candidates above remain backups until saved proof is captured. |
| Mechanical | Adult-only nesting, respawn/home state, optional alpha challenge. | `NestService`/`SurvivalService` mentioned in status docs; SpeciesConfig adult growth; antigravity roadmap proposes alpha loop. |
| UI | Nest prompt, home marker, egg status, alpha challenge warning. | Needs a diegetic home marker proof distinct from the food/water sense-guide. |
| UX | Player has a reason to return and defend territory. | Must avoid grief-heavy PvP around hatchlings. |

**Storyboard frames**

1. **Build/claim:** adult chooses sheltered nest site.
2. **Egg/home:** egg visual appears; respawn/home marker becomes diegetic.
3. **Threat:** predator approaches; player chooses defend/call/flee.
4. **Alpha:** optional late-game ritual/territory challenge, not mandatory.

**Acceptance check:** screenshot shows real nest/egg asset and UI prompt after save/reopen; no default placeholder box/ball.

---

## Asset quality and priority gates

### Gate A — Visual asset must be readable in-world

Reject if the player cannot identify the object without labels:

- Food must look like fern/bush/fruit/meat/bones.
- Water must look like water and have visible shoreline/depth.
- Nest must look like nest/egg.
- Dinosaur must be recognizable silhouette and species-appropriate.
- City ruin must tell “old human world” through shape/material.

### Gate B — Mechanical asset must connect to a rule

Every asset must answer: “What can the player do with this?”

- Fern/bush → eat/growth.
- Carcass/bones → carnivore food/scavenge/fossil clue.
- Water/lily/reed → drink/swim/oxygen/fish.
- Nest/egg → hatch/respawn/home.
- Ruin/wreck/fossil → discovery/DNA/endgame risk.
- Dino mesh → playable/NPC identity, hitbox, animation.

### Gate C — UI/UX asset must reduce confusion

Prefer assets/UI that replace ambiguous homemade cues:

- Replace misleading direction arrow with target-aware scent/sense pulse + distance + diet icon.
- Replace “Food/Water” text with icon + visible target + context verb.
- Replace invisible helper parts with visible interactive models plus hidden query helpers if needed.
- Replace noisy generic HUD with state-specific feedback: hunger low, water nearby, threat near, oxygen active, growth ready.

### Gate D — Creator asset trust

Current local metadata is not enough to claim “high rated.” For each shortlisted Creator Store asset:

1. Verify rating/favorites/creator reputation in Studio/Creator Store.
2. Insert primary result only in edit mode, serially.
3. Strip uncontrolled scripts and looped/autoplay audio; keep executable imports only after source review, ownership, authority/sandbox proof, and focused tests.
4. Tag `SourceAssetId`, `AssetManifestId`, `CreatorStoreOnly`, `ImportedVisibleAsset`.
5. Screenshot in staging and in intended gameplay context.
6. Only then promote to storyboard “approved visual.”

---

## Highest-impact next storyboard refinements

1. **G027 persistence board** — save/reopen the live `G027_AssetBackedStoryBatch`, then capture nest/egg, plant, and HUD icon proof in intended gameplay context.
2. **Food/water sense UX board** — prove `SenseGuideController` with scent pulse, diet icon, target highlight, and visible food/water props for herbivore, carnivore, and omnivore starters.
3. **Hatch selection identity board** — Coelophysis, Parasaurolophus, Utahraptor, and Citipati each need a real mesh reference, diet/role cue, movement expectation, selected-state styling, and proof that the post-hatch dinosaur matches the pre-hatch choice.
4. **Species identity board** — every playable species gets a real mesh reference, role card, movement mode, attack style, food type, and sound palette.
5. **Asset-backed biome insertion board** — for each biome, pick 8–12 visual anchors from catalog/search refs, then record whether they are only candidates, inserted live, scattered by `WorldDressingService`, screenshot-proven, and saved/persisted.
6. **City mystery board** — pick ruins/wrecks/fossils and define the environmental story sequence.
7. **Nest/alpha board** — define adult ownership loop, respawn rules, anti-grief UX, and home marker visuals.

## Open questions / limits

- Ratings are **not locally available** in the repo evidence. Asset rating must be checked via Creator Store/Studio before claiming an asset is high-rated.
- Live `Workspace.dinosaur` staging contents are validated visually/structurally, but not all species names/source IDs are persisted in repo. Starter proof should prioritize the current four curated starters before broad roster polish.
- Other agents may be editing concurrently; re-check `git status` and live Studio state before turning storyboard candidates into release claims.
- This document intentionally does not place assets, run imports, or modify gameplay code.
