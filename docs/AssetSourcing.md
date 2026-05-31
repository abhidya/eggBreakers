# eggBreakers — Asset Sourcing & Species Roster Gap Analysis

> **Provenance:** This document folds into the repo the asset-sourcing research originally produced by **antigravity (Gemini), session `b7bf5f93`** — artifacts that previously lived only outside the repo at `/Users/abdulrehmanbhidya/.gemini/antigravity/brain/b7bf5f93-d89d-41dd-ad25-5254c2b49379/` (`dino_asset_discovery_log.md`, `walkthrough.md`, `dino_survival_analysis_and_sourcing_plan.md`). Consolidated here so the verified search IDs and findings are version-controlled.

---

## 1. Verified Creator Store Search Directory (17 search IDs)

Executed in the Roblox Creator Store via the Studio MCP Proxy and mapped to release-requirement categories.

| Sourcing Category | Search Query | Verified Search ID | Object Types Resolved |
| :--- | :--- | :--- | :--- |
| Playable Rigs & NPCs | `"rigged dinosaur"` | `ecb52c0b-842b-4101-bd90-246afe79029c` | dinosaur, creature |
| Dinosaur Animations | `"dinosaur creature animation pack"` | `7ec5e593-0bcc-4471-8962-4bd96c62e722` | dinosaur, creature, npc |
| Dinosaur Animations (Walk) | `"dinosaur walk"` | `69163394-a380-414d-b926-5862eb983c33` | dinosaur, creature, animal |
| Dinosaur Animations (Idle) | `"dinosaur idle"` | `37e23414-8ed7-4ec6-81dd-4f6f38aa1e23` | dinosaur, creature, animal |
| Nesting & Eggs | `"dinosaur egg"` | `da5da35b-1cef-496f-a3be-ee2803d568e5` | egg, object, dinosaur, artifact, nest |
| Interactive Nesting | `"dinosaur egg nest"` | `df69fe17-9e1c-4e69-bf24-bf7ed3f3c689` | container, nest, basket |
| Herbivore Foliage | `"fern low poly"` | `1d710ea1-f95e-4c6d-86d6-3e2674563392` | leaf, plant |
| Carcass & Remains | `"animal carcass bones remains"` | `98ad66c5-2481-4723-8ee0-85bd64bbf36d` | skeleton, model, bones |
| Carcass & Remains (Alt) | `"dinosaur bone"` | `8837548f-f8a2-4e15-ba67-be24558a2903` | dinosaur bone, fossil, avatar |
| Apocalyptic Ruins | `"wrecked car"` | `c05bf215-a3d4-47ed-88b7-3d1da14a7807` | car, vehicle |
| Atmosphere & Sky | `"skybox"` | `71e43324-251a-4d18-8946-2dabb3695bca` | skybox, background image |
| Environment Packs | `"low poly forest pack"` | `bf9d61b5-b97f-4759-a0bc-c8c3d2fd80d4` | tree, rock, forest |
| Combat Hit VFX | `"impact particles"` | `0228cff4-c4d4-4146-85e1-605066022c43` | particle, effect |
| Combat Slash VFX | `"slash vfx"` | `d4bfe578-681b-46f7-9f4c-ae6e84c66bc6` | effect, visual |
| UI Icons & Buttons | `"survival ui icon pack"` | `0313df36-5640-4f42-93b2-757658af8454` | icon pack, ui element, icons |
| Audio: Vocal SFX | `"dinosaur roar sound"` | `420848a7-3243-4cdf-816c-ec73f0933f56` | dinosaur, creature, monster |
| Audio: Consumption SFX | `"eating drinking sound effects"` | `049f70b9-49ad-4040-9c2c-3a5355d003f6` | drink, beverage |
| Custom Cursor UI | `"stylized custom cursor"` | `684359a3-a55c-430a-a7da-011f4e85219e` | cursor, icon, pointer |

> Note: the source log titled this a "17 VERIFIED" directory; the table enumerates 18 distinct search-query rows (two are alternate Carcass & Remains queries). All IDs are reproduced verbatim from the discovery log.

