local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local SmallPreyService = {}
SmallPreyService.PreyTag = "SmallPrey"
SmallPreyService.DefaultHealth = 20
SmallPreyService.DefaultNutrition = 32

function SmallPreyService:GetPosition(prey)
    if not prey then return nil end
    if prey:IsA("BasePart") then return prey.Position end
    if prey.GetPivot then return prey:GetPivot().Position end
    return nil
end

function SmallPreyService:Register(prey, options)
    if not prey then return false, "missing_prey" end
    local config = options or {}
    prey:SetAttribute("SmallPrey", true)
    prey:SetAttribute("Diet", "Herbivore")
    prey:SetAttribute("Health", config.health or prey:GetAttribute("Health") or self.DefaultHealth)
    prey:SetAttribute("Nutrition", config.nutrition or self.DefaultNutrition)
    prey:SetAttribute("FleesPredators", true)
    if not CollectionService:HasTag(prey, self.PreyTag) then CollectionService:AddTag(prey, self.PreyTag) end
    if not CollectionService:HasTag(prey, "Damageable") then CollectionService:AddTag(prey, "Damageable") end
    return true, prey
end

function SmallPreyService:FleeFrom(prey, threatPosition, distance)
    if not prey or typeof(threatPosition) ~= "Vector3" then return false, "missing_threat" end
    local position = self:GetPosition(prey)
    if not position then return false, "missing_position" end
    local away = position - threatPosition
    if away.Magnitude <= 0.05 then away = Vector3.new(1, 0, 0) end
    local target = position + away.Unit * (distance or 12)
    prey:SetAttribute("LastFleeTarget", string.format("%.1f,%.1f,%.1f", target.X, target.Y, target.Z))
    prey:SetAttribute("LastAction", "Flee")
    if prey:IsA("BasePart") then
        prey.Position = target
    elseif prey.PivotTo then
        prey:PivotTo(CFrame.new(target))
    end
    return true, target
end

function SmallPreyService:CreateCarcass(prey)
    local position = self:GetPosition(prey)
    if not position then return nil, "missing_position" end
    local carcass = Instance.new("Part")
    carcass.Name = (prey.Name or "SmallPrey") .. "_SmallPreyCarcass"
    carcass.Size = Vector3.new(3, 1, 2)
    carcass.Position = position
    carcass.Anchored = true
    carcass.CanCollide = false
    carcass.CanTouch = false
    carcass.CanQuery = true
    carcass.Color = Color3.fromRGB(120, 70, 55)
    carcass:SetAttribute("Diet", "Carnivore")
    carcass:SetAttribute("FoodKind", "SmallPreyCarcass")
    carcass:SetAttribute("Nutrition", prey:GetAttribute("Nutrition") or self.DefaultNutrition)
    carcass:SetAttribute("SourcePrey", prey.Name)
    carcass:SetAttribute("Depleted", false)
    carcass.Parent = Workspace:FindFirstChild("NPCs") or Workspace
    CollectionService:AddTag(carcass, "FoodSource")
    return carcass
end

function SmallPreyService:ApplyDamage(prey, amount)
    if not prey then return false, "missing_prey" end
    local health = math.max(0, (prey:GetAttribute("Health") or self.DefaultHealth) - (amount or 10))
    prey:SetAttribute("Health", health)
    if health <= 0 then
        prey:SetAttribute("Dead", true)
        prey:SetAttribute("LastAction", "Dead")
        local carcass = self:CreateCarcass(prey)
        return true, carcass
    end
    return true, health
end

return SmallPreyService
