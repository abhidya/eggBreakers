local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local ProgressionService = require(game:GetService("ServerScriptService").Services.ProgressionService)
local suite = { name = "E2E_GrowthToJuvenile.server", category = "E2E", tests = {} }

table.insert(suite.tests,{name="server accelerated growth reaches juvenile",run=function() local p=MockPlayer.new(44001,"GrowE2E"); local s=SurvivalService:CreateState(p,"gallimimus"); s.Hatched=true; Assert.truthy(SurvivalService:AddGrowth(p,25),"server-only growth accepted"); Assert.equals(s.GrowthStage,"Juvenile","juvenile reached") end})
table.insert(suite.tests,{name="model scale stats reward popup",run=function() local p=MockPlayer.new(44002,"GrowRewardE2E"); local s=SurvivalService:CreateState(p,"triceratops"); s.Hatched=true; SurvivalService:AddGrowth(p,25); Assert.equals(s.Health,95,"juvenile stats applied"); Assert.truthy(ProgressionService:OnGrowthStage(p,"Juvenile"),"juvenile reward fires once") end})
return suite
