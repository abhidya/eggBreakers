local RunService = game:GetService("RunService")
local NPCSpawnService = require(script.Parent.Services.NPCSpawnService)

if RunService:IsStudio() then
    task.defer(function()
        local active = NPCSpawnService:MaintainMinimumActive()
        print("[eggBreakers] NPC active target maintained: " .. tostring(active))
    end)
end
