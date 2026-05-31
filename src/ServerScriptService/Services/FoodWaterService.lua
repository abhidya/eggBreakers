local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local RemoteValidationService = require(script.Parent.RemoteValidationService)
local SurvivalService = require(script.Parent.SurvivalService)
local WaterService = require(script.Parent.WaterService)

local FoodWaterService = { DepletionLoopRunning = false }
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
    TreeBrowse = true,
    Shrub      = true,
    Grass      = true,
    Berry      = true,
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
    local diet = target:GetAttribute("Diet")
    -- If it explicitly says Carnivore it is a carcass, not foliage.
    if diet == "Carnivore" then return false end
    -- Unlabelled FoodSource parts default to foliage.
    if not diet then return true end
    -- Herbivore/Omnivore tagged parts are foliage.
    return diet == "Herbivore" or diet == "Omnivore"
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
        self:NormaliseFoliageMetadata(target)
        return true
    end
    return false
end

--- Stamp consistent metadata onto a single FoodSource instance.
--- Only writes attributes that are not already set (additive, safe to call multiple times).
function FoodWaterService:NormaliseFoliageMetadata(target)
    if not target then return false, "nil_target" end
    if not CollectionService:HasTag(target, "FoodSource") then return false, "not_food_source" end
    if not isFoliageFoodSource(target) then return false, "not_foliage" end

    -- Diet: must be "Herbivore" so omnivores (pass via ValidateFoodTarget's omnivore branch)
    -- and herbivores both accept it, while carnivores are correctly rejected.
    if not target:GetAttribute("Diet") then
        target:SetAttribute("Diet", self.FoliageDefaultDiet)
    elseif target:GetAttribute("Diet") == "Omnivore" then
        -- Re-tag to Herbivore so the food itself is consistently labelled;
        -- omnivore players/NPCs still eat it because ValidateFoodTarget treats
        -- a Herbivore-labelled food as edible by omnivores (targetDiet ~= diet
        -- only blocks non-omnivore players from wrong-diet food; omnivore
        -- players skip that branch entirely).
        target:SetAttribute("Diet", "Herbivore")
    end

    if not target:GetAttribute("FoodKind") then
        -- Infer from collection tags or default
        local fk = self.FoliageDefaultFoodKind
        if CollectionService:HasTag(target, "TreeProp") then fk = "TreeBrowse" end
        target:SetAttribute("FoodKind", fk)
    end

    if not target:GetAttribute("Nutrition") then
        target:SetAttribute("Nutrition", self.FoliageDefaultNutrition)
    end

    if not target:GetAttribute("RespawnCooldownSeconds") then
        target:SetAttribute("RespawnCooldownSeconds", self.FoliageDefaultRespawnCooldownSeconds)
    end

    -- Mark as EdibleVegetation so NPCService brain can also detect it.
    if not target:GetAttribute("EdibleVegetation") then
        target:SetAttribute("EdibleVegetation", true)
    end

    return true
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
                local ok = self:NormaliseFoliageMetadata(inst)
                if ok then count = count + 1 end
            end
        end
    end

    -- Also watch for future tagged instances (terrain streaming / placement).
    CollectionService:GetInstanceAddedSignal("FoodSource"):Connect(function(inst)
        -- Yield one frame so the instance's attributes may be set by the placer first.
        task.defer(function()
            self:NormaliseFoliageMetadata(inst)
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
    self:NormaliseFoliageMetadata(target)
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
