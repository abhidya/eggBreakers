-- SenseGuideController: diegetic "sixth sense" food/water guide for the local dino.
--
-- Progressive disclosure: this controller is SILENT until the player's hunger or
-- thirst drops past a comfort threshold. Only then does it gently highlight the
-- single NEAREST VALID diet target with:
--   * a soft world Highlight (green for food, blue for water),
--   * a billboard badge over the target showing the diet icon + rounded distance,
--   * a gentle breathing pulse on the highlight + badge.
-- When the player is full/hydrated, or no valid target is in range, it hides
-- everything. It NEVER points a misleading arrow at things you cannot use, and it
-- excludes NPCs (live brains) the same way the action hint does.
--
-- This module owns NO target-finding logic of its own. The host (ClientBootstrap)
-- already has the authoritative, diet-aware finder
-- (ClientBootstrap:FindNearestEatDrinkTarget) and the latest stat payload; the
-- host injects both via :Bind(...). That keeps a single source of truth and means
-- this guide stays in perfect agreement with the EatDrink button + action hint.
--
-- It is intentionally separate from, and additive to, the existing
-- NearestActionHintLabel waypoint cue (which MobileControlsTests asserts on).
--
-- Public API (stable):
--   SenseGuideController:Bind(opts)            -- wire host finder + stat getter
--   SenseGuideController:Update()              -- recompute + show/hide (call on a cadence)
--   SenseGuideController:Hide()                -- force-hide all visuals
--   SenseGuideController.ShouldGuide(stats)    -- pure: is the player needy enough?
--   SenseGuideController.Settings              -- tunable thresholds/colors

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")

local player = Players.LocalPlayer

local SenseGuideController = {}

SenseGuideController.Settings = {
	-- Only surface the guide once a need crosses below this comfort level.
	HungerComfort   = 55,
	ThirstComfort   = 55,
	-- How far away we will still bother guiding the player (studs).
	MaxGuideDistance = 140,
	-- Soft world highlight colors per diet target type.
	FoodFill   = Color3.fromRGB(120, 220, 130),
	FoodOutline = Color3.fromRGB(200, 255, 200),
	WaterFill  = Color3.fromRGB(120, 200, 255),
	WaterOutline = Color3.fromRGB(210, 240, 255),
	-- Gentle pulse timing.
	PulsePeriod = 1.6,
}

-- Host-injected dependencies (set in :Bind).
SenseGuideController._finder    = nil   -- function(maxDistance) -> target, targetType, distance
SenseGuideController._getStats  = nil   -- function() -> stats table
SenseGuideController._bound     = false

-- Live visual instances (created lazily, reused).
SenseGuideController._highlight = nil
SenseGuideController._billboard = nil
SenseGuideController._badge     = nil
SenseGuideController._pulse     = nil   -- RenderStepped connection driving the breathing pulse
SenseGuideController._activeTarget = nil

local function iconForType(targetType)
	return targetType == "Water" and "💧" or "🍎"
end

-- Pure: returns true when the player is hungry/thirsty enough to warrant guidance.
-- Defensive about a missing/partial stats table so it is safe with no world/staging.
function SenseGuideController.ShouldGuide(stats)
	if type(stats) ~= "table" then return false end
	local hunger = tonumber(stats.hunger)
	local thirst = tonumber(stats.thirst)
	local s = SenseGuideController.Settings
	if hunger ~= nil and hunger <= s.HungerComfort then return true end
	if thirst ~= nil and thirst <= s.ThirstComfort then return true end
	return false
end

-- Pure: which need is more urgent? Returns "Food", "Water", or nil (both comfy).
-- Lets the guide prefer the target that actually addresses the dominant need.
function SenseGuideController.PreferredMode(stats)
	if type(stats) ~= "table" then return nil end
	local hunger = tonumber(stats.hunger)
	local thirst = tonumber(stats.thirst)
	local s = SenseGuideController.Settings
	local foodLow  = hunger ~= nil and hunger <= s.HungerComfort
	local waterLow = thirst ~= nil and thirst <= s.ThirstComfort
	if foodLow and waterLow then
		-- whichever is lower wins; tie -> water (dehydration bites first)
		if (thirst or 100) <= (hunger or 100) then return "Water" end
		return "Food"
	end
	if waterLow then return "Water" end
	if foodLow then return "Food" end
	return nil
end

-- Bind the host's authoritative finder + stat getter. Safe to call once.
-- opts = { Finder = function(maxDistance, preferredMode) -> target, type, distance,
--          GetStats = function() -> stats }
function SenseGuideController:Bind(opts)
	opts = opts or {}
	if type(opts.Finder) == "function" then self._finder = opts.Finder end
	if type(opts.GetStats) == "function" then self._getStats = opts.GetStats end
	self._bound = true
	return self
end

