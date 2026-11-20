-- WorldFx: the Cheese Tide warning banner, screen flash and shake, and the Rainbow mutation shimmer.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local gui = Instance.new("ScreenGui")
gui.Name = "TideFx"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")

local tint = Instance.new("Frame")
tint.Size = UDim2.fromScale(1, 1)
tint.BackgroundColor3 = Color3.fromRGB(255, 200, 30)
tint.BackgroundTransparency = 1
tint.BorderSizePixel = 0
tint.Parent = gui

local banner = Instance.new("TextLabel")
banner.Size = UDim2.new(0.8, 0, 0, 90)
banner.Position = UDim2.new(0.5, 0, 0.36, 0)
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.BackgroundColor3 = Color3.fromRGB(200, 20, 40)
banner.BackgroundTransparency = 0.1
banner.TextColor3 = Color3.fromRGB(255, 240, 120)
banner.Font = Enum.Font.FredokaOne
banner.TextScaled = true
banner.Visible = false
Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 16)
local bannerStroke = Instance.new("UIStroke", banner)
bannerStroke.Thickness = 4
bannerStroke.Color = Color3.fromRGB(255, 220, 60)
bannerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
banner.Parent = gui
local bannerScale = Instance.new("UIScale")
bannerScale.Parent = banner
local function fitBanner()
	bannerScale.Scale = math.clamp(camera.ViewportSize.Y / 820, 0.4, 1.4)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitBanner)
fitBanner()

local phase = "calm"
local warnEndsAt = 0

local function onTideWarning(newPhase: string, seconds: number)
	phase = newPhase
	if newPhase == "warn" then
		warnEndsAt = os.clock() + seconds
		banner.Visible = true
	elseif newPhase == "sweep" then
		banner.Visible = true
		banner.Text = "THE CHEESE TIDE IS HERE! STAY ON A BASE!"
	else
		banner.Visible = false
		tint.BackgroundTransparency = 1
	end
end
Net.event("TideWarning").OnClientEvent:Connect(onTideWarning)

local function tideWallX(): number?
	local wall = workspace:FindFirstChild("CheeseTide")
	if wall and wall.PrimaryPart and wall.PrimaryPart.Position.Y > -50 then
		return wall.PrimaryPart.Position.X
	end
	return nil
end

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	if phase == "warn" then
		local left = math.max(0, math.ceil(warnEndsAt - t))
		banner.Text = "SIREN! CHEESE TIDE IN " .. left .. "s - RUN TO A BASE!"
		banner.BackgroundColor3 = if math.floor(t * 4) % 2 == 0 then Color3.fromRGB(220, 20, 40) else Color3.fromRGB(120, 10, 30)
		tint.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
		tint.BackgroundTransparency = 0.85 + math.sin(t * 12) * 0.05
	elseif phase == "sweep" then
		local x = tideWallX()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if x and root then
			local distance = math.abs(root.Position.X - x)
			local near = math.clamp(1 - distance / 60, 0, 1)
			tint.BackgroundColor3 = Color3.fromRGB(255, 200, 30)
			tint.BackgroundTransparency = 1 - near * 0.35
			if near > 0 then
				local shake = near * 0.25
				camera.CFrame = camera.CFrame * CFrame.new(math.sin(t * 40) * shake, math.cos(t * 33) * shake, 0)
			end
		end
	end
	-- Rainbow mutation shimmer
	local hue = (t * 0.25) % 1
	for i, part in CollectionService:GetTagged("RainbowPart") do
		(part :: BasePart).Color = Color3.fromHSV((hue + i * 0.07) % 1, 0.8, 1)
	end
end)
