local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local args = process.args

local function usage()
	error("usage: lune run tools/g016_clean_place_candidate.luau <input.rbxl> <output.rbxl>", 0)
end

if #args ~= 2 then
	usage()
end

local inputPath = args[1]
local outputPath = args[2]

if not fs.isFile(inputPath) then
	error(`input file does not exist: {inputPath}`, 0)
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

local function isScriptInstance(instance)
	return instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript")
end

local function isImportedRootPath(path)
	return pathContains(path, "ReplicatedStorage.ImportedAssetLibrary")
		or pathContains(path, "Workspace.Map.ImportedAssets")
end

local function isFinalProofFolderPath(path)
	return path == "ReplicatedStorage.G016FinalGateProof"
		or path == "ReplicatedStorage.G016ClientProof"
end

local function isValidationArtifact(instance)
	local path = fullName(instance)
	local name = instance.Name or ""
	if isFinalProofFolderPath(path) then
		return false
	end

	if string.find(name, "FreshSlopProof", 1, true) ~= nil then return true end
	if string.find(name, "OrientationFreshServices", 1, true) ~= nil then return true end
	if string.find(name, "AlreadyUpright", 1, true) ~= nil then return true end
	if string.find(name, "UpsideDown", 1, true) ~= nil then return true end
	if string.find(name, "RolledUnknown", 1, true) ~= nil then return true end
	if string.find(name, "DamageTarget", 1, true) ~= nil then return true end
	if isImportedRootPath(path) and string.find(name, "TestImported", 1, true) ~= nil then return true end
	if isImportedRootPath(path) and string.find(name, "Proof", 1, true) ~= nil then return true end
	return false
end

local function hasRemovedAncestor(instance, removeSet)
	local current = instance.Parent
	while current do
		if removeSet[current] then
			return true
		end
		current = current.Parent
	end
	return false
end

local dataModel = roblox.deserializePlace(fs.readFile(inputPath))
local descendants = dataModel:GetDescendants()
local removals = {}
local removeSet = {}
local scriptRemovals = 0
local validationRemovals = 0
local tempSamples = {}
local scriptSamples = {}

for _, instance in ipairs(descendants) do
	local path = fullName(instance)
	local shouldRemove = false
	local reason = nil

	if isValidationArtifact(instance) then
		shouldRemove = true
		reason = "validation-artifact"
	elseif isScriptInstance(instance) and isImportedRootPath(path) and attr(instance, "ImportedScriptQuarantined") ~= true then
		shouldRemove = true
		reason = "imported-script"
	end

	if shouldRemove and not hasRemovedAncestor(instance, removeSet) then
		table.insert(removals, { instance = instance, path = path, className = instance.ClassName, reason = reason })
		removeSet[instance] = true
	end
end

for _, record in ipairs(removals) do
	if record.reason == "imported-script" then
		scriptRemovals += 1
		if #scriptSamples < 20 then
			table.insert(scriptSamples, `{record.className}:{record.path}`)
		end
	else
		validationRemovals += 1
		if #tempSamples < 20 then
			table.insert(tempSamples, `{record.className}:{record.path}`)
		end
	end
	record.instance:Destroy()
end

fs.writeFile(outputPath, roblox.serializePlace(dataModel))

print(`input={inputPath}`)
print(`output={outputPath}`)
print(`removedValidationArtifacts={validationRemovals}`)
print(`removedImportedScripts={scriptRemovals}`)
if #tempSamples > 0 then
	print("validationArtifactSamples:")
	for _, sample in ipairs(tempSamples) do
		print(`- {sample}`)
	end
end
if #scriptSamples > 0 then
	print("importedScriptSamples:")
	for _, sample in ipairs(scriptSamples) do
		print(`- {sample}`)
	end
end
