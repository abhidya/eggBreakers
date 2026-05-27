local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bootstrap = require(script.Parent.Bootstrap)
Bootstrap.Init()

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local PlayerDataService = require(script.Parent.Services.PlayerDataService)
local SurvivalService = require(script.Parent.Services.SurvivalService)
local FoodWaterService = require(script.Parent.Services.FoodWaterService)
local CombatService = require(script.Parent.Services.CombatService)
local GroupService = require(script.Parent.Services.GroupService)
local CallService = require(script.Parent.Services.CallService)
local NestService = require(script.Parent.Services.NestService)
local FossilService = require(script.Parent.Services.FossilService)
local ProgressionService = require(script.Parent.Services.ProgressionService)
local CityDiscoveryService = require(script.Parent.Services.CityDiscoveryService)
local MapLayoutService = require(script.Parent.Services.MapLayoutService)
local StatReplicationService = require(script.Parent.Services.StatReplicationService)
local MovementLockService = require(script.Parent.Services.MovementLockService)
local CharacterVisualService = require(script.Parent.Services.CharacterVisualService)
local RateLimitService = require(script.Parent.Services.RateLimitService)
local NPCSpawnService = require(script.Parent.Services.NPCSpawnService)
local WeatherBiomeService = require(script.Parent.Services.WeatherBiomeService)
local StarterSpeciesService = require(script.Parent.Services.StarterSpeciesService)

MapLayoutService:EnsureMapFolders()
MapLayoutService:EnsureSpawnSafety()
CityDiscoveryService:EnsureCityDiscoveryTriggers()
SurvivalService:StartNeedsLoop(1, Players, StatReplicationService)
FoodWaterService:StartDepletionLoop(1)
NPCSpawnService:StartSpawnLoop(3)
WeatherBiomeService:StartLoop(90)

local function getStarterSpecies(data)
    return StarterSpeciesService:ChooseStarterSpecies(data)
end

local function notifyResult(player, ok, resultOrReason, successMessage)
    if ok then
        StatReplicationService:Notify(player, successMessage or "Action complete", "Success", 2)
    else
        StatReplicationService:Notify(player, tostring(resultOrReason), "Warning", 2)
    end
end

local function sendStats(player)
    local state = SurvivalService:GetState(player)
    if state then StatReplicationService:Send(player, state) end
end

local function applyDeathState(player, state)
    if not state or state.Dead ~= true then return end
    if state.RespawnScheduled == true then return end
    state.RespawnScheduled = true
    MovementLockService:SetHatchedMovement(player, false, state)
    StatReplicationService:Notify(player, "You died: " .. tostring(state.DeathCause or "Damage") .. ". Respawning from an egg.", "Warning", 4)
    task.delay(2, function()
        if not player.Parent then return end
        local respawned = SurvivalService:Respawn(player)
        MovementLockService:SetHatchedMovement(player, false, respawned)
        CharacterVisualService:ApplyForState(player, respawned)
        sendStats(player)
        StatReplicationService:Notify(player, "Respawned as an egg. Hatch again.", "Info", 4)
    end)
end

SurvivalService:OnDeath(applyDeathState)

local function initializePlayer(player)
    local data = PlayerDataService:Load(player)
    local state = SurvivalService:CreateState(player, getStarterSpecies(data))
    MovementLockService:SetHatchedMovement(player, false, state)
    CharacterVisualService:ApplyForState(player, state)
    sendStats(player)
end

local function applyCharacterState(player)
    local state = SurvivalService:GetState(player)
    MovementLockService:SetHatchedMovement(player, state and state.Hatched == true, state)
    CharacterVisualService:ApplyForState(player, state)
end

local function bindPlayer(player)
    player.CharacterAdded:Connect(function()
        applyCharacterState(player)
    end)
    initializePlayer(player)
    if player.Character then
        applyCharacterState(player)
    end
end

Players.PlayerAdded:Connect(bindPlayer)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(bindPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
    PlayerDataService:Save(player)
    PlayerDataService:Clear(player)
    ProgressionService:Clear(player)
    CityDiscoveryService:Clear(player)
    RateLimitService:ClearPlayer(player)
end)

Remotes.RequestHatch.OnServerEvent:Connect(function(player, inputType)
    if not RateLimitService:Check(player, "RequestHatch", 0.08) then
        StatReplicationService:Notify(player, "Hatch input too fast", "Warning", 1)
        sendStats(player)
        return
    end
    local ok, result = SurvivalService:RequestHatch(player, inputType)
    if ok and result.Hatched then
        local stats = SpeciesConfig[result.SpeciesId].BaseStats[result.GrowthStage]
        result.CurrentWalkSpeed = stats.WalkSpeed
        MovementLockService:SetHatchedMovement(player, true, result)
        CharacterVisualService:ApplyForState(player, result)
        ProgressionService:OnHatched(player)
        StatReplicationService:Notify(player, "You hatched!", "Success", 3)
    else
        notifyResult(player, ok, result, "Shell cracking")
    end
    sendStats(player)
end)

Remotes.RequestEat.OnServerEvent:Connect(function(player, target)
    local oldStage = SurvivalService:GetState(player) and SurvivalService:GetState(player).GrowthStage
    local ok, result = FoodWaterService:RequestEat(player, target)
    if ok and result.GrowthStage ~= oldStage then
        ProgressionService:OnGrowthStage(player, result.GrowthStage)
    end
    notifyResult(player, ok, result, "Ate food")
    sendStats(player)
end)

Remotes.RequestDrink.OnServerEvent:Connect(function(player, target)
    local ok, result = FoodWaterService:RequestDrink(player, target)
    notifyResult(player, ok, result, "Drank water")
    sendStats(player)
end)

Remotes.RequestAttack.OnServerEvent:Connect(function(player, attackType, target)
    local ok, result = CombatService:RequestAttack(player, attackType, target)
    notifyResult(player, ok, result, "Attack attempted")
    sendStats(player)
end)

Remotes.RequestCall.OnServerEvent:Connect(function(player, callType)
    local ok, result = CallService:RequestCall(player, callType)
    notifyResult(player, ok, result, "Call sent")
end)

Remotes.RequestGroupInvite.OnServerEvent:Connect(function(player, targetPlayer)
    local ok, result = GroupService:RequestInvite(player, targetPlayer)
    if ok then StatReplicationService:Notify(targetPlayer, player.Name .. " invited you to a group", "Info", 5) end
    notifyResult(player, ok, result, "Invite sent")
end)

if Remotes:FindFirstChild("RequestGroupAccept") then
    Remotes.RequestGroupAccept.OnServerEvent:Connect(function(player, fromPlayer)
        local ok, result = GroupService:AcceptInvite(player, fromPlayer)
        notifyResult(player, ok, result, "Group joined")
    end)
end

Remotes.RequestNestAction.OnServerEvent:Connect(function(player, actionType, nestInstance)
    local ok, result = NestService:RequestNestAction(player, actionType, nestInstance)
    notifyResult(player, ok, result, "Nest updated")
    sendStats(player)
end)

Remotes.RequestCollectFossil.OnServerEvent:Connect(function(player, fossilInstance)
    local ok, result = FossilService:RequestCollect(player, fossilInstance)
    notifyResult(player, ok, result, "Fossil collected")
    sendStats(player)
end)

-- Test/trigger helper: server-owned discovery path. Map trigger scripts should call this service, never client currency grants.
_G.eggBreakersDiscoverZone = function(player, zoneId)
    return CityDiscoveryService:Discover(player, zoneId)
end
