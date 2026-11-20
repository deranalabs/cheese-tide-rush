-- Main: boots the harbour, wires players to their bases, routes client requests and syncs state to each HUD.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)

local Server = script.Parent
local PlayerState = require(Server.PlayerState)
local WorldBuilder = require(Server.WorldBuilder)
local Base = require(Server.Base)
local Carry = require(Server.Carry)
local Market = require(Server.Market)
local Economy = require(Server.Economy)
local Steal = require(Server.Steal)
local Raider = require(Server.Raider)
local Tide = require(Server.Tide)
local Upgrades = require(Server.Upgrades)
local Rebirth = require(Server.Rebirth)

local lastRequestAt: { [Player]: number } = {}

local function onCharacterAdded(player: Player, character: Model)
	local plot = Base.plotOf(player)
	character:WaitForChild("HumanoidRootPart", 10)
	task.wait(0.1)
	if plot then
		character:PivotTo(plot.spawnCF)
	end
	Upgrades.applySpeed(player)
	Rebirth.applyTitle(player)
end

local function onPlayerAdded(player: Player)
	local plot = Base.assign(player)
	if not plot then
		player:Kick("The harbour is full (8 docks). Try another server!")
		return
	end
	PlayerState.create(player, plot.index)
	Base.refreshSlots(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("NumberValue")
	cash.Name = "Cash"
	cash.Parent = leaderstats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = leaderstats
	leaderstats.Parent = player
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
	Net.toast(player, "Welcome to Cheese Tide Rush! Buy brainrots on the market lane and walk them home.", "info")
end

local function onPlayerRemoving(player: Player)
	if not PlayerState.get(player) then
		return
	end
	Carry.dropAll(player)
	Base.clearUnits(player)
	Base.release(player)
	PlayerState.remove(player)
	lastRequestAt[player] = nil
end

local function onRequest(player: Player, action: unknown, arg: unknown)
	local now = os.clock()
	if now - (lastRequestAt[player] or 0) < 0.25 then
		return
	end
	lastRequestAt[player] = now
	if action == "Lock" then
		Steal.tryLock(player)
	elseif action == "Upgrade" and typeof(arg) == "string" then
		Upgrades.tryBuy(player, arg)
	elseif action == "Rebirth" then
		Rebirth.tryRebirth(player)
	end
end

-- Pushes a fresh snapshot to every player whose state changed.
local function syncDirtyStates()
	for player, state in PlayerState.all() do
		if not state.dirty then
			continue
		end
		state.dirty = false
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			leaderstats.Cash.Value = state.cash
			leaderstats.Rebirths.Value = state.rebirths
		end
		Net.event("StateSync"):FireClient(player, PlayerState.snapshot(state, { costs = Upgrades.costs(state), rebirthCost = Rebirth.cost(state) }))
	end
end

local plots = WorldBuilder.build()
Base.init(plots)
Carry.start()
Market.start()
Economy.start()
Steal.start()
Raider.start()
Tide.start()

Net.event("Request").OnServerEvent:Connect(onRequest)
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

-- Studio-only hook so a play test can trigger events on demand (never created in a live server).
local function createPlayTestHook()
	local hook = Instance.new("BindableFunction")
	hook.Name = "PlayTestHook"
	hook.OnInvoke = function(action: string, player: Player, value: any)
		if action == "cash" then
			PlayerState.addCash(player, value)
		elseif action == "raid" then
			return Raider.raidNow()
		elseif action == "tide" then
			task.spawn(Tide.sweep)
		elseif action == "summary" then
			local state = PlayerState.get(player)
			local placed = {}
			for slot, unit in state.placed do
				table.insert(placed, slot .. ":" .. unit.model.Name)
			end
			return string.format("cash=%d pad=%d ips=%d carried=%d placed=[%s] slots=%d rebirths=%d lock=%s", state.cash, state.padCash, PlayerState.incomePerSecond(state), #state.carried, table.concat(placed, ","), state.slots, state.rebirths, (PlayerState.lockStatus(state)))
		end
		return true
	end
	hook.Parent = game:GetService("ServerStorage")
end
if game:GetService("RunService"):IsStudio() then
	createPlayTestHook()
end

while true do
	task.wait(Config.SYNC_INTERVAL)
	syncDirtyStates()
end
