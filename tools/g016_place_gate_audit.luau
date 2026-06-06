local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local args = process.args

local function usage()
	error("usage: lune run tools/g016_place_gate_audit.luau <place.rbxl> [<place.rbxl> ...]", 0)
end

if #args == 0 then
	usage()
end

local REQUIRED_RELEASE_ASSETS = 500
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

local function addUnique(set, value)
	local sourceId = meaningfulSourceId(value)
	if sourceId then
		set[sourceId] = true
	end
end

local function setSize(set)
	local count = 0
	for _ in pairs(set) do
		count += 1
	end
	return count
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

local function pathContains(path, fragment)
	return string.find(path, fragment, 1, true) ~= nil
end

local function isTaggedImport(instance)
	local sourceId = meaningfulSourceId(attr(instance, "SourceAssetId"))
	return sourceId ~= nil
		or attr(instance, "AssetManifestId") ~= nil
		or attr(instance, "ImportedVisibleAsset") == true
		or attr(instance, "CreatorStoreOnly") == true
end

local function isBasePart(instance)
	return instance:IsA("BasePart")
end

local function isVisibleImportedAsset(instance)
	if attr(instance, "ImportedVisibleAsset") == true then
		return true
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
	local rawScriptReviewQueued = false
	for _, descendant in ipairs(instance:GetDescendants()) do
		if isScriptInstance(descendant) and attr(descendant, "ImportedScriptQuarantined") ~= true then
			rawScriptReviewQueued = rawScriptReviewQueued or isRawScriptReviewQueue(descendant)
			if not isReleaseReadyScript(descendant) then
				scriptsPresent = true
			end
		end
	end
	return scriptsPresent, rawScriptReviewQueued
end

local function hasTaggedAncestor(instance, stopRoot)
	local current = instance.Parent
	while current and current ~= stopRoot.Parent do
		if isTaggedImport(current) then
			return true
		end
		if current == stopRoot then
			return false
		end
		current = current.Parent
	end
	return false
end

local function isVisibleReleaseRoot(instance)
	return attr(instance, "CreatorStoreOnly") == true
		and attr(instance, "ImportedVisibleAsset") == true
		and meaningfulSourceId(attr(instance, "SourceAssetId")) ~= nil
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
		table.insert(roots, { root = library, location = "ReplicatedStorage/" .. IMPORTED_LIBRARY_NAME, library = true, placed = false })
	end
	local workspaceImported = workspace and childByPath(workspace, { "Map", "ImportedAssets" })
	if workspaceImported then
		table.insert(roots, { root = workspaceImported, location = "Workspace/Map/ImportedAssets", library = false, placed = true })
	end
	return roots
end

