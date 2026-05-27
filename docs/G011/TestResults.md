# G011 Test Results

- PASS: `luac -p` on modified Lua files.
- PASS: `rojo sourcemap default.project.json --output /tmp/eggBreakers-sourcemap.json`.
- PASS: local Lua manifest validation: 500 entries, 500 unique `SourceAssetId`, 123 audited script-bearing sources.
- PASS: Roblox Studio fresh-clone `AssetManifest` validation: 500 entries, 500 unique `SourceAssetId`, `CS-4596418748` probe marked `ScriptsRemoved`.
- PARTIAL: active Studio targeted suite execution used cached old requires for test modules; fresh-clone manifest validation passed and a clean Studio/Rojo reload should exercise the new tests.
