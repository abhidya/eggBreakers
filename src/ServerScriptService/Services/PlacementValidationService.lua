local MapLayoutService = require(script.Parent.MapLayoutService)

local PlacementValidationService = {}

PlacementValidationService.RouteClearanceStuds = 22
PlacementValidationService.GridStepToleranceStuds = 2
PlacementValidationService.MinimumNaturalOffsetStuds = 7
PlacementValidationService.MinimumUniqueSourceAssetIds = 500

PlacementValidationService.CategoryRules = {
    NurseryGrove = {
        allowed = { NurseryTree = true, Bush = true, Fern = true, Nest = true },
        forbidden = { Fossil = true, CityRuin = true, CarWreck = true, Rubble = true, SwampTree = true, Cliff = true },
        edgeCategories = { NurseryTree = true, Bush = true },
    },
    FernPlains = {
        allowed = { Tree = true, Bush = true, Fern = true, Food = true, Water = true },
        forbidden = { CityRuin = true, CarWreck = true, Rubble = true, Cliff = true },
        edgeCategories = { Tree = true, Bush = true },
    },
    JungleBasin = {
        allowed = { Tree = true, Bush = true, Fern = true, Vine = true, Food = true, Water = true },
        forbidden = { CityRuin = true, CarWreck = true, Rubble = true, Cliff = true },
        edgeCategories = { Tree = true, Bush = true, Vine = true },
    },
    RedstoneCanyon = {
        allowed = { Rock = true, Cliff = true, Boulder = true, Fossil = true },
        forbidden = { CityRuin = true, CarWreck = true, SwampTree = true, NurseryTree = true },
        edgeCategories = { Rock = true, Cliff = true, Boulder = true },
    },
    SwampDelta = {
        allowed = { SwampTree = true, Reed = true, Log = true, MudRock = true, Water = true },
        forbidden = { CityRuin = true, CarWreck = true, Cliff = true, NurseryTree = true },
        edgeCategories = { SwampTree = true, Reed = true, Log = true },
    },
    ApocalypticCity = {
        allowed = { CityRuin = true, CarWreck = true, Rubble = true, Overgrowth = true, Fossil = true },
        forbidden = { NurseryTree = true, SwampTree = true, Cliff = true },
        edgeCategories = { Rubble = true, Overgrowth = true },
    },
    MountainNestingCliffs = {
        allowed = { Rock = true, Cliff = true, Boulder = true, Fossil = true, Nest = true },
        forbidden = { CityRuin = true, CarWreck = true, SwampTree = true, NurseryTree = true },
        edgeCategories = { Rock = true, Cliff = true, Boulder = true },
    },
}

PlacementValidationService.RequiredBiomeCategories = {
    NurseryGrove = { "NurseryTree", "Bush" },
    FernPlains = { "Tree", "Bush" },
    JungleBasin = { "Tree", "Vine" },
    RedstoneCanyon = { "Rock", "Cliff" },
    SwampDelta = { "SwampTree", "Reed" },
    ApocalypticCity = { "CityRuin", "CarWreck", "Rubble" },
    MountainNestingCliffs = { "Rock", "Cliff", "Fossil" },
}

PlacementValidationService.AcceptanceChecklist = {
    "no square/grid placement: natural plans must use varied X/Z deltas, rotations, and biome-edge offsets",
    "clear route corridors: decorative props stay outside terrain-backed route rectangles plus clearance",
    "trees and bushes form groves on biome edges rather than path centers",
    "city ruins, cars, rubble, overgrowth, and city fossils stay in ApocalypticCity blocks/edges",
    "rocks, cliffs, boulders, and mountain fossils stay in RedstoneCanyon or MountainNestingCliffs",
    "swamp trees, reeds, logs, mud rocks, and shallow water stay in SwampDelta",
    "fossils are never placed inside NurseryGrove safe zone",
    "final imported placement sets must provide at least 500 unique SourceAssetId values and reject cloned duplicates",
}

