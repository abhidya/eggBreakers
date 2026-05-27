local SurvivalService = require(script.Parent.SurvivalService)

local OxygenService = {}
OxygenService.MaxOxygen = 100
OxygenService.DrainPerSecond = 12
OxygenService.RestorePerSecond = 25
OxygenService.DrowningDamagePerSecond = 8

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

function OxygenService:EnsureOxygen(state)
    if not state then return nil end
    if type(state.Oxygen) ~= "number" then
        state.Oxygen = self.MaxOxygen
    end
    return state.Oxygen
end

function OxygenService:ApplyOxygenTick(player, deltaSeconds, underwater)
    local state = SurvivalService:GetState(player)
    if not state or state.Dead == true or state.Hatched ~= true then return false, "not_alive_hatched" end
    local delta = deltaSeconds or 1
    self:EnsureOxygen(state)
    if underwater == true then
        state.Oxygen = clamp(state.Oxygen - self.DrainPerSecond * delta, 0, self.MaxOxygen)
        state.Underwater = true
        if state.Oxygen <= 0 then
            SurvivalService:ApplyDamage(player, self.DrowningDamagePerSecond * delta, "Drowning")
        end
    else
        state.Oxygen = clamp(state.Oxygen + self.RestorePerSecond * delta, 0, self.MaxOxygen)
        state.Underwater = false
    end
    return true, state
end

return OxygenService
