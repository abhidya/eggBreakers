local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MockPlayer = require(ReplicatedStorage.Shared.TestFramework.MockPlayer)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)

local Bootstrap = require(ServerScriptService.Bootstrap)
local CharacterVisualService = require(ServerScriptService.Services.CharacterVisualService)
local CombatService = require(ServerScriptService.Services.CombatService)
local AssetImportAuditService = require(ServerScriptService.Services.AssetImportAuditService)
local FoodWaterService = require(ServerScriptService.Services.FoodWaterService)
local NPCService = require(ServerScriptService.Services.NPCService)
local NPCSpawnService = require(ServerScriptService.Services.NPCSpawnService)
local SurvivalService = require(ServerScriptService.Services.SurvivalService)

local suite = { name = "G014FinalGate", category = "E2E", tests = {} }

local function makeCharacter(name)
    local character = Instance.new("Model")
    character.Name = name or "G014Character"
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 2, 1)
    root.Position = Vector3.new(0, 5, 0)
    root.Parent = character
    character.PrimaryPart = root
    character.Parent = Workspace
    return character, root
end

local function makePlayer(userId, speciesId, hatched)
    local player = MockPlayer.new(userId, "G014Player" .. tostring(userId))
    player.Character = makeCharacter("G014Character" .. tostring(userId))
    local state = SurvivalService:CreateState(player, speciesId or "parasaurolophus")
    state.Hatched = hatched == true
    return player, state
end

local function cleanupPlayer(player)
    if player and player.Character then player.Character:Destroy() end
end

local function materializedCount()
	local audit = AssetImportAuditService:AuditAndRepair({ mutate = true })
	return audit.counts.releaseReadyVisibleAssets or 0, audit.counts
end

local function hasRequiredTestFiles()
    local folder = ServerScriptService:FindFirstChild("Tests") and ServerScriptService.Tests:FindFirstChild("G014")
    return folder and folder:FindFirstChild("G014FinalGateSuite") ~= nil and folder:FindFirstChild("G014FinalGate") ~= nil
end

table.insert(suite.tests, { name = "bootstrap creates exact remote contract", run = function()
    local remotes = Bootstrap.Init()
    for remoteName in pairs(require(ReplicatedStorage.Shared.RemoteContracts)) do
        local remote = remotes:FindFirstChild(remoteName)
        Assert.notNil(remote, "missing remote " .. remoteName)
        Assert.equals(remote.ClassName, "RemoteEvent", remoteName .. " class")
    end
end })

table.insert(suite.tests, { name = "release visual assets resolve imported egg and species models", run = function()
    local result = CharacterVisualService:ValidateReleaseVisualAssets()
    Assert.truthy(result.passed, table.concat(result.failures, "; "))
end })

table.insert(suite.tests, { name = "client release fallback parts are dev disabled", run = function()
    local scriptObj = StarterPlayer.StarterPlayerScripts:FindFirstChild("CharacterVisualBootstrap")
    Assert.notNil(scriptObj, "CharacterVisualBootstrap missing")
    Assert.truthy(string.find(scriptObj.Source, "DEBUG_VISUAL_FALLBACK = false", 1, true) ~= nil, "client generated Part fallback must be disabled in release")
    Assert.notNil(StarterPlayer.StarterPlayerScripts:FindFirstChild("ClientBootstrap"), "ClientBootstrap missing")
end })

table.insert(suite.tests, { name = "hatch, drink, and combat are server authoritative", run = function()
    local player, state = makePlayer(91401, "utahraptor", false)
    local water = Instance.new("Part")
    water.Name = "G014Water"
    water.Position = Vector3.new(1, 5, 0)
    water.Parent = Workspace
    CollectionService:AddTag(water, "WaterSource")
    local drinkOk = FoodWaterService:RequestDrink(player, water)
    Assert.falsy(drinkOk, "unhatched player drank water")
    state.Hatched = true
    local target = Instance.new("Part")
    target.Name = "G014Damageable"
    target.Position = Vector3.new(4, 5, 0)
    target:SetAttribute("Health", 30)
    target.Parent = Workspace
    CollectionService:AddTag(target, "Damageable")
    local attack = SpeciesConfig.utahraptor.Abilities.PrimaryAttack
    local attackOk = CombatService:RequestAttack(player, attack, target)
    Assert.truthy(attackOk, "valid attack rejected")
    Assert.truthy((target:GetAttribute("Health") or 30) < 30, "attack did not reduce health")
    Assert.equals(target:GetAttribute("LastServerDamage"), SpeciesConfig.utahraptor.BaseStats.Hatchling.Damage, "server damage marker")
    target:Destroy(); water:Destroy(); cleanupPlayer(player)
end })

table.insert(suite.tests, { name = "NPC and carcass visuals are not generic Part release placeholders", run = function()
    local ok, record = NPCSpawnService:CreateNPCRecord(nil, "Prey", 91402)
    Assert.truthy(ok, "NPC imported model missing: " .. tostring(record))
    local npcModel = record.Instance
    Assert.truthy(npcModel and npcModel:FindFirstChildWhichIsA("BasePart", true) ~= nil, "NPC has no visible body")
    local carcass = NPCService:CreateCarcassFoodSource(record, 35)
    Assert.notNil(carcass, "carcass imported visual missing")
    Assert.falsy(carcass:IsA("Part"), "carcass is generic Part placeholder")
    if carcass then carcass:Destroy() end
    if npcModel then npcModel:Destroy() end
end })

table.insert(suite.tests, { name = "G014 story gate files exist and release import count is honest", run = function()
	Assert.truthy(hasRequiredTestFiles(), "G014 final gate files missing")
	local count, counts = materializedCount()
	Assert.truthy(count > 0, "materialized count missing")
	Assert.truthy(count >= 500, "releaseReadyVisibleAssets below 500: " .. tostring(count) .. " (actuallyImportedAssets=" .. tostring(counts and counts.actuallyImportedAssets or "unknown") .. ")")
end })

return TestRunner.registerSuite(suite)
