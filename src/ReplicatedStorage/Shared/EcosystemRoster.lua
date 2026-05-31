local Workspace = game:GetService("Workspace")

-- EcosystemRoster
-- Enumerates every rigged dinosaur model staged under Workspace.dinosaur's diet folders at
-- RUNTIME and returns a flat roster describing each species. This lets NPCSpawnService spawn the
-- whole 56-species ecosystem as living NPCs (not just the ~9 fixed playable kinds).
--
-- The roster is derived purely from what is present in the world, so it is fully world-absent
-- safe: when Workspace.dinosaur is missing (e.g. headless tests, world not yet populated) every
-- query returns an empty roster / nil resolution instead of erroring.
local EcosystemRoster = {}

-- Where the staged dinosaur models live (matches StagedMeshLibrary.StagingFolderName).
EcosystemRoster.StagingFolderName = "dinosaur"

-- Diet folder name -> { diet = <Herbivore/Carnivore/Omnivore>, aquatic = <bool> }.
-- Aquatic species have no herbivore/omnivore meaning in this slice, so they map to Carnivore
-- with an aquatic flag (per the ownership spec: "Aquatic -> Carnivore + aquatic flag").
EcosystemRoster.DietFolders = {
    ["Herbivores (land)"] = { diet = "Herbivore", aquatic = false },
    ["Carnivores (land)"] = { diet = "Carnivore", aquatic = false },
    ["Omnivores(land)"]   = { diet = "Omnivore",  aquatic = false },
    ["Aquatic"]           = { diet = "Carnivore", aquatic = true },
}

-- Deterministic iteration order for the diet folders (pairs() order is unspecified).
EcosystemRoster.DietFolderOrder = {
    "Herbivores (land)",
    "Carnivores (land)",
    "Omnivores(land)",
    "Aquatic",
}

function EcosystemRoster:StagingRoot()
    return Workspace:FindFirstChild(self.StagingFolderName)
end

local function hasVisiblePart(instance)
    if not instance then return false end
    if instance:IsA("BasePart") and instance.Transparency < 1 then return true end
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Transparency < 1 then return true end
    end
    return false
end

-- Build a {speciesId, ...} style identifier from a model name so downstream services have a
-- stable, attribute-friendly token (lowercased, alphanumerics + underscores).
local function toSpeciesId(name)
    local id = string.lower(name)
    id = string.gsub(id, "[^%w]+", "_")
    id = string.gsub(id, "^_+", "")
    id = string.gsub(id, "_+$", "")
    if id == "" then id = "species" end
    return id
end

-- Enumerate every model under each diet folder of Workspace.dinosaur.
-- Returns an array of entries:
--   {
--     speciesName = <model.Name>,
--     speciesId   = <stable token derived from name>,
--     dietFolder  = <diet folder name>,
--     diet        = "Herbivore" | "Carnivore" | "Omnivore",
--     aquatic     = <bool>,
--     sourceModel = <the staged Model/Instance to clone>,
--   }
-- Safe when Workspace.dinosaur is absent (returns {}).
function EcosystemRoster:GetRoster(opts)
    opts = opts or {}
    local requireVisible = opts.requireVisible ~= false -- default: only visible-bodied models
    local roster = {}

    local root = self:StagingRoot()
    if not root then
        return roster
    end

    for _, folderName in ipairs(self.DietFolderOrder) do
        local meta = self.DietFolders[folderName]
        local folder = root:FindFirstChild(folderName)
        if folder and meta then
            for _, child in ipairs(folder:GetChildren()) do
                local isSpawnable = child:IsA("Model") or child:IsA("BasePart")
                if isSpawnable and (not requireVisible or hasVisiblePart(child)) then
                    table.insert(roster, {
                        speciesName = child.Name,
                        speciesId = toSpeciesId(child.Name),
                        dietFolder = folderName,
                        diet = meta.diet,
                        aquatic = meta.aquatic == true,
                        sourceModel = child,
                    })
                end
            end
        end
    end

    return roster
end

-- Resolve a single roster entry by its staged model name (exact match first, then
-- case-insensitive). Returns the entry table or nil.
function EcosystemRoster:ResolveByName(name)
    if not name then return nil end
    local roster = self:GetRoster({ requireVisible = false })
    for _, entry in ipairs(roster) do
        if entry.speciesName == name then
            return entry
        end
    end
    local lowered = string.lower(name)
    for _, entry in ipairs(roster) do
        if string.lower(entry.speciesName) == lowered then
            return entry
        end
    end
    return nil
end

-- Convenience: how many distinct staged species are currently enumerable. 0 when world absent.
function EcosystemRoster:Count()
    return #self:GetRoster()
end

return EcosystemRoster
