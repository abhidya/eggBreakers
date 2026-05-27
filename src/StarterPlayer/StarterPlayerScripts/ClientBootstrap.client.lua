local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

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

local function distanceToRoot(root, target)
    if not root or not target or not target:IsDescendantOf(workspace) then return nil end
    local targetPosition = target:IsA("BasePart") and target.Position or target:GetPivot().Position
    return (root.Position - targetPosition).Magnitude
end

function ClientBootstrap:FindNearestEatDrinkTarget(maxDistance)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local bestTarget = nil
    local bestDistance = maxDistance or 14
    local function consider(target)
        if target:GetAttribute("Depleted") == true then return end
        local distance = distanceToRoot(root, target)
        if distance and distance <= bestDistance then
            bestTarget = target
            bestDistance = distance
        end
    end

    for _, target in ipairs(CollectionService:GetTagged(Constants.Tags.FoodSource)) do
        consider(target)
    end
    for _, target in ipairs(CollectionService:GetTagged(Constants.Tags.WaterSource)) do
        consider(target)
    end
    return bestTarget
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

function ClientBootstrap:PlayActionMotion(actionName)
    if self.MotionPlaying then return false end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
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
            local target = ClientBootstrap:FindNearestEatDrinkTarget(14)
            if target then
                if CollectionService:HasTag(target, Constants.Tags.FoodSource) then
                    ClientBootstrap:PlayActionMotion("Eat")
                    InputController:RequestEat(target)
                    showFeedback(gui, "Eating")
                elseif CollectionService:HasTag(target, Constants.Tags.WaterSource) or target:GetAttribute("WaterSource") or target.Name:find("Water") then
                    ClientBootstrap:PlayActionMotion("Drink")
                    InputController:RequestDrink(target)
                    showFeedback(gui, "Drinking")
                end
            else
                ClientBootstrap:ShowActionFeedback(gui, "No food or water nearby")
            end
        end)
    end
    local attack = gui:FindFirstChild("AttackButton")
    if attack then
        attack.Activated:Connect(function()
            ClientBootstrap:PlayActionMotion("Attack")
            InputController:RequestAttack(ClientBootstrap:GetPrimaryAttack(), ClientBootstrap:FindNearestTagged(Constants.Tags.Damageable, 12))
            showFeedback(gui, "Attacking")
        end)
    end

    local sprint = gui:FindFirstChild("SprintButton")
    if sprint then
        sprint.Activated:Connect(function()
            local isSprinting = not player:GetAttribute("Sprinting")
            player:SetAttribute("Sprinting", isSprinting)
            local humanoid = getHumanoid()
            if humanoid then humanoid.WalkSpeed = isSprinting and SPRINT_WALK_SPEED or DEFAULT_WALK_SPEED end
            sprint.Text = isSprinting and "Sprint ON" or "Sprint"
            setButtonActive(sprint, isSprinting)
            showFeedback(gui, isSprinting and "Sprint speed active" or "Sprint off")
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
end

function ClientBootstrap:Init()
    HUDController:EnsureGui()
    HatchUIController:Show()
    wireMobileButtons(MobileControlsController:CreateControls({ MobileButtonScale = 1 }))
    Remotes:WaitForChild("StatUpdate").OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" then return end
        ClientBootstrap.LastStats = payload
        if type(payload.hatchProgress) == "number" then HatchUIController:SetProgress(payload.hatchProgress) end
        if payload.hatched == true and HatchUIController.Gui then HatchUIController.Gui.Enabled = false end
    end)
    return true
end

ClientBootstrap:Init()
return ClientBootstrap
