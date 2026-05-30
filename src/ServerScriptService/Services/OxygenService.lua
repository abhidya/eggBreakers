local SurvivalService = require(script.Parent.SurvivalService)
local SpeciesConfig = require(game:GetService("ReplicatedStorage").Shared.SpeciesConfig)

local OxygenService = {}

-- NOTE (oxygen unification BR-12):
--   OxygenService.MaxOxygen was previously hardcoded to 100, conflicting with
--   the per-species/per-stage MaxOxygen stat in SpeciesConfig (typically 60–110).
--   It is now a FALLBACK only, used when the species stat cannot be resolved
--   (e.g. during hatch before speciesId is set, or in unit tests that do not
--   supply a full state).  All runtime paths read MaxOxygen from the species
--   stat via GetMaxOxygen(state).
--   If a test asserts OxygenService.MaxOxygen == 100, it is testing the
--   fallback constant — that is intentional and correct behaviour.
OxygenService.MaxOxygen = 100      -- fallback / test constant; do NOT use directly in gameplay logic
OxygenService.DrainPerSecond = 12
OxygenService.RestorePerSecond = 25
OxygenService.DrowningDamagePerSecond = 8

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

-- ---------------------------------------------------------------------------
-- GetMaxOxygen
-- Single source of truth.  Reads MaxOxygen from the current growth-stage stat
-- block in SpeciesConfig.  Falls back to OxygenService.MaxOxygen if the state
-- is missing required fields (safety net for tests / edge-cases).
-- ---------------------------------------------------------------------------
function OxygenService:GetMaxOxygen(state)
    if state and state.SpeciesId and state.GrowthStage then
        local cfg = SpeciesConfig[state.SpeciesId]
        if cfg and cfg.BaseStats and cfg.BaseStats[state.GrowthStage] then
            local maxO = cfg.BaseStats[state.GrowthStage].MaxOxygen
            if type(maxO) == "number" and maxO > 0 then
                return maxO
            end
        end
    end
    -- Fallback: use the module constant (keeps old unit tests passing).
    return self.MaxOxygen
end

-- ---------------------------------------------------------------------------
-- EnsureOxygen
-- Initialises state.Oxygen to the species-appropriate maximum when the field
-- is missing or not a number.  Uses GetMaxOxygen so the cap is always correct.
-- ---------------------------------------------------------------------------
function OxygenService:EnsureOxygen(state)
    if not state then return nil end
    local maxO = self:GetMaxOxygen(state)
    if type(state.Oxygen) ~= "number" then
        state.Oxygen = maxO
    end
    return state.Oxygen
end

-- ---------------------------------------------------------------------------
-- ApplyOxygenTick
-- Drains oxygen while underwater (triggering drowning damage at 0) and
-- restores it in air.  Clamp uses GetMaxOxygen so species with higher lung
-- capacity (e.g. Spinosaurus MaxOxygen=110) are handled correctly.
-- ---------------------------------------------------------------------------
function OxygenService:ApplyOxygenTick(player, deltaSeconds, underwater)
    local state = SurvivalService:GetState(player)
    if not state or state.Dead == true or state.Hatched ~= true then return false, "not_alive_hatched" end
    local delta = deltaSeconds or 1
    self:EnsureOxygen(state)
    local maxO = self:GetMaxOxygen(state)
    if underwater == true then
        state.Oxygen = clamp(state.Oxygen - self.DrainPerSecond * delta, 0, maxO)
        state.Underwater = true
        if state.Oxygen <= 0 then
            SurvivalService:ApplyDamage(player, self.DrowningDamagePerSecond * delta, "Drowning")
        end
    else
        state.Oxygen = clamp(state.Oxygen + self.RestorePerSecond * delta, 0, maxO)
        state.Underwater = false
    end
    return true, state
end

return OxygenService
