local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local args = process.args

local function usage()
    error("usage: lune run tools/convert_rbxl_to_rbxlx.luau <input.rbxl> <output.rbxlx>", 0)
end

if #args ~= 2 then
    usage()
end

local inputPath = args[1]
local outputPath = args[2]

if not fs.isFile(inputPath) then
    error(`input file does not exist: {inputPath}`, 0)
end

local bytes = fs.readFile(inputPath)
local dataModel = roblox.deserializePlace(bytes)
local xml = roblox.serializePlace(dataModel, true)

fs.writeFile(outputPath, xml)
print(`converted {inputPath} -> {outputPath}`)
