local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local WaterService = require(script.Parent.WaterService)

local FishService = {}
FishService.FishTag = "FishSource"
FishService.DefaultNutrition = 18
FishService.DefaultRespawnSeconds = 90

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
    if not WaterService:IsWaterSource(water) then return nil, "not_water" end
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
    fish.Material = Enum.Material.SmoothPlastic
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
    fish:SetAttribute("WaterSource", water.Name)
    fish:SetAttribute("Depleted", false)
    fish:SetAttribute("ProceduralGameplayVisual", true)
    fish:SetAttribute("VisibleGameplayAffordance", true)
    fish:SetAttribute("ReleaseVisibleGeneratedPartAllowed", true)
    fish:SetAttribute("ReleaseVisibleGeneratedPartReason", "Server-authored fish food affordance; source asset id can be attached by story/palette builders.")
    fish:SetAttribute("FloatingAllowed", true)
    fish.Parent = self:GetFolder()
    CollectionService:AddTag(fish, "FoodSource")
    CollectionService:AddTag(fish, self.FishTag)
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

return FishService
