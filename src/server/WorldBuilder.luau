-- WorldBuilder: builds the neon harbour at dusk (lighting, water, docks, market lane, 8 base plots, props).

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local WorldBuilder = {}

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

local function block(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, props: any?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if props then
		for key, value in props do
			(part :: any)[key] = value
		end
	end
	part.Parent = parent
	return part
end

local function surfaceText(part: BasePart, face: Enum.NormalId, text: string, color: Color3, background: Color3?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = if background then 0 else 1
	label.BackgroundColor3 = background or Color3.new()
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.fromRGB(30, 10, 40)
	stroke.Parent = label
	label.Parent = gui
	return label
end

local function setupLighting()
	Lighting.ClockTime = 17.75
	Lighting.GeographicLatitude = 20
	Lighting.Brightness = 3
	Lighting.ExposureCompensation = 0.35
	Lighting.Ambient = Color3.fromRGB(120, 95, 140)
	Lighting.OutdoorAmbient = Color3.fromRGB(175, 140, 175)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.6
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.32
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(255, 150, 140)
	atmosphere.Decay = Color3.fromRGB(110, 60, 140)
	atmosphere.Glare = 0.6
	atmosphere.Haze = 1.4
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.9
	bloom.Size = 30
	bloom.Threshold = 1.6
	bloom.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Saturation = 0.25
	grade.Contrast = 0.1
	grade.TintColor = Color3.fromRGB(255, 235, 245)
	grade.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.06
	rays.Parent = Lighting
end

local function buildWaterAndDocks(world: Folder)
	workspace.Terrain:FillBlock(CFrame.new(0, -8, 0), Vector3.new(1400, 12, 1400), Enum.Material.Water)
	workspace.Terrain.WaterColor = Color3.fromRGB(30, 90, 140)
	workspace.Terrain.WaterReflectance = 0.6
	workspace.Terrain.WaterWaveSize = 0.25
	block(world, "Docks", Vector3.new(300, 4, 150), CFrame.new(0, -2, 0), Color3.fromRGB(160, 115, 85), Enum.Material.WoodPlanks)
	-- pier trim and bollards along the water's edge
	for _, z in { -75.5, 75.5 } do
		block(world, "Trim", Vector3.new(300, 0.6, 1), CFrame.new(0, 0.2, z), Color3.fromRGB(0, 230, 255), Enum.Material.Neon)
		for x = -140, 140, 20 do
			block(world, "Bollard", Vector3.new(1.6, 1.6, 1.6), CFrame.new(x, 0.8, z - 2), Color3.fromRGB(40, 40, 50), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder, CFrame = CFrame.new(x, 0.8, z - 2) * UPRIGHT })
		end
	end
end

local function buildMarketLane(world: Folder)
	local laneLength = Config.LANE_END_X - Config.LANE_START_X
	block(world, "Conveyor", Vector3.new(laneLength, 0.4, 12), CFrame.new(0, 0.2, 0), Color3.fromRGB(35, 30, 45), Enum.Material.DiamondPlate)
	for _, z in { -6.3, 6.3 } do
		block(world, "LaneRail", Vector3.new(laneLength, 0.8, 0.6), CFrame.new(0, 0.5, z), if z < 0 then Color3.fromRGB(255, 60, 200) else Color3.fromRGB(0, 230, 255), Enum.Material.Neon)
	end
	for x = Config.LANE_START_X + 6, Config.LANE_END_X - 6, 12 do
		for _, side in { -1, 1 } do
			block(world, "Chevron", Vector3.new(0.4, 0.1, 3.4), CFrame.new(x, 0.42, side * 1.6) * CFrame.Angles(0, math.rad(35 * side), 0), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, { CanCollide = false })
		end
	end
	-- market gates at both ends
	for _, x in { Config.LANE_START_X, Config.LANE_END_X } do
		for _, z in { -9, 9 } do
			block(world, "GatePost", Vector3.new(2, 16, 2), CFrame.new(x, 8, z), Color3.fromRGB(60, 40, 80), Enum.Material.Metal)
		end
		local sign = block(world, "MarketSign", Vector3.new(2, 5, 22), CFrame.new(x, 17, 0), Color3.fromRGB(30, 15, 50), Enum.Material.SmoothPlastic)
		local face = if x < 0 then Enum.NormalId.Right else Enum.NormalId.Left
		surfaceText(sign, face, "BRAINROT MARKET", Color3.fromRGB(255, 220, 60))
		surfaceText(sign, if x < 0 then Enum.NormalId.Left else Enum.NormalId.Right, "BRAINROT MARKET", Color3.fromRGB(255, 220, 60))
	end
end

local function buildLamp(world: Folder, position: Vector3, color: Color3)
	block(world, "LampPole", Vector3.new(0.6, 12, 0.6), CFrame.new(position + Vector3.new(0, 6, 0)), Color3.fromRGB(30, 30, 40), Enum.Material.Metal)
	local head = block(world, "LampHead", Vector3.new(1.6, 1.6, 1.6), CFrame.new(position + Vector3.new(0, 12.5, 0)), color, Enum.Material.Neon, { Shape = Enum.PartType.Ball })
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 26
	light.Brightness = 1.6
	light.Parent = head
end

local function buildProps(world: Folder)
	local lampColors = { Color3.fromRGB(255, 80, 200), Color3.fromRGB(0, 220, 255), Color3.fromRGB(255, 200, 60) }
	local n = 0
	for x = -120, 120, 30 do
		for _, z in { -14, 14 } do
			n += 1
			buildLamp(world, Vector3.new(x, 0, z), lampColors[n % 3 + 1])
		end
	end
	-- warehouses with neon signs along the far side of the water
	local signs = { "FROMAGE & SONS", "TIDE WATCH", "CHEESE DOCK 7", "NO SWIMMING", "BRIE BAIT CO", "GOUDA FREIGHT" }
	for i, x in { -125, -75, -25, 25, 75, 125 } do
		for _, z in { -96, 96 } do
			local height = 18 + (i % 3) * 6
			local shed = block(world, "Warehouse", Vector3.new(34, height, 18), CFrame.new(x, height / 2 - 2, z), Color3.fromRGB(60 + i * 6, 45, 75), Enum.Material.Concrete)
			local sign = block(world, "WarehouseSign", Vector3.new(24, 4, 0.5), CFrame.new(x, height - 1, z - 9.3 * math.sign(z)), Color3.fromRGB(20, 10, 30))
			sign.CFrame = CFrame.lookAt(sign.Position, Vector3.new(x, height - 1, 0))
			surfaceText(sign, Enum.NormalId.Front, signs[i], lampColors[(i % 3) + 1])
			shed.Name = "Warehouse" .. i
		end
	end
	-- lighthouse at the harbour mouth
	block(world, "Lighthouse", Vector3.new(30, 10, 10), CFrame.new(165, 15, 0) * UPRIGHT, Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
	block(world, "LighthouseStripe", Vector3.new(4, 10.4, 10.4), CFrame.new(165, 14, 0) * UPRIGHT, Color3.fromRGB(230, 40, 60), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
	local lamp = block(world, "LighthouseLamp", Vector3.new(6, 6, 6), CFrame.new(165, 33, 0), Color3.fromRGB(255, 240, 150), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
	local glow = Instance.new("PointLight")
	glow.Range = 60
	glow.Brightness = 3
	glow.Color = Color3.fromRGB(255, 230, 150)
	glow.Parent = lamp
	-- siren towers the tide switches on
	for _, x in { -150, 150 } do
		for _, z in { -30, 30 } do
			block(world, "SirenPole", Vector3.new(1, 18, 1), CFrame.new(x, 9, z), Color3.fromRGB(50, 50, 60), Enum.Material.Metal)
			local beacon = block(world, "SirenBeacon", Vector3.new(2.6, 2.6, 2.6), CFrame.new(x, 19, z), Color3.fromRGB(90, 20, 20), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
			beacon:AddTag("SirenBeacon")
		end
	end
	-- moored boats
	for i, spot in { Vector3.new(-60, -1, 130), Vector3.new(40, -1, -128), Vector3.new(110, -1, 125) } do
		local hull = block(world, "BoatHull", Vector3.new(26, 4, 9), CFrame.new(spot), Color3.fromRGB(200, 60 + i * 40, 70), Enum.Material.SmoothPlastic)
		block(world, "BoatCabin", Vector3.new(8, 5, 6), hull.CFrame * CFrame.new(-4, 4.5, 0), Color3.fromRGB(240, 240, 230))
		block(world, "BoatLight", Vector3.new(1, 1, 1), hull.CFrame * CFrame.new(-4, 7.5, 0), Color3.fromRGB(0, 255, 200), Enum.Material.Neon)
	end
end

-- One plot: platform, slots, cash pad, lock button, laser gate, owner sign.
local function buildPlot(world: Folder, index: number)
	local column = (index - 1) % 4 + 1
	local side = if index <= 4 then 1 else -1
	local center = Vector3.new(Config.PLOT_COLUMNS_X[column], 0, side * Config.PLOT_ROW_Z)
	local cf = CFrame.lookAt(center, Vector3.new(center.X, 0, 0)) -- faces the market lane
	local color = Config.PLOT_COLORS[index]
	local size = Config.PLOT_SIZE

	local folder = Instance.new("Folder")
	folder.Name = "Plot" .. index
	folder.Parent = world
	local floorTop = size.Y
	block(folder, "Platform", size, cf * CFrame.new(0, size.Y / 2, 0), Color3.fromRGB(95, 75, 125), Enum.Material.Slate)
	for _, x in { -size.X / 2, size.X / 2 } do
		block(folder, "Edge", Vector3.new(0.6, 0.5, size.Z), cf * CFrame.new(x, floorTop, 0), color, Enum.Material.Neon)
	end
	block(folder, "Edge", Vector3.new(size.X, 0.5, 0.6), cf * CFrame.new(0, floorTop, size.Z / 2), color, Enum.Material.Neon)

	local slots = {}
	local slotPads = {}
	for i = 1, Config.MAX_SLOTS do
		local row = if i <= 5 then 0 else 1
		local x = ((i - 1) % 5 - 2) * 7.5
		local slotCF = cf * CFrame.new(x, floorTop, 1 + row * 8)
		slots[i] = slotCF
		slotPads[i] = block(folder, "SlotPad" .. i, Vector3.new(0.3, 5.5, 5.5), slotCF * CFrame.new(0, 0.1, 0) * UPRIGHT, color, Enum.Material.Neon, { Shape = Enum.PartType.Cylinder, CanCollide = false })
	end

	local cashPad = block(folder, "CashPad", Vector3.new(7, 0.5, 6), cf * CFrame.new(12.5, floorTop + 0.1, -10), Color3.fromRGB(40, 255, 120), Enum.Material.Neon)
	local cashText = surfaceText(block(folder, "CashBoard", Vector3.new(7, 3, 0.4), cf * CFrame.new(12.5, floorTop + 2.2, -6.8), Color3.fromRGB(10, 30, 20)), Enum.NormalId.Front, "$0", Color3.fromRGB(120, 255, 150))

	local lockButton = block(folder, "LockButton", Vector3.new(4, 1, 4), cf * CFrame.new(-12.5, floorTop + 0.5, -10), Color3.fromRGB(255, 50, 70), Enum.Material.Neon)
	local lockPrompt = Instance.new("ProximityPrompt")
	lockPrompt.ActionText = "Lock Base"
	lockPrompt.ObjectText = "Laser Gate"
	lockPrompt.HoldDuration = 0.3
	lockPrompt.KeyboardKeyCode = Enum.KeyCode.E
	lockPrompt.RequiresLineOfSight = false
	lockPrompt.Parent = lockButton
	local lockText = surfaceText(block(folder, "LockBoard", Vector3.new(7, 3, 0.4), cf * CFrame.new(-12.5, floorTop + 2.2, -6.8), Color3.fromRGB(30, 10, 15)), Enum.NormalId.Front, "LOCK READY", Color3.fromRGB(255, 120, 130))

	local gate = {}
	for _, x in { -size.X / 2, size.X / 2 } do
		block(folder, "GatePost", Vector3.new(1, 6, 1), cf * CFrame.new(x, floorTop + 3, -size.Z / 2), Color3.fromRGB(70, 70, 80), Enum.Material.Metal)
	end
	for h = 1, 4 do
		table.insert(gate, block(folder, "LaserBeam", Vector3.new(size.X, 0.25, 0.25), cf * CFrame.new(0, floorTop + h * 1.3, -size.Z / 2), Color3.fromRGB(255, 30, 50), Enum.Material.Neon, { CanCollide = false, Transparency = 1, CastShadow = false }))
	end

	local signBoard = block(folder, "OwnerSign", Vector3.new(26, 5, 0.6), cf * CFrame.new(0, floorTop + 8, size.Z / 2), Color3.fromRGB(20, 10, 30))
	block(folder, "SignPost", Vector3.new(0.8, 6, 0.8), cf * CFrame.new(-10, floorTop + 3, size.Z / 2), Color3.fromRGB(40, 40, 50), Enum.Material.Metal)
	block(folder, "SignPost", Vector3.new(0.8, 6, 0.8), cf * CFrame.new(10, floorTop + 3, size.Z / 2), Color3.fromRGB(40, 40, 50), Enum.Material.Metal)
	local signText = surfaceText(signBoard, Enum.NormalId.Front, "EMPTY DOCK", color)

	return {
		index = index,
		cframe = cf,
		floorTop = floorTop,
		color = color,
		slots = slots,
		slotPads = slotPads,
		cashPad = cashPad,
		cashText = cashText,
		lockPrompt = lockPrompt,
		lockText = lockText,
		gate = gate,
		signText = signText,
		spawnCF = cf * CFrame.new(0, floorTop + 3.5, -6),
		owner = nil,
	}
end

function WorldBuilder.build()
	setupLighting()
	local world = Instance.new("Folder")
	world.Name = "Harbour"
	world.Parent = workspace
	buildWaterAndDocks(world)
	buildMarketLane(world)
	buildProps(world)
	local plots = {}
	for i = 1, #Config.PLOT_COLORS do
		plots[i] = buildPlot(world, i)
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = CFrame.new(0, 0.5, 20)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = world
	return plots
end

return WorldBuilder
