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

local function isImportedScopePath(path)
	return pathContains(path, "Workspace.Map")
		or pathContains(path, "Workspace.NPCs")
		or pathContains(path, "Workspace.dinosaur")
		or pathContains(path, "ReplicatedStorage.ImportedAssetLibrary")
end

local function setSize(set)
	local count = 0
	for _ in pairs(set) do
		count += 1
	end
	return count
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
	local uniqueReleaseCount = setSize(uniqueReleaseIds)
	local releasePass = uniqueReleaseCount >= REQUIRED_RELEASE_ASSETS
	local coreProofPass = proof.storiesPassed == 15 and proof.liveE2E and proof.mobile and proof.clientLiveControls
	local finalPass = releasePass and coreProofPass and proof.freshAllCategory and proof.rbxlPersistence and importedRuntimeScripts == 0

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
	print(`uniqueReleaseReadySourceIds={result.uniqueReleaseCount}`)
	print(`releaseGapTo500={result.releaseGap}`)
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
