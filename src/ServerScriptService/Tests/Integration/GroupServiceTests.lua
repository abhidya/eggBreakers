local Assert = require(game:GetService("ReplicatedStorage").Shared.TestFramework.Assert)
local MockPlayer = require(game:GetService("ReplicatedStorage").Shared.TestFramework.MockPlayer)
local GroupService = require(game:GetService("ServerScriptService").Services.GroupService)
local suite = { name = "GroupServiceTests.server", category = "Integration", tests = {} }

table.insert(suite.tests, { name = "invite validation", run = function()
    local p = MockPlayer.new(36001, "GroupTester")
    local ok, reason = GroupService:RequestInvite(p, p)
    Assert.falsy(ok, "mock non-Instance target rejected before invite side effects")
    Assert.equals(reason, "bad_target", "bad target reason")
end })

table.insert(suite.tests, { name = "join leave member list herd pack", run = function()
    local p = MockPlayer.new(36002, "GroupTester2")
    local group = GroupService:CreateOrJoin(p, "Pack")
    Assert.equals(group.Type, "Pack", "group type saved")
    Assert.truthy(group.Members[p], "member added")
    GroupService:Leave(p)
    Assert.falsy(GroupService.PlayerGroup[p], "member left")
end })

return suite
