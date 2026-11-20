-- TideGauge: the glass column on the right edge that fills with cheese as the next tide approaches.
-- Reads the server's workspace attributes TideState / TideNextAt (set by Tide) and RaiderName (set by Raider);
-- timings come from Config. Turns tide red with a pulsing edge in the last RED_SECONDS and shows the wall rising while the tide is in.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Style = require(script.Parent.Style)

local RED_SECONDS = 15
local SWEEP_SECONDS = (Config.TIDE_END_X - Config.TIDE_START_X) / Config.TIDE_SPEED

local gui = Style.screen("TideGauge", 2)

local gauge = Instance.new("Frame")
gauge.Name = "Gauge"
gauge.Size = UDim2.fromOffset(176, 476)
gauge.Position = UDim2.new(1, -14, 0, 124)
gauge.AnchorPoint = Vector2.new(1, 0)
gauge.BackgroundColor3 = Style.NIGHT
gauge.BackgroundTransparency = 0.2
gauge.ClipsDescendants = false
Instance.new("UICorner", gauge).CornerRadius = UDim.new(0, 14)
local edge = Instance.new("UIStroke", gauge)
edge.Color = Style.NEON
edge.Thickness = 3
gauge.Parent = gui

local header = Style.hazard(gauge, UDim2.new(1, -20, 0, 12), UDim2.fromOffset(10, 8))
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 4)
Style.label(gauge, "CHEESE TIDE", UDim2.new(1, -16, 0, 32), UDim2.fromOffset(8, 24), Style.CHEESE, Style.HAZARD_DARK)

-- The glass column
local glass = Instance.new("Frame")
glass.Name = "Glass"
glass.Size = UDim2.fromOffset(84, 270)
glass.Position = UDim2.new(0.5, 0, 0, 62)
glass.AnchorPoint = Vector2.new(0.5, 0)
glass.BackgroundColor3 = Color3.fromRGB(60, 70, 110)
glass.BackgroundTransparency = 0.45
glass.ClipsDescendants = true
Instance.new("UICorner", glass).CornerRadius = UDim.new(0, 16)
local glassEdge = Instance.new("UIStroke", glass)
glassEdge.Color = Color3.fromRGB(220, 240, 255)
glassEdge.Thickness = 3
glass.Parent = gauge

local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.AnchorPoint = Vector2.new(0, 1)
fill.Position = UDim2.fromScale(0, 1)
fill.Size = UDim2.fromScale(1, 0)
fill.BackgroundColor3 = Style.CHEESE
fill.BorderSizePixel = 0
fill.Parent = glass
local crest = Style.hazard(fill, UDim2.new(1, 0, 0, 10), UDim2.fromOffset(0, 0))
crest.Visible = false

-- tick marks every quarter, plus a shine stripe so it reads as glass
for i = 1, 3 do
	local tick = Instance.new("Frame")
	tick.Size = UDim2.new(0.35, 0, 0, 3)
	tick.Position = UDim2.new(0.65, 0, i / 4, 0)
	tick.BackgroundColor3 = Color3.new(1, 1, 1)
	tick.BackgroundTransparency = 0.3
	tick.BorderSizePixel = 0
	tick.ZIndex = 2
	tick.Parent = glass
end
local shine = Instance.new("Frame")
shine.Size = UDim2.new(0, 8, 1, -24)
shine.Position = UDim2.fromOffset(12, 12)
shine.BackgroundColor3 = Color3.new(1, 1, 1)
shine.BackgroundTransparency = 0.6
shine.BorderSizePixel = 0
shine.ZIndex = 2
Instance.new("UICorner", shine).CornerRadius = UDim.new(1, 0)
shine.Parent = glass

local countdown = Style.label(gauge, "0:00", UDim2.new(1, -12, 0, 70), UDim2.fromOffset(6, 338), Color3.new(1, 1, 1), Style.HAZARD_DARK)
local status = Style.label(gauge, "NEXT TIDE", UDim2.new(1, -12, 0, 30), UDim2.fromOffset(6, 408), Style.CHEESE, Style.HAZARD_DARK)
local hint = Style.label(gauge, "DOCKS ARE SAFE", UDim2.new(1, -12, 0, 24), UDim2.fromOffset(6, 442), Color3.fromRGB(200, 235, 255), Style.HAZARD_DARK)

