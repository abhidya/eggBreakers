local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local CollectionService = game:GetService("CollectionService")
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local FoodWaterService = require(game:GetService("ServerScriptService").Services.FoodWaterService)
local CombatService = require(game:GetService("ServerScriptService").Services.CombatService)
local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)
local suite = { name = "E2E_CarnivoreSurvival.server", category = "E2E", tests = {} }
local function setup(id) local p=MockPlayer.new(id,"CarnE2E"); RateLimitService:ClearPlayer(p); local r=Instance.new("Part"); r.Name="HumanoidRootPart"; r.Position=Vector3.new(0,3,0); local c=Instance.new("Model"); r.Parent=c; p.Character=c; local s=SurvivalService:CreateState(p,"velociraptor"); s.Hatched=true; return p,s end
local function food(diet) local f=Instance.new("Part"); f.Position=Vector3.new(2,3,0); f:SetAttribute("Diet",diet); f:SetAttribute("Nutrition",20); f.Parent=workspace; CollectionService:AddTag(f,"FoodSource"); return f end

table.insert(suite.tests,{name="carnivore rejects plant accepts meat",run=function() local p=setup(43001); local plant=food("Herbivore"); Assert.falsy(FoodWaterService:RequestEat(p,plant),"carnivore rejects plant"); RateLimitService:ClearPlayer(p); local meat=food("Carnivore"); Assert.truthy(FoodWaterService:RequestEat(p,meat),"carnivore eats meat"); plant:Destroy(); meat:Destroy() end})
table.insert(suite.tests,{name="hunt attack applies species damage and stamina cost",run=function() local p,s=setup(43002); local startingStamina=s.Stamina; local prey=Instance.new("Part"); prey.Position=Vector3.new(5,3,0); prey.Parent=workspace; CollectionService:AddTag(prey,"Damageable"); Assert.truthy(CombatService:RequestAttack(p,"Claw",prey),"server hunt attack succeeds"); Assert.equals(prey:GetAttribute("PendingServerDamage"),7,"hatchling velociraptor claw applies configured damage"); Assert.equals(s.Stamina,startingStamina-10,"claw consumes configured stamina cost"); prey:Destroy() end})
return suite
