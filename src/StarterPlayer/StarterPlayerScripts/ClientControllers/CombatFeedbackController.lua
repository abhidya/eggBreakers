--[[
    CombatFeedbackController
    WS-E (BR-09) — Lane C

    Listens for CombatFeedback remote events fired by CombatService and renders:
      • Floating damage numbers (world-space BillboardGui) at the target
      • Brief hit-flash on the target's parts
      • Overhead NPC health bar that drains in real-time and fades when full
      • Crit hits render larger / yellow
      • Threat indicator that pulses when a nearby NPC has ApexEventActive

    All UI instances are tracked and cleaned up; no leaks.
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

local CombatFeedbackController = {}

-- ── constants ──────────────────────────────────────────────────────────────
local DAMAGE_NUMBER_LIFETIME   = 1.8   -- seconds before damage label vanishes
local DAMAGE_FLOAT_SPEED       = 4     -- studs/sec upward drift
local HIT_FLASH_DURATION       = 0.12  -- seconds the flash lasts per hit
local HEALTH_BAR_FADE_DELAY    = 3.5   -- seconds of inactivity before bar fades
local HEALTH_BAR_FADE_TIME     = 0.6
local THREAT_PULSE_RADIUS      = 60    -- studs — NPCs within this range checked
local THREAT_POLL_INTERVAL     = 0.5   -- seconds between threat scans
local CRIT_SCALE               = 1.65  -- multiplier on label TextSize for crits

-- ── state ──────────────────────────────────────────────────────────────────
local activeHealthBars  = {}   -- [model] = { bar=Frame, bg=Frame, label=TextLabel, lastHit=tick() }
local activeDamageNums  = {}   -- list of { label=BillboardGui, pos=Vector3, spawnTime=tick() }
local flashConnections  = {}   -- [model] = { original colors, restore connection }
local threatGui         = nil
local threatLabel       = nil
local lastThreatPoll    = 0

-- ── helpers ────────────────────────────────────────────────────────────────

local function getModelRoot(model)
    if model:IsA("Model") then
        return model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
    elseif model:IsA("BasePart") then
        return model
    end
    return nil
end

-- Returns a world-space position slightly above the target
local function aboveTarget(model, studsUp)
    local root = getModelRoot(model)
    if root then
        return root.Position + Vector3.new(0, studsUp or 5, 0)
    end
    return Vector3.new(0, studsUp or 5, 0)
end

-- ── floating damage numbers ────────────────────────────────────────────────

local function spawnDamageNumber(position, damage, isCrit)
    local bb = Instance.new("BillboardGui")
    bb.Name = "DamageNumber"
    bb.StudsOffset = Vector3.new(0, 0, 0)
    bb.AlwaysOnTop = false
    bb.Size = UDim2.fromOffset(isCrit and 120 or 80, isCrit and 56 or 36)
    bb.LightInfluence = 0

    -- Anchor to a small, invisible part at the hit position
    local anchor = Instance.new("Part")
    anchor.Name = "_DmgAnchor"
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.Transparency = 1
    anchor.Size = Vector3.new(0.05, 0.05, 0.05)
    anchor.Position = position
    anchor.Parent = Workspace

    bb.Adornee = anchor
    bb.Parent = anchor

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Text = isCrit and ("★ " .. tostring(damage) .. "!") or ("-" .. tostring(damage))
    label.TextColor3 = isCrit and Color3.fromRGB(255, 220, 40) or Color3.fromRGB(255, 80, 80)
    label.TextStrokeTransparency = 0.2
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Parent = bb

    table.insert(activeDamageNums, {
        anchor    = anchor,
        label     = label,
        spawnTime = tick(),
        position  = position,
    })
end

-- ── hit flash ──────────────────────────────────────────────────────────────

local function flashTarget(model)
    -- Collect BaseParts; save original colors; tween to white then back
    local parts = {}
    local origColors = {}
    local function collect(inst)
        for _, child in ipairs(inst:GetChildren()) do
            if child:IsA("BasePart") then
                table.insert(parts, child)
                origColors[child] = child.Color
            end
            collect(child)
        end
    end
    if model:IsA("Model") then
        collect(model)
    elseif model:IsA("BasePart") then
        table.insert(parts, model)
        origColors[model] = model.Color
    end

    local flashColor = Color3.fromRGB(255, 255, 255)
    for _, part in ipairs(parts) do
        part.Color = flashColor
    end

    task.delay(HIT_FLASH_DURATION, function()
        for _, part in ipairs(parts) do
            if part and part.Parent then
                part.Color = origColors[part] or part.Color
            end
        end
    end)
end

-- ── overhead NPC health bar ────────────────────────────────────────────────

local function ensureHealthBar(model)
    if activeHealthBars[model] then return activeHealthBars[model] end

    local root = getModelRoot(model)
    if not root then return nil end

    local bb = Instance.new("BillboardGui")
    bb.Name = "NPCHealthBar"
    bb.Adornee = root
    bb.StudsOffset = Vector3.new(0, 4.5, 0)
    bb.Size = UDim2.fromOffset(140, 26)
    bb.AlwaysOnTop = false
    bb.LightInfluence = 0
    bb.Parent = root

    -- Background
    local bg = Instance.new("Frame")
    bg.Name = "BG"
    bg.Size = UDim2.fromScale(1, 0.55)
    bg.Position = UDim2.fromScale(0, 0.22)
    bg.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
    bg.BorderSizePixel = 0
    bg.Parent = bb

    -- Fill
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = Color3.fromRGB(210, 50, 50)
    fill.BorderSizePixel = 0
    fill.Parent = bg

    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.fromScale(1, 0.38)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = model.Name
    nameLabel.Parent = bb

    local record = {
        billboard = bb,
        fill      = fill,
        lastHit   = tick(),
        fading    = false,
    }
    activeHealthBars[model] = record

    -- Clean up if model is removed
    model.AncestryChanged:Connect(function()
        if not model.Parent then
            if bb and bb.Parent then bb:Destroy() end
            activeHealthBars[model] = nil
        end
    end)

    return record
end

local function updateHealthBar(model, targetHealth, targetMaxHealth)
    local record = ensureHealthBar(model)
    if not record then return end
    record.lastHit = tick()
    record.fading  = false

    local pct = math.clamp((targetHealth or 0) / math.max(targetMaxHealth or 1, 1), 0, 1)

    -- Tween the fill width
    local fillGoal = { Size = UDim2.fromScale(pct, 1) }
    TweenService:Create(record.fill, TweenInfo.new(0.25, Enum.EasingStyle.Quad), fillGoal):Play()

    -- Color: green → yellow → red
    local color
    if pct > 0.55 then
        color = Color3.fromRGB(82, 200, 120)
    elseif pct > 0.25 then
        color = Color3.fromRGB(230, 170, 60)
    else
        color = Color3.fromRGB(235, 75, 65)
    end
    record.fill.BackgroundColor3 = color

    -- Ensure visible
    record.billboard.GroupTransparency = 0
end

-- ── threat indicator ───────────────────────────────────────────────────────

local function ensureThreatGui()
    if threatGui then return end
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    threatGui = Instance.new("ScreenGui")
    threatGui.Name = "ThreatIndicatorGui"
    threatGui.ResetOnSpawn = false
    threatGui.IgnoreGuiInset = true
    threatGui.Enabled = false
    threatGui.Parent = playerGui

    -- Pulsing ring in the top-right corner
    local frame = Instance.new("Frame")
    frame.Name = "ThreatFrame"
    frame.Size = UDim2.fromOffset(90, 90)
    frame.Position = UDim2.new(1, -100, 0, 10)
    frame.BackgroundTransparency = 1
    frame.Parent = threatGui

    local circle = Instance.new("Frame")
    circle.Name = "Circle"
    circle.Size = UDim2.fromScale(1, 1)
    circle.BackgroundColor3 = Color3.fromRGB(220, 50, 30)
    circle.BackgroundTransparency = 0.3
    circle.BorderSizePixel = 0
    local uic = Instance.new("UICorner")
    uic.CornerRadius = UDim.new(0.5, 0)
    uic.Parent = circle
    circle.Parent = frame

    threatLabel = Instance.new("TextLabel")
    threatLabel.Size = UDim2.fromScale(1, 1)
    threatLabel.BackgroundTransparency = 1
    threatLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    threatLabel.TextScaled = true
    threatLabel.Font = Enum.Font.GothamBold
    threatLabel.Text = "⚠ APEX"
    threatLabel.Parent = frame
end

local _threatPulseTween = nil

local function showThreat(active)
    ensureThreatGui()
    if active then
        threatGui.Enabled = true
        if not _threatPulseTween or _threatPulseTween.PlaybackState ~= Enum.PlaybackState.Playing then
            local circle = threatGui.ThreatFrame.Circle
            local ti = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
            _threatPulseTween = TweenService:Create(circle, ti, { BackgroundTransparency = 0.75 })
            _threatPulseTween:Play()
        end
    else
        if _threatPulseTween then
            _threatPulseTween:Cancel()
            _threatPulseTween = nil
        end
        threatGui.Enabled = false
    end
end

local function scanForThreats()
    local player = Players.LocalPlayer
    local character = player.Character
    if not character then showThreat(false) return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then showThreat(false) return end

    local playerPos = root.Position
    local foundApex = false

    -- Walk Workspace looking for tagged NPC instances with ApexEventActive
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:GetAttribute("ApexEventActive") == true then
            local nRoot = getModelRoot(obj)
            if nRoot and (nRoot.Position - playerPos).Magnitude <= THREAT_PULSE_RADIUS then
                foundApex = true
                break
            end
        end
    end

    showThreat(foundApex)
end

-- ── RunService heartbeat (float damage numbers, fade health bars, threat poll)
local function onHeartbeat(dt)
    local now = tick()

    -- Float and expire damage numbers
    local surviving = {}
    for _, entry in ipairs(activeDamageNums) do
        local age = now - entry.spawnTime
        if age < DAMAGE_NUMBER_LIFETIME then
            if entry.anchor and entry.anchor.Parent then
                entry.anchor.Position = entry.anchor.Position + Vector3.new(0, DAMAGE_FLOAT_SPEED * dt, 0)
                -- Fade out in last 40% of lifetime
                local fadeStart = DAMAGE_NUMBER_LIFETIME * 0.6
                if age > fadeStart then
                    local alpha = (age - fadeStart) / (DAMAGE_NUMBER_LIFETIME - fadeStart)
                    entry.label.TextTransparency = math.clamp(alpha, 0, 1)
                    entry.label.TextStrokeTransparency = math.clamp(0.2 + alpha * 0.8, 0.2, 1)
                end
            end
            table.insert(surviving, entry)
        else
            -- Cleanup
            if entry.anchor and entry.anchor.Parent then
                entry.anchor:Destroy()
            end
        end
    end
    activeDamageNums = surviving

    -- Fade health bars that haven't been hit recently
    for model, record in pairs(activeHealthBars) do
        if not record.fading and (now - record.lastHit) > HEALTH_BAR_FADE_DELAY then
            record.fading = true
            TweenService:Create(
                record.billboard,
                TweenInfo.new(HEALTH_BAR_FADE_TIME, Enum.EasingStyle.Quad),
                { GroupTransparency = 1 }
            ):Play()
        end
    end

    -- Threat poll (throttled)
    if (now - lastThreatPoll) >= THREAT_POLL_INTERVAL then
        lastThreatPoll = now
        scanForThreats()
    end
end

-- ── main event handler ─────────────────────────────────────────────────────

local function onCombatFeedback(payload)
    if type(payload) ~= "table" then return end

    local position      = payload.position      or Vector3.new(0, 0, 0)
    local damage        = payload.damage        or 0
    local targetHealth  = payload.targetHealth  or 0
    local targetMaxHealth = payload.targetMaxHealth or 100
    local isCrit        = payload.isCrit        == true
    local targetName    = payload.targetName    or ""

    -- Spawn floating damage number slightly above the hit position
    spawnDamageNumber(position + Vector3.new(0, 3, 0), damage, isCrit)

    -- Find the model in Workspace for flash / health bar (best-effort by name)
    local targetModel = nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == targetName then
            targetModel = obj
            break
        end
    end

    if targetModel then
        flashTarget(targetModel)
        updateHealthBar(targetModel, targetHealth, targetMaxHealth)
    end
end

-- ── init ───────────────────────────────────────────────────────────────────

function CombatFeedbackController:Init()
    if not Remotes then return end
    local remote = Remotes:WaitForChild("CombatFeedback", 10)
    if not remote then return end

    remote.OnClientEvent:Connect(onCombatFeedback)
    RunService.Heartbeat:Connect(onHeartbeat)

    -- Ensure threat GUI is ready
    ensureThreatGui()
end

return CombatFeedbackController
