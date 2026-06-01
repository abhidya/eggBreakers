local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

-- source-pack mappings are direct imported asset roots, kept separate from
-- SpeciesMesh so the logic-only matrix can still describe gameplay diet folders.
StagedMeshLibrary.AssetPackSpecies = {}

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

local function countMeshParts(instance)
    if not instance then
        return 0
    end
    local count = instance:IsA("MeshPart") and 1 or 0
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("MeshPart") then
            count += 1
        end
    end
    return count
end

local function isAssetPackVisualCandidate(instance)
    return instance ~= nil
        and (instance:IsA("Model") or instance:IsA("BasePart"))
        and countMeshParts(instance) > 0
end

function StagedMeshLibrary:StagingRoot()
    local workspaceRoot = Workspace:FindFirstChild(self.StagingFolderName)
    if workspaceRoot then
        return workspaceRoot
    end

    local library = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    if not library then
        return nil
    end
    return library:FindFirstChild(self.StagingFolderName) or library:FindFirstChild("G028_RiggedDinosaurModels_AuditCandidate")
end

function StagedMeshLibrary:FindImportedRoot(rootName)
    if type(rootName) ~= "string" or rootName == "" then
        return nil
    end
    local library = ReplicatedStorage:FindFirstChild("ImportedAssetLibrary")
    if library then
        local direct = library:FindFirstChild(rootName)
        if direct then
            return direct
        end
        local staging = library:FindFirstChild(self.StagingFolderName)
        local nested = staging and staging:FindFirstChild(rootName)
        if nested then
            return nested
        end
    end
    return Workspace:FindFirstChild(rootName)
end

function StagedMeshLibrary:_resolveAssetPackEntry(entry)
    if type(entry) ~= "table" then
        return nil, "no_asset_pack_entry"
    end
    local root = self:FindImportedRoot(entry.sourceFolder or entry.folder)
    if not root then
        return nil, "no_asset_pack_root"
    end
    local sourceName = entry.sourceName or entry.name
    if type(sourceName) ~= "string" or sourceName == "" then
        return nil, "no_asset_pack_source_name"
    end
    local exact = root:FindFirstChild(sourceName)
    if isAssetPackVisualCandidate(exact) then
        return exact
    end
    local deep = root:FindFirstChild(sourceName, true)
    if isAssetPackVisualCandidate(deep) then
        return deep
    end
    local target = normalizeName(sourceName)
    for _, child in ipairs(root:GetDescendants()) do
        if normalizeName(child.Name) == target and isAssetPackVisualCandidate(child) then
            return child
        end
    end
    return nil, "no_mesh_backed_asset_pack_model"
end

function StagedMeshLibrary:ResolveAssetPackModel(speciesId)
    if speciesId == nil then
        return nil, "no_species_id"
    end
    local entry = self.AssetPackSpecies[speciesId]
    local target = normalizeName(speciesId)
    if not entry then
        for key, candidate in pairs(self.AssetPackSpecies) do
            if normalizeName(key) == target then
                entry = candidate
                break
            end
        end
    end
    if not entry then
        return nil, "no_asset_pack_mapping"
    end
    return self:_resolveAssetPackEntry(entry)
end

function StagedMeshLibrary:ResolveModel(speciesId)
    if not speciesId then
        return nil, "no_species_id"
    end
    local assetPackModel = self:ResolveAssetPackModel(speciesId)
    if assetPackModel then
        return assetPackModel
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

    -- 1) imported Creator Store pack mapping. This is the happy path for the
    -- 50+ random hatch roster when the reviewed mesh pack is present.
    local assetPackModel = self:ResolveAssetPackModel(speciesId)
    if assetPackModel then
        return assetPackModel, "asset_pack_dinosaur_mesh"
    end

    -- 2) curated mapping (exact, then normalized).
    if self.SpeciesMesh[speciesId] then
        return self:ResolveModel(speciesId)
    end
    local target = normalizeName(speciesId)
    for key in pairs(self.SpeciesMesh) do
        if normalizeName(key) == target then
            return self:ResolveModel(key)
        end
    end

    -- 3) live staged roster.
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
    local retiredPrototypeSpecies = {
        gallimimus = true,
        triceratops = true,
        velociraptor = true,
        carnotaurus = true,
    }
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
            if id ~= "" and StagedMeshLibrary.SpeciesMesh[id] == nil and not retiredPrototypeSpecies[id] then
                StagedMeshLibrary.SpeciesMesh[id] = {
                    folder = rec.folder,
                    name = rec.name,
                }
            end
        end
        for _, rec in ipairs(roster.SupplementalAssetSpecies or {}) do
            local id = normalizeName(rec.name)
            if id ~= "" and not retiredPrototypeSpecies[id] then
                StagedMeshLibrary.AssetPackSpecies[id] = {
                    folder = rec.folder,
                    name = rec.name,
                    sourceFolder = rec.sourceFolder,
                    sourceName = rec.sourceName or rec.name,
                    sourceAssetId = rec.sourceAssetId,
                }
                if StagedMeshLibrary.SpeciesMesh[id] == nil then
                    StagedMeshLibrary.SpeciesMesh[id] = {
                        folder = rec.folder,
                        name = rec.name,
                    }
                end
            end
        end
    end
end

return StagedMeshLibrary
