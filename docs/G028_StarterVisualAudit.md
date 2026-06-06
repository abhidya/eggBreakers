# G028 Starter Visual Audit

Validated: 2026-05-31, live Studio `eggBreakers3.rbxl`.

## Trigger

The Play screenshot showed a Parasaurolophus HUD while the character body was a pale block. That means the previous audit proved asset metadata and resolver coverage, but not the actual rendered player model.

## Findings

- The staged dinosaur source library was missing from the open edit tree at the time of the screenshot, so `CharacterVisualService` could not resolve `Workspace.dinosaur`.
- `CharacterVisualService:ApplyForState` hid the default Roblox avatar before proving a replacement egg/dinosaur visual existed. In release mode, a missing imported visual could therefore leave the player as a hidden/default block state.
- Re-inserting Creator Store asset `18759347676` as `G028_RiggedDinosaurModels_AuditCandidate` produced a real rigged dinosaur pack with no executable scripts:
  - `scriptCount=0`
  - `MeshPart=411`
  - `Motor6D=439`
  - `AnimationController=58`
  - `Model=58`
- The pack contains exact starter sources:
  - `Herbivores (land)/Parasaurolophus`
  - `Carnivores (land)/Coelophysis`
  - `Carnivores (land)/Utahraptor`
  - `Omnivores(land)/Citipati (female)`
- The raw imported models are adult-sized. A hatchling Parasaurolophus measured about `46.15` studs long before the source patch, so stage-aware scaling is required for hatchling readability.

## Live Studio Actions

- Renamed/merged the inserted pack into `Workspace.dinosaur`.
- Tagged the root and starter models with `SourceAssetId=18759347676`, `AssetManifestId=G028-18759347676`, `CreatorStoreOnly=true`, `ImportedVisibleAsset=true`, `ScriptsAudited=true`, and `RequiredPlayableVisual=true`.
- Created `Workspace.G028_VisualAuditPreview` and applied the live visual service to all four starters.

## Live Proof

All four starter preview characters resolved as `staged_dinosaur_mesh`:

| Species | Source | MeshParts | Motor6Ds | Readable length before source downscale |
| --- | --- | ---: | ---: | ---: |
| Parasaurolophus | `Workspace.dinosaur.Herbivores (land).Parasaurolophus` | 7 | 7 | 46.15 |
| Coelophysis | `Workspace.dinosaur.Carnivores (land).Coelophysis` | 8 | 8 | 12.06 |
| Utahraptor | `Workspace.dinosaur.Carnivores (land).Utahraptor` | 8 | 8 | 19.16 |
| Citipati | `Workspace.dinosaur.Omnivores(land).Citipati (female)` | 9 | 9 | 13.09 |

Screen capture: `G028_Starter_Visual_Audit_Quartet`.

## Source Fixes

- `ApplyForState` now resolves/prepares a replacement before hiding the default avatar, records visual failure attributes, and leaves the default avatar visible when release fallback is disabled.
- Staged visual resolution now prefers `StagedMeshLibrary:ResolveAny`, so full roster names resolve instead of only the curated table.
- `StagedMeshLibrary` can resolve from `ReplicatedStorage.ImportedAssetLibrary.dinosaur` as well as `Workspace.dinosaur`, so future storage can move away from visible world placement.
- `SpeciesModelService` understands `staged://<species>/<stage>` paths.
- Oversized imported dinosaur meshes are scaled to stage targets before growth scaling. Hatchlings target about `8` studs long while still respecting the minimum visible height.

## Remaining Visual Work

- Save `eggBreakers3.rbxl` after confirming the live `Workspace.dinosaur` import should persist.
- Run a fresh Play screenshot after Rojo sync/reload to confirm the source downscale patch is active in Studio, not just source-controlled.
- Add locomotion/animation audit after the static visual pass; the models are rigged, but animation IDs and controller integration still need proof.
