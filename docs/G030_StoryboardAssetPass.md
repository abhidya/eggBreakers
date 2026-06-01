# G030 Storyboard Asset Pass

Status: **docs-only asset-first placement plan**.

Date: 2026-05-31

Scope: storyboard asset/design lane only. This pass does not import assets, move Studio instances, edit source, or claim release proof. It audits `docs/StoryModeStoryboard.md`, `docs/G029_StoryAssetDrivenBatch.md`, `docs/AssetCandidates.md`, and `docs/G018/ASSET_SEARCH_SWARM_RESULTS.md` against the current screenshot complaint: the map still reads flat/boxy and the inserted assets read too tiny to carry the story.

## Diagnosis

G029 improved the opening beats with a nest, secondary rustle nest, and plant pack clones, but the composition is still asset-light:

- One or two small imported models per zone are not enough to overcome primitive terrain.
- New direct searches confirm the current gap is breadth and density: vegetation clusters, food variety, prey/ambient creatures, water/lake reads, corpse/bone set pieces, mobile survival HUD affordances, and NPC behavior references.
- Current placements need to be treated as markers inside larger authored set pieces, not as final visual coverage.
- The next pass should import or reuse fewer, larger, unmistakable silhouette anchors first, then add scatter only after the beat reads from gameplay camera distance.
- Each beat needs a foreground interaction asset, a midground landmark, and a background/horizon shape. Tiny detail props should not be inserted until those three reads are solved.
- Script-bearing catalog assets should be reviewed and adapted when they contain useful behavior. The goal is not lazy script removal; the goal is owned, understood behavior with unreviewed remotes, persistence, and unsafe side effects kept disabled until rewritten or wrapped.

## Asset-First Placement Rules

1. Start every live insert with the camera read, not the catalog count.
2. Place at least one hero-scale asset cluster per beat before adding scatter.
3. Use existing `Workspace.Map.ImportedAssets/G029_StoryAssetDrivenBatch` placements as seed locations, but scale or surround them with larger authored clusters.
4. Reject any candidate that only reads when zoomed in, creates a tiny dot on flat ground, or needs a label to explain its role.
5. For Creator Store insertion, use the authorized Studio path from the G018 notes: exact Studio search query, insert from Creator Store result, then stamp source id, script audit status, zone, placement role, and screenshot proof.

## Direct Search Swarm Shortlist -- 2026-05-31

Direct helper used: `node tools/roblox_search_direct.js search_assets '{"query":"...", "max_results":5}'`, then previewed shortlisted ids. This is the import order for the next asset-first implementation pass; none of these count as placed or release-ready until Studio insertion, script review, grounding, screenshot proof, and audit pass.

| Rank | SourceAssetId | Candidate | Storyboard beat/gate | Action |
| --- | ---: | --- | --- | --- |
| 1 | `10301700052` | `Dinosaur NPCS Pack REMASTERED` | Beat 2 predator/prey choice, 50+ hatch/NPC visual readiness | Primary dinosaur roster import; quarantine and audit rig/script/collision footprint. |
| 2 | `9784445039` | `Dinosaur npc pack` | Beat 2 backup 50+ roster | Keep as fallback if the remaster pack is too heavy or brittle. |
| 3 | `95133385212578` | `Pathfinding npcs AI Follow Navigate Enemy Script` | Beat 2 movement, Beat 4 ambush, Beat 6 apex threat | Read scripts for path recompute/aggro ideas; port into owned CPU-budgeted NPC code. |
| 4 | `5643011147` | `Animal Flock` | Beat 2 herd cohesion and ambient life | Review flocking/wander behavior and adapt into prey/herd systems. |
| 5 | `136851548154128` | `Attacking NPC Punch Faceless Robot Android` | Beat 2 fight response, Beat 6 apex combat read | Review attack cooldown and hit reaction patterns as combat reference. |
| 6 | `95482576700075` | `Food Boxes Variety Pack Grocery Fruits Veggies` | Beat 1 food lesson, Beat 8 diet variety | Import visual food variety and adapt any pickup/eat scripts only after review. |
| 7 | `2915526744` | `Low Poly Plant Pack` | Beat 0/1/4/5/8 vegetation density | Use as high-readability vegetation cluster source. |
| 8 | `82422796413615` | `Pond Pond Lily Rocks Reflection Peaceful Water Koi` | Beat 5 drinkable water visual gate | Extract pond/shoreline/lily visuals; keep drinkability in owned `WaterService`. |
| 9 | `131340001261404` | `Hydration GUI Script Thirst Water Drinkable UI` | Beat 1/5 thirst affordance | Script-bearing UI reference; quarantine, read, and adapt to owned HUD. |
| 10 | `110801640375836` | `Monochrome White UI Icon Pack` | Beat 0-8 mobile survival icon gate | Visual icon source for mobile affordances. |
| 11 | `128301661731715` | `Simple Health Bar GUI Display Vitality Meter Statu` | Beat 0-8 health/growth readability | Compact HUD visual reference. |
| 12 | `123830443378354` | `Dead Bacon Pork Meat Food Props 3D Model` | Beat 1 carnivore carcass/meat gate | Meat prop reference; verify it reads as in-world carcass food. |
| 13 | `5663348866` | `Visitor Center Fossils` | Beat 6 bones/fossils, Beat 7 ruins mystery | Fossil/bone landmark source, with collision/script audit before placement. |

