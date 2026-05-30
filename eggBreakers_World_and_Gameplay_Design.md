# eggBreakers — World & Gameplay Design + Asset Sourcing

> Companion to `eggBreakers_Master_Plan.md`. This doc captures the creative direction (world, story, mechanics) and pairs every need with live Creator Store research. Goal: a real, natural world — not a flat green plane with a drop-off, broken square water, and default Roblox sky.

---

## 1. What's Wrong With the World Today (validated)
- **Flat terrain with a hard drop-off edge** — reads as a test baseplate, not a world.
- **Broken water** — shallow square "generated Part" plates, untagged, one too deep to swim.
- **Default Roblox sky** — no atmosphere, no mood, no time-of-day identity.
- **Empty far distance** — biomes float far apart with nothing on the horizon; the edge of the map is just void.
- **~6% dressed** — almost no trees/rocks/props; the few that exist are invisible-helper placeholders.
- **Primitive creatures** — block/union dinos, no animation, teleporting.

We fix this by **building a real terrain world inside a decorated boundary, under a custom sky, dressed with high-rated imported assets.**

---

## 2. World Design

### 2.1 Real Terrain (not a plane)
Use Roblox **Terrain** (not flat Parts) sculpted per biome with elevation, cliffs, valleys, beaches, and terrain water. Each biome gets its own material palette and height profile so traversal feels natural and hides the map edge behind landforms.

### 2.2 The Six-Biome Map (condensed, contiguous)
Lay biomes in a ring/spiral so the player journeys outward from the safe center. Condense centers so there's no long empty walk (fixes the placement test).

```
                 [ MountainNestingCliffs ]
        [ RedstoneCanyon ]        [ ApocalypticCity ]
                 \                /
                  [  JungleBasin ]            <- danger ramps up outward
        [ FernPlains ]            [ SwampDelta ]
                 \                /
                  [ NurseryGrove ]            <- safe spawn (center)
```

### 2.3 Decorated Boundary Ring (no drop-off, no invisible wall feel)
Ring the playable area with **layered scenery**: an inner natural barrier (cliffs, dense forest, rubble, fences/old walls near the city) plus **far-away decorative assets on the horizon** (distant mountains, silhouettes, ruined skyline) that are non-collidable and purely for depth. The player feels enclosed by *world*, not by a wall. Use a thin invisible collision wall behind the scenery so no one walks off the edge.

