# G015 Test Results

Overall release gate: **FAIL**.

| Gate | Status | Evidence |
|---|---|---|
| Rojo availability | PASS | `/usr/local/bin/rojo`, version 7.6.1. |
| Source syntax | PASS | `find src -name '*.lua' -print0 | xargs -0 -n1 luac -p` passed. |
| Rojo build | PASS | `rojo build default.project.json --output /tmp/eggBreakers-g015-gate.rbxl` passed. |
| Studio MCP responsiveness | PASS | Active `eggBreakers2.rbxl` Luau execution succeeded. |
| AssetImportAuditService mutate audit | FAIL | After G015 import batch: actuallyImportedAssets=34, releaseReadyVisibleAssets=34, remaining gap 466. |
| G015 final gate suite | FAIL | 7 total, 1 passed, 6 failed: asset count, fresh all-category proof, mobile proof, RBXL persistence proof, placeholder proof, user-story PASS proof. |
| Fresh all-category TestRunner | FAIL | 146 total, 129 passed, 17 failed. |
| Mobile/controller E2E | BLOCKED | No device/emulator/controller runtime proof available in this lane. |
| RBXL save/reopen persistence | BLOCKED | MCP exposes no save/close/reopen API; not proven. |
| Release placement/import audit | FAIL | Required categories below minimum; placement tests also failed. |
