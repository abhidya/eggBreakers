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
        rain.Size = Vector3.new(4700, 2, 4400)
        rain.Position = Vector3.new(-450, 90, -250)
        rain.Transparency = 1
        rain:SetAttribute("WeatherEffect", true)
        rain.Parent = folder
    end
    rain.Size = Vector3.new(4700, 2, 4400)
    rain.Position = Vector3.new(-450, 90, -250)
    rain.Transparency = self.CurrentWeather == "Rain" and 0.62 or 1
    rain:SetAttribute("VisibleWeatherFeedback", self.CurrentWeather == "Rain")

    local streak = folder:FindFirstChild("VisibleRainStreaks")
    if not streak then
        streak = Instance.new("Part")
        streak.Name = "VisibleRainStreaks"
        streak.Anchored = true
        streak.CanCollide = false
        streak.CanTouch = false
        streak.CanQuery = false
        streak.Material = Enum.Material.Neon
        streak.Color = Color3.fromRGB(150, 205, 255)
        streak.Size = Vector3.new(4700, 80, 4400)
        streak.Position = Vector3.new(-450, 48, -250)
        streak.Parent = folder
    end
    streak.Transparency = self.CurrentWeather == "Rain" and 0.88 or 1
    streak:SetAttribute("WeatherEffect", true)
    streak:SetAttribute("VisibleWeatherFeedback", self.CurrentWeather == "Rain")
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
