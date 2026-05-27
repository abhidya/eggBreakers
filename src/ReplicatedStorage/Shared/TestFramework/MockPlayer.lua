local MockPlayer = {}
MockPlayer.__index = MockPlayer

function MockPlayer.new(userId, name)
    local self = setmetatable({}, MockPlayer)
    self.UserId = userId or math.random(100000, 999999)
    self.Name = name or ("MockPlayer" .. tostring(self.UserId))
    self.Character = nil
    return self
end

function MockPlayer:IsA(className)
    return className == "Player"
end

return MockPlayer
