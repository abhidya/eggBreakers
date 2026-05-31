--[[
    SoundLibrary
    Wave-5 AUDIO/SFX layer.

    Maps an action category -> one or more known-free rbxassetid sound ids.
    The server picks a category on action success and fires PlayActionSound;
    the client SfxController resolves the category to a concrete sound id and
    plays a localized Sound at the given world position.

    Categories (diegetic dino-survival actions):
      EatCrunch   — biting / chewing vegetation or carcass
      DrinkSlurp  — lapping water at a shoreline / pool
      AttackBite  — lunge / bite attack swing
      HitImpact   — a strike connecting (damage dealt / taken)
      Roar        — territorial call / roar

    All ids below are Roblox-hosted free sound assets (rbxassetid). Multiple
    ids per category let the client randomize so repeated actions do not sound
    mechanically identical.

    This module is shared (client + server). It must stay require-safe with no
    world/runtime dependencies, and 'return SoundLibrary' must be LAST.
--]]

local SoundLibrary = {}

-- category -> array of rbxassetid sound ids (strings, "rbxassetid://<n>")
SoundLibrary.Sounds = {
    EatCrunch = {
        "rbxassetid://9112854440",
        "rbxassetid://5982877794",
    },
    DrinkSlurp = {
        "rbxassetid://9114013796",
        "rbxassetid://5982897546",
    },
    AttackBite = {
        "rbxassetid://9118819211",
        "rbxassetid://7176423918",
    },
    HitImpact = {
        "rbxassetid://9125786809",
        "rbxassetid://3744371342",
    },
    Roar = {
        "rbxassetid://9120524136",
        "rbxassetid://5466166437",
    },
}

-- Default playback tuning per category. Kept conservative so audio is felt,
-- not overpowering. Resolved client-side; safe defaults if a key is missing.
SoundLibrary.Defaults = {
    EatCrunch  = { Volume = 0.6, RollOffMaxDistance = 60,  PlaybackSpeedJitter = 0.08 },
    DrinkSlurp = { Volume = 0.55, RollOffMaxDistance = 55,  PlaybackSpeedJitter = 0.06 },
    AttackBite = { Volume = 0.7, RollOffMaxDistance = 80,  PlaybackSpeedJitter = 0.10 },
    HitImpact  = { Volume = 0.75, RollOffMaxDistance = 90,  PlaybackSpeedJitter = 0.10 },
    Roar       = { Volume = 0.85, RollOffMaxDistance = 220, PlaybackSpeedJitter = 0.05 },
}

-- Returns true if the category is known.
function SoundLibrary:HasCategory(category)
    return type(category) == "string" and self.Sounds[category] ~= nil
end

-- Resolves a category to a single concrete rbxassetid.
-- If soundId is provided and non-empty, it is honored verbatim (lets the
-- server pin a specific id). Otherwise a (deterministic-if-seeded) random id
-- from the category list is chosen. Returns nil for unknown categories.
function SoundLibrary:Resolve(category, soundId, rng)
    if type(soundId) == "string" and soundId ~= "" then
        return soundId
    end
    local ids = self.Sounds[category]
    if type(ids) ~= "table" or #ids == 0 then
        return nil
    end
    if #ids == 1 then
        return ids[1]
    end
    local index
    if rng then
        index = rng:NextInteger(1, #ids)
    else
        index = math.random(1, #ids)
    end
    return ids[index]
end

-- Returns playback defaults for a category (always a table, never nil).
function SoundLibrary:GetDefaults(category)
    return self.Defaults[category] or { Volume = 0.6, RollOffMaxDistance = 60, PlaybackSpeedJitter = 0.05 }
end

return SoundLibrary