local function targetPart(target)
	if not target then return nil end
	if target:IsA("BasePart") then return target end
	if target:IsA("Model") then
		return target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
	end
	return target:FindFirstChildWhichIsA("BasePart")
end

local function targetPosition(target)
	if not target or not target:IsDescendantOf(workspace) then return nil end
	if target:IsA("BasePart") then return target.Position end
	if target.GetPivot then return target:GetPivot().Position end
	local part = targetPart(target)
	return part and part.Position or nil
end

-- Lazily build (or rebuild) the highlight + billboard badge attached to `target`.
function SenseGuideController:_ensureVisuals(target, targetType)
	local adornee = targetPart(target)
	if not adornee then return false end

	-- Soft world highlight.
	if not self._highlight or not self._highlight.Parent then
		local hl = Instance.new("Highlight")
		hl.Name = "SenseGuideHighlight"
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = player:FindFirstChildOfClass("PlayerGui") or player
		self._highlight = hl
	end
	local s = self.Settings
	if targetType == "Water" then
		self._highlight.FillColor = s.WaterFill
		self._highlight.OutlineColor = s.WaterOutline
	else
		self._highlight.FillColor = s.FoodFill
		self._highlight.OutlineColor = s.FoodOutline
	end
	-- Highlight an entire model where possible so the whole bush/pond glows.
	self._highlight.Adornee = (target:IsA("Model") and target) or adornee

	-- Billboard badge: diet icon + distance.
	if not self._billboard or not self._billboard.Parent then
		local bb = Instance.new("BillboardGui")
		bb.Name = "SenseGuideBadge"
		bb.Size = UDim2.fromOffset(120, 52)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = s.MaxGuideDistance + 40
		bb.LightInfluence = 0

		local badge = Instance.new("TextLabel")
		badge.Name = "SenseGuideBadgeLabel"
		badge.Size = UDim2.fromScale(1, 1)
		badge.BackgroundTransparency = 0.25
		badge.BackgroundColor3 = Color3.fromRGB(14, 26, 18)
		badge.TextColor3 = Color3.fromRGB(255, 255, 255)
		badge.TextScaled = true
		badge.Font = Enum.Font.GothamBold
		badge.Text = "🍎 0m"
		badge:SetAttribute("IconOnlyTracker", true)
		badge:SetAttribute("SenseGuide", true)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = badge
		badge.Parent = bb

		self._billboard = bb
		self._badge = badge
	end
	self._billboard.Adornee = adornee
	self._billboard.Parent = player:FindFirstChildOfClass("PlayerGui") or player
	return true
end

-- Drive the gentle breathing pulse on highlight + badge while active.
function SenseGuideController:_startPulse()
	if self._pulse then return end
	local s = self.Settings
	self._pulse = RunService.RenderStepped:Connect(function()
		if not self._highlight then return end
		-- 0..1 breathing wave
		local t = (math.sin((os.clock() / s.PulsePeriod) * math.pi * 2) + 1) * 0.5
		self._highlight.FillTransparency = 0.55 + 0.25 * t
		self._highlight.OutlineTransparency = 0.05 + 0.20 * t
		if self._badge then
			self._badge.BackgroundTransparency = 0.18 + 0.14 * t
		end
	end)
end

function SenseGuideController:_stopPulse()
	if self._pulse then
		self._pulse:Disconnect()
		self._pulse = nil
	end
end

-- Hide all guide visuals (progressive disclosure: invisible when not needed).
function SenseGuideController:Hide()
	self:_stopPulse()
	self._activeTarget = nil
	if self._highlight then self._highlight.Adornee = nil end
	if self._billboard then self._billboard.Enabled = false end
end

-- Recompute the nearest valid target and show/hide accordingly.
-- Cheap and idempotent; intended to be called on a cadence (e.g. Heartbeat throttle).
function SenseGuideController:Update()
	if not self._bound or type(self._finder) ~= "function" then
		self:Hide()
		return false
	end
	local stats = type(self._getStats) == "function" and self._getStats() or nil

	if not self.ShouldGuide(stats) then
		self:Hide()
		return false
	end

	local preferred = self.PreferredMode(stats)
	local target, targetType, distance = self._finder(self.Settings.MaxGuideDistance, preferred)
	-- If nothing of the preferred kind is near, fall back to any valid diet target
	-- so a starving herbivore still gets pointed at water when no plants are close.
	if not target and preferred ~= nil then
		target, targetType, distance = self._finder(self.Settings.MaxGuideDistance)
	end

	local position = targetPosition(target)
	if not target or not position then
		self:Hide()
		return false
	end

	if not self:_ensureVisuals(target, targetType) then
		self:Hide()
		return false
	end

	self._activeTarget = target
	if self._billboard then self._billboard.Enabled = true end
	if self._badge then
		self._badge.Text = string.format("%s %dm", iconForType(targetType), math.floor((distance or 0) + 0.5))
	end
	self:_startPulse()
	return true, target, targetType, distance
end

return SenseGuideController
