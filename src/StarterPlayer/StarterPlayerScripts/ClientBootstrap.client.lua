local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local controllers = script.Parent:WaitForChild("ClientControllers")
local HUDController = require(controllers:WaitForChild("HUDController"))
local HatchUIController = require(controllers:WaitForChild("HatchUIController"))
local InputController = require(controllers:WaitForChild("InputController"))
local MobileControlsController = require(controllers:WaitForChild("MobileControlsController"))
local ActionGuidanceController = require(controllers:WaitForChild("ActionGuidanceController"))
local SenseGuideController = require(controllers:WaitForChild("SenseGuideController"))
local SfxController = require(controllers:WaitForChild("SfxController"))
local NpcHealthThreatController = require(controllers:WaitForChild("NpcHealthThreatController"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Constants = require(ReplicatedStorage.Shared.Constants)
local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)
local player = Players.LocalPlayer

local ClientBootstrap = {}
ClientBootstrap.LastStats = nil
ClientBootstrap.RestHidden = false
ClientBootstrap.Sprinting = false
ClientBootstrap.MotionPlaying = false
ClientBootstrap.LastTargetScanAt = 0
ClientBootstrap.TargetScanSeconds = 0.5
ClientBootstrap.SenseTargetDistance = 80
ClientBootstrap.ActionTargetDistance = 14

local function getTargetPosition(target)
    if not target or not target:IsDescendantOf(workspace) then return nil end
    if target:IsA("BasePart") then return target.Position end
    if target.GetPivot then return target:GetPivot().Position end
    return nil
end

local function distanceToRoot(root, target)
    local targetPosition = getTargetPosition(target)
    if not root or not targetPosition then return nil end
    return (root.Position - targetPosition).Magnitude
end

function ClientBootstrap:DescribeTarget(target)
    if not target then return "None", "none" end
    local display = target:GetAttribute("InteractionHint") or target:GetAttribute("DisplayName") or target.Name
    if CollectionService:HasTag(target, Constants.Tags.FoodSource) then
        local diet = target:GetAttribute("Diet") or "Food"
        return tostring(display), tostring(diet)
    end
    if CollectionService:HasTag(target, Constants.Tags.WaterSource) or target:GetAttribute("WaterSource") then
        return tostring(display), "Water"
    end
    return tostring(display), "Target"
end

function ClientBootstrap:IsFoodAllowedForDiet(target, diet)
    if not target or not CollectionService:HasTag(target, Constants.Tags.FoodSource) then return false end
    local foodDiet = tostring(target:GetAttribute("Diet") or "")
    if diet == "Omnivore" then return true end
    if foodDiet == diet then return true end
    if diet == "Herbivore" and target:GetAttribute("TreeBrowse") == true then return true end
    return false
end

function ClientBootstrap:FindNearestEatDrinkTarget(maxDistance, preferredMode)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local bestTarget = nil
    local bestDistance = maxDistance or 14
    local bestType = nil
    local diet = self.LastStats and self.LastStats.diet
    local function consider(target, targetType)
        if target:GetAttribute("Depleted") == true then return end
        if target:GetAttribute("ActiveNPCBrain") == true or target:GetAttribute("NPCId") then return end
        if targetType == "Food" and not self:IsFoodAllowedForDiet(target, diet) then return end
        if preferredMode == "Food" and targetType ~= "Food" then return end
        if preferredMode == "Water" and targetType ~= "Water" then return end
        local distance = distanceToRoot(root, target)
        if distance and distance <= bestDistance then
            bestTarget = target
            bestDistance = distance
            bestType = targetType
        end
    end

    for _, target in ipairs(CollectionService:GetTagged(Constants.Tags.FoodSource)) do
        consider(target, "Food")
    end
    for _, target in ipairs(CollectionService:GetTagged(Constants.Tags.WaterSource)) do
        consider(target, "Water")
    end
    return bestTarget, bestType, bestDistance
end

function ClientBootstrap:FindNearestTagged(tag, maxDistance)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local bestTarget = nil
    local bestDistance = maxDistance or 12
    for _, target in ipairs(CollectionService:GetTagged(tag)) do
        local distance = distanceToRoot(root, target)
        if distance and distance <= bestDistance then
            bestTarget = target
            bestDistance = distance
        end
    end
    return bestTarget
end

function ClientBootstrap:GetPrimaryAttack()
    local speciesId = self.LastStats and self.LastStats.species or Constants.DefaultSpeciesId
    local species = SpeciesConfig[speciesId] or SpeciesConfig[Constants.DefaultSpeciesId]
    return (species and species.Abilities and species.Abilities.PrimaryAttack) or "Nibble"
end

function ClientBootstrap:GetHumanoid()
    local character = player.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

function ClientBootstrap:SetButtonText(button, text)
    if button and button:IsA("TextButton") then
        button.Text = text
    end
end

function ClientBootstrap:ShowActionFeedback(gui, message, button)
    local label = gui and gui:FindFirstChild("ActionFeedbackLabel")
    if not label then return false end
    label.Text = message
    label.Visible = true
    label:SetAttribute("LastFeedback", message)
    if button then
        button:SetAttribute("LastActionResult", message)
    end
    return true
end

function ClientBootstrap:UpdateActionGuidance(gui)
    return ActionGuidanceController:Update(gui, self)
end

function ClientBootstrap:CreateLocalCallPulse(callType)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local pulse = Instance.new("Part")
    pulse.Name = "LocalCallPulse"
    pulse.Shape = Enum.PartType.Ball
    pulse.Anchored = true
    pulse.CanCollide = false
    pulse.CanTouch = false
    pulse.CanQuery = false
    pulse.Material = Enum.Material.Neon
    pulse.Color = Color3.fromRGB(120, 210, 255)
    pulse.Transparency = 0.45
    pulse.Size = Vector3.new(8, 8, 8)
    pulse.CFrame = root.CFrame
    pulse:SetAttribute("CallType", callType)
    pulse:SetAttribute("VisibleActionEffect", true)
    pulse.Parent = workspace
    Debris:AddItem(pulse, 1.25)
    return pulse
end

function ClientBootstrap:ApplyHiddenVisual(isHidden)
    local character = player.Character
    if not character then return end
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.LocalTransparencyModifier = isHidden and 0.35 or 0
        end
    end
end

function ClientBootstrap:FaceActionTarget(target)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local targetPosition = getTargetPosition(target)
    if not root or not targetPosition then return false end
    local lookAt = Vector3.new(targetPosition.X, root.Position.Y, targetPosition.Z)
    if (lookAt - root.Position).Magnitude <= 0.05 then return false, "target_too_close" end
    root.CFrame = CFrame.lookAt(root.Position, lookAt)
    root:SetAttribute("LastActionTarget", target.Name)
    root:SetAttribute("LastActionTargetPosition", string.format("%.1f,%.1f,%.1f", targetPosition.X, targetPosition.Y, targetPosition.Z))
    return true
end

function ClientBootstrap:PlayActionMotion(actionName, target)
    if self.MotionPlaying then return false end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    if target then
        self:FaceActionTarget(target)
    end
    self.MotionPlaying = true
    local original = root.CFrame
    local forward = original.LookVector
    local target = original
    if actionName == "Eat" or actionName == "Drink" then
        target = original * CFrame.new(0, -0.35, -0.8) * CFrame.Angles(math.rad(-10), 0, 0)
    elseif actionName == "Attack" then
        target = original + forward * 2.5
    elseif actionName == "Call" then
        target = original * CFrame.new(0, 0.45, 0) * CFrame.Angles(math.rad(5), 0, 0)
    elseif actionName == "Hide" then
        target = original * CFrame.new(0, -0.25, 0)
    end
    local out = TweenService:Create(root, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = target })
    local back = TweenService:Create(root, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = original })
    out:Play()
    out.Completed:Connect(function()
        back:Play()
    end)
    back.Completed:Connect(function()
        ClientBootstrap.MotionPlaying = false
    end)
    return true
