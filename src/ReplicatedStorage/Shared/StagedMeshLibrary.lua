local Workspace = game:GetService("Workspace")

local StagedMeshLibrary = {}

StagedMeshLibrary.StagingFolderName = "dinosaur"

-- playable speciesId -> { folder=<diet folder>, name=<staged model name> }. Substitutes where no exact mesh staged.
StagedMeshLibrary.SpeciesMesh = {
    coelophysis   = { folder = "Carnivores (land)", name = "Coelophysis" },
    parasaurolophus = { folder = "Herbivores (land)", name = "Parasaurolophus" },
    utahraptor    = { folder = "Carnivores (land)", name = "Utahraptor" },
    citipati      = { folder = "Omnivores(land)",   name = "Citipati (female)" },
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

-- ---------------------------------------------------------------------------
-- FULL STAGED ROSTER SUPPORT
-- The curated SpeciesMesh table above stays the source of truth for the 8
-- vertical-slice species. The helpers below let ANY staged species resolve to
-- a staged model by enumerating Workspace.dinosaur at runtime and matching on a
-- normalized (lowercased, parenthetical-qualifier/separator-stripped) name.
-- ---------------------------------------------------------------------------

-- Exact diet folder names under Workspace.dinosaur.
StagedMeshLibrary.DietFolders = {
    "Herbivores (land)",
    "Carnivores (land)",
    "Omnivores(land)",
    "Aquatic",
}

local function normalizeName(name)
    if type(name) ~= "string" then
        return ""
    end
    local s = string.lower(name)
    s = string.gsub(s, "%(.-%)", "") -- drop "(male)" / "(female)" / "(Baby)" qualifiers
    s = string.gsub(s, "[^%a%d]", "")
    return s
end
StagedMeshLibrary.normalizeName = normalizeName

local function dietForFolder(folderName)
    if folderName == "Herbivores (land)" then
        return "Herbivore"
    elseif folderName == "Omnivores(land)" then
        return "Omnivore"
    else
        return "Carnivore" -- Carnivores (land) + Aquatic
    end
end

-- Enumerate Workspace.dinosaur diet folders -> normalizedKey -> { folder, name, diet }.
-- Duplicate normalized names collapse to the first model seen. Safe when the staging
-- root is absent (returns an empty table).
function StagedMeshLibrary:BuildFullRoster()
    local roster = {}
    local root = self:StagingRoot()
    if not root then
        return roster
    end
    for _, folderName in ipairs(self.DietFolders) do
        local folder = root:FindFirstChild(folderName)
        if folder then
            local diet = dietForFolder(folderName)
            for _, model in ipairs(folder:GetChildren()) do
                local key = normalizeName(model.Name)
                if key ~= "" and roster[key] == nil then
                    roster[key] = {
                        folder = folderName,
                        name = model.Name,
                        diet = diet,
                    }
                end
            end
        end
    end
    return roster
end

-- Cached live roster (rebuilt lazily; call :RefreshRoster() after staging changes).
local cachedRoster = nil

function StagedMeshLibrary:RefreshRoster()
    cachedRoster = nil
end

local function getRoster(self)
    if cachedRoster and next(cachedRoster) ~= nil then
        return cachedRoster
    end
    cachedRoster = self:BuildFullRoster()
    return cachedRoster
end

-- Resolve ANY staged species to a staged Model instance.
-- Resolution order:
--   1) curated SpeciesMesh mapping (exact key, then normalized key)
--   2) live Workspace.dinosaur roster, matched by normalized name
-- Returns (Model, nil) on success or (nil, reason) on failure, mirroring
-- :ResolveModel's contract so callers can branch the same way.
function StagedMeshLibrary:ResolveAny(speciesId)
    if speciesId == nil then
        return nil, "no_species_id"
    end

    -- 1) curated mapping (exact, then normalized).
    if self.SpeciesMesh[speciesId] then
        return self:ResolveModel(speciesId)
    end
    local target = normalizeName(speciesId)
    for key in pairs(self.SpeciesMesh) do
        if normalizeName(key) == target then
            return self:ResolveModel(key)
        end
    end

    -- 2) live staged roster.
    local root = self:StagingRoot()
    if not root then
        return nil, "no_staging_root"
    end
    local roster = getRoster(self)
    local hit = roster[target]
    if not hit then
        -- second pass: tolerant scan over live names
        for key, rec in pairs(roster) do
            if key == target or normalizeName(rec.name) == target then
                hit = rec
                break
            end
        end
    end
    if not hit then
        return nil, "no_staged_mapping"
    end
    local folder = root:FindFirstChild(hit.folder)
    if not folder then
        return nil, "no_diet_folder"
    end
    local model = folder:FindFirstChild(hit.name)
    if not model then
        return nil, "no_staged_model"
    end
    return model
end

-- True if ANY staged model resolves for this species (curated OR full roster).
function StagedMeshLibrary:HasAnyMesh(speciesId)
    return (self:ResolveAny(speciesId)) ~= nil
end

-- ---------------------------------------------------------------------------
-- Additively populate SpeciesMesh for the FULL staged roster from SpeciesRoster's
-- static name+folder list, so every injected playable species has a { folder, name }
-- mapping (the matrix test asserts SpeciesMesh[speciesId] exists for every playable
-- species). Curated 8 entries are NEVER overwritten. Guarded so headless/tests still
-- load if SpeciesRoster is missing.
-- ---------------------------------------------------------------------------
do
    local ok, roster = pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local shared = ReplicatedStorage:FindFirstChild("Shared")
        if not shared then
            return nil
        end
        local mod = shared:FindFirstChild("SpeciesRoster")
        if not mod then
            return nil
        end
        return require(mod)
    end)
    if ok and roster and roster.StagedSpecies then
        for _, rec in ipairs(roster.StagedSpecies) do
            local id = normalizeName(rec.name)
            if id ~= "" and StagedMeshLibrary.SpeciesMesh[id] == nil then
                StagedMeshLibrary.SpeciesMesh[id] = {
                    folder = rec.folder,
                    name = rec.name,
                }
            end
        end
    end
end

return StagedMeshLibrary
