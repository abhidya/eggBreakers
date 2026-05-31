--[[
    NpcHealthThreatController
    Combat feel — NPC health + apex threat UI (client-only, no authority)

    Two diegetic, attribute-driven feedback systems that read SERVER-AUTHORITATIVE
    state (never deciding damage/health themselves):

      1. Overhead NPC health bars on *recently-damaged* NPCs.
         Driven by the model attributes CombatService stamps server-side:
           • Health / MaxHealth   — authoritative current/max HP
           • LastDamagedAt        — os.clock() timestamp of last server hit
         Bars appear when an NPC is freshly damaged, track HP in real time via
         Health attribute changes, and fade out after a quiet period. Also listens
         to the CombatFeedback remote so a bar pops the instant a hit lands.

      2. Apex-threat screen pulse: a full-screen red vignette that pulses while an
         Apex NPC (ApexCategory == true, or an active ApexEventActive event) is
         within threat range of the local player.

      3. Attack telegraph read: listens to the CombatTelegraph remote and gives a
         brief overhead "wind-up" tick on the telegraphing NPC's bar so players can
         read the incoming swing. Purely cosmetic — damage stays server-side.

    Distinct from CombatFeedbackController (which owns floating damage numbers,
    hit-flash, its own bars, and a corner apex ring): this controller is the
    attribute-driven, full-screen-vignette layer and is namespaced ("HT_*") so the
    two never collide. All instances are tracked and cleaned up; no leaks.

    Self-initialises on require in a client context, so it works whether it is
    required by a bootstrap script or stands alone.
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")

local NpcHealthThreatController = {}

-- ── tunables ─────────────────────────────────────────────────────────────────
local BAR_SHOW_AFTER_DAMAGE   = true   -- only show bars on recently-damaged NPCs
local BAR_FADE_DELAY          = 4.0    -- s of no damage before the bar fades
local BAR_FADE_TIME           = 0.5
local BAR_RECENT_DAMAGE_WINDOW = 0.75  -- s — "recently damaged" for initial show
local TELEGRAPH_TICK_TIME     = 0.18   -- s — overhead wind-up flash duration
local THREAT_RADIUS_FALLBACK  = 140    -- studs — used if NPC has no ThreatRadius
local THREAT_POLL_INTERVAL    = 0.4    -- s between apex scans
local VIGNETTE_PULSE_TIME     = 0.65   -- s per pulse half-cycle

-- ── state ────────────────────────────────────────────────────────────────────
local bars            = {}  -- [model] = { billboard, fill, nameLabel, lastDamageAt, fading, conns = {} }
local vignetteGui     = nil
local vignetteFrame   = nil
local _vignetteTween  = nil
local lastThreatPoll  = 0
local _initialized    = false

-- ── helpers ──────────────────────────────────────────────────────────────────

local function getModelRoot(model)
    if not model or not model.Parent then return nil end
    if model:IsA("Model") then
        return model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
    elseif model:IsA("BasePart") then
        return model
    end
    return nil
end

local function isNpc(model)
    return model and model:IsA("Model")
        and (model:GetAttribute("ActiveNPCBrain") == true or model:GetAttribute("NPCKind") ~= nil or model:GetAttribute("SpeciesId") ~= nil)
end

local function readHealth(model)
    local health = model:GetAttribute("Health")
    local maxHealth = model:GetAttribute("MaxHealth")
    if maxHealth == nil or maxHealth <= 0 then maxHealth = health or 1 end
    return tonumber(health) or 0, math.max(tonumber(maxHealth) or 1, 1)
end

local function healthColor(pct)
    if pct > 0.55 then
        return Color3.fromRGB(90, 205, 120)
    elseif pct > 0.25 then
        return Color3.fromRGB(232, 176, 64)
    end
    return Color3.fromRGB(236, 78, 66)
end

-- ── overhead health bars ─────────────────────────────────────────────────────

local function destroyBar(model)
    local record = bars[model]
    if not record then return end
    for _, conn in ipairs(record.conns) do
        pcall(function() conn:Disconnect() end)
    end
    if record.billboard and record.billboard.Parent then
        record.billboard:Destroy()
    end
    bars[model] = nil
end

local function refreshBarValues(model)
    local record = bars[model]
    if not record then return end
    local health, maxHealth = readHealth(model)
    local pct = math.clamp(health / maxHealth, 0, 1)

    TweenService:Create(
        record.fill,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad),
        { Size = UDim2.fromScale(pct, 1) }
    ):Play()
    record.fill.BackgroundColor3 = healthColor(pct)

    if model:GetAttribute("ApexCategory") == true then
        record.nameLabel.TextColor3 = Color3.fromRGB(255, 120, 110)
        record.nameLabel.Text = "⚠ " .. model.Name
    else
        record.nameLabel.Text = model.Name
    end
end

local function ensureBar(model)
    if bars[model] then return bars[model] end
    if not isNpc(model) then return nil end
    local root = getModelRoot(model)
    if not root then return nil end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "HT_NpcHealthBar"
    billboard.Adornee = root
    billboard.StudsOffset = Vector3.new(0, 5.25, 0)
    billboard.Size = UDim2.fromOffset(150, 30)
    billboard.MaxDistance = 120
    billboard.AlwaysOnTop = false
    billboard.LightInfluence = 0
    billboard.Parent = root

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.fromScale(1, 0.42)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.4
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = model.Name
    nameLabel.Parent = billboard

    local bg = Instance.new("Frame")
    bg.Name = "Track"
    bg.AnchorPoint = Vector2.new(0.5, 1)
    bg.Position = UDim2.fromScale(0.5, 1)
    bg.Size = UDim2.fromScale(1, 0.5)
    bg.BackgroundColor3 = Color3.fromRGB(24, 10, 10)
    bg.BackgroundTransparency = 0.15
    bg.BorderSizePixel = 0
    bg.Parent = billboard

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 3)
    bgCorner.Parent = bg

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = Color3.fromRGB(90, 205, 120)
    fill.BorderSizePixel = 0
    fill.Parent = bg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = fill

    -- Telegraph tick: thin amber bar that flashes on wind-up.
    local tick = Instance.new("Frame")
    tick.Name = "TelegraphTick"
    tick.AnchorPoint = Vector2.new(0.5, 0)
    tick.Position = UDim2.fromScale(0.5, 0)
    tick.Size = UDim2.fromScale(0, 0.12)
    tick.BackgroundColor3 = Color3.fromRGB(255, 196, 64)
    tick.BorderSizePixel = 0
    tick.BackgroundTransparency = 1
    tick.Parent = billboard

    local record = {
        billboard    = billboard,
        fill         = fill,
        tick         = tick,
        nameLabel    = nameLabel,
        lastDamageAt = os.clock(),
        fading       = false,
        conns        = {},
    }
    bars[model] = record

    -- Live HP tracking from the authoritative attribute.
    table.insert(record.conns, model:GetAttributeChangedSignal("Health"):Connect(function()
        record.lastDamageAt = os.clock()
        record.fading = false
        billboard.Enabled = true
        refreshBarValues(model)
    end))

    -- Cleanup when the NPC leaves the world.
    table.insert(record.conns, model.AncestryChanged:Connect(function()
        if not model.Parent then destroyBar(model) end
    end))

    refreshBarValues(model)
    return record
