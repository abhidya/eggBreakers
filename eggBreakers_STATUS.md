# eggBreakers — Consolidated Status Index

**Authoritative snapshot. Last validated: 2026-05-31** (live Studio + source build, leader-driven). Supersedes older dated numbers elsewhere.

Roblox dinosaur-survival vertical slice. 6 biomes: NurseryGrove → FernPlains → JungleBasin → SwampDelta → RedstoneCanyon → ApocalypticCity. Rojo-managed (`src/`), active place `eggBreakers3.rbxl`.

---

## 1. Current validated state
- **Tests:** Source build and diff hygiene pass for this checkpoint. Latest live all-category run remains stale until a fresh Studio reload/resync; prior E2E failures were release-gate/cache related, not the current source claim.
- **Branch:** `codex/story-swarm-wave` tracking origin; place `.rbxl` changes remain live-only until manually saved.
- **Live asset gate:** `actuallyImportedAssets=26`, `releaseReadyVisibleAssets=26` after the G027 nest/plant/UI batch. Still FAILS the 500 release target.
- **G028 visual audit:** the screenshot correctly exposed a gap. Starter meshes now have live visual proof from Creator Store asset `18759347676`; see `docs/G028_StarterVisualAudit.md`.

## 2. Shipped this session (committed to main)
- **Real dino visuals** — recovered the 56 rigged mesh species (your `Rigged Dinosaur Models` pack, re-inserted → `Workspace.dinosaur`); `StagedMeshLibrary` maps the current curated starter set plus broader staged roster → real meshes; **NPCs and player render as real dinos** (was: default avatar + 88–172-part primitives).
- **Food readability + diegetic sense-guide** — visible edible foliage/carcass; `SenseGuideController` (diet-aware nearest-target highlight + distance + icon) replacing the misleading arrow.
- **Combat** — server attack telegraph + NPC overhead health bars + apex-threat UI.
- **Life cycle** — nesting (lay-egg / hatch-from-nest), growth stage-up + Alpha, **dying pipeline** (death→settle→carcass→despawn); hatch/Alpha remotes wired.
- **NPC hygiene** — stale/excess/primitive NPC despawn so only real-mesh dinos remain.
- **Per-species test matrix** + terrain/world-builder code + **`WorldDressingService`** (scatter + raycast-ground placement engine).

### 2026-05-31 docs/UX alignment addendum
- **Current curated starters:** source now treats `coelophysis`, `parasaurolophus`, `utahraptor`, and `citipati` as the first-session starter set (`StarterSpeciesService.StarterOrder`, `HatchUIController.StarterSpecies`). Older Gallimimus/Triceratops/Velociraptor/Carnotaurus starter language should be read as historical unless explicitly marked otherwise.
- **Lifecycle UX contract:** the playable spine is hatch selection → movement → eat/drink → rest/sleep with age ticking → growth stages → dying/death age → respawn/nest. Storyboard proof should show these as player-readable states, not just server attributes.
- **Biome insertion contract:** `WorldDressingService` is the asset-backed scatter/ground/tag pipeline. Docs should distinguish pipeline readiness from live inserted assets, screenshot proof, and saved/persisted place state.
- **G027 asset-backed beat batch:** inserted and tagged `8895193` Dinosaur eggs in a nest, `12630982706` Low-Poly Plants Pack, and `110801640375836` Monochrome White UI Icon Pack under `Workspace.Map.ImportedAssets.G027_AssetBackedStoryBatch`; renamed the icon child `Baseball_Bat` to `Bat_Icon` to avoid the old low-quality "ball" false positive.
- **G028 starter visual fix:** inserted/tagged `18759347676` Rigged Dinosaur Models as `Workspace.dinosaur`; verified no scripts and exact starter models for Coelophysis, Parasaurolophus, Utahraptor, and Citipati. Source now avoids hiding the avatar on visual-resolution failure and scales oversized staged hatchlings down to stage-readable size.

## 3. World-population pipeline (proven, ready to run)
- **Source (quality):** `Roblox_Search` fork on `place1` → `search_assets` (favorites-ranked) → `preview_asset`.
- **Place into game:** `Roblox_Studio` proxy on `eggBreakers2` → `search_creator_store` → `insert_from_creator_store` (verified: inserted a clean 12-MeshPart tree).
- **Dress:** `WorldDressingService:DressBiome(biomeId, model, opts)` → scatter + ground + tag per biome.
- **Vetted megapack targets:** Nature `6503281311` · Desert/Canyon `5517265199` · Destroyed buildings `13451762331` · Vines `15618055880` · Lily pad `405880646` · Skyboxes `102765136165948`.

## 4. Honest gaps / open work
- 🔴 **Map still underdressed** — G027 proved a first asset-backed beat batch, but the full 6-biome dressing/screenshot/save campaign remains open. #29 boundary (cliff/ocean/fence + far silhouettes), #30 dress 6 biomes.
- 🟠 **Flight/swim** — 2 tests red; **no rated Creator asset exists** (searched), so it's bespoke code with a deeper `IsFlightUnlocked`/harness blocker; deferred for a hands-on fix (#22).
- 🟠 **NPC locomotion** — still teleports (anchored, no Humanoid); needs Humanoid:MoveTo + Animator (#19, plan ready).
- 🟠 **Animations** — `SpeciesConfig.AnimationIds` empty → dinos static; no rated animation pack found (lead: same-creator `Dinosaur morphs` 9840203800).
- 🟠 **Audio** — none; plan ready (#31).
- ⚠️ **PERSISTENCE** — the recovered `Workspace.dinosaur` pen + inserted assets, including G027, are **live-only**. **Save the place (⌘S)** or they're lost on restart (no MCP "save place" exists).

## 5. Tooling / provenance
- **MCP split:** `Roblox_Studio` (proxy → active `eggBreakers3`, all build/test/play); `Roblox_Search` (kevinswint/abhidya fork → search/preview only). One Studio plugin each; broad parallel search may time out, but exact Studio Creator Store searches were fast for the G027 batch.
- **Concurrency:** omx/oh-my-codex agents may run detached and write files / leave `.git/index.lock` — see `memory/eggbreakers-concurrent-agents.md`.
- Design docs: `eggBreakers_Master_Plan.md`, `eggBreakers_World_and_Gameplay_Design.md`, `eggBreakers_Asset_Ledger_and_Build_Sequence.md`, `DESIGN.md`, `docs/StoryModeStoryboard.md`, `docs/SWARM_HANDOFF.md`.

## 6. Next
Serial world-pop campaign: insert vetted biome asset packs → `DressBiome`/`DressBiomeVaried` NurseryGrove + FernPlains with saved screenshot proof → boundary → iterate biome by biome. Starter proof should begin with Coelophysis, Parasaurolophus, Utahraptor, and Citipati, then locomotion + animations to make the world *move*.
