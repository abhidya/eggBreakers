# eggBreakers — Asset Ledger, Mechanics Disposition & Build Sequence

> The execution foundation. Step 1: what we have. Step 2: what we want + where it comes from. Step 3: mechanics keep/develop/replace. Step 4: the from-scratch build order. Everything here is audited against the live place (eggBreakers2.rbxl) and Codex's `.omx` history.

## Current Authoritative Snapshot — 2026-05-30 (validated via live Studio)

> Freshest authoritative state, validated via a live Studio test run by the orchestrator. Wording follows `docs/G026/PlanningCountContradictionReport.md`: `catalogedSourceAssetIds=500` is the **catalog** (unique SourceAssetIds), NOT 500 live imports; `releaseReadyVisibleAssets=22/500` is the **release gate**. The inventory and ledger counts below are DATED HISTORY unless restated here.

- **Assets:** `releaseReadyVisibleAssets=22/500`. The `500` is `catalogedSourceAssetIds` — a catalog of unique SourceAssetIds, not live imports. Historical/contradictory counts (22, 23, 34, 79, 215, 221, 227 /500) are dated history only; 22/500 supersedes them. The STEP 1 inventory's "28 unique release-ready" figure below is historical.
- **Tests:** 176 total / 143 passed / 34 failed. 15 are PRE-EXISTING module-load failures (error on require, exist at HEAD, NOT from the recent merge): CombatServiceTests, FoodServiceTests, NPCServiceTests, CombatFormulaTests, 4 Performance budget tests, Placement NPCSpawnValidation + SpawnPlacementValidation, E2E_CarnivoreSurvival + E2E_PlayableLoopClosure, G013FinalGate, G014FinalGateSuite, Security ExploitSafeZoneAttackTests. 19 are content/release-gate failures: G015/G016/G018 FinalGate, AssetManifestValidation, FlightSwimOxygenServiceTests x2, SpeciesConfigTests, TestRunner coverage.
- **Asset-quality disconnect (visual + tree audit):** `Workspace.dinosaur` is a STAGING PEN holding 56 genuine textured MESH dino species (Herbivores 16, Carnivores 28, Omnivores 4, Aquatic 8; ~5-10 MeshParts each, clean, no unions) UNUSED in gameplay. `Workspace.NPCs` spawns are PRIMITIVES (88-172 Parts, 0 MeshParts each). The player character is the DEFAULT Roblox R15 avatar (SpeciesId=nil, no dino visual applied). There is NO velociraptor mesh staged (nearest: Utahraptor, Microraptor, Coelophysis). A junk model named "Delete(and delete thumbnail)" exists.
- **Just-merged code (on main):** pteranodon rename (was pterodactyl); spinosaurus SemiAquatic NPC spawn kind; combat hit VFX; nest respawn; water drinkable validation (WaterService); MapLayoutService WorldBuilder hooks + a syntax fix.

See also `eggBreakers_STATUS.md` for the consolidated status page.

---

## STEP 1 — Current Asset Inventory (audited)

| Asset class | Count (live) | Quality verdict | Disposition |
|-------------|-------------:|-----------------|-------------|
| Server services (NPCService, Combat, Survival, etc.) | ~33 modules | Solid engine | **KEEP** |
| Test suite (Unit→Performance + gates) | 65 suites / 228 tests *(historical — latest live run is 176 total / 143 passed / 34 failed; see Current Authoritative Snapshot)* | Comprehensive | **KEEP** (re-baseline) |
| `AssetImportAuditService` + quarantine | 1 | Useful, but MeshPart rule wrong | **KEEP + FIX** |
| Primitive CSG dinos (`Imported_Playable_*`) | 6 sets | Block/union, no rig | **CUT/REPLACE** |
| Live NPC instances (anchored primitives) | 50 *(historical — 2026-05-30 audit: `Workspace.NPCs` are primitives at 88-172 Parts, 0 MeshParts; see Current Authoritative Snapshot)* | Anchored, no Humanoid/anim | **REPLACE** (new rigs) |
| New mesh dino packs (`Dino Pack!`, `rex`, loose models) | 5,767 MeshParts, 21 roots *(historical — 2026-05-30 audit finds 56 genuine textured mesh dino species staged in `Workspace.dinosaur` but UNUSED; see Current Authoritative Snapshot)* | Real meshes/rigs — **plus** 758 Workspace scripts (744 enabled) + 20 looped sounds; live-only, not in repo | **KEEP MESH/RIG, REVIEW scripts/sounds, ADAPT or STRIP per safety** |
| Imported props (`Map/ImportedAssets`) | 8 placed / ~28 unique SourceIds | Mostly CSG wearing import tags | **AUDIT/REPLACE** |
| Quarantined imports (`ReplicatedStorage/QuarantinedImportedAssets`) | 96 moved by Codex | Low-quality/mesh/simple-gen | **REVIEW** (some are real meshes wrongly quarantined) |
| Placeholder food (balls/markers) | 47 hidden + visible | Junk | **CUT/REPLACE** |
| Water (square generated Parts) | 7 | Broken, untagged, one too deep | **CUT/REPLACE** (Terrain water) |
| Biome dressing (invisible trunk/canopy "trees") | ~55 desc | Placeholder, rule-violating | **CUT/REPLACE** |
| Embedded Sounds (pack ambient/roars) | 216 total, ~20 looped/6 autoplay | Causes startup buzzing | **CUT** (curate fresh SFX) |
| Map terrain | flat plane + drop-off | Unnatural | **REBUILD** (sculpted Terrain) |
| Skybox | Roblox default | No identity | **REPLACE** (custom sky) |