-- RAIDER ALERT tag under the gauge
local raider = Instance.new("Frame")
raider.Name = "RaiderAlert"
raider.Size = UDim2.fromOffset(176, 66)
raider.Position = UDim2.new(1, -14, 0, 610)
raider.AnchorPoint = Vector2.new(1, 0)
raider.BackgroundColor3 = Style.TIDE_RED
raider.Visible = false
Instance.new("UICorner", raider).CornerRadius = UDim.new(0, 10)
local raiderEdge = Instance.new("UIStroke", raider)
raiderEdge.Color = Style.NEON
raiderEdge.Thickness = 3
raider.Parent = gui
Style.hazard(raider, UDim2.new(1, 0, 0, 8), UDim2.fromOffset(0, 0), Style.CHEESE)
Style.label(raider, "RAIDER ALERT", UDim2.new(1, -12, 0, 28), UDim2.fromOffset(6, 10), Color3.new(1, 1, 1), Style.HAZARD_DARK)
local raiderName = Style.label(raider, "", UDim2.new(1, -12, 0, 24), UDim2.fromOffset(6, 38), Style.CHEESE, Style.HAZARD_DARK)

local gapTotal = Config.TIDE_MAX_GAP
local sweepStartedAt = os.clock()
workspace:GetAttributeChangedSignal("TideNextAt"):Connect(function()
	local nextAt = workspace:GetAttribute("TideNextAt")
	if nextAt then
		gapTotal = math.max(1, nextAt - workspace:GetServerTimeNow())
	end
end)
local warningStartedAt = os.clock()
workspace:GetAttributeChangedSignal("TideState"):Connect(function()
	local state = workspace:GetAttribute("TideState")
	if state == "sweeping" then
		sweepStartedAt = os.clock()
	elseif state == "warning" then
		warningStartedAt = os.clock()
	end
end)

local function clock(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

RunService.RenderStepped:Connect(function()
	local state = workspace:GetAttribute("TideState") or "calm"
	local nextAt = workspace:GetAttribute("TideNextAt")
	local left = if nextAt then nextAt - workspace:GetServerTimeNow() else gapTotal
	if state == "warning" then
		left = math.min(left, Config.TIDE_WARNING - (os.clock() - warningStartedAt))
	end
	local pulse = math.abs(math.sin(os.clock() * 6))
	local red: boolean
	if state == "sweeping" then
		local elapsed = os.clock() - sweepStartedAt
		red = true
		fill.Size = UDim2.fromScale(1, math.clamp(elapsed / SWEEP_SECONDS * 1.6, 0.05, 1)) -- the wall rises, then holds
		fill.BackgroundColor3 = Style.CHEESE
		crest.Visible = true
		countdown.Text = clock(SWEEP_SECONDS - elapsed)
		status.Text = "TIDE IS IN!"
		hint.Text = "HIDE ON A DOCK"
	else
		red = state == "warning" or left <= RED_SECONDS
		fill.Size = UDim2.fromScale(1, math.clamp(1 - left / gapTotal, 0.02, 1))
		fill.BackgroundColor3 = if red then Style.TIDE_RED else Style.CHEESE
		crest.Visible = false
		countdown.Text = clock(left)
		status.Text = if red then "TIDE INCOMING!" else "NEXT TIDE IN"
		hint.Text = if red then "RUN TO A DOCK!" else "DOCKS ARE SAFE"
	end
	countdown.TextColor3 = if red then Color3.fromRGB(255, 120, 120) else Color3.new(1, 1, 1)
	status.TextColor3 = if red then Color3.fromRGB(255, 110, 110) else Style.CHEESE
	edge.Color = if red then Style.TIDE_RED else Style.NEON
	edge.Thickness = if red then 3 + 4 * pulse else 3
	glassEdge.Color = if red then Style.TIDE_RED else Color3.fromRGB(220, 240, 255)

	local raiderActive = workspace:GetAttribute("RaiderName")
	raider.Visible = raiderActive ~= nil
	if raiderActive then
		raiderName.Text = string.upper(raiderActive)
		raiderEdge.Thickness = 2 + 3 * pulse
	end
end)
