# eggBreakers — Master Production Plan & Swarm Orchestration Spec

> A single source of truth for taking eggBreakers from "mechanically real but visually broken" to a polished, prod-ready dinosaur survival game. Structured so independent agents can own a workstream in parallel. Every task has an ID, an acceptance criterion, and an asset/source note.

## Current Authoritative Snapshot — 2026-05-30 (validated via live Studio)

> Freshest authoritative state, validated via a live Studio test run by the orchestrator. Wording follows `docs/G026/PlanningCountContradictionReport.md`: `catalogedSourceAssetIds=500` is the **catalog** (unique SourceAssetIds), NOT 500 live imports; `releaseReadyVisibleAssets=22/500` is the **release gate**. All numbers elsewhere in this doc are DATED HISTORY unless restated here.

- **Assets:** `releaseReadyVisibleAssets=22/500`. The `500` is `catalogedSourceAssetIds` — a catalog of cataloged unique SourceAssetIds, not live imports. Historical/contradictory counts (22, 23, 34, 79, 215, 221, 227 /500) are dated history only; 22/500 supersedes them.
- **Tests:** 176 total / 143 passed / 34 failed.
  - 15 are PRE-EXISTING module-load failures (test modules error on require, exist at HEAD, NOT caused by the recent merge): CombatServiceTests, FoodServiceTests, NPCServiceTests, CombatFormulaTests, 4 Performance budget tests (AssetCollisionBudgetTest, LoopBudgetTest, NPCCountBudgetTest, ParticleBudgetTest), Placement NPCSpawnValidation + SpawnPlacementValidation, E2E_CarnivoreSurvival + E2E_PlayableLoopClosure, G013FinalGate, G014FinalGateSuite, Security ExploitSafeZoneAttackTests.
  - 19 are content/release-gate failures: G015/G016/G018 FinalGate (500-asset count + live-proof gates), AssetManifestValidation (placeholder primitives in Workspace.dinosaur), FlightSwimOxygenServiceTests x2, SpeciesConfigTests (playable-species cap), TestRunner coverage.
- **Asset-quality disconnect (visual + tree audit):** `Workspace.dinosaur` is a STAGING PEN holding 56 genuine textured MESH dino species (Herbivores 16, Carnivores 28, Omnivores 4, Aquatic 8; ~5-10 MeshParts each, clean, no unions) that are UNUSED in gameplay. `Workspace.NPCs` spawns are PRIMITIVES (88-172 Parts, 0 MeshParts each). The player character is the DEFAULT Roblox R15 avatar (SpeciesId=nil, no dino visual applied). There is NO velociraptor mesh staged (nearest staged: Utahraptor, Microraptor, Coelophysis). A junk model named "Delete(and delete thumbnail)" exists.
- **Just-merged code (on main):** pteranodon rename (was pterodactyl); spinosaurus SemiAquatic NPC spawn kind; combat hit VFX (CombatFeedbackController + ReplicatedStorage.ImportedAssetLibrary.CombatHitVFXTemplate); nest respawn (ServerMain + SurvivalService); water drinkable validation (WaterService); MapLayoutService WorldBuilder hooks (BiomeCenters/GroundPlace) + a syntax fix.

See also `eggBreakers_STATUS.md` for the consolidated status page.

---

**Status snapshot (historical — see Current Authoritative Snapshot above; validated via Studio MCP):** 199/228 tests passing · 50 anchored primitive NPCs · 2 new mesh dino packs (5,767 MeshParts, 744 enabled legacy scripts) · map ~6% dressed · flight/swim scope-frozen · all `AnimationIds` empty.

---

## 1. Clean Design Goals (the north star)

These are the non-negotiable qualities every task is measured against.