end

local function bumpBar(model)
    local record = ensureBar(model)
    if not record then return end
    record.lastDamageAt = os.clock()
    record.fading = false
    record.billboard.Enabled = true
    refreshBarValues(model)
end

local function playTelegraphTick(model)
    local record = ensureBar(model)
    if not record or not record.tick then return end
    local tick = record.tick
    tick.BackgroundTransparency = 0.05
    TweenService:Create(tick, TweenInfo.new(0.08, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(1, 0.12) }):Play()
    task.delay(TELEGRAPH_TICK_TIME, function()
        if tick and tick.Parent then
            TweenService:Create(tick, TweenInfo.new(0.12), { BackgroundTransparency = 1, Size = UDim2.fromScale(0, 0.12) }):Play()
        end
    end)
end

-- ── apex threat vignette ─────────────────────────────────────────────────────

local function ensureVignette()
    if vignetteGui then return end
    local player = Players.LocalPlayer
    if not player then return end
    local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 10)
    if not playerGui then return end

    vignetteGui = Instance.new("ScreenGui")
    vignetteGui.Name = "HT_ApexThreatVignette"
    vignetteGui.ResetOnSpawn = false
    vignetteGui.IgnoreGuiInset = true
    vignetteGui.DisplayOrder = -5  -- behind HUD
    vignetteGui.Enabled = false
    vignetteGui.Parent = playerGui

    vignetteFrame = Instance.new("ImageLabel")
    vignetteFrame.Name = "Vignette"
    vignetteFrame.BackgroundTransparency = 1
    vignetteFrame.Size = UDim2.fromScale(1, 1)
    -- Radial gradient asset (built-in studio gradient); falls back to a tinted edge.
    vignetteFrame.Image = "rbxassetid://5028857084"
    vignetteFrame.ScaleType = Enum.ScaleType.Stretch
    vignetteFrame.ImageColor3 = Color3.fromRGB(180, 24, 18)
    vignetteFrame.ImageTransparency = 0.6
    vignetteFrame.Active = false
    vignetteFrame.Parent = vignetteGui
