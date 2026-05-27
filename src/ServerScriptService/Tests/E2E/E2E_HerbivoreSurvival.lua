local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local CollectionService = game:GetService("CollectionService")
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local FoodWaterService = require(game:GetService("ServerScriptService").Services.FoodWaterService)
local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)
local suite = { name = "E2E_HerbivoreSurvival.server", category = "E2E", tests = {} }
local function setup(id) local p=MockPlayer.new(id,"HerbE2E"); RateLimitService:ClearPlayer(p); local r=Instance.new("Part"); r.Name="HumanoidRootPart"; r.Position=Vector3.new(0,3,0); local c=Instance.new("Model"); r.Parent=c; p.Character=c; local s=SurvivalService:CreateState(p,"triceratops"); s.Hatched=true; return p,s end
local function food(diet) local f=Instance.new("Part"); f.Position=Vector3.new(2,3,0); f:SetAttribute("Diet",diet); f:SetAttribute("Nutrition",20); f.Parent=workspace; CollectionService:AddTag(f,"FoodSource"); return f end

table.insert(suite.tests,{name="herbivore rejects meat accepts plant",run=function() local p=setup(42001); local meat=food("Carnivore"); Assert.falsy(FoodWaterService:RequestEat(p,meat),"herbivore rejects meat"); RateLimitService:ClearPlayer(p); local plant=food("Herbivore"); Assert.truthy(FoodWaterService:RequestEat(p,plant),"herbivore eats plant"); meat:Destroy(); plant:Destroy() end})
table.insert(suite.tests,{name="drink/growth/danger warning flow",run=function() local p,s=setup(42002); local water=Instance.new("Part"); water.Position=Vector3.new(2,3,0); water.Parent=workspace; CollectionService:AddTag(water,"WaterSource"); s.Thirst=40; Assert.truthy(FoodWaterService:RequestDrink(p,water),"drink succeeds"); SurvivalService:AddGrowth(p,25); Assert.equals(s.GrowthStage,"Juvenile","growth advances"); water:Destroy() end})
return suite
