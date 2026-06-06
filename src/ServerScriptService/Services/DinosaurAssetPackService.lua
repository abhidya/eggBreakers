local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ImportedScriptPolicy = require(ReplicatedStorage.Shared.ImportedScriptPolicy)

local DinosaurAssetPackService = {}

DinosaurAssetPackService.LibraryName = "ImportedAssetLibrary"

DinosaurAssetPackService.Packs = {
    {
        AssetId = 8289268262,
        RootName = "G033_DinosaurMeshes_8289268262",
        AssetManifestId = "G033_DinosaurMeshes_8289268262",
        ImportedVisibleAsset = true,
        DinosaurRosterPack = true,
        UseAsDinoVisualHappyPath = true,
        PlacementRole = "DinosaurRosterMeshPack",
        ScriptReviewSourceUse = "g033_dinosaur_mesh_pack",
    },
    {
        AssetId = 10737775518,
        RootName = "G033_DinosaurNPCPack_50PlusCandidate",
        AssetManifestId = "G033_DinosaurNPCPack_50PlusCandidate",
        ImportedVisibleAsset = true,
        DinosaurRosterPack = true,
        UseAsDinoVisualHappyPath = true,
        PlacementRole = "DinosaurNPCScriptReviewPack",
        ScriptReviewSourceUse = "g033_dinosaur_npc_pack_review",
    },
}

local function countMeshParts(instance)
    local count = instance:IsA("MeshPart") and 1 or 0
    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant:IsA("MeshPart") then
            count += 1
        end
    end
    return count
end

local function countScripts(instance)
    local count = 0
    for _, descendant in ipairs(instance:GetDescendants()) do
        if ImportedScriptPolicy.IsScriptContainer(descendant) then
            count += 1
        end
    end
    return count
end

function DinosaurAssetPackService:EnsureLibrary()
    local library = ReplicatedStorage:FindFirstChild(self.LibraryName)
    if not library then
        library = Instance.new("Folder")
        library.Name = self.LibraryName
        library.Parent = ReplicatedStorage
    end
    return library
end

function DinosaurAssetPackService:StampPackRoot(root, pack)
    root:SetAttribute("SourceAssetId", tostring(pack.AssetId))
    root:SetAttribute("AssetManifestId", pack.AssetManifestId)
    root:SetAttribute("CreatorStoreOnly", true)
    root:SetAttribute("ImportedVisibleAsset", pack.ImportedVisibleAsset == true)
    root:SetAttribute("DinosaurRosterPack", pack.DinosaurRosterPack == true)
    root:SetAttribute("UseAsDinoVisualHappyPath", pack.UseAsDinoVisualHappyPath == true)
    root:SetAttribute("PlacementRole", pack.PlacementRole)
    root:SetAttribute("AssetPackAutoLoadEnabled", true)
    root:SetAttribute("AssetPackAutoLoadedBy", "DinosaurAssetPackService")
    if pack.PrimitivePartOnlyPack then
        root:SetAttribute("PrimitivePartOnlyPack", true)
    end
end

function DinosaurAssetPackService:StampPackContents(root, pack)
    self:StampPackRoot(root, pack)
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:GetAttribute("SourceAssetId") == nil then
            descendant:SetAttribute("SourceAssetId", tostring(pack.AssetId))
        end
        if descendant:GetAttribute("AssetManifestId") == nil then
            descendant:SetAttribute("AssetManifestId", pack.AssetManifestId)
        end
        if descendant:GetAttribute("CreatorStoreOnly") == nil then
            descendant:SetAttribute("CreatorStoreOnly", true)
        end
        if ImportedScriptPolicy.IsScriptContainer(descendant) then
            if ImportedScriptPolicy.IsExecutableScript(descendant) then
                descendant.Disabled = true
            end
            ImportedScriptPolicy.StampRawReviewRoot(descendant, pack.ScriptReviewSourceUse)
            ImportedScriptPolicy.StampRawReviewRoot(root, pack.ScriptReviewSourceUse)
        elseif descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = true
        end
    end
    root:SetAttribute("MeshPartCount", countMeshParts(root))
    root:SetAttribute("SourceScriptCount", countScripts(root))
end

function DinosaurAssetPackService:LoadPack(pack, library)
    local loaded = InsertService:LoadAsset(pack.AssetId)
    local root = Instance.new("Folder")
    root.Name = pack.RootName
    for _, child in ipairs(loaded:GetChildren()) do
        child.Parent = root
    end
    loaded:Destroy()
    self:StampPackContents(root, pack)
    root.Parent = library
    return root
end

function DinosaurAssetPackService:EnsurePack(pack)
    local library = self:EnsureLibrary()
    local existing = library:FindFirstChild(pack.RootName)
    if existing then
        self:StampPackContents(existing, pack)
        return true, existing, "existing"
    end

    local ok, rootOrErr = pcall(function()
        return self:LoadPack(pack, library)
    end)
    if ok then
        return true, rootOrErr, "loaded"
    end
    warn(("[eggBreakers] Failed to load dinosaur asset pack %s (%s): %s"):format(pack.RootName, tostring(pack.AssetId), tostring(rootOrErr)))
    return false, nil, tostring(rootOrErr)
end

function DinosaurAssetPackService:EnsureDinosaurPacks()
    local results = {}
    for _, pack in ipairs(self.Packs) do
        local ok, root, status = self:EnsurePack(pack)
        table.insert(results, {
            ok = ok,
            status = status,
            rootName = pack.RootName,
            assetId = pack.AssetId,
            meshParts = root and countMeshParts(root) or 0,
            scripts = root and countScripts(root) or 0,
        })
    end
    return results
end

return DinosaurAssetPackService
