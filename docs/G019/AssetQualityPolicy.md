# G019 Asset Quality Policy

Owner policy for the final playable build:

- Final UI must not look like a debug HUD. Debug labels, debug-only fallback visuals, placeholder names, and developer-only markers are not release visuals.
- Food visuals must not be low-quality/simple generated glowing balls. If a temporary procedural marker exists for gameplay, it is a non-release fallback until replaced with a quality food/vegetation/NPC visual.
- Tree and vegetation dressing must not be rectangle-plus-ball/simple generated trees. Final visible dressing must be quality imported/source-authored art or an explicitly approved replacement.
- Counts must stay honest: duplicate `SourceAssetId` values, catalog-only manifest rows, debug generated parts, hidden/quarantined visuals, and policy-excluded assets do not count as release-ready live assets.
- Release-ready visible assets require player-angle screenshot evidence after placement. Catalog metadata, import success, or bounding-box checks alone do not prove the asset works in the playable space.

## Audit/source guard

`AssetImportAuditService` is the source guard for import-count reporting:

- `catalogedSourceAssetIds` remains separate from live imported/tagged/placed/release-ready evidence.
- Unique counts are keyed by `SourceAssetId`, so duplicates do not inflate imported or release-ready totals.
- Assets explicitly marked with `AssetQualityExclusionKind = "low-quality"` (or equivalent LQ attributes) are reported under low-quality exclusions and withheld from `releaseReadyVisibleAssets`.
- Assets explicitly marked with `AssetQualityExclusionKind = "mesh"` are reported under mesh exclusions separately from low-quality exclusions.
- Current owner direction is stricter for this patch: imported `MeshPart` roots are treated as mesh-excluded by default and moved to `ReplicatedStorage/QuarantinedImportedAssets` during mutate audits unless an ancestor is protected as a required playable visual.
- Imported names matching food/glowing balls, rectangle/ball trees, placeholders, debug fallbacks, or simple-generated patterns are treated as low-quality exclusions even when the imported asset was not manually tagged.
- Required playable visuals marked `RequiredPlayableVisual = true` must not be quality-excluded without a non-empty `RequiredPlayableVisualPolicyNote` or `AssetQualityPolicyNote` explaining the temporary exception/replacement plan.
- The audit reports exclusions and, during mutate runs, quarantines non-required excluded imported roots. It must not erase/delete required playable visuals as a side effect of quality policy. Script quarantine remains limited to imported executable scripts.

## Player-angle visual gate

Before a placed asset can count as release-ready:

- Capture it from the player path or room quadrant where it is actually seen.
- Confirm it is grounded on terrain/floor, correctly scaled, oriented toward the intended path or focal point, and not blocking camera/navigation by accident.
- Reject or replace assets that look wrong from player height, even if Creator Store metadata and Studio bounding boxes looked acceptable.
- Record visual fallout in the asset-search MCP inspection memory with `visual_risks`, `visual_risk_score`, and `screenshot_verdict` so future sourcing passes skip known-bad choices.
- Use scoped `plan_playable_space_review(review_mode="player_angle", spaces=[...])` for asset-fix passes, then run the full playable-space review for milestone signoff.
- Clean up legacy visible filler such as `ImportedDressingVisual`, `ImportedFoodVisual`, `VisibleRainVolume`, debug placeholders, temporary generated food/tree markers, and hidden training artifacts before signoff.

## Reporting requirements

Every G019 asset quarantine/audit report must include separate counts for:

1. cataloged source IDs,
2. actually imported unique source IDs,
3. placed visible imported IDs,
4. release-ready visible IDs,
5. mesh exclusions,
6. low-quality/simple-generated exclusions,
7. debug-looking/fallback exclusions,
8. quality asset roots quarantined during mutate runs,
9. any required playable visuals excluded under an explicit policy note.
10. player-angle visual review coverage and unresolved screenshot risks.

If release-ready totals drop after quality exclusions, report the lower number. Do not backfill with duplicates, catalog-only rows, or temporary generated visuals.
