local CollectionService = game:GetService("CollectionService")

local WaterService = {}
WaterService.WaterTag        = "WaterSource"
WaterService.FishHabitatTag  = "FishHabitat"
WaterService.DrinkableTag    = "DrinkableWater"   -- NEW: shallow+validated water
WaterService.SwimWaterTag    = "SwimWater"
WaterService.SafeDepthStuds  = 6                  -- max Y-size for shallow/drinkable

-- ─────────────────────────────────────────────────────────────
-- Existing public API (stable, unchanged signatures)
-- ─────────────────────────────────────────────────────────────
function WaterService:IsWaterSource(instance)
    return instance ~= nil and (
        CollectionService:HasTag(instance, self.WaterTag)
        or CollectionService:HasTag(instance, self.DrinkableTag)
        or instance:GetAttribute("WaterSource") == true
        or instance:GetAttribute("ShallowDrinkable") == true
    )
end

function WaterService:GetBounds(water)
    if not water then return nil, "missing_water" end
    if water:IsA("BasePart") then
        return water.Position, water.Size
    end
    if water:IsA("Model") then
        local pivot = water:GetPivot()
        local _, size = water:GetBoundingBox()
        return pivot.Position, size
    end
    return nil, "unsupported_water"
end

function WaterService:ClassifyDepth(water)
    if not self:IsWaterSource(water) then return nil, "not_water" end
    local _, sizeOrReason = self:GetBounds(water)
    if typeof(sizeOrReason) ~= "Vector3" then return nil, sizeOrReason end
    local depth = sizeOrReason.Y
    if depth <= self.SafeDepthStuds then
        return "Shallow", depth
    end
    return "Deep", depth
end

function WaterService:ContainsPoint(water, point, padding)
    if typeof(point) ~= "Vector3" then return false, "missing_point" end
    local center, sizeOrReason = self:GetBounds(water)
    if not center then return false, sizeOrReason end
    local size = sizeOrReason
    local pad = padding or 0
    return math.abs(point.X - center.X) <= (size.X / 2 + pad)
        and math.abs(point.Y - center.Y) <= (size.Y / 2 + pad)
        and math.abs(point.Z - center.Z) <= (size.Z / 2 + pad)
end

function WaterService:MarkFishHabitat(water)
    if not self:IsValidFishHabitat(water) then return false, "invalid_fish_habitat" end
    water:SetAttribute("FishHabitat", true)
    if not CollectionService:HasTag(water, self.FishHabitatTag) then
        CollectionService:AddTag(water, self.FishHabitatTag)
    end
    return true
end

-- ─────────────────────────────────────────────────────────────
-- NEW: shallow / drinkable water validation helpers
-- These address the CollisionValidation test that flagged a
-- "too-deep" water zone being accepted as a drink target.
-- ─────────────────────────────────────────────────────────────

--- Returns true when `water` is a valid shallow drinkable source:
---   • tagged WaterSource (or has WaterSource attribute)
---   • Y-size ≤ SafeDepthStuds  (not too deep)
---   • NOT flagged as swim/deep/fish-only water or UndrinkableDepth
--- This is the canonical gate that FoodWaterService / collision
--- validation should use instead of bare IsWaterSource.
function WaterService:IsValidDrinkableWater(water)
    if not self:IsWaterSource(water) then return false, "not_water" end
    -- Explicit opt-out flags let designers mark deep zones undinkable.
    if water:GetAttribute("DeepWater") then return false, "deep_water" end
    if water:GetAttribute("UndrinkableDepth") then return false, "undrinkable_depth" end
    if water:GetAttribute("SwimZone") then return false, "swim_water" end
    if water:GetAttribute("FishSpawnAllowed") then return false, "fish_habitat" end
    local classification, depthOrReason = self:ClassifyDepth(water)
    if classification == nil then
        -- ClassifyDepth failed (e.g. unsupported type); allow rather than block.
        return true
    end
    if classification == "Deep" then
        return false, "too_deep"
    end
    return true
end

function WaterService:IsSwimWater(water)
    if not self:IsWaterSource(water) then return false, "not_water" end
    if water:GetAttribute("SwimZone") == true then return true end
    if water:GetAttribute("DeepWater") == true then return true end
    local classification = self:ClassifyDepth(water)
    if classification == "Deep" then return true end
    return false, "not_swim_water"
end

function WaterService:IsValidFishHabitat(water)
    if not self:IsWaterSource(water) then return false, "not_water" end
    if water:GetAttribute("FishSpawnAllowed") ~= true then return false, "fish_not_allowed" end
    local swimOk = self:IsSwimWater(water)
    if not swimOk then return false, "not_swim_water" end
    return true
end

function WaterService:GetWaterIntegrity(water)
    if not self:IsWaterSource(water) then return nil, "not_water" end
    local depthClass, depthOrReason = self:ClassifyDepth(water)
    if not depthClass then return nil, depthOrReason end
    local swimOk = self:IsSwimWater(water)
    local drinkOk = self:IsValidDrinkableWater(water)
    if drinkOk then
        return "DrinkableShallow", depthOrReason
    end
    if swimOk then
        return depthClass == "Deep" and "SwimDeep" or "SwimShallow", depthOrReason
    end
    return depthClass, depthOrReason
end

--- Marks `water` as a validated shallow drinkable source.
--- Adds the DrinkableWater collection tag and sets the
--- ShallowDrinkable attribute.  Rejects deep/invalid sources.
--- Returns true on success, false + reason on failure.
function WaterService:MarkShallowDrinkable(water)
    local ok, reason = self:IsValidDrinkableWater(water)
    if not ok then return false, reason end
    water:SetAttribute("ShallowDrinkable", true)
    if not CollectionService:HasTag(water, self.DrinkableTag) then
        CollectionService:AddTag(water, self.DrinkableTag)
    end
    return true
end

--- Scan all WaterSource-tagged instances and mark shallow ones
--- as drinkable; deep ones get the DeepWater attribute and have
--- DrinkableWater tag removed if it was previously set in error.
--- Call once at game init (MapLayoutService calls this after
--- EnsureTerrainContinuity).
function WaterService:ValidateAllWaterSources()
    local shallow, deep = 0, 0
    for _, water in ipairs(CollectionService:GetTagged(self.WaterTag)) do
        local classification = self:ClassifyDepth(water)
        local integrity = self:GetWaterIntegrity(water)
        if classification then
            water:SetAttribute("WaterDepthClass", classification)
        end
        if integrity then
            water:SetAttribute("WaterIntegrity", integrity)
        end

        local swimOk = self:IsSwimWater(water)
        if swimOk then
            water:SetAttribute("SwimWater", true)
            water:SetAttribute("ShallowDrinkable", false)
            if not CollectionService:HasTag(water, self.SwimWaterTag) then
                CollectionService:AddTag(water, self.SwimWaterTag)
            end
            if CollectionService:HasTag(water, self.DrinkableTag) then
                CollectionService:RemoveTag(water, self.DrinkableTag)
            end
        elseif classification == "Shallow" then
            self:MarkShallowDrinkable(water)
            shallow = shallow + 1
        elseif classification == "Deep" then
            -- Ensure deep zones are not accidentally drinkable.
            water:SetAttribute("DeepWater", true)
            water:SetAttribute("ShallowDrinkable", false)
            if CollectionService:HasTag(water, self.DrinkableTag) then
                CollectionService:RemoveTag(water, self.DrinkableTag)
            end
            deep = deep + 1
        end

        if self:IsValidFishHabitat(water) then
            self:MarkFishHabitat(water)
        end
    end
    return shallow, deep
end

return WaterService
