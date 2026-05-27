local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StatReplicationService = {}

function StatReplicationService:BuildPayload(state)
    return {
        health = state.Health,
        hunger = state.Hunger,
        thirst = state.Thirst,
        stamina = state.Stamina,
        growth = state.Growth,
        growthStage = state.GrowthStage,
        hatched = state.Hatched == true,
        hatchProgress = state.HatchProgress or 0,
        diet = state.Diet,
        species = state.SpeciesId,
        statusEffects = state.StatusEffects or {},
    }
end

function StatReplicationService:Send(player, state)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local statUpdate = remotes and remotes:FindFirstChild("StatUpdate")
	if statUpdate and state then
		local ok = pcall(function()
			statUpdate:FireClient(player, self:BuildPayload(state))
		end)
		if not ok and type(player) == "table" then
			player.LastStatUpdate = self:BuildPayload(state)
		end
	end
end

function StatReplicationService:Notify(player, message, notificationType, duration, icon)
    local payload = { message = message, type = notificationType or "Info", duration = duration or 3, icon = icon }
    if type(player) == "table" then
        player.LastNotification = payload
    end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local event = remotes and remotes:FindFirstChild("ClientNotification")
	if event then
		local ok = pcall(function()
			event:FireClient(player, payload)
		end)
		if not ok and type(player) == "table" then
			player.LastNotification = payload
		end
	end
    return payload
end

return StatReplicationService
