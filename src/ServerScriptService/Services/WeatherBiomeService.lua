local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local WeatherBiomeService = { CurrentWeather = "Clear" }
WeatherBiomeService.WeatherCycle = { "Clear", "Cloudy", "Rain" }

function WeatherBiomeService:GetFolder()
    local folder = Workspace:FindFirstChild("WeatherEffects")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "WeatherEffects"
        folder.Parent = Workspace
    end
    return folder
end

function WeatherBiomeService:ApplyWeather(weatherName)
    self.CurrentWeather = weatherName or self.CurrentWeather or "Clear"
    Lighting:SetAttribute("CurrentWeather", self.CurrentWeather)
    Lighting.Brightness = self.CurrentWeather == "Rain" and 1.5 or 2
    Lighting.ClockTime = self.CurrentWeather == "Rain" and 15.5 or 13
    local folder = self:GetFolder()
    local rain = folder:FindFirstChild("VisibleRainVolume")
    if not rain then
        rain = Instance.new("Part")
        rain.Name = "VisibleRainVolume"
        rain.Anchored = true
        rain.CanCollide = false
        rain.CanTouch = false
        rain.CanQuery = false
        rain.Material = Enum.Material.Glass
        rain.Color = Color3.fromRGB(120, 170, 255)
        rain.Size = Vector3.new(900, 2, 900)
        rain.Position = Vector3.new(-1500, 90, 120)
        rain.Transparency = 1
        rain:SetAttribute("WeatherEffect", true)
        rain.Parent = folder
    end
    rain.Transparency = self.CurrentWeather == "Rain" and 0.82 or 1
    return self.CurrentWeather
end

function WeatherBiomeService:StartLoop(intervalSeconds)
    if self.Running then return false, "already_running" end
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
