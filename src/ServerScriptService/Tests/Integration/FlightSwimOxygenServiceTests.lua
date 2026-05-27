local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MockPlayer = require(ReplicatedStorage.Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)
local FlightService = require(game:GetService("ServerScriptService").Services.FlightService)
local SwimService = require(game:GetService("ServerScriptService").Services.SwimService)
local OxygenService = require(game:GetService("ServerScriptService").Services.OxygenService)

local suite = { name = "FlightSwimOxygenServiceTests.server", category = "Integration", tests = {} }

local function makePlayer(id, speciesId, position)
    local player = MockPlayer.new(id, "MovementModeTester")
    RateLimitService:ClearPlayer(player)
    local state = SurvivalService:CreateState(player, speciesId or "gallimimus")
    state.Hatched = true
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Position = position or Vector3.new(0, 3, 0)
    local character = Instance.new("Model")
    root.Parent = character
    player.Character = character
    return player, state, character
end

local function makeWater(position)
    local water = Instance.new("Part")
    water.Name = "MovementModeWater"
    water.Size = Vector3.new(20, 4, 20)
    water.Position = position or Vector3.new(0, 3, 0)
    water.Parent = workspace
    CollectionService:AddTag(water, "WaterSource")
    return water
end

table.insert(suite.tests, { name = "US31 flight is server-gated and consumes stamina", run = function()
    local player, state, character = makePlayer(93101, "velociraptor")
    state.Stamina = 40
    local lockedOk, lockedReason = FlightService:RequestFlight(player, true)
    Assert.falsy(lockedOk, "flight starts locked for non-flyers")
    Assert.equals(lockedReason, "flight_locked", "locked flight reason")
    RateLimitService:ClearPlayer(player)
    state.FlightUnlocked = true
    local ok = FlightService:RequestFlight(player, true)
    Assert.truthy(ok, "unlocked flight starts")
    Assert.equals(state.Flying, true, "state enters flying")
    Assert.equals(state.Stamina, 28, "takeoff consumes stamina")
    RateLimitService:ClearPlayer(player)
    Assert.truthy(FlightService:RequestFlight(player, false), "flight can stop")
    Assert.equals(state.Flying, false, "state exits flying")
    character:Destroy()
end })

table.insert(suite.tests, { name = "US32 swim remote path enters water and initializes oxygen", run = function()
    local player, state, character = makePlayer(93201, "gallimimus", Vector3.new(1, 3, 0))
    state.Stamina = 20
    local water = makeWater(Vector3.new(0, 3, 0))
    local ok = SwimService:RequestSwim(player, water)
    Assert.truthy(ok, "near water swim succeeds")
    Assert.equals(state.Swimming, true, "state enters swimming")
    Assert.equals(state.Flying, false, "swim cancels flying")
    Assert.equals(state.Oxygen, OxygenService.MaxOxygen, "oxygen initialized")
    Assert.equals(state.Stamina, 16, "swim stroke consumes stamina")
    water:Destroy(); character:Destroy()
end })

table.insert(suite.tests, { name = "US32 oxygen drains underwater, damages at zero, and restores at surface", run = function()
    local player, state, character = makePlayer(93202, "gallimimus")
    state.Health = 50
    state.Oxygen = 6
    local ok = OxygenService:ApplyOxygenTick(player, 1, true)
    Assert.truthy(ok, "oxygen tick succeeds")
    Assert.equals(state.Oxygen, 0, "oxygen drains to zero")
    Assert.truthy(state.Health < 50, "drowning damages health")
    local damagedHealth = state.Health
    OxygenService:ApplyOxygenTick(player, 1, false)
    Assert.truthy(state.Oxygen > 0, "oxygen restores at surface")
    Assert.equals(state.Health, damagedHealth, "surface restore does not add damage")
    character:Destroy()
end })

return suite
