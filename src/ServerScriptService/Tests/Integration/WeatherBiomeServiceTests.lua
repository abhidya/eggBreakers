local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TestRunner = require(ReplicatedStorage.Shared.TestFramework.TestRunner)
local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)
local WeatherBiomeService = require(ServerScriptService.Services.WeatherBiomeService)
local Lighting = game:GetService("Lighting")

local suite = { name = "WeatherBiomeServiceTests", category = "Integration", tests = {} }

table.insert(suite.tests, { name = "weather creates visible rain feedback and lighting state", run = function()
    local weather = WeatherBiomeService:ApplyWeather("Rain")
    Assert.equals(weather, "Rain", "rain weather applied")
    Assert.equals(Lighting:GetAttribute("CurrentWeather"), "Rain", "Lighting records current weather")
    local folder = workspace:FindFirstChild("WeatherEffects")
    Assert.equals(folder:GetAttribute("WeatherCoverageX"), 4700, "rain coverage spans playable map width")
    Assert.equals(folder:GetAttribute("WeatherCoverageZ"), 4400, "rain coverage spans playable map depth")
    Assert.truthy((folder:GetAttribute("RainTileCount") or 0) >= 9, "rain uses tiled parts to avoid Roblox 2048-stud part clamp")
    local visibleRainTiles = 0
    local visibleStreakTiles = 0
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("BasePart") and child:GetAttribute("WeatherEffect") == true then
            Assert.truthy(child.Size.X <= 2048 and child.Size.Z <= 2048, "weather tile respects Roblox part size limit")
            if string.find(child.Name, "VisibleRainVolume", 1, true) and child.Transparency < 1 then
                visibleRainTiles = visibleRainTiles + 1
            elseif string.find(child.Name, "VisibleRainStreaks", 1, true) and child.Transparency < 1 then
                visibleStreakTiles = visibleStreakTiles + 1
            end
            Assert.equals(child:GetAttribute("VisibleWeatherFeedback"), true, "weather tile marks visible feedback")
        end
    end
    Assert.truthy(visibleRainTiles >= 9, "visible rain tiles exist")
    Assert.truthy(visibleStreakTiles >= 9, "visible rain streak tiles exist")
    WeatherBiomeService:ApplyWeather("Clear")
    Assert.equals(Lighting:GetAttribute("CurrentWeather"), "Clear", "clear weather restored")
end })

return TestRunner.registerSuite(suite)
