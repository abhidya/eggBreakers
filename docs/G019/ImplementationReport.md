# G019 Implementation Report

Status: IN PROGRESS / HONEST FAIL for release.

## Parallel execution

`omx team` was attempted but this pane was not inside the tmux leader pane, so the runtime rejected launch with `Team mode requires running inside tmux current leader pane`. Native parallel worker lanes were used instead with the same tracked task split.

## Completed source changes

- Kid-friendly mobile/HUD cleanup: compact labels (`Snack`, `Chomp`, `Zoom`, `Roar`, `Rest`), less text, no debug-shell wording, optional Flight/Swim hidden unless species supports them, visual arrow/icon food-water tracker.
- Species-biome spawn points: Gallimimus/Fern, Triceratops/Fern+Jungle, Velociraptor/Jungle+Fern, Carnotaurus/Redstone+City, plus nursery fallback spawns. Server routes initial spawn/respawn to species spawns.
- Carnotaurus orientation: source now forces upright correction after attachment and records verification attributes.
- Food loop cleanup: procedural food balls and glowing practice target are hidden query helpers, not visible final food. Vegetation/tree browse helpers become potential herbivore food. Prey/flying prey/NPC carcasses are marked carnivore-food candidates.
- Asset quality policy: live low-quality/mesh/simple-generated audit now separates quarantined/excluded assets from release-ready counts and requires policy notes for required playable visuals.

## Live Studio evidence

Active Studio: `eggBreakers2.rbxl`.

A live quality quarantine moved 96 low-quality/mesh/simple-generated candidates to `ReplicatedStorage/QuarantinedImportedAssets`, hid 47 procedural food markers, then restored the four required playable dinosaur model sets as `RequiredPlayableVisual` exceptions until equal-or-better replacements are imported.

Latest live audit after quarantine/restoration:

| Count | Value |
|---|---:|
| Cataloged SourceAssetIds | 500 |
| Actually Imported Assets | 23 |
| Audited Imported Assets | 23 |
| Tagged Imported Assets | 23 |
| Placed Visible Assets | 23 |
| Release Ready Visible Assets | 23 |
| Script Objects Found | 0 |
| Scripts Quarantined | 0 |
| Quarantined Imported Asset Roots | 96 |
| Remaining Gap To 500 | 477 |

Release remains FAIL because quality filtering reduced the honest live release-ready count to 23/500.

## Verification

- `find src -name '*.lua' -print | sort | xargs -n 1 luac -p` — PASS.
- `rojo build default.project.json --output /tmp/eggBreakers-g019-integrated.rbxl` — PASS.
- `git diff --check -- . ':(exclude)eggBreakers.rbxl' ':(exclude)eggBreakers2.rbxl'` — PASS.
- Studio live `AssetImportAuditService:AuditAndRepair({ mutate = true })` — PASS execution, FAIL release counts (23/500).

## Remaining blockers

- Need 477 more release-ready, quality-approved, unique Creator Store visible assets.
- Need fresh Studio reload/full TestRunner after Rojo sync.
- Need mobile device/touch proof.
- Need saved/reopened `.rbxl` persistence proof after live quarantine and map shrink.
- Need replacement of quarantined LQ food/tree/city/prop visuals with better Creator Store assets.

G019 STATUS: FAIL — release-ready quality-approved imported assets are 23/500; fresh Studio reload/mobile proof remains unproven.
