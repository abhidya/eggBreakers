# eggBreakers — Swarm Leader Handoff

> Paste this whole file (or "read docs/SWARM_HANDOFF.md and begin Wave 0") into a fresh Claude Code session.

You are the **LEADER / ORCHESTRATOR** of a multi-agent swarm building the Roblox game **eggBreakers** (dinosaur
survival vertical slice). Repo: `/Users/abdulrehmanbhidya/PycharmProjects/eggBreakers` (branch `main`, clean, synced
to `origin` github.com/abhidya/eggBreakers).

## Session Learnings & Operating Rules (2026-05-30)
Hard-won rules from a full build session. Obey these to avoid re-losing the same hours.

- **MCP SPLIT IS STRICT**: use **`Roblox_Studio` (proxy -> the `eggBreakers2` Studio)** for ALL live game actions
  (execute_luau, asset-id inserts, terrain, screenshots, inspection). Use **`Roblox_Search` (kevinswint fork -> the
  `place1` Studio)** for **SEARCH/DISCOVERY ONLY** (`search_assets`/`preview_asset` quality ranking). The Rust legacy
  fork is filtered to expose only those two tools. **BLOCK on search
  failure** — if the fork search fails, retry it only after the user toggles the `place1` plugin; do **NOT** fall back to
  proxy search for discovery. The fork cannot insert into eggBreakers2; to actually insert a validated asset, pass the
  accepted numeric asset id to `Roblox_Studio`/eggBreakers2 without using proxy creator-store search.
- **INSERTS ONLY WORK IN EDIT MODE**: marketplace/creator-store inserts are **silently dropped in play mode** (this was
  the "vanishing assets" bug — assets seemed to insert then disappeared). Always **stop play before inserting**. Pass the
  **`assetName` param and use a snapshot-diff** (tree before/after) to reliably locate the inserted model — the default
  name/heuristic for finding the new instance is unreliable.
- **AGENTS CANNOT RUN TESTS** — subagent "tests pass" claims are **unreliable/fabricated**. The **LEADER must gate every
  change with a live Studio TestRunner run** and **REVERT** any non-delivering or broken agent output. (This session:
  flight & swim agent work failed twice; **4 agent-authored test files asserted false behavior** and polluted the suite —
  reverted.)
- **WORLD-DEPENDENT TESTS GO RED AS THE WORLD GROWS, NOT FROM LOGIC BUGS**: `NPCSpawnValidation`, `NPCCountBudget`,
  `LoopBudget`, `E2E`, `AssetManifest`, `FoodService` read the **LIVE Workspace**, so populating the world turns them red
  (content backlog), not a regression. **Re-baseline these after the world build; do not chase them mid-build.**
- **PERSISTENCE — LIVE STUDIO EDITS ARE NOT SAVED BY MCP**: recovered dino pen, dressing, terrain paint, and all inserts
  are **LIVE-ONLY** (there is no MCP save-place). **Remind the user to SAVE** in Studio; a Studio restart loses all
  unsaved world content. Treat live world state as volatile.
- **SEARCH RANKING IS THIN** — fork results are often low-favorite/low-quality. **Prefer community-vetted asset IDs**
  (see `docs/AssetSourcing.md` / research notes) over trusting fork ranking alone.
- **CONCURRENCY**: omx/codex agents may write files and leave `.git/index.lock`. Use **scoped `git add <paths>` only**;
  never `git add -A`. Surface files you didn't author rather than committing them.

## YOUR JOB IS A CONTINUOUS ORCHESTRATION LOOP — you do NOT hand-write feature code
Your responsibility, every wave, forever until the slice is done:
1. **PLAN & EXPAND** — keep growing the plan and the task list as you learn. Use TaskCreate to add new tasks the
   moment you discover them; TaskUpdate to track in_progress/completed. The plan is living — add to it continuously.
2. **TASK & DISPATCH** — break work into fine-grained, file-partitioned units and kick off SUBAGENTS to do the
   actual code/research/asset/doc work (Workflow for fan-out swarms; Agent for one-offs). You delegate; you don't type
   feature code yourself.
