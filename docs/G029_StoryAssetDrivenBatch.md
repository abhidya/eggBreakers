# G029 Story Asset Driven Batch

Status: **live Studio batch inserted; not final release PASS**.

Date: 2026-05-31

## Search And Preview

Required route used:

```bash
node tools/roblox_search_direct.js search_assets '{"query":"dinosaur egg nest","max_results":10}'
```

Accepted candidates:

| Beat | SourceAssetId | Name | Use |
| --- | --- | --- | --- |
| Beat 0 | `8895193` | Dinosaur eggs in a nest | Nursery hatch nest/egg visual |
| Beat 0 | `93304870` | nest | Secondary rustle nest; scripts reviewed |
| Beat 1/2/4/5 | `12630982706` | PreHistoricPlantPack | Starter food, grazing, jungle cover, swamp cover |

Rejected candidate:

| SourceAssetId | Reason |
| --- | --- |
| `85917246797063` | Search returned an oversized desert/oasis landscape primary while looking for Redstone canyon dressing. It was not placed into the story path. |

## Live Placement

Inserted through Studio `search_creator_store` + `insert_from_creator_store`, then organized under:

`Workspace.Map.ImportedAssets.G029_StoryAssetDrivenBatch`

Placed storyboard clones:

| Instance | Zone | Story role |
| --- | --- | --- |
| `Beat0_NurseryPrimaryNest` | NurseryGrove | Egg wakeup nest |
| `Beat0_NurseryRustleNest` | NurseryGrove | Secondary nest ambience |
| `Beat1_NurseryFernFood_A` | NurseryGrove | First herbivore food read |
| `Beat1_NurseryFernFood_B` | NurseryGrove | First herbivore food read |
| `Beat2_FernPlainsGrazingPatch` | FernPlains | Grazing target |
| `Beat4_JungleBasinAmbushCover` | JungleBasin | Ambush/cover dressing |
| `Beat5_SwampDeltaMarshCover` | SwampDelta | Marsh foliage dressing |

Live probe after placement returned:

```text
placed=7
byZone={NurseryGrove=4, FernPlains=1, JungleBasin=1, SwampDelta=1}
scripts=2
reviewedScripts=2
```

Follow-up grounding repair after live waypoint/assets complaint:

```text
buried BaseParts under G029 batch = 0
all placed storyboard roots have GroundTopY, GroundBottomY, GroundClearance, and GroundedStoryboardAsset=true
```

The source placement gate now checks both floating and buried visible assets, and inherits `ZoneId`/`GroundTopY` from imported model roots so child parts inside marketplace models are covered.

## Script Review

The two imported scripts in `93304870` only call a local `Rustle:Play()` sound from touched leaves/moss. They were stamped:

- `ReviewedImportedScript=true`
- `ScriptAuditPurpose="local rustle sound on touched leaves/moss only"`
- `ScriptSandboxStatus="reviewed_no_remotes_no_datastore_no_damage"`

## Remaining Art Gaps

This batch improves first-session readability, but it is not enough for final design quality:

- Nursery still needs a stronger authored nest composition around the hatch camera.
- Redstone still needs a non-oversized canyon/fossil dressing asset.
- Swamp needs reeds/lily pads or fish-visible water dressing, not only a plant pack clone.
- Live save/reopen proof and full asset audit are still required before counting this as release-ready.
