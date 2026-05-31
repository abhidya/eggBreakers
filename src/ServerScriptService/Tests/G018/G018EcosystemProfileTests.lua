local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local MockPlayer = require(ReplicatedStorage.Shared.TestFramework.MockPlayer)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local SurvivalService = require(ServerScriptService.Services.SurvivalService)
local StatReplicationService = require(ServerScriptService.Services.StatReplicationService)
local RemoteContracts = require(ReplicatedStorage.Shared.RemoteContracts)

local suite = { name = "G018EcosystemProfileTests", category = "Integration", tests = {} }

local function resetPlayer(id, speciesId)
    local player = MockPlayer.new(id, "G018ProfileTester")
    local state = SurvivalService:CreateState(player, speciesId or "parasaurolophus")
    state.Hatched = true
    return player, state
end

table.insert(suite.tests, { name = "species expose ecosystem category movement and survival reserves", run = function()
    for speciesId, species in pairs(SpeciesConfig) do
        Assert.equals(species.SpeciesId, speciesId, "species id matches key")
        Assert.notNil(species.CreatureCategory, "creature category required")
        Assert.notNil(species.EcosystemProfile, "ecosystem profile required")
        Assert.notNil(species.MovementModes, "movement modes required")
        for stage, stats in pairs(species.BaseStats) do
            Assert.truthy(stats.StaminaRegen > 0, speciesId .. " " .. stage .. " stamina regen")
            Assert.truthy(stats.MaxOxygen > 0, speciesId .. " " .. stage .. " oxygen reserve")
            Assert.notNil(stats.FlightStaminaDrain, speciesId .. " " .. stage .. " flight drain declared")
        end
    end
end })

table.insert(suite.tests, { name = "survival state and stat payload include G018 profile fields", run = function()
    local player, state = resetPlayer(61801, "parasaurolophus")
    Assert.equals(state.CreatureCategory, "SmallPrey", "state carries small-prey category")
    Assert.equals(state.EcosystemProfile.CanGraze, true, "state carries grazing profile")
    Assert.equals(state.MovementModes.Ground, true, "state carries movement modes")
    Assert.truthy(state.Oxygen > 0 and state.MaxOxygen > 0, "state carries oxygen reserve")

    local payload = StatReplicationService:BuildPayload(state)
    Assert.equals(payload.creatureCategory, "SmallPrey", "payload carries category")
    Assert.equals(payload.ecosystemProfile.CanGraze, true, "payload carries ecosystem profile")
    Assert.equals(payload.movementModes.Ground, true, "payload carries movement modes")
    Assert.equals(payload.maxOxygen, state.MaxOxygen, "payload carries max oxygen")
    Assert.equals(payload.ageSeconds, state.AgeSeconds, "payload carries readable age")

    SurvivalService:Kill(player, "ProfileProof")
    local deathPayload = StatReplicationService:BuildPayload(state)
    Assert.equals(deathPayload.deathState, "Dying", "payload carries death state")
    Assert.equals(deathPayload.diedAtAgeSeconds, state.DiedAtAgeSeconds, "payload carries death age")
end })

table.insert(suite.tests, { name = "swim oxygen recovers and flight stamina is capability gated", run = function()
    local player, state = resetPlayer(61802, "utahraptor")
    state.Oxygen = state.MaxOxygen
    local ok = SurvivalService:ApplySwimOxygenTick(player, true, 1)
    Assert.truthy(ok, "submerged tick succeeds")
    Assert.truthy(state.Oxygen < state.MaxOxygen, "submerged tick drains oxygen")
    local drained = state.Oxygen
    ok = SurvivalService:ApplySwimOxygenTick(player, false, 1)
    Assert.truthy(ok, "surface tick succeeds")
    Assert.truthy(state.Oxygen > drained, "surface tick recovers oxygen")

    local flightOk, reason = SurvivalService:ConsumeFlightStamina(player, 1)
    Assert.falsy(flightOk, "non-flying species cannot spend flight stamina")
    Assert.equals(reason, "flight_unavailable", "flight gate reason")
end })

table.insert(suite.tests, { name = "remote stat contract advertises G018 profile fields", run = function()
    local payload = RemoteContracts.StatUpdate.Payload
    local seen = {}
    for _, field in ipairs(payload) do seen[field] = true end
    Assert.truthy(seen.oxygen, "oxygen in stat payload contract")
    Assert.truthy(seen.maxOxygen, "max oxygen in stat payload contract")
    Assert.truthy(seen.creatureCategory, "category in stat payload contract")
    Assert.truthy(seen.movementModes, "movement modes in stat payload contract")
    Assert.truthy(seen.ecosystemProfile, "ecosystem profile in stat payload contract")
    Assert.truthy(seen.ageSeconds, "age in stat payload contract")
    Assert.truthy(seen.deathState, "death state in stat payload contract")
    Assert.truthy(seen.diedAtAgeSeconds, "death age in stat payload contract")
end })

return TestRunner.registerSuite(suite)