**Honest release count today:** 28 unique release-ready imported assets vs **500** required. *(historical — see Current Authoritative Snapshot; freshest authoritative count is `releaseReadyVisibleAssets=22/500`, where 500 = `catalogedSourceAssetIds` catalog, not live imports.)*

---

## STEP 2 — Target Asset Ledger (the shopping list)

Category quotas inherited from Codex's `ImportBatchPlan` (proven to be what the gate wants), each mapped to a **validated** Creator Store query. ✅ = confirmed category match this session.

| Category | Target unique | Query (validated) | Match |
|----------|-------------:|-------------------|:----:|
| Playable species + stage variants | 40 | "rigged animated dinosaur" / "dinosaur creature animation pack" | ✅ |
| Egg / nest / hatch | 20 | "dinosaur egg nest" (refine) | ◇ |
| Herbivore food plants | 60 | "low poly plants ferns bushes foliage food" | ✅ |
| Carnivore carcass / remains | 40 | "animal carcass bones remains" (refine) | ◇ |
| NPC prey/predator/ambient creatures | 60 | "rigged animated dinosaur" / "animal" | ✅ |
| NurseryGrove foliage/rocks/shelter | 50 | "low poly nature trees rocks environment pack" | ✅ |
| FernPlains foliage/landmarks | 50 | nature pack + "mountain forest" | ✅ |
| JungleBasin foliage/vines/logs | 50 | nature pack (jungle subquery) | ✅ |
| RedstoneCanyon rocks/cliffs/fossils | 50 | "rock cliff canyon" (refine) | ◇ |
| SwampDelta reeds/water plants/logs | 50 | "swamp reeds water plants" (refine) | ◇ |
| ApocalypticCity ruins/cars/rubble | 80 | "rubble debris wrecked car ruins destroyed" | ✅ |
| MountainNestingCliffs rocks/nest | 30 | "stone wall fence boundary barrier ruins" / rocks | ✅ |
| UI / icons / audio / VFX | 20 | VFX: "impact hit blood particle" ✅ · Audio: separate index ◇ · UI: build in-house | mixed |
| Custom sky | — | "skybox sky atmosphere" | ✅ |
| Boundary ring + far decoration | — | "stone wall fence" + distant rock/mountain | ✅ |

**Import discipline (from Codex learnings — non-negotiable):**
- `insert_from_creator_store` places **only the primary result** → use **many distinct searches**, not one.
- **No parallel inserts** → stop play, insert **serially**, retry on "target not reachable".
- Loop per asset: search → insert → tag (`SourceAssetId`/`AssetManifestId`/`CreatorStoreOnly`/`ImportedVisibleAsset`) → review scripts/sounds → adapt useful behavior or quarantine unsafe behavior → move to `Map/ImportedAssets` → `AuditAndRepair({mutate=true})`.
- **Fix the MeshPart audit rule FIRST** or every quality import gets quarantined (BR-18).

---

## STEP 3 — Mechanics Disposition

| Mechanic | Current state | Disposition |
|----------|--------------|-------------|
| Hatch → 4-stage growth | Works (engine) | **KEEP**, re-skin with real rigs |
| Hunger/thirst/stamina + age/rest/dying | Works as a server lifecycle spine | **KEEP** + HUD/story proof for movement, eat/drink, rest/sleep, age tick, dying state, death age, respawn |
| NPC AI brain (sense/flee/hunt/herd/apex) | Works as data; movement broken | **DEVELOP** (Humanoid locomotion + anim) |
| Movement (locomotion) | Teleport via PivotTo, anchored | **REPLACE** approach (Humanoid:MoveTo + physics) |
| Animation | None (empty IDs) | **DEVELOP** + asset (animation packs) |
| Combat | Server math, no feedback | **DEVELOP** (telegraph, damage numbers, VFX/SFX) |
| Carnivore predation (NPC + players) | NPC carcass only | **DEVELOP** (extend to players, anti-grief rails) |
| Flight | Inert (always locked) | **DEVELOP** real flight for flyer species |
| Swim + Oxygen | Inert; constant drift | **DEVELOP** real swim for aquatics; unify oxygen |
| Food finding | Nearest-tag, placeholder food | **DEVELOP** (sense UX) + REPLACE food assets |
| Water/drink | Broken square water | **REPLACE** (Terrain water) |
| Weather/rain | Broken; scope-frozen | **CUT** for slice (optional later) |
| HUD / mobile UI | Functional, plain | **DEVELOP** (design in-house) |
| Map / biomes | Flat, sparse, far apart | **REBUILD** from storyboards |