local function serviceEquivalentAudit(dataModel)
	local catalogedSourceIds = {}
	local importedSourceIds = {}
	local taggedSourceIds = {}
	local placedSourceIds = {}
	local releaseReadySourceIds = {}
	local auditedSourceIds = {}
	local qualityExcludedSourceIds = {}
	local scriptRecords = 0
	local executableScriptRecords = 0
	local releaseReadySamples = {}
	local importedRootLocations = {}

	local replicatedStorage = dataModel:FindFirstChild("ReplicatedStorage")
	local shared = replicatedStorage and replicatedStorage:FindFirstChild("Shared")
	local manifestModule = shared and shared:FindFirstChild("AssetManifest")
	if manifestModule and manifestModule.Source then
		local source = manifestModule.Source
		for id in string.gmatch(source, 'SourceAssetId%s*=%s*"([^"]+)"') do
			addUnique(catalogedSourceIds, id)
		end
	end

	for _, rootInfo in ipairs(collectServiceRoots(dataModel)) do
		table.insert(importedRootLocations, rootInfo.location)
		local candidates = {}
		if isTaggedImport(rootInfo.root) then
			table.insert(candidates, rootInfo.root)
		end
		for _, descendant in ipairs(rootInfo.root:GetDescendants()) do
			if isTaggedImport(descendant) then
				table.insert(candidates, descendant)
			end
			if isScriptInstance(descendant) then
				scriptRecords += 1
				if isExecutableScript(descendant) then
					executableScriptRecords += 1
				end
			end
		end

		for _, instance in ipairs(candidates) do
			local sourceAssetId = meaningfulSourceId(attr(instance, "SourceAssetId"))
			local tagged = sourceAssetId ~= nil
				and attr(instance, "AssetManifestId") ~= nil
				and attr(instance, "CreatorStoreOnly") == true
			local visibleOrPlaced = isVisibleImportedAsset(instance) or rootInfo.placed
			local scriptsPresent, rawScriptReviewQueued = hasBlockingScript(instance)
			local excluded = qualityExclusionKind(instance) ~= nil

			addUnique(importedSourceIds, sourceAssetId)
			if tagged then addUnique(taggedSourceIds, sourceAssetId) end
			if visibleOrPlaced then addUnique(placedSourceIds, sourceAssetId) end
			if excluded then addUnique(qualityExcludedSourceIds, sourceAssetId) end
			if attr(instance, "ScriptsAudited") == true or rawScriptReviewQueued then
				addUnique(auditedSourceIds, sourceAssetId)
			end
			if tagged and visibleOrPlaced and not scriptsPresent and not excluded then
				addUnique(releaseReadySourceIds, sourceAssetId)
				if #releaseReadySamples < 20 and sourceAssetId then
					table.insert(releaseReadySamples, `{sourceAssetId}:{fullName(instance)}`)
				end
			end
		end
	end

	table.sort(releaseReadySamples)
	table.sort(importedRootLocations)
	return {
		importedRootLocations = importedRootLocations,
		catalogedSourceAssetIds = setSize(catalogedSourceIds),
		actuallyImportedAssets = setSize(importedSourceIds),
		auditedImportedAssets = setSize(auditedSourceIds),
		taggedImportedAssets = setSize(taggedSourceIds),
		placedVisibleAssets = setSize(placedSourceIds),
		releaseReadyVisibleAssets = setSize(releaseReadySourceIds),
		qualityExcludedAssets = setSize(qualityExcludedSourceIds),
		scriptObjectsFound = scriptRecords,
		executableScriptObjectsFound = executableScriptRecords,
		releaseReadySamples = releaseReadySamples,
	}
end

local function isImportedScopePath(path)
	return pathContains(path, "Workspace.Map")
		or pathContains(path, "Workspace.NPCs")
		or pathContains(path, "Workspace.dinosaur")
		or pathContains(path, "ReplicatedStorage.ImportedAssetLibrary")
end