PlacementValidationService.ReferencePlan = {
    { id = "NurseryEdgeTreeA", biome = "NurseryGrove", category = "NurseryTree", position = Vector3.new(-2235, 11, -215), rotationY = 17 },
    { id = "NurseryEdgeBushA", biome = "NurseryGrove", category = "Bush", position = Vector3.new(-2240, 11, 238), rotationY = 71 },
    { id = "FernGroveOakA", biome = "FernPlains", category = "Tree", position = Vector3.new(-1378, 11, -242), rotationY = 29 },
    { id = "FernGroveBushA", biome = "FernPlains", category = "Bush", position = Vector3.new(-894, 11, 236), rotationY = 104 },
    { id = "JungleVineEdgeA", biome = "JungleBasin", category = "Vine", position = Vector3.new(-1696, 11, 1173), rotationY = 11 },
    { id = "JungleCanopyA", biome = "JungleBasin", category = "Tree", position = Vector3.new(-1185, 11, 1185), rotationY = 143 },
    { id = "RedstoneCliffA", biome = "RedstoneCanyon", category = "Cliff", position = Vector3.new(-514, 11, -871), rotationY = 38 },
    { id = "RedstoneBoulderA", biome = "RedstoneCanyon", category = "Rock", position = Vector3.new(132, 11, -835), rotationY = 82 },
    { id = "SwampCypressA", biome = "SwampDelta", category = "SwampTree", position = Vector3.new(-486, 9, 1169), rotationY = 21 },
    { id = "SwampReedsA", biome = "SwampDelta", category = "Reed", position = Vector3.new(196, 9, 744), rotationY = 116 },
    { id = "OldEdenTowerRuinA", biome = "ApocalypticCity", category = "CityRuin", position = Vector3.new(385, 11, 170), rotationY = 7 },
    { id = "OldEdenCarWreckA", biome = "ApocalypticCity", category = "CarWreck", position = Vector3.new(918, 11, 308), rotationY = 63 },
    { id = "OldEdenRubbleA", biome = "ApocalypticCity", category = "Rubble", position = Vector3.new(1088, 11, -284), rotationY = 137 },
    { id = "MountainCliffA", biome = "MountainNestingCliffs", category = "Cliff", position = Vector3.new(-432, 78, -1918), rotationY = 31 },
    { id = "MountainRockA", biome = "MountainNestingCliffs", category = "Rock", position = Vector3.new(238, 78, -1947), rotationY = 74 },
    { id = "MountainFossilA", biome = "MountainNestingCliffs", category = "Fossil", position = Vector3.new(154, 78, -1464), rotationY = 109 },
    { id = "CityFossilA", biome = "ApocalypticCity", category = "Fossil", position = Vector3.new(575, 11, 277), rotationY = 157 },
}

local function abs(value)
    if value < 0 then return -value end
    return value
end

function PlacementValidationService:_zoneForBiome(biome)
    return MapLayoutService.ZoneTerrain[biome]
end

function PlacementValidationService:_insideRect(position, center, size, clearance)
    clearance = clearance or 0
    return abs(position.X - center.X) <= (size.X / 2 + clearance)
        and abs(position.Z - center.Z) <= (size.Z / 2 + clearance)
end

function PlacementValidationService:_insideBiome(record)
    local zone = self:_zoneForBiome(record.biome)
    if not zone then return false end
    return self:_insideRect(record.position, zone.center, zone.size, 0)
end

function PlacementValidationService:_nearBiomeEdge(record)
    local zone = self:_zoneForBiome(record.biome)
    if not zone then return false end
    local xOffset = abs(record.position.X - zone.center.X)
    local zOffset = abs(record.position.Z - zone.center.Z)
    return xOffset >= (zone.size.X / 2 - 110) or zOffset >= (zone.size.Z / 2 - 110)
end

function PlacementValidationService:_keepsRoutesClear(record)
    for _, route in ipairs(MapLayoutService.RouteTerrain) do
        if self:_insideRect(record.position, route.center, route.size, self.RouteClearanceStuds) then
            return false, route.name
        end
    end
    return true
end

function PlacementValidationService:_categoryAllowed(record)
    local rules = self.CategoryRules[record.biome]
    if not rules then return false, "unknown_biome" end
    if rules.forbidden[record.category] then return false, "forbidden_category" end
    if not rules.allowed[record.category] then return false, "category_not_allowed" end
    if record.category == "Fossil" and record.biome == "NurseryGrove" then return false, "fossil_in_nursery" end
    return true
end

function PlacementValidationService:_hasNaturalSpacing(records)
    if #records < 3 then return true end
    local repeatedDeltaCount = 0
    local previousDx, previousDz
    table.sort(records, function(a, b)
        if a.position.X == b.position.X then return a.position.Z < b.position.Z end
        return a.position.X < b.position.X
    end)
    for index = 2, #records do
        local dx = math.floor(abs(records[index].position.X - records[index - 1].position.X) + 0.5)
        local dz = math.floor(abs(records[index].position.Z - records[index - 1].position.Z) + 0.5)
        if previousDx and abs(dx - previousDx) <= self.GridStepToleranceStuds and abs(dz - previousDz) <= self.GridStepToleranceStuds then
            repeatedDeltaCount = repeatedDeltaCount + 1
        end
        if dx < self.MinimumNaturalOffsetStuds and dz < self.MinimumNaturalOffsetStuds then
            return false
        end
        previousDx, previousDz = dx, dz
    end
    return repeatedDeltaCount == 0
