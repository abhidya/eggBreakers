local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteContracts = require(ReplicatedStorage.Shared.RemoteContracts)

local Bootstrap = {}

function Bootstrap.EnsureRemotes()
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotesFolder then
        remotesFolder = Instance.new("Folder")
        remotesFolder.Name = "Remotes"
        remotesFolder.Parent = ReplicatedStorage
    end

    for remoteName in pairs(RemoteContracts) do
        local existing = remotesFolder:FindFirstChild(remoteName)
        if not existing then
            local remote = Instance.new("RemoteEvent")
            remote.Name = remoteName
            remote.Parent = remotesFolder
        elseif not existing:IsA("RemoteEvent") then
            error("Remote contract " .. remoteName .. " exists but is not a RemoteEvent")
        end
    end

    return remotesFolder
end

function Bootstrap.Init()
    return Bootstrap.EnsureRemotes()
end

return Bootstrap
