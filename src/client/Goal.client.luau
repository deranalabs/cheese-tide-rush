-- Goal: one bar above the bottom bar naming the player's next real goal with a progress bar.
-- Picks the first unmet goal from StateSync snapshots: buy a brainrot, fill the dock, buy the cheapest upgrade
-- that costs less than a rebirth, reach the rebirth price, rebirth. Every price shown is one the server charges.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Net = require(Shared.Net)
local Style = require(script.Parent.Style)

local gui = Style.screen("Goal", 1)

local bar = Style.paper(gui, UDim2.fromOffset(660, 46), UDim2.new(0.5, 0, 1, -100), Vector2.new(0.5, 1))
bar.Name = "NextGoal"
Style.hazard(bar, UDim2.new(0, 12, 1, -10), UDim2.fromOffset(5, 5))

local tag = Instance.new("Frame")
tag.Size = UDim2.fromOffset(76, 34)
tag.Position = UDim2.fromOffset(22, 6)
tag.BackgroundColor3 = Style.TIDE_RED
Instance.new("UICorner", tag).CornerRadius = UDim.new(0, 6)
tag.Parent = bar
Style.label(tag, "NEXT", UDim2.new(1, -8, 1, -6), UDim2.fromOffset(4, 3), Color3.new(1, 1, 1))

local goalText = Style.label(bar, "", UDim2.fromOffset(250, 34), UDim2.fromOffset(106, 6), Style.INK)
goalText.TextXAlignment = Enum.TextXAlignment.Left

local track = Instance.new("Frame")
track.Size = UDim2.fromOffset(282, 34)
track.Position = UDim2.fromOffset(366, 6)
track.BackgroundColor3 = Style.HAZARD_DARK
track.ClipsDescendants = true
Instance.new("UICorner", track).CornerRadius = UDim.new(0, 8)
track.Parent = bar
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Style.CHEESE
fill.BorderSizePixel = 0
fill.Parent = track
local amount = Style.label(track, "", UDim2.new(1, -12, 1, -6), UDim2.fromOffset(6, 3), Color3.new(1, 1, 1), Style.HAZARD_DARK)
amount.ZIndex = 2

local ready = false

-- Returns the goal's name, the progress text and a 0..1 fraction.
local function pickGoal(s): (string, string, number)
	if s.used + #s.carried == 0 then
		return "BUY A BRAINROT", "0 / 1 ON YOUR DOCK", 0
	end
	if s.used < s.slots then
		return "FILL YOUR DOCK", s.used .. " / " .. s.slots .. " SLOTS", s.used / s.slots
	end
	local bestKind, bestCost = nil, math.huge
	for kind, cost in s.costs do
		if cost >= 0 and cost < s.rebirthCost and cost < bestCost then
			bestKind, bestCost = kind, cost
		end
	end
	if bestKind then
		local label = string.upper(Config.UPGRADES[bestKind].label) .. " UPGRADE"
		return label, Format.money(math.min(s.cash, bestCost)) .. " / " .. Format.money(bestCost), s.cash / bestCost
	end
	if s.cash < s.rebirthCost then
		return "REBIRTH", Format.money(s.cash) .. " / " .. Format.money(s.rebirthCost), s.cash / s.rebirthCost
	end
	return "REBIRTH NOW!", Format.money(s.cash) .. " / " .. Format.money(s.rebirthCost), 1
end

Net.event("StateSync").OnClientEvent:Connect(function(snapshot)
	local name, progress, fraction = pickGoal(snapshot)
	goalText.Text = name
	amount.Text = progress
	fraction = math.clamp(fraction, 0, 1)
	fill.Size = UDim2.fromScale(fraction, 1)
	ready = fraction >= 1
end)

RunService.RenderStepped:Connect(function()
	fill.BackgroundColor3 = if ready then Style.CHEESE:Lerp(Color3.new(1, 1, 1), math.abs(math.sin(os.clock() * 4)) * 0.5) else Style.CHEESE
end)