end

function PlacementValidationService:ValidatePlan(plan)
    local failures = {}
    local seen = {}
    local byBiome = {}
    local categoryCoverage = {}

    for _, record in ipairs(plan or {}) do
        if not record.id or seen[record.id] then
            table.insert(failures, "placement id missing or duplicated")
        else
            seen[record.id] = true
        end

        if not record.position or typeof(record.position) ~= "Vector3" then
            table.insert(failures, tostring(record.id) .. " missing Vector3 position")
        elseif not self:_insideBiome(record) then
            table.insert(failures, tostring(record.id) .. " outside biome " .. tostring(record.biome))
        else
            local routeClear, routeName = self:_keepsRoutesClear(record)
            if not routeClear then
                table.insert(failures, tostring(record.id) .. " blocks route corridor " .. tostring(routeName))
            end
        end

        local categoryAllowed, categoryReason = self:_categoryAllowed(record)
        if not categoryAllowed then
            table.insert(failures, tostring(record.id) .. " invalid category: " .. tostring(categoryReason))
        end

        local rules = self.CategoryRules[record.biome]
        if rules and rules.edgeCategories[record.category] and record.position and typeof(record.position) == "Vector3" and not self:_nearBiomeEdge(record) then
            table.insert(failures, tostring(record.id) .. " should be a grove/edge placement")
        end

        byBiome[record.biome] = byBiome[record.biome] or {}
        table.insert(byBiome[record.biome], record)
        categoryCoverage[record.biome] = categoryCoverage[record.biome] or {}
        categoryCoverage[record.biome][record.category] = true
    end

    for biome, requiredCategories in pairs(self.RequiredBiomeCategories) do
        for _, category in ipairs(requiredCategories) do
            if not categoryCoverage[biome] or not categoryCoverage[biome][category] then
                table.insert(failures, biome .. " missing required category " .. category)
            end
        end
    end

    for biome, records in pairs(byBiome) do
        if not self:_hasNaturalSpacing(records) then
            table.insert(failures, biome .. " appears square/grid spaced")
        end
    end

    return {
        passed = #failures == 0,
        failures = failures,
        total = #(plan or {}),
    }
end



function PlacementValidationService:_boundsForRect(center, size)
    return {
        minX = center.X - size.X / 2,
        maxX = center.X + size.X / 2,
        minZ = center.Z - size.Z / 2,
        maxZ = center.Z + size.Z / 2,
    }
end

function PlacementValidationService:ValidateGeometryCoverage(plan)
    local failures = {}
    local underlay = MapLayoutService.FullMapUnderlay
    local bounds = self:_boundsForRect(underlay.center, underlay.size)

    for zoneId, zone in pairs(MapLayoutService.ZoneTerrain) do
        local zoneBounds = self:_boundsForRect(zone.center, zone.size)
        if zoneBounds.minX < bounds.minX or zoneBounds.maxX > bounds.maxX or zoneBounds.minZ < bounds.minZ or zoneBounds.maxZ > bounds.maxZ then
            table.insert(failures, zoneId .. " is outside full-map terrain underlay")
        end
        if zone.topY < underlay.topY then
            table.insert(failures, zoneId .. " topY is below full-map terrain underlay")
        end
    end

    for _, route in ipairs(MapLayoutService.RouteTerrain) do
        local routeBounds = self:_boundsForRect(route.center, route.size)
        if routeBounds.minX < bounds.minX or routeBounds.maxX > bounds.maxX or routeBounds.minZ < bounds.minZ or routeBounds.maxZ > bounds.maxZ then
            table.insert(failures, route.name .. " route is outside full-map terrain underlay")
        end
    end

    for _, record in ipairs(plan or self.ReferencePlan) do
        if record.position and typeof(record.position) == "Vector3" then
            if record.position.X < bounds.minX or record.position.X > bounds.maxX or record.position.Z < bounds.minZ or record.position.Z > bounds.maxZ then
                table.insert(failures, tostring(record.id) .. " placement is outside full-map terrain underlay")
            end
            local zone = self:_zoneForBiome(record.biome)
            if zone and record.position.Y < underlay.topY then
                table.insert(failures, tostring(record.id) .. " placement is below safe terrain underlay")
            end
        end
    end

    return {
        passed = #failures == 0,
        failures = failures,
        underlayName = underlay.name,
        underlaySize = underlay.size,
        underlayTopY = underlay.topY,
    }