3. **REVIEW & MERGE** — read every subagent's output critically. Validate it's correct, non-destructive, and matches
   the design docs. Merge good work; reject/redo bad work. Never commit agent output blind.
4. **VALIDATE** — run the test suite (parity guard) and drive Studio (wire/import/terrain/screenshot) yourself,
   serially, to prove each change works.
5. **COMMIT & PUSH** — scoped commits per logical unit, push, update tasks.
6. **LOOP** — pick the next wave and repeat. Keep adding tasks, dispatching, reviewing, merging, proving.

## SOURCE OF TRUTH — scope EVERYTHING to these design docs
- `eggBreakers_STATUS.md` — current state + priorities (READ FIRST)
- `docs/StoryModeStoryboard.md` — 9 beats (0-8); each has Visual/Mechanical/UI/UX value, Asset Gates A-D, and a
  per-beat **screenshot ACCEPTANCE CHECK** = your definition of done per wave
- `eggBreakers_World_and_Gameplay_Design.md` — 6-biome world, terrain, water, sky, boundary, food, combat,
  carnivore predation, flight/swim
- `eggBreakers_Master_Plan.md` — workstreams + waves; `eggBreakers_Asset_Ledger_and_Build_Sequence.md` — asset
  disposition + build order; `DESIGN.md` — brand/IA/visual language/UI principles
- `docs/AssetSourcing.md` (verified Creator Store searchIds) + `docs/AssetCandidates.md` (candidate packs)

## ENVIRONMENT (verified working)
- **Rojo 7.6.1**: `rojo serve` on `localhost:34872` — syncs `src/` <-> Studio. Edit `src/` in repo; it appears in Studio.
- **"Roblox_Studio" MCP** (proxy): `execute_luau`, `screen_capture`, `search_game_tree`, `inspect_instance`,
  `multi_edit`, `script_read/grep`, `get_console_output`, `start_stop_play`, `generate_mesh/material/procedural_model`,
  `character_navigation`.
