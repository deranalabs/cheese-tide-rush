-- Raider: the Night Gull flies in from the sea to snatch the lowest-rarity unlocked brainrot; bonk it to win it back.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Cast = require(Shared.Cast)
local Rarity = require(Shared.Rarity)
local Format = require(Shared.Format)
local Net = require(Shared.Net)
local PlayerState = require(script.Parent.PlayerState)
local Base = require(script.Parent.Base)
local Steal = require(script.Parent.Steal)

local Raider = {}

local rng = Random.new()
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

local function piece(model: Model, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Shape = shape or Enum.PartType.Block
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Parent = model
	return part
end

local function buildRaiderModel(): Model
	local model = Instance.new("Model")
	model.Name = "NightGullRaider"
	local root = piece(model, Vector3.new(3, 0.2, 3), CFrame.new(0, 0.1, 0), Color3.new(), nil, nil)
	root.Transparency = 1
	model.PrimaryPart = root
	piece(model, Vector3.new(5, 3.4, 3.4), CFrame.new(0, 2.5, 0) * UPRIGHT, Color3.fromRGB(35, 25, 55), Enum.PartType.Cylinder)
	piece(model, Vector3.one * 2.8, CFrame.new(0, 5.6, 0), Color3.fromRGB(235, 235, 240), Enum.PartType.Ball)
	piece(model, Vector3.new(0.9, 0.6, 1.6), CFrame.new(0, 5.3, -1.8), Color3.fromRGB(255, 150, 30))
	for _, x in { -0.6, 0.6 } do
		piece(model, Vector3.one * 0.6, CFrame.new(x, 6, -1.2), Color3.fromRGB(255, 20, 40), Enum.PartType.Ball, Enum.Material.Neon)
	end
	piece(model, Vector3.new(3.2, 0.5, 3.2), CFrame.new(0, 4.4, 0), Color3.fromRGB(20, 15, 30))
	for _, x in { -1, 1 } do
		piece(model, Vector3.new(3.5, 0.3, 1.6), CFrame.new(x * 3, 3.5, 0.3) * CFrame.Angles(0, 0, math.rad(20 * x)), Color3.fromRGB(200, 200, 210))
	end
	piece(model, Vector3.one * 2.2, CFrame.new(0, 2.6, 2.2), Color3.fromRGB(150, 110, 70), Enum.PartType.Ball)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 30, 60)
	light.Range = 14
	light.Brightness = 3
	light.Parent = root
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(10, 2.2)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 9, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 160
	gui.Parent = root
	local label = Instance.new("TextLabel")
	label.Name = "Status"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 70, 90)
	label.Text = "NIGHT GULL RAIDER"
	local stroke = Instance.new("UIStroke", label)
	stroke.Thickness = 3
	label.Parent = gui
	return model
end

-- The lowest-rarity brainrot on any unlocked base is the raider's favourite snack.
local function pickTarget()
	local best
	for player, state in PlayerState.all() do
		if Steal.isLocked(player) then
			continue
		end
		for slot, unit in state.placed do
			local rank = Rarity.INFO[Cast.get(unit.castIndex).rarity].rank
			if not best or rank < best.rank or (rank == best.rank and unit.income < best.unit.income) then
				best = { owner = player, slot = slot, unit = unit, rank = rank }
			end
		end
	end
	return best
end

local function walkTo(model: Model, goal: Vector3, speed: number, shouldStop: () -> boolean): boolean
	while true do
		local pivot = model:GetPivot()
		local flat = Vector3.new(goal.X, pivot.Position.Y, goal.Z)
		local delta = flat - pivot.Position
		if delta.Magnitude < 1 then
			return true
		end
		if shouldStop() then
			return false
		end
		local dt = task.wait()
		local step = math.min(delta.Magnitude, speed * dt)
		local nextPos = pivot.Position + delta.Unit * step
		model:PivotTo(CFrame.lookAt(nextPos, nextPos + delta.Unit))
	end
end

