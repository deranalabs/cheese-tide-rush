-- BrainrotFactory: builds a brainrot character out of plain Parts, with its face, sparkle and name label.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cast = require(Shared.Cast)
local Rarity = require(Shared.Rarity)
local Format = require(Shared.Format)

local BrainrotFactory = {}

local UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- turns a cylinder's axis from X to Y

local function addPart(model: Model, props): BasePart
	local part = if props.wedge then Instance.new("WedgePart") else Instance.new("Part")
	if not props.wedge then
		(part :: Part).Shape = props.shape or Enum.PartType.Block
	end
	part.Size = props.size
	part.CFrame = props.cf
	part.Color = props.color
	part.Material = props.material or Enum.Material.SmoothPlastic
	part.Transparency = props.transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = true
	part.Name = props.name or "Piece"
	part.Parent = model
	if props.role then
		part:SetAttribute("Role", props.role)
	end
	return part
end

local function addFace(model: Model, headCF: CFrame, headSize: number, def)
	local plate = addPart(model, { size = Vector3.new(headSize, headSize, 0.05), cf = headCF * CFrame.new(0, 0, -headSize / 2 - 0.08), color = Color3.new(), transparency = 1, name = "FacePlate" })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(200, 200)
	gui.LightInfluence = 0.3
	gui.Parent = plate
	local wild = (def.index % 3) -- three face moods
	for i, x in { 0.3, 0.7 } do
		local eye = Instance.new("Frame")
		local eyeSize = if wild == 1 and i == 2 then 0.32 else 0.24
		eye.Size = UDim2.fromScale(eyeSize, eyeSize)
		eye.AnchorPoint = Vector2.new(0.5, 0.5)
		eye.Position = UDim2.fromScale(x, 0.38)
		eye.BackgroundColor3 = Color3.new(1, 1, 1)
		eye.BorderSizePixel = 0
		Instance.new("UICorner", eye).CornerRadius = UDim.new(0.5, 0)
		local stroke = Instance.new("UIStroke", eye)
		stroke.Thickness = 4
		local pupil = Instance.new("Frame")
		pupil.Size = UDim2.fromScale(0.45, 0.45)
		pupil.AnchorPoint = Vector2.new(0.5, 0.5)
		pupil.Position = UDim2.fromScale(if wild == 2 then 0.3 + (i - 1) * 0.4 else 0.55, 0.55)
		pupil.BackgroundColor3 = Color3.new(0, 0, 0)
		pupil.BorderSizePixel = 0
		Instance.new("UICorner", pupil).CornerRadius = UDim.new(0.5, 0)
		pupil.Parent = eye
		eye.Parent = gui
	end
	local mouth = Instance.new("Frame")
	mouth.AnchorPoint = Vector2.new(0.5, 0.5)
	mouth.Position = UDim2.fromScale(0.5, 0.75)
	mouth.Size = if wild == 0 then UDim2.fromScale(0.5, 0.16) elseif wild == 1 then UDim2.fromScale(0.18, 0.18) else UDim2.fromScale(0.42, 0.08)
	mouth.BackgroundColor3 = Color3.fromRGB(150, 20, 40)
	mouth.BorderSizePixel = 0
	Instance.new("UICorner", mouth).CornerRadius = UDim.new(0.5, 0)
	local tongue = Instance.new("Frame")
	tongue.Size = UDim2.fromScale(0.4, 0.5)
	tongue.Position = UDim2.fromScale(0.3, 0.5)
	tongue.BackgroundColor3 = Color3.fromRGB(255, 110, 140)
	tongue.BorderSizePixel = 0
	Instance.new("UICorner", tongue).CornerRadius = UDim.new(0.5, 0)
	tongue.Parent = mouth
	mouth.Parent = gui
end

