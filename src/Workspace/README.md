# Workspace Layout

Create folders in Studio or generated map scripts: Zones, FoodSources, WaterSources, NPCSpawns, Nests, Fossils, Landmarks.

## Natural Placement Acceptance

Placement plans must pass `PlacementValidationService:ValidatePlan` before assets are committed to the map:

- avoid square/grid spacing by varying X/Z offsets, rotations, and cluster sizes;
- keep all decorative props outside route corridor rectangles plus clearance;
- keep trees, bushes, vines, reeds, and logs in biome groves or edges rather than path centers;
- place city ruins, cars, rubble, overgrowth, and city fossils only inside ApocalypticCity blocks/edges;
- place rocks, cliffs, boulders, and mountain fossils in RedstoneCanyon or MountainNestingCliffs;
- place swamp trees, reeds, logs, mud rocks, and shallow water in SwampDelta;
- keep fossils out of NurseryGrove safe-zone placement;
- require final imported placement sets to include at least 500 unique `SourceAssetId` values and fail cloned duplicate source IDs.
