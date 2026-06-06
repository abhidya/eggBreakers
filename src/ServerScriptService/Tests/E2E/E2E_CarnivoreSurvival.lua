local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local CollectionService = game:GetService("CollectionService")
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SpeciesConfig = require(game:GetService("ReplicatedStorage").Shared.SpeciesConfig)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local FoodWaterService = require(game:GetService("ServerScriptService").Services.FoodWaterService)
local CombatService = require(game:GetService("ServerScriptService").Services.CombatService)
local NPCService = require(game:GetService("ServerScriptService").Services.NPCService)
local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)
local suite = { name = "E2E_CarnivoreSurvival.server", category = "E2E", tests = {} }
local function setup(id) local p=MockPlayer.new(id,"CarnE2E"); RateLimitService:ClearPlayer(p); local r=Instance.new("Part"); r.Name="HumanoidRootPart"; r.Position=Vector3.new(0,3,0); local c=Instance.new("Model"); r.Parent=c; p.Character=c; local s=SurvivalService:CreateState(p,"utahraptor"); s.Hatched=true; return p,s end
local function food(diet) local f=Instance.new("Part"); f.Position=Vector3.new(2,3,0); f:SetAttribute("Diet",diet); f:SetAttribute("Nutrition",20); f.Parent=workspace; CollectionService:AddTag(f,"FoodSource"); return f end

table.insert(suite.tests,{name="carnivore rejects plant accepts meat",run=function() local p=setup(43001); local plant=food("Herbivore"); Assert.falsy(FoodWaterService:RequestEat(p,plant),"carnivore rejects plant"); RateLimitService:ClearPlayer(p); local meat=food("Carnivore"); Assert.truthy(FoodWaterService:RequestEat(p,meat),"carnivore eats meat"); plant:Destroy(); meat:Destroy() end})
table.insert(suite.tests,{name="hunt attack applies species damage and stamina cost",run=function() local p,s=setup(43002); local species=SpeciesConfig[s.SpeciesId]; local attack=species.Abilities.PrimaryAttack; local startingStamina=s.Stamina; local prey=Instance.new("Part"); prey.Position=Vector3.new(5,3,0); prey.Parent=workspace; CollectionService:AddTag(prey,"Damageable"); local oldCrit=CombatService.CritChance; CombatService.CritChance=0; local ok,err=pcall(function() Assert.truthy(CombatService:RequestAttack(p,attack,prey),"server hunt attack succeeds"); Assert.equals(prey:GetAttribute("LastServerDamage"),species.BaseStats.Hatchling.Damage,"hatchling utahraptor attack applies configured damage"); Assert.equals(s.Stamina,startingStamina-(CombatService.StaminaCost[attack] or 10),"attack consumes configured stamina cost") end); CombatService.CritChance=oldCrit; prey:Destroy(); if not ok then error(err) end end})
table.insert(suite.tests,{name="predator kills herbivore prey and carnivore eats carcass",run=function()
    local p,state=setup(43003)
    state.Hunger=30
    local predator=Instance.new("Model"); predator.Name="HuntingPredatorNPC"; local predatorRoot=Instance.new("Part"); predatorRoot.Name="HumanoidRootPart"; predatorRoot.Parent=predator; predator.PrimaryPart=predatorRoot; predator:PivotTo(CFrame.new(0,3,0)); predator.Parent=workspace
    local prey=Instance.new("Model"); prey.Name="HerbivoreFoodPreyNPC"; local preyRoot=Instance.new("Part"); preyRoot.Name="HumanoidRootPart"; preyRoot.Parent=prey; prey.PrimaryPart=preyRoot; prey:PivotTo(CFrame.new(6,3,0)); prey.Parent=workspace
    local predatorOk,predatorRecord=NPCService:Register(predator,"Predator")
    local preyOk,preyRecord=NPCService:Register(prey,"Prey")
    Assert.truthy(predatorOk and preyOk,"predator and prey registered")
    predatorRecord.Hatched=true; preyRecord.Hatched=true; preyRecord.Health=20
    Assert.truthy(NPCService:AttackRecord(predatorRecord,preyRecord),"predator attacks herbivore prey")
    Assert.equals(preyRecord.State,"Dead","herbivore prey dies")
    local carcass=preyRecord.Carcass
    Assert.notNil(carcass,"dead herbivore leaves carcass")
    Assert.equals(carcass:GetAttribute("Diet"),"Carnivore","carcass is carnivore food")
    local root=p.Character:FindFirstChild("HumanoidRootPart"); root.Position=carcass:GetPivot().Position+Vector3.new(0,0,-3)
    RateLimitService:ClearPlayer(p)
    local eatOk=FoodWaterService:RequestEat(p,carcass)
    Assert.truthy(eatOk,"carnivore eats herbivore prey carcass")
    Assert.truthy(state.Hunger > 30,"carcass restores carnivore hunger")
    predator:Destroy(); prey:Destroy(); carcass:Destroy()
end})
return suite
