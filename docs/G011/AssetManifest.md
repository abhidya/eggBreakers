# G011 Asset Manifest Audit

- Date: 2026-05-27
- Rule: 500 unique Roblox Creator Store source asset IDs; cloned local duplicates do not count.
- Source of truth: `src/ReplicatedStorage/Shared/AssetManifest.lua`
- Count: 500 manifest entries, 500 unique `SourceAssetId` values.
- Catalog source: Roblox Creator Store Toolbox Service v2 plus Studio MCP inserted probe `CS-4596418748`.
- Script policy: imported scripts are not allowed to run by default; sources with scripts are marked `ScriptsRemoved` unless explicitly sandboxed.
- Script-bearing source count: 143 audited sources.

## Placement classification

- Foliage: natural grove/bank edges, `AvoidRouteCenters=true`, `PlacementPattern=natural_offset_no_grid`.
- City props: Apocalyptic City only.
- Rock/cliff props: Redstone Canyon or Mountain Nesting Cliffs only.
- Swamp/pond props: Swamp Delta only.
- Fossils: outside Nursery Grove safe zone.