end

ClientBootstrap.Controllers = {
    HUDController = HUDController,
    HatchUIController = HatchUIController,
    InputController = InputController,
    MobileControlsController = MobileControlsController,
    SenseGuideController = SenseGuideController,
    SfxController = SfxController,
    NpcHealthThreatController = NpcHealthThreatController,
}

local DEFAULT_WALK_SPEED = 16
local SPRINT_WALK_SPEED = 24
local HIDE_TRANSPARENCY = 0.55

local function getHumanoid()
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

local function getCharacterRoot()
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

local function showFeedback(gui, message, button)
    ClientBootstrap:ShowActionFeedback(gui, message, button)
end

local function markButtonPressed(button, resultText)
    if not button then return end
    local now = os.clock()
    local cooldown = button:GetAttribute("CooldownSeconds") or 0.2
    button:SetAttribute("LastPressedAt", now)
    button:SetAttribute("CooldownUntil", now + cooldown)
    button:SetAttribute("PressCount", (button:GetAttribute("PressCount") or 0) + 1)
    button:SetAttribute("LastActionResult", resultText)
end

local function setButtonContext(button, context, enabled, hideWhenUnavailable)
    if not button then return end
    local isEnabled = enabled ~= false
    button:SetAttribute("Context", context)
    button:SetAttribute("ContextEnabled", isEnabled)
    button:SetAttribute("HiddenWhenUnavailable", hideWhenUnavailable == true)
    button.AutoButtonColor = isEnabled
    button.Active = isEnabled
    if hideWhenUnavailable then
        button.Visible = isEnabled
        button.BackgroundTransparency = 0
    else
        button.BackgroundTransparency = isEnabled and 0 or 0.2
    end