end

local function setThreat(active)
    ensureVignette()
    if not vignetteGui then return end
    if active then
        vignetteGui.Enabled = true
        if not _vignetteTween or _vignetteTween.PlaybackState ~= Enum.PlaybackState.Playing then
            local ti = TweenInfo.new(VIGNETTE_PULSE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
            _vignetteTween = TweenService:Create(vignetteFrame, ti, { ImageTransparency = 0.35 })
            _vignetteTween:Play()
        end
    else
        if _vignetteTween then
            _vignetteTween:Cancel()
            _vignetteTween = nil
        end
        if vignetteFrame then vignetteFrame.ImageTransparency = 0.6 end
        vignetteGui.Enabled = false
    end
end

local function scanForApex()
    local player = Players.LocalPlayer
    local character = player and player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then setThreat(false) return end
    local playerPos = root.Position

    local foundApex = false
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model")
            and (obj:GetAttribute("ApexCategory") == true or obj:GetAttribute("ApexEventActive") == true)
            and obj:GetAttribute("Dead") ~= true then
            local nRoot = getModelRoot(obj)
            if nRoot then
                local radius = tonumber(obj:GetAttribute("ThreatRadius")) or THREAT_RADIUS_FALLBACK
                if (nRoot.Position - playerPos).Magnitude <= radius then
                    foundApex = true
                    break
                end
            end
        end
    end
    setThreat(foundApex)
end

-- ── per-frame upkeep ─────────────────────────────────────────────────────────

local function onHeartbeat()
    local now = os.clock()

    for model, record in pairs(bars) do
        if not model.Parent then
            destroyBar(model)
        else
            local recentlyDamaged = (now - record.lastDamageAt) <= BAR_RECENT_DAMAGE_WINDOW
            if BAR_SHOW_AFTER_DAMAGE and not record.fading then
                if (now - record.lastDamageAt) > BAR_FADE_DELAY then
                    record.fading = true
                    local tween = TweenService:Create(
                        record.billboard,
                        TweenInfo.new(BAR_FADE_TIME, Enum.EasingStyle.Quad),
                        { GroupTransparency = 1 }
                    )
                    tween.Completed:Connect(function(state)
                        if state == Enum.PlaybackState.Completed and record.fading then
                            destroyBar(model)
                        end
                    end)
                    tween:Play()
                end
            end
            if recentlyDamaged and record.billboard then
                record.billboard.GroupTransparency = 0
            end
        end
    end

    if (now - lastThreatPoll) >= THREAT_POLL_INTERVAL then
        lastThreatPoll = now
        scanForApex()
    end
end

-- ── remote handlers ──────────────────────────────────────────────────────────

local function findModelByName(name)
    if not name or name == "" then return nil end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == name and isNpc(obj) then
            return obj
        end
    end
    return nil
end

local function onCombatFeedback(payload)
    if type(payload) ~= "table" then return end
    if payload.kind == "telegraph" then return end  -- handled via CombatTelegraph
    local model = findModelByName(payload.targetName)
    if model then bumpBar(model) end
end

local function onTelegraph(payload)
    if type(payload) ~= "table" then return end
    local model = findModelByName(payload.targetName)
    if model then playTelegraphTick(model) end
end

-- ── init ─────────────────────────────────────────────────────────────────────

function NpcHealthThreatController:Init()
    if _initialized then return true end
    if not RunService:IsClient() then return false end
    _initialized = true

    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if remotes then
        local feedback = remotes:FindFirstChild("CombatFeedback") or remotes:WaitForChild("CombatFeedback", 10)
        if feedback then
            feedback.OnClientEvent:Connect(onCombatFeedback)
        end
        local telegraph = remotes:FindFirstChild("CombatTelegraph") or remotes:WaitForChild("CombatTelegraph", 10)
        if telegraph then
            telegraph.OnClientEvent:Connect(onTelegraph)
        end
    end

    RunService.Heartbeat:Connect(onHeartbeat)
    ensureVignette()
    return true
end

-- Self-initialise when required on the client. Guarded so requiring this module
-- on the server (e.g. in headless tests) is a harmless no-op.
if RunService:IsClient() then
    task.spawn(function()
        NpcHealthThreatController:Init()
    end)
end

return NpcHealthThreatController
