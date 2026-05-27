# G015 Release Placement Audit

Overall: FAIL — only 15 release-ready visible unique SourceAssetIds are proven; several required categories have zero release-ready placement proof.

| Category | Count imported | Count placed | Count release-ready | Sample SourceAssetIds | Status | Evidence |
|---|---:|---:|---:|---|---|---|
| egg/nest visual | 2 | 2 | 2 | 8895193, 4666597044 | FAIL | Below minimum 20. |
| all playable species/stage visuals | 4+ | 4+ | 4+ | 646098924, 63385946, 412719275, 471993246 | FAIL | Below minimum 40. |
| herbivore food visuals | 2 | 2 | 2 | 162897134, 14703400302 | FAIL | Below minimum 60. |
| carnivore food/carcass visuals | 0 | 0 | 0 | none | FAIL | No full release-ready carcass set proven. |
| NPC prey/predator visuals | 0 | 0 | 0 | none | FAIL | No full release-ready NPC set proven. |
| Nursery Grove props | 0 | 0 | 0 | none | FAIL | Missing required category proof. |
| Fern Plains props | 1 | 1 | 1 | 162897134 | FAIL | Below minimum 50. |
| Jungle Basin props | 1 | 1 | 1 | 14703400302 | FAIL | Below minimum 50. |
| Redstone Canyon props | 1 | 1 | 1 | 137420276606883 | FAIL | Below minimum 50. |
| Swamp Delta props | 2 | 2 | 2 | 13261235137, 7727678976 | FAIL | Below minimum 50. |
| Old Eden city props | 3 | 3 | 3 | 108178603114720, 111614048167471 | FAIL | Below minimum 80. |
| fossils | 1 | 1 | 1 | 137420276606883 | FAIL | Below required release proof. |
| nests | 2 | 2 | 2 | 8895193, 4666597044 | FAIL | Below required release proof. |
| UI/audio/VFX | 0 | 0 | 0 | none | FAIL | Missing required category proof. |

Fresh TestRunner placement failures also reported placeholder/placement issues: `Workspace.DamageTarget` visible default block Part, missing `FullMapSafeTerrainUnderlay`, biome mismatch for CS-4596418748, and food placement metadata error.
