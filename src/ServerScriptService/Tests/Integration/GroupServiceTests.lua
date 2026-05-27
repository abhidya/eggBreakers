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


table.insert(suite.tests, { name = "accept invite joins target to inviter group", run = function()
    local inviter = MockPlayer.new(36003, "Inviter")
    local target = MockPlayer.new(36004, "Invitee")
    GroupService.PendingInvites[target] = { [inviter] = { From = inviter, To = target } }
    local ok, group = GroupService:AcceptInvite(target, inviter)
    Assert.truthy(ok, "invite accepted")
    Assert.truthy(group.Members[inviter], "inviter in group")
    Assert.truthy(group.Members[target], "target joined group")
end })

return suite