1. **Living world, not a diorama.** Dinosaurs walk with physics and animation — never teleport, slide, or float. Every creature reads as alive.
2. **Natural, legible biomes.** Six distinct biomes that look hand-crafted: varied terrain, dense dressing, believable water, smooth traversal — no flat green void, no far-apart empty gaps.
3. **High-quality assets, queried not hand-built.** Source rigged creatures and environment from well-rated Creator Store packs. Keep mesh + rig only; behavior comes from our engine. No primitive/CSG stand-ins, no JPOG rips in the shipping build.
4. **Readable, responsive gameplay.** Combat, growth, hunger/thirst, and threat are all visible through a clean survival HUD with feedback (hit, heal, danger, progression).
5. **Honest, shippable content.** The asset-honesty audit passes legitimately; nothing tagged as imported that isn't; release gates green.
6. **Scoped & coherent.** A clear slice of species across all three movement modes — ground, **flying, and aquatic** — and 6 biomes. Flight and swim are first-class mechanics to build properly (real physics movement), not faux-Y floats. Cut only true noise, not core traversal.

---

## 2. Current-State Truth — Broken Implementation Registry

Each row: severity, the problem, the evidence, and the disposition (**FIX** in place / **REPLACE** with import / **CUT or GATE** / **BUILD** new).

| ID | Severity | System | Problem (evidence) | Disposition |
|----|----------|--------|--------------------|-------------|
| BR-01 | Critical | NPC movement | `PivotTo(CFrame.lookAt())` in 8-stud steps on a 1s tick → teleport. NPC bodies fully anchored, no Humanoid. | FIX (rework to Humanoid:MoveTo) |
| BR-02 | Critical | NPC animation | All `SpeciesConfig.AnimationIds` empty; NPCs have 0 Animation objects / no Animator. | BUILD + REPLACE (use pack rigs) |
| BR-03 | Critical | Playable models | `ModelPaths` point at primitive block/union sets, not real mesh dinos. | REPLACE (wire new packs) |
| BR-04 | Critical | Imported scripts | **758 Workspace scripts (744 enabled)** from imported packs (qPerfectionWeld/RandomlyWalk/AttackPeople/README) — security + perf + behavior conflict. Live-only; not in repo `src/`. | FIX (strip/quarantine) |
| BR-05 | High | Map spread | Biomes far apart with empty traversal (test: "outer biome centers condensed"); terrain flat & unnatural. | FIX + REPLACE (re-layout + dressing) |
| BR-06 | High | Biome dressing | Trees are invisible-helper trunk/canopy parts violating naming rules; map ~6% dressed. | REPLACE (nature packs) |
| BR-07 | High | Water | Visible generated Parts missing release tags; `FernLakeSwimZone` too deep (collision test). | FIX + REPLACE (water material/mesh) |
| BR-08 | High | Food sources | Placeholder/"ball" food, starter food overlap, omnivore/herbivore metadata mismatch. | REPLACE (foliage/carcass assets) + FIX metadata |
| BR-09 | High | Combat feel | Pure server attribute math; no telegraph, hit feedback, or NPC health UI. | BUILD |
| BR-10 | High | Floating objects | Anchored parts placed at fixed Y, not grounded to terrain → visible floaters. | FIX (raycast-to-ground placement) |
| BR-11 | High | Flight | `FlightService` gates on a flag nothing sets → always `flight_locked`; NPCs fake-fly via Y on anchored parts; no species has `Flight=true`. Flight is a **wanted mechanic** but currently non-functional. | FIX + BUILD (real flight for flyers) |
| BR-12 | High | Swim/Oxygen | Swim never triggers (no species `Swim=true`); `OxygenService.MaxOxygen=100` vs config `60` — two sources of truth. Swim is a **wanted mechanic** but currently inert. | FIX + BUILD (real swim for aquatics) |
| BR-13 | Medium | Apex event | Apex/threat logic exists but no player-facing signal; partially wired. | BUILD (UI) + FIX |
| BR-14 | Medium | Carnotaurus | Config hack `VisualOrientationCorrection PitchDegrees=180` to fix inverted import. | REPLACE (clean rig) |
| BR-15 | High | Release gates | Need ≥500 honest imported visible assets + live-proof artifacts (G015/G016/G018). | FIX (after asset pipeline) |
| BR-16 | Medium | E2E loop | "player can attack registered dinosaur NPC" fails — record lookup vs instance mismatch. | FIX |
| BR-17 | High | Audio | Startup buzzing: ~20 looped + 6 auto-playing Sounds embedded in free-model dinos (e.g. `Gigazilla` Sound vol **7.9** looped; multiple `TrueNeck/Head.Sound`) all fire at once via 82 enabled sound-playing pack scripts → loud drone that fades as scripts settle. | FIX (strip pack sounds+scripts) |
| BR-18 | High | Audit policy | The import audit **forbids MeshPart roots as release-ready** and quarantines them as "mesh excluded" — directly conflicts with shipping the user's new genuine **mesh** dino packs. Policy must change or the real assets will never count toward 500. | DECISION + FIX (audit rule) |

