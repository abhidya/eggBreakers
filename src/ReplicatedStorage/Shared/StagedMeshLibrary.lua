local Workspace = game:GetService("Workspace")

local StagedMeshLibrary = {}

StagedMeshLibrary.StagingFolderName = "dinosaur"

-- playable speciesId -> { folder=<diet folder>, name=<staged model name> }. Substitutes where no exact mesh staged.
StagedMeshLibrary.SpeciesMesh = {
    gallimimus    = { folder = "Carnivores (land)", name = "Coelophysis" },
    triceratops   = { folder = "Herbivores (land)", name = "Triceratops" },
    velociraptor  = { folder = "Carnivores (land)", name = "Utahraptor" },
    carnotaurus   = { folder = "Carnivores (land)", name = "Carnotaurus" },
    tyrannosaurus = { folder = "Carnivores (land)", name = "Tyrannosaurus" },
    oviraptor     = { folder = "Omnivores(land)",   name = "Citipati (male)" },
    pteranodon    = { folder = "Carnivores (land)", name = "Quetzalcoatlus" },
    spinosaurus   = { folder = "Carnivores (land)", name = "Spinosaurus" },
}

function StagedMeshLibrary:StagingRoot()
    return Workspace:FindFirstChild(self.StagingFolderName)
end

function StagedMeshLibrary:ResolveModel(speciesId)
    if not speciesId then
        return nil, "no_species_id"
    end
    local entry = self.SpeciesMesh[speciesId]
    if not entry then
        return nil, "no_staged_mapping"
    end
    local root = self:StagingRoot()
    if not root then
        return nil, "no_staging_root"
    end
    local folder = root:FindFirstChild(entry.folder)
    if not folder then
        return nil, "no_diet_folder"
    end
    local model = folder:FindFirstChild(entry.name)
    if not model then
        return nil, "no_staged_model"
    end
    return model
end

function StagedMeshLibrary:HasMesh(speciesId)
    return (self:ResolveModel(speciesId)) ~= nil
end

return StagedMeshLibrary
