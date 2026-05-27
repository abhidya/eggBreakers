# G015 Recheck Summary

| Area | Current status | Evidence | Release blocker? | Next action |
|---|---|---|---|---|
| Latest commit | PASS | f07ceb7 (G015 gate commit on top of 5553ade60ff7c7a0e6cd54a6308ed95b4ed24b53 `added temp`) | No | Use current head in final report. |
| eggBreakers2.rbxl presence | PASS | File exists and Studio instance `eggBreakers2.rbxl` opened/activated by MCP. | No | Keep active for audits. |
| Bootstrap/remotes | PASS | G014 evidence plus active place has `ServerScriptService.Bootstrap`. | No | Re-run during final smoke if continuing. |
| Hatch smoke | PASS | G014 Studio smoke passed; not rerun after G015 import batch. | No | Rerun after any save/reopen. |
| Imported egg visual | PASS | G014 evidence; G015 added `G015_Dinosaur_Nest_Egg` SourceAssetId 4666597044. | No | Audit persistence. |
| Imported dinosaur visual | PASS | G014 evidence for 4 species stage visuals. | No | Audit persistence. |
| Food/water/growth | FAIL | Fresh all-category TestRunner failed placement/integration items; food placement error `attempt to compare number < nil`. | Yes | Fix placement metadata and rerun. |
| Combat | FAIL | Fresh TestRunner failed `CombatServiceTests.server / server applies damage only`, expected 16 got nil. | Yes | Debug CombatService test regression. |
| NPC | FAIL | Release proof blocked by asset count and placement audit; NPC category not fully proven. | Yes | Complete imported NPC placement and TestRunner proof. |
| Carcass | FAIL | Release proof blocked by asset count and placement audit. | Yes | Complete imported carcass placement and asset test proof. |
| City/fossil | FAIL | G015 inserted city/fossil assets but release count remains 34/500 and placement audit incomplete. | Yes | Continue imports and coherent placement. |
| Group/call | FAIL | Server tests exist; client group proof incomplete. | Yes | Run/implement client E2E proof. |
| Nesting | FAIL | G015 nest/egg asset inserted, but release proof and adult nesting E2E remain incomplete. | Yes | Run nesting asset/E2E proof. |
| Client/mobile | BLOCKED | No physical mobile/controller execution available via current MCP; only UI/source tests exist. | Yes | Use device/emulator/controller lane or keep BLOCKED. |
| Asset counts | FAIL | Live Studio audit after G015 batch: releaseReadyVisibleAssets=34/500. | Yes | Import/materialize 466 more real unique assets. |
| Full Studio TestRunner | FAIL | Fresh edit-mode all-category run: 146 total, 129 passed, 17 failed. | Yes | Fix failures and prove Play/client categories. |
| RBXL save/reopen | BLOCKED | MCP can open files but exposes no save/close/reopen persistence API; no verified saved reload after G015 batch. | Yes | Use Studio save/reopen operation or external automation. |
