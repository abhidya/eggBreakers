# G018 Story Beat Coverage Audit

Status: **SOURCE COVERAGE IMPROVED / LIVE PROOF STILL BLOCKED**

Audit date: 2026-05-31 worker source lane.

Release honesty rule: this audit does not mark G018 or Beats 0-8 as live PASS. Final acceptance still requires fresh Studio/live E2E screenshots or probes, mobile/client proof, RBXL save/reopen persistence, fresh all-category TestRunner evidence, publish-blocker scan, and the 500 release-ready imported visible asset gate.

## Imported Script Policy

Updated expectation: Creator Store scripts are not automatically forbidden when they make an asset dynamic, but executable imports must be reviewed and owned before they can run in the shipped place.

Required evidence for any imported `Script` or `LocalScript` kept for dynamic asset behavior:

- Source review recorded with owner, purpose, and accepted authority boundary.
- Sandbox/authority proof: no uncontrolled remotes, grants, datastore writes, player damage, teleport, network ownership, or hidden require chain outside the approved behavior.
- Test coverage for the behavior and the denial paths.
- Integration proof in the intended asset context.
- Release audit metadata showing review status, sandbox/authority status, and live proof source.

Unaudited executable imports still fail release readiness. ModuleScripts may remain only when reviewed/sandboxed or owned by repo code.

## Beat-To-Test Map

| Beat | Story acceptance | Current source coverage | Source status | Live-proof gap |
| --- | --- | --- | --- | --- |
| Beat 0 — Egg wakeup | Pre-hatch choice among Coelophysis/Parasaurolophus/Utahraptor/Citipati leads to the same visible baby dinosaur mesh, nest/egg visual, no default avatar/helper box | `StoryboardBeatValidation.server`: staged hatchling mesh + hidden helpers; imported egg/nest when source exists; `E2E_HatchToFirstFood.server`: selected egg species persists through hatch; client hatch UI has starter selector coverage in source | Partial source coverage | Live proof must show selector choice, selected species id, successful hatch without restart, matching post-hatch dinosaur/species UI, real nest/egg, safe food/water, no default avatar |
| Beat 1 — First food/water | Food/water read without labels and match diet/action UI | `StoryboardBeatValidation.server`: hidden query parts, visible classified fern/carcass affordances; existing `FoodWaterPlacementValidation`/water tests | Covered in source | Live capture must prove food looks like food, water looks like water, and action affordance is clear |
| Beat 2 — First predator/prey | Mesh prey/predator silhouettes and combat/threat readability | `StoryboardBeatValidation.server`: staged MeshPart prey/predator NPCs when sources exist; existing NPC spawn/combat tests | Covered in source | Live capture must show readable predator/prey at distance plus impact/health feedback |
| Beat 3 — Growth moment | Visible scale/stage change and UI stage payload | `StoryboardBeatValidation.server`: growth advances to Adult, exposes larger visual scale, and replicates growth stage payload | Covered in source | Before/after screenshots must prove visual growth and UI state change |
| Beat 4 — Jungle ambush/call | Jungle predator setup and call/threat affordance | `StoryboardBeatValidation.server`: JungleBasin dangerous predator marker resolves to call-capable species | Partial source coverage | Live capture must prove dense environment, directional call/alert, and low clutter |
| Beat 5 — Swamp swim/fish/oxygen | Fish only in valid water; swim water distinct from drink-only water | `StoryboardBeatValidation.server`: fish school creation accepted only for valid swim habitat and remains inside water bounds; G018 oxygen tests cover source oxygen drain/recovery | Covered in source for water/fish; oxygen UI still needs client/live proof | Live underwater sequence must prove oxygen appears only while relevant, drains/recovers, and fish interaction works |
| Beat 6 — Redstone apex trial | Apex warning before damage and readable threat | `StoryboardBeatValidation.server`: apex event broadcasts, sets active warning, and marks nearby prey warned | Covered in source | Live capture must show Redstone identity, fossil/route context, apex warning before damage |
| Beat 7 — ApocalypticCity mystery | Old Eden discovery through invisible trigger volumes and city story frame | `StoryboardBeatValidation.server`: city discovery volumes are invisible, non-blocking, and tied to `ApocalypticCity`; existing city placement/progression tests cover routes/reward | Covered in source for trigger contract | Live screenshot must show city ruin/wreck/overgrowth/predator or fossil hook |
| Beat 8 — Nest/lineage/alpha loop | Adult-only nest/home state and egg payoff | `StoryboardBeatValidation.server`: adult LayEgg records egg count, home respawn, and hatchling buff; existing nest E2E covers service path | Covered in source | Live screenshot must show real nest/egg asset and prompt, with anti-grief/safe-zone proof still pending |

## G018 User-Story Crosswalk

| G018 story | Beat relevance | Current audit status |
| --- | --- | --- |
| US27 small prey | Beats 2, 4, 8 | Source profile/spawn coverage exists; live predator/prey proof blocked |
| US28 fish schools | Beat 5 | Source fish-in-water assertion exists; live aquatic hunting proof blocked |
| US29 water integrity | Beats 1, 5 | Source water/drink/swim checks exist; live water-volume proof blocked |
| US30 grazing | Beats 1, 3, 4 | Source food/depletion/growth coverage exists; live grazing orientation/depletion proof blocked |
| US31 flight stamina | Beats 4, 8 optional aerial extension | Source capability tests exist; live flyer proof blocked |
| US32 swim oxygen | Beat 5 | Source oxygen drain/recovery exists; live swim/oxygen UI proof blocked |
| US33 apex events | Beat 6 | Source apex warning assertion exists; live apex event proof blocked |
| US34 herding and pack sociality | Beats 2, 4, 8 | Source herding metadata/brain coverage and pack regroup attributes exist; live coordinated-motion/body-block proof blocked |
| US35 stat profiles | Beat 3 and all roles | Source profile payload coverage exists; client/mobile proof blocked |
| US36 omnivore | Beats 1, 2, 8 | Source diet-gate and NPC mating beat coverage exists; live omnivore path and nest lineage proof blocked |

## Remaining Risks

- Beat 0 now has a stricter UX contract than the older hatch-only proof: it must prove selected species continuity for the current four starters from pre-hatch selector through post-hatch visual/UI reveal, not merely that hatching completes.
- Several source tests prove contracts with mock/staged fixtures, not the current live place visuals.
- Existing security/audit surfaces still contain historical strip/quarantine wording; policy should migrate to reviewed-script metadata before dynamic scripted assets are accepted as release-ready.
- Store candidates are provisional until Creator Store preview, safe-script review, import proof, and gameplay-distance screenshots are attached.
