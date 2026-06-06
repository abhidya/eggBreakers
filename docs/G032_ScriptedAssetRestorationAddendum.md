# G032 Scripted Asset Restoration Addendum

Date: 2026-05-31

## Purpose

Restore assets that were removed as false positives only because they contained executable objects. G032 treats raw scripted Creator Store imports as reviewable source material, not automatic deletion targets.

## Restoration Queue

| Order | Queue item | Target story gap | Live action | Keep condition | Acceptance evidence |
| ---: | --- | --- | --- | --- | --- |
| 1 | Fish | SwampDelta fish, swim, and aquatic feeding proof | Reimport the raw scripted fish asset, preserve the inserted root, and review every `Script`, `LocalScript`, and `ModuleScript` before gameplay placement. | Raw scripts stay disabled in the review queue until reviewed, adapted to eggBreakers-owned behavior, and stamped. Remove only after concrete unsafe or irrelevant review findings. | Fish are visible in valid water, support the fish/swim beat, pass asset audit, and have screenshot or live probe proof. |
| 2 | Nest | Hatch, respawn, home, and lineage proof | Reimport the raw scripted nest or egg/nest asset, then place it as a real nest/home candidate instead of substituting generated parts. | Reviewed/adapted/stamped scripts may stay if they serve nest behavior, animation, sound, or visual state. | Nest/egg is visible after save/reopen, supports the nest prompt/home beat, passes asset audit, and is not counted as a placeholder. |
| 3 | City | Old Eden / ApocalypticCity environmental story proof | Reimport raw scripted ruin, vehicle, building, or city set assets that were removed only by the script heuristic. | Keep reviewed/adapted/stamped scripts that provide useful animation, ambience, destructible-state setup, or local visual effects. | City scene reads as ruin/overgrowth/hazard in one frame, passes asset audit, and provides live discovery or route proof. |
| 4 | Raptor | Predator silhouette, starter identity, and apex threat proof | Reimport raw scripted raptor or dinosaur character assets before falling back to lower-fidelity candidates. | Keep reviewed/adapted/stamped scripts only when behavior is owned, bounded, and compatible with current species systems. | Raptor mesh is recognizable in-world, does not run uncontrolled vendor behavior, passes asset audit, and supports starter/threat proof. |

## Live Execution Rules

1. Do not delete an imported asset solely because it contains scripts. Treat that as a G032 review queue entry.
2. Reimport the raw scripted asset first. Do not replace a false-positive removal with a generated stand-in, primitive placeholder, or unrelated clean asset until the raw asset has failed review.
3. Snapshot the inserted root before edits. Record the source asset id, root name, destination, and queue item.
4. Review every executable descendant. Classify each script as `keep`, `adapt`, `disable`, or `remove`.
5. Raw scripts that have not been adapted stay with the imported root in a disabled review queue stamped `RawImportedScriptPreserved=true` and `ScriptReviewStatus="raw_preserved_pending_adaptation"`. They do not count as release-ready, but they also must not be stripped solely for existing.
6. Runtime scripts may stay enabled only after review, adaptation into eggBreakers-owned behavior, and explicit stamping. Minimum runtime stamp fields are:
   - `ImportedScriptAudited=true`
   - `ImportedScriptAdapted=true`
   - `ImportedScriptStamped=true`
   - `ImportedScriptOwner=<owning eggBreakers service or storyboard pass>`
   - `ScriptAdaptedTo=<repo-owned service/controller entrypoint>`
   - `ScriptAuditDecision=keep`
   - `ScriptAuditScope=G032`
7. Disable and preserve scripts that remain unreviewed, noisy, network-active without ownership, incompatible with current services/controllers, or irrelevant to the target story gap. Quarantine or remove only after review shows concrete risk or no storyboard use.
8. Stamp accepted visible roots and descendants with the same provenance fields used by the Creator Store workflow: `SourceAssetId`, `AssetManifestId`, `CreatorStoreOnly=true`, `ImportedVisibleAsset=true`, and a specific `PlacementRole`.
9. Run the live asset audit after each restored queue item. A restored asset is not release-ready until the audit accepts it and the related fish/nest/city/raptor story proof is captured.
10. Preserve honesty in counts. Catalog-only assets, rejected reimports, generated replacements, hidden quarantine copies, and unreviewed scripted imports do not count toward release-ready visible assets.

## Stop Condition

G032 is complete when the fish, nest, city, and raptor queue items each have a live restored candidate or a documented failed-review reason, with audit evidence and story proof recorded for every kept asset.