end

local function setButtonActive(button, isActive)
    if not button then return end
    button:SetAttribute("Active", isActive)
    button.BackgroundColor3 = isActive and Color3.fromRGB(56, 126, 68) or Color3.fromRGB(35, 45, 35)
end

local function applyHiddenVisual(isHidden)
    local character = player.Character
    if not character then return end
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.LocalTransparencyModifier = isHidden and HIDE_TRANSPARENCY or 0
        end
    end
end

local function createLocalCallPulse(callType)
    local root = getCharacterRoot()
    if not root then return nil end
    local pulse = Instance.new("Part")
    pulse.Name = "LocalCallPulse"
    pulse.Shape = Enum.PartType.Ball
    pulse.Anchored = true
    pulse.CanCollide = false
    pulse.CanTouch = false
    pulse.CanQuery = false
    pulse.Material = Enum.Material.Neon
    pulse.Color = Color3.fromRGB(120, 210, 255)
    pulse.Transparency = 0.45
    pulse.Size = Vector3.new(8, 8, 8)
    pulse.CFrame = root.CFrame
    pulse:SetAttribute("CallType", callType)
    pulse:SetAttribute("VisibleActionEffect", true)
    pulse.Parent = workspace
    Debris:AddItem(pulse, 1.25)
    return pulse
end

local function wireMobileButtons(result)
    local gui = result and result.Gui
    if not gui then return end
    local function refreshContext()
        local stats = ClientBootstrap.LastStats or {}
        local modes = stats.movementModes or {}
        setButtonContext(gui:FindFirstChild("EatDrinkButton"), "🍎💧", true)
        setButtonContext(gui:FindFirstChild("AttackButton"), "🦷 " .. ClientBootstrap:GetPrimaryAttack(), true)
        setButtonContext(gui:FindFirstChild("SprintButton"), (stats.stamina and stats.stamina < 15) and "⚡ low" or "⚡", stats.stamina == nil or stats.stamina >= 5)
        setButtonContext(gui:FindFirstChild("CallButton"), "📣", true)
        setButtonContext(gui:FindFirstChild("RestHideButton"), player:GetAttribute("Hidden") and "🌿 cozy" or "🌿", true)
        local canFly = modes.Flight == true or modes.flight == true or modes.flying == true
        local canSwim = modes.Swim == true or modes.swim == true or modes.swimming == true
        setButtonContext(gui:FindFirstChild("FlightButton"), canFly and "🪽" or "", canFly, true)
        setButtonContext(gui:FindFirstChild("SwimButton"), canSwim and "🌊" or "", canSwim, true)
    end
    ClientBootstrap.RefreshMobileContext = refreshContext
    refreshContext()
    local eatDrink = gui:FindFirstChild("EatDrinkButton")
    if eatDrink then
        eatDrink.Activated:Connect(function()
            local target, targetType = ClientBootstrap:FindNearestEatDrinkTarget(14)
            if target then
                if targetType == "Food" then
                    ClientBootstrap:PlayActionMotion("Eat", target)
                    InputController:RequestEat(target)
                    showFeedback(gui, "🍎 +")
                elseif targetType == "Water" then
                    ClientBootstrap:PlayActionMotion("Drink", target)
                    InputController:RequestDrink(target)
                    showFeedback(gui, "💧 +")
                end
            else
                ClientBootstrap:ShowActionFeedback(gui, "◌ 🍎 💧")
            end
            ClientBootstrap:UpdateActionGuidance(gui)
        end)
    end
    local attack = gui:FindFirstChild("AttackButton")
    if attack then
        attack.Activated:Connect(function()
            local target = ClientBootstrap:FindNearestTagged(Constants.Tags.Damageable, 12)
            ClientBootstrap:PlayActionMotion("Attack", target)
            InputController:RequestAttack(ClientBootstrap:GetPrimaryAttack(), target)
            markButtonPressed(attack, "Chomp")
            showFeedback(gui, "Chomp!", attack)
        end)
    end

    local sprint = gui:FindFirstChild("SprintButton")
    if sprint then
        sprint.Activated:Connect(function()
            local isSprinting = not player:GetAttribute("Sprinting")
            player:SetAttribute("Sprinting", isSprinting)
            InputController:RequestSprint(isSprinting)
            local humanoid = getHumanoid()
            if humanoid then humanoid.WalkSpeed = isSprinting and SPRINT_WALK_SPEED or DEFAULT_WALK_SPEED end
            sprint.Text = isSprinting and "⚡ Zoom!" or "⚡ Zoom"
            setButtonActive(sprint, isSprinting)
            showFeedback(gui, isSprinting and "⚡↓" or "⚡+")
        end)
    end

    local call = gui:FindFirstChild("CallButton")
    if call then
        call.Activated:Connect(function()
            local callType = "Friendly"
            ClientBootstrap:PlayActionMotion("Call")
            InputController:RequestCall(callType)
            local pulse = createLocalCallPulse(callType)
            call:SetAttribute("LastCallType", callType)
            call:SetAttribute("VisibleEffectCreated", pulse ~= nil)
            markButtonPressed(call, "Roar sent")
            showFeedback(gui, "📣!", call)
        end)
    end

    local restHide = gui:FindFirstChild("RestHideButton")
    if restHide then
        restHide.Activated:Connect(function()
            local isHidden = not player:GetAttribute("Hidden")
            player:SetAttribute("Hidden", isHidden)
            InputController:RequestRest(isHidden)
            ClientBootstrap:PlayActionMotion("Hide")
            applyHiddenVisual(isHidden)
            restHide.Text = isHidden and "🌿 Cozy" or "🌿 Rest"
            setButtonActive(restHide, isHidden)
            markButtonPressed(restHide, isHidden and "Cozy" or "Ready")
            showFeedback(gui, isHidden and "🌿💤" or "✅", restHide)
        end)
    end

    local flight = gui:FindFirstChild("FlightButton")
    if flight then
        flight.Activated:Connect(function()
            local enabled = not player:GetAttribute("Flying")
            player:SetAttribute("Flying", enabled)
            InputController:RequestFlight(enabled)
            flight.Text = enabled and "🪽 Flying" or "🪽 Fly"
            setButtonActive(flight, enabled)
            showFeedback(gui, enabled and "🪽⚡" or "🦶")
        end)
    end

    local swim = gui:FindFirstChild("SwimButton")
    if swim then
        swim.Activated:Connect(function()
            local water = ClientBootstrap:FindNearestEatDrinkTarget(18, "Water")
            InputController:RequestSwim(water)
            swim:SetAttribute("LastWaterTarget", water and water.Name or "")
            showFeedback(gui, water and "🌊🫧" or "◌ 💧")
            ClientBootstrap:UpdateActionGuidance(gui)
        end)
    end
