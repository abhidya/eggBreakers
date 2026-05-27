local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local controllers = script.Parent:WaitForChild("ClientControllers")
local HUDController = require(controllers:WaitForChild("HUDController"))
local HatchUIController = require(controllers:WaitForChild("HatchUIController"))
local InputController = require(controllers:WaitForChild("InputController"))
local MobileControlsController = require(controllers:WaitForChild("MobileControlsController"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

local ClientBootstrap = {}
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
            local target = player:GetAttribute("CurrentInteractionTarget")
            if typeof(target) == "Instance" then
                if target:GetAttribute("Diet") then
                    InputController:RequestEat(target)
                elseif target:GetAttribute("WaterSource") or target.Name:find("Water") then
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
