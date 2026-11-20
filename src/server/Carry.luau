-- Carry: brainrots a player has bought or stolen follow them home and drop into free slots on arrival.
-- Exposes give, dropAll and start (a Heartbeat loop that moves carried units behind their carrier).
-- Leaves deciding when units are lost to its callers (such as Tide), and slot placement and plot geometry to Base.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cast = require(Shared.Cast)
local Format = require(Shared.Format)
local Net = require(Shared.Net)
local PlayerState = require(script.Parent.PlayerState)
local Base = require(script.Parent.Base)

local Carry = {}

function Carry.give(player: Player, unit)
	local state = PlayerState.get(player)
	table.insert(state.carried, unit)
	unit.model.Parent = workspace
	PlayerState.markDirty(player)
end

-- Every carried unit is lost (the tide washes it away, or its carrier left).
function Carry.dropAll(player: Player): number
	local state = PlayerState.get(player)
	if not state then
		return 0
	end
	local lost = #state.carried
	for _, unit in state.carried do
		unit.model:Destroy()
	end
	table.clear(state.carried)
	PlayerState.markDirty(player)
	return lost
end

local function placeCarriedAtHome(player: Player, state)
	while #state.carried > 0 do
		local slot = Base.freeSlot(state)
		if not slot then
			return
		end
		local unit = table.remove(state.carried, 1)
		Base.placeUnit(player, unit, slot)
		Net.toast(player, Cast.displayName(unit.castIndex, unit.mutation) .. " is home! +" .. Format.rate(unit.income), "good")
	end
end

local function followStep(dt: number)
	local alpha = math.clamp(dt * 6, 0, 1)
	for player, state in PlayerState.all() do
		if #state.carried == 0 then
			continue
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			continue
		end
		local plot = Base.plots()[state.plotIndex]
		if Base.isInsidePlot(plot, root.Position) then
			placeCarriedAtHome(player, state)
		end
		local feet = root.CFrame * CFrame.new(0, -3, 0)
		for i, unit in state.carried do
			local target = feet * CFrame.new((i % 2 * 2 - 1) * 2.5, 0, 4 + i * 3.5)
			local current = unit.model:GetPivot()
			unit.model:PivotTo(current:Lerp(target, alpha))
		end
	end
end

function Carry.start()
	RunService.Heartbeat:Connect(followStep)
end

return Carry
