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

local function resolveStagedPath(path)
    local speciesId = string.match(path or "", "^staged://([^/]+)")
    if not speciesId then
        return nil, "not_staged_path"
    end
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local moduleScript = shared and shared:FindFirstChild("StagedMeshLibrary")
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        return nil, "missing_staged_library"
    end
    local okRequire, library = pcall(require, moduleScript)
    if not okRequire or type(library) ~= "table" then
        return nil, "invalid_staged_library"
    end
    local resolver = library.ResolveAny or library.ResolveModel
    if type(resolver) ~= "function" then
        return nil, "invalid_staged_resolver"
    end
    local okResolve, model, reason = pcall(resolver, library, speciesId)
    if okResolve and typeof(model) == "Instance" then
        return model
    end
    return nil, reason or "missing_staged_model"
end

local function resolveConfiguredPath(species, growthStage)
    local configuredPath = species and species.ModelPaths and species.ModelPaths[growthStage]
    if not configuredPath then return nil, "missing_stage_path" end
    if string.sub(configuredPath, 1, 9) == "staged://" then
        return resolveStagedPath(configuredPath)
    end
    return resolvePath(configuredPath)
end

function SpeciesModelService:ResolveModel(speciesId, growthStage, options)
    options = options or {}
    local species = SpeciesConfig[speciesId]
    if not species or not species.ModelPaths then return nil, "missing_species" end
    local configuredPath = species.ModelPaths[growthStage]
    local exact, exactReason = resolveConfiguredPath(species, growthStage)
    if exact then return exact end
    local fallbackId = species.VisualFallbackSpeciesId
    if fallbackId then
        if options.allowVisualFallback ~= false then
            local fallbackSpecies = SpeciesConfig[fallbackId]
            local fallbackModel = resolveConfiguredPath(fallbackSpecies, growthStage)
            if fallbackModel then
                return fallbackModel, "visual_fallback_" .. fallbackId
            end
        end
    end
    if options.requireExact then
        return nil, exactReason or "missing_exact_model"
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
