local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local MapLayoutService = require(ServerScriptService.Services.MapLayoutService)
local StoryAssetPlacements = require(ReplicatedStorage.Shared.StoryAssetPlacements)

local spawn = MapLayoutService:EnsureSpawnSafety()
local folders = MapLayoutService:EnsureMapFolders()
local result = MapLayoutService:EnsureStoryAssetPlacements(folders)

local saveOk, saveErr = pcall(function()
    game:Save()
end)

local map = Workspace:FindFirstChild("Map")
local storyboards = map and map:FindFirstChild("Storyboards")
local storyboardNames = {}
if storyboards then
    for _, child in ipairs(storyboards:GetChildren()) do
        table.insert(storyboardNames, child.Name)
    end
end
table.sort(storyboardNames)

print(HttpService:JSONEncode({
    builtSpawn = spawn ~= nil,
    expectedPlacements = #StoryAssetPlacements.Placements,
    placed = result.placed,
    imported = result.imported,
    fallback = result.fallback,
    storyboards = storyboardNames,
    mapStoryAssetPlacementsBuilt = map and map:GetAttribute("StoryAssetPlacementsBuilt") == true,
    mapStoryAssetPlacementCount = map and map:GetAttribute("StoryAssetPlacementCount") or 0,
    saveAttempted = true,
    saveOk = saveOk,
    saveError = saveOk and nil or tostring(saveErr),
}))
