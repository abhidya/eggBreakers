local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local RemoteValidationService = require(script.Parent.RemoteValidationService)
local SurvivalService = require(script.Parent.SurvivalService)
local WaterService = require(script.Parent.WaterService)

local FoodWaterService = { DepletionLoopRunning = false, CarcassConsumedCallbacks = {} }
FoodWaterService.EatDistance = 12
FoodWaterService.DrinkDistance = 14
FoodWaterService.FoodGrowthGrant = 4
FoodWaterService.WaterGrowthGrant = 4

-- Foliage food defaults: applied when a FoodSource tagged part has no explicit Diet/FoodKind.
-- Herbivore and Omnivore players/NPCs can eat foliage; Carnivores cannot.
FoodWaterService.FoliageDefaultDiet      = "Herbivore"  -- herbivore-compatible; omnivores pass via ValidateFoodTarget
FoodWaterService.FoliageDefaultFoodKind  = "Foliage"
FoodWaterService.FoliageDefaultNutrition = 20
FoodWaterService.FoliageDefaultRespawnCooldownSeconds = 60

-- Diet labels considered plant/foliage (used when auto-tagging unknown FoodSource parts)
local FOLIAGE_FOOD_KINDS = {
    Foliage    = true,
    Fern       = true,
    StarterPlant = true,
    PlantPatch = true,
    SparsePlant = true,
    MarshPlant = true,
    HighRiskPlant = true,
    TreeBrowse = true,
    Shrub      = true,
    Grass      = true,
    Berry      = true,
}

local OMNIVORE_FOOD_KINDS = {
    SeedPod = true,
    FallenFruit = true,
    Mushroom = true,
    CactusFruit = true,
    NestScraps = true,
    EggScraps = true,
}

local CARNIVORE_FOOD_KINDS = {
    Fish = true,
    TutorialCarcass = true,
    SmallCarcassCache = true,
    PreyCarcass = true,
    SmallPreyCarcass = true,
    AerialPreyCarcass = true,
    LargeCarcass = true,
    PredatorCarcass = true,
    HighRiskCarcass = true,
    PlayerCarcass = true,
}

-- ─────────────────────────────────────────────────────────────
-- Visual helpers (public, stable API)
-- ─────────────────────────────────────────────────────────────
-- Dimmed transparency applied to the *visible* readable foliage child while
-- the food source is depleted. Kept partly visible (not fully hidden) so the
-- player still sees a "grazed-down" cluster that regrows on the timer.
FoodWaterService.DepletedFoliageTransparency = 0.75

function FoodWaterService:GetEatVerb(target, eaterDiet)
    local foodKind = target and target:GetAttribute("FoodKind")
    local foodDiet = target and target:GetAttribute("Diet")
    if foodKind == "Fish" or (target and CollectionService:HasTag(target, "FishSource")) then
        return "SnapFish"
    end
    if foodDiet == "Carnivore" or foodKind == "PreyCarcass" or foodKind == "LargeCarcass" or foodKind == "PredatorCarcass" then
        return eaterDiet == "Omnivore" and "Scavenge" or "BiteCarcass"
    end
    if foodDiet == "Omnivore" then
        return "Forage"
    end
    if foodKind == "TreeBrowse" or (target and target:GetAttribute("TreeBrowse") == true) then
        return "Browse"
    end
    return "Graze"
end

function FoodWaterService:BuildEatContext(target, eaterName, eaterDiet, nutrition)
    local foodKind = target and target:GetAttribute("FoodKind")
    local foodDiet = target and target:GetAttribute("Diet")
    return {
        EaterName = eaterName or "Unknown",
        EaterDiet = eaterDiet or "Unknown",
        FoodName = target and target.Name or "",
        FoodDiet = foodDiet or "Unknown",
        FoodKind = foodKind or (foodDiet == "Carnivore" and "Carcass" or "Foliage"),
        Nutrition = nutrition or (target and target:GetAttribute("Nutrition")) or 25,
        Verb = self:GetEatVerb(target, eaterDiet),
        At = os.time(),
    }
end

function FoodWaterService:StampEaterFeedback(playerOrRecord, state, context)
    if state then
        state.LastEatAction = context.Verb
        state.LastEatTarget = context.FoodName
        state.LastEatFoodKind = context.FoodKind
        state.LastEatFoodDiet = context.FoodDiet
        state.LastEatNutrition = context.Nutrition
        state.LastAteAt = context.At
    end

    local character = playerOrRecord and playerOrRecord.Character
    if character and character.SetAttribute then
        character:SetAttribute("LastAction", "Eat")
        character:SetAttribute("EatingState", context.Verb)
        character:SetAttribute("EatTarget", context.FoodName)
        character:SetAttribute("EatTargetKind", context.FoodKind)
        character:SetAttribute("EatNutrition", context.Nutrition)
    end
