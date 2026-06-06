# G020 Cache-Backed Storyboards for eggBreakers

Generated: 2026-06-04T02:54:18.560Z

This pass dreams in the shape of assets that actually exist. It uses the live custom asset-search MCP for story-slot candidates plus the repo's existing Creator Store manifest. No Studio search was used. These are story seeds, not release palette commits; every candidate still needs Studio geometry/script audit and player-angle screenshot review.

## Story Spine

Hatch alone -> read food/water from the world -> survive predator/prey pressure -> grow into a role -> master sound, cover, and water -> confront apex fossil territory -> discover Old Eden in the ruined city.

## Beat 0 - Egg Wakeup in Nursery Grove

Crack the camera out of the shell, reveal the nest, then show a baby dinosaur body before the first need pulse.

Cache-backed visual palette:

### beat0.egg_wakeup.nest
- Dinosaur Egg of Extinct (ID 240666886) — query: dinosaur egg; source: live_mcp_curate_assets; scripts: no catalog scripts
- Auquatic Creature Eggs for Dinosaur Simulator (ID 423991750) — query: dinosaur egg; source: live_mcp_curate_assets; scripts: no catalog scripts
- Egg For dinosaur simulator (ID 708850786) — query: dinosaur egg; source: live_mcp_curate_assets; scripts: no catalog scripts
- dinosaur egg! jurassic incubation fossil pet rp (ID 105854615288868) — query: dinosaur fossil; source: project_asset_manifest; scripts: no catalog scripts
- dinosaur egg fossil prehistoric jurassic park rp (ID 121754374281911) — query: fossil; source: project_asset_manifest; scripts: no catalog scripts

### beat0.egg_wakeup.nest_detail
- Sauropod Nest + Sauropod eggs (ID 463709089) — query: egg nest; source: live_mcp_curate_assets; scripts: no catalog scripts
- Theropod Nest + Theropod eggs (ID 463710364) — query: egg nest; source: live_mcp_curate_assets; scripts: no catalog scripts
- New Eggs of the Nest (ID 104497410410577) — query: egg nest; source: live_mcp_curate_assets; scripts: no catalog scripts

### beat0.egg_wakeup.hatchling_mesh
- Blue (ID 2167783289) — query: baby dinosaur; source: live_mcp_curate_assets; scripts: no catalog scripts
- Patrickasaurus (ID 5443261863) — query: baby dinosaur; source: live_mcp_curate_assets; scripts: no catalog scripts
- Baby Carnotaurus (ID 6185104172) — query: baby dinosaur; source: live_mcp_curate_assets; scripts: no catalog scripts

Player-angle review target:
- Capture from player height after placement; reject or replace anything floating, buried, mis-scaled, sparse, off-theme, script-risky, or camera-occluding.

## Beat 1 - Food and Water Lesson

Let the body teach rules through silhouettes: fern and plant packs for herbivores, bones/carcass for carnivores, and readable water surfaces.

Cache-backed visual palette:

### beat1.food.herbivore_fern
- Realisitc Fern (ID 434184732) — query: fern; source: live_mcp_curate_assets; scripts: no catalog scripts
- Fern Bush (ID 7979002756) — query: fern; source: mcp_search_cache+live_mcp_curate_assets; scripts: no catalog scripts
- Patente na cabeca para nossa eb :) fernandinhobr (ID 12173453659) — query: fern; source: live_mcp_curate_assets; scripts: needs script audit
- 🌳 Jungle Tree Bush Nature Garden Greenery Swamp (ID 120350729305000) — query: swamp tree; source: project_asset_manifest; scripts: needs script audit

### beat1.food.plant_pack
- Low Poly Plant Pack (ID 2915526744) — query: low poly plant; source: live_mcp_curate_assets; scripts: no catalog scripts
- low poly potted plant (ID 9253654788) — query: low poly plant; source: live_mcp_curate_assets; scripts: no catalog scripts
- Low-Poly Plants Pack (ID 12630982706) — query: low poly plant; source: live_mcp_curate_assets; scripts: no catalog scripts

