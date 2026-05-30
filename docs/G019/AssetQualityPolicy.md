# G019 Asset Quality Policy

Owner policy for the final playable build:

- Final UI must not look like a debug HUD. Debug labels, debug-only fallback visuals, placeholder names, and developer-only markers are not release visuals.
- Food visuals must not be low-quality/simple generated glowing balls. If a temporary procedural marker exists for gameplay, it is a non-release fallback until replaced with a quality food/vegetation/NPC visual.
- Tree and vegetation dressing must not be rectangle-plus-ball/simple generated trees. Final visible dressing must be quality imported/source-authored art or an explicitly approved replacement.
- Counts must stay honest: duplicate `SourceAssetId` values, catalog-only manifest rows, debug generated parts, hidden/quarantined visuals, and policy-excluded assets do not count as release-ready live assets.

## Audit/source guard

`AssetImportAuditService` is the source guard for import-count reporting:

- `catalogedSourceAssetIds` remains separate from live imported/tagged/placed/release-ready evidence.
- Unique counts are keyed by `SourceAssetId`, so duplicates do not inflate imported or release-ready totals.
- Assets explicitly marked with `AssetQualityExclusionKind = "low-quality"` (or equivalent LQ attributes) are reported under low-quality exclusions and withheld from `releaseReadyVisibleAssets`.
- Assets explicitly marked with `AssetQualityExclusionKind = "mesh"` are reported under mesh exclusions separately from low-quality exclusions.
- MeshPart usage alone is not a quality failure. Many valid Creator Store imports are mesh-based; only a deliberate mesh-exclusion policy mark with a reason should withhold them.
- Required playable visuals marked `RequiredPlayableVisual = true` must not be quality-excluded without a non-empty `RequiredPlayableVisualPolicyNote` or `AssetQualityPolicyNote` explaining the temporary exception/replacement plan.
- The audit reports exclusions; it must not erase/delete required playable visuals as a side effect of quality policy. Script quarantine remains limited to imported executable scripts.

## Reporting requirements

Every G019 asset quarantine/audit report must include separate counts for:

1. cataloged source IDs,
2. actually imported unique source IDs,
3. placed visible imported IDs,
4. release-ready visible IDs,
5. mesh exclusions,
6. low-quality/simple-generated exclusions,
7. debug-looking/fallback exclusions,
8. any required playable visuals excluded under an explicit policy note.

If release-ready totals drop after quality exclusions, report the lower number. Do not backfill with duplicates, catalog-only rows, or temporary generated visuals.
