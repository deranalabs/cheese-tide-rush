-- Steal: grabbing an unlocked brainrot from another base, and the timed laser-gate lock that defends a base.
-- Exposes lockDuration, isLocked, tryLock and start (which wires the lock prompts, the steal handler and the lock-board refresh).
-- Leaves slot storage and plot visuals to Base, carrying the loot home to Carry, and saved state to PlayerState.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Cast = require(Shared.Cast)
local Net = require(Shared.Net)
local PlayerState = require(script.Parent.PlayerState)
local Base = require(script.Parent.Base)
local Carry = require(script.Parent.Carry)

local Steal = {}

function Steal.lockDuration(state): number
	return Config.LOCK_BASE_TIME + state.levels.LockTime * Config.LOCK_TIME_STEP
end

function Steal.isLocked(player: Player): boolean
	local state = PlayerState.get(player)
	return state ~= nil and os.clock() < state.lockedUntil
end

function Steal.tryLock(player: Player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	local status, left = PlayerState.lockStatus(state)
	if status ~= "ready" then
		Net.toast(player, if status == "locked" then "Already locked!" else ("Lock recharging: " .. math.ceil(left) .. "s"), "bad")
		return
	end
	local duration = Steal.lockDuration(state)
	state.lockedUntil = os.clock() + duration
	state.lockReadyAt = state.lockedUntil + Config.LOCK_COOLDOWN
	Base.setLockVisual(Base.plots()[state.plotIndex], true)
	PlayerState.markDirty(player)
	Net.toast(player, "Laser gate ON for " .. duration .. "s. Nobody steals from you now!", "good")
end

local function tryStealUnit(thief: Player, owner: Player, slot: number)
	if thief == owner then
		return
	end
	local thiefState = PlayerState.get(thief)
	local ownerState = PlayerState.get(owner)
	if not thiefState or not ownerState then
		return
	end
	if Steal.isLocked(owner) then
		Net.toast(thief, "That base is locked behind a laser gate!", "bad")
		return
	end
	if PlayerState.capacityLeft(thiefState) <= 0 then
		Net.toast(thief, "Your base is full, no room for loot!", "bad")
		return
	end
	local unit = Base.takeUnit(owner, slot)
	if not unit then
		return
	end
	Carry.give(thief, unit)
	local name = Cast.displayName(unit.castIndex, unit.mutation)
	Net.toast(thief, "You stole " .. name .. "! Run home!", "epic")
	Net.toast(owner, thief.DisplayName .. " stole your " .. name .. "! Lock your base!", "bad")
end

-- Refreshes each base's lock board and switches gates off when their time runs out.
local function refreshLockBoards()
	for _, plot in Base.plots() do
		local state = plot.owner and PlayerState.get(plot.owner)
		if not state then
			continue
		end
		local status, left = PlayerState.lockStatus(state)
		Base.setLockVisual(plot, status == "locked")
		if status == "locked" then
			plot.lockText.Text = "LOCKED " .. math.ceil(left) .. "s"
		elseif status == "cooldown" then
			plot.lockText.Text = "RECHARGE " .. math.ceil(left) .. "s"
		else
			plot.lockText.Text = "LOCK READY"
		end
		state.dirty = true
	end
end

function Steal.start()
	Base.setStealHandler(tryStealUnit)
	for _, plot in Base.plots() do
		plot.lockPrompt.Triggered:Connect(function(player)
			if plot.owner == player then
				Steal.tryLock(player)
			else
				Net.toast(player, "That is not your lock button!", "bad")
			end
		end)
	end
	task.spawn(function()
		while true do
			task.wait(0.5)
			refreshLockBoards()
		end
	end)
end

return Steal
