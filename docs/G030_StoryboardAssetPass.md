# G030 Storyboard Asset Pass

Status: **docs-only asset-first placement plan**.

Date: 2026-05-31

Scope: storyboard asset/design lane only. This pass does not import assets, move Studio instances, edit source, or claim release proof. It audits `docs/StoryModeStoryboard.md`, `docs/G029_StoryAssetDrivenBatch.md`, `docs/AssetCandidates.md`, and `docs/G018/ASSET_SEARCH_SWARM_RESULTS.md` against the current screenshot complaint: the map still reads flat/boxy and the inserted assets read too tiny to carry the story.

## Diagnosis

G029 improved the opening beats with a nest, secondary rustle nest, and plant pack clones, but the composition is still asset-light:

- One or two small imported models per zone are not enough to overcome primitive terrain.
- Current placements need to be treated as markers inside larger authored set pieces, not as final visual coverage.
- The next pass should import or reuse fewer, larger, unmistakable silhouette anchors first, then add scatter only after the beat reads from gameplay camera distance.
- Each beat needs a foreground interaction asset, a midground landmark, and a background/horizon shape. Tiny detail props should not be inserted until those three reads are solved.

## Asset-First Placement Rules

1. Start every live insert with the camera read, not the catalog count.
2. Place at least one hero-scale asset cluster per beat before adding scatter.
3. Use existing `Workspace.Map.ImportedAssets/G029_StoryAssetDrivenBatch` placements as seed locations, but scale or surround them with larger authored clusters.
4. Reject any candidate that only reads when zoomed in, creates a tiny dot on flat ground, or needs a label to explain its role.
5. For Creator Store insertion, use the authorized Studio path from the G018 notes: exact Studio search query, insert from Creator Store result, then stamp source id, script audit status, zone, placement role, and screenshot proof.

## Beat Asset Plan