end

function FoodWaterService:MarkFoodEaten(target, context)
    if not target then return false, "missing_target" end
    context = context or self:BuildEatContext(target)
    local biteCount = (target:GetAttribute("BiteCount") or 0) + 1
    target:SetAttribute("BiteCount", biteCount)
    target:SetAttribute("LastEatenBy", context.EaterName)
    target:SetAttribute("LastEatenByDiet", context.EaterDiet)
    target:SetAttribute("LastEatAction", context.Verb)
    target:SetAttribute("LastEatNutrition", context.Nutrition)
    target:SetAttribute("LastFoodState", "Depleted")
    target:SetAttribute("Depleted", true)
    target:SetAttribute("DepletedAt", context.At)
    target:SetAttribute("DepletedReason", context.Verb)
    self:SetDepletedVisual(target, true)
    local cooldown = target:GetAttribute("RespawnCooldownSeconds")
    if cooldown then
        target:SetAttribute("DepletedUntil", context.At + cooldown)
    end
    return true, context
end

function FoodWaterService:OnCarcassConsumed(callback)
    if type(callback) ~= "function" then return false, "bad_callback" end
    table.insert(self.CarcassConsumedCallbacks, callback)
    return true
end

function FoodWaterService:NotifyCarcassConsumed(target, eater, state, context)
    if not target or target:GetAttribute("CarcassFoodSource") ~= true then
        return false, "not_carcass"
    end
    local notified = 0
    for _, callback in ipairs(self.CarcassConsumedCallbacks) do
        local ok = pcall(callback, target, eater, state, context)
        if ok then
            notified = notified + 1
        end
    end
    target:SetAttribute("CarcassConsumeCallbacks", notified)
    if target:GetAttribute("CarcassConsumed") ~= true then
        self:ReplaceConsumedCarcassWithBones(target, eater, context)
    end
    return true, notified
end

function FoodWaterService:GetInstancePosition(instance)
    if not instance then return nil end
    if instance:IsA("BasePart") then return instance.Position end
    if instance.GetPivot then
        local ok, pivot = pcall(function() return instance:GetPivot() end)
        if ok then return pivot.Position end
    end
    return nil
end

function FoodWaterService:CreateProceduralBonesReplacement(sourceCarcass, eater, context)
    local position = self:GetInstancePosition(sourceCarcass) or Vector3.new(0, 3, 0)
    local bones = Instance.new("Model")
    bones.Name = (sourceCarcass and sourceCarcass.Name or "Carcass") .. "_Bones"

    local function makeBone(name, size, offset, rotation)
        local part = Instance.new("Part")
        part.Name = name
        part.Shape = Enum.PartType.Cylinder
        part.Size = size
        part.Material = Enum.Material.SmoothPlastic
        part.Color = Color3.fromRGB(228, 218, 184)
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = true
        part.CFrame = CFrame.new(position + offset) * rotation
        part.Parent = bones
        return part
    end

    bones.PrimaryPart = makeBone("SpineBone", Vector3.new(0.45, 5.5, 0.45), Vector3.new(0, 0.35, 0), CFrame.Angles(0, 0, math.rad(90)))
    makeBone("RibBoneA", Vector3.new(0.35, 3.2, 0.35), Vector3.new(-0.8, 0.55, 0.35), CFrame.Angles(math.rad(70), 0, math.rad(90)))
    makeBone("RibBoneB", Vector3.new(0.35, 3.2, 0.35), Vector3.new(0.8, 0.55, -0.35), CFrame.Angles(math.rad(-70), 0, math.rad(90)))

    local skull = Instance.new("Part")
    skull.Name = "SkullBone"
    skull.Shape = Enum.PartType.Ball
    skull.Size = Vector3.new(1.35, 0.9, 1.05)
    skull.Material = Enum.Material.SmoothPlastic
    skull.Color = Color3.fromRGB(232, 223, 190)
    skull.Anchored = true
    skull.CanCollide = false
    skull.CanTouch = false
    skull.CanQuery = true
    skull.CFrame = CFrame.new(position + Vector3.new(2.9, 0.55, 0))
    skull.Parent = bones

    bones:SetAttribute("Diet", "")
    bones:SetAttribute("Nutrition", 0)
    bones:SetAttribute("FoodKind", "DepletedCarcassBones")
    bones:SetAttribute("Depleted", true)
    bones:SetAttribute("CarcassBones", true)
    bones:SetAttribute("CarcassConsumed", true)
    bones:SetAttribute("ProceduralBonesVisual", true)
    bones:SetAttribute("SourceCarcass", sourceCarcass and sourceCarcass.Name or "")
    bones:SetAttribute("EatenBy", (context and context.EaterName) or (eater and eater.Name) or "")
    bones:SetAttribute("GameplayQuery", true)
    bones.Parent = Workspace:FindFirstChild("NPCs") or Workspace
    return bones
