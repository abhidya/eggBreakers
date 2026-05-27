local UserStoryTestRegistry = {}

UserStoryTestRegistry.Stories = {
    { id = "US27", title = "Small prey categories are visible, edible, and predator-aware", required = { "Unit", "Integration", "E2E", "Placement", "Live" }, liveProof = "US27LiveProofPassed" },
    { id = "US28", title = "Fish schools spawn in valid water and support aquatic hunting", required = { "Integration", "E2E", "Placement", "Live" }, liveProof = "US28LiveProofPassed" },
    { id = "US29", title = "Water integrity prevents floating/dry swim and keeps drink targets valid", required = { "Integration", "Placement", "E2E", "Live" }, liveProof = "US29LiveProofPassed" },
    { id = "US30", title = "Herbivore grazing targets real food and faces action targets", required = { "Integration", "E2E", "Client", "Live" }, liveProof = "US30LiveProofPassed" },
    { id = "US31", title = "Flight stamina gates takeoff, glide, landing, and exhaustion", required = { "Unit", "Integration", "Client", "E2E", "Live" }, liveProof = "US31LiveProofPassed" },
    { id = "US32", title = "Swim oxygen gates diving, surfacing, damage, and recovery", required = { "Unit", "Integration", "Client", "E2E", "Live" }, liveProof = "US32LiveProofPassed" },
    { id = "US33", title = "Apex category events use server authority and readable danger telegraphing", required = { "Integration", "E2E", "Security", "Performance", "Live" }, liveProof = "US33LiveProofPassed" },
    { id = "US34", title = "Herding keeps social species grouped without trapping players", required = { "Integration", "E2E", "Performance", "Live" }, liveProof = "US34LiveProofPassed" },
    { id = "US35", title = "Species stat profiles expose distinct survival roles and growth scaling", required = { "Unit", "Integration", "Client", "Live" }, liveProof = "US35LiveProofPassed" },
    { id = "US36", title = "Omnivore support allows safe plant and meat food paths", required = { "Unit", "Integration", "E2E", "Security", "Live" }, liveProof = "US36LiveProofPassed" },
}

function UserStoryTestRegistry.all()
    return UserStoryTestRegistry.Stories
end

function UserStoryTestRegistry.byId(id)
    for _, story in ipairs(UserStoryTestRegistry.Stories) do
        if story.id == id then
            return story
        end
    end
    return nil
end

return UserStoryTestRegistry
