local RateLimitService = {}
RateLimitService._last = {}

function RateLimitService:Check(player, actionName, cooldownSeconds, now)
    now = now or os.clock()
    local userId = player.UserId
    self._last[userId] = self._last[userId] or {}
    local last = self._last[userId][actionName]
    if last and now - last < cooldownSeconds then
        return false
    end
    self._last[userId][actionName] = now
    return true
end

function RateLimitService:ClearPlayer(player)
    self._last[player.UserId] = nil
end

return RateLimitService
