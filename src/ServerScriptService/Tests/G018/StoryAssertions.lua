local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)

local StoryAssertions = {}

function StoryAssertions.proofFolder()
    return ReplicatedStorage:FindFirstChild("G018FinalGateProof")
end

function StoryAssertions.proofAttribute(name)
    local folder = StoryAssertions.proofFolder()
    return folder and folder:GetAttribute(name)
end

function StoryAssertions.requireProofTrue(attributeName, expectedDescription)
    Assert.equals(StoryAssertions.proofAttribute(attributeName), true,
        "missing G018FinalGateProof." .. attributeName .. " proof; expected " .. expectedDescription ..
        " from fresh Studio/live evidence, not docs or source-only assumptions")
end

function StoryAssertions.assertRegistryEnumeratesAllStories(registry)
    local stories = registry.all()
    local seen = {}
    Assert.equals(#stories, 10, "G018 registry must enumerate exactly US27-US36")
    for index, story in ipairs(stories) do
        local expectedId = string.format("US%02d", index + 26)
        Assert.equals(story.id, expectedId, "story order/id contract")
        Assert.falsy(seen[story.id], "duplicate story id " .. tostring(story.id))
        seen[story.id] = true
        Assert.truthy(type(story.title) == "string" and #story.title > 0, story.id .. " title required")
        Assert.truthy(type(story.required) == "table" and #story.required > 0, story.id .. " required categories missing")
        Assert.truthy(type(story.liveProof) == "string" and #story.liveProof > 0, story.id .. " live proof attribute missing")
    end
end

local function assertNonEmptyString(value, message)
    Assert.truthy(type(value) == "string" and #value > 0, message)
end

function StoryAssertions.assertStoryHasLivePass(story)
    StoryAssertions.requireProofTrue(story.liveProof, story.id .. " " .. story.title)
    Assert.equals(StoryAssertions.proofAttribute(story.id .. "Status"), "PASS", story.id .. " matrix status must be PASS")
    assertNonEmptyString(StoryAssertions.proofAttribute(story.id .. "Evidence"), story.id .. " must name concrete live/source evidence")
    assertNonEmptyString(StoryAssertions.proofAttribute(story.id .. "ObservedAt"), story.id .. " must include fresh proof observation timestamp")
    assertNonEmptyString(StoryAssertions.proofAttribute(story.id .. "ProofSource"), story.id .. " must include proof source, such as Studio TestRunner or live play probe")
    Assert.equals(StoryAssertions.proofAttribute(story.id .. "Milestone"), "G018FinalGate", story.id .. " proof milestone must match G018FinalGate")
end

return StoryAssertions