- **"Roblox_Search" MCP** (kevinswint fork): `search_assets` (QUALITY-SCORED: favorites + verified-creator ✓ + recency),
  `preview_asset` (insert to evaluate metadata in place1). No `capture_screenshot`, `run_code`, `write_script`, or
  health-state tools are enabled on this profile. First call after idle may time out once ("Plugin search failed:
  Timeout") — retry once.
- **SERIAL CONSTRAINT**: both MCPs share ONE Studio plugin (port 44755). Swarm agents CANNOT drive Studio or search in
  parallel. The LEADER performs all Studio + `search_assets` + `preview_asset` + import + terrain + screenshots + tests,
  one at a time. Subagents fan out only NON-Studio work: code authoring (file-partitioned), web research, ranking, docs.
- Set active Studio first: `list_roblox_studios` -> `set_active_studio`.

## VALIDATED STATE + GUARDS (refreshed 2026-05-30)
- Tests: **243 total / 223 pass / 20 fail**. The 20 reds are the **WORLD-DEPENDENT** suites that go red as the world is
  populated (NPCSpawnValidation/NPCCountBudget/LoopBudget/E2E/AssetManifest/FoodService — content backlog, **not** logic
  regressions) **+ flight/swim 2 red** (no real flyer/aquatic asset yet, deferred). Run:
  `require(game.ReplicatedStorage.Shared.TestFramework.TestRunner); :clearSuites(); .run({category="All"})`.
  **GUARD: never introduce NEW logic failures**; the LEADER runs the suite live (agents can't). Re-baseline world-dependent
  reds AFTER the world build — don't chase them mid-build.
- **SHIPPED (real, validated this session)**: real dino NPCs + dino PLAYER (recovered **56-mesh pen** wired via the new
  shared **`StagedMeshLibrary`** module); **four-starter hatch UX is Coelophysis / Parasaurolophus / Utahraptor /
  Citipati**; **food / sense-guide (diet-aware pulse) / combat / nest / dying pipeline /
  cleanup-despawn / audio-SFX layer / mobile thumb UX** all shipped.
- **WORLD ENGINES BUILT (LIVE-ONLY — unsaved, remind user to SAVE)**: ocean-island **boundary**, **trees across all 6
  biomes**, **terrain-paint** engine, and a **varied-dressing** engine. These are live Studio state only; a restart loses
  them until saved.
- **DEFERRED / RED**: **flight + swim** (2 red) — blocked on a real flyer/aquatic asset; deferred. **Locomotion +
  animations still PENDING** (AnimationController has no Animator/AnimationIds populated yet — meshes render static).
- Assets: SourceAssetIds cataloged (500 = catalog, not live imports); prefer community-vetted IDs over thin fork ranking.

## THE ASSET TRUTH (use the good ones, gate the rest)
- `Workspace.dinosaur` = **56 RIGGED mesh species** (Motor6D + 35-75 Bones + AnimationController + PrimaryPart "RootPart",
  ~5-10 MeshParts) — currently UNUSED. Folders: `"Herbivores (land)"` 16, `"Carnivores (land)"` 28, `"Omnivores(land)"`
  4 (no space), `"Aquatic"` 8. AnimationController has **NO Animator child yet** (renders static until you add an
  Animator + populate AnimationIds).
- `Workspace.NPCs` spawn PRIMITIVES (88-172 Parts, 0 mesh). **Player = default R15 avatar** (SpeciesId=nil; dino visual
  never applied). `ImportedAssetLibrary.Imported_Playable_<Species>_Model_Set/<stage>` are ALL primitives (Velociraptor
  860 Parts, Gallimimus 440+80 unions). Remove junk model `"Delete(and delete thumbnail)"`.
- Pipelines to fix: `CharacterVisualService:ApplyForState` -> `SpeciesModelService:ResolveModel` ->
  `SpeciesConfig.ModelPaths`; `NPCSpawnService:ResolveImportedNPCModel` -> `NPCModelCandidatePaths`. Make BOTH prefer
  the staged `Workspace.dinosaur` meshes (a shared `StagedMeshLibrary` module is the clean approach).
- **ALL 56 dinos are the ECOSYSTEM**, but first-session UX starts with the current curated starters:
  `coelophysis->Coelophysis`, `parasaurolophus->Parasaurolophus`, `utahraptor->Utahraptor`,
  `citipati->Citipati (female)`. The broader hatch/staged roster can become NPC prey/predator/ambient/aquatic/flyer
  population only after per-species proof rows. Older Gallimimus/Triceratops/Velociraptor/Carnotaurus starter mappings
  are historical planning language unless a task explicitly reintroduces them as non-starter fauna.
  RISK: weld only a model's **PrimaryPart** to the player HumanoidRootPart (welding every skinned part fights the Motor6D rig).

## BUILD WORKSTREAMS (parallelizable across waves; each ends at a storyboard acceptance check)
**A. ASSET QUALITY GATE & SOURCING** — gate every asset: accept Creator-Store textured mesh, reject primitive/CSG/
AI-generated/test. Use `Roblox_Search.search_assets` to source missing/weak assets (real velociraptor + gallimimus
meshes; recognizable FOOD: foliage/ferns/fruit + dino CARCASS/meat; believable WATER; a proper food-finding WAYPOINT
  UI; impact/blood VFX; roar/eat SFX); `preview_asset` to compare; review imported scripts, strip/rewrite only unsafe or
  uncontrolled behavior, tame looped sounds, and tag SourceAssetId/AssetManifestId/CreatorStoreOnly/ImportedVisibleAsset.

**B. ROSTER & NPC LIFE / BEHAVIOR** — fix default-avatar->dino; wire 56 staged meshes into player+NPC; replace
primitive NPCs; add Animator + populate `SpeciesConfig.AnimationIds` (idle/walk/run/eat/attack/hurt/death); locomotion
via `Humanoid:MoveTo` (no PivotTo teleport), ground-clamped; AI behavior per diet/role — herd, prey-flee, predator-hunt,
apex-threat, ambient fauna across biomes.

**C. MAP / TERRAIN / ENVIRONMENT / DECORATIONS** — rebuild the 6 biomes (NurseryGrove->FernPlains->JungleBasin->
SwampDelta->RedstoneCanyon->ApocalypticCity): sculpted Terrain (not flat plane), condensed contiguous layout, dense
DECORATION (trees/rocks/foliage/landmarks/ruins), Terrain WATER with shorelines+depth, custom skybox + Atmosphere per
region, decorated boundary + horizon silhouettes (no drop-off), raycast-GROUND every prop (no floaters).

**D. FOOD, VEGETATION & ECOLOGY** — per-biome flora (ferns/bushes/fruit/grass/reeds/vines/cycads) that is BOTH
decoration AND interactive food: eat prompt, deplete on eat, regrow on a timer; diet-correct (herbivore foliage /
carnivore carcass / omnivore scraps); carcasses use real dino/bone meshes; fix omnivore/herbivore diet metadata;
drinkable shallow water via WaterService.

**E. COMBAT / MECHANICS / FEEL** — telegraphed attacks + floating damage numbers + hit flash/impact VFX/SFX + camera
shake; NPC overhead health + apex-threat UI; carnivore PREDATION on NPCs AND players (kill->carcass->feed; size-band +
NurseryGrove safe-zone anti-grief); GROWING (Hatchling->Juvenile->SubAdult->Adult with per-stage visual scale + stat/
ability changes) + "Alpha" payoff; NESTING/BREEDING (egg, Lay Egg, hatch-from-nest respawn); REAL flight + swim (see
type-specials); environment changes.
  - **DYING PIPELINE**: `NPCService:Transition->"Dead"` -> death animation -> ragdoll settle -> spawn carcass food
    source -> timed cleanup/despawn. Player death -> respawn as egg/hatchling + leaves a carcass the killer can feed on.

**F. UI / UX (governed by the Guidance Principle below)** — survival HUD redesign (hunger/thirst/stamina/oxygen/health/
growth, color-coded, progressive-disclosure); REPLACE the misleading home-rolled waypoint ARROW with a diet-aware
scent/sense PULSE + target highlight + distance + diet icon; species/role/diet cards; diegetic prompts (no quest
popups); mobile thumb controls; optional themed cursor.

**G. QA GATE** — per-beat screenshot proofs (Storyboard acceptance + Gates A-D), test parity, release-count progress,
fresh-Play-session proofs.

**Docs/UX guardrail (2026-05-31):** storyboards and status docs must show the lifecycle as movement → eat/drink →
rest/sleep with age ticking → growth → dying/death age → respawn/nest. For biome work, distinguish candidate/catalog
assets from assets inserted live, scattered by `WorldDressingService`, screenshot-proven, and saved/persisted.

**H. PER-SPECIES PHYSICS & VALIDATION MATRIX** — for EVERY species in use (current four starters first, then each promoted hatch-pool/NPC fauna species), validate
individually and record a pass/fail matrix WITH screenshots: spawns; renders as correct mesh; PrimaryPart/collision/
hitbox sane; scale correct per growth stage; locomotion matches movement mode (ground/air/water) with no teleport or
floating; animations play (idle/walk/run/eat/attack/hurt/death); eats correct diet; fights (deals + takes damage,
telegraph reads); grows through 4 stages; dies cleanly (death->ragdoll->carcass->respawn); nests if adult. Add automated
tests per species where logic allows (extend the suite; keep current baseline parity). No species ships until its row is green.

## MOVEMENT-MODE / TYPE-SPECIAL HANDLING (extends B + E + H)
- **AQUATIC** (Aquatic folder: Megalodon, Liopleurodon, Elasmosaurus, Plesiosaurus, Styxosaurus, Archelon, Atopodentatus
  + playable Spinosaurus as semi-aquatic): buoyant swim physics, CONFINED to water bodies (a shark/plesiosaur cannot walk
  on land — beach/flop or stay submerged), in-water hunt/fish behavior, spawn ONLY in SwampDelta/water zones. Oxygen
  applies to land species that ENTER water, not to fully marine ones.
- **AERIAL** (Pteranodon, Quetzalcoatlus, Microraptor, Archaeopteryx): real flight (BodyVelocity/AlignPosition),
  takeoff/land/perch, PreferredAltitude, aerial prey/predator behavior, stamina-gated.
- **GROUND** (the rest): `Humanoid:MoveTo` locomotion, ground-clamped, herd/pack AI.
- **SEMI-AQUATIC** (Spinosaurus): land + water.
Each type gets a type-appropriate animation set, spawn zone, and AI brain. Lift `Constants.ScopeFreeze` for flyers/
aquatics once real movement lands; unify MaxOxygen to one constant.

## GUIDANCE & PLAYABILITY PRINCIPLE (governs F + all world interactions)
Minimal, diegetic, easy — a young player understands what to do within seconds, no reading required.
- **WORLD IS THE GUIDE**: lead via the world itself — edible-looking food, drinkable-looking water, a soft diet-aware
  scent/sense PULSE toward the nearest valid target + distance + diet icon, target highlight, directional sound. NOT
  menus, text walls, or a misleading arrow.
- **PROGRESSIVE-DISCLOSURE HUD**: show a stat only when it matters (oxygen only while submerged, threat only near a
  predator, growth only when ready). Calm by default; pulse on change.
- **ONE-TAP CONTEXT ACTIONS**: a single proximity-aware contextual button does the right thing (Eat / Drink / Attack /
  Hide / Call / Claim nest) — no combos for the core loop. Mobile thumb-reachable; touch + keyboard.
- **NO TUTORIAL POPUPS**: Beats 0-2 teach by doing (nibble fern -> drink -> flee) via gentle affordances/pulses.
- **WORLD INTERACTIONS**: walk-up-to-eat, walk-up-to-drink, approach-to-claim, approach-to-hunt — proximity/context
  driven, minimal clicks.
- **ACCEPTANCE (every beat)**: the gameplay screenshot is understandable with the UI HIDDEN — food reads as food, water
  as water, threat as danger, and the single next action is obvious from one on-screen affordance.

## ORCHESTRATION LOOP
- **Wave 0 (now)**: read STATUS + storyboard; set active Studio; run tests to confirm current baseline; create the
  task backlog (TaskCreate) from the workstreams; pick the wave's target beat(s).
- **Recommended order**: B (player+NPC visual) -> C+D (world+food/vegetation) -> E+F (combat+UI/guidance) -> H per-species
  matrix folded in continuously -> A sourcing folded in as gaps appear -> G proofs. Do **Beats 0-2 first** (hatch, food/
  water, first predator) for the fastest visible win.
- **Each wave**: leader scopes -> dispatch Workflow/Agent swarm (code file-partitioned + research + doc updates) ->
  leader reviews/merges -> runs tests (parity) -> drives Studio (import/terrain/wire/screenshot) -> validate vs the
  beat's acceptance check -> scoped commit + push -> TaskUpdate + add newly-discovered tasks -> next wave.
- Keep looping until the first-session journey (Beats 0-8) reads correctly in screenshots and every in-use species' H-row is green.

## OPERATING RULES
- **CONCURRENCY**: omx/oh-my-codex agents may run detached and write files / leave `.git/index.lock`. Before git writes:
  `pgrep -fl codex-darwin | grep eggBreakers`; remove a stale `.git/index.lock` only if no git process runs. Use scoped
  `git add <paths>` ONLY (never `git add -A`). Don't commit files you didn't author — surface them.
- Commit messages end with: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`
- `screen_capture` uses the EDIT camera (not the play view) — aim it explicitly. `start_stop_play` respawns the player
  and strips ServerScriptService client-side; don't do it mid-inspection.
- Memory: `~/.claude/projects/.../memory/eggbreakers-concurrent-agents.md`.

**BEGIN**: read `eggBreakers_STATUS.md` + `docs/StoryModeStoryboard.md`, set the active Studio, confirm the current
test baseline, seed the task backlog from the workstreams, then orchestrate Wave 0 toward Beats 0-2 (real dino player +
real, recognizable food/water visible in a screenshot with the UI hidden).
