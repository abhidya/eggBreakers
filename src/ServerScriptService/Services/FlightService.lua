local RemoteValidationService = require(script.Parent.RemoteValidationService)
local SurvivalService = require(script.Parent.SurvivalService)
local SpeciesConfig = require(game:GetService("ReplicatedStorage").Shared.SpeciesConfig)

local FlightService = {}
FlightService.TakeoffStaminaCost = 12

-- ---------------------------------------------------------------------------
-- IsFlightCapableSpecies
-- Server-authoritative check: returns true if the species in SpeciesConfig
-- declares MovementModes.Flight == true.  This is the single source of truth
-- for whether a dino CAN fly — no client flag needed.
-- ---------------------------------------------------------------------------
function FlightService:IsFlightCapableSpecies(speciesId)
    if not speciesId then return false end
    local cfg = SpeciesConfig[speciesId]
    return cfg ~= nil
        and cfg.MovementModes ~= nil
        and cfg.MovementModes.Flight == true
end

-- ---------------------------------------------------------------------------
-- GrantFlightIfEligible
-- Called by SurvivalService (or a session-init hook) when a player's state is
-- loaded/hatched.  Sets state.FlightUnlocked and state.CanFly based purely on
-- the species config — no separate unlock currency required for the flag.
-- ---------------------------------------------------------------------------
function FlightService:GrantFlightIfEligible(state)
    if not state then return end
    local capable = self:IsFlightCapableSpecies(state.SpeciesId)
    state.FlightUnlocked = capable
    state.CanFly = capable
end

-- ---------------------------------------------------------------------------
-- IsFlightUnlocked
-- Legacy gate preserved; now also respects SpeciesConfig as a fallback so
-- existing states without FlightUnlocked/CanFly set still work correctly.
-- ---------------------------------------------------------------------------
function FlightService:IsFlightUnlocked(state)
    if not state then return false end
    -- Explicit flags take priority (set by GrantFlightIfEligible or prior code).
    if state.FlightUnlocked == true or state.CanFly == true then return true end
    -- Fallback: derive from SpeciesConfig in case flags were never stamped.
    return self:IsFlightCapableSpecies(state.SpeciesId)
end

function FlightService:RequestFlight(player, enabled)
    if not RemoteValidationService:CheckRate(player, "RequestFlight") then return false, "rate_limited" end
    local state = SurvivalService:GetState(player)
    if not RemoteValidationService:IsAlive(state) or not RemoteValidationService:IsHatched(state) then return false, "not_alive_hatched" end
    -- Ensure flags are stamped (idempotent).
    self:GrantFlightIfEligible(state)
    if not self:IsFlightUnlocked(state) then return false, "flight_locked" end
    if enabled == true then
        if not SurvivalService:ConsumeStamina(player, self.TakeoffStaminaCost) then return false, "low_stamina" end
        state.Flying = true
        state.Swimming = false
        state.MovementState = "Flying"
        state.MovementSurface = "Flight"
    else
        state.Flying = false
        state.MovementState = state.Swimming and "Swimming" or "Grounded"
        state.MovementSurface = state.Swimming and "Swim" or "Ground"
    end
    return true, state
end

return FlightService