local function addHat(model: Model, hat: string, top: CFrame, s: number, accent: Color3)
	if hat == "Crown" then
		addPart(model, { shape = Enum.PartType.Cylinder, size = Vector3.new(0.7 * s, 1.6 * s, 1.6 * s), cf = top * CFrame.new(0, 0.35 * s, 0) * UPRIGHT, color = Color3.fromRGB(255, 205, 50), material = Enum.Material.Neon })
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2
			addPart(model, { size = Vector3.new(0.3, 0.6, 0.3) * s, cf = top * CFrame.new(math.cos(a) * 0.65 * s, 0.95 * s, math.sin(a) * 0.65 * s), color = Color3.fromRGB(255, 80, 120), material = Enum.Material.Neon })
		end
	elseif hat == "Cone" then
		for i = 0, 3 do
			local d = (1.6 - i * 0.38) * s
			addPart(model, { shape = Enum.PartType.Cylinder, size = Vector3.new(0.45 * s, d, d), cf = top * CFrame.new(0, (0.22 + i * 0.42) * s, 0) * UPRIGHT, color = if i % 2 == 0 then accent else Color3.fromRGB(255, 255, 255) })
		end
	elseif hat == "Antenna" then
		addPart(model, { shape = Enum.PartType.Cylinder, size = Vector3.new(1.4 * s, 0.15, 0.15), cf = top * CFrame.new(0, 0.7 * s, 0) * UPRIGHT, color = Color3.fromRGB(60, 60, 60) })
		addPart(model, { shape = Enum.PartType.Ball, size = Vector3.one * 0.55 * s, cf = top * CFrame.new(0, 1.5 * s, 0), color = accent, material = Enum.Material.Neon })
	elseif hat == "Halo" then
		addPart(model, { shape = Enum.PartType.Cylinder, size = Vector3.new(0.15, 2 * s, 2 * s), cf = top * CFrame.new(0, 0.9 * s, 0) * UPRIGHT, color = Color3.fromRGB(255, 245, 160), material = Enum.Material.Neon, transparency = 0.25 })
	elseif hat == "Cheese" then
		addPart(model, { wedge = true, size = Vector3.new(1.2, 0.9, 1.6) * s, cf = top * CFrame.new(0, 0.45 * s, 0), color = Color3.fromRGB(255, 205, 60) })
	elseif hat == "Captain" then
		addPart(model, { shape = Enum.PartType.Cylinder, size = Vector3.new(0.15 * s, 2.1 * s, 2.1 * s), cf = top * CFrame.new(0, 0.1 * s, 0) * UPRIGHT, color = Color3.fromRGB(30, 40, 80) })
		addPart(model, { shape = Enum.PartType.Cylinder, size = Vector3.new(0.6 * s, 1.4 * s, 1.4 * s), cf = top * CFrame.new(0, 0.45 * s, 0) * UPRIGHT, color = Color3.fromRGB(245, 245, 245) })
		addPart(model, { size = Vector3.new(0.4, 0.4, 0.1) * s, cf = top * CFrame.new(0, 0.5 * s, -0.72 * s), color = accent, material = Enum.Material.Neon })
	elseif hat == "Horns" then
		for _, side in { -1, 1 } do
			addPart(model, { wedge = true, size = Vector3.new(0.3, 1.1, 0.6) * s, cf = top * CFrame.new(side * 0.6 * s, 0.4 * s, 0) * CFrame.Angles(0, math.rad(90 * side), math.rad(-15 * side)), color = accent, material = Enum.Material.Neon })
		end
	end
end

-- Colours a part for a mutation; Rainbow parts get a tag the client animates.
local function applyMutation(model: Model, mutation: string?)
	local info = Rarity.mutationInfo(mutation)
	if not info then
		return
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("Role") == "Skin" then
			part.Color = info.color
			part.Material = info.material
			if mutation == "Diamond" then
				part.Transparency = 0.15
				part.Reflectance = 0.3
			elseif mutation == "Rainbow" then
				CollectionService:AddTag(part, "RainbowPart")
			end
		end
	end
end

