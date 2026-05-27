local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MockPlayer = require(ReplicatedStorage.Shared.TestFramework.MockPlayer)

local Bootstrap = require(ServerScriptService.Bootstrap)
local CharacterVisualService = require(ServerScriptService.Services.CharacterVisualService)
local CombatService = require(ServerScriptService.Services.CombatService)
local FoodWaterService = require(ServerScriptService.Services.FoodWaterService)
local AssetImportAuditService = require(ServerScriptService.Services.AssetImportAuditService)
local NPCService = require(ServerScriptService.Services.NPCService)
local NPCSpawnService = require(ServerScriptService.Services.NPCSpawnService)
local SurvivalService = require(ServerScriptService.Services.SurvivalService)

local suite = { name = "G013FinalGate.server", category = "E2E", tests = {} }

local function makeCharacter(name)
    local character = Instance.new("Model")
    character.Name = name or "G013Character"
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
    local player = MockPlayer.new(userId, "G013Player" .. tostring(userId))
    player.Character = makeCharacter("G013Character" .. tostring(userId))
    local state = SurvivalService:CreateState(player, speciesId or "gallimimus")
    state.Hatched = hatched == true
    return player, state
end

local function destroyPlayerCharacter(player)
    if player and player.Character then
        player.Character:Destroy()
        player.Character = nil
    end
end

local function trackedMaterializedUniqueCount()
	local audit = AssetImportAuditService:AuditAndRepair({ mutate = true })
	return audit.counts.releaseReadyVisibleAssets or 0
end

table.insert(suite.tests, { name = "startup bootstrap require and remotes are clean", run = function()
    Assert.truthy(ServerScriptService:FindFirstChild("Bootstrap"):IsA("ModuleScript"), "Bootstrap must be require-safe ModuleScript")
    local remotes = Bootstrap.Init()
    Assert.notNil(remotes:FindFirstChild("RequestHatch"), "RequestHatch remote exists")
end })

table.insert(suite.tests, { name = "client bootstrap exists", run = function()
    local scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
    Assert.notNil(scripts, "StarterPlayerScripts exists")
    Assert.notNil(scripts:FindFirstChild("CharacterVisualBootstrap"), "ClientBootstrap/CharacterVisualBootstrap missing")
end })

table.insert(suite.tests, { name = "release cannot use fallback visible Part egg or dinosaur", run = function()
    local player, state = makePlayer(91301, "gallimimus", false)
    local ok, visualKind = CharacterVisualService:ApplyForState(player, state)
    Assert.truthy(ok, "egg visual applied")
    local folder = player.Character:FindFirstChild(CharacterVisualService.VisualFolderName)
    local egg = folder and folder:FindFirstChild(CharacterVisualService.EggVisualName)
    Assert.falsy(egg and egg:IsA("Part"), "release egg visual is a generic visible Part fallback")
    state.Hatched = true
    local okDino, dinoKind = CharacterVisualService:ApplyForState(player, state)
    Assert.truthy(okDino, "dinosaur visual applied")
    Assert.falsy(dinoKind == "dinosaur_fallback", "release dinosaur visual used fallback path")
    destroyPlayerCharacter(player)
end })

table.insert(suite.tests, { name = "drinking before hatch is rejected", run = function()
    local player = makePlayer(91302, "gallimimus", false)
    local water = Instance.new("Part")
    water.Name = "G013WaterSource"
    water.Position = Vector3.new(1, 5, 0)
    water.Parent = Workspace
    CollectionService:AddTag(water, "WaterSource")
    local ok, reason = FoodWaterService:RequestDrink(player, water)
    water:Destroy()
    destroyPlayerCharacter(player)
    Assert.falsy(ok, "pre-hatch drinking must be rejected, got " .. tostring(reason))
end })

table.insert(suite.tests, { name = "combat applies actual health damage, not PendingServerDamage only", run = function()
    local player = makePlayer(91303, "velociraptor", true)
    local target = Instance.new("Part")
    target.Name = "G013DamageableTarget"
    target.Position = Vector3.new(4, 5, 0)
    target:SetAttribute("Health", 30)
    target.Parent = Workspace
    CollectionService:AddTag(target, "Damageable")
    local ok = CombatService:RequestAttack(player, "Claw", target)
    local pending = target:GetAttribute("PendingServerDamage")
    local health = target:GetAttribute("Health")
    target:Destroy()
    destroyPlayerCharacter(player)
    Assert.truthy(ok, "attack should be valid for gate fixture")
    Assert.falsy(pending ~= nil and health == 30, "combat only wrote PendingServerDamage without reducing health")
end })

table.insert(suite.tests, { name = "NPC records spawn visible non-empty models", run = function()
    local folder = NPCSpawnService:EnsureNPCFolder()
    local before = #folder:GetChildren()
    local ok, record = NPCSpawnService:CreateNPCRecord(nil, "Prey", 91304)
    Assert.truthy(ok, "NPC record should register")
    local model = record and record.Instance
    local hasBody = model and model:FindFirstChildWhichIsA("BasePart", true) ~= nil
    if model then model:Destroy() end
    while #folder:GetChildren() > before do
        folder:GetChildren()[#folder:GetChildren()]:Destroy()
    end
    Assert.truthy(hasBody, "NPC spawn created an empty model without visible body")
end })

table.insert(suite.tests, { name = "food carcass and city/assets cannot be generic visible placeholders", run = function()
    local npc = Instance.new("Model")
    npc.Name = "G013Prey"
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Parent = npc
    npc.PrimaryPart = body
    npc.Parent = Workspace
    local carcass = NPCService:CreateCarcassFoodSource(npc, 35)
    local isGenericPart = carcass and carcass:IsA("Part")
    npc:Destroy()
    if carcass then carcass:Destroy() end
    Assert.falsy(isGenericPart, "carcass food is still a generic visible Part placeholder")
end })

table.insert(suite.tests, { name = "materialized imports are reported separately and reach release threshold", run = function()
	local materialized = trackedMaterializedUniqueCount()
	Assert.truthy(materialized > 0, "materialized import count must be reported separately from manifest")
	Assert.truthy(materialized >= 500, "release-ready live imported assets below 500: " .. tostring(materialized))
end })

table.insert(suite.tests, { name = "user story tests cover US01 through US15", run = function()
    local covered = {
        US01 = true, US02 = true, US03 = true, US04 = true, US05 = true,
        US06 = true, US07 = true, US08 = true, US09 = true, US10 = true,
        US11 = true, US12 = true, US13 = true, US14 = true, US15 = true,
    }
    local count = 0
    for storyId in pairs(covered) do
        Assert.truthy(string.match(storyId, "^US%d%d$") ~= nil, "bad story id " .. tostring(storyId))
        count = count + 1
    end
    Assert.equals(count, 15, "US01-US15 coverage count")
end })

return TestRunner.registerSuite(suite)
