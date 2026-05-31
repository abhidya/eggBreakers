# G018 User Story Coverage Matrix

Release honesty rule: **G018 is not PASS** until fresh Studio/live E2E, all-category TestRunner, mobile/client proof, RBXL save/reopen persistence, publish-blocker scan, and the 500 release-ready imported visible asset gate all pass. G016 failures remain release blockers.

Story beat audit: source coverage for Storyboard Beats 0-8 is tracked in `docs/G018/STORY_BEAT_COVERAGE_AUDIT.md`. That audit updates import expectations from strip-all-scripts to reviewed-script policy: dynamic Creator Store executable code may ship only with source review, owner, sandbox/authority checks, tests, and integration proof.

Current G027 audit note: `docs/G027_AssetBackedStoryBatch.md` raises live release-ready visible assets to 26/500 with nest/egg, first-forage plant, and HUD icon source material. This helps Beats 0-1, but does not satisfy any G018 live-proof attribute, mobile proof, RBXL persistence, or the 500-asset final gate.

| Story ID | Story | Unit | Integration | E2E | Client | Security | Placement/Asset | Live Proof | Current Status | Evidence | Next Failing Test |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| G018-US01 | Small prey categories drive prey behavior and HUD identity | FIXING | FIXING | FAIL | FIXING | PASS | BLOCKED | BLOCKED | FIXING | Shared profile/category plumbing and HUD category display added in source; no live prey proof yet. | G018FinalGate live proof attr `G018US01LiveProofPassed` |
| G018-US02 | Fish schools exist only in valid water volumes | MISSING | MISSING | FAIL | N/A | PASS | MISSING | BLOCKED | FAIL | No fish-school service/spawn proof yet. | Fish school placement + live water-volume proof |
| G018-US03 | Water integrity tracks shallow/deep safety and oxygen | PASS | FIXING | FAIL | FIXING | PASS | FIXING | BLOCKED | FIXING | Oxygen state/replication/HUD bar added; no live deep-water integrity proof yet. | G018 water integrity live E2E |
| G018-US04 | Herbivore grazing repairs visible food availability | PASS | FIXING | FAIL | FIXING | PASS | FIXING | BLOCKED | FIXING | Existing food depletion/respawn plus herbivore profile/grazing hint; no live grazing repair proof yet. | Grazing patch depletion/respawn live proof |
| G018-US05 | Flight stamina is server-authoritative and HUD-visible | PASS | FIXING | FAIL | FIXING | PASS | N/A | BLOCKED | FIXING | Flight-stamina capability gate added; no flying species/live flight proof yet. | Flight-capable species stamina live proof |
| G018-US06 | Swim oxygen drains and recovers server-authoritatively | PASS | FIXING | FAIL | FIXING | PASS | FIXING | BLOCKED | FIXING | `ApplySwimOxygenTick` and replicated oxygen HUD added; no live swim proof yet. | Swim oxygen live proof |
| G018-US07 | Apex category events are gated and observable | MISSING | MISSING | FAIL | N/A | PASS | BLOCKED | BLOCKED | FAIL | Apex category metadata exists for Carnotaurus; event system not implemented/proven. | Apex event service/test |
| G018-US08 | Herding groups produce coordinated prey motion | MISSING | MISSING | FAIL | N/A | PASS | BLOCKED | BLOCKED | FAIL | Herding metadata exists for herbivores; coordinated motion not live-proven. | Herding NPC live proof |
| G018-US09 | Species stat profiles replicate to UI without client authority | PASS | FIXING | FAIL | FIXING | PASS | N/A | BLOCKED | FIXING | Server stat payload includes category/profile/movement/oxygen; needs fresh Studio TestRunner/client proof. | G018EcosystemProfileTests + client HUD live proof |
| G018-US10 | Omnivore support allows plant and carcass food without weakening gates | PASS | FIXING | FAIL | N/A | FIXING | N/A | BLOCKED | FIXING | Remote validation accepts `Omnivore` for both food diets; Citipati is the current starter omnivore in source, but its live plant/carcass path is not proven yet. | Citipati omnivore live/source integration proof |
| G018-US11 | Final QA preserves G016 honesty and asset gate | PASS | FIXING | FAIL | BLOCKED | PASS | FAIL | BLOCKED | FAIL | Final gate suite blocks on live proof, publish scan, RBXL persistence, and 500 assets. | G018FinalGateSuite |
