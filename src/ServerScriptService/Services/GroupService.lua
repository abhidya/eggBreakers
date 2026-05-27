local RemoteValidationService = require(script.Parent.RemoteValidationService)
local GroupService = { Groups = {}, PlayerGroup = {} }

function GroupService:RequestInvite(player, targetPlayer)
    if not RemoteValidationService:CheckRate(player, "RequestGroupInvite") then return false, "rate_limited" end
    if typeof(targetPlayer) ~= "Instance" or not targetPlayer:IsA("Player") then return false, "bad_target" end
    if player == targetPlayer then return false, "self_invite" end
    return true, { From = player, To = targetPlayer }
end

function GroupService:CreateOrJoin(player, groupType)
    groupType = groupType or "Herd"
    local group = self.PlayerGroup[player] or { Type = groupType, Members = {} }
    group.Members[player] = true
    self.PlayerGroup[player] = group
    return group
end

function GroupService:Leave(player)
    local group = self.PlayerGroup[player]
    if group then group.Members[player] = nil end
    self.PlayerGroup[player] = nil
end

return GroupService
