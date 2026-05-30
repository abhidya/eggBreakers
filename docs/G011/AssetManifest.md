# G011 Asset Manifest Audit

- Date: 2026-05-27
- Rule: 500 unique Roblox Creator Store source asset IDs; cloned local duplicates do not count.
- Source of truth: `src/ReplicatedStorage/Shared/AssetManifest.lua`
- Count: 500 manifest entries, 500 unique `SourceAssetId` values.
- Catalog source: Roblox Creator Store Toolbox Service v2 plus Studio MCP inserted probe `CS-4596418748`.
- Script policy: imported scripts are not allowed to run by default; sources with scripts are marked `ScriptsRemoved` unless explicitly sandboxed.
- Boundary: this manifest is a catalog audit, not the live imported/release-ready asset count. Later G014 live Creator Store imports may be valid even when their `SourceAssetId` is outside this 500-row catalog; they still require separate Studio import/tag/script-audit/placement proof before counting toward release.

## Placement classification

- Foliage: natural grove/bank edges, `AvoidRouteCenters=true`, `PlacementPattern=natural_offset_no_grid`.
- City props: Apocalyptic City only.
- Rock/cliff props: Redstone Canyon or Mountain Nesting Cliffs only.
- Swamp props: Swamp Delta only.
- Fossils: outside Nursery Grove safe zone.
