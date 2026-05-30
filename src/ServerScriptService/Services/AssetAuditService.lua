local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local AssetManifest = require(ReplicatedStorage.Shared.AssetManifest)
local AssetImportAuditService = require(script.Parent.AssetImportAuditService)

local AssetAuditService = {}
AssetAuditService.ForbiddenVisibleNameSignals = { "Placeholder", "Temp", "TODO", "Graybox", "Blockout", "TestCube", "ReplaceMe" }
AssetAuditService.AllowedInvisibleParents = { "InvisibleGameplayVolumes", "NPCSpawns", "Nests", "Fossils", "SpawnLocations" }
AssetAuditService.TestFixtureRootNames = {
    BrainPredator = true,
    BrainPredatorNPC = true,
    BrainPrey = true,
    BrainPreyNPC = true,
    BoundedStepNPC = true,
    CandidatePredatorNPC = true,
    CandidatePreyNPC = true,
    DamageablePrey = true,
    DefaultRobloxAvatar = true,
    DistantGrazingFern = true,
    EdibleCanopyBrowse = true,
    GrazingPreyNPC = true,
    HidePredatorNPC = true,
    HidePreyNPC = true,
    LoopPredatorNPC = true,
    LoopPreyNPC = true,
    MixedCarcass = true,
    MixedFern = true,
    MovementModeWater = true,
    NeedsFern = true,
    NeedsPreyNPC = true,
    NeedsWater = true,
    NestScrapsOmnivoreFood = true,
    OmnivoreReachabilityRoot = true,
    OviraptorHerdMateNPC = true,
    OviraptorOmnivoreNPC = true,
    TestFood = true,
    TreeBrowsingPreyNPC = true,
}

function AssetAuditService:IsVisibleInstance(instance)
    if not instance:IsA("BasePart") then return false end
    return instance.Transparency < 1
end

function AssetAuditService:IsInvisibleHelper(instance)
    if not instance:IsA("BasePart") then return false end
    if instance.Transparency ~= 1 then return false end
    if self:IsCreatorStoreDerived(instance) then return true end
    if instance:GetAttribute("ReleaseHiddenProceduralVisual") == true
        and instance:GetAttribute("InvisibleQueryHelper") == true
        and instance:GetAttribute("GameplayQuery") == true then
        return true
    end
    if instance:GetAttribute("NPCSpawn") == true or instance:GetAttribute("WeatherEffect") == true or instance:GetAttribute("ProceduralVFX") == true then
        return true
    end
    local current = instance.Parent
    while current and current ~= Workspace do
        for _, allowed in ipairs(self.AllowedInvisibleParents) do
            if current.Name == allowed then
                return string.sub(instance.Name, 1, 11) == "_INVISIBLE_"
                    or instance:GetAttribute("GameplayVolume") == true
                    or instance:GetAttribute("NPCSpawn") == true
            end
        end
        current = current.Parent
    end
    return false
end

function AssetAuditService:IsStudioTestFixture(instance)
    if not RunService:IsStudio() then return false end
    if not instance then return false end
    if instance:GetAttribute("TestFixture") == true or instance:GetAttribute("TestOnly") == true then
        return true
    end
    local current = instance
    while current and current ~= Workspace do
        if current.Name == "_TestScratch" or current.Name == "TestScratch" then
            return true
        end
        current = current.Parent
    end
    return instance.Parent == Workspace and self.TestFixtureRootNames[instance.Name] == true
end

function AssetAuditService:CleanupStudioTestFixtures()
    if not RunService:IsStudio() then return 0 end
    local removed = 0
    for _, child in ipairs(Workspace:GetChildren()) do
        if self:IsStudioTestFixture(child) then
            child:Destroy()
            removed = removed + 1
        elseif child:IsA("BasePart")
            and child.Name == "Part"
            and child:GetAttribute("CreatorStoreOnly") ~= true
            and child:GetAttribute("ImportedVisibleAsset") ~= true
            and child:GetAttribute("GameplayVolume") ~= true
            and child:GetAttribute("WaterSource") ~= true then
            child:Destroy()
            removed = removed + 1
        end
    end
    return removed
