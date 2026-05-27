# G018 Active Work Queue

Status: **IN PROGRESS / NOT RELEASE READY**  
Owner lane: worker-5 QA docs, final gate skeleton, publish-blocker evidence.  
Created: 2026-05-27.

## Release honesty constraints

- Do **not** mark G018 final PASS from docs-only or source-only evidence.
- Preserve the G016 release honesty contract: the 500 unique Creator Store release asset gate remains enforced.
- Creator Store imports are the primary path; `GenerationService` is allowed only as a backup authoring path and cannot fake Creator Store provenance.
- Blocked asset id `9922699889` must remain absent from source/place evidence before any publish claim.
- `.omx/ultragoal` is leader-owned and was not changed by this worker lane.

## Tasks

| ID | Work item | Owner lane | Status | Gate evidence required |
| --- | --- | --- | --- | --- |
| G018-QA-001 | Create G018 docs and final gate skeleton | worker-5 | DONE | `docs/G018/*`, `src/ServerScriptService/Tests/G018/*`, `luac` syntax pass |
| G018-QA-002 | Publish-blocker scan for asset `9922699889` | worker-5 | DONE for repo/worktree scan; live Studio metadata scan still required before publish | Exact commands and zero-match counts in `TEST_RESULTS.md` |
| G018-QA-003 | Small prey ecosystem proof | worker-1/feature lanes | PENDING | `G018FinalGateProof.US27LiveProofPassed=true` plus matrix row evidence |
| G018-QA-004 | Fish schools and water integrity proof | worker-1/feature lanes | PENDING | `US28`/`US29` proof attrs plus placement/E2E evidence |
| G018-QA-005 | Herbivore grazing/action orientation proof | worker-3/feature lanes | PENDING | `US30LiveProofPassed=true`, target-facing and food-target evidence |
| G018-QA-006 | Flight stamina and swim oxygen proof | worker-2/feature lanes | PENDING | `US31`/`US32` proof attrs and client/server E2E evidence |
| G018-QA-007 | Apex, herding, profiles, omnivore proof | worker-4/feature lanes | PENDING | `US33`-`US36` proof attrs and fresh TestRunner evidence |
| G018-QA-008 | Final all-category and live play matrix | leader/QA | BLOCKED | Fresh all-category zero-failure run, live E2E run id, RBXL persistence, 500 asset count |

## Current blockers before any final PASS

1. G018 implementation lanes are still pending live proof for US27-US36.
2. `G018FinalGateProof` has not been produced by a fresh Studio/live harness.
3. 500 release-ready visible Creator Store assets are still required by `AssetManifest.MinimumUniqueAssets` and `AssetImportAuditService:ValidateReleaseCounts`.
4. This lane ran a repo/worktree scan for `9922699889`, but a publish claim still needs a live Studio/place metadata scan if the leader requires Studio-only evidence.
