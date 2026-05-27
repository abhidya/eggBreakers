local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assert = require(ReplicatedStorage.Shared.TestFramework.Assert)

local StoryAssertions = {}

function StoryAssertions.proofFolder()
    return ReplicatedStorage:FindFirstChild("G016FinalGateProof")
end

function StoryAssertions.proofAttribute(name)
    local folder = StoryAssertions.proofFolder()
    return folder and folder:GetAttribute(name)
end

function StoryAssertions.requireProofTrue(attributeName, expectedDescription)
    Assert.equals(StoryAssertions.proofAttribute(attributeName), true,
        "missing G016FinalGateProof." .. attributeName .. " proof; expected " .. expectedDescription ..
        " from fresh Studio/live play evidence, not docs or source-only assumptions")
end

function StoryAssertions.assertRegistryEnumeratesAllStories(registry)
    local seen = {}
    local stories = registry.all()
    Assert.equals(#stories, 15, "G016 registry must enumerate exactly US01-US15")
    for index, story in ipairs(stories) do
        local expectedId = string.format("US%02d", index)
        Assert.equals(story.id, expectedId, "story order/id contract")
        Assert.falsy(seen[story.id], "duplicate story id " .. tostring(story.id))
        seen[story.id] = true
        Assert.truthy(type(story.title) == "string" and #story.title > 0, story.id .. " title required")
        Assert.truthy(type(story.required) == "table" and #story.required > 0, story.id .. " required categories missing")
        Assert.truthy(type(story.liveProof) == "string" and #story.liveProof > 0, story.id .. " live proof attribute missing")
    end
end

function StoryAssertions.assertStoryHasLivePass(story)
    StoryAssertions.requireProofTrue(story.liveProof, story.id .. " " .. story.title)
    Assert.equals(StoryAssertions.proofAttribute(story.id .. "Status"), "PASS", story.id .. " matrix status must be PASS")
    Assert.truthy(type(StoryAssertions.proofAttribute(story.id .. "Evidence")) == "string",
        story.id .. " must name concrete live/source evidence")
end

return StoryAssertions