| Beat | Needed camera read | Primary asset IDs / search queries | Placement plan |
| --- | --- | --- | --- |
| Beat 0 Egg wakeup | A nest bowl and eggs dominate the hatch camera; the baby dino is visibly born in a protected place, not on a flat plate. | Accepted/live: `8895193` Dinosaur eggs in a nest, `93304870` nest. Candidates/search: `134872049070713` Dinosaur Nest Prehistoric Cave Eggs Hatchery RP; `1679857865` wood pick up (branch); `150068032` Scrambled Eggs in a Nest; `101855130` Egg Nest; query `dinosaur egg nest`; query `dinosaur nest eggs fossil bones prehistoric`. | Build a 12-18 stud nursery nest composition around the hatch point: primary egg/nest at player scale, branch ring around it, 2-3 foliage walls behind it, and a clear exit corridor toward first food. Existing G029 nests should become the core, not the whole scene. |
| Beat 1 First food/water | Food and water are readable before UI appears. Herbivore food is green/fruit, carnivore food is meat/bone, water has an edge. | Accepted/live: `12630982706` PreHistoricPlantPack. Foliage candidates/search: `9143588267` low poly grass, `23181538` Berry Bush, `14720407179` Low poly bush, `21678497` Plant mesh, query `low poly plants pack`, query `berry bush`, query `plant mesh fern leaf`. Meat/search: `animal carcass dead deer ribcage carrion meat`, `raw meat haunch leg bone drumstick`, `raw meat steak food pack meshes`, `butcher meat slab hanging raw beef carcass`. Water/search: `6764901150` Part To Water Animated, `32769873` Realistic Water, query `low poly water plane`, query `Part To Water Animated`. | Replace lone food dots with diet-specific feeding stations: three large fern/bush clusters for herbivores, one safe rib/meat cache for carnivores, and one visible water edge with reeds/rocks. Keep helper/query parts hidden under visible models. |
| Beat 2 Predator/prey choice | A herd silhouette and a predator silhouette are both visible across FernPlains. | Dino candidates/search: `102772249876319` Rigged Dinosaur Models, `129426942556570` Rigged Dinosaur Models 2, `9371720275` Raptor Character!, `8585959958` VelociRaptor Blue, `9961766535` cool dino, query `Rigged Dinosaur Models`, query `Raptor dinosaur rigged`, query `VelociRaptor Blue 8585959958`. Foliage anchor: `12630982706` PreHistoricPlantPack. | Stage a wide herd/predator tableau instead of isolated NPCs: 3-5 herbivore bodies or placeholders in a midground group, a predator half-covered by grass/treeline, and a carcass endpoint that proves hunting creates food. If only one raptor visual passes, use it large and distant as a silhouette until rig review is complete. |
| Beat 3 Growth moment | The before/after body scale is obvious and has a clean rest-cover location. | Dino mesh candidates from Beat 2 plus existing staged starter meshes. Cover/search: `low poly bush`, `forest pack foliage`, `meshpart pbr foliage and nature pack`, query `forest pack foliage`. UI/icon reference: `110801640375836` Monochrome White UI Icon Pack. | Put the growth rest spot beside a recognizable shelter cluster, not in an open square. Use a fixed comparison object like a stump, bush, or nest branch so screenshot proof can show the hatchling-to-juvenile scale change. |
| Beat 4 JungleBasin ambush | Dense, occluding jungle corridor with a readable ambush path. | G029/live: `12630982706` PreHistoricPlantPack. Candidates/search: `72003029540472` vines hang roots jungle cave ivy moss leaf decor; `139313340758271` Tropical PBR Plants Classic Nature Aesthetic Grow; `18242667178` [HD] Vegitation Pack; `259909318` Plants; query `low poly jungle forest vegetation trees bushes`; query `prehistoric jungle foliage pack`; query `jungle vine`. | Author a narrow corridor with 2 high foliage walls, hanging vines at head height, and one predator reveal pocket. Do not sprinkle tiny plants across flat ground until the corridor occlusion reads from the player camera. |
| Beat 5 SwampDelta swim/fish | Water is a biome: shore, reeds/lilies, fish movement, oxygen risk. | Fish candidates/search: `6923368893` Mulet fish Mesh, `711629760` Fish, `135378314068756` Fishy Aquatic Ocean Water Fish School, `100298727033570` Salty Fish School Aquatic Ocean Water Swim Scho, query `Mulet fish Mesh 6923368893`, query `fish school water`. Swamp/water candidates: `86198817809169` Lily Pad Frog Green Water Lily; `95359664633430` Koi Pond Bridge Water Rocks Lily Aesthetic; `12598461005` Realistic Southern Swamp Trees Pack; `18986634714` Swamp Trees; query `low poly water plane`; query `river rocks shoreline water environment low poly`. Audio candidates: `9120552550` waterfall stream, `9117823374` splash/swimming. | Insert visible water plane/edge first, then reeds/lily pads at the shoreline, then 5-8 fish clones or a fish-school model inside the water volume. Avoid a single fish dot in a square pool; fish must be grouped and contrasted against water. |
| Beat 6 RedstoneCanyon apex trial | Red cliffs, skull/bones, and a large apex silhouette make the player feel small. | Bone/fossil candidates/search: `117562283357615` T-Rex Skull Gothic Bone Build Decor; `77970470720479` T-Rex Skull Decor RP Horror Spooky; `137420276606883` dinosaur bones; `14047690299` bones/fossil candidate; query `dinosaur nest eggs fossil bones prehistoric`. Apex candidates/search: `9881605049` Animatable Godzilla Model as reference-only fallback; `9113985717` creature roar SFX; `75002201062316` Rev Tyrannosaurus Dinosaur Roar Apex Predator; query `dinosaur roar monster roar sound effect`. | Fix canyon identity with 3 large vertical rock/cliff silhouettes and a foreground fossil/skull pickup. The rejected desert/oasis landscape from G029 should not be used as the primary canyon read. Add roar/audio only after visual threat staging exists. |
| Beat 7 ApocalypticCity mystery | One frame shows ruined human world: wreck, wall/building, overgrowth, danger. | City candidates/search: `125968528580422` Destroyed Building Ruined City Apocalypse RP; `91515408060922` Ruined Vehicle Pack Car Wreck Decayed Debris; `118944114691030` Destroyed Cars Wreckage Vehicles Debris Pack; `136643767057529` Abandoned Truck Rusty Wreck Derelict Vehicle; `4675550604` Broken Car; `4449997799` Megaphone; search `apocalypse city ruins wrecked car rubble low poly`; search `Broken Car 4675550604`. | Build the city approach as a silhouette gateway: one ruined building/wall, one wrecked vehicle in the path, one overgrowth cluster, and one fossil/apex hook. Broken Car alone is useful but too small; pair it with a large ruined building or truck. |
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