Current starter slice: Coelophysis, Parasaurolophus, Utahraptor, and Citipati. Treat older Gallimimus/Triceratops/Velociraptor/Carnotaurus starter notes as historical planning unless a task explicitly promotes them as non-starter fauna.

---

## STEP 4 — From-Scratch Build Sequence

> Built on audited assets + the storyboards in `eggBreakers_World_and_Gameplay_Design.md`, which are achievable *because* the asset/script audit is done.

**Wave 0 — Safe reset (⚠ needs your go-ahead, see gate below)**
1. Branch/snapshot the place; **archive** the current Workspace dressing/NPCs/water into a `_Legacy` folder (non-destructive) rather than permanent delete.
2. Fix the MeshPart audit policy (A.7) so real imports can count.
3. Review all pack scripts + embedded looped sounds (A.1, A.6) — keep useful dynamic behavior only after adaptation; disable/quarantine buzzing, duplicate AI, exploit-risk, and authority-conflicting scripts.

**Wave 1 — World shell**
4. Sculpt Terrain per biome (elevation, water bodies) from the storyboard map layout.
5. Custom sky + atmosphere/lighting per region.
6. Decorated boundary ring + far-horizon silhouettes (no drop-off).

**Wave 2 — Dress & populate (parallel, serial inserts)**
7. Batch-import biome dressing to category quotas; raycast-ground every prop.
8. Import + wire rigged species (mesh + rig + animation) into `NPCService`/spawns.
9. Import food foliage + carcasses; fix diet metadata.
10. ApocalypticCity build-out (ruins/cars/rubble).

For each biome batch, record the asset state explicitly: candidate/search ref, inserted in edit mode, tagged/reviewed, scattered by `WorldDressingService`, screenshot-proven, and saved/persisted. A catalog row alone is not live dressing.

**Wave 3 — Feel**
11. Locomotion rework (Humanoid:MoveTo, grounding, flight/swim physics).
12. Combat feedback + readable damage + NPC health/threat UI.
13. Survival HUD redesign + mobile pass.

**Wave 4 — Prove & ship**
14. Drive release count to 500 honest assets; capture live-proof artifacts.
15. Full suite green; publish-blocker scan.

---

## Test-Guarded Refactor Protocol (run BEFORE touching engine code)

The suite is the safety net for the refactor. How it works (verified live):

- **Structure:** each test is a `ModuleScript` returning `{ name, category, tests = {{ name, run = fn }} }`, registered via `TestRunner.registerSuite`. Categories: Unit, Integration, Placement, E2E, Security, Performance, Client.
- **Assertions:** `Assert.truthy / falsy / equals / notNil / between` (`ReplicatedStorage.Shared.TestFramework.Assert`).
- **Isolation:** `MockPlayer` + `MockInstanceFactory` let logic tests run with no live world. The runner clones each suite as `_FreshLoad` to dodge the require cache, and cleans fixtures between tests.
- **Auto-gate:** `Tests.TestRunner` runs on Play in Studio and asserts zero failures.
- **How to run on demand:** `require(ReplicatedStorage.Shared.TestFramework.TestRunner)` → `clearSuites()` → `LoadSuitesFrom(ServerScriptService.Tests)` → `run({ category = "Unit" })` (or `"Integration"`, or omit for all).

**Baseline captured this session:** Unit **19/19 green**; full run **199/228** — the 29 failures are **content/asset/placement/gate**, not engine logic. So the locomotion/combat/animation refactor is well-protected by the Unit + Integration suites.

**Protocol for the refactor:**
1. Before a change: run `Unit` + the relevant `Integration` suite (e.g. `CombatServiceTests`, `NPCServiceTests`) → confirm green.
2. Make the change.
3. Re-run the same suites → must stay green. Don't proceed on a regression.
4. Treat Placement/E2E/gate failures as the **content backlog** (expected until the world is rebuilt) — don't let them mask a new logic regression.
5. Add new tests alongside new behavior (flight/swim physics, player predation, damage readout).

---

## ⚠ Safety Gate — Map Clearing

"Clear the map and build from scratch" means destroying existing instances. I will **not permanently delete** your content without explicit confirmation. Recommended safe approach: **archive into a `_Legacy` folder or a new branch/place copy**, build the new world alongside, then remove the legacy folder once you've signed off. 

**Confirm one:** (a) archive-to-`_Legacy` (reversible, recommended), or (b) you'll snapshot the .rbxl yourself and authorize a hard clear. I'll proceed once you choose.

---

*Companion to `eggBreakers_Master_Plan.md` (workstreams + Codex learnings) and `eggBreakers_World_and_Gameplay_Design.md` (world/story/mechanics). This ledger is the bridge from audit to build.*
