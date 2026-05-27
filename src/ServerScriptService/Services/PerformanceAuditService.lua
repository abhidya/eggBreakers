local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local NPCService = require(script.Parent.NPCService)

local PerformanceAuditService = {}
PerformanceAuditService.MaxNPCs = 30
PerformanceAuditService.MaxParticlesPerZone = 20
PerformanceAuditService.MaxDecorativeCollidableParts = 40
PerformanceAuditService.MaxImportedPartsWithTouch = 25
PerformanceAuditService.MaxImportedRuntimeScripts = 0

function PerformanceAuditService:_isDecorative(instance)
    return instance:GetAttribute("Decorative") == true or instance.Name:find("Foliage") ~= nil
end

function PerformanceAuditService:_isImportedAssetDescendant(instance)
    local current = instance
    while current do
        if current.Name == "ImportedAssets" or current.Name == "ImportedAssetLibrary" then
            return true
        end
        current = current.Parent
    end
    return false
end

function PerformanceAuditService:_isRuntimeScript(instance)
    return instance:IsA("Script") or instance:IsA("LocalScript")
end

function PerformanceAuditService:_scanRoots()
    local roots = {}
    local map = Workspace:FindFirstChild("Map")
    table.insert(roots, map or Workspace)
    local library = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    if library then
        table.insert(roots, library)
    end
    return roots
end

function PerformanceAuditService:_zoneKeyFor(instance)
    local current = instance
    while current do
        local parent = current.Parent
        if parent and parent.Name == "ImportedAssets" then
            return current.Name
        end
        if parent and parent.Name == "Zones" then
            return current.Name
        end
        current = parent
    end
    return "Unzoned"
end

function PerformanceAuditService:Scan()
    local failures = {}
    local decorativeCollidable = 0
    local importedTouchEnabled = 0
    local importedRuntimeScriptCount = 0
    if #NPCService.NPCs > self.MaxNPCs then
        table.insert(failures, "NPC count exceeds cap: " .. tostring(#NPCService.NPCs))
    end
    local particleCountByZone = {}
    for _, scanRoot in ipairs(self:_scanRoots()) do
        for _, instance in ipairs(scanRoot:GetDescendants()) do
            if self:_isRuntimeScript(instance) and self:_isImportedAssetDescendant(instance) then
                importedRuntimeScriptCount = importedRuntimeScriptCount + 1
                table.insert(failures, instance:GetFullName() .. " imported runtime script should be removed or quarantined")
            end
            if instance:IsA("ParticleEmitter") then
            if instance.Enabled and instance.Rate > 0 then
                local key = self:_zoneKeyFor(instance)
                particleCountByZone[key] = (particleCountByZone[key] or 0) + 1
            end
        end
            if instance:IsA("BasePart") then
                if self:_isDecorative(instance) and instance.CanCollide then
                decorativeCollidable = decorativeCollidable + 1
                table.insert(failures, instance:GetFullName() .. " decorative/foliage collision should be disabled")
            end
            if instance:GetAttribute("ImportedVisibleAsset") == true and instance.CanTouch then
                importedTouchEnabled = importedTouchEnabled + 1
            end
                if instance:GetAttribute("ImportedVisibleAsset") == true and instance:GetAttribute("GameplayQuery") ~= true and instance.CanQuery then
                    table.insert(failures, instance:GetFullName() .. " imported decorative asset should disable CanQuery unless GameplayQuery=true")
                end
            end
        end
    end
    if decorativeCollidable > self.MaxDecorativeCollidableParts then
        table.insert(failures, "decorative collidable parts exceed cap: " .. tostring(decorativeCollidable))
    end
    if importedTouchEnabled > self.MaxImportedPartsWithTouch then
        table.insert(failures, "imported CanTouch parts exceed cap: " .. tostring(importedTouchEnabled))
    end
    if importedRuntimeScriptCount > self.MaxImportedRuntimeScripts then
        table.insert(failures, "imported runtime scripts exceed cap: " .. tostring(importedRuntimeScriptCount))
    end
    for zone, count in pairs(particleCountByZone) do
        if count > self.MaxParticlesPerZone then
            table.insert(failures, zone .. " has excessive particle emitters: " .. tostring(count))
        end
    end
    return {
        failures = failures,
        passed = #failures == 0,
        decorativeCollidable = decorativeCollidable,
        importedTouchEnabled = importedTouchEnabled,
        importedRuntimeScriptCount = importedRuntimeScriptCount,
    }
end

return PerformanceAuditService
