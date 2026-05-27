# Workspace Layout

Create folders in Studio or generated map scripts: Zones, FoodSources, WaterSources, NPCSpawns, Nests, Fossils, Landmarks.

Visible imported assets must reference `ReplicatedStorage.Shared.AssetManifest` with `AssetManifestId` and, when present on the instance, a matching `SourceAssetId`. The manifest is the source of truth for the G011 rule: 500 unique Roblox Creator Store source asset IDs, with imported scripts removed or sandbox-audited before runtime placement.
