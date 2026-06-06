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

| Place | Stories live passed | Unique release-ready source ids | Gap to 500 | Imported runtime scripts | Fresh all-category proof | RBXL persistence proof | Final G016 |
| --- | ---: | ---: | ---: | ---: | --- | --- | --- |
| `eggBreakers.rbxl` | 0/15 | 0 | 500 | 0 | false | false | FAIL |
| `eggBreakers2.rbxl` | 13/15 | 20 | 480 | 0 | false | false | FAIL |
| `eggBreakers3.rbxl` | 13/15 | 32 | 468 | 453 | false | false | FAIL |
| `eggBreakers4.rbxl` | 13/15 | 49 | 451 | 0 | false | false | FAIL |

## Current Blockers

- US14 and US15 live proof are absent in every persisted `.rbxl`.
- `eggBreakers4.rbxl` only proves 49 unique release-ready source ids by offline
  root counting, not the required 500.
- `FreshAllCategoryTestRunnerPassed` is absent.
- `RBXLPersistencePassed` is absent.
- `eggBreakers4.rbxl` still contains validation/test leftovers such as
  `FreshSlopProofShared_*`, `AlreadyUpright*`, `UpsideDown*`, and
  `TestImported*` roots. These must not count as release scenery.

## Next Action

Use `tools/g016_place_gate_audit.luau` after every place import/save batch.
Do not checkpoint G013 complete until the best persisted `.rbxl` reports:

- `storiesLivePassed=15/15`
- `uniqueReleaseReadySourceIds>=500`
- `importedRuntimeScripts=0`
- `freshAllCategory=true`
- `rbxlPersistence=true`
- `finalG016Pass=true`