These are ordered to fix the largest visual failures first: flat/boxy map read, tiny assets, missing diet-specific food, missing water/fish, and missing city/canyon landmarks.

1. **Beat 7 city landmark cluster**
   - Search/insert order: `Destroyed Building Ruined City Apocalypse RP 125968528580422`, then `Ruined Vehicle Pack Car Wreck Decayed Debris 91515408060922`, then `Broken Car 4675550604`.
   - Placement: one building/wall at skyline scale, one vehicle in the path, one overgrowth/grass cluster around it.
   - Stop condition: one gameplay-camera screenshot reads as "ruined city" without labels.

2. **Beat 5 water/fish readability cluster**
   - Search/insert order: `Part To Water Animated 6764901150`, then `Mulet fish Mesh 6923368893`, then `Lily Pad Frog Green Water Lily 86198817809169`.
   - Placement: visible water plane/edge first, lily/reed edge second, fish group third.
   - Stop condition: screenshot reads as water habitat, not a square plate with a tiny fish.

3. **Beat 1 carnivore food station**
   - Search/insert order: `animal carcass dead deer ribcage carrion meat`, then `raw meat haunch leg bone drumstick`, then `butcher meat slab hanging raw beef carcass`.
   - Placement: one large safe starter carcass cache near Nursery/FernPlains transition, paired with bone scatter and diet prompt.
   - Stop condition: carnivore food is recognizable without UI text.

4. **Beat 0 nursery nest composition upgrade**
   - Search/insert order: reuse `8895193` and `93304870`, then search `wood pick up (branch) 1679857865`, then `Dinosaur Nest Prehistoric Cave Eggs Hatchery RP 134872049070713`.
   - Placement: scale the nest cluster around hatch camera; add branch ring and foliage wall rather than more tiny eggs.
   - Stop condition: hatch screenshot shows protected nest/home, not baby on a flat map.

5. **Beat 4 jungle corridor**
   - Search/insert order: `vines hang roots jungle cave ivy moss leaf decor 72003029540472`, then `Tropical PBR Plants Classic Nature Aesthetic Grow 139313340758271`, then reuse `12630982706`.
   - Placement: two dense walls plus a reveal pocket for predator silhouette.
   - Stop condition: screenshot shows partial occlusion and a reason to hide/call/flee.

6. **Beat 6 canyon fossil/apex foreground**
   - Search/insert order: `T-Rex Skull Gothic Bone Build Decor 117562283357615`, then `dinosaur bones 137420276606883`, then `Creature Roar Mix Of Animals Gate Creaks 1 9113985717` for audio only after visual pass.
   - Placement: skull/fossil in foreground, tall red rock silhouettes behind, apex shadow lane beyond.
   - Stop condition: screenshot reads as apex canyon with fossil reward and danger.

7. **Beat 2 predator/prey silhouette upgrade**
   - Search/insert order: `Rigged Dinosaur Models`, then `Raptor Character! 9371720275`, then `VelociRaptor Blue 8585959958`.
   - Placement: herd group and predator silhouette in the same FernPlains frame.
   - Stop condition: player can tell predator from prey at distance.

## Live Proof Requirements Before Calling Any Placement Done

- Use authorized Creator Store insertion, not raw `InsertService:LoadAsset`.
- Stamp every accepted root with `SourceAssetId`, `CreatorStoreOnly`, `ImportedVisibleAsset`, `PlacementRole`, `ZoneId`, and script audit attributes.
- Review and quarantine scripts before release counting; do not keep loose imported behavior unless owned, reviewed, and tested.
- Ground and scale each root from the gameplay camera, then screenshot the intended beat.
- Run the existing asset audit after insertion and record honest counts; do not claim G018/G029/G030 final PASS from docs-only work.
