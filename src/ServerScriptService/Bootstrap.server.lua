local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteContracts = require(ReplicatedStorage.Shared.RemoteContracts)

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

for remoteName in pairs(RemoteContracts) do
    if not remotesFolder:FindFirstChild(remoteName) then
        local remote = Instance.new("RemoteEvent")
        remote.Name = remoteName
        remote.Parent = remotesFolder
    end
end
