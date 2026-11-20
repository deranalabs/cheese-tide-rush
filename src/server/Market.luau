-- Market: spawns brainrots onto the conveyor lane, moves them along it, and sells them to players.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Cast = require(Shared.Cast)
local Rarity = require(Shared.Rarity)
local Format = require(Shared.Format)
local Net = require(Shared.Net)
local PlayerState = require(script.Parent.PlayerState)
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local Carry = require(script.Parent.Carry)

local Market = {}

local rng = Random.new()
local belt = {}
local beltFolder: Folder
local spawnCount = 0 -- alternates label levels so neighbours on the lane never overlap

local FACING = CFrame.Angles(0, math.rad(-90), 0) -- walk along +X with the face forward

local function removeFromBelt(entry)
	local index = table.find(belt, entry)
	if index then
		table.remove(belt, index)
	end
end

function Market.tryBuy(player: Player, entry)
	local state = PlayerState.get(player)
	if not state or not table.find(belt, entry) then
		return
	end
	local name = Cast.displayName(entry.castIndex, entry.mutation)
	if PlayerState.capacityLeft(state) <= 0 then
		Net.toast(player, "No free slot! Walk your carried brainrots home or buy a Slot upgrade.", "bad")
		return
	end
	if not PlayerState.trySpend(player, entry.price) then
		Net.toast(player, "Need " .. Format.money(entry.price) .. " for " .. name, "bad")
		return
	end
	removeFromBelt(entry)
	entry.prompt:Destroy()
	BrainrotFactory.setPrice(entry.model, nil)
	local unit = PlayerState.newUnit(entry.castIndex, entry.mutation, entry.model)
	Carry.give(player, unit)
	local def = Cast.get(entry.castIndex)
	Net.toast(player, "Bought " .. name .. "! \"" .. def.quip .. "\" Walk it home!", "good")
	if Rarity.INFO[def.rarity].rank >= 5 then
		Net.toastAll(player.DisplayName .. " bought a " .. string.upper(def.rarity) .. " " .. name .. "!", "epic")
	end
end

local function spawnOnBelt()
	local castIndex = Cast.rollIndex(rng)
	local mutation = Rarity.rollMutation(rng)
	local model = BrainrotFactory.build(castIndex, mutation)
	local price = Cast.priceOf(castIndex, mutation)
	BrainrotFactory.setPrice(model, price)
	spawnCount += 1
	local label = model:FindFirstChild("Label", true)
	if label then
		label:SetAttribute("Level", spawnCount % 2)
	end
	local entry = { castIndex = castIndex, mutation = mutation, model = model, price = price, x = Config.LANE_START_X }
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy " .. Format.money(price)
	prompt.ObjectText = Cast.displayName(castIndex, mutation)
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = Config.BUY_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		Market.tryBuy(player, entry)
	end)
	entry.prompt = prompt
	model:PivotTo(CFrame.new(entry.x, 0.4, 0) * FACING)
	model.Parent = beltFolder
	table.insert(belt, entry)
end

local function moveBelt(dt: number)
	for i = #belt, 1, -1 do
		local entry = belt[i]
		entry.x += Config.LANE_SPEED * dt
		if entry.x > Config.LANE_END_X then
			entry.model:Destroy()
			table.remove(belt, i)
		else
			local bob = math.abs(math.sin(entry.x * 0.9)) * 0.35
			entry.model:PivotTo(CFrame.new(entry.x, 0.4 + bob, 0) * FACING)
		end
	end
end

-- Pre-fills the lane so the market is busy from the first second.
local function prefill()
	local count = math.floor((Config.LANE_END_X - Config.LANE_START_X) / (Config.LANE_SPEED * Config.SPAWN_INTERVAL))
	for i = 1, count do
		spawnOnBelt()
		belt[#belt].x = Config.LANE_END_X - i * Config.LANE_SPEED * Config.SPAWN_INTERVAL
	end
end

function Market.start()
	beltFolder = Instance.new("Folder")
	beltFolder.Name = "MarketBelt"
	beltFolder.Parent = workspace
	prefill()
	RunService.Heartbeat:Connect(moveBelt)
	task.spawn(function()
		while true do
			task.wait(Config.SPAWN_INTERVAL)
			spawnOnBelt()
		end
	end)
end

return Market
