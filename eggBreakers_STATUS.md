# eggBreakers — Consolidated Status Index

**Authoritative snapshot. Last validated: 2026-05-30** (live Studio, leader-driven). Supersedes older dated numbers elsewhere.

Roblox dinosaur-survival vertical slice. 6 biomes: NurseryGrove → FernPlains → JungleBasin → SwampDelta → RedstoneCanyon → ApocalypticCity. Rojo-managed (`src/`), place `eggBreakers2.rbxl`.

---

## 1. Current validated state
- **Tests:** 243 total / 223 passed / 20 failed. The 20 are content/release-gate + 2 pre-existing FlightSwim, plus one rotating **world-dependent flaky** suite (CombatServiceTests / E2E_CarnivoreSurvival) — **no logic regressions**.
- **Branch:** `main` synced to origin. Working tree clean (place `.rbxl` left uncommitted by design).

## 2. Shipped this session (committed to main)
- **Real dino visuals** — recovered the 56 rigged mesh species (your `Rigged Dinosaur Models` pack, re-inserted → `Workspace.dinosaur`); `StagedMeshLibrary` maps all 8 playable species → real meshes; **NPCs and player render as real dinos** (was: default avatar + 88–172-part primitives).
- **Food readability + diegetic sense-guide** — visible edible foliage/carcass; `SenseGuideController` (diet-aware nearest-target highlight + distance + icon) replacing the misleading arrow.
- **Combat** — server attack telegraph + NPC overhead health bars + apex-threat UI.
- **Life cycle** — nesting (lay-egg / hatch-from-nest), growth stage-up + Alpha, **dying pipeline** (death→settle→carcass→despawn); hatch/Alpha remotes wired.
- **NPC hygiene** — stale/excess/primitive NPC despawn so only real-mesh dinos remain.
- **Per-species test matrix** + terrain/world-builder code + **`WorldDressingService`** (scatter + raycast-ground placement engine).

## 3. World-population pipeline (proven, ready to run)
- **Source (quality):** `Roblox_Search` fork on `place1` → `search_assets` (favorites-ranked) → `preview_asset`.
- **Place into game:** `Roblox_Studio` proxy on `eggBreakers2` → `search_creator_store` → `insert_from_creator_store` (verified: inserted a clean 12-MeshPart tree).
- **Dress:** `WorldDressingService:DressBiome(biomeId, model, opts)` → scatter + ground + tag per biome.
- **Vetted megapack targets:** Nature `6503281311` · Desert/Canyon `5517265199` · Destroyed buildings `13451762331` · Vines `15618055880` · Lily pad `405880646` · Skyboxes `102765136165948`.

## 4. Honest gaps / open work
- 🔴 **Map still flat/undressed** — environment assets not yet *placed* (pipeline ready; serial campaign next). #29 boundary (cliff/ocean/fence + far silhouettes), #30 dress 6 biomes.
- 🟠 **Flight/swim** — 2 tests red; **no rated Creator asset exists** (searched), so it's bespoke code with a deeper `IsFlightUnlocked`/harness blocker; deferred for a hands-on fix (#22).
- 🟠 **NPC locomotion** — still teleports (anchored, no Humanoid); needs Humanoid:MoveTo + Animator (#19, plan ready).
- 🟠 **Animations** — `SpeciesConfig.AnimationIds` empty → dinos static; no rated animation pack found (lead: same-creator `Dinosaur morphs` 9840203800).
- 🟠 **Audio** — none; plan ready (#31).
- ⚠️ **PERSISTENCE** — the recovered `Workspace.dinosaur` pen + inserted assets are **live-only**. **Save the place (⌘S)** or they're lost on restart (no MCP "save place" exists).

## 5. Tooling / provenance
- **MCP split:** `Roblox_Studio` (proxy → `eggBreakers2`, all build/test/play); `Roblox_Search` (kevinswint fork → empty `place1`, search/preview only). One Studio plugin each → search is serial; fork's first call after idle may time out (retry).
- **Concurrency:** omx/oh-my-codex agents may run detached and write files / leave `.git/index.lock` — see `memory/eggbreakers-concurrent-agents.md`.
- Design docs: `eggBreakers_Master_Plan.md`, `eggBreakers_World_and_Gameplay_Design.md`, `eggBreakers_Asset_Ledger_and_Build_Sequence.md`, `DESIGN.md`, `docs/StoryModeStoryboard.md`, `docs/SWARM_HANDOFF.md`.

## 6. Next
Serial world-pop campaign: insert the nature megapack → `DressBiome` NurseryGrove + FernPlains → boundary → screenshot → iterate biome by biome. Then locomotion + animations to make the world *move*.
