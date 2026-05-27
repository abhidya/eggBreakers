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
    local speciesId = self.LastStats and self.LastStats.species or "gallimimus"
    local species = SpeciesConfig[speciesId] or SpeciesConfig.gallimimus
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

function ClientBootstrap:ShowActionFeedback(gui, message)
    local label = gui and gui:FindFirstChild("ActionFeedbackLabel")
    if not label then return false end
    label.Text = message
    label.Visible = true
    label:SetAttribute("LastFeedback", message)
    return true
end

function ClientBootstrap:UpdateActionGuidance(gui)
    if not gui then return false end
    local target, targetType, distance = self:FindNearestEatDrinkTarget(80)
    local hint = gui:FindFirstChild("NearestActionHintLabel")
    local dialogue = gui:FindFirstChild("DialoguePromptLabel")
    local eatDrink = gui:FindFirstChild("EatDrinkButton")
    local stats = self.LastStats or {}
    if target then
        local targetName, targetDiet = self:DescribeTarget(target)
        local verb = targetType == "Water" and "DRINK" or "EAT"
        local text = string.format("%s: %s (%s) %.0fm", verb, targetName, targetDiet, distance or 0)
        if hint then
            hint.Text = "Nearest real asset: " .. text
            hint:SetAttribute("TargetName", target.Name)
            hint:SetAttribute("TargetType", targetType)
            hint:SetAttribute("DistanceStuds", math.floor((distance or 0) + 0.5))
        end
        if eatDrink then
            eatDrink.Text = verb .. "\n" .. targetName
            eatDrink:SetAttribute("CurrentTargetName", target.Name)
            eatDrink:SetAttribute("CurrentTargetType", targetType)
        end
        if dialogue then
            if targetType == "Water" then
                dialogue.Text = "Guide: drink this blue water to raise THIRST and gain Growth."
            else
                dialogue.Text = "Guide: eat this real " .. string.lower(targetDiet) .. " food to raise HUNGER and grow."
            end
        end
    else
        if hint then
            hint.Text = "No food/water close. Move toward glowing plants, tree browse, carcasses, or blue water — not NPC labels."
            hint:SetAttribute("TargetName", "")
            hint:SetAttribute("TargetType", "None")
        end
        if eatDrink then
            local need = (tonumber(stats.thirst) or 100) < (tonumber(stats.hunger) or 100) and "DRINK" or "EAT"
            eatDrink.Text = need .. "\nfind marker"
            eatDrink:SetAttribute("CurrentTargetName", "")
            eatDrink:SetAttribute("CurrentTargetType", "None")
        end
        if dialogue then
            dialogue.Text = "Guide: look for non-NPC action markers: green plants/tree leaves, red carcasses, fish, or blue water."
        end
    end
    return true
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

local function showFeedback(gui, message)
    local label = gui and gui:FindFirstChild("ActionFeedbackLabel")
    if not label then return end
    label.Text = message
    label.Visible = true
    label:SetAttribute("LastFeedback", message)
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
    local eatDrink = gui:FindFirstChild("EatDrinkButton")
    if eatDrink then
        eatDrink.Activated:Connect(function()
            local target, targetType = ClientBootstrap:FindNearestEatDrinkTarget(14)
            if target then
                if targetType == "Food" then
                    ClientBootstrap:PlayActionMotion("Eat", target)
                    InputController:RequestEat(target)
                    showFeedback(gui, "Eating: hunger + growth should rise")
                elseif targetType == "Water" then
                    ClientBootstrap:PlayActionMotion("Drink", target)
                    InputController:RequestDrink(target)
                    showFeedback(gui, "Drinking: thirst + growth should rise")
                end
            else
                ClientBootstrap:ShowActionFeedback(gui, "No real food/water nearby — follow FOOD/WATER marker")
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
            showFeedback(gui, "Attacking")
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
            sprint.Text = isSprinting and "SPRINT ON\nstamina ↓" or "SPRINT\nuses stamina"
            setButtonActive(sprint, isSprinting)
            showFeedback(gui, isSprinting and "Sprint ON: stamina drains while moving" or "Sprint off: stamina recovers")
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
            showFeedback(gui, "Friendly call sent")
        end)
    end

    local restHide = gui:FindFirstChild("RestHideButton")
    if restHide then
        restHide.Activated:Connect(function()
            local isHidden = not player:GetAttribute("Hidden")
            player:SetAttribute("Hidden", isHidden)
            ClientBootstrap:PlayActionMotion("Hide")
            applyHiddenVisual(isHidden)
            restHide.Text = isHidden and "Hidden" or "Rest/Hide"
            setButtonActive(restHide, isHidden)
            showFeedback(gui, isHidden and "Hidden/resting" or "Visible")
        end)
    end

    local flight = gui:FindFirstChild("FlightButton")
    if flight then
        flight.Activated:Connect(function()
            local enabled = not player:GetAttribute("Flying")
            player:SetAttribute("Flying", enabled)
            InputController:RequestFlight(enabled)
            flight.Text = enabled and "FLYING\nstamina ↓" or "FLY\nstamina"
            setButtonActive(flight, enabled)
            showFeedback(gui, enabled and "Flight ON: stamina drains" or "Flight off / landing")
        end)
    end

    local swim = gui:FindFirstChild("SwimButton")
    if swim then
        swim.Activated:Connect(function()
            local water = ClientBootstrap:FindNearestEatDrinkTarget(18, "Water")
            InputController:RequestSwim(water)
            swim:SetAttribute("LastWaterTarget", water and water.Name or "")
            showFeedback(gui, water and "Swimming: watch oxygen" or "No water close enough to swim")
            ClientBootstrap:UpdateActionGuidance(gui)
        end)
    end
end

function ClientBootstrap:Init()
    HUDController:EnsureGui()
    HatchUIController:Show()
    local mobile = MobileControlsController:CreateControls({ MobileButtonScale = 1 })
    wireMobileButtons(mobile)
    RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - ClientBootstrap.LastTargetScanAt >= ClientBootstrap.TargetScanSeconds then
            ClientBootstrap.LastTargetScanAt = now
            ClientBootstrap:UpdateActionGuidance(mobile.Gui)
        end
    end)
    Remotes:WaitForChild("StatUpdate").OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" then return end
        ClientBootstrap.LastStats = payload
        ClientBootstrap:UpdateActionGuidance(mobile.Gui)
        if type(payload.hatchProgress) == "number" then HatchUIController:SetProgress(payload.hatchProgress) end
        if payload.hatched == true and HatchUIController.Gui then HatchUIController.Gui.Enabled = false end
    end)
    return true
end

ClientBootstrap:Init()
return ClientBootstrap