end

function PlacementValidationService:ValidateUniqueSourceAssets(records, minimum)
    minimum = minimum or self.MinimumUniqueSourceAssetIds
    local failures = {}
    local unique = {}
    local uniqueCount = 0

    for _, record in ipairs(records or {}) do
        local sourceAssetId = record.SourceAssetId or record.sourceAssetId
        if sourceAssetId == nil or sourceAssetId == "" then
            table.insert(failures, tostring(record.id) .. " missing SourceAssetId")
        elseif unique[sourceAssetId] then
            table.insert(failures, tostring(record.id) .. " duplicates SourceAssetId " .. tostring(sourceAssetId))
        else
            unique[sourceAssetId] = true
            uniqueCount = uniqueCount + 1
        end
    end

    if uniqueCount < minimum then
        table.insert(failures, "unique SourceAssetId count " .. tostring(uniqueCount) .. " below required " .. tostring(minimum))
    end

    return {
        passed = #failures == 0,
        failures = failures,
        uniqueSourceAssetIds = uniqueCount,
        minimum = minimum,
    }
end


function PlacementValidationService:ValidateFoodSourceInstance(instance)
    local failures = {}
    if not instance then
        return { passed = false, failures = { "missing food source" } }
    end
    if not instance:IsA("BasePart") then
        table.insert(failures, instance:GetFullName() .. " food source must be a BasePart for reachability checks")
    end
    local diet = instance:GetAttribute("Diet")
    if diet ~= "Herbivore" and diet ~= "Carnivore" and diet ~= "Omnivore" then
        table.insert(failures, instance:GetFullName() .. " food source has invalid Diet " .. tostring(diet))
    end
    local nutrition = instance:GetAttribute("Nutrition")
    if type(nutrition) ~= "number" or nutrition <= 0 then
        table.insert(failures, instance:GetFullName() .. " food source has invalid Nutrition " .. tostring(nutrition))
    end
    local zoneId = instance:GetAttribute("ZoneId")
    if type(zoneId) == "string" and zoneId ~= "" then
        local zone = MapLayoutService.ZoneTerrain[zoneId]
        if not zone then
            table.insert(failures, instance:GetFullName() .. " food source references unknown ZoneId " .. zoneId)
        elseif instance:IsA("BasePart") then
            local position = instance.Position
            if not self:_insideRect(position, zone.center, zone.size, 0) then
                table.insert(failures, instance:GetFullName() .. " food source outside ZoneId bounds " .. zoneId)
            end
            if position.Y < zone.topY - 1 then
                table.insert(failures, instance:GetFullName() .. " food source is below zone terrain")
            end
        end
    end
    return { passed = #failures == 0, failures = failures }
end

function PlacementValidationService:ValidateNoFloatingVisibleAssets(root)
    root = root or workspace
    local failures = {}
    local checked = 0
    for _, instance in ipairs(root:GetDescendants()) do
        if instance:IsA("BasePart") and instance.Transparency < 1 and instance:GetAttribute("FloatingAllowed") ~= true then
            checked = checked + 1
            local groundTopY = instance:GetAttribute("GroundTopY")
            local zoneId = instance:GetAttribute("ZoneId")
            if groundTopY == nil and type(zoneId) == "string" and MapLayoutService.ZoneTerrain[zoneId] then
                groundTopY = MapLayoutService.ZoneTerrain[zoneId].topY
            end
            if type(groundTopY) == "number" then
                local bottomY = instance.Position.Y - instance.Size.Y / 2
                if bottomY > groundTopY + 2 then
                    table.insert(failures, instance:GetFullName() .. " floats above ground by " .. tostring(math.floor((bottomY - groundTopY) * 10 + 0.5) / 10) .. " studs")
                end
            end
        end
    end
    return { passed = #failures == 0, failures = failures, checked = checked }
end

function PlacementValidationService:GetReferencePlan()
    local plan = {}
    for _, record in ipairs(self.ReferencePlan) do
        local copy = {}
        for key, value in pairs(record) do
            copy[key] = value
        end
        if copy.position and typeof(copy.position) == "Vector3" then
            copy.position = MapLayoutService:CompactPosition(copy.position)
        end
        table.insert(plan, copy)
    end
    return plan
end

return PlacementValidationService
