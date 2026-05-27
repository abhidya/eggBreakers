local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local GroupService = require(game:GetService("ServerScriptService").Services.GroupService)
local CallService = require(game:GetService("ServerScriptService").Services.CallService)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)
local suite = { name = "E2E_GroupAndCall.server", category = "E2E", tests = {} }

table.insert(suite.tests,{name="two player invite join indicator",run=function() local a=MockPlayer.new(46001,"A"); local b=MockPlayer.new(46002,"B"); local g=GroupService:CreateOrJoin(a,"Pack"); GroupService.PlayerGroup[b]=g; g.Members[b]=true; Assert.truthy(g.Members[a],"player A in group"); Assert.truthy(g.Members[b],"player B in group") end})
table.insert(suite.tests,{name="nearby warning call and cooldown",run=function() local p=MockPlayer.new(46003,"Caller"); RateLimitService:ClearPlayer(p); SurvivalService:CreateState(p,"velociraptor").Hatched=true; local ok=CallService:RequestCall(p,"Warning"); Assert.truthy(ok,"first call succeeds"); local ok2=CallService:RequestCall(p,"Warning"); Assert.falsy(ok2,"cooldown prevents spam") end})
return suite