## Beat Asset Plan

| Beat | Needed camera read | Primary asset IDs / search queries | Placement plan |
| --- | --- | --- | --- |
| Beat 0 Egg wakeup | A nest bowl and eggs dominate the hatch camera; the baby dino is visibly born in a protected place, not on a flat plate. | Accepted/live: `8895193` Dinosaur eggs in a nest, `93304870` nest. Candidates/search: `134872049070713` Dinosaur Nest Prehistoric Cave Eggs Hatchery RP; `1679857865` wood pick up (branch); `150068032` Scrambled Eggs in a Nest; `101855130` Egg Nest; query `dinosaur egg nest`; query `dinosaur nest eggs fossil bones prehistoric`. | Build a 12-18 stud nursery nest composition around the hatch point: primary egg/nest at player scale, branch ring around it, 2-3 foliage walls behind it, and a clear exit corridor toward first food. Existing G029 nests should become the core, not the whole scene. |
| Beat 1 First food/water | Food and water are readable before UI appears. Herbivore food is green/fruit/plant variety, carnivore food is meat/bone/carcass, water has an edge. | Accepted/live: `12630982706` PreHistoricPlantPack. New direct candidates: `95482576700075` Food Boxes Variety Pack Grocery Fruits Veggies; `84374663188587` Food Mesh Pack Aesthetic Summer Low Poly Asset; `12061127971` Bowl of Berries; `85041264042784` Fruit Models; `97564378130720` Pork Model; `8114193948` Steak; `5663348866` Visitor Center Fossils; `126241039` Tyrannosaurus Skeleton; `82422796413615` Pond Pond Lily Rocks Reflection Peaceful Water Koi. Search queries: `vegetation food variety pack berry fruit mushroom plant edible survival scripts`, `raw meat food pack steak bone carcass`, `drinkable lake water pond river low poly water plane scripts`. | Replace lone food dots with diet-specific stations: three distinct herbivore forage clusters, one carnivore bones-plus-meat cache, and one pond/shoreline cluster. If imported food packs include scripts, review pickup/eat/tool behavior and adapt useful parts into owned food prompts rather than deleting them blindly. |
| Beat 2 Predator/prey choice | A herd silhouette, small prey/ambient motion, and a predator silhouette are visible across FernPlains. | Primary roster leads: `10301700052` Dinosaur NPCS Pack REMASTERED; backup `9784445039` Dinosaur npc pack. Existing dino candidates/search: `102772249876319` Rigged Dinosaur Models, `129426942556570` Rigged Dinosaur Models 2, `9371720275` Raptor Character!, `8585959958` VelociRaptor Blue, `9961766535` cool dino, `10566989115` Ridable Raptor (Dino War), query `rigged animated dinosaur npc scripts`. Prey/AI candidates: `4987660875` Walking Animal Kit; `12830467683` animal pack; `9564989831` High Quality RABBIT Model; `95133385212578` Pathfinding npcs AI Follow Navigate Enemy Script; `5643011147` Animal Flock; `136851548154128` Attacking NPC Punch Faceless Robot Android. | Stage a wide herd/predator tableau with ambient prey between food and danger. Review/adapt walking, flee, pathfinding, aggro, and attack scripts into owned NPC boundaries; keep imported behavior quarantined until code-reviewed, but do not discard useful behavior just because it arrived as a script. |
| Beat 3 Growth moment | The before/after body scale is obvious and has a clean rest-cover location. | Dino mesh candidates from Beat 2 plus existing staged starter meshes. Cover/search: `low poly bush`, `forest pack foliage`, `meshpart pbr foliage and nature pack`, query `forest pack foliage`. UI/icon reference: `110801640375836` Monochrome White UI Icon Pack. | Put the growth rest spot beside a recognizable shelter cluster, not in an open square. Use a fixed comparison object like a stump, bush, or nest branch so screenshot proof can show the hatchling-to-juvenile scale change. |
| Beat 4 JungleBasin ambush | Dense, occluding jungle corridor with a readable ambush path. | G029/live: `12630982706` PreHistoricPlantPack. New direct candidates: `16926013033` Classic Jungle Pack; `76411335285660` Small Tree Boulders Rocks Nature Forest Decor; `139313340758271` Tropical PBR Plants Classic Nature Aesthetic Grow; `110016223641862` Tropical PBR Plants Realism Jungle Trees RP. Existing candidates/search: `72003029540472` vines hang roots jungle cave ivy moss leaf decor; `18242667178` [HD] Vegitation Pack; `259909318` Plants; query `low poly jungle swamp canyon biome pack`. | Author a narrow corridor with 2 high foliage walls, hanging vines at head height, ambient prey/rustle markers, and one predator reveal pocket. Adapt any wind/sway/interaction scripts into owned decoration behavior if they help the jungle feel alive. |
| Beat 5 SwampDelta swim/fish | Water is a biome: shore, reeds/lilies, fish movement, oxygen risk. | Fish candidates/search: `6923368893` Mulet fish Mesh, `711629760` Fish, `135378314068756` Fishy Aquatic Ocean Water Fish School, `100298727033570` Salty Fish School Aquatic Ocean Water Swim Scho, query `fish school water`. New water candidates: `82422796413615` Pond Pond Lily Rocks Reflection Peaceful Water Koi; `83768002206979` Fish Pond with Fish Peaceful Lily Koi Aesthetic; `106480076` Small Lake; `122638802` Small Pond in a Hilly Biome. Swamp candidates: `86198817809169` Lily Pad Frog Green Water Lily; `95359664633430` Koi Pond Bridge Water Rocks Lily Aesthetic; `12598461005` Realistic Southern Swamp Trees Pack; `18986634714` Swamp Trees. | Insert visible pond/lake edge first, then reeds/lily pads at the shoreline, then 5-8 fish clones or a fish-school model inside the water volume. Large map-style ponds should be mined for water/shoreline pieces, not imported wholesale. |
| Beat 6 RedstoneCanyon apex trial | Red cliffs, skull/bones, a carcass/fossil foreground, and a large apex silhouette make the player feel small. | Bone/fossil candidates/search: `5663348866` Visitor Center Fossils; `126241039` Tyrannosaurus Skeleton; `77853682434184` Dino Fossil Exhibit Museum Prop Ancient Bones; `139996849216182` Dino Fossil Museum Exhibit Bones; `117562283357615` T-Rex Skull Gothic Bone Build Decor; `77970470720479` T-Rex Skull Decor RP Horror Spooky; query `dinosaur corpse bones carcass skeleton fossil ribcage dead dinosaur`. Apex/AI candidates/search: `9881605049` Animatable Godzilla Model as reference-only fallback; `95133385212578` pathfinding NPC AI; `9113985717` creature roar SFX. | Fix canyon identity with 3 large vertical rock/cliff silhouettes and a foreground fossil/skull/carcass pickup. Review NPC combat/pathfinding scripts as behavior references for apex threat staging; add roar/audio only after visual threat staging exists. |
| Beat 7 ApocalypticCity mystery | One frame shows ruined human world: wreck, wall/building, overgrowth, danger. | City candidates/search: `125968528580422` Destroyed Building Ruined City Apocalypse RP; `91515408060922` Ruined Vehicle Pack Car Wreck Decayed Debris; `118944114691030` Destroyed Cars Wreckage Vehicles Debris Pack; `136643767057529` Abandoned Truck Rusty Wreck Derelict Vehicle; `4675550604` Broken Car; `4449997799` Megaphone; overgrowth candidates `16926013033`, `76411335285660`, `139313340758271`; fossil hook `5663348866` or `126241039`; search `apocalypse city ruins wrecked car rubble low poly`. | Build the city approach as a silhouette gateway: one ruined building/wall, one wrecked vehicle in the path, overgrowth swallowing it, and one fossil/apex hook. Broken Car alone is useful but too small; pair it with a large ruined building or truck. |
| Beat 8 Nest, lineage, alpha | Adult nest/home is a defendable territory landmark, not the same tiny nursery prop copied into empty space. | Nest candidates from Beat 0: `8895193`, `93304870`, `134872049070713`, `1679857865`; bone/danger dressing `117562283357615`; UI icon reference `110801640375836`; query `dinosaur egg nest`; query `dinosaur nest eggs fossil bones prehistoric`. | Use a larger adult nest ring with branch scatter, egg focal point, and one territorial landmark visible from approach. The home marker should be diegetic: nest shape plus subtle icon, not only a floating arrow. |

