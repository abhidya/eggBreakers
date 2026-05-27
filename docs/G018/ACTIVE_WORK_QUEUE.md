# G018 Active Work Queue

Status: **IN PROGRESS / NOT RELEASE READY**
Created: 2026-05-27.
Scope: ecosystem expansion, water repair, grazing, flight, swimming, apex, herding, species profiles, omnivore support, UI/QA, and publish-blocker proof.

## Release honesty constraints

- Do **not** mark G018 final PASS from docs-only or source-only evidence.
- Preserve the G016 release honesty contract: live Play E2E, fresh all-category TestRunner, mobile/client proof, RBXL save/reopen, and the 500 unique Creator Store release asset gate remain enforced.
- Creator Store / Creator Marketplace imports are primary; `GenerationService` is only a backup authoring path and cannot fake Creator Store provenance or count as a release-ready imported visible asset by itself.
- Blocked asset id `9922699889` must remain absent from source, checked-in RBXL bytes, live Studio place metadata, and publish evidence before any publish claim.
- `.omx/ultragoal` is leader-owned; workers must not mutate Ultragoal artifacts.

## Work items

| ID | Work item | Owner lane | Status | Gate evidence required |
| --- | --- | --- | --- | --- |
| G018-QA-001 | Shared ecosystem profile/stat/UI plumbing | worker-1 | SOURCE FIXING | `G018EcosystemProfileTests`, StatReplication payload, HUD/client proof |
| G018-QA-002 | Small prey ecosystem | worker-2 | SOURCE FIXING | US27 live proof, prey flee/hide/carcass evidence, placement proof |
| G018-QA-003 | Fish schools and water integrity | worker-2 | SOURCE FIXING | US28/US29 proof attrs, fish bounds, water volume/drink/swim audit |
| G018-QA-004 | Herbivore grazing/action orientation | worker-3 | SOURCE FIXING | US30 proof, target-facing action evidence, visible food depletion/respawn |
| G018-QA-005 | Flight stamina and swim oxygen | worker-2 | SOURCE FIXING | US31/US32 server+client proof attrs and exploit rejection evidence |
| G018-QA-006 | Apex, herding, profiles, omnivore | worker-4 | SOURCE FIXING | US33-US36 proof attrs, apex priority, herding, omnivore/security evidence |
| G018-QA-007 | G018 docs/final gate/publish blocker scan | worker-5/worker-1 | SOURCE FIXING | G018 final gate files, publish scan for `9922699889`, no fake PASS |
| G018-QA-008 | Final all-category and live play matrix | leader/QA | BLOCKED | Fresh all-category zero-failure run, live E2E run id, RBXL persistence, mobile/client proof, 500 asset count |

## Current blockers before any final PASS

1. G018 implementation has source/build proof but still needs fresh live proof for US27-US36.
2. `G018FinalGateProof` has not been produced by a fresh Studio/live harness.
3. 500 release-ready visible Creator Store assets are still required by `AssetManifest.MinimumUniqueAssets` and `AssetImportAuditService:ValidateReleaseCounts`.
4. Local scans found no `9922699889` literal in source/RBXL bytes, but a publish claim still needs a live Studio/place metadata scan and RBXL save/reopen proof.
5. Full all-category Studio TestRunner remains blocked by known release/proof gates until the final QA lane supplies fresh evidence.
