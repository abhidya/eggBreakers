local G018UserStoryTestRegistry = {}

G018UserStoryTestRegistry.Stories = {
    { id = "G018-US01", title = "Small prey categories drive prey behavior and HUD identity", required = { "Unit", "Integration", "Client", "Live" }, liveProof = "G018US01LiveProofPassed" },
    { id = "G018-US02", title = "Fish schools exist only in valid water volumes", required = { "Integration", "Placement", "Live" }, liveProof = "G018US02LiveProofPassed" },
    { id = "G018-US03", title = "Water integrity tracks shallow/deep safety and oxygen", required = { "Integration", "Placement", "Live" }, liveProof = "G018US03LiveProofPassed" },
    { id = "G018-US04", title = "Herbivore grazing repairs visible food availability", required = { "Integration", "E2E", "Live" }, liveProof = "G018US04LiveProofPassed" },
    { id = "G018-US05", title = "Flight stamina is server-authoritative and HUD-visible", required = { "Unit", "Integration", "Client", "Live" }, liveProof = "G018US05LiveProofPassed" },
    { id = "G018-US06", title = "Swim oxygen drains and recovers server-authoritatively", required = { "Unit", "Integration", "Client", "Live" }, liveProof = "G018US06LiveProofPassed" },
    { id = "G018-US07", title = "Apex category events are gated and observable", required = { "Integration", "E2E", "Live" }, liveProof = "G018US07LiveProofPassed" },
    { id = "G018-US08", title = "Herding groups produce coordinated prey motion", required = { "Integration", "E2E", "Live" }, liveProof = "G018US08LiveProofPassed" },
    { id = "G018-US09", title = "Species stat profiles replicate to UI without client authority", required = { "Unit", "Integration", "Client" }, liveProof = "G018US09LiveProofPassed" },
    { id = "G018-US10", title = "Omnivore support allows both plant and carcass food without weakening herbivore/carnivore gates", required = { "Unit", "Integration", "Security" }, liveProof = "G018US10LiveProofPassed" },
    { id = "G018-US11", title = "G018 final QA preserves G016 release honesty and asset gate", required = { "Security", "Placement", "Performance", "Live" }, liveProof = "G018US11LiveProofPassed" },
}

function G018UserStoryTestRegistry.all()
    return G018UserStoryTestRegistry.Stories
end

function G018UserStoryTestRegistry.byId(id)
    for _, story in ipairs(G018UserStoryTestRegistry.Stories) do
        if story.id == id then
            return story
        end
    end
    return nil
end

return G018UserStoryTestRegistry