---

## 3. Parallel Workstreams (swarm-ownable)

Each workstream is independently ownable. Cross-stream dependencies are called out so the orchestrator can sequence waves. Tasks use `WS-letter.number`.

### WS-A — Asset Pipeline & Cleanup  *(owner: "Asset Steward")*
Foundational; unblocks B, C, D. Make imports safe, honest, and organized.

| Task | Goal | Acceptance criterion | Asset/source |
|------|------|----------------------|--------------|
| A.1 | Strip & quarantine pack scripts | Run `AssetImportAuditService:AuditAndRepair({mutate=true})`; 0 enabled executable scripts remain in Workspace dino packs | existing service |
| A.2 | Establish a clean import convention | Every shipping asset lives under `Map/ImportedAssets` or a species library, tagged `SourceAssetId` + `AssetManifestId` + `CreatorStoreOnly` | AssetManifest |
| A.3 | De-dup SourceAssetIds | No duplicate SourceAssetId inflates counts (fixes AssetImportAuditStateTests) | audit |
| A.4 | Curate species rig set | One canonical rigged mesh per playable species (Hatchling→Adult scale), Humanoid + Animator present | Creator Store query (§5) |
| A.5 | Retire primitive sets | Old block/union `Imported_Playable_*` sets removed from shipping path | — |
| A.6 | Silence audio spam | Strip/disable all embedded looped & auto-play Sounds from imported packs (fixes startup buzzing BR-17); keep only intentional, curated SFX | sound sweep |
| A.7 | Resolve MeshPart audit policy | Decide how genuine mesh imports count toward release (BR-18); update `AssetImportAuditService` so quality mesh packs are release-ready, not auto-quarantined | audit rule |

### WS-B — NPC Movement & Animation  *(owner: "Locomotion")*
Depends on A.4. The core "make it alive" stream.

| Task | Goal | Acceptance criterion | Notes |
|------|------|----------------------|-------|
| B.1 | Unanchor + Humanoid locomotion | NPCs move via `Humanoid:MoveTo`; no PivotTo stepping | rewrite NPCService:MoveToward |
| B.2 | Continuous steering | Motion interpolates every Heartbeat; brain stays on 1s decision tick | decouple tick from motion |
| B.3 | Ground clamping | NPCs stand on terrain via HipHeight; no fixed-Y floaters | raycast spawn |
| B.4 | NPCAnimationService | NPCState → animation track (Idle/Walk/Run/Eat/Attack/Hurt/Death); speed-blended | new module |
| B.5 | Populate AnimationIds | All `SpeciesConfig.AnimationIds` filled from pack/authored anims | config |
| B.6 | Server-side replication | Anims play on server Animator; all clients see them, no desync | — |
| B.7 | Death→ragdoll→carcass | Clean death anim → settle → carcass food source | NPCService:Transition |

### WS-C — Map & Environment Naturalization  *(owner: "Worldsmith")*
Depends on A.2. Fix the flat, sparse, far-apart world.

