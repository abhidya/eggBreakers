# G013 Asset Materialization Report

Status: **FAIL** — materialized Creator Store imports remain below the owner-corrected release target.

| Metric | Count | Evidence |
| --- | ---: | --- |
| Required unique materialized primary Creator Store assets | 500 | Owner-corrected G013/G011 rule. |
| Tracked materialized unique primary `SourceAssetId` values | 44 | `src/ReplicatedStorage/Shared/UniqueImportPilotReport.lua` has 45 source-id rows and 44 unique IDs. |
| Remaining unique primary import gap | 456 | `500 - 44`. |
| New imports claimed by task 31 | 0 | Studio Luau audit timed out and no Creator Store insert tool was exposed in this lane. |

Manifest/catalog rows are intentionally reported separately from materialized imports. This report does not count duplicates, secondary IDs that were not directly inserted, manifest-only rows, mesh/fake placeholders, or local clones.

Next action: execute `docs/G013/NextImportBatchPlan.md` in a worker lane with reliable Studio edit-mode Creator Store search/insert access.
