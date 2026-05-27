# Workspace Layout

Create folders in Studio or generated map scripts: Zones, FoodSources, WaterSources, NPCSpawns, Nests, Fossils, Landmarks. Visible imported assets must be listed in `.omx/AssetManifest.md`.

## Natural Placement Acceptance

Placement plans must pass `PlacementValidationService:ValidatePlan` before assets are committed to the map:

- avoid square/grid spacing by varying X/Z offsets, rotations, and cluster sizes;
- keep all decorative props outside route corridor rectangles plus clearance;
- keep trees, bushes, vines, reeds, and logs in biome groves or edges rather than path centers;
- place city ruins, cars, rubble, overgrowth, and city fossils only inside ApocalypticCity blocks/edges;
- place rocks, cliffs, boulders, and mountain fossils in RedstoneCanyon or MountainNestingCliffs;
- place swamp trees, reeds, logs, mud rocks, and shallow water in SwampDelta;
- keep fossils out of NurseryGrove safe-zone placement.