local function runRaid(target)
	local owner: Player = target.owner
	local ownerState = PlayerState.get(owner)
	local plot = Base.plots()[ownerState.plotIndex]
	local slotCF = plot.slots[target.slot]
	local seaPoint = plot.cframe * CFrame.new(0, 0, 40)
	local escapePoint = (plot.cframe * CFrame.new(0, 0, 75)).Position
	local model = buildRaiderModel()
	model:PivotTo(CFrame.new(seaPoint.Position.X, plot.floorTop, seaPoint.Position.Z))
	model.Parent = workspace
	local status = model.PrimaryPart:FindFirstChildWhichIsA("BillboardGui"):FindFirstChild("Status") :: TextLabel

	local bonked = false
	local loot = nil
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Bonk!"
	prompt.ObjectText = "Night Gull Raider"
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.B -- its own key, so a nearby lock button never hides it
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		if bonked then
			return
		end
		bonked = true
		local reward = math.max(25, PlayerState.incomePerSecond(PlayerState.get(player) or ownerState) * Config.RAIDER_BONK_REWARD_SECONDS)
		PlayerState.addCash(player, reward)
		Net.toastAll(player.DisplayName .. " BONKED the Night Gull Raider! +" .. Format.money(reward), "epic")
	end)

	local targetName = Cast.displayName(target.unit.castIndex, target.unit.mutation)
	Net.toast(owner, "A NIGHT GULL RAIDER is coming for your " .. targetName .. "! Lock your base or BONK it!", "bad")
	status.Text = "RAIDER: wants " .. targetName

	local function stopApproach()
		return bonked or Steal.isLocked(owner) or ownerState.placed[target.slot] ~= target.unit or not owner.Parent
	end
	local arrived = walkTo(model, (slotCF * CFrame.new(0, 0, 3.5)).Position, Config.RAIDER_SPEED, stopApproach)
	if arrived and not stopApproach() then
		status.Text = "SNATCHING " .. targetName .. "..."
		local waited = 0
		while waited < Config.RAIDER_GRAB_TIME and not stopApproach() do
			waited += task.wait()
		end
		if not stopApproach() then
			loot = Base.takeUnit(owner, target.slot)
		end
	end
	if not loot and Steal.isLocked(owner) and not bonked then
		Net.toast(owner, "The raider bounced off your laser gate!", "good")
	end

	if loot then
		status.Text = "ESCAPING WITH " .. targetName .. "!"
		Net.toast(owner, "The raider grabbed your " .. targetName .. "! Chase it and BONK it!", "bad")
		local carry = task.spawn(function()
			while loot and model.Parent do
				loot.model:PivotTo(model:GetPivot() * CFrame.new(0, 2, 3))
				task.wait()
			end
		end)
		walkTo(model, escapePoint, Config.RAIDER_SPEED * 0.6, function() -- loot is heavy: a chase is fair
			return bonked
		end)
		task.cancel(carry)
		if bonked and owner.Parent and PlayerState.get(owner) then
			local slot = Base.freeSlot(ownerState)
			if slot then
				Base.placeUnit(owner, loot, slot)
				Net.toast(owner, targetName .. " was rescued and is back home!", "good")
			else
				loot.model:Destroy()
			end
		else
			loot.model:Destroy()
			if owner.Parent then
				Net.toast(owner, "The Night Gull escaped with your " .. targetName .. "...", "bad")
			end
		end
	end
	status.Text = if bonked then "OUCH! *flees*" else "SQUAWK!"
	prompt:Destroy()
	walkTo(model, escapePoint, Config.RAIDER_SPEED * 1.5, function()
		return false
	end)
	model:Destroy()
end

Raider.NAME = "Night Gull Raider"

-- Runs one raid and publishes the raider's name on workspace attribute "RaiderName" while it is active.
local function raid(target)
	workspace:SetAttribute("RaiderName", Raider.NAME)
	local ok, err = pcall(runRaid, target)
	workspace:SetAttribute("RaiderName", nil)
	if not ok then
		warn("Raid failed: " .. tostring(err))
	end
end

function Raider.start()
	task.spawn(function()
		while true do
			task.wait(rng:NextNumber(Config.RAIDER_MIN_GAP, Config.RAIDER_MAX_GAP))
			local target = pickTarget()
			if target then
				raid(target)
			end
		end
	end)
end

-- Lets the play test start a raid right away.
function Raider.raidNow()
	local target = pickTarget()
	if target then
		task.spawn(raid, target)
	end
	return target ~= nil
end

return Raider
