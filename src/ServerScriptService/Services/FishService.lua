local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local WaterService = require(script.Parent.WaterService)

local FishService = {}
FishService.FishTag = "FishSource"
FishService.FishSchoolTag = "FishSchool"
FishService.ImportedScriptAdaptedTag = "ImportedScriptAdapted"
FishService.ImportedBehaviorName = "Beat5VendorFishRandomWalk"
FishService.DefaultNutrition = 18
FishService.DefaultRespawnSeconds = 90
FishService.DefaultRandomWalkStepStuds = 6

function FishService:GetFolder()
    local folder = Workspace:FindFirstChild("FishSources")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "FishSources"
        folder.Parent = Workspace
    end
    return folder
end

function FishService:CreateFishSource(water, name, offset)
    local habitatOk, habitatReason = WaterService:IsValidFishHabitat(water)
    if not habitatOk then return nil, habitatReason end
    local center, sizeOrReason = WaterService:GetBounds(water)
    if not center then return nil, sizeOrReason end
    local size = sizeOrReason
    local fish = Instance.new("Part")
    fish.Name = name or "FishFoodSource"
    fish.Size = Vector3.new(2, 0.6, 1)
    fish.Anchored = true
    fish.CanCollide = false
    fish.CanTouch = false
    fish.CanQuery = true
    fish.Color = Color3.fromRGB(70, 130, 180)
    local localOffset = offset or Vector3.new(0, 0, 0)
    fish.Position = center + Vector3.new(
        math.clamp(localOffset.X, -size.X / 2, size.X / 2),
        math.clamp(localOffset.Y, -size.Y / 2, size.Y / 2),
        math.clamp(localOffset.Z, -size.Z / 2, size.Z / 2)
    )
    fish:SetAttribute("Diet", "Carnivore")
    fish:SetAttribute("FoodKind", "Fish")
    fish:SetAttribute("Nutrition", self.DefaultNutrition)
    fish:SetAttribute("RespawnCooldownSeconds", self.DefaultRespawnSeconds)
    fish:SetAttribute("FishSchool", true)
    fish:SetAttribute("WaterSource", water.Name)
    fish:SetAttribute("WaterSourceName", water.Name)
    fish:SetAttribute("ZoneId", water:GetAttribute("ZoneId"))
    fish:SetAttribute("BiomeId", water:GetAttribute("BiomeId") or water:GetAttribute("ZoneId"))
    fish:SetAttribute("Depleted", false)
    fish.Parent = self:GetFolder()
    CollectionService:AddTag(fish, "FoodSource")
    CollectionService:AddTag(fish, self.FishTag)
    CollectionService:AddTag(fish, self.FishSchoolTag)
    WaterService:MarkFishHabitat(water)
    return fish
end

function FishService:MoveWithinWater(fish, water, offset)
    if not fish or not fish:IsA("BasePart") then return false, "missing_fish" end
    if not WaterService:IsWaterSource(water) then return false, "not_water" end
    local center, sizeOrReason = WaterService:GetBounds(water)
    if not center then return false, sizeOrReason end
    local size = sizeOrReason
    local requested = offset or Vector3.new(0, 0, 0)
    local clamped = Vector3.new(
        math.clamp(requested.X, -size.X / 2, size.X / 2),
        math.clamp(requested.Y, -size.Y / 2, size.Y / 2),
        math.clamp(requested.Z, -size.Z / 2, size.Z / 2)
    )
    fish.Position = center + clamped
    fish:SetAttribute("LastSwimOffset", string.format("%.1f,%.1f,%.1f", clamped.X, clamped.Y, clamped.Z))
    return true
end

function FishService:ApplyBeat5ImportedRandomWalk(fish, water, options)
    if not fish or not fish:IsA("BasePart") then return false, "missing_fish" end
    local habitatOk, habitatReason = WaterService:IsValidFishHabitat(water)
    if not habitatOk then return false, habitatReason end
    local center, sizeOrReason = WaterService:GetBounds(water)
    if not center then return false, sizeOrReason end

    local config = options or {}
    local stepStuds = math.max(0, config.stepStuds or self.DefaultRandomWalkStepStuds)
    local rng = config.rng or Random.new()
    local currentOffset = fish.Position - center
    local walkDelta = Vector3.new(
        rng:NextNumber(-stepStuds, stepStuds),
        rng:NextNumber(-stepStuds * 0.25, stepStuds * 0.25),
        rng:NextNumber(-stepStuds, stepStuds)
    )
    local ok, reason = self:MoveWithinWater(fish, water, currentOffset + walkDelta)
    if not ok then return false, reason end

    fish:SetAttribute("ImportedScriptAdapted", true)
    fish:SetAttribute("AdaptedIntoEggBreakers", true)
    fish:SetAttribute("ScriptAdaptedTo", "FishService.ApplyBeat5ImportedRandomWalk")
    fish:SetAttribute("ImportedBehaviorOwner", self.ImportedBehaviorName)
    fish:SetAttribute("ImportedSourceBeat", "Beat5")
    fish:SetAttribute("LastRandomWalkDelta", string.format("%.1f,%.1f,%.1f", walkDelta.X, walkDelta.Y, walkDelta.Z))
    if not CollectionService:HasTag(fish, self.ImportedScriptAdaptedTag) then
        CollectionService:AddTag(fish, self.ImportedScriptAdaptedTag)
    end
    return true
end

function FishService:FindSchoolForWater(water)
    local waterName = water and water.Name
    if not waterName then return nil end
    for _, fish in ipairs(CollectionService:GetTagged(self.FishSchoolTag)) do
        if fish.Parent ~= nil and fish:GetAttribute("WaterSourceName") == waterName then
            return fish
        end
    end
    return nil
end

function FishService:EnsureFishSchoolsForWaterSources()
    local created = 0
    for _, water in ipairs(CollectionService:GetTagged(WaterService.WaterTag)) do
        if WaterService:IsValidFishHabitat(water) and not self:FindSchoolForWater(water) then
            local fish = self:CreateFishSource(water, water.Name .. "_FishSchool", Vector3.new(0, 0, 0))
            if fish then
                created = created + 1
            end
        end
    end
    return created
end

return FishService