## Reject / Defer List

| Candidate / area | Decision | Reason |
| --- | --- | --- |
| `85917246797063` desert/oasis landscape | Reject for G030 live insert | G029 already rejected it as oversized and semantically wrong for Redstone canyon dressing. |
| Water/shoreline arena-map results from `water shoreline rocks river lake environment pack` | Reject | Search returned battleground arenas and unrelated maps, not usable water edge assets. |
| `Poorly modelated terrain` `13023826437` | Reject | The current complaint is flat/boxy terrain; importing poor terrain reinforces the problem. |
| Most `animal carcass meat bone raw food mesh` results from G018 | Defer | The G018 search was noisy with humanoid parts, decals, unrelated SFX, and no clean carcass result. Use the more targeted carcass/meat queries from `AssetCandidates.md`. |
| `survival ui icon pack compass marker waypoint` raw results | Defer | G018 found mostly unrelated meshes/decals/audio. Keep repo-owned HUD work or use the Location Marker System only as a reference until a clean UI asset/module is reviewed. |
| `Pack poly by me` `4596418748` | Defer | Huge broad pack with 643 MeshParts and 14 scripts; too noisy for a focused storyboard pass. |
| Jurassic Park/World named dinosaur MeshParts, including `981164890`, `984698485`, `492443960` | Defer / prototype-only | IP risk and static mesh-only signal. Do not promote to publish path without rights review. |
| `9881605049` Animatable Godzilla Model | Reference-only | Apex-sized and animated, but not dinosaur-specific enough and likely IP risk. |
| `6884562726` DOD:S Italy House Clumps | Reference-only | Useful ruined-house benchmark, but title suggests ripped game content/IP risk. |
| `100298727033570` Salty Fish School Aquatic Ocean Water Swim Scho | Defer / prototype-only | No scripts reported, but description says meshes are not uploader-owned. |
| Tiny single-asset scatter in open zones | Reject as placement pattern | The screenshot problem is scale and composition. Tiny props should follow, not lead, each beat. |

