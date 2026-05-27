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
    local rain = folder and folder:FindFirstChild("VisibleRainVolume")
    Assert.notNil(rain, "visible rain volume exists")
    Assert.equals(rain:GetAttribute("WeatherEffect"), true, "rain is tagged as weather effect")
    Assert.truthy(rain.Transparency < 1, "rain has visible feedback")
    WeatherBiomeService:ApplyWeather("Clear")
    Assert.equals(Lighting:GetAttribute("CurrentWeather"), "Clear", "clear weather restored")
end })

return TestRunner.registerSuite(suite)
