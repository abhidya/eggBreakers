local UserStoryTestRegistry = {}

UserStoryTestRegistry.Stories = {
    { id = "US01", title = "Hatch from egg", required = { "Unit", "Integration", "E2E", "Client", "Live" }, liveProof = "US01LiveProofPassed" },
    { id = "US02", title = "Dinosaur identity and diet are obvious after hatch", required = { "Unit", "Integration", "E2E", "Client", "Placement", "Live" }, liveProof = "US02LiveProofPassed" },
    { id = "US03", title = "Herbivore eats visible plant food", required = { "Unit", "Integration", "E2E", "Client", "Placement", "Live" }, liveProof = "US03LiveProofPassed" },
    { id = "US04", title = "Carnivore eats visible meat/carcass", required = { "Unit", "Integration", "E2E", "Client", "Placement", "Live" }, liveProof = "US04LiveProofPassed" },
    { id = "US05", title = "Dinosaur drinks visible water", required = { "Unit", "Integration", "E2E", "Client", "Placement", "Live" }, liveProof = "US05LiveProofPassed" },
    { id = "US06", title = "Hunger/thirst/stamina/growth live loop works", required = { "Unit", "Integration", "E2E", "Client", "Live" }, liveProof = "US06LiveProofPassed" },
    { id = "US07", title = "Combat applies real server damage", required = { "Unit", "Integration", "E2E", "Client", "Security", "Live" }, liveProof = "US07LiveProofPassed" },
    { id = "US08", title = "NPC ecosystem uses visible imported creatures", required = { "Integration", "E2E", "Placement", "Live" }, liveProof = "US08LiveProofPassed" },
    { id = "US09", title = "Old Eden city/fossil discovery works", required = { "Integration", "E2E", "Placement", "Live" }, liveProof = "US09LiveProofPassed" },
    { id = "US10", title = "Group and calls work with visible feedback", required = { "Unit", "Integration", "E2E", "Client", "Live" }, liveProof = "US10LiveProofPassed" },
    { id = "US11", title = "Nesting works with imported nest", required = { "Unit", "Integration", "E2E", "Client", "Placement", "Live" }, liveProof = "US11LiveProofPassed" },
    { id = "US12", title = "Death at 0 health and respawn persistence work", required = { "Unit", "Integration", "E2E", "Client", "Live" }, liveProof = "US12LiveProofPassed" },
    { id = "US13", title = "Client UI/mobile/controller controls can play game", required = { "Client", "E2E", "Live", "Mobile" }, liveProof = "US13LiveProofPassed" },
    { id = "US14", title = "Asset materialization honesty reaches 500 release-ready imports", required = { "Security", "Placement", "E2E", "Live" }, liveProof = "US14LiveProofPassed" },
    { id = "US15", title = "Fresh full QA gate proves all stories", required = { "Unit", "Integration", "Placement", "E2E", "Security", "Performance", "Client", "Live" }, liveProof = "US15LiveProofPassed" },
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
