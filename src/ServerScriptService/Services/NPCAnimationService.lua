-- NPCAnimationService.lua
-- Drives Humanoid Animator tracks for NPCs based on the NPCState attribute.
-- Animation IDs are sourced from SpeciesConfig.AnimationIds (salvaged from imported dino pack;
-- per-rig validation required before final shipping).
--
-- State → track mapping:
--   Idle, HatchAtNest, Eat, Drink, Hide  → Idle track
--   Wander, Herd, SeekFood, SeekWater    → Walk track  (speed-blended with WalkSpeed)
--   Chase, Flee                           → Run  track  (speed-blended with SprintSpeed)
--   Attack                               → Attack track
--   Dead                                 → stops all tracks

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)

-- ──────────────────────────────────────────────────────────────
-- Internal state per NPC instance
-- ──────────────────────────────────────────────────────────────
local NPCAnimationService = {}
NPCAnimationService._tracked = {}  -- [npc instance] = { animator, tracks = {}, currentKey }

-- ──────────────────────────────────────────────────────────────
-- Helper: resolve state → animation key
-- ──────────────────────────────────────────────────────────────
local STATE_TO_KEY = {
    Idle        = "Idle",
    HatchAtNest = "Idle",
    Eat         = "Eat",
    Drink       = "Drink",
    Hide        = "Idle",
    Wander      = "Walk",
    Herd        = "Walk",
    SeekFood    = "Walk",
    SeekWater   = "Walk",
    Chase       = "Run",
    Flee        = "Run",
    Attack      = "Attack",
    Dead        = "Dead",
    Despawn     = "Dead",
    ApexEvent   = "Idle",
}

-- Speed multipliers per key for blending (applied to AnimationTrack.Speed)
local KEY_SPEED_SCALE = {
    Walk = 1.0,
    Run  = 1.4,
}

-- ──────────────────────────────────────────────────────────────
-- Internal: load animation tracks for an NPC
-- ──────────────────────────────────────────────────────────────
local function loadTracksForNPC(npc, speciesId)
    local humanoid = npc:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return nil end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    local animIds = SpeciesConfig[speciesId] and SpeciesConfig[speciesId].AnimationIds or {}
    local tracks = {}

    for key, id in pairs(animIds) do
        if type(id) == "string" and id ~= "" then
            local anim = Instance.new("Animation")
            anim.AnimationId = id
            local ok, track = pcall(function()
                return animator:LoadAnimation(anim)
            end)
            anim:Destroy()  -- animation object not needed after load
            if ok and track then
                tracks[key] = track
            end
        end
    end

    return {
        animator    = animator,
        tracks      = tracks,
        currentKey  = nil,
    }
end

-- ──────────────────────────────────────────────────────────────
-- Internal: play a keyed track, stop others
-- ──────────────────────────────────────────────────────────────
local function applyKey(entry, key, speedScale)
    if entry.currentKey == key then return end

    -- Stop all running tracks
    for k, track in pairs(entry.tracks) do
        if track.IsPlaying and k ~= key then
            track:Stop(0.2)
        end
    end

    if key == "Dead" then
        -- Stop everything for dead state
        for _, track in pairs(entry.tracks) do
            if track.IsPlaying then track:Stop(0.15) end
        end
        entry.currentKey = key
        return
    end

    local track = entry.tracks[key]
    if track then
        if not track.IsPlaying then
            track:Play(0.2)
        end
        -- Speed blend
        local scale = speedScale or KEY_SPEED_SCALE[key] or 1.0
        track:AdjustSpeed(scale)
    end
    entry.currentKey = key
end

-- ──────────────────────────────────────────────────────────────
-- Public: Register an NPC for animation tracking
-- ──────────────────────────────────────────────────────────────
function NPCAnimationService:Register(npcInstance, speciesId)
    if not npcInstance or not speciesId then return false, "missing_args" end
    if NPCAnimationService._tracked[npcInstance] then
        return true, "already_registered"
    end

    local entry = loadTracksForNPC(npcInstance, speciesId)
    if not entry then return false, "no_humanoid" end

    NPCAnimationService._tracked[npcInstance] = entry
    return true
end

-- ──────────────────────────────────────────────────────────────
-- Public: Unregister (cleanup on despawn)
-- ──────────────────────────────────────────────────────────────
function NPCAnimationService:Unregister(npcInstance)
    local entry = NPCAnimationService._tracked[npcInstance]
    if not entry then return false, "not_registered" end
    for _, track in pairs(entry.tracks) do
        if track.IsPlaying then track:Stop(0) end
    end
    NPCAnimationService._tracked[npcInstance] = nil
    return true
end

-- ──────────────────────────────────────────────────────────────
-- Public: Update animation for one NPC record (call from NPCService brain tick)
-- ──────────────────────────────────────────────────────────────
function NPCAnimationService:UpdateRecord(record)
    if not record or not record.Instance then return false, "missing_record" end
    local npc = record.Instance
    local entry = NPCAnimationService._tracked[npc]
    if not entry then
        -- Auto-register lazily if Humanoid exists
        local ok = NPCAnimationService:Register(npc, record.SpeciesId or "")
        if not ok then return false, "no_humanoid" end
        entry = NPCAnimationService._tracked[npc]
        if not entry then return false, "register_failed" end
    end

    local state = record.State or "Idle"
    local key = STATE_TO_KEY[state] or "Idle"

    -- Speed-blend Walk/Run based on Humanoid velocity magnitude vs config
    local speedScale = KEY_SPEED_SCALE[key] or 1.0
    local humanoid = npc:FindFirstChildWhichIsA("Humanoid")
    if humanoid and (key == "Walk" or key == "Run") then
        local vel = humanoid.RootPart and humanoid.RootPart.AssemblyLinearVelocity
        if vel then
            local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
            local refSpeed = (key == "Run") and (humanoid.WalkSpeed * 1.4) or humanoid.WalkSpeed
            if refSpeed > 0 then
                speedScale = math.clamp(speed / refSpeed, 0.5, 2.0)
            end
        end
    end

    applyKey(entry, key, speedScale)
    return true
end

-- ──────────────────────────────────────────────────────────────
-- Public: Start a heartbeat loop that drives all registered NPCs
-- (alternative to per-tick calls from NPCService)
-- ──────────────────────────────────────────────────────────────
function NPCAnimationService:StartHeartbeatLoop(npcService)
    if self._heartbeatStarted then return false, "already_started" end
    self._heartbeatStarted = true
    task.spawn(function()
        while self._heartbeatStarted do
            RunService.Heartbeat:Wait()
            if npcService and npcService.NPCs then
                for _, record in ipairs(npcService.NPCs) do
                    NPCAnimationService:UpdateRecord(record)
                end
            end
        end
    end)
    return true
end

function NPCAnimationService:StopHeartbeatLoop()
    self._heartbeatStarted = false
end

return NPCAnimationService
