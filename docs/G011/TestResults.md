# G011 Test Results

- PASS: `luac -p` on modified Lua files.
- PASS: `rojo sourcemap default.project.json --output /tmp/eggBreakers-sourcemap-task2.json`.
- PASS: local Lua manifest + placement validation: 500 entries, 500 unique `SourceAssetId`, 143 audited script-bearing sources, city=219, swamp=45, rock=71, fossil=47, foliage=163.
- PASS: Roblox Studio patched-source validation for the active place: 500 entries, 500 unique `SourceAssetId`, 143 audited script-bearing sources, city=219, swamp=45, rock=71, fossil=47, foliage=163.
- PARTIAL: active Studio targeted suite execution can retain cached module requires; validation used a fresh temporary ModuleScript with the current source text to avoid stale cache.
