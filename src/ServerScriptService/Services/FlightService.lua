local RemoteValidationService = require(script.Parent.RemoteValidationService)
local SurvivalService = require(script.Parent.SurvivalService)

local FlightService = {}
FlightService.TakeoffStaminaCost = 12

function FlightService:IsFlightUnlocked(state)
    return state ~= nil and (state.FlightUnlocked == true or state.CanFly == true)
end

function FlightService:RequestFlight(player, enabled)
    if not RemoteValidationService:CheckRate(player, "RequestFlight") then return false, "rate_limited" end
    local state = SurvivalService:GetState(player)
    if not RemoteValidationService:IsAlive(state) or not RemoteValidationService:IsHatched(state) then return false, "not_alive_hatched" end
    if not self:IsFlightUnlocked(state) then return false, "flight_locked" end
    if enabled == true then
        if not SurvivalService:ConsumeStamina(player, self.TakeoffStaminaCost) then return false, "low_stamina" end
        state.Flying = true
        state.Swimming = false
    else
        state.Flying = false
    end
    return true, state
end

return FlightService