## Exact Next Live Insert Priorities

These are reordered around the newest evidence: the next live pass should first make the world dense and interactive, then add script-reviewed behavior. Direct search/preview evidence is summarized in `docs/AssetCandidates.md`.

1. **Vegetation and forage density pass**
   - Search/insert order: `Classic Jungle Pack 16926013033`, `Small Tree Boulders Rocks Nature Forest Decor 76411335285660`, `Tropical PBR Plants Classic Nature Aesthetic Grow 139313340758271`, then reuse `12630982706`.
   - Placement: make Beat 0/1/4/5/8 read as nested, forageable, and occluded: foliage walls, dense ground cover, shelter clumps, and approach framing.
   - Script handling: review any wind/sway/growth scripts and adapt useful visual motion into owned decoration code.
   - Stop condition: gameplay-camera screenshots show foliage density before labels or UI explain the zone.

2. **Food variety and carnivore carcass station**
   - Search/insert order: `Food Boxes Variety Pack Grocery Fruits Veggies 95482576700075`, `Food Mesh Pack Aesthetic Summer Low Poly Asset 84374663188587`, `Bowl of Berries 12061127971`, `Fruit Models 85041264042784`, `Pork Model 97564378130720`, `Steak 8114193948`, then `Visitor Center Fossils 5663348866` or `Tyrannosaurus Skeleton 126241039` as bone/carcass silhouette.
   - Placement: build separate herbivore forage, fruit/berry, and carnivore meat/bone stations so food does not look like repeated dots.
   - Script handling: review pickup/eat/tool scripts and port only useful prompt/state logic into owned food systems.
   - Stop condition: herbivore and carnivore food are distinguishable without UI text.

