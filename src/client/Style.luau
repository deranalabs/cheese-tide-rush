-- Style: the harbour's HUD design language (dock-ledger paper, ink, cheese yellow, tide red, hazard stripes, neon edges).
-- Exposes colours plus small builders (screen, label, paper panel, hazard strip) that the tide gauge, ledger and goal bar share.
-- Holds looks only: no game data, no remotes.

local Players = game:GetService("Players")

local Style = {}

Style.PAPER = Color3.fromRGB(244, 230, 192)
Style.PAPER_DARK = Color3.fromRGB(222, 202, 156)
Style.INK = Color3.fromRGB(52, 34, 22)
Style.CHEESE = Color3.fromRGB(255, 205, 40)
Style.TIDE_RED = Color3.fromRGB(235, 45, 55)
Style.NIGHT = Color3.fromRGB(25, 15, 40)
Style.NEON = Color3.fromRGB(255, 205, 60) -- matches the stroke of the existing HUD panels
Style.HAZARD_DARK = Color3.fromRGB(30, 22, 18)
Style.SILHOUETTE = Color3.fromRGB(14, 12, 18)

-- A ScreenGui that scales with the viewport the same way the main HUD does.
function Style.screen(name: string, displayOrder: number?): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = displayOrder or 0
	local scale = Instance.new("UIScale")
	scale.Parent = gui
	local function fit()
		local size = workspace.CurrentCamera.ViewportSize
		scale.Scale = math.clamp(math.min(size.X / 1300, size.Y / 820), 0.4, 1.4)
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	fit()
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

function Style.label(parent: Instance, text: string, size: UDim2, position: UDim2, color: Color3, strokeColor: Color3?): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	if strokeColor then
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2.5
		stroke.Color = strokeColor
		stroke.Parent = label
	end
	label.Parent = parent
	return label
end

-- Ledger paper with an ink border and a neon cheese edge.
function Style.paper(parent: Instance, size: UDim2, position: UDim2, anchor: Vector2?): Frame
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.AnchorPoint = anchor or Vector2.zero
	frame.BackgroundColor3 = Style.PAPER
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Style.NEON
	stroke.Thickness = 3
	frame.Parent = parent
	return frame
end

-- A thin strip of diagonal cheese-and-tar hazard stripes.
-- A CanvasGroup clips the rotated stripes to the strip.
function Style.hazard(parent: Instance, size: UDim2, position: UDim2, accent: Color3?): CanvasGroup
	local strip = Instance.new("CanvasGroup")
	strip.Size = size
	strip.Position = position
	strip.BackgroundColor3 = Style.HAZARD_DARK
	strip.BorderSizePixel = 0
	for i = 0, 70 do
		local stripe = Instance.new("Frame")
		stripe.Size = UDim2.new(0, 9, 4, 0)
		stripe.AnchorPoint = Vector2.new(0.5, 0.5)
		stripe.Position = UDim2.new(0, i * 18, 0.5, 0)
		stripe.Rotation = 35
		stripe.BackgroundColor3 = accent or Style.CHEESE
		stripe.BorderSizePixel = 0
		stripe.Parent = strip
	end
	strip.Parent = parent
	return strip
end

return Style
