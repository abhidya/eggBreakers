--[[
    SfxController
    Wave-5 AUDIO/SFX layer (client).

    Listens for the PlayActionSound ServerToClient remote and plays a localized
    Sound at the supplied world position. The server fires a category (EatCrunch,
    DrinkSlurp, AttackBite, HitImpact, Roar) on action success; this controller
    resolves the category to a concrete rbxassetid via SoundLibrary and plays a
    one-shot 3D sound that cleans itself up.

    Design notes:
      • Self-initialises on require (idempotent — safe to require twice).
      • Client-guarded: does nothing meaningful on the server.
      • World-absent safe: never errors if Remotes / character are missing.
      • No leaks: each sound is parented to a short-lived anchored Part and
        removed via Debris after it finishes.
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local SoundService      = game:GetService("SoundService")
local Debris            = game:GetService("Debris")
local Workspace         = game:GetService("Workspace")

local SoundLibrary = require(ReplicatedStorage.Shared.SoundLibrary)

local SfxController = {}
SfxController._initialised = false

local rng = Random.new()

local function toVector3(position)
    if typeof(position) == "Vector3" then
        return position
    end
    if type(position) == "table" then
        local x = tonumber(position.X or position.x or position[1])
        local y = tonumber(position.Y or position.y or position[2])
        local z = tonumber(position.Z or position.z or position[3])
        if x and y and z then
            return Vector3.new(x, y, z)
        end
    end
    return nil
end

-- Plays a one-shot localized sound. Public so other client code/tests can drive it.
function SfxController:Play(category, position, soundId)
    local resolvedId = SoundLibrary:Resolve(category, soundId, rng)
    if not resolvedId then
        return false
    end

    local defaults = SoundLibrary:GetDefaults(category)
    local sound = Instance.new("Sound")
    sound.Name = "Sfx_" .. tostring(category)
    sound.SoundId = resolvedId
    sound.Volume = defaults.Volume or 0.6
    sound.RollOffMaxDistance = defaults.RollOffMaxDistance or 60
    sound.RollOffMinDistance = 6
    local jitter = defaults.PlaybackSpeedJitter or 0
    if jitter > 0 then
        sound.PlaybackSpeed = 1 + rng:NextNumber(-jitter, jitter)
    end

    local worldPosition = toVector3(position)
    if worldPosition then
        -- Anchored, non-colliding emitter at the action's world position for true 3D falloff.
        local emitter = Instance.new("Part")
        emitter.Name = "SfxEmitter"
        emitter.Anchored = true
        emitter.CanCollide = false
        emitter.CanTouch = false
        emitter.CanQuery = false
        emitter.Transparency = 1
        emitter.Size = Vector3.new(0.2, 0.2, 0.2)
        emitter.CFrame = CFrame.new(worldPosition)
        emitter.Parent = Workspace
        sound.Parent = emitter
        sound:Play()
        local lifetime = math.max(0.25, (sound.TimeLength > 0 and sound.TimeLength or 4))
        Debris:AddItem(emitter, lifetime + 0.5)
    else
        -- No position — fall back to a non-positional 2D one-shot.
        sound.Parent = SoundService
        sound:Play()
        local lifetime = math.max(0.25, (sound.TimeLength > 0 and sound.TimeLength or 4))
        Debris:AddItem(sound, lifetime + 0.5)
    end

    sound.Ended:Connect(function()
        if sound.Parent and sound.Parent:IsA("Part") then
            sound.Parent:Destroy()
        else
            sound:Destroy()
        end
    end)

    return true
end

local function onPlayActionSound(payload)
    if type(payload) ~= "table" then return end
    SfxController:Play(payload.category, payload.position, payload.soundId)
end

function SfxController:Init()
    if self._initialised then return self end
    -- Client-guard: only wire remotes on the client. On the server this is a no-op
    -- so the module stays require-safe in shared/test contexts.
    if not RunService:IsClient() then
        return self
    end
    self._initialised = true

    task.spawn(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
        if not remotes then return end
        local remote = remotes:WaitForChild("PlayActionSound", 30)
        if not remote then return end
        remote.OnClientEvent:Connect(onPlayActionSound)
    end)

    return self
end

-- Self-init on require (idempotent, client-guarded).
SfxController:Init()

return SfxController
