# G019 Tracked Production Requests

Status: IN PROGRESS — this is a production cleanup tracker, not a release pass.

## Owner requests being tracked together

| ID | Request | Current handling | Status |
|---|---|---|---|
| G019-01 | Make map 50% smaller while preserving assets | Live Studio transform applied to `Workspace/Map`; source compact layout now uses exact half-scale `scaleXZ=0.5` with all source placements transformed together; needs Studio persistence/reload proof | IN PROGRESS |
| G019-02 | Multiple spawn points per dinosaur species by biome | SpeciesConfig now records SpawnBiomes for four starter species; service/test integration in progress | IN PROGRESS |
| G019-03 | Current dinos list | Starter playable species are Gallimimus, Triceratops, Velociraptor, Carnotaurus | TRACKED |
| G019-04 | Carnotaurus upside down | Orientation correction exists but live asset still shows upside down; stronger correction in progress | IN PROGRESS |
| G019-05 | Mobile UI unfriendly/overlap/debug text | Parallel UI lane simplifying HUD/mobile controls for kids | IN PROGRESS |
| G019-06 | Better food/waypoint tracker | Parallel UI lane replacing long text with compact visual cue | IN PROGRESS |
| G019-07 | Food assets/glowing balls are bad | Procedural food/glowing balls remain hidden query helpers and low-quality imported placeholders are auto-excluded/quarantined by source audit | IN PROGRESS |
| G019-08 | Rectangle+ball trees are bad | Procedural tree blocks are hidden query helpers/browse volumes; low-quality rectangle/ball tree imports are auto-excluded/quarantined by source audit | IN PROGRESS |
| G019-09 | Vegetation and NPCs should be potential food | Vegetation browse helpers and all NPC spawn markers are source-tagged as food candidates where appropriate | IN PROGRESS |
| G019-10 | Audit assets and remove/quarantine LQ/mesh ones | Owner policy codified in `docs/G019/AssetQualityPolicy.md`; audit now separates mesh vs LQ exclusions, quarantines non-required excluded roots on mutate, and requires explicit notes before excluding required playable visuals | IN PROGRESS |
| G019-11 | Use team/parallel execution | `omx team` blocked in this pane because not inside tmux; native parallel worker lanes spawned as fallback | IN PROGRESS |

## Hard release facts

- Release cannot pass until live `releaseReadyVisibleAssets >= 500` with fresh Studio/mobile/reload proof.
- Duplicates, catalog-only rows, debug generated Parts, hidden/quarantined visuals, and mesh/LQ/debug policy exclusions do not count as release-ready.
- MeshPart imported assets are now withheld/quarantined by the source audit unless protected as required playable visuals; mesh and low-quality/simple-generated exclusions remain reported separately.
- Required playable visuals must not be erased or excluded without an explicit policy note/replacement rationale.
- Current live asset count may drop after the quality quarantine; report must stay honest.
