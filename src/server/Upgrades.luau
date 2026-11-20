-- Upgrades: buys Speed, Slot and Lock Time levels and applies their effects.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Net = require(Shared.Net)
local PlayerState = require(script.Parent.PlayerState)
local Base = require(script.Parent.Base)

local Upgrades = {}

function Upgrades.costOf(state, kind: string): number?
	local info = Config.UPGRADES[kind]
	local level = state.levels[kind]
	if not info or level >= info.max then
		return nil
	end
	return math.floor(info.base * info.growth ^ level)
end

function Upgrades.costs(state)
	local result = {}
	for kind in Config.UPGRADES do
		result[kind] = Upgrades.costOf(state, kind) or -1
	end
	return result
end

function Upgrades.applySpeed(player: Player)
	local state = PlayerState.get(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if state and humanoid then
		humanoid.WalkSpeed = 16 + state.levels.Speed * Config.UPGRADES.Speed.step
	end
end

function Upgrades.tryBuy(player: Player, kind: string)
	local state = PlayerState.get(player)
	if not state or not Config.UPGRADES[kind] then
		return
	end
	local cost = Upgrades.costOf(state, kind)
	if not cost then
		Net.toast(player, Config.UPGRADES[kind].label .. " is maxed out!", "info")
		return
	end
	if not PlayerState.trySpend(player, cost) then
		Net.toast(player, "Need " .. Format.money(cost) .. " for " .. Config.UPGRADES[kind].label, "bad")
		return
	end
	state.levels[kind] += 1
	if kind == "Speed" then
		Upgrades.applySpeed(player)
	elseif kind == "Slots" then
		state.slots = Config.BASE_SLOTS + state.levels.Slots
		Base.refreshSlots(player)
	end
	PlayerState.markDirty(player)
	Net.toast(player, Config.UPGRADES[kind].label .. " upgraded to level " .. state.levels[kind] .. "!", "good")
end

function Upgrades.reset(player: Player)
	local state = PlayerState.get(player)
	state.levels = { Speed = 0, Slots = 0, LockTime = 0 }
	state.slots = Config.BASE_SLOTS
	Base.refreshSlots(player)
	Upgrades.applySpeed(player)
end

return Upgrades
