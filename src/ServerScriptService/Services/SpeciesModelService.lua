local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpeciesConfig = require(ReplicatedStorage.Shared.SpeciesConfig)

local SpeciesModelService = {}
SpeciesModelService.RequiredStages = { "Hatchling", "Juvenile", "SubAdult", "Adult" }

local function resolvePath(path)
    local current = game
    for segment in string.gmatch(path, "[^/]+") do
        current = current:FindFirstChild(segment)
        if not current then return nil end
    end
    return current
end

function SpeciesModelService:ResolveModel(speciesId, growthStage, options)
    options = options or {}
    local species = SpeciesConfig[speciesId]
    if not species or not species.ModelPaths then return nil, "missing_species" end
    local configuredPath = species.ModelPaths[growthStage]
    if not configuredPath then return nil, "missing_stage_path" end
    local exact = resolvePath(configuredPath)
    if exact then return exact end
    if options.requireExact then
        return nil, "missing_exact_model"
    end
    local rootPath = string.match(configuredPath, "(.+)/[^/]+$")
    local root = rootPath and resolvePath(rootPath)
    if root then return root, "stage_fallback_root" end
    return nil, "missing_model"
end

function SpeciesModelService:ValidateConfiguredModels(options)
    options = options or {}
    local failures = {}
    for speciesId in pairs(SpeciesConfig) do
        for _, stage in ipairs(self.RequiredStages) do
            local model, reason = self:ResolveModel(speciesId, stage, { requireExact = options.requireExact == true })
            if not model then
                table.insert(failures, speciesId .. "/" .. stage .. " model missing: " .. tostring(reason))
            end
        end
    end
    return { passed = #failures == 0, failures = failures }
end

return SpeciesModelService
