# G018 Live Play E2E Matrix

Status: **NOT FINAL PASS**. This matrix defines the required proof contract for `G018FinalGateProof`; it is not satisfied until a fresh live harness writes the listed attributes with concrete evidence.

| Story | Player-visible outcome | Required proof attribute | Current status | Evidence needed |
| --- | --- | --- | --- | --- |
| US27 | Small prey categories are visible, edible, and predator-aware. | `US27LiveProofPassed` | PENDING | Live prey spawn/avoid/flee/eat chain with visible prey count and predator interaction. |
| US28 | Fish schools spawn in valid water and support aquatic hunting. | `US28LiveProofPassed` | PENDING | Live fish school count, water-zone validation, aquatic interaction proof. |
| US29 | Water integrity prevents dry swim/floating drink targets. | `US29LiveProofPassed` | PENDING | Placement + live probe showing drink/swim targets are in valid water volumes. |
| US30 | Herbivore grazing targets real food and faces the action target. | `US30LiveProofPassed` | PENDING | Live grazing path with target orientation proof and food depletion/stat delta. |
| US31 | Flight stamina gates takeoff, glide, landing, exhaustion. | `US31LiveProofPassed` | PENDING | Client/server flight action sequence with stamina drain/recovery and forced landing. |
| US32 | Swim oxygen gates diving, surfacing, damage, recovery. | `US32LiveProofPassed` | PENDING | Underwater oxygen drain, surface recovery, and damage threshold proof. |
| US33 | Apex category events are server-authoritative and readable. | `US33LiveProofPassed` | PENDING | Apex event spawn/telegraph/damage validation plus exploit-safe remote checks. |
| US34 | Herding keeps social species grouped without trapping players. | `US34LiveProofPassed` | PENDING | Herd cohesion/dispersion proof with pathing and no player body-block regression. |
| US35 | Species stat profiles create distinct survival roles. | `US35LiveProofPassed` | PENDING | Stat profile comparison across species/stage, replicated to UI without client authority. |
| US36 | Omnivore support allows safe plant and meat food paths. | `US36LiveProofPassed` | PENDING | Omnivore eats plant and meat through server validation; invalid diet exploit rejected. |

## Final matrix-level attributes

A final G018 pass requires all of the following on `ReplicatedStorage.G018FinalGateProof`:

- `LivePlayE2EMatrixPassed=true`
- `LivePlayE2EMatrixMilestone="G018FinalGate"`
- `LivePlayE2ERunId=<non-empty string>`
- `FreshAllCategoryTestRunnerPassed=true`
- `FreshAllCategoryTestRunnerFailed=0`
- For each US27-US36: `<US##>Status="PASS"`, `<US##>Evidence`, `<US##>ObservedAt`, `<US##>ProofSource`, `<US##>Milestone="G018FinalGate"`.