### 2.4 Custom Sky & Atmosphere
Replace the default skybox with a curated one + `Atmosphere`, `Lighting`, and optional gentle day cycle. Mood per region: soft dawn over NurseryGrove → harsh sun over RedstoneCanyon → overcast/ash over ApocalypticCity. **Cut the broken rain element**; reintroduce weather only as a tasteful, optional polish later (it's currently scope-frozen anyway).

### 2.5 ApocalypticCity (the showpiece biome)
The only human trace — an overgrown, collapsed city reclaimed by nature and ruled by the apex. Ruined towers, broken roads, rubble, rusted vehicles, vines over concrete, ash light. It's the endgame frontier and the horizon landmark visible from earlier biomes.

### 2.6 Water Redesign
Replace square Part plates with **Terrain water** (rivers, lakes, swamp) or quality water meshes — correct depth, shorelines, flow. Drinking and (later, when un-gated) swimming attach to real bodies of water. All water tagged to release standard.

---

## 3. Gameplay Design

### 3.1 Core Loop (unchanged spine, upgraded feel)
Hatch → sense needs → **find food/water** → grow (4 stages) → **fight/flee** → survive deeper biomes → reach the city. The ecosystem is the only quest-giver.

### 3.2 Improved Food Finding
Today NPCs/players eat via raw nearest-tagged scans with placeholder food. Upgrade:
- **Real foliage food** (ferns/bushes/fruit) for herbivores, **carcasses** for carnivores, scavengeable scraps for omnivores.
- **Scent/sense UX:** on-screen directional hint or highlight to the nearest valid food for your diet when hunger is low (readable, not a minimap dump).
- **Diet-correct filtering** fixed (omnivore/herbivore metadata bug).
- **Depletion & regrowth:** eaten foliage depletes and regrows on a timer so the world feels used but recovers.

### 3.3 Improved Fight Mechanics
- **Telegraphed attacks** (wind-up anim) + **hit feedback** (damage numbers, flash, impact VFX, SFX, camera shake).
- **Responsive, readable damage:** every hit shows the exact damage dealt (floating combat number), the target's health bar drains in real time, and your own health/stamina react instantly — so you always understand how much damage you're doing and taking. Crits/heavy attacks read distinctly (bigger number, harder shake).
- **Weight by species/stage:** bite/claw/headbutt/lunge with stamina costs already in config — wire them to anims and feel.
- **NPC health + threat UI** overhead and apex-event screen signal.

### 3.4 Carnivore Predation — Eating NPCs *and* Players (new mechanic)
Carnivores can **hunt, kill, and feed on** both AI prey and other players:
- **Kill → carcass → feed:** defeating prey spawns a carcass food source (already modeled for NPCs) that any carnivore/omnivore can eat to restore hunger and gain growth. Extend the same path to **defeated players** (player dies → respawns as egg, leaves a carcass the killer can eat).
- **Balance & safety rails:**
  - **Safe zones** (NurseryGrove) forbid PvP predation — hatchlings can't be farmed.
  - **Size/stage gating:** can only meaningfully prey on creatures within a stage band (no adult T-Rex one-shotting hatchlings for trivial reward; or reduced reward to discourage griefing).
  - **Server-authoritative** damage & kill credit (already the pattern) to prevent exploits.
  - **Reward curve** tuned so hunting is worth it but spawn-camping isn't.
- **UX:** clear "you were hunted by X" / "you fed on X" feedback; carcass clearly readable in-world.

### 3.5 Movement Modes — Ground, Flight & Swim (all in scope)
All three traversal modes are **core mechanics**, with species mapped to each:
- **Ground** (default): gallimimus, triceratops, velociraptor, carnotaurus, tyrannosaurus, oviraptor.
- **Flight** — add/enable a **flyer** (e.g. pterosaur): `Flight=true`, real airborne movement via BodyVelocity/AlignPosition, stamina-gated takeoff, altitude control. Fix `FlightService` so the unlock is actually granted (today it always returns `flight_locked`). NPC flyers must use the same real physics, not faux-Y float.
- **Swim** — add/enable an **aquatic/semi-aquatic** species (e.g. spinosaurus): `Swim=true`, swim triggers on real Terrain-water bodies, with the **Oxygen/drowning** loop active. Unify `MaxOxygen` to one constant (currently 60 in config vs 100 in service).

Lift the `Constants.ScopeFreeze` ban on Flyers/Aquatics once these land, and update the gate tests. Keep one source of truth per stat/flag.

---

## 4. Storyboards

### 4.1 First-Session Journey (six beats)
1. **Hatch** — egg cracks at NurseryGrove dawn, custom sky glowing; camera reveals a small, *animated* dinosaur.
2. **First needs** — nibble real ferns, drink at a clear terrain pool; diegetic HUD teaches hunger/thirst.
3. **Cross the threshold** — leave the grove into FernPlains; a herd scatters; the world reacts.
4. **First hunt/threat** — a predator call; threat indicator pulses; flee, hide, or (as carnivore) chase and feed.
5. **Growth** — feed enough → visible stage-up, stats rise, ability unlocks; earned power.
6. **The horizon** — distant ruined-city skyline over the boundary ring; the promise of the endgame. Loop hook.

### 4.2 Carnivore Power-Fantasy Beat (storyboard)
1. Adult carnivore stalks a gallimimus herd from JungleBasin cover.
2. Telegraphed lunge → impact VFX → prey down → **carcass**.
3. Feed animation; hunger restored; growth ticks.
4. Another **player** carnivore contests the carcass — tense standoff → fight → the world has emergent drama.

### 4.3 Boundary & Vista (art direction board)
NurseryGrove foreground (lush, safe) → mid-ground biomes → **decorated boundary** (cliffs/forest/old city walls) → **far horizon silhouettes** (mountains, ruined towers) under a custom atmospheric sky. No visible edge, no flat void.

---

## 5. Asset Sourcing Shortlist (live Creator Store research)

Searches run through the Studio MCP. **✅** = strong category matches returned; **◇** = weak/no types, refine query or use Terrain tools at insert time.

| World need | Query used | Result | Action |
|------------|-----------|--------|--------|
| Rigged dinos (playable + NPC) | "rigged animated dinosaur" | ✅ dinosaur, creature, monster, npc | insert top-rated, strip scripts, keep rig |
| Creature animations | "dinosaur creature animation pack walk run idle" | ✅ dinosaur, creature, npc, pack | fills empty AnimationIds (BR-02) |
| Biome dressing | "low poly nature trees rocks environment pack" | ✅ tree, landscape, plant, rock, nature pack, forest, mountain | dress all biomes |
| Food foliage | "low poly plants ferns bushes foliage food" | ✅ plants, rocks, vegetation, fern, flowers | herbivore food sources |
| Custom sky | "skybox sky atmosphere" | ✅ skybox, background image | replace default sky |
| Boundary ring | "stone wall fence boundary barrier ruins" | ✅ structure, fence, wall, building, castle wall | decorated edge + city walls |
| Combat VFX | "impact hit blood particle VFX effect" | ✅ effect, blood splatter, blood, liquid, explosion | hit feedback (3.3 / E.3) |
| City rubble & vehicles | "rubble debris wrecked car ruins destroyed" | ✅ vehicle, car, scene, environment, prop | ApocalypticCity dressing |
| Creature SFX | "dinosaur roar growl animal sound effects" | ◇ returned 3D types — run a dedicated **Audio** search at insert | roars/bites/ambient (empty `Sounds`) |
| Realistic terrain biomes | "realistic terrain biome environment pack" | ◇ no strong types — refine ("low poly biome kit", "terrain pack") | refine + use Terrain tools |
| Apocalyptic city | "post apocalyptic ruined city buildings pack" | ◇ no strong types — use rubble/vehicle/wall results above | combine refined queries |
| Realistic water | "realistic water lake river" | ◇ no strong types — prefer **Terrain water** | use Terrain water + shoreline meshes |

**Search-completeness note:** still un-queried and worth a pass before build — dedicated **Audio/SFX** assets (Creator Store audio is a separate index), and **egg/nest** props. Everything else above has a confirmed category match.

**Sourcing rule (locked):** insert → run `AssetImportAuditService:AuditAndRepair({mutate=true})` to strip/quarantine bundled scripts → tag `SourceAssetId`/`AssetManifestId`/`CreatorStoreOnly` → keep mesh+rig only → behavior from our services. Verify free/commercial license before shipping.

---

## 6. Existing-Asset & Script Audit (start-from-scratch inventory)

**Cut from shipping build:**
- JPOG dino rips (`Dino Pack!`, `rex`, loose Workspace dino models) — **mesh/rig salvageable, 744 legacy scripts must be stripped**.
- Primitive `Imported_Playable_*` block/union dino sets — replace with rigged imports.
- Placeholder "ball"/square food & water Parts.
- Invisible-helper trunk/canopy "trees".
- Default skybox; broken rain.

**Keep / repurpose:**
- All server **services** (`NPCService`, `CombatService`, `SurvivalService`, etc.) — solid engine, keep.
- `AssetImportAuditService` + quarantine — the cleanup tool.
- The **test suite** — re-baseline as content lands.
- New pack **meshes + rigs** — after script strip + tag.

**Script policy:** zero imported executable Scripts in the shipping Workspace. Behavior is ours. Imported ModuleScripts only if audited + sandboxed.

---

*Pairs with the Master Plan's parallel workstreams. This doc defines the "what it should be"; the Master Plan defines the "who builds what, in what order."*
