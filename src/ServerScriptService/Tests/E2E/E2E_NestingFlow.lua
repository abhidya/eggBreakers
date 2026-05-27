local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local CollectionService = game:GetService("CollectionService")
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local NestService = require(game:GetService("ServerScriptService").Services.NestService)
local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)
local suite = { name = "E2E_NestingFlow.server", category = "E2E", tests = {} }
local function setup(id,stage) local p=MockPlayer.new(id,"NestE2E"); RateLimitService:ClearPlayer(p); local s=SurvivalService:CreateState(p,"triceratops"); s.Hatched=true; s.GrowthStage=stage; local r=Instance.new("Part"); r.Name="HumanoidRootPart"; r.Position=Vector3.new(0,3,0); local c=Instance.new("Model"); r.Parent=c; p.Character=c; local n=Instance.new("Part"); n.Position=Vector3.new(3,3,0); n.Parent=workspace; CollectionService:AddTag(n,"NestZone"); return p,n end

table.insert(suite.tests,{name="adult creates nest state",run=function() local p,n=setup(47001,"Adult"); Assert.truthy(NestService:RequestNestAction(p,"Create",n),"adult nest succeeds"); Assert.notNil(NestService.Nests[p],"nest state exists"); n:Destroy() end})
table.insert(suite.tests,{name="non adult nest fails",run=function() local p,n=setup(47002,"Juvenile"); local ok,reason=NestService:RequestNestAction(p,"Create",n); Assert.falsy(ok,"non-adult rejected"); Assert.equals(reason,"not_adult","non adult reason"); n:Destroy() end})
return suite
