local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local CollectionService = game:GetService("CollectionService")
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local CityDiscoveryService = require(game:GetService("ServerScriptService").Services.CityDiscoveryService)
local FossilService = require(game:GetService("ServerScriptService").Services.FossilService)
local PlayerDataService = require(game:GetService("ServerScriptService").Services.PlayerDataService)
local RateLimitService = require(game:GetService("ServerScriptService").Services.RateLimitService)
local suite = { name = "E2E_CityDiscovery.server", category = "E2E", tests = {} }
local function rootFor(p) local r=Instance.new("Part"); r.Name="HumanoidRootPart"; r.Position=Vector3.new(0,3,0); local c=Instance.new("Model"); r.Parent=c; p.Character=c end

table.insert(suite.tests,{name="city discovery popup and once reward",run=function() local p=MockPlayer.new(45001,"CityE2E"); PlayerDataService:Get(p); Assert.truthy(CityDiscoveryService:Discover(p,"ApocalypticCity"),"city discovery succeeds"); local ok,reason=CityDiscoveryService:Discover(p,"ApocalypticCity"); Assert.falsy(ok,"city discovery once"); Assert.equals(reason,"already_discovered","repeat reason") end})
table.insert(suite.tests,{name="fossil collection server currency",run=function() local p=MockPlayer.new(45002,"FossilE2E"); PlayerDataService:Get(p); RateLimitService:ClearPlayer(p); rootFor(p); local fossil=Instance.new("Part"); fossil.Position=Vector3.new(3,3,0); fossil:SetAttribute("FossilReward",3); fossil.Parent=workspace; CollectionService:AddTag(fossil,"Fossil"); Assert.truthy(FossilService:RequestCollect(p,fossil),"fossil collect succeeds"); Assert.equals(PlayerDataService:Get(p).Fossils,3,"fossils granted server-side"); fossil:Destroy() end})
return suite