end

function FoodWaterService:ReplaceConsumedCarcassWithBones(carcass, eater, context)
    if not carcass or carcass:GetAttribute("CarcassFoodSource") ~= true then return false, "not_carcass" end
    carcass:SetAttribute("Depleted", true)
    carcass:SetAttribute("Nutrition", 0)
    carcass:SetAttribute("PotentialCarnivoreFood", false)
    carcass:SetAttribute("CarnivoreFoodCandidate", false)
    carcass:SetAttribute("CarcassConsumed", true)
    carcass:SetAttribute("CarcassVisualState", "Bones")
    if CollectionService:HasTag(carcass, "CarnivoreFoodCandidate") then
        CollectionService:RemoveTag(carcass, "CarnivoreFoodCandidate")
    end
    if CollectionService:HasTag(carcass, "FoodSource") then
        CollectionService:RemoveTag(carcass, "FoodSource")
    end

    local bones = self:CreateProceduralBonesReplacement(carcass, eater, context)
    carcass:SetAttribute("BonesReplacement", bones and bones.Name or "")
    if bones and carcass.Parent then
        carcass.Parent = nil
    end
    return bones ~= nil, bones
end

--- Resolve the separate visible foliage child (added by MapLayoutService) so
--- depletion can dim it and regrowth can restore it. Returns nil when absent
--- (e.g. plain test parts), keeping all behaviour additive/safe.
function FoodWaterService:GetFoliageVisual(target)
    if not (target and target:IsA("BasePart")) then return nil end
    local name = target:GetAttribute("FoliageVisualName")
    local visual = name and target:FindFirstChild(name) or target:FindFirstChild("EdibleFoliageVisual")
    if visual and visual:IsA("BasePart") and visual:GetAttribute("EdibleFoliageVisual") then
        return visual
    end
    return nil
end

function FoodWaterService:GetFoliageVisuals(target)
    local visuals = {}
    if not (target and target:IsA("BasePart")) then return visuals end
    for _, descendant in ipairs(target:GetDescendants()) do
        if descendant:IsA("BasePart")
            and (descendant:GetAttribute("EdibleFoliageVisual") == true or descendant:GetAttribute("VisibleGameplayAffordance") == true)
        then
            table.insert(visuals, descendant)
        end
    end
    return visuals
end

function FoodWaterService:SetDepletedVisual(target, depleted)
    if target and target:IsA("BasePart") then
        if depleted then
            if target:GetAttribute("RestoreTransparency") == nil then
                target:SetAttribute("RestoreTransparency", target.Transparency)
            end
            target.Transparency = 1
            target.CanQuery = false
            target.CanTouch = false
        else
            target.Transparency = target:GetAttribute("RestoreTransparency") or 0
            target.CanQuery = true
            target.CanTouch = true
        end

        -- Dim / restore every readable food affordance child. This is
        -- independent of the query part's transparency so the query part stays
        -- an invisible helper while the visible cluster gives feedback.
        for _, visual in ipairs(self:GetFoliageVisuals(target)) do
            if depleted then
                if visual:GetAttribute("RestoreTransparency") == nil then
                    visual:SetAttribute("RestoreTransparency", visual.Transparency)
                end
                visual.Transparency = self.DepletedFoliageTransparency
            else
                visual.Transparency = visual:GetAttribute("RestoreTransparency") or 0
            end
        end
    end
end

-- ─────────────────────────────────────────────────────────────
-- Depletion / regrowth (public, stable API)
-- ─────────────────────────────────────────────────────────────
function FoodWaterService:RefreshDepletion(target, now)
    if not target or target:GetAttribute("Depleted") ~= true then return end
    local depletedUntil = target:GetAttribute("DepletedUntil")
    if depletedUntil and (now or os.time()) >= depletedUntil then
        target:SetAttribute("Depleted", false)
        target:SetAttribute("DepletedUntil", nil)
        self:SetDepletedVisual(target, false)
    end