| Task | Goal | Acceptance criterion | Asset/source |
|------|------|----------------------|--------------|
| C.1 | Re-layout biome centers | Outer biomes condensed to playable range (passes BiomePlacementValidation) | MapLayoutService |
| C.2 | Terrain sculpting | Each biome has elevation/variation, not flat plane | Terrain + heightmaps |
| C.3 | Biome dressing density | Each biome dressed with trees/rocks/foliage to target count; no invisible-helper trees | nature packs (§5) |
| C.4 | Ground all props | Every placed prop raycast-grounded; zero floaters (BR-10) | placement util |
| C.5 | Landmarks per biome | Volcano/mountain/ruins/forest vista materialized (passes scenic test) | landmark assets |
| C.6 | Naming/storage compliance | All dressing passes AssetManifestValidation | audit |

### WS-D — Food & Water Quality  *(owner: "Ecology")*
Depends on A.2.

| Task | Goal | Acceptance criterion | Asset/source |
|------|------|----------------------|--------------|
| D.1 | Replace placeholder food | No "ball"/placeholder food; herbivore food = real foliage meshes | foliage packs |
| D.2 | Fix food metadata | Omnivore/herbivore Diet tags consistent (passes FoodSource tests) | config |
| D.3 | Fix starter food spacing | Compact-but-non-overlapping near spawn | placement |
| D.4 | Believable water | Water uses Terrain water or quality mesh; `FernLakeSwimZone` depth corrected; release tags present | WaterService |
| D.5 | Carcass visuals | Carnivore carcasses use a clean mesh, not block | bone/carcass asset |

### WS-E — Combat, Gameplay Feel & UI/UX  *(owner: "Feel & HUD")*
Depends on B (for anim hooks). The part we **design**, not import.

| Task | Goal | Acceptance criterion | Notes |
|------|------|----------------------|-------|
| E.1 | Survival HUD redesign | Clean hunger/thirst/stamina/oxygen/health + growth-stage meter | StarterGui rework |
| E.2 | Attack telegraph + anim | Wind-up before damage; readable | CombatService + client |
| E.3 | Hit feedback | Damage numbers, hit flash, impact VFX, SFX, camera shake | HUDController |
| E.4 | NPC health/threat UI | Overhead health on damaged NPCs; apex-threat indicator | client |
| E.5 | Growth/progression UX | Visible stage-up moment, DNA/unlock feedback | ProgressionService |
| E.6 | Fix E2E attack bug | BR-16 resolved; test green | NPCService lookup |
| E.7 | Mobile controls pass | Touch controls usable for all core actions (gate proof) | MobileControlsController |

### WS-F — Scope & Coherence  *(owner: "Director")*
Cross-cuts everything; do first as a decision gate.

| Task | Goal | Acceptance criterion |
|------|------|----------------------|
| F.1 | Lock the slice | Decision recorded: species roster + 6 biomes, **including ground, flying, and aquatic movement modes** |
| F.2 | Make flight real | BR-11 resolved: at least one flyer species with `Flight=true`; `FlightService` unlock actually granted; real airborne movement (BodyVelocity/AlignPosition) for players AND NPCs — no faux-Y float; consistent across config/NPC/services |
| F.3 | Make swim real | BR-12 resolved: at least one aquatic species with `Swim=true`; swim triggers on real water bodies; Oxygen/drowning loop active; **unify MaxOxygen to one constant** |
| F.4 | Single source of truth | Each stat/flag (incl. movement modes) defined once (no config vs service drift) |
| F.5 | Lift scope-freeze | Update `Constants.ScopeFreeze` so Flyers/Aquatics are no longer forbidden once F.2/F.3 land; adjust gate tests accordingly |

### WS-G — Story & Narrative Design  *(owner: "Narrative")*
Independent; informs C (biome theming) and E (UX tone). See §4.

| Task | Goal | Acceptance criterion |
|------|------|----------------------|
| G.1 | World premise & tone | One-paragraph premise + tone guide locked |
| G.2 | Biome story arc | Each of 6 biomes given a narrative role + progression beat |
| G.3 | Storyboards | Visual storyboards for the core loop & first-session journey (see §4) |
| G.4 | Gameplay-from-story | Distilled mechanic list each justified by a story beat & backed by an asset |

### WS-H — Release Gate & Proof  *(owner: "QA Gate")*
Depends on A, C, D. Final.