### beat1.food.carnivore_carcass
- skull (ID 11134159) — query: skull; source: project_asset_manifest; scripts: no catalog scripts
- Skull (ID 3201274546) — query: skull; source: project_asset_manifest; scripts: no catalog scripts
- Dead rat (ID 3414358748) — query: animal carcass; source: live_mcp_curate_assets; scripts: no catalog scripts
- Honestly (ID 3943514194) — query: animal carcass; source: live_mcp_curate_assets; scripts: no catalog scripts
- Skull (ID 15199287211) — query: skull; source: project_asset_manifest; scripts: no catalog scripts
- Gaster Blaster Closed Tough (ID 119531396484206) — query: animal carcass; source: live_mcp_curate_assets; scripts: no catalog scripts

### beat1.food.bone_fallback
- Dog Bone (ID 1894867381) — query: bone; source: live_mcp_curate_assets; scripts: no catalog scripts
- rigged crocodile with bone system (ID 6806168763) — query: bone; source: live_mcp_curate_assets; scripts: no catalog scripts
- Synty Dungeon Pack: Skeletons & Bones (ID 6934081776) — query: bone; source: live_mcp_curate_assets; scripts: no catalog scripts

### beat1.food.drinkable_water
- Tornado customizable (ID 6880772899) — query: water pond; source: live_mcp_curate_assets; scripts: no catalog scripts
- Luigi's Mansion (ID 10045874583) — query: water pond; source: live_mcp_curate_assets; scripts: no catalog scripts
- old background screen (ID 18638079602) — query: water pond; source: live_mcp_curate_assets; scripts: no catalog scripts

Player-angle review target:
- Capture from player height after placement; reject or replace anything floating, buried, mis-scaled, sparse, off-theme, script-risky, or camera-occluding.

## Beat 2 - Fern Plains Predator/Prey Choice

Use herd body libraries and raptor silhouettes to stage the first real survival decision.

Cache-backed visual palette:

### beat2.fern_plains.herd
- DINOSAUR PACK! (ID 430905421) — query: rigged dinosaur models; source: live_mcp_curate_assets; scripts: needs script audit
- Rigged Dinosaur Models (ID 18759347676) — query: rigged dinosaur models; source: live_mcp_curate_assets; scripts: no catalog scripts
- Rigged Dinosaur Models 2 (ID 129426942556570) — query: rigged dinosaur models; source: live_mcp_curate_assets; scripts: no catalog scripts

### beat2.fern_plains.predator
- Jurassic World - Ridable Velociraptor (ID 248223518) — query: velociraptor; source: live_mcp_curate_assets; scripts: needs script audit
- Velociraptor (ID 281912567) — query: velociraptor; source: live_mcp_curate_assets; scripts: needs script audit
- Jurassic Park Male Velociraptor NPC (ID 1320554267) — query: velociraptor; source: live_mcp_curate_assets; scripts: needs script audit

Player-angle review target:
- Capture from player height after placement; reject or replace anything floating, buried, mis-scaled, sparse, off-theme, script-risky, or camera-occluding.

## Beat 3 - Growth Role Reveal

Sell growth with a pulse, sparkle/aura, role badge, and small reaction in nearby creatures.

Cache-backed visual palette:

### beat3.growth.role_reveal_vfx
- Ice spikes (ID 967645239) — query: sparkle aura; source: live_mcp_curate_assets; scripts: no catalog scripts
- FX Pack Effects Sparkle Glow Magic Blast Aura (ID 80757861006305) — query: sparkle aura; source: live_mcp_curate_assets; scripts: no catalog scripts
- particle magic glow sparkle aura blast effect (ID 119164855832816) — query: sparkle aura; source: live_mcp_curate_assets; scripts: no catalog scripts

Player-angle review target:
- Capture from player height after placement; reject or replace anything floating, buried, mis-scaled, sparse, off-theme, script-risky, or camera-occluding.

## Beat 4 - Jungle Basin Ambush

Make the jungle about partial information: vines block sight, roar/call cues imply danger, cover matters.

Cache-backed visual palette:

### beat4.jungle_basin.vines
- Average plant (ID 965843717) — query: jungle vine; source: live_mcp_curate_assets; scripts: no catalog scripts
- Another average plant (ID 965844264) — query: jungle vine; source: mcp_search_cache+live_mcp_curate_assets; scripts: no catalog scripts
- Realistic Tree Tropical Jungle Oak with Vines (ID 122280174982594) — query: jungle vine; source: live_mcp_curate_assets; scripts: no catalog scripts