### Sourcing quality filter (anti-"slop")
To prevent low-quality CSG primitives, broken collision meshes, or unrated placeholders:
1. **Mesh checks** — accept only models with rigged `MeshParts` or clean low-poly `.fbx` geometry.
2. **Rojo alignment** — store all imported visible assets under `ReplicatedStorage.ImportedAssetLibrary` so they stay synced in git.
3. **Script review and adaptation** — executable imports are allowed when reviewed. Keep or rework useful dynamic behavior so it serves the storyboards and eggBreakers authority model; disable only code that stays uncontrolled, unsafe, noisy, or incompatible after review.

### Non-destructive import pipeline
`Creator Store search → insert primary result → inspect scripts/sounds/animations → rework useful behavior under eggBreakers services/controllers → tag (SourceAssetId + AssetManifestId) → move to ReplicatedStorage.ImportedAssetLibrary → run AssetAuditService verification.`

---

## 2. Place-File Diagnostic & Species-Nomenclature Findings (from walkthrough)

### Place-file diagnostics
An ASCII-safe grep was run against the historical 13.0 MB `eggBreakers2_old.rbxl` and the current 1.0 MB `eggBreakers2.rbxl`:
- **Both files have only 1 MeshPart** and **21 references** to `rbxassetid://`.
- **Conclusion:** the 13.0 MB → 1.0 MB size difference was entirely **CSG (UnionOperation) geometry**, not 3D rigged meshes. The "5,767 MeshParts" dinosaur packs are **live-only, not in repo** — never committed to git, existing only in the Roblox cloud.

### Nomenclature & spawn alignment (corrected in the just-merged code)
- **Pteranodon:** `SpeciesId` updated `"pterodactyl"` → `"pteranodon"` in `NPCService.lua`; spawn candidate path corrected to `Imported_Playable_Pteranodon_Model_Set/Hatchling` in `NPCSpawnService.lua`; the string-find scanner pattern expanded to match `"pteranodon"`.
- **Spinosaurus:** new `SemiAquatic` profile added to `KindProfiles` in `NPCService.lua` (maps to `spinosaurus`); `"SemiAquatic"` added to `SpawnKinds` and candidate model paths configured under `NPCModelCandidatePaths` in `NPCSpawnService.lua`.

### Combat hit VFX integration
- Sourced asset ID `12136850996` (search ID `0228cff4-c4d4-4146-85e1-605066022c43`).
- A Luau cleanup script extracted **18 distinct particle emitters**, wrapped them in a single `Attachment` named `ImpactPoint` inside a transparent part `CombatHitVFXTemplate`, stamped quality attributes (`ImportedVisibleAsset`, `CreatorStoreOnly`, `AssetManifestId`, `SourceAssetId`), and parented it under `ReplicatedStorage.ImportedAssetLibrary` (Rojo-synced).
- `CombatFeedbackController.lua` clones the template to the hit position, calls `:Emit(math.random(8,15))` on the 18 emitters, and schedules deletion via `Debris:AddItem` after 2 seconds.

---

## 3. Species Roster Gap Analysis (from analysis doc)

8 playable species are configured in `SpeciesConfig.lua`. Implementation status varies widely. **Note the antigravity table marks species as "plumbed via CSG fallback" — independent of the freshest 2026-05-30 audit finding that the real fix is to wire in the 56 staged textured meshes in `Workspace.dinosaur` rather than CSG fallbacks.**