end

function FoodWaterService:StartDepletionLoop(intervalSeconds)
    if self.DepletionLoopRunning then return false, "already_running" end
    self.DepletionLoopRunning = true
    task.spawn(function()
        while self.DepletionLoopRunning do
            local now = os.time()
            for _, target in ipairs(CollectionService:GetTagged("FoodSource")) do
                self:RefreshDepletion(target, now)
            end
            task.wait(intervalSeconds or 1)
        end
    end)
    return true
end

function FoodWaterService:StopDepletionLoop()
    self.DepletionLoopRunning = false
end

-- ─────────────────────────────────────────────────────────────
-- Foliage metadata normalisation (NEW, additive)
-- Ensures every FoodSource foliage part has consistent Diet /
-- FoodKind / Nutrition / RespawnCooldownSeconds attributes so
-- FoodServiceTests and diet-validation logic agree.
-- ─────────────────────────────────────────────────────────────

--- Returns true if the instance looks like a foliage food source
--- (either its FoodKind is a known plant kind, or it has no Diet
--- set yet and is not tagged as a carcass/carnivore food).
local function isFoliageFoodSource(target)
    local foodKind = target:GetAttribute("FoodKind")
    if foodKind and FOLIAGE_FOOD_KINDS[foodKind] then return true end
    if foodKind and (OMNIVORE_FOOD_KINDS[foodKind] or CARNIVORE_FOOD_KINDS[foodKind]) then return false end
    local diet = target:GetAttribute("Diet")
    -- If it explicitly says Carnivore it is a carcass, not foliage.
    if diet == "Carnivore" then return false end
    -- Unlabelled FoodSource parts default to foliage.
    if not diet then return true end
    -- Explicit omnivore forage keeps its own diet so NPC/player food variety remains visible.
    return diet == "Herbivore"
end

local function inferDietFromFoodKind(target)
    if not target then return nil end
    local diet = target:GetAttribute("Diet")
    if diet == "Herbivore" or diet == "Carnivore" or diet == "Omnivore" then
        return diet
    end
    local foodKind = target:GetAttribute("FoodKind")
    if target:GetAttribute("CarcassFoodSource") == true
        or target:GetAttribute("PlayerCarcass") == true
        or CollectionService:HasTag(target, "FishSource")
        or (foodKind and CARNIVORE_FOOD_KINDS[foodKind])
    then
        return "Carnivore"
    end
    if foodKind and OMNIVORE_FOOD_KINDS[foodKind] then
        return "Omnivore"
    end
    return "Herbivore"
end

local function defaultFoodKindForDiet(diet)
    if diet == "Carnivore" then return "PreyCarcass" end
    if diet == "Omnivore" then return "SeedPod" end
    return FoodWaterService.FoliageDefaultFoodKind
end

