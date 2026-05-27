local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local CollectionService = game:GetService("CollectionService")
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local FoodWaterService = require(game:GetService("ServerScriptService").Services.FoodWaterService)
local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)
local suite = { name = "E2E_HatchToFirstFood.server", category = "E2E", tests = {} }
local function rootFor(p) local r=Instance.new("Part"); r.Name="HumanoidRootPart"; r.Position=Vector3.new(0,3,0); local c=Instance.new("Model"); r.Parent=c; p.Character=c end

table.insert(suite.tests, { name = "hatch assigns dinosaur and diet", run = function()
    local p=MockPlayer.new(41001,"E2EHatch"); SurvivalService:CreateState(p,"gallimimus")
    for _=1,5 do SurvivalService:RequestHatch(p,"tap") end
    local s=SurvivalService:GetState(p)
    Assert.equals(s.Hatched,true,"player hatched")
    Assert.equals(s.SpeciesId,"gallimimus","species assigned")
    Assert.equals(s.Diet,"Herbivore","diet shown")
end })

table.insert(suite.tests, { name = "first food increases hunger and tutorial advances", run = function()
    local p=MockPlayer.new(41002,"E2EFood"); RateLimitService:ClearPlayer(p); rootFor(p)
    local s=SurvivalService:CreateState(p,"gallimimus"); s.Hatched=true; s.Hunger=40
    local food=Instance.new("Part"); food.Position=Vector3.new(2,3,0); food:SetAttribute("Diet","Herbivore"); food:SetAttribute("Nutrition",25); food.Parent=workspace; CollectionService:AddTag(food,"FoodSource")
    Assert.truthy(FoodWaterService:RequestEat(p,food),"first food request accepted")
    Assert.truthy(s.Hunger>40,"hunger increased")
    Assert.equals(food:GetAttribute("Depleted"),true,"tutorial food consumed")
    food:Destroy()
end })
return suite
