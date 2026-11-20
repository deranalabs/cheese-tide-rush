-- Tide: every 45-60 s a glowing wall of neon cheese sweeps the harbour; anyone caught off a base loses what they carry.
-- Exposes sweep and start; it sets the TideState/TideNextAt workspace attributes and fires TideWarning to clients.
-- Leaves removing carried units to Carry, safe-zone checks and spawn points to Base, and the siren sound and banner to the client.

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local PlayerState = require(script.Parent.PlayerState)
local Base = require(script.Parent.Base)
local Carry = require(script.Parent.Carry)

local Tide = {}

local rng = Random.new()
local wall: Model
local HIDDEN = CFrame.new(0, -200, 0)
local CHEESE = Color3.fromRGB(255, 205, 40)

local function buildWall(): Model
	local model = Instance.new("Model")
	model.Name = "CheeseTide"
	local function slab(size: Vector3, offset: CFrame, color: Color3, transparency: number, material: Enum.Material, shape: Enum.PartType?)
		local part = Instance.new("Part")
		part.Shape = shape or Enum.PartType.Block
		part.Size = size
		part.CFrame = offset
		part.Color = color
		part.Material = material
		part.Transparency = transparency
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CastShadow = false
		part.Parent = model
		return part
	end
	local core = slab(Vector3.new(8, 22, 160), CFrame.new(0, 11, 0), CHEESE, 0.12, Enum.Material.Neon)
	model.PrimaryPart = core
	slab(Vector3.new(14, 30, 166), CFrame.new(-2, 13, 0), Color3.fromRGB(255, 240, 120), 0.7, Enum.Material.ForceField)
	-- cheese holes and a foamy crest
	for i = 1, 14 do
		local z = -75 + i * 10
		slab(Vector3.new(1, 1, 1) * (3 + (i % 3)), CFrame.new(4.2, 5 + (i * 7) % 14, z), Color3.fromRGB(215, 145, 20), 0, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		slab(Vector3.new(6, 6, 6), CFrame.new(1, 22 + (i % 2) * 1.5, z), Color3.fromRGB(255, 250, 200), 0.1, Enum.Material.Neon, Enum.PartType.Ball)
	end
	local spray = Instance.new("ParticleEmitter")
	spray.Color = ColorSequence.new(Color3.fromRGB(255, 230, 90))
	spray.LightEmission = 0.8
	spray.Rate = 120
	spray.Lifetime = NumberRange.new(1, 2)
	spray.Speed = NumberRange.new(10, 20)
	spray.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0) })
	spray.EmissionDirection = Enum.NormalId.Right
	spray.SpreadAngle = Vector2.new(40, 40)
	spray.Enabled = false
	spray.Parent = core
	local light = Instance.new("PointLight")
	light.Color = CHEESE
	light.Range = 30
	light.Brightness = 1.5
	light.Parent = core
	model:PivotTo(HIDDEN)
	model.Parent = workspace
	return model
end

local function setSirens(on: boolean)
	for _, beacon in CollectionService:GetTagged("SirenBeacon") do
		beacon.Color = if on then Color3.fromRGB(255, 30, 30) else Color3.fromRGB(90, 20, 20)
	end
end

local function catchPlayer(player: Player, state)
	local lost = Carry.dropAll(player)
	local plot = Base.plots()[state.plotIndex]
	local character = player.Character
	if character then
		character:PivotTo(plot.spawnCF)
	end
	if lost > 0 then
		Net.toast(player, "SWEPT BY THE CHEESE TIDE! You lost " .. lost .. " carried brainrot" .. (if lost > 1 then "s" else "") .. "!", "bad")
	else
		Net.toast(player, "Swept by the Cheese Tide! Back to base.", "bad")
	end
end

-- Runs one full sweep: warning, sirens, then the wall crossing the harbour.
function Tide.sweep()
	Net.event("TideWarning"):FireAllClients("warn", Config.TIDE_WARNING)
	workspace:SetAttribute("TideState", "warning")
	for i = 1, Config.TIDE_WARNING * 2 do
		setSirens(i % 2 == 1)
		task.wait(0.5)
	end
	setSirens(true)
	workspace:SetAttribute("TideState", "sweeping")
	Net.event("TideWarning"):FireAllClients("sweep", 0)
	local core = wall.PrimaryPart :: BasePart
	core:FindFirstChildWhichIsA("ParticleEmitter").Enabled = true
	local caught = {}
	local x = Config.TIDE_START_X
	while x < Config.TIDE_END_X do
		x += Config.TIDE_SPEED * RunService.Heartbeat:Wait()
		wall:PivotTo(CFrame.new(x, 11, 0))
		for player, state in PlayerState.all() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and not caught[player] and math.abs(root.Position.X - x) < Config.TIDE_HIT_HALF_WIDTH and not Base.isInsideAnyPlot(root.Position) then
				caught[player] = true
				catchPlayer(player, state)
			end
		end
	end
	core:FindFirstChildWhichIsA("ParticleEmitter").Enabled = false
	wall:PivotTo(HIDDEN)
	setSirens(false)
	workspace:SetAttribute("TideState", "calm")
	Net.event("TideWarning"):FireAllClients("calm", 0)
end

function Tide.start()
	wall = buildWall()
	workspace:SetAttribute("TideState", "calm")
	task.spawn(function()
		while true do
			local gap = rng:NextNumber(Config.TIDE_MIN_GAP, Config.TIDE_MAX_GAP)
			workspace:SetAttribute("TideNextAt", workspace:GetServerTimeNow() + gap)
			task.wait(gap - Config.TIDE_WARNING)
			local ok, err = pcall(Tide.sweep)
			if not ok then
				warn("Tide sweep failed: " .. tostring(err))
			end
		end
	end)
end

return Tide
