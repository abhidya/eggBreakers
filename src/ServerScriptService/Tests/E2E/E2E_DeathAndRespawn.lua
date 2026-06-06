local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local SurvivalService = require(game:GetService("ServerScriptService").Services.SurvivalService)
local PlayerDataService = require(game:GetService("ServerScriptService").Services.PlayerDataService)
local suite = { name = "E2E_DeathAndRespawn.server", category = "E2E", tests = {} }

table.insert(suite.tests,{name="death records cause and readable dying state",run=function() local p=MockPlayer.new(48001,"DeathE2E"); local s0=SurvivalService:CreateState(p,"parasaurolophus"); s0.Hatched=true; SurvivalService:ApplyNeedsTick(p,12); SurvivalService:Kill(p,"TestDamage"); local s=SurvivalService:GetState(p); Assert.equals(s.Dead,true,"player dead"); Assert.equals(s.DeathCause,"TestDamage","cause recorded"); Assert.equals(s.DeathState,"Dying","dying state recorded"); Assert.truthy((s.DiedAtAgeSeconds or 0)>=12,"death records age") end})
table.insert(suite.tests,{name="resting advances age and readable sleep before dying",run=function()
    local p=MockPlayer.new(48003,"RestAgeDeathE2E")
    local s=SurvivalService:CreateState(p,"parasaurolophus")
    s.Hatched=true
    s.Health=30
    s.Stamina=0
    local ok=SurvivalService:SetResting(p,true)
    Assert.truthy(ok,"rest starts for hatched living dinosaur")
    Assert.equals(s.Resting,true,"rest flag set")
    Assert.equals(s.SleepState,"Resting","sleep state readable")
    SurvivalService:ApplyNeedsTick(p,5)
    Assert.truthy((s.AgeSeconds or 0)>=5,"resting life still ages")
    Assert.truthy(s.Stamina>0,"rest recovers stamina")
    Assert.truthy(s.Health>30,"rest recovers health when fed and hydrated")
    SurvivalService:Kill(p,"LifecycleTest")
    Assert.equals(s.Resting,false,"death exits rest")
    Assert.equals(s.SleepState,"Dead","sleep state becomes dead")
    Assert.equals(s.DeathState,"Dying","death state remains readable")
    Assert.equals(s.DiedAtAgeSeconds,s.AgeSeconds,"death records current age")
end})
table.insert(suite.tests,{name="respawn resets life account rewards remain",run=function() local p=MockPlayer.new(48002,"RespawnE2E"); local data=PlayerDataService:Get(p); data.DNA=77; SurvivalService:CreateState(p,"utahraptor").Hatched=true; SurvivalService:Kill(p,"Test"); local ns=SurvivalService:Respawn(p); Assert.equals(ns.Dead,false,"respawn alive") ; Assert.equals(ns.Hatched,false,"respawn returns egg") ; Assert.equals(PlayerDataService:Get(p).DNA,77,"account currency remains") end})
return suite