| Task | Goal | Acceptance criterion |
|------|------|----------------------|
| H.1 | Asset count to target | ≥500 honest release-ready imported visible assets |
| H.2 | Capture live proofs | MobileProof / RBXLPersistence / FreshAllCategory artifacts attached |
| H.3 | Full suite green | 228/228 (or re-baselined) passing |

---

## 4. Story Design & Storyboards

### 4.1 Premise (G.1)
You hatch into a world after the old order has fallen — a lush, dangerous land reclaiming a ruined human city at its edge. You are a single dinosaur fighting the oldest story there is: **eat, drink, grow, survive, and don't get eaten.** Each biome you survive pushes you from a hidden nursery toward the apex-ruled frontier. No quests, no NPCs handing out tasks — the ecosystem *is* the story.

### 4.2 Tone
Grounded natural-history awe meets survival tension. Beautiful, not cartoony. Quiet nursery → tense plains → hostile canyon/city. The "Apocalyptic City" is the only human trace — overgrown, ambiguous, never explained.

### 4.3 Biome Story Arc (G.2) — also the difficulty/progression curve

| Order | Biome | Story role | Beat / first-time feeling | Threat |
|-------|-------|-----------|---------------------------|--------|
| 1 | NurseryGrove (safe) | Birth & tutorial | "I'm small and new; this is safe." | None |
| 2 | FernPlains | First independence | "Open world, herds, first real hunger." | Low |
| 3 | JungleBasin | Hidden danger | "Cover, ambush, pack predators." | Medium |
| 4 | SwampDelta | Scarcity & navigation | "Hard terrain, water everywhere, drowning risk." | Medium |
| 5 | RedstoneCanyon | The frontier | "Apex territory; everything is bigger." | High |
| 6 | ApocalypticCity | The mystery / endgame | "What happened here? The top of the food chain rules ruins." | Apex |

### 4.4 Storyboard — First Session Journey (G.3)
A six-panel arc the team can illustrate and build toward:

1. **Hatch.** Egg cracks in NurseryGrove dawn light. Camera pulls back to reveal a small dinosaur. UI fades in (hunger/thirst calm).
2. **First needs.** Player nibbles foliage, drinks at a shallow pool. Tutorial prompts via diegetic HUD, not popups.
3. **Leaving safety.** Crossing the NurseryGrove boundary into FernPlains; a herd of gallimimus scatters — the world reacts to you.
4. **First threat.** A predator call echoes; threat indicator pulses; player flees or hides. Stamina matters.
5. **Growth.** After feeding, a visible stage-up: the dinosaur grows, stats rise, new ability unlocks. Earned power.
6. **The horizon.** Camera lingers on the distant canyon/city skyline — the promise of where survival leads. Loop hook.

### 4.5 Distilled Gameplay (G.4) — each mechanic justified & asset-backed

| Mechanic | Story justification | Asset need (query high-rated) |
|----------|--------------------|--------------------------------|
| Hatch → grow (4 stages) | Coming-of-age survival arc | Rigged species at 4 scales |
| Hunger/thirst/stamina | The body's clock | Foliage + water assets |
| Predator/prey AI + herds | The ecosystem as antagonist | Rigged predators/prey + anims |
| Threat/flee/hide | Tension beats | VFX/SFX + HUD |
| Combat (bite/claw/headbutt) | Earn your place | Attack anims + impact VFX |
| Apex events | Endgame pressure | Apex roar SFX + screen UI |
| Biome traversal | The journey outward | Nature/landmark packs |

---

## 5. Asset Sourcing Plan (query, don't build)

Creator Store searches validated live through the MCP. Strong category matches returned:

