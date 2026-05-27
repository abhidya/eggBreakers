local RemoteValidationService = require(script.Parent.RemoteValidationService)
local GroupService = { Groups = {}, PlayerGroup = {}, PendingInvites = {} }

function GroupService:RequestInvite(player, targetPlayer)
    if not RemoteValidationService:CheckRate(player, "RequestGroupInvite") then return false, "rate_limited" end
    if typeof(targetPlayer) ~= "Instance" or not targetPlayer:IsA("Player") then return false, "bad_target" end
    if player == targetPlayer then return false, "self_invite" end
    self.PendingInvites[targetPlayer] = self.PendingInvites[targetPlayer] or {}
    local invite = { From = player, To = targetPlayer, CreatedAt = os.time() }
    self.PendingInvites[targetPlayer][player] = invite
    return true, invite
end

function GroupService:CreateOrJoin(player, groupType)
    groupType = groupType or "Herd"
    local group = self.PlayerGroup[player] or { Type = groupType, Members = {} }
    group.Members[player] = true
    self.PlayerGroup[player] = group
    return group
end

function GroupService:AcceptInvite(targetPlayer, fromPlayer)
    local pending = self.PendingInvites[targetPlayer] and self.PendingInvites[targetPlayer][fromPlayer]
    if not pending then return false, "no_invite" end
    local group = self:CreateOrJoin(fromPlayer, "Pack")
    group.Members[targetPlayer] = true
    self.PlayerGroup[targetPlayer] = group
    self.PendingInvites[targetPlayer][fromPlayer] = nil
    return true, group
end

function GroupService:Leave(player)
    local group = self.PlayerGroup[player]
    if group then group.Members[player] = nil end
    self.PlayerGroup[player] = nil
end

return GroupService