end

function ClientBootstrap:Init()
    HUDController:EnsureGui()
    HatchUIController:Show()
    HatchUIController:SetSpeciesOptions(HatchUIController.StarterSpecies, nil, function(speciesId)
        InputController:RequestSelectSpecies(speciesId)
    end)
    local mobile = MobileControlsController:CreateControls({ MobileButtonScale = 1 })
    wireMobileButtons(mobile)
    -- Diegetic food/water sense guide. Reuses our authoritative, diet-aware target
    -- finder + live stats so it stays in lockstep with the EatDrink button and the
    -- NearestActionHintLabel. Progressive disclosure: it stays hidden until hungry/thirsty.
    SenseGuideController:Bind({
        Finder = function(maxDistance, preferredMode)
            return ClientBootstrap:FindNearestEatDrinkTarget(maxDistance, preferredMode)
        end,
        GetStats = function()
            return ClientBootstrap.LastStats
        end,
    })
    RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - ClientBootstrap.LastTargetScanAt >= ClientBootstrap.TargetScanSeconds then
            ClientBootstrap.LastTargetScanAt = now
            ClientBootstrap:UpdateActionGuidance(mobile.Gui)
            SenseGuideController:Update()
        end
    end)
    Remotes:WaitForChild("StatUpdate").OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" then return end
        ClientBootstrap.LastStats = payload
        if ClientBootstrap.RefreshMobileContext then
            ClientBootstrap.RefreshMobileContext()
        end
        ClientBootstrap:UpdateActionGuidance(mobile.Gui)
        SenseGuideController:Update()
        if type(payload.hatchProgress) == "number" then HatchUIController:SetProgress(payload.hatchProgress) end
        if type(payload.species) == "string" and HatchUIController.Gui and HatchUIController.Gui.Enabled ~= false then
            HatchUIController:SetSpeciesOptions(HatchUIController.StarterSpecies, payload.species)
        end
        if payload.hatched == true and HatchUIController.Gui then HatchUIController.Gui.Enabled = false end
    end)
    return true
end

ClientBootstrap:Init()
return ClientBootstrap