local function firstN(list, limit)
	local out = {}
	local max = math.min(#list, limit)
	for index = 1, max do
		table.insert(out, list[index])
	end
	return out
end

local function boolText(value)
	return value == true and "true" or "false"
end

local function proofSummary(dataModel)
	local replicatedStorage = dataModel:FindFirstChild("ReplicatedStorage")
	local proof = replicatedStorage and replicatedStorage:FindFirstChild("G016FinalGateProof")
	local clientProof = replicatedStorage and replicatedStorage:FindFirstChild("G016ClientProof")
	local proofAttrs = proof and attrs(proof) or {}
	local clientAttrs = clientProof and attrs(clientProof) or {}
	local storiesPassed = 0
	local missingStories = {}

	for index = 1, 15 do
		local storyId = string.format("US%02d", index)
		if proofAttrs[storyId .. "LiveProofPassed"] == true then
			storiesPassed += 1
		else
			table.insert(missingStories, storyId)
		end
	end

	return {
		hasProofFolder = proof ~= nil,
		hasClientProofFolder = clientProof ~= nil,
		storiesPassed = storiesPassed,
		missingStories = missingStories,
		freshAllCategory = proofAttrs.FreshAllCategoryTestRunnerPassed == true,
		freshAllCategoryFailed = proofAttrs.FreshAllCategoryTestRunnerFailed,
		freshAllCategoryTotal = proofAttrs.FreshAllCategoryTestRunnerTotal,
		liveE2E = proofAttrs.LiveE2EProofPassed == true,
		mobile = proofAttrs.MobileControllerProofPassed == true,
		clientLiveControls = clientAttrs.US13LiveControlsPassed == true,
		rbxlPersistence = proofAttrs.RBXLPersistencePassed == true,
		visibleDinosaurs = proofAttrs.VisibleDinosaurCount,
		visibleCarnivores = proofAttrs.VisibleCarnivoreCount,
		runId = proofAttrs.LiveE2EProofRunId or proofAttrs.L005LiveProbeRunId or clientAttrs.US13LiveControlsRunId,
	}
end

local function auditPlace(path)
	if not fs.isFile(path) then
		error(`input file does not exist: {path}`, 0)
	end

	local dataModel = roblox.deserializePlace(fs.readFile(path))
	local descendants = dataModel:GetDescendants()
	local uniqueReleaseIds = {}
	local taggedRoots = 0
	local releaseReadyRoots = 0
	local importedScriptDescendants = 0
	local importedRuntimeScripts = 0
	local tempArtifacts = {}
	local rootSamples = {}
	local sourceIdSamples = {}
	local sampledSourceIds = {}

	for _, instance in ipairs(descendants) do
		local pathName = fullName(instance)
		local name = instance.Name
		local isScriptClass = instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript")
		local isProofFolder = pathName == "ReplicatedStorage.G016FinalGateProof"
			or pathName == "ReplicatedStorage.G016ClientProof"
		local suspiciousTemp = string.find(name, "FreshSlopProof", 1, true) ~= nil
			or string.find(name, "OrientationFreshServices", 1, true) ~= nil
			or string.find(name, "AlreadyUpright", 1, true) ~= nil
			or string.find(name, "UpsideDown", 1, true) ~= nil
			or string.find(name, "RolledUnknown", 1, true) ~= nil
			or string.find(name, "TestImported", 1, true) ~= nil
			or string.find(name, "DamageTarget", 1, true) ~= nil
			or (pathContains(pathName, "ImportedAssetLibrary") and string.find(name, "Proof", 1, true) ~= nil)
		suspiciousTemp = suspiciousTemp and not isProofFolder

		if suspiciousTemp then
			table.insert(tempArtifacts, `{instance.ClassName}:{pathName}`)
		end

		if isTaggedImport(instance) and isImportedScopePath(pathName) and not hasTaggedAncestor(instance, dataModel) then
			taggedRoots += 1
			if #rootSamples < 15 then
				table.insert(rootSamples, `{instance.ClassName}:{pathName}`)
			end
			if isVisibleReleaseRoot(instance) then
				releaseReadyRoots += 1
				local sourceId = meaningfulSourceId(attr(instance, "SourceAssetId"))
				uniqueReleaseIds[sourceId] = true
				if not sampledSourceIds[sourceId] and #sourceIdSamples < 20 then
					sampledSourceIds[sourceId] = true
					table.insert(sourceIdSamples, sourceId)
				end
			end
		end

		if isScriptClass and isImportedScopePath(pathName) then
			importedScriptDescendants += 1
			if instance:IsA("Script") or instance:IsA("LocalScript") then
				importedRuntimeScripts += 1
			end
		end
	end

	table.sort(tempArtifacts)
	table.sort(sourceIdSamples)

	local proof = proofSummary(dataModel)
	local serviceAudit = serviceEquivalentAudit(dataModel)
	local uniqueReleaseCount = setSize(uniqueReleaseIds)
	local releasePass = serviceAudit.actuallyImportedAssets >= REQUIRED_RELEASE_ASSETS
		and serviceAudit.releaseReadyVisibleAssets >= REQUIRED_RELEASE_ASSETS
	local coreProofPass = proof.storiesPassed == 15 and proof.liveE2E and proof.mobile and proof.clientLiveControls
	local finalPass = releasePass and coreProofPass and proof.freshAllCategory and proof.rbxlPersistence and serviceAudit.executableScriptObjectsFound == 0

	return {
		path = path,
		descendants = #descendants,
		taggedRoots = taggedRoots,
		releaseReadyRoots = releaseReadyRoots,
		uniqueReleaseCount = uniqueReleaseCount,
		releaseGap = math.max(REQUIRED_RELEASE_ASSETS - uniqueReleaseCount, 0),
		importedScriptDescendants = importedScriptDescendants,
		importedRuntimeScripts = importedRuntimeScripts,
		tempArtifactCount = #tempArtifacts,
		tempArtifactSamples = firstN(tempArtifacts, 20),
		rootSamples = rootSamples,
		sourceIdSamples = sourceIdSamples,
		serviceAudit = serviceAudit,
		proof = proof,
		coreProofPass = coreProofPass,
		releasePass = releasePass,
		finalPass = finalPass,
	}
end

for _, path in ipairs(args) do
	local result = auditPlace(path)
	print("")
	print(`# G016 place gate audit: {result.path}`)
	print(`descendants={result.descendants}`)
	print(`taggedRoots={result.taggedRoots}`)
	print(`releaseReadyRoots={result.releaseReadyRoots}`)
	print(`broadWorldUniqueReleaseReadySourceIds={result.uniqueReleaseCount}`)
	print(`broadWorldReleaseGapTo500={result.releaseGap}`)
	print(`gateImportedRootLocations={table.concat(result.serviceAudit.importedRootLocations, ",")}`)
	print(`gateActuallyImportedAssets={result.serviceAudit.actuallyImportedAssets}`)
	print(`gateAuditedImportedAssets={result.serviceAudit.auditedImportedAssets}`)
	print(`gateTaggedImportedAssets={result.serviceAudit.taggedImportedAssets}`)
	print(`gatePlacedVisibleAssets={result.serviceAudit.placedVisibleAssets}`)
	print(`gateReleaseReadyVisibleAssets={result.serviceAudit.releaseReadyVisibleAssets}`)
	print(`gateQualityExcludedAssets={result.serviceAudit.qualityExcludedAssets}`)
	print(`gateScriptObjectsFound={result.serviceAudit.scriptObjectsFound}`)
	print(`gateExecutableScriptObjectsFound={result.serviceAudit.executableScriptObjectsFound}`)
	print(`gateReleaseGapTo500={math.max(REQUIRED_RELEASE_ASSETS - result.serviceAudit.releaseReadyVisibleAssets, 0)}`)
	print(`importedScriptDescendants={result.importedScriptDescendants}`)
	print(`importedRuntimeScripts={result.importedRuntimeScripts}`)
	print(`tempArtifactCount={result.tempArtifactCount}`)
	print(`proofFolder={boolText(result.proof.hasProofFolder)}`)
	print(`clientProofFolder={boolText(result.proof.hasClientProofFolder)}`)
	print(`storiesLivePassed={result.proof.storiesPassed}/15`)
	print(`missingStories={table.concat(result.proof.missingStories, ",")}`)
	print(`liveE2E={boolText(result.proof.liveE2E)}`)
	print(`mobileController={boolText(result.proof.mobile)}`)
	print(`clientLiveControls={boolText(result.proof.clientLiveControls)}`)
	print(`freshAllCategory={boolText(result.proof.freshAllCategory)}`)
	print(`freshAllCategoryTotal={tostring(result.proof.freshAllCategoryTotal)}`)
	print(`freshAllCategoryFailed={tostring(result.proof.freshAllCategoryFailed)}`)
	print(`rbxlPersistence={boolText(result.proof.rbxlPersistence)}`)
	print(`visibleDinosaurs={tostring(result.proof.visibleDinosaurs)}`)
	print(`visibleCarnivores={tostring(result.proof.visibleCarnivores)}`)
	print(`proofRunId={tostring(result.proof.runId)}`)
	print(`coreProofPass={boolText(result.coreProofPass)}`)
	print(`releasePass={boolText(result.releasePass)}`)
	print(`finalG016Pass={boolText(result.finalPass)}`)
	if #result.serviceAudit.releaseReadySamples > 0 then
		print("gateReleaseReadySamples:")
		for _, sample in ipairs(result.serviceAudit.releaseReadySamples) do
			print(`- {sample}`)
		end
	end
	if #result.sourceIdSamples > 0 then
		print(`sourceIdSamples={table.concat(result.sourceIdSamples, ",")}`)
	end
	if #result.tempArtifactSamples > 0 then
		print("tempArtifactSamples:")
		for _, sample in ipairs(result.tempArtifactSamples) do
			print(`- {sample}`)
		end
	end
	if #result.rootSamples > 0 then
		print("taggedRootSamples:")
		for _, sample in ipairs(result.rootSamples) do
			print(`- {sample}`)
		end
	end
end