local function makeLabel(text: string, color: Color3, order: number, height: number, name: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.LayoutOrder = order
	label.Size = UDim2.fromScale(1, height)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(20, 10, 30)
	stroke.Parent = label
	return label
end

local function addBillboard(model: Model, head: BasePart, def, mutation: string?, s: number)
	local rarityInfo = Rarity.INFO[def.rarity]
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Adornee = head
	gui.Size = UDim2.fromScale(7.4, 3.3)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.4 * s + 1.6, 0)
	gui:SetAttribute("BaseOffset", gui.StudsOffsetWorldSpace)
	gui.MaxDistance = 110
	gui.LightInfluence = 0
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = gui
	gui.Parent = head
	local mutationText = if mutation then " + " .. string.upper(mutation) else ""
	makeLabel(Cast.displayName(def.index, mutation), Color3.new(1, 1, 1), 1, 0.3, "Name").Parent = gui
	local rarityColor = if mutation then (Rarity.mutationInfo(mutation) :: any).color else rarityInfo.color
	makeLabel(string.upper(def.rarity) .. mutationText, rarityColor, 2, 0.24, "Rarity").Parent = gui
	makeLabel(Format.rate(Cast.incomeOf(def.index, mutation)), Color3.fromRGB(110, 255, 120), 3, 0.26, "Income").Parent = gui
	local price = makeLabel("", Color3.fromRGB(255, 225, 90), 4, 0.2, "Price")
	price.Visible = false
	price.Parent = gui
end

