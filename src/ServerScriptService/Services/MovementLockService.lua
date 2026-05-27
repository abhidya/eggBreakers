local MovementLockService = {}

function MovementLockService:SetHatchedMovement(player, isHatched, state)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    if isHatched and state then
        humanoid.WalkSpeed = state.CurrentWalkSpeed or humanoid.WalkSpeed
        humanoid.JumpPower = 50
    else
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
    end
    return true
end

return MovementLockService
