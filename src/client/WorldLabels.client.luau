-- WorldLabels: keeps the text floating in the world legible in a crowd.
-- Character labels (tag "CastLabel") get a distance-aware size with an on-screen minimum, a stagger height from
-- their "Level" attribute that always clears the label below, and a fade past FADE_START.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer

local WORLD_HEIGHT = 3 -- label height in studs when close
local MIN_PIXELS = 96 -- label height floor on a 720 px tall screen (scales with the screen)
local ASPECT = 2.6 -- width over height, room for the longest name
local GAP = 0.35 -- studs between a label and the one stacked above it
local FADE_START, FADE_END = 60, 85 -- studs from the camera

local alphaOf: { [BillboardGui]: number } = setmetatable({}, { __mode = "k" }) :: any

local function setAlpha(gui: BillboardGui, alpha: number)
	if alphaOf[gui] == alpha then
		return
	end
	alphaOf[gui] = alpha
	gui.Enabled = alpha < 1
	for _, item in gui:GetDescendants() do
		if item:IsA("TextLabel") then
			item.TextTransparency = alpha
		elseif item:IsA("UIStroke") then
			item.Transparency = alpha
		end
	end
end

RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	local camPos = camera.CFrame.Position
	local viewY = camera.ViewportSize.Y
	local focal = viewY / 2 / math.tan(math.rad(camera.FieldOfView) / 2)
	local minPixels = MIN_PIXELS * viewY / 720
	for _, gui in CollectionService:GetTagged("CastLabel") do
		local adornee = gui.Adornee
		if adornee and adornee:IsA("BasePart") and adornee:IsDescendantOf(workspace) then
			local distance = (adornee.Position - camPos).Magnitude
			local height = math.max(WORLD_HEIGHT, minPixels * distance / focal)
			gui.Size = UDim2.fromScale(height * ASPECT, height)
			local lift = (height - 2) / 2 + (gui:GetAttribute("Level") or 0) * (height + GAP)
			gui.StudsOffsetWorldSpace = (gui:GetAttribute("BaseOffset") or Vector3.zero) + Vector3.new(0, lift, 0)
			setAlpha(gui, math.clamp((distance - FADE_START) / (FADE_END - FADE_START), 0, 1))
		end
	end
end)