-- Returns a Model whose pivot is at its feet, facing -Z.
function BrainrotFactory.build(castIndex: number, mutation: string?): Model
	local def = Cast.get(castIndex)
	local rarityInfo = Rarity.INFO[def.rarity]
	local s = rarityInfo.scale
	local model = Instance.new("Model")
	model.Name = def.name
	model:SetAttribute("CastIndex", castIndex)
	model:SetAttribute("Mutation", mutation or "")

	local root = addPart(model, { size = Vector3.new(3 * s, 0.2, 3 * s), cf = CFrame.new(0, 0.1, 0), color = Color3.new(), transparency = 1, name = "Root" })
	model.PrimaryPart = root

	-- legs
	local legH = 1 * s
	for _, x in { -0.6, 0.6 } do
		addPart(model, { shape = Enum.PartType.Cylinder, size = Vector3.new(legH, 0.5 * s, 0.5 * s), cf = CFrame.new(x * s, legH / 2, 0) * UPRIGHT, color = def.accent })
		addPart(model, { size = Vector3.new(0.6, 0.3, 0.9) * s, cf = CFrame.new(x * s, 0.15 * s, -0.2 * s), color = Color3.fromRGB(40, 30, 40) })
	end

	-- body
	local bodyTop
	local body = def.body
	if body == "Ball" then
		addPart(model, { shape = Enum.PartType.Ball, size = Vector3.one * 3 * s, cf = CFrame.new(0, legH + 1.4 * s, 0), color = def.color, role = "Skin" })
		bodyTop = legH + 2.6 * s
	elseif body == "Can" then
		addPart(model, { shape = Enum.PartType.Cylinder, size = Vector3.new(3 * s, 2.6 * s, 2.6 * s), cf = CFrame.new(0, legH + 1.5 * s, 0) * UPRIGHT, color = def.color, role = "Skin" })
		addPart(model, { shape = Enum.PartType.Cylinder, size = Vector3.new(0.4 * s, 2.75 * s, 2.75 * s), cf = CFrame.new(0, legH + 1.5 * s, 0) * UPRIGHT, color = def.accent, material = Enum.Material.Neon })
		bodyTop = legH + 3 * s
	elseif body == "Box" then
		addPart(model, { size = Vector3.new(2.8, 2.8, 2.2) * s, cf = CFrame.new(0, legH + 1.4 * s, 0), color = def.color, role = "Skin" })
		addPart(model, { size = Vector3.new(2.9, 0.35, 2.3) * s, cf = CFrame.new(0, legH + 0.6 * s, 0), color = def.accent, material = Enum.Material.Neon })
		bodyTop = legH + 2.8 * s
	elseif body == "Fish" then
		addPart(model, { shape = Enum.PartType.Ball, size = Vector3.new(2.6, 2.6, 2.6) * s, cf = CFrame.new(0, legH + 1.3 * s, 0), color = def.color, role = "Skin" })
		addPart(model, { wedge = true, size = Vector3.new(0.3, 1.8, 1.6) * s, cf = CFrame.new(0, legH + 1.4 * s, 1.9 * s), color = def.accent, material = Enum.Material.Neon })
		addPart(model, { wedge = true, size = Vector3.new(0.3, 1, 1.2) * s, cf = CFrame.new(0, legH + 2.7 * s, 0.4 * s), color = def.accent })
		bodyTop = legH + 2.4 * s
	elseif body == "Tall" then
		addPart(model, { shape = Enum.PartType.Cylinder, size = Vector3.new(3.6 * s, 1.9 * s, 1.9 * s), cf = CFrame.new(0, legH + 1.8 * s, 0) * UPRIGHT, color = def.color, role = "Skin" })
		addPart(model, { size = Vector3.new(0.5, 1.6, 0.2) * s, cf = CFrame.new(0, legH + 1.5 * s, -0.95 * s), color = def.accent, material = Enum.Material.Neon })
		bodyTop = legH + 3.6 * s
	else -- Cheese wedge with holes
		addPart(model, { wedge = true, size = Vector3.new(3, 2.6, 3) * s, cf = CFrame.new(0, legH + 1.3 * s, 0) * CFrame.Angles(0, math.rad(180), 0), color = def.color, role = "Skin" })
		for i, offset in { Vector3.new(-1.51, 0.4, 0.5), Vector3.new(1.51, -0.3, -0.4), Vector3.new(-1.51, -0.6, -0.8) } do
			addPart(model, { shape = Enum.PartType.Cylinder, size = Vector3.new(0.1, 0.5 + i * 0.12, 0.5 + i * 0.12) * s, cf = CFrame.new(offset * s + Vector3.new(0, legH + 1.3 * s, 0)), color = Color3.fromRGB(200, 140, 30) })
		end
		bodyTop = legH + 2.4 * s
	end

	-- arms
	for _, side in { -1, 1 } do
		addPart(model, { shape = Enum.PartType.Ball, size = Vector3.one * 0.8 * s, cf = CFrame.new(side * 1.6 * s, legH + 1.2 * s, -0.3 * s), color = def.accent })
	end

	-- head with face
	local headSize = 2.1 * s
	local headCF = CFrame.new(0, bodyTop + headSize / 2 - 0.2 * s, -0.2 * s)
	local head = addPart(model, { shape = Enum.PartType.Ball, size = Vector3.one * headSize, cf = headCF, color = def.color, name = "Head", role = "Skin" })
	addFace(model, headCF, headSize * 0.9, def)
	addHat(model, def.hat, headCF * CFrame.new(0, headSize / 2 - 0.15 * s, 0), s, def.accent)

	-- higher rarities sparkle and glow
	if rarityInfo.rank >= 3 or mutation then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Color = ColorSequence.new(if mutation then (Rarity.mutationInfo(mutation) :: any).color else rarityInfo.color)
		sparkle.LightEmission = 1
		sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
		sparkle.Transparency = NumberSequence.new(0.2)
		sparkle.Lifetime = NumberRange.new(0.8, 1.4)
		sparkle.Rate = rarityInfo.rank * 3
		sparkle.Speed = NumberRange.new(1.5, 3)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Parent = head
	end
	if rarityInfo.rank >= 5 then
		local light = Instance.new("PointLight")
		light.Color = rarityInfo.color
		light.Range = 12
		light.Brightness = 2
		light.Parent = head
	end

	applyMutation(model, mutation)
	addBillboard(model, head, def, mutation, s)
	return model
end

-- Shows "BUY $X" under the label while a character rides the market conveyor.
function BrainrotFactory.setPrice(model: Model, price: number?)
	local label = model:FindFirstChild("Label", true)
	local priceLabel = label and label:FindFirstChild("Price")
	if priceLabel then
		priceLabel.Visible = price ~= nil
		priceLabel.Text = if price then "BUY " .. Format.money(price) else ""
	end
end

return BrainrotFactory
