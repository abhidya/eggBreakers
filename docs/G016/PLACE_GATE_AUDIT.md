# G016 Binary Place Gate Audit

Observed: 2026-06-06

Tool:

```sh
lune run tools/g016_place_gate_audit.luau eggBreakers.rbxl eggBreakers2.rbxl eggBreakers3.rbxl eggBreakers4.rbxl
```

## Result

The persisted `.rbxl` files do not prove G016 complete. The best persisted
candidate is `eggBreakers4.rbxl`: it has core live proof folders for US01-US13,
no imported runtime scripts detected by the offline parser, and 12 visible NPCs
in the root samples, but it still fails the final G016 release gate.

The tool reports two asset-count lanes:

- `gate*` counts only the roots used by `AssetImportAuditService`:
  `ReplicatedStorage.ImportedAssetLibrary` and `Workspace.Map.ImportedAssets`.
  This is the release gate count.
- `gateReleaseReadyVisibleAssets` requires real visible `BasePart` geometry.
  `ImportedVisibleAsset=true` or placement under `Workspace.Map.ImportedAssets`
  is not enough when a headless marker/model has no visible parts.
- `broadWorld*` scans broader world/import-like placement evidence. It is useful
  for readability and persistence triage, but it is not the release gate count.

| Place | Stories live passed | Gate release-ready ids | Gate gap to 500 | Broad world ids | Gate executable scripts | Fresh all-category proof | RBXL persistence proof | Final G016 |
| --- | ---: | ---: | ---: | ---: | ---: | --- | --- | --- |
| `eggBreakers.rbxl` | 0/15 | 0 | 500 | 0 | 0 | false | false | FAIL |
| `eggBreakers2.rbxl` | 13/15 | 23 | 477 | 20 | 0 | false | false | FAIL |
| `eggBreakers3.rbxl` | 13/15 | 29 | 471 | 32 | 453 | false | false | FAIL |
| `eggBreakers4.rbxl` | 13/15 | 34 | 466 | 49 | 0 | false | false | FAIL |

## Current Blockers

- US14 and US15 live proof are absent in every persisted `.rbxl`.
- `eggBreakers4.rbxl` only proves 34 unique release-ready source ids under the
  production audit roots, not the required 500. Its 49 broad-world ids are
  supplemental placement/readability evidence and must not be used as the
  release gate number.
- `FreshAllCategoryTestRunnerPassed` is absent.
- `RBXLPersistencePassed` is absent.
- `eggBreakers4.rbxl` still contains validation/test leftovers such as
  `FreshSlopProofShared_*`, `AlreadyUpright*`, `UpsideDown*`, and
  `TestImported*` roots. These must not count as release scenery.

## Next Action

Use `tools/g016_place_gate_audit.luau` after every place import/save batch.
Do not checkpoint G013 complete until the best persisted `.rbxl` reports:

- `storiesLivePassed=15/15`
- `gateReleaseReadyVisibleAssets>=500`
- `gateExecutableScriptObjectsFound=0`
- `freshAllCategory=true`
- `rbxlPersistence=true`
- `finalG016Pass=true`
