local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local PlayerDataService = require(game:GetService("ServerScriptService").Services.PlayerDataService)
local suite = { name = "E2E_DeathAndRespawn.server", category = "E2E", tests = {} }

table.insert(suite.tests,{name="death records cause and screen",run=function() local p=MockPlayer.new(48001,"DeathE2E"); SurvivalService:CreateState(p,"gallimimus").Hatched=true; SurvivalService:Kill(p,"TestDamage"); local s=SurvivalService:GetState(p); Assert.equals(s.Dead,true,"player dead"); Assert.equals(s.DeathCause,"TestDamage","cause recorded") end})
table.insert(suite.tests,{name="respawn resets life account rewards remain",run=function() local p=MockPlayer.new(48002,"RespawnE2E"); local data=PlayerDataService:Get(p); data.DNA=77; SurvivalService:CreateState(p,"velociraptor").Hatched=true; SurvivalService:Kill(p,"Test"); local ns=SurvivalService:Respawn(p); Assert.equals(ns.Dead,false,"respawn alive") ; Assert.equals(ns.Hatched,false,"respawn returns egg") ; Assert.equals(PlayerDataService:Get(p).DNA,77,"account currency remains") end})
return suite