| Need | Query | Returned types (confirmed) | Use |
|------|-------|----------------------------|-----|
| Playable/NPC dinos | "rigged animated dinosaur" | dinosaur, creature, monster, npc | WS-A.4, WS-B |
| Creature animations | "dinosaur creature animation pack walk run idle" | dinosaur, creature, npc, pack | WS-B.5 (fills empty AnimationIds) |
| Biome dressing | "low poly nature trees rocks environment pack" | tree, landscape, plant, environment, rock, nature pack, forest, mountain, nature | WS-C |
| Food foliage | "low poly plants ferns bushes foliage food" | plants, vegetation, fern, flowers | WS-D |
| Custom sky | "skybox sky atmosphere" | skybox, background image | WS-C.4 atmosphere |
| Boundary ring | "stone wall fence boundary barrier ruins" | structure, fence, wall, building, castle wall | WS-C.3 |
| Combat VFX | "impact hit blood particle VFX effect" | effect, blood splatter, blood, explosion | WS-E.3 |
| City rubble/vehicles | "rubble debris wrecked car ruins destroyed" | vehicle, car, scene, environment, prop | WS-C.5 (ApocalypticCity) |
| Creature SFX | "dinosaur roar growl sound" | ◇ run dedicated Audio search | WS-E (empty `Sounds`) |
| Terrain / water / egg-nest | refine queries | ◇ use Terrain tools; audio index separate | WS-C / WS-D |
| UI/HUD | n/a | **3D-only store — design in-house** | WS-E |

**Sourcing rule:** insert via `insert_from_creator_store`, immediately run A.1 (strip scripts) + A.2 (tag), keep mesh+rig only, verify license is free/commercial-safe, drive all behavior from our services.

---

## 6. Parallel Execution Waves (for the orchestrator)

```
Wave 0 (decide):      WS-F (scope), G.1–G.2 (premise/arc)
Wave 1 (foundation):  WS-A (asset pipeline)  ──► gates B, C, D
Wave 2 (parallel):    WS-B (locomotion) ‖ WS-C (world) ‖ WS-D (ecology) ‖ G.3–G.4 (storyboards)
Wave 3 (feel):        WS-E (combat/HUD/UX)   [needs B anim hooks]
Wave 4 (ship):        WS-H (gates & proofs)  [needs A, C, D]
```

**Critical path:** F → A → B → E → H. C and D run fully parallel to B once A lands. G runs anytime.

---

## 7. Definition of Done (prod-ready bar)
- No teleporting/floating/sliding creatures; all animated.
- 6 biomes naturally dressed, condensed, grounded, with believable water.
- Only high-rated imported (script-stripped, tagged) assets in the shipping build.
- Survival HUD + combat feedback complete and mobile-usable.
- Flight/swim cleanly gated or cut; one source of truth per stat.
- Asset-honesty audit + all release gates green with live proofs.
- A first-session journey that matches the §4 storyboard.

---

## 8. Learnings From Prior Codex / `.omx` Work

Salvaged from the repo's `.omx/` orchestration state and `docs/G014–G019` gate logs. Codex made **slow progress because it kept fighting the 500-asset gate and the import tooling** — these learnings let the swarm skip those traps.

### 8.1 The 500-asset gate was the recurring wall
- `ImportBatchPlan.md` / `AssetMaterializationReport.md`: best result reached **34/500** release-ready assets (now 28 — it regressed). The gate breaks down into category quotas (40 species, 60 herbivore plants, 80 city ruins, etc.) — see that doc for the full quota table; reuse it as the import target list.
- The gate also demands **live-proof attributes** (`MobileProofPassed`, `RBXLPersistencePassed`, `FreshAllCategoryTestRunnerPassed`) that must come from a fresh observed Studio run — not source assumptions. Codex never satisfied these.

### 8.2 Creator Store import tooling gotchas (critical for WS-A)
- **`insert_from_creator_store` inserts only the PRIMARY result** per search; secondary IDs are alternatives and don't get placed/counted. → To hit volume, run **many distinct searches**, not one search expecting many assets.
- **Parallel inserts fail** with play-mode / "target not reachable" errors → must `start_stop_play(false)` and insert **serially** with retries.
- Established import loop (keep it): search → insert primary → tag `SourceAssetId`/`AssetManifestId`/`CreatorStoreOnly`/`ImportedVisibleAsset` → quarantine scripts → move under `Workspace.Map.ImportedAssets` → `AssetImportAuditService:AuditAndRepair({mutate=true})`.

