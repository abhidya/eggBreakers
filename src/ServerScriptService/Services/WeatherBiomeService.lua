local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local WeatherBiomeService = { CurrentWeather = "Clear" }
WeatherBiomeService.WeatherCycle = { "Clear", "Cloudy", "Rain" }
WeatherBiomeService.CoverageSize = Vector3.new(4700, 2, 4400)
WeatherBiomeService.CoverageCenter = Vector3.new(-450, 90, -250)
WeatherBiomeService.MaxTileSize = 2048
-- Design doc: "Cut the broken rain element." The giant neon "VisibleRainStreaks"
-- slabs washed the scene blue. They are disabled by default; flip to true only
-- if a future, non-ugly streak VFX is wired up. Non-visual weather state below
-- (biome weather, lighting, rain volume tiles) is unaffected.
WeatherBiomeService.VisibleRainEnabled = false

function WeatherBiomeService:GetFolder()
    local folder = Workspace:FindFirstChild("WeatherEffects")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "WeatherEffects"
        folder.Parent = Workspace
    end
    return folder
end

function WeatherBiomeService:_configureWeatherPart(part, size, position, material, color)
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Material = material
    part.Color = color
    part.Size = size
    part.Position = position
    part:SetAttribute("WeatherEffect", true)
    part:SetAttribute("ProceduralVFX", true)
end

function WeatherBiomeService:_ensureRainTiles(folder, prefix, height, y, material, color)
    local coverage = self.CoverageSize
    local center = self.CoverageCenter
    local maxTile = self.MaxTileSize
    local xTiles = math.ceil(coverage.X / maxTile)
    local zTiles = math.ceil(coverage.Z / maxTile)
    local tileX = coverage.X / xTiles
    local tileZ = coverage.Z / zTiles
    local used = {}

    for x = 1, xTiles do
        for z = 1, zTiles do
            local name = string.format("%s_%d_%d", prefix, x, z)
            used[name] = true
            local part = folder:FindFirstChild(name)
            if not part then
                part = Instance.new("Part")
                part.Name = name
                part.Parent = folder
            end
            local offsetX = -coverage.X / 2 + tileX * (x - 0.5)
            local offsetZ = -coverage.Z / 2 + tileZ * (z - 0.5)
            self:_configureWeatherPart(
                part,
                Vector3.new(tileX, height, tileZ),
                Vector3.new(center.X + offsetX, y, center.Z + offsetZ),
                material,
                color
            )
            part:SetAttribute("CoverageX", coverage.X)
            part:SetAttribute("CoverageZ", coverage.Z)
            part:SetAttribute("RainTileCount", xTiles * zTiles)
        end
    end

    for _, child in ipairs(folder:GetChildren()) do
        if string.sub(child.Name, 1, #prefix + 1) == prefix .. "_" and not used[child.Name] then
            child:Destroy()
        end
    end
    return xTiles * zTiles
end

-- Destroys any existing "VisibleRainStreaks" slabs under Workspace.WeatherEffects.
-- Safe to call when the folder/parts are absent; returns the number removed.
function WeatherBiomeService:ClearVisibleRain(folder)
    folder = folder or Workspace:FindFirstChild("WeatherEffects")
    if not folder then
        return 0
    end
    local removed = 0
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("BasePart") and string.find(child.Name, "VisibleRainStreaks", 1, true) then
            child:Destroy()
            removed += 1
        end
    end
    return removed
end

function WeatherBiomeService:ApplyWeather(weatherName)
    self.CurrentWeather = weatherName or self.CurrentWeather or "Clear"
    Lighting:SetAttribute("CurrentWeather", self.CurrentWeather)
    Lighting.Brightness = self.CurrentWeather == "Rain" and 1.5 or 2
    Lighting.ClockTime = self.CurrentWeather == "Rain" and 15.5 or 13
    local folder = self:GetFolder()
    local rainTileCount = self:_ensureRainTiles(folder, "VisibleRainVolume", 2, self.CoverageCenter.Y, Enum.Material.Glass, Color3.fromRGB(120, 170, 255))
    if self.VisibleRainEnabled then
        self:_ensureRainTiles(folder, "VisibleRainStreaks", 80, 48, Enum.Material.Neon, Color3.fromRGB(150, 205, 255))
    else
        -- Streak slabs are cut: make sure none linger (e.g. from a prior session/build).
        self:ClearVisibleRain(folder)
    end

    local visible = self.CurrentWeather == "Rain"
    folder:SetAttribute("WeatherCoverageX", self.CoverageSize.X)
    folder:SetAttribute("WeatherCoverageZ", self.CoverageSize.Z)
    folder:SetAttribute("RainTileCount", rainTileCount)
    folder:SetAttribute("VisibleWeatherFeedback", visible)
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("BasePart") then
            if string.find(child.Name, "VisibleRainVolume", 1, true) then
                child.Transparency = visible and 0.62 or 1
            elseif string.find(child.Name, "VisibleRainStreaks", 1, true) then
                child.Transparency = visible and 0.88 or 1
            end
            child:SetAttribute("VisibleWeatherFeedback", visible)
        end
    end
    return self.CurrentWeather
end

-- Boot hook: clean up any pre-existing streak slabs so they never wash the scene
-- blue on a fresh session. Safe when the world/folder is absent (returns 0).
function WeatherBiomeService:Init()
    if not self.VisibleRainEnabled then
        self:ClearVisibleRain()
    end
    return self
end

function WeatherBiomeService:StartLoop(intervalSeconds)
    if self.Running then return false, "already_running" end
    if not self.VisibleRainEnabled then
        self:ClearVisibleRain()
    end
    self.Running = true
    task.spawn(function()
        local index = 1
        while self.Running do
            self:ApplyWeather(self.WeatherCycle[index])
            index = (index % #self.WeatherCycle) + 1
            task.wait(intervalSeconds or 90)
        end
    end)
    return true
end

function WeatherBiomeService:StopLoop()
    self.Running = false
end

return WeatherBiomeService