3. **Prey and ambient creature pass**
   - Search/insert order: `Walking Animal Kit 4987660875`, `animal pack 12830467683`, `High Quality RABBIT Model 9564989831`, then fish candidates `711629760`, `135378314068756`, and `6923368893`.
   - Placement: add small prey clusters between player, food, and predator beats; add fish groups only after water is visually readable.
   - Script handling: review wander, walking, flee, and animation scripts and adapt behavior into owned NPC/ambient spawning boundaries.
   - Stop condition: Beat 2 and Beat 5 contain visible life, not only static props.

4. **Drinkable lake and shoreline pass**
   - Search/insert order: `Pond Pond Lily Rocks Reflection Peaceful Water Koi 82422796413615`, `Fish Pond with Fish Peaceful Lily Koi Aesthetic 83768002206979`, `Small Lake 106480076`, then use `Small Pond in a Hilly Biome 122638802` only as a source/extraction reference because preview showed a huge 743.8 x 139.0 x 744.7 stud map.
   - Placement: water plane/edge first, shoreline rocks/reeds/lilies second, fish/ambient motion third, drinkable helper volumes hidden under visible water.
   - Script handling: adapt only local visual motion or fish movement scripts; keep drinkable gameplay owned by project water systems.
   - Stop condition: screenshot reads as a drinkable/swimmable lake habitat.

5. **Mobile survival UI kit pass**
   - Search/insert order: `Custom Inventory 94781121605731`, `Simple Health Bar GUI Display Vitality Meter Statu 128301661731715`, `Monochrome White UI Icon Pack 110801640375836`.
   - Placement: use icons/status frames for hunger, thirst, health, nest/home, call/roar, and objective prompts after the physical beat reads.
   - Script handling: `94781121605731` preview showed 2 direct scripts; review input handling, remotes, datastore calls, and layout code. Adapt UI modules into owned HUD controllers; do not keep catalog persistence/remotes live.
   - Stop condition: mobile HUD affordances are clear and do not replace physical world readability.

6. **NPC combat/AI script review pass**
   - Search/insert order: `Pathfinding npcs AI Follow Navigate Enemy Script 95133385212578`, `Attacking NPC Punch Faceless Robot Android 136851548154128`, `Interactive NPC Tool - InteractiveNPC 10902562071`, then dino behavior candidates `Ridable Raptor (Dino War) 10566989115` and `cool dino 9961766535`.
   - Placement: use as behavior references for Beat 2 predator/prey, Beat 4 ambush, and Beat 6 apex threat.
   - Script handling: review and adapt path recompute cadence, aggro ranges, attack cooldowns, flee behavior, and animation hooks into owned NPC combat/AI modules. Do not blanket-remove scripts before review, but keep unreviewed behavior quarantined.
   - Stop condition: the first adapted AI behavior is documented with source asset, reviewed script notes, and a gameplay-camera proof clip or screenshot.

7. **Ruined city and canyon landmark pass**
   - Search/insert order: city `125968528580422`, `91515408060922`, `4675550604`; canyon/fossil `5663348866`, `126241039`, `117562283357615`; add overgrowth from priority 1.
   - Placement: large landmark silhouettes first, vehicle/fossil foreground second, overgrowth and small debris third.
   - Script handling: city/fossil assets are mostly visual candidates, but still inspect descendants for hidden scripts, heavy collision, and IP/source risk.
   - Stop condition: one screenshot reads as ruined city and one screenshot reads as apex canyon without labels.

## Live Proof Requirements Before Calling Any Placement Done

- Use authorized Creator Store insertion, not raw `InsertService:LoadAsset`.
- Stamp every accepted root with `SourceAssetId`, `CreatorStoreOnly`, `ImportedVisibleAsset`, `PlacementRole`, `ZoneId`, and script audit attributes.
- Review and quarantine scripts before release counting; do not keep loose imported behavior unless owned, reviewed, and tested.
- Ground and scale each root from the gameplay camera, then screenshot the intended beat.
- Run the existing asset audit after insertion and record honest counts; do not claim G018/G029/G030 final PASS from docs-only work.
