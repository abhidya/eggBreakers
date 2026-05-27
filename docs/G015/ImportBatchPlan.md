# G015 Import Batch Plan

Status: FAIL — plan exists, target not reached. Current release-ready unique assets: 34/500. Remaining gap: 466.

| Category | Minimum release-ready unique assets | Current proven | Status |
|---|---:|---:|---|
| Playable species models / variants / stage visuals | 40 | 4+ prior G014 species sets | FAIL |
| Egg/nest/hatch assets | 20 | 2 | FAIL |
| Herbivore food plants | 60 | 2 | FAIL |
| Carnivore food/carcass/prey-remains assets | 40 | 0 fully proven | FAIL |
| NPC prey/predator/ambient creature assets | 60 | 0 fully proven | FAIL |
| Nursery Grove foliage/rocks/shelter | 50 | 0 fully proven | FAIL |
| Fern Plains foliage/rocks/landmarks | 50 | 1+ | FAIL |
| Jungle Basin foliage/vines/logs | 50 | 1 | FAIL |
| Redstone Canyon rocks/cliffs/fossils | 50 | 1 | FAIL |
| Swamp Delta reeds/water plants/logs | 50 | 2 | FAIL |
| Apocalyptic City ruins/cars/rubble/overgrowth | 80 | 3 | FAIL |
| Mountain Nesting Cliffs rocks/nest/fossils | 30 | 1 | FAIL |
| UI/icons/audio/VFX | 20 | 0 | FAIL |

Batch loop used: Creator Store search -> insert primary result -> tag SourceAssetId/AssetManifestId/CreatorStoreOnly/ImportedVisibleAsset -> quarantine imported scripts -> move under `Workspace.Map.ImportedAssets` -> run `AssetImportAuditService:AuditAndRepair({ mutate = true })`.

Hard limitation observed: MCP `insert_from_creator_store` inserts only the primary result for a search; secondary result IDs are alternatives and were not counted. Parallel insert can report play-mode or target-not-reachable errors, requiring `start_stop_play(false)` and serial retry.
