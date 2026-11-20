-- PlayerState: the single home of every player's game state (cash, units, upgrades, rebirths, lock).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Cast = require(Shared.Cast)

local PlayerState = {}

local states: { [Player]: any } = {}
local nextUnitId = 0

function PlayerState.create(player: Player, plotIndex: number)
	local state = {
		player = player,
		plotIndex = plotIndex,
		cash = Config.STARTING_CASH,
		padCash = 0,
		totalEarned = 0,
		rebirths = 0,
		slots = Config.BASE_SLOTS,
		levels = { Speed = 0, Slots = 0, LockTime = 0 },
		placed = {}, -- [slotIndex] = unit
		carried = {}, -- array of units following the player
		lockedUntil = 0,
		lockReadyAt = 0,
		dirty = true,
	}
	states[player] = state
	return state
end

function PlayerState.get(player: Player)
	return states[player]
end

function PlayerState.remove(player: Player)
	states[player] = nil
end

function PlayerState.all()
	return states
end

function PlayerState.markDirty(player: Player)
	local state = states[player]
	if state then
		state.dirty = true
	end
end

-- A unit is one owned brainrot: which character, which mutation, and its model in the world.
function PlayerState.newUnit(castIndex: number, mutation: string?, model: Model)
	nextUnitId += 1
	return { id = nextUnitId, castIndex = castIndex, mutation = mutation, model = model, income = Cast.incomeOf(castIndex, mutation) }
end

function PlayerState.incomeMultiplier(state): number
	return 1 + state.rebirths * Config.REBIRTH_INCOME_BONUS
end

function PlayerState.incomePerSecond(state): number
	local sum = 0
	for _, unit in state.placed do
		sum += unit.income
	end
	return math.floor(sum * PlayerState.incomeMultiplier(state))
end

function PlayerState.addCash(player: Player, amount: number)
	local state = states[player]
	if state then
		state.cash += amount
		state.dirty = true
	end
end

function PlayerState.trySpend(player: Player, amount: number): boolean
	local state = states[player]
	if not state or state.cash < amount then
		return false
	end
	state.cash -= amount
	state.dirty = true
	return true
end

function PlayerState.usedSlots(state): number
	local count = 0
	for _ in state.placed do
		count += 1
	end
	return count
end

function PlayerState.capacityLeft(state): number
	return state.slots - PlayerState.usedSlots(state) - #state.carried
end

function PlayerState.title(state): string
	local titles = Config.REBIRTH_TITLES
	return titles[math.min(state.rebirths + 1, #titles)]
end

function PlayerState.lockStatus(state): (string, number)
	local now = os.clock()
	if now < state.lockedUntil then
		return "locked", state.lockedUntil - now
	elseif now < state.lockReadyAt then
		return "cooldown", state.lockReadyAt - now
	end
	return "ready", 0
end

-- What the client is allowed to know: plain numbers and strings, never instances.
function PlayerState.snapshot(state, extras)
	local lockStatus, lockLeft = PlayerState.lockStatus(state)
	local carried = {}
	for _, unit in state.carried do
		table.insert(carried, Cast.displayName(unit.castIndex, unit.mutation))
	end
	return {
		cash = state.cash,
		padCash = state.padCash,
		income = PlayerState.incomePerSecond(state),
		multiplier = PlayerState.incomeMultiplier(state),
		rebirths = state.rebirths,
		title = PlayerState.title(state),
		slots = state.slots,
		used = PlayerState.usedSlots(state),
		carried = carried,
		levels = state.levels,
		lockStatus = lockStatus,
		lockLeft = math.ceil(lockLeft),
		costs = extras.costs,
		rebirthCost = extras.rebirthCost,
	}
end

return PlayerState
