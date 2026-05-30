# G026 Planning Count Contradiction Cleanup Report

Status: **REPORT ONLY — no release PASS**
Date: 2026-05-30
Scope: docs/planning count contradictions found during the G026 AI-slop cleanup lane. This report does not change source behavior or mutate `.omx/ultragoal`.

## Behavior Lock

No behavior-bearing files were changed in this lane. The cleanup is limited to documenting contradictory planning/evidence counts so later workers can update stale docs deliberately instead of normalizing the wrong number.

## Cleanup Plan

1. Treat the leader handoff context as the freshest G026 snapshot for this lane: `releaseReadyVisibleAssets=22`, `actuallyImportedAssets=22`, `catalogedSourceAssetIds=500`, and live TestRunner `228 total / 212 passed / 16 failed`.
2. Keep the 500 target and catalog/live split intact: `500` cataloged IDs is not equivalent to `500` release-ready live imports.
3. Inventory stale count claims without rewriting history-heavy evidence logs in this pass.
4. Recommend one follow-up doc pass that updates summary/planning docs to distinguish:
   - latest live G026 count,
   - historical batch counts,
   - catalog count,
   - release target.

## Count Contradiction Inventory

| Area | File / evidence | Count or claim | Classification | Cleanup action |
| --- | --- | --- | --- | --- |
| Fresh G026 handoff | `.omx/context/ai-slop-cleaner-g026-leader-20260530T152459Z.md` | `releaseReadyVisibleAssets=22`, `actuallyImportedAssets=22`, `catalogedSourceAssetIds=500`; TestRunner `228 total / 212 passed / 16 failed` | Current lane source of truth | Use as the latest snapshot for G026 cleanup reporting. |
| G018 final evidence | `docs/G018/FinalGateEvidence.md` | `Latest provided context reports 215/500` | Stale/contradictory summary | Update in a later docs edit to say the latest G026 handoff reports `22/500`; preserve that older higher counts may exist as historical batch evidence only if explicitly dated. |
| G014/G019 summaries | `docs/G014/TestResults.md`, `docs/G014/FinalReport.md`, `docs/G019/ImplementationReport.md` | Current summary sections repeatedly call `23/500` authoritative, with later appended sections also mentioning `27/500`, `79/500`, and related batch counts | Historical log mixed with summary | Keep historical sections, but add/update a single "latest authoritative snapshot" banner when the leader confirms whether G026 `22/500` supersedes those docs. |
| G016 summaries | `docs/G016/USER_STORY_COVERAGE_MATRIX.md`, `docs/G016/ACTIVE_WORK_QUEUE.md`, `docs/G016/TEST_RESULTS.md` | Summary rows still mention `34/500`; later log entries mention `221/500` and `227/500` | Stale summary rows plus historical append-only evidence | Do not use summary rows as current count without a dated freshness note. Follow-up should mark `34/500`, `221/500`, and `227/500` as historical snapshots unless fresh Studio proof revalidates them. |
| G015 docs | `docs/G015/*` | `34/500` and related gap calculations | Historical predecessor evidence | Leave as history; do not use as next-batch baseline. |
| G011 manifest docs | `docs/G011/AssetManifest.md`, `docs/assets/import-audit.md` | `500` catalog entries / unique `SourceAssetId` values | Grounded catalog count, not a contradiction by itself | Preserve; these files correctly warn that cataloged does not mean imported/release-ready. |
| Master plan snapshot | `eggBreakers_Master_Plan.md` | `199/228 tests passing`, `50 anchored primitive NPCs`, `744 enabled legacy scripts`, and asset plan text says `34/500` "now 28" | Planning snapshot is stale against leader G026 context (`212/228`, `22/500`) | Follow-up should add a dated freshness note or move these numbers under "historical baseline" to avoid competing with current gate evidence. |

## Fallback / Slop Findings

- **Masking fallback slop:** none edited in this report-only lane.
- **Documentation slop:** multiple planning files present undated or semi-current counts as if authoritative. This can mask release blockers by making `22/500`, `23/500`, `34/500`, `79/500`, `215/500`, `221/500`, and `227/500` look simultaneously current.
- **Grounded compatibility/fail-safe fallback:** the catalog/live split in `docs/G011/AssetManifest.md` and `docs/assets/import-audit.md` is grounded and should be preserved.

## Recommended Bounded Follow-up

Do one docs-only pass after leader confirms the current Studio audit snapshot:

1. Add a small "Current authoritative count snapshot" block to the highest-level planning docs.
2. Demote older numeric claims to dated historical evidence instead of deleting them.
3. Use one wording pattern everywhere: `catalogedSourceAssetIds=500` is the catalog; `releaseReadyVisibleAssets=<fresh count>/500` is the release gate.
4. Do not mark release PASS until `ValidateReleaseCounts(500)`, fresh all-category TestRunner, mobile/client proof, and RBXL save/reopen proof all pass together.

## Quality Gate Plan for This Report Lane

- Markdown/report hygiene: ensure the new report is tracked and has no merge conflict markers.
- Diff hygiene: run `git diff --check`.
- Source behavior sanity: run existing local Lua syntax and Rojo build gates if available; expected to remain unchanged because this lane is docs-only.

## Remaining Risks

- The actual live Studio state may have changed after the leader context. This report intentionally avoids claiming that `22/500` is globally final; it only identifies it as the freshest evidence provided to this worker lane.
- Historical append-only evidence logs contain many legitimate older counts. Cleanup should clarify freshness, not erase audit history.
