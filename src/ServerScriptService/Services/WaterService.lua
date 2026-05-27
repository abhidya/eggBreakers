local CollectionService = game:GetService("CollectionService")

local WaterService = {}
WaterService.WaterTag = "WaterSource"
WaterService.FishHabitatTag = "FishHabitat"
WaterService.SafeDepthStuds = 6

function WaterService:IsWaterSource(instance)
    return instance ~= nil and (CollectionService:HasTag(instance, self.WaterTag) or instance:GetAttribute("WaterSource") == true)
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
    if not self:IsWaterSource(water) then return false, "not_water" end
    water:SetAttribute("FishHabitat", true)
    if not CollectionService:HasTag(water, self.FishHabitatTag) then
        CollectionService:AddTag(water, self.FishHabitatTag)
    end
    return true
end

return WaterService