--- Live predicate: is this instance a valid, eatable food source right now?
--- True when it carries the "FoodSource" CollectionService tag, OR it is an
--- EdibleVegetation-tagged dressing part (which we promote to FoodSource on the
--- fly so WorldDressing'd vegetation is eatable even before normalisation runs).
function FoodWaterService:IsFoodSource(target)
    if not target then return false end
    if CollectionService:HasTag(target, "FoodSource") then return true end
    if target:GetAttribute("EdibleVegetation") == true then
        -- Promote to a real FoodSource so the eat path / depletion loop pick it up.
        CollectionService:AddTag(target, "FoodSource")
        self:NormaliseFoodMetadata(target)
        return true
    end
    return false
end

--- Stamp consistent metadata onto a single FoodSource instance.
--- Only writes attributes that are not already set (additive, safe to call multiple times).
function FoodWaterService:NormaliseFoodMetadata(target)
    if not target then return false, "nil_target" end
    if not CollectionService:HasTag(target, "FoodSource") then return false, "not_food_source" end

    local inferredDiet = inferDietFromFoodKind(target)
    if not target:GetAttribute("Diet") then
        target:SetAttribute("Diet", inferredDiet)
    end

    if not target:GetAttribute("FoodKind") then
        local fk = defaultFoodKindForDiet(inferredDiet)
        if inferredDiet == "Herbivore" and CollectionService:HasTag(target, "TreeProp") then fk = "TreeBrowse" end
        target:SetAttribute("FoodKind", fk)
    end

    if not target:GetAttribute("Nutrition") then
        target:SetAttribute("Nutrition", self.FoliageDefaultNutrition)
    end

    if not target:GetAttribute("RespawnCooldownSeconds") then
        target:SetAttribute("RespawnCooldownSeconds", self.FoliageDefaultRespawnCooldownSeconds)
    end

    -- Mark only plant browse as EdibleVegetation so meat/fish/omnivore foods stay distinct.
    if isFoliageFoodSource(target) and not target:GetAttribute("EdibleVegetation") then
        target:SetAttribute("EdibleVegetation", true)
    end

    return true
end

function FoodWaterService:NormaliseFoliageMetadata(target)
    return self:NormaliseFoodMetadata(target)
end

--- Scan all currently tagged FoodSource instances and normalise foliage ones.
--- Call once at game init (before the depletion loop starts) and whenever new
--- terrain chunks are loaded.
function FoodWaterService:NormaliseAllFoliageMetadata()
    local count = 0
    for _, target in ipairs(CollectionService:GetTagged("FoodSource")) do
        local ok = self:NormaliseFoliageMetadata(target)
        if ok then count = count + 1 end
    end

    -- Pick up WorldDressingService's edible vegetation living under
    -- Workspace.Map.BiomeDressing. These are tagged EdibleVegetation; promote any
    -- that are not yet FoodSource-tagged so the eat path / depletion loop see them.
    local map = Workspace:FindFirstChild("Map")
    local dressing = map and map:FindFirstChild("BiomeDressing")
    if dressing then
        for _, inst in ipairs(dressing:GetDescendants()) do
            if inst:GetAttribute("EdibleVegetation") == true then
                if not CollectionService:HasTag(inst, "FoodSource") then
                    CollectionService:AddTag(inst, "FoodSource")
                end
                local ok = self:NormaliseFoodMetadata(inst)
                if ok then count = count + 1 end
            end
        end
    end

    -- Also watch for future tagged instances (terrain streaming / placement).
    CollectionService:GetInstanceAddedSignal("FoodSource"):Connect(function(inst)
        -- Yield one frame so the instance's attributes may be set by the placer first.
        task.defer(function()
            self:NormaliseFoodMetadata(inst)
        end)
    end)
    return count
end

-- ─────────────────────────────────────────────────────────────
-- Core eat / drink (public, stable API — unchanged signatures)
-- ─────────────────────────────────────────────────────────────
function FoodWaterService:RequestEat(player, target)
    -- Promote EdibleVegetation dressing parts to tagged FoodSources (with full
    -- metadata) so ValidateFoodTarget's FoodSource-tag check passes for them.
    self:IsFoodSource(target)
    self:NormaliseFoodMetadata(target)
    self:RefreshDepletion(target)
    if not RemoteValidationService:CheckRate(player, "RequestEat") then return false, "rate_limited" end
    local state = SurvivalService:GetState(player)
    if not RemoteValidationService:IsAlive(state) or not RemoteValidationService:IsHatched(state) then return false, "not_alive_hatched" end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local ok, reason = RemoteValidationService:ValidateFoodTarget(root, target, state.Diet, self.EatDistance)
    if not ok then return false, reason end
    local nutrition = target:GetAttribute("Nutrition") or 25
    state.Hunger = math.min(100, state.Hunger + nutrition)
    local context = self:BuildEatContext(target, player.Name, state.Diet, nutrition)
    self:MarkFoodEaten(target, context)
    if target:GetAttribute("CarcassFoodSource") == true then
        self:NotifyCarcassConsumed(target, player, state, context)
    end
    self:StampEaterFeedback(player, state, context)
    SurvivalService:AddGrowth(player, self.FoodGrowthGrant)
    return true, state
end

function FoodWaterService:RequestDrink(player, target)
    if not RemoteValidationService:CheckRate(player, "RequestDrink") then return false, "rate_limited" end
    local state = SurvivalService:GetState(player)
    if not RemoteValidationService:IsAlive(state) or not RemoteValidationService:IsHatched(state) then return false, "not_alive_hatched" end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local drinkOk, drinkReason = WaterService:IsValidDrinkableWater(target)
    if not drinkOk then return false, drinkReason end
    if not RemoteValidationService:IsClose(root, target, self.DrinkDistance) then return false, "too_far" end
    state.Thirst = math.min(100, state.Thirst + 35)
    SurvivalService:AddGrowth(player, self.WaterGrowthGrant)
    return true, state
end

return FoodWaterService