end

function AssetAuditService:IsCreatorStoreDerived(instance)
    local current = instance
    while current do
        if current:GetAttribute("CreatorStoreOnly") then return true end
        current = current.Parent
    end
    return false
end

function AssetAuditService:IsAllowedProceduralGameplayVisual(instance)
    local current = instance
    while current do
        if current:GetAttribute("WeatherEffect") == true or current:GetAttribute("ProceduralVFX") == true then
            return true
        end
        if current:GetAttribute("ProceduralWaterSource") == true or current:GetAttribute("ProceduralGameplayVisual") == true then
            return true
        end
        current = current.Parent
    end
    return false
end

function AssetAuditService:IsVisibleGeneratedPart(instance)
    if not instance:IsA("Part") or instance.Shape ~= Enum.PartType.Block then return false end
    if self:IsCreatorStoreDerived(instance) then return false end
    return instance:GetAttribute("GeneratedPart") == true
        or instance:GetAttribute("GeneratedVisiblePart") == true
        or instance:GetAttribute("ProceduralGameplayVisual") == true
        or instance:GetAttribute("ProceduralWaterSource") == true
end

function AssetAuditService:ValidateVisibleGeneratedPartRelease(instance, failures)
    if not self:IsVisibleGeneratedPart(instance) then return end
    if instance:GetAttribute("ReleaseVisibleGeneratedPartAllowed") ~= true then
        table.insert(failures, instance:GetFullName() .. " visible generated Part lacks ReleaseVisibleGeneratedPartAllowed=true")
    end
    local reason = instance:GetAttribute("ReleaseVisibleGeneratedPartReason")
    if reason == nil or tostring(reason) == "" then
        table.insert(failures, instance:GetFullName() .. " visible generated Part lacks ReleaseVisibleGeneratedPartReason")
    end
end

function AssetAuditService:IsPotentialFoodCandidate(instance)
    if CollectionService:HasTag(instance, "FoodSource") then return true end
    return instance:GetAttribute("FoodSourceCandidate") == true
        or instance:GetAttribute("FoodWhenDefeated") == true
        or instance:GetAttribute("PotentialCarnivoreFood") == true
        or instance:GetAttribute("PotentialHerbivoreFood") == true
        or instance:GetAttribute("TreeBrowse") == true
end

function AssetAuditService:ValidatePotentialFoodCandidate(instance, failures)
    if not self:IsPotentialFoodCandidate(instance) then return end

    local isTaggedFood = CollectionService:HasTag(instance, "FoodSource")
    local diet = instance:GetAttribute("Diet")
    local nutrition = instance:GetAttribute("Nutrition")
    local hasConcreteFood = (diet == "Herbivore" or diet == "Carnivore" or diet == "Omnivore")
        and type(nutrition) == "number" and nutrition > 0
    if isTaggedFood and not hasConcreteFood then
        table.insert(failures, instance:GetFullName() .. " tagged FoodSource lacks valid Diet/Nutrition")
        return
    end
    if hasConcreteFood then return end

    local vegetationFood = instance:GetAttribute("PotentialHerbivoreFood") == true
        or instance:GetAttribute("TreeBrowse") == true
        or instance:GetAttribute("VegetationType") ~= nil
        or instance:GetAttribute("PlantPart") ~= nil
    if vegetationFood then
        return
    end

    local npcFood = instance:GetAttribute("FoodWhenDefeated") == true
        or instance:GetAttribute("PotentialCarnivoreFood") == true
        or instance:GetAttribute("NPCKind") ~= nil
        or instance:GetAttribute("NPCSpawn") == true
    if npcFood and (instance:GetAttribute("FoodWhenDefeated") == true or instance:GetAttribute("CarnivoreFoodKind") ~= nil) then
        return
    end

    table.insert(failures, instance:GetFullName() .. " potential food candidate lacks concrete food metadata or vegetation/NPC deferred-food attributes")
