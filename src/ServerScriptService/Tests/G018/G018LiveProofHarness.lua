local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry = require(script.Parent.UserStoryTestRegistry)

local G018LiveProofHarness = {}

G018LiveProofHarness.ProofFolderName = "G018FinalGateProof"
G018LiveProofHarness.Milestone = "G018FinalGate"

function G018LiveProofHarness:GetProofFolder()
    local folder = ReplicatedStorage:FindFirstChild(self.ProofFolderName)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = self.ProofFolderName
        folder.Parent = ReplicatedStorage
    end
    return folder
end

function G018LiveProofHarness:MarkStoryPass(story, evidence, proofSource, observedAt)
    local folder = self:GetProofFolder()
    folder:SetAttribute(story.liveProof, true)
    folder:SetAttribute(story.id .. "Status", "PASS")
    folder:SetAttribute(story.id .. "Evidence", evidence)
    folder:SetAttribute(story.id .. "ObservedAt", observedAt or os.date("!%Y-%m-%dT%H:%M:%SZ"))
    folder:SetAttribute(story.id .. "ProofSource", proofSource)
    folder:SetAttribute(story.id .. "Milestone", self.Milestone)
end

function G018LiveProofHarness:MarkStoryFail(story, reason, proofSource, observedAt)
    local folder = self:GetProofFolder()
    folder:SetAttribute(story.liveProof, false)
    folder:SetAttribute(story.id .. "Status", "FAIL")
    folder:SetAttribute(story.id .. "Evidence", reason)
    folder:SetAttribute(story.id .. "ObservedAt", observedAt or os.date("!%Y-%m-%dT%H:%M:%SZ"))
    folder:SetAttribute(story.id .. "ProofSource", proofSource)
    folder:SetAttribute(story.id .. "Milestone", self.Milestone)
end

function G018LiveProofHarness:RequiredStories()
    return Registry.all()
end

function G018LiveProofHarness:AssertContractOnly()
    local stories = self:RequiredStories()
    return #stories == 10 and stories[1].id == "US27" and stories[#stories].id == "US36"
end

return G018LiveProofHarness