### 8.3 The MeshPart paradox (now blocking, see BR-18)
- The audit auto-quarantined **96 low-quality/mesh/simple-generated** candidates and hid **47 procedural food markers**; it treats **MeshPart imports as non-release-ready**. Required playable dinos were only kept via `RequiredPlayableVisual` policy-note exceptions.
- **Implication:** the user's new genuine mesh packs will be quarantined by the current rules. The audit policy must be updated (A.7) or the real assets can never count.

### 8.4 Generated assets never count
- Project rule (G018 queue): **Creator Store assets are primary; `GenerationService` is authoring-fallback only and never counts as release-ready by itself.** Confirms the earlier finding that the nil-SourceAssetId "AI-generated" sets don't satisfy the gate.

### 8.5 Bugs Codex already found & fixed (don't re-debug)
- **Transparent hatched dino:** avatar-hiding logic hid imported visuals; fixed by preserving imported visual parts (`RETRY_LOG`). Watch for regressions in `CharacterVisualService`.
- **Map compaction:** half-scale layout (`scaleXZ=0.5`) used to condense biomes; two legacy placements re-centered into Jungle/Redstone.
- **Carnotaurus** upright-correction and species→biome spawn routing already implemented.

### 8.6 Orchestration infra note
- `omx team` (tmux-leader parallel mode) **failed to launch** ("requires running inside tmux current leader pane"); Codex fell back to native worker lanes. If re-running an omx swarm, ensure it's launched from the leader pane, or plan for native-lane fallback.

### 8.7 Net takeaway for the swarm
Codex's *engine/source* work is largely sound; it stalled on **content volume + import ergonomics + a self-imposed audit rule that rejects the very mesh assets we now have.** Prioritize: (1) fix the audit's MeshPart policy, (2) batch-import via many serial searches, (3) capture the live-proof artifacts, (4) reuse Codex's category quota table as the shopping list.

---

## 9. Verification & Provenance Log

What was actually checked to back the claims in this plan (accuracy + completeness audit):

- **Repo ↔ place sync verified.** Repo `src/` = **133** source files; live place has **133** non-Workspace scripts (ServerScriptService 107, StarterPlayer 13, ReplicatedStorage 13) — exact match, Rojo-managed, nothing missed. The extra **758** scripts are all in Workspace (imported packs), live-only, not in source control.
- **Flight/swim dead-path claim verified.** `FlightUnlocked`/`CanFly` are only *read* in production; the single assignment is in `FlightSwimOxygenServiceTests` (a test).
- **Tests run + structurally audited.** Full run 199/228; Unit re-run **19/19 green**. All 65 test modules audited by category, world-dependence, and assertion density: Unit 8 / Integration 15 are pure-logic (refactor guard); 7 are world-dependent (won't guard logic); 6 "no-category" modules are helper registries/harnesses, not suites; `ExploitSafeZoneAttackTests` is thin (1 assert). **Not yet done:** line-by-line read of all 71 test files.
- **Asset origin verified.** 0 `MeshPart`s before the packs; 5,767 after. Imported "playable" sets were CSG wearing `SourceAssetId` tags. nil-SourceAssetId sets are not release-countable.
- **Audio buzzing root-caused.** 216 Sounds; ~20 looped / 6 auto-play embedded in packs (e.g. `Gigazilla` vol 7.9 looped) fired by 82 enabled sound scripts.
- **Codex history mined** from `.omx/` + `docs/G0xx` (read-only; not modified).

**Known open gaps (honest):** dedicated Audio/SFX + egg-nest Creator Store searches not yet run; full line-by-line read of all test files pending; `RedstoneCanyon`/`SwampDelta`/terrain/water Creator Store queries need refinement at insert time.

---

*Generated from a live Studio MCP investigation of eggBreakers2.rbxl plus the repo's `.omx/` and `docs/G0xx` history (read-only). Every broken-implementation row is backed by code/engine evidence. This document is intended to be handed to parallel agents — each section is independently actionable.*