end

function AssetAuditService:HasForbiddenVisibleName(instance)
    for _, signal in ipairs(self.ForbiddenVisibleNameSignals) do
        if string.find(string.lower(instance.Name), string.lower(signal), 1, true) then return true end
    end
    return false
end

function AssetAuditService:ValidateManifest(minimum)
    return AssetManifest.Validate({ minimum = minimum or AssetManifest.MinimumUniqueAssets })
end

function AssetAuditService:ValidateManifestReference(instance, failures)
    local manifestId = instance:GetAttribute("AssetManifestId")
    if manifestId == nil then
        table.insert(failures, instance:GetFullName() .. " visible imported asset lacks AssetManifestId attribute")
        return
    end
    local entry = AssetManifest.GetById(manifestId)
    if not entry then
        table.insert(failures, instance:GetFullName() .. " references unknown AssetManifestId " .. tostring(manifestId))
        return
    end

    local sourceAssetId = instance:GetAttribute("SourceAssetId")
    if sourceAssetId ~= nil and tostring(sourceAssetId) ~= entry.SourceAssetId then
        table.insert(failures, instance:GetFullName() .. " SourceAssetId does not match manifest entry " .. tostring(manifestId))
    end
    if instance:GetAttribute("ImportedScriptsPresent") == true then
        table.insert(failures, instance:GetFullName() .. " still contains imported scripts after catalog audit")
    end
    if entry.ImportedScriptsPresent or entry.ScriptsAudited ~= true then
        table.insert(failures, instance:GetFullName() .. " references unaudited imported script state in manifest")
    end
    if not AssetManifest.AllowedScriptSandboxStatuses[entry.ScriptSandboxStatus] then
        table.insert(failures, instance:GetFullName() .. " references unsupported manifest script sandbox status")
    end
end


function AssetAuditService:GetAssetStateCounts(options)
    return AssetImportAuditService:AuditAndRepair(options).counts
end

function AssetAuditService:ValidateReleaseImportReadiness(minimum)
    return AssetImportAuditService:ValidateReleaseCounts(minimum)
end

function AssetAuditService:ScanWorkspace()
    local cleanedTestFixtures = self:CleanupStudioTestFixtures()
    local failures = {}
    local visibleCount = 0
    for _, instance in ipairs(Workspace:GetDescendants()) do
        if not self:IsStudioTestFixture(instance) then
            if self:IsVisibleInstance(instance) then
                visibleCount = visibleCount + 1
                if self:HasForbiddenVisibleName(instance) then
                    table.insert(failures, instance:GetFullName() .. " has forbidden placeholder-like name")
                end
                if instance:IsA("Part") and instance.Shape == Enum.PartType.Block and not self:IsCreatorStoreDerived(instance) then
                    if self:IsAllowedProceduralGameplayVisual(instance) then
                        self:ValidateVisibleGeneratedPartRelease(instance, failures)
                    else
                        table.insert(failures, instance:GetFullName() .. " is visible default block Part not marked Creator Store-derived")
                    end
                end
                if instance:GetAttribute("ImportedVisibleAsset") == true then
                    self:ValidateManifestReference(instance, failures)
                end
            elseif instance:IsA("BasePart") and instance.Transparency == 1 and not self:IsInvisibleHelper(instance) then
                table.insert(failures, instance:GetFullName() .. " invisible helper violates naming/storage rule")
            end
            self:ValidatePotentialFoodCandidate(instance, failures)
        end
    end
    return { visibleCount = visibleCount, failures = failures, passed = #failures == 0, cleanedTestFixtures = cleanedTestFixtures }
end

return AssetAuditService
