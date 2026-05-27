local RunService = game:GetService("RunService")
local MapLayoutService = require(script.Parent.Services.MapLayoutService)

MapLayoutService:EnsureSpawnSafety()

if RunService:IsStudio() then
    local ok, missing = MapLayoutService:ValidateLayoutFolders()
    if ok then
        print("[eggBreakers] Map terrain/nav scaffold ready")
    else
        warn("[eggBreakers] Missing map terrain/nav scaffold: " .. table.concat(missing, ", "))
    end
end
