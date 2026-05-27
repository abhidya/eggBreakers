local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local controllers = script.Parent:WaitForChild("ClientControllers")
local HUDController = require(controllers:WaitForChild("HUDController"))
local HatchUIController = require(controllers:WaitForChild("HatchUIController"))
local InputController = require(controllers:WaitForChild("InputController"))
local MobileControlsController = require(controllers:WaitForChild("MobileControlsController"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Constants = require(ReplicatedStorage.Shared.Constants)
local player = Players.LocalPlayer

local ClientBootstrap = {}

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

ClientBootstrap.Controllers = {
    HUDController = HUDController,
    HatchUIController = HatchUIController,
    InputController = InputController,
    MobileControlsController = MobileControlsController,
}

local function wireMobileButtons(result)
    local gui = result and result.Gui
    if not gui then return end
    local eatDrink = gui:FindFirstChild("EatDrinkButton")
    if eatDrink then
        eatDrink.Activated:Connect(function()
            local target = ClientBootstrap:FindNearestEatDrinkTarget(14)
            if target then
                if CollectionService:HasTag(target, Constants.Tags.FoodSource) then
                    InputController:RequestEat(target)
                elseif CollectionService:HasTag(target, Constants.Tags.WaterSource) then
                    InputController:RequestDrink(target)
                end
            end
        end)
    end
    local attack = gui:FindFirstChild("AttackButton")
    if attack then attack.Activated:Connect(function() InputController:RequestAttack("Claw", nil) end) end
    local call = gui:FindFirstChild("CallButton")
    if call then call.Activated:Connect(function() InputController:RequestCall("Friendly") end) end
end

function ClientBootstrap:Init()
    HUDController:EnsureGui()
    HatchUIController:Show()
    wireMobileButtons(MobileControlsController:CreateControls({ MobileButtonScale = 1 }))
    Remotes:WaitForChild("StatUpdate").OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" then return end
        if type(payload.hatchProgress) == "number" then HatchUIController:SetProgress(payload.hatchProgress) end
        if payload.hatched == true and HatchUIController.Gui then HatchUIController.Gui.Enabled = false end
    end)
    return true
end

ClientBootstrap:Init()
return ClientBootstrap
