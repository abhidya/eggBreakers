local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local args = process.args

local function usage()
	error("usage: lune run tools/g016_release_ready_inventory.luau <place.rbxl> [<place.rbxl> ...]", 0)
end

if #args == 0 then
	usage()
end

local IMPORTED_LIBRARY_NAME = "ImportedAssetLibrary"

local LOW_QUALITY_NAME_PATTERNS = {
	"food[%s_%-]*ball",
	"glow[%w%s_%-]*ball",
	"glowing[%w%s_%-]*ball",
	"ball[%s_%-]*tree",
	"rectangle[%w%s_%-]*tree",
	"rectangle[%w%s_%-]*ball[%w%s_%-]*tree",
	"simple[%s_%-]*generated",
	"debug[%s_%-]*fallback",
	"placeholder",
}

local function attrs(instance)
	local ok, result = pcall(function()
		return instance:GetAttributes()
	end)
	if ok and result then
		return result
	end
	return {}
end

local function attr(instance, name)
	return attrs(instance)[name]
end

local function meaningfulSourceId(value)
	if value == nil then
		return nil
	end
	local text = tostring(value)
	if text == "" or text == "-1" or text == "0" then
		return nil
	end
	return text
end

local function fullName(instance)
	local ok, value = pcall(function()
		return instance:GetFullName()
	end)
	if ok then
		return value
	end

	local parts = {}
	local current = instance
	while current do
		table.insert(parts, 1, current.Name)
		current = current.Parent
	end
	return table.concat(parts, ".")
end

local function isTaggedImport(instance)
	return meaningfulSourceId(attr(instance, "SourceAssetId")) ~= nil
		or attr(instance, "AssetManifestId") ~= nil
		or attr(instance, "ImportedVisibleAsset") == true
		or attr(instance, "CreatorStoreOnly") == true
end

local function isBasePart(instance)
	return instance:IsA("BasePart")
end

local function isVisibleImportedAsset(instance)
	if isBasePart(instance) then
		return instance.Transparency < 1
	end
	if not instance:IsA("Model") and not instance:IsA("Folder") then
		return false
	end
	for _, descendant in ipairs(instance:GetDescendants()) do
		if isBasePart(descendant) and descendant.Transparency < 1 then
			return true
		end
	end
	return false
end

local function normalizeQualityExclusionKind(value)
	if value == nil then
		return nil
	end
	local text = string.lower(tostring(value))
	if text == "mesh" or text == "mesh-only" or text == "mesh_exclusion" then return "mesh" end
	if text == "lq" or text == "low-quality" or text == "lowquality" or text == "simple-generated" then return "lowQuality" end
	if text == "debug" or text == "debug-looking" then return "debug" end
	return text
end

local function nameLooksLowQuality(instance)
	local text = string.lower(instance.Name or "")
	for _, pattern in ipairs(LOW_QUALITY_NAME_PATTERNS) do
		if string.find(text, pattern) then
			return true
		end
	end
	return false
end

local function nameHasStandaloneBallToken(instance)
	local text = string.lower(instance.Name or "")
	if text == "ball" then return true end
	if string.find(text, "^ball[%s_%-_]") then return true end
	if string.find(text, "[%s_%-_]ball$") then return true end
	if string.find(text, "[%s_%-_]ball[%s_%-_]") then return true end
	return false
end

local function isGlowingBallPart(instance)
	if not isBasePart(instance) then return false end
	if not nameHasStandaloneBallToken(instance) and not (instance.ClassName == "Part" and tostring(instance.Shape) == "Ball") then
		return false
	end
	if tostring(instance.Material) == "Neon" then return true end
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
			return true
		end
	end
	return false
end

local function instanceNameContains(instance, token)
	return string.find(string.lower(instance.Name or ""), token, 1, true) ~= nil
end

local function isPartShape(instance, shape)
	return instance.ClassName == "Part" and tostring(instance.Shape) == shape
end

local function looksLikeRectangleBallTree(instance)
	if not instanceNameContains(instance, "tree") then return false end
	local hasBlock = false
	local hasBall = false
	local function visit(part)
		hasBlock = hasBlock or isPartShape(part, "Block")
		hasBall = hasBall or isPartShape(part, "Ball")
	end
	visit(instance)
	for _, descendant in ipairs(instance:GetDescendants()) do
		visit(descendant)
	end
	return hasBlock and hasBall
end

local function looksLowQualityGeneratedFoodOrVegetation(instance)
	if nameLooksLowQuality(instance) or isGlowingBallPart(instance) or looksLikeRectangleBallTree(instance) then
		return true
	end
	for _, descendant in ipairs(instance:GetDescendants()) do
		if nameLooksLowQuality(descendant) or isGlowingBallPart(descendant) then
			return true
		end
	end
	return false
end

local function qualityExclusionKind(instance)
	if looksLowQualityGeneratedFoodOrVegetation(instance) then
		return "lowQuality"
	end
	local current = instance
	while current do
		local kind = normalizeQualityExclusionKind(attr(current, "AssetQualityExclusionKind"))
		if kind then return kind end
		if attr(current, "LowQualityAsset") == true or attr(current, "AssetQualityExcluded") == true then
			return "lowQuality"
		end
		if attr(current, "MeshExcludedAsset") == true then
			return "mesh"
		end
		if attr(current, "DebugOnly") == true or attr(current, "DebugFallbackVisual") == true then
			return "debug"
		end
		current = current.Parent
	end
	return nil
end

local function isScriptInstance(instance)
	return instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript")
end

