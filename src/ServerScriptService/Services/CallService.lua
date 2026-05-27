local RemoteValidationService = require(script.Parent.RemoteValidationService)
local SurvivalService = require(script.Parent.SurvivalService)

local CallService = {}
CallService.Allowed = { Friendly = true, Warning = true, Threat = true, BabyDistress = true }

function CallService:RequestCall(player, callType)
    if not RemoteValidationService:CheckRate(player, "RequestCall") then return false, "rate_limited" end
    local state = SurvivalService:GetState(player)
    if not state or not self.Allowed[callType] then return false, "bad_call" end
    return true, { Player = player, CallType = callType, Radius = 80 }
end

return CallService
