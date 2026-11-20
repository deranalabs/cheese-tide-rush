-- Base: plot ownership, safe-zone checks, slot placement and the laser-gate visuals of each base.
-- Exposes assign/release, plotOf, isInsidePlot/isInsideAnyPlot, freeSlot, placeUnit/takeUnit/clearUnits, refreshSlots and setLockVisual.
-- Leaves building the plots to whoever calls init, the steal rules and lock timing to Steal (via setStealHandler), and saved state to PlayerState.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Cast = require(Shared.Cast)
local PlayerState = require(script.Parent.PlayerState)

local Base = {}

local plots = {}
local stealHandler: ((Player, Player, number) -> ())? = nil

function Base.init(builtPlots)
	plots = builtPlots
end

function Base.plots()
	return plots
end

function Base.assign(player: Player)
	for _, plot in plots do
		if not plot.owner then
			plot.owner = player
			plot.signText.Text = string.upper(player.DisplayName) .. "'S DOCK"
			return plot
		end
	end
	return nil
end

function Base.release(player: Player)
	for _, plot in plots do
		if plot.owner == player then
			plot.owner = nil
			plot.signText.Text = "EMPTY DOCK"
			plot.cashText.Text = "$0"
			Base.setLockVisual(plot, false)
		end
	end
end

function Base.plotOf(player: Player)
	local state = PlayerState.get(player)
	return state and plots[state.plotIndex]
end

function Base.isInsidePlot(plot, position: Vector3): boolean
	local localPos = plot.cframe:PointToObjectSpace(position)
	local half = Config.PLOT_SIZE / 2
	return math.abs(localPos.X) <= half.X + 1 and math.abs(localPos.Z) <= half.Z + 1
end

function Base.isInsideAnyPlot(position: Vector3): boolean
	for _, plot in plots do
		if Base.isInsidePlot(plot, position) then
			return true
		end
	end
	return false
end

function Base.freeSlot(state): number?
	for i = 1, state.slots do
		if not state.placed[i] then
			return i
		end
	end
	return nil
end

function Base.setStealHandler(handler: (Player, Player, number) -> ())
	stealHandler = handler
end

-- Puts a unit on a slot of its owner's base and gives it a steal prompt for everyone else.
function Base.placeUnit(player: Player, unit, slot: number)
	local state = PlayerState.get(player)
	local plot = plots[state.plotIndex]
	state.placed[slot] = unit
	unit.model:PivotTo(plot.slots[slot])
	unit.model.Parent = workspace
	-- neighbouring labels sit at alternating heights so names never overlap
	local label = unit.model:FindFirstChild("Label", true)
	if label then
		label.StudsOffsetWorldSpace = label:GetAttribute("BaseOffset") + Vector3.new(0, if slot % 2 == 0 then 1.6 else 0, 0)
	end
	local root = unit.model.PrimaryPart
	local old = root:FindFirstChild("StealPrompt")
	if old then
		old:Destroy()
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal"
	prompt.ObjectText = Cast.displayName(unit.castIndex, unit.mutation)
	prompt.HoldDuration = Config.STEAL_HOLD
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("OwnerUserId", player.UserId)
	prompt.Parent = root
	prompt.Triggered:Connect(function(thief)
		if stealHandler then
			stealHandler(thief, player, slot)
		end
	end)
	PlayerState.markDirty(player)
end

-- Removes a unit from its slot (for stealing, raiding or rebirth) and returns it.
function Base.takeUnit(player: Player, slot: number)
	local state = PlayerState.get(player)
	local unit = state and state.placed[slot]
	if not unit then
		return nil
	end
	state.placed[slot] = nil
	local prompt = unit.model.PrimaryPart:FindFirstChild("StealPrompt")
	if prompt then
		prompt:Destroy()
	end
	PlayerState.markDirty(player)
	return unit
end

function Base.clearUnits(player: Player)
	local state = PlayerState.get(player)
	for slot, unit in state.placed do
		unit.model:Destroy()
		state.placed[slot] = nil
	end
	PlayerState.markDirty(player)
end

-- Unlocked slots glow in the plot colour; locked ones stay dark.
function Base.refreshSlots(player: Player)
	local state = PlayerState.get(player)
	local plot = plots[state.plotIndex]
	for i, pad in plot.slotPads do
		local open = i <= state.slots
		pad.Material = if open then Enum.Material.Neon else Enum.Material.SmoothPlastic
		pad.Color = if open then plot.color else Color3.fromRGB(40, 40, 50)
		pad.Transparency = if open then 0.35 else 0.2
	end
end

function Base.setLockVisual(plot, locked: boolean)
	for _, beam in plot.gate do
		beam.Transparency = if locked then 0.1 else 1
	end
end

return Base