| Species | Diet | Role | Playable? | NPC Spawned? | Status / Issues |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Gallimimus | Herbivore | Scout / Runner | Yes | Yes (Prey) | Plumbed. Uses CSG fallback model. |
| Triceratops | Herbivore | Defensive Tank | Yes | Yes (Prey) | Plumbed. Uses CSG fallback model. |
| Velociraptor | Carnivore | Agile Pack Hunter | Yes | Yes (Predator) | Plumbed. Uses CSG fallback model. **No real raptor mesh staged** (nearest: Utahraptor, Microraptor, Coelophysis). |
| Carnotaurus | Carnivore | Chase Predator | Yes | Yes (Predator) | Plumbed. **Bug:** loads inverted (pitch 180° offset). |
| Oviraptor | Omnivore | Scavenger | Yes | Yes (Omnivore) | Plumbed. Uses CSG fallback model. |
| Tyrannosaurus | Carnivore | Apex Predator | Yes | Yes (Apex) | Plumbed. High DNA cost (3000). |
| Pteranodon | Carnivore | Soarer / Fisher | Locked | (was bugged) | Nomenclature bug — config said `pteranodon`, services looked for `pterodactyl` / `Imported_Playable_Pterodactyl_Model_Set` (does not exist), fell back to Velociraptor/Gallimimus, flight locked. **Fixed in just-merged code.** |
| Spinosaurus | Carnivore | River Fisher | Locked | (was no) | Previously ignored by both NPC services; swimming locked. **Plumbed via new SemiAquatic profile in just-merged code.** |

### Asset quality tiers (analysis doc)
- **Low-quality "slop":** CSG playable models (e.g. `Imported_Playable_Gallimimus_Model_Set` is blocky `Part` + `UnionOperation`, not rigged mesh); placeholder `glow_ball` neon food markers; rectangle-plus-ball placeholder trees; unrated AI-generated primitives lacking collision meshes / naming / perf tags.
- **Creator Store imports (22 materialized):** e.g. `G014B6_RiverRocks` (230489811), `G014B4_DesertRock` (4490168579), `G014B6_JungleLog` (5380493574), `G014B6_BrokenConcreteWall` (555552023), `G014B6_RustyPipes` (11469354822), `G015_Import_volcano_rocks_lava` (110082641596723). Generally high-quality low-poly meshes — but only **22 of 500** required for the release gate.
- **Self-rolled mechanics / UI:** HUDController (kid-friendly survival dashboard), MobileControlsController (thumb-cluster action buttons), modular server services (PlayerData, Combat, Survival, Grouping).

### Critical gameplay gaps flagged
- **NPC locomotion:** NPCs are anchored; movement falls back to `PivotTo` translation on a 1-second tick (8-stud teleport steps) because models lack Humanoids / are anchored. Recommended fix: unanchored `HumanoidRootPart` + `Humanoid` + `Animator`, run `Humanoid:MoveTo` on heartbeat.
- **Missing animations:** all `SpeciesConfig.AnimationIds` are empty strings → static T-poses, sliding.
- **Nesting/reproduction:** `NestService.lua` is a dummy (only adult-check + state vars); no visual nesting, egg hatching, or parenting.
- **Alpha/growth:** 100% growth → "Adult" but no visual/mechanical Alpha status (Alpha is only a name-sort herding tag).
- **Predation safety:** hatchlings highly vulnerable to PvP outside NurseryGrove; herbivores lack physics-based defensive moves.
- **Scavenging/fossils:** raw stat grants, no interactive mini-games.

### Recommended roadmap (waves)
- **Wave 1 — Locomotion & nomenclature:** resolve pterodactyl→pteranodon, plumb Spinosaurus (SemiAquatic, SwampDelta), fix NPC locomotion (real Humanoid + MoveTo).
- **Wave 2 — Animation & asset sourcing:** map Creator-Store dinosaur Walk/Run/Idle/Eat/Drink/Attack animation IDs into `SpeciesConfig.AnimationIds`; replace blocky props with rated environment packs; review the ~744 legacy scripts and looped sounds in the raw packs, then adapt useful movement/animation/audio behavior and disable only incompatible leftovers.
- **Wave 3 — Mechanics expansion:** interactive nesting (physical Nest, Lay Egg prompt, hatch-from-nest respawn); Become Alpha (DNA-sacrifice ascend challenge, 1.2× scale, glow/shader, `AlphaRoar` pack buff); physics combat feedback via native `HumanoidRootPart:ApplyImpulse` + Creator-Store VFX (keep existing 70-line floating-damage readout).

---

*Source: antigravity (Gemini) session `b7bf5f93`. Folded into the repo on 2026-05-30. Cross-reference: `eggBreakers_STATUS.md`, `docs/G026/PlanningCountContradictionReport.md`.*
