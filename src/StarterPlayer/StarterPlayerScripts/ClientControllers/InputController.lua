local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local InputController = {}

function InputController:RequestHatch(inputType) Remotes.RequestHatch:FireServer(inputType) end
function InputController:RequestEat(target) Remotes.RequestEat:FireServer(target) end
function InputController:RequestDrink(target) Remotes.RequestDrink:FireServer(target) end
function InputController:RequestSwim(water) Remotes.RequestSwim:FireServer(water) end
function InputController:RequestFlight(enabled) Remotes.RequestFlight:FireServer(enabled == true) end
function InputController:RequestAttack(attackType, target) Remotes.RequestAttack:FireServer(attackType, target) end
function InputController:RequestCall(callType) Remotes.RequestCall:FireServer(callType) end
function InputController:RequestNestAction(actionType, nest) Remotes.RequestNestAction:FireServer(actionType, nest) end
function InputController:RequestCollectFossil(fossil) Remotes.RequestCollectFossil:FireServer(fossil) end

return InputController