local function isExecutableScript(instance)
	return instance:IsA("Script") or instance:IsA("LocalScript")
end

local function hasStringAttribute(instance, attributeName)
	local value = attr(instance, attributeName)
	return type(value) == "string" and value ~= ""
end

local function hasAncestorAttribute(instance, attributeName, expectedValue)
	local current = instance
	while current do
		local value = attr(current, attributeName)
		if expectedValue == nil then
			if value ~= nil then return true end
		elseif value == expectedValue then
			return true
		end
		current = current.Parent
	end
	return false
end

local function isRawScriptReviewQueue(instance)
	return hasAncestorAttribute(instance, "RawImportedScriptPreserved", true)
		or hasAncestorAttribute(instance, "G032RawScriptPreserved", true)
		or hasAncestorAttribute(instance, "ImportedScriptReviewQueue", true)
		or hasAncestorAttribute(instance, "ScriptReviewStatus", "raw_preserved_pending_adaptation")
end

local function isReviewedAdaptedStampedScript(instance)
	local reviewed = attr(instance, "ImportedScriptAudited") == true
		or attr(instance, "ReviewedImportedScript") == true
	local adapted = (
			attr(instance, "ImportedScriptAdapted") == true
			or attr(instance, "AdaptedIntoEggBreakers") == true
		)
		and hasStringAttribute(instance, "ScriptAdaptedTo")
	local stamped = attr(instance, "ImportedScriptStamped") == true
		and hasStringAttribute(instance, "ScriptAuditPurpose")
		and hasStringAttribute(instance, "ScriptSandboxStatus")
		and hasStringAttribute(instance, "ImportedScriptOwner")
		and attr(instance, "ScriptAuditDecision") == "keep"
		and attr(instance, "ScriptAuditScope") == "G032"
	return reviewed and adapted and stamped
end

local function isReleaseReadyScript(instance)
	if isExecutableScript(instance) then
		return isReviewedAdaptedStampedScript(instance)
	end
	return instance:IsA("ModuleScript")
		and isReviewedAdaptedStampedScript(instance)
		and attr(instance, "Sandboxed") == true
end

local function hasBlockingScript(instance)
	local scriptsPresent = false
	for _, descendant in ipairs(instance:GetDescendants()) do
		if isScriptInstance(descendant) and attr(descendant, "ImportedScriptQuarantined") ~= true then
			if not isRawScriptReviewQueue(descendant) and not isReleaseReadyScript(descendant) then
				scriptsPresent = true
			elseif isRawScriptReviewQueue(descendant) and not isReleaseReadyScript(descendant) then
				scriptsPresent = true
			end
		end
	end
	return scriptsPresent
end

local function childByPath(root, path)
	local current = root
	for _, name in ipairs(path) do
		if not current then
			return nil
		end
		current = current:FindFirstChild(name)
	end
	return current
end

local function collectServiceRoots(dataModel)
	local replicatedStorage = dataModel:FindFirstChild("ReplicatedStorage")
	local workspace = dataModel:FindFirstChild("Workspace")
	local roots = {}
	local library = replicatedStorage and replicatedStorage:FindFirstChild(IMPORTED_LIBRARY_NAME)
	if library then
		table.insert(roots, { root = library, location = "ReplicatedStorage/" .. IMPORTED_LIBRARY_NAME })
	end
	local workspaceImported = workspace and childByPath(workspace, { "Map", "ImportedAssets" })
	if workspaceImported then
		table.insert(roots, { root = workspaceImported, location = "Workspace/Map/ImportedAssets" })
	end
	return roots
end

local function collectReleaseReady(path)
	if not fs.isFile(path) then
		error(`input file does not exist: {path}`, 0)
	end

	local dataModel = roblox.deserializePlace(fs.readFile(path))
	local bySourceId = {}
	local records = {}

	for _, rootInfo in ipairs(collectServiceRoots(dataModel)) do
		local candidates = {}
		if isTaggedImport(rootInfo.root) then
			table.insert(candidates, rootInfo.root)
		end
		for _, descendant in ipairs(rootInfo.root:GetDescendants()) do
			if isTaggedImport(descendant) then
				table.insert(candidates, descendant)
			end
		end

		for _, instance in ipairs(candidates) do
			local sourceAssetId = meaningfulSourceId(attr(instance, "SourceAssetId"))
			local tagged = sourceAssetId ~= nil
				and attr(instance, "AssetManifestId") ~= nil
				and attr(instance, "CreatorStoreOnly") == true
			local visible = isVisibleImportedAsset(instance)
			local excluded = qualityExclusionKind(instance) ~= nil
			local scriptsPresent = hasBlockingScript(instance)
			if tagged and visible and not scriptsPresent and not excluded and not bySourceId[sourceAssetId] then
				local record = {
					sourceAssetId = sourceAssetId,
					assetManifestId = tostring(attr(instance, "AssetManifestId")),
					className = instance.ClassName,
					name = instance.Name,
					path = fullName(instance),
					rootLocation = rootInfo.location,
				}
				bySourceId[sourceAssetId] = record
				table.insert(records, record)
			end
		end
	end

	table.sort(records, function(left, right)
		return left.sourceAssetId < right.sourceAssetId
	end)
	return records
end

for _, path in ipairs(args) do
	local records = collectReleaseReady(path)
	print(`# release-ready inventory: {path}`)
	print(`count={#records}`)
	for _, record in ipairs(records) do
		print(`{record.sourceAssetId}\t{record.assetManifestId}\t{record.rootLocation}\t{record.className}\t{record.path}`)
	end
end
