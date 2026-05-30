local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bootstrap = require(script.Parent.Bootstrap)
Bootstrap.Init()

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local PlayerDataService = require(script.Parent.Services.PlayerDataService)
local SurvivalService = require(script.Parent.Services.SurvivalService)
local FoodWaterService = require(script.Parent.Services.FoodWaterService)
local SwimService = require(script.Parent.Services.SwimService)
local FlightService = require(script.Parent.Services.FlightService)
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

local function preferredSpawnBiome(state)
    local species = state and SpeciesConfig[state.SpeciesId]
    local spawnBiomes = species and species.SpawnBiomes
    if type(spawnBiomes) == "table" then
        return spawnBiomes.Primary or spawnBiomes.Nursery or spawnBiomes.Secondary
    end
    return nil
end

local function routeCharacterToSpeciesSpawn(player, state)
    if not player or not state then return false end
    local spawn, spawnCFrame = nil, nil
    if state.NestRespawn and state.NestRespawn.Parent then
        local nest = state.NestRespawn
        spawnCFrame = nest:IsA("Model") and nest:GetPivot() or nest.CFrame
        spawnCFrame = spawnCFrame + Vector3.new(0, 3, 0)
    else
        spawn, spawnCFrame = MapLayoutService:GetPlayerSpawnForSpecies(state.SpeciesId, preferredSpawnBiome(state))
    end

    if spawn then
        player.RespawnLocation = spawn
        state.LastSpawnName = spawn.Name
        state.LastSpawnZoneId = spawn:GetAttribute("ZoneId")
    elseif state.NestRespawn and state.NestRespawn.Parent then
        state.LastSpawnName = state.NestRespawn.Name
        state.LastSpawnZoneId = state.NestRespawn:GetAttribute("ZoneId") or "NurseryGrove"
    end

    local character = player.Character
    if character and spawnCFrame then
        local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        if root then
            character:PivotTo(spawnCFrame)
            return true
        end
    end
    return spawn ~= nil or (state.NestRespawn ~= nil and state.NestRespawn.Parent ~= nil)
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
        routeCharacterToSpeciesSpawn(player, respawned)
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
    routeCharacterToSpeciesSpawn(player, state)
    MovementLockService:SetHatchedMovement(player, false, state)
    CharacterVisualService:ApplyForState(player, state)
    sendStats(player)
end

local function applyCharacterState(player)
    local state = SurvivalService:GetState(player)
    if state and state.Hatched ~= true then
        routeCharacterToSpeciesSpawn(player, state)
    end
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
    local previousState = SurvivalService:GetState(player)
    local oldStage = previousState and previousState.GrowthStage
    local oldGrowth = previousState and previousState.Growth
    local ok, result = FoodWaterService:RequestEat(player, target)
    if ok and result.GrowthStage ~= oldStage then
        local stats = SpeciesConfig[result.SpeciesId].BaseStats[result.GrowthStage]
        result.CurrentWalkSpeed = stats.WalkSpeed
        MovementLockService:SetHatchedMovement(player, true, result)
        CharacterVisualService:ApplyForState(player, result)
        ProgressionService:OnGrowthStage(player, result.GrowthStage)
    end
    if ok and result.Growth ~= oldGrowth then
        CharacterVisualService:ApplyForState(player, result)
    end
    notifyResult(player, ok, result, "Ate food")
    sendStats(player)
end)

Remotes.RequestDrink.OnServerEvent:Connect(function(player, target)
    local previousState = SurvivalService:GetState(player)
    local oldStage = previousState and previousState.GrowthStage
    local oldGrowth = previousState and previousState.Growth
    local ok, result = FoodWaterService:RequestDrink(player, target)
    if ok and result.GrowthStage ~= oldStage then
        ProgressionService:OnGrowthStage(player, result.GrowthStage)
    end
    if ok and result.Growth ~= oldGrowth then
        CharacterVisualService:ApplyForState(player, result)
    end
    notifyResult(player, ok, result, "Drank water")
    sendStats(player)
end)

if Remotes:FindFirstChild("RequestSwim") then
    Remotes.RequestSwim.OnServerEvent:Connect(function(player, water)
        local ok, result = SwimService:RequestSwim(player, water)
        notifyResult(player, ok, result, "Swimming")
        sendStats(player)
    end)
end

if Remotes:FindFirstChild("RequestFlight") then
    Remotes.RequestFlight.OnServerEvent:Connect(function(player, enabled)
        local ok, result = FlightService:RequestFlight(player, enabled == true)
        notifyResult(player, ok, result, enabled == true and "Flight active" or "Flight off")
        sendStats(player)
    end)
end

if Remotes:FindFirstChild("RequestSprint") then
    Remotes.RequestSprint.OnServerEvent:Connect(function(player, enabled)
        local ok, result = SurvivalService:SetSprinting(player, enabled == true)
        if ok and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = result.CurrentWalkSpeed or humanoid.WalkSpeed
            end
        end
        notifyResult(player, ok, result, enabled == true and "Sprint draining stamina" or "Sprint off")
        sendStats(player)
    end)
end

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