### beat4.jungle_basin.sound_cue
- Jurassic Park Tyrannosaurus CSG model (ID 344514273) — query: dinosaur roar; source: live_mcp_curate_assets; scripts: no catalog scripts
- Giganotosaurus -dinosaur (ID 855368632) — query: dinosaur roar; source: live_mcp_curate_assets; scripts: no catalog scripts
- Proceratosaurus (Jurassic Park & World) (ID 984698485) — query: dinosaur roar; source: live_mcp_curate_assets; scripts: no catalog scripts

Player-angle review target:
- Capture from player height after placement; reject or replace anything floating, buried, mis-scaled, sparse, off-theme, script-risky, or camera-occluding.

## Beat 5 - Swamp Delta Oxygen/Fish

Water becomes a biome: swamp trees, lilies, fish targets, oxygen pressure, and Spinosaurus payoff.

Cache-backed visual palette:

### beat5.swamp_delta.reeds_lilypad
- Swamp Trees (ID 432559636) — query: swamp tree; source: live_mcp_curate_assets; scripts: no catalog scripts
- Dead Swamp Tree (ID 543827347) — query: swamp tree; source: project_asset_manifest+live_mcp_curate_assets; scripts: no catalog scripts
- Dead Tree Stump (ID 853438298) — query: dead tree; source: project_asset_manifest; scripts: no catalog scripts
- Mushrooms (ID 3060765489) — query: mushroom; source: project_asset_manifest; scripts: no catalog scripts
- Dead Tree (ID 3573742671) — query: dead tree; source: project_asset_manifest; scripts: no catalog scripts
- G011Probe Tree (ID 4596418748) — query: dinosaur fossil tree rock swamp city ruins car rubble cliff; source: project_asset_manifest; scripts: needs script audit

### beat5.swamp_delta.lilypad
- Venusaur Doll (ID 458900702) — query: water lily; source: live_mcp_curate_assets; scripts: no catalog scripts
- Water Lily (ID 708797531) — query: water lily; source: live_mcp_curate_assets; scripts: no catalog scripts
- Bridge over a Pond of Water Lilies by Claude Monet (ID 75850368020021) — query: water lily; source: live_mcp_curate_assets; scripts: no catalog scripts

### beat5.swamp_delta.fish
- Fish (ID 1725227984) — query: fish; source: live_mcp_curate_assets; scripts: no catalog scripts
- [RECTANGLE] FISH TANK (ID 1864520521) — query: fish; source: live_mcp_curate_assets; scripts: no catalog scripts
- Swimming Fish (ID 12261121165) — query: fish; source: live_mcp_curate_assets; scripts: needs script audit

### beat5.swamp_delta.spinosaurus
- Spinosaurus npc (ID 2989814926) — query: spinosaurus; source: live_mcp_curate_assets; scripts: needs script audit
- Spinosaurus ( OLD ) (ID 5434115710) — query: spinosaurus; source: live_mcp_curate_assets; scripts: no catalog scripts
- Spinosaurus NPC (WORKS ON BOTH R6 & R15) (ID 8920161016) — query: spinosaurus; source: live_mcp_curate_assets; scripts: needs script audit

Player-angle review target:
- Capture from player height after placement; reject or replace anything floating, buried, mis-scaled, sparse, off-theme, script-risky, or camera-occluding.

## Beat 6 - Redstone Canyon Apex Fossils

Red/canyon/fossil assets build dread before the apex warning and fossil reward.

Cache-backed visual palette:

### beat6.redstone_canyon.rocks
- Destroyable sandstone building (ID 47609929) — query: sandstone; source: project_asset_manifest; scripts: no catalog scripts
- Sandstone (ID 55194015) — query: sandstone; source: project_asset_manifest; scripts: no catalog scripts
- Boulder/big rock (ID 70617428) — query: boulder; source: project_asset_manifest; scripts: no catalog scripts
- Boulder (ID 94940698) — query: boulder; source: project_asset_manifest; scripts: no catalog scripts
- {Skybox} Painted Dust skybox (Canyon) Original (ID 164561025) — query: red canyon; source: live_mcp_curate_assets; scripts: no catalog scripts
- Red Desert Hills Skybox (ID 228255587) — query: red canyon; source: live_mcp_curate_assets; scripts: no catalog scripts

