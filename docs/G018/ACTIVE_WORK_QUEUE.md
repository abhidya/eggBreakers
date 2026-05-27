# G018 Active Work Queue

Rule: no final PASS until live E2E, fresh all-category TestRunner, mobile/client proof, RBXL persistence, publish-blocker scan, and 500 release-ready imported visible assets pass.
Rule: G016 owner complaints and release blockers remain authoritative until fresh evidence supersedes them.
Rule: Creator Store / Creator Marketplace assets are primary; GenerationService remains authoring fallback only and never counts as release-ready imported assets by itself.

## E001 — Shared profile/stat/UI plumbing
Status: SOURCE FIXING
Evidence: species category/profile/movement/oxygen payload and HUD oxygen/profile guidance added; needs fresh Studio TestRunner and client proof.
Next gate: `G018EcosystemProfileTests` plus live HUD/mobile proof.

## E002 — Fish schools and water integrity
Status: TODO
Evidence: no fish school service or live water-volume proof yet.
Next gate: add fish-school placement/runtime tests and live water integrity proof.

## E003 — Grazing/herding/apex events
Status: TODO
Evidence: metadata exists for grazing/herding/apex categories, but behavior/event systems are not live-proven.
Next gate: source tests + live E2E for coordinated herd motion and apex event gating.

## E004 — Final QA and publish blockers
Status: BLOCKED
Evidence: local scan found no `9922699889` matches in rbxl strings/manifest, but final gate still requires fresh Studio proof attributes and 500 release-ready assets.
Next gate: run Studio TestRunner, save/reopen audit, mobile/client proof, and asset count validation.
