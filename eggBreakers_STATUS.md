# eggBreakers — Consolidated Status Index

**Authoritative status snapshot. Last validated: 2026-05-30** (live Studio test run by the orchestrator — treat as freshest/authoritative over any older dated numbers elsewhere in the repo).

eggBreakers is a Roblox dinosaur survival vertical slice across 6 biomes: NurseryGrove, FernPlains, JungleBasin, SwampDelta, RedstoneCanyon, ApocalypticCity. Rojo-managed, source under `src/`.

---

## 1. Current Validated State (2026-05-30)

### Tests: 176 total / 143 passed / 34 failed

The 34 failures split into two buckets:

**A. Pre-existing module-load failures (15)** — these test modules error on `require`, exist at HEAD, and were **NOT** caused by the recent merge:
- CombatServiceTests, FoodServiceTests, NPCServiceTests, CombatFormulaTests
- Performance budget tests (4): AssetCollisionBudgetTest, LoopBudgetTest, NPCCountBudgetTest, ParticleBudgetTest
- Placement: NPCSpawnValidation, SpawnPlacementValidation
- E2E: E2E_CarnivoreSurvival, E2E_PlayableLoopClosure
- Gates: G013FinalGate, G014FinalGateSuite
- Security: ExploitSafeZoneAttackTests

**B. Content / release-gate failures (19)** — real content gaps:
- G015 / G016 / G018 FinalGate (500-asset count + live-proof gates)
- AssetManifestValidation (placeholder primitives present in `Workspace.dinosaur`)
- FlightSwimOxygenServiceTests (x2)
- SpeciesConfigTests (playable-species cap)
- TestRunner coverage

### Assets: 22 / 500 release-ready live imported visible assets

**CRITICAL framing:** "500" = the count of cataloged **unique SourceAssetIds** (a catalog target), **NOT** 500 live imports. Per `docs/G026/PlanningCountContradictionReport.md`, the docs cite contradictory counts (22, 23, 34, 79, 215, 221, 227 / 500). Treat those as **dated history**; **22 / 500 is the freshest authoritative live-import number.**

### KEY FINDING — the asset-quality disconnect (visual + tree audit)

There is a real, high-impact disconnect between the staged assets and what actually appears in gameplay:

- **`Workspace.dinosaur` is a STAGING PEN** holding **56 genuine textured MESH dino species** (Herbivores 16, Carnivores 28, Omnivores 4, Aquatic 8; ~5–10 MeshParts each, clean, no unions) that are **UNUSED in gameplay**.
- **`Workspace.NPCs` spawns are PRIMITIVES** (88–172 Parts, **0 MeshParts** each) — the blocky placeholders players actually encounter.
- **The player character is the DEFAULT Roblox R15 avatar** (`SpeciesId = nil`, no dino visual applied) — a bug; players never spawn as their dino mesh.
- **There is NO velociraptor mesh** in the staged lineup. Nearest staged raptors: Utahraptor, Microraptor, Coelophysis.
- A junk model named **`Delete(and delete thumbnail)`** exists and should be removed.

---

## 2. What the Recent Merge Added (just-merged to `main`)

The orchestrator committed the following to `main`:
- **Pteranodon rename** (was `pterodactyl`) — fixes species nomenclature so the flyer can spawn.
- **Spinosaurus SemiAquatic** NPC spawn kind — plumbs the previously-ignored semi-aquatic species.
- **Combat hit VFX** — `CombatFeedbackController` + `ReplicatedStorage.ImportedAssetLibrary.CombatHitVFXTemplate`.
- **Nest respawn** — `ServerMain` + `SurvivalService`.
- **Water drinkable validation** — `WaterService`.
- **MapLayoutService WorldBuilder hooks** — `BiomeCenters` / `GroundPlace` + a syntax fix (functions had been appended after the module's `return`).

---

## 3. Planning Doc Index & Three-Agent Provenance

Three AI agents contributed to this project; their artifacts live in distinct locations:

| Agent | Identity | Artifact location | What it produced |
| :--- | :--- | :--- | :--- |
| **omx** | oh-my-codex (GPT-5.x swarm) | `.omx/` + `docs/G0xx/` milestone gate logs | Gate logs, audits, gap analyses |
| **Claude** | — | the 3 top-level `eggBreakers_*.md` design docs | Master plan + design docs |
| **antigravity** | Gemini, session `b7bf5f93` | OUTSIDE the repo at `/Users/abdulrehmanbhidya/.gemini/antigravity/brain/b7bf5f93-d89d-41dd-ad25-5254c2b49379/` — **now folded into `docs/AssetSourcing.md`** | Asset discovery log (17 verified searchIds), walkthrough, sourcing/roster analysis |

### Key repo docs
- `eggBreakers_Master_Plan.md` — overall plan (Claude).
- `eggBreakers_World_and_Gameplay_Design.md` — world + gameplay design (Claude).
- `eggBreakers_Asset_Ledger_and_Build_Sequence.md` — asset ledger + build order (Claude).
- `README.md`
- `docs/G026/PlanningCountContradictionReport.md` — documents the contradictory asset counts.
- `docs/AssetSourcing.md` — **NEW**, folds in the antigravity (Gemini) asset-sourcing artifacts.

### omx artifacts (`.omx/`)
Includes: AssetManifest.md, DataSchema.md, E2EReports.md, EconomyBalance.md, GameDesignBible.md, GapAnalysis.md, PerformanceAudit.md, PerformanceBudget.md, PlacementAudit.md, PublishingChecklist.md (and more).

### Milestone gate logs (`docs/G0xx/`)
Present milestones: G011, G013, G014, G015, G016, G018, G019, G026.

---

## 4. Prioritized Next Steps — Asset-Quality Work

Ordered by impact on the visual/quality disconnect:

1. **Fix the default-avatar bug.** Players currently spawn as the default Roblox R15 avatar (`SpeciesId = nil`). Apply the selected dino mesh to the player character so players actually appear as their species.
2. **Wire the 56 staged `Workspace.dinosaur` meshes into the playable roster + NPC spawns.** These clean textured meshes already exist but are unused; connect them to species selection and the NPC spawn pipeline.
3. **Replace the 88–172-part primitive NPCs with those meshes.** `Workspace.NPCs` currently spawns 0-MeshPart primitive blobs; swap in the staged textured meshes.
4. **Source a real velociraptor / raptor mesh.** None exists in the staged lineup; nearest are Utahraptor, Microraptor, Coelophysis. Velociraptor is a starter species and needs a proper mesh (see `docs/AssetSourcing.md` for verified Creator Store search IDs).
5. **Gate every asset by quality.** Distinguish Creator-Store-rated meshes from low-quality / primitive / test-generated / CSG fallback assets; only quality-passing assets count toward the release gate.
6. **Remove the `Delete(and delete thumbnail)` junk model** from the workspace.

---

*This file is the single authoritative consolidated index. See `docs/AssetSourcing.md` for the verified Creator Store search directory and species roster gap analysis.*