### beat6.redstone_canyon.fossils
- Dinosaur Fossil (ID 577078767) — query: dinosaur fossil; source: project_asset_manifest+live_mcp_curate_assets; scripts: no catalog scripts
- Velociraptor female (Jurassic Park & World) (ID 981164890) — query: dinosaur fossil; source: live_mcp_curate_assets; scripts: no catalog scripts
- Leviaphan fossils (ID 6566037175) — query: fossil; source: project_asset_manifest; scripts: no catalog scripts
- Fossils pack (ID 15679580048) — query: fossil; source: project_asset_manifest; scripts: no catalog scripts
- dinosaur skeleton bones fossil exhibit jurassic (ID 70417873353617) — query: dinosaur fossil; source: project_asset_manifest; scripts: no catalog scripts
- dinosaur artifact fossil study bone museum rp (ID 77582032189286) — query: fossil; source: project_asset_manifest; scripts: needs script audit

Player-angle review target:
- Capture from player height after placement; reject or replace anything floating, buried, mis-scaled, sparse, off-theme, script-risky, or camera-occluding.

## Beat 7 - Apocalyptic City Mystery

Old Eden reads through ruin silhouettes, wrecked cars, road debris, and sparse industrial audio risk.

Cache-backed visual palette:

### beat7.city.ruins
- Road Closed Sign (ID 250378973) — query: road sign; source: project_asset_manifest; scripts: no catalog scripts
- Road Sign (ID 368743404) — query: road sign; source: project_asset_manifest; scripts: no catalog scripts
- Street light (ID 404475960) — query: street light; source: project_asset_manifest; scripts: no catalog scripts
- City 17 Ruins Skybox (ID 408225227) — query: city ruins; source: live_mcp_curate_assets; scripts: no catalog scripts
- Concrete Barrier (ID 536859534) — query: concrete barrier; source: project_asset_manifest; scripts: no catalog scripts
- Road Sign | Medieval (ID 963358218) — query: road sign; source: project_asset_manifest; scripts: no catalog scripts

### beat7.city.wrecked_cars
- PBR Wrecked Car (ID 8027653806) — query: wrecked car; source: project_asset_manifest+live_mcp_curate_assets; scripts: no catalog scripts
- Wrecked Car 1 (ID 9213436305) — query: wrecked car; source: project_asset_manifest+live_mcp_curate_assets; scripts: no catalog scripts
- Car (ID 16121800852) — query: wrecked car; source: live_mcp_curate_assets; scripts: no catalog scripts

Player-angle review target:
- Capture from player height after placement; reject or replace anything floating, buried, mis-scaled, sparse, off-theme, script-risky, or camera-occluding.

## System - Wayfinding, Guide, and Biome Gates

Use compass/marker UI and guide/portal candidates carefully; most need script review before adoption.

Cache-backed visual palette:

### system.ui.food_waypoint
- Compass Gui (ID 1653779126) — query: compass gui; source: live_mcp_curate_assets; scripts: needs script audit
- Compass GUI (ID 1808937909) — query: compass gui; source: live_mcp_curate_assets; scripts: needs script audit
- Compass gui - xDragan! (ID 11967723143) — query: compass gui; source: live_mcp_curate_assets; scripts: needs script audit

### system.lobby.guide_npc
- Friendly Soldier NPC (ID 8669998570) — query: friendly npc; source: live_mcp_curate_assets; scripts: needs script audit
- Friendly soldier NPC (ID 9514179046) — query: friendly npc; source: live_mcp_curate_assets; scripts: needs script audit
- Friendly Soldier NPC (ID 13708942684) — query: friendly npc; source: live_mcp_curate_assets; scripts: needs script audit

### system.portal.biome_gate
- Portal Gun (ID 488366960) — query: portal; source: live_mcp_curate_assets; scripts: needs script audit
- Portal Gun Spawner (ID 4779485676) — query: portal; source: live_mcp_curate_assets; scripts: needs script audit
- Minecraft Portal [WORKING] (ID 6991952630) — query: portal; source: live_mcp_curate_assets; scripts: needs script audit

Player-angle review target:
- Capture from player height after placement; reject or replace anything floating, buried, mis-scaled, sparse, off-theme, script-risky, or camera-occluding.

## Headless Assembly Use

Use `asset-brain/v1/plans/eggbreakers-headless-assembly.json` to fan out room/lobby fragments. Each fragment must pass `validate_fragment_manifest` and then merge with `scripts/headless_fragment_merge.luau` before Studio opens for screenshot review.
