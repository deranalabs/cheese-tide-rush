-- Hud: draws cash, income, carried brainrots, upgrade and rebirth buttons and toasts from server snapshots.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared.Format)
local Net = require(Shared.Net)

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "Hud"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Shrinks the whole HUD on small screens so panels never overlap.
local uiScale = Instance.new("UIScale")
uiScale.Parent = gui
local function fitToScreen()
	local size = workspace.CurrentCamera.ViewportSize
	uiScale.Scale = math.clamp(math.min(size.X / 1300, size.Y / 820), 0.4, 1.4)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitToScreen)
fitToScreen()

local TOAST_COLORS = {
	info = Color3.fromRGB(60, 40, 90),
	good = Color3.fromRGB(30, 140, 70),
	bad = Color3.fromRGB(190, 40, 60),
	cash = Color3.fromRGB(20, 120, 60),
	epic = Color3.fromRGB(150, 60, 220),
}

local function newLabel(parent: Instance, text: string, size: UDim2, position: UDim2, color: Color3, anchor: Vector2?): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.AnchorPoint = anchor or Vector2.zero
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(25, 10, 35)
	stroke.Parent = label
	label.Parent = parent
	return label
end

local function panel(parent: Instance, size: UDim2, position: UDim2, anchor: Vector2?): Frame
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.AnchorPoint = anchor or Vector2.zero
	frame.BackgroundColor3 = Color3.fromRGB(25, 15, 40)
	frame.BackgroundTransparency = 0.25
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(255, 205, 60)
	stroke.Thickness = 2
	frame.Parent = parent
	return frame
end

-- Title and rebirth rank (top left)
local titlePanel = panel(gui, UDim2.fromOffset(300, 92), UDim2.fromOffset(16, 16))
newLabel(titlePanel, "CHEESE TIDE RUSH", UDim2.new(1, -20, 0, 44), UDim2.fromOffset(10, 4), Color3.fromRGB(255, 215, 60))
local rankLabel = newLabel(titlePanel, "Dock Rookie  x1", UDim2.new(1, -20, 0, 34), UDim2.fromOffset(10, 50), Color3.fromRGB(255, 255, 255))

-- Cash and income (top centre)
local cashPanel = panel(gui, UDim2.fromOffset(340, 104), UDim2.new(0.5, 0, 0, 12), Vector2.new(0.5, 0))
local cashLabel = newLabel(cashPanel, "$0", UDim2.new(1, -20, 0, 58), UDim2.fromOffset(10, 4), Color3.fromRGB(120, 255, 140))
local incomeLabel = newLabel(cashPanel, "+$0/s", UDim2.new(1, -20, 0, 36), UDim2.fromOffset(10, 62), Color3.fromRGB(255, 255, 255))

-- Carried brainrots and slot count (left)
local carryPanel = panel(gui, UDim2.fromOffset(300, 120), UDim2.fromOffset(16, 120))
local slotsLabel = newLabel(carryPanel, "Base 0/6", UDim2.new(1, -20, 0, 34), UDim2.fromOffset(10, 6), Color3.fromRGB(255, 215, 60))
local carryLabel = newLabel(carryPanel, "Buy brainrots on the lane!", UDim2.new(1, -20, 0, 70), UDim2.fromOffset(10, 42), Color3.fromRGB(255, 255, 255))
carryLabel.TextWrapped = true

-- Button bar (bottom)
local bar = Instance.new("Frame")
bar.Size = UDim2.new(0, 860, 0, 74)
bar.Position = UDim2.new(0.5, 0, 1, -14)
bar.Name = "Buttons"
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.BackgroundTransparency = 1
bar.Parent = gui
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = bar

local buttons = {}
local function button(key: string, color: Color3, onClick: () -> ())
	local b = Instance.new("TextButton")
	b.Name = key
	b.LayoutOrder = #bar:GetChildren()
	b.Size = UDim2.fromOffset(162, 74)
	b.BackgroundColor3 = color
	b.Text = key
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextScaled = true
	b.Font = Enum.Font.FredokaOne
	b.AutoButtonColor = true
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
	local pad = Instance.new("UIPadding", b)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	local stroke = Instance.new("UIStroke", b)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Thickness = 2
	b.Activated:Connect(onClick)
	b.Parent = bar
	buttons[key] = b
	return b
end

local request = Net.event("Request")
button("Lock", Color3.fromRGB(220, 40, 70), function() request:FireServer("Lock") end)
button("Speed", Color3.fromRGB(40, 150, 230), function() request:FireServer("Upgrade", "Speed") end)
button("Slots", Color3.fromRGB(230, 150, 30), function() request:FireServer("Upgrade", "Slots") end)
button("LockTime", Color3.fromRGB(140, 70, 220), function() request:FireServer("Upgrade", "LockTime") end)
button("Rebirth", Color3.fromRGB(240, 60, 180), function() request:FireServer("Rebirth") end)

-- Toasts (centre, stacked)
local toastHolder = Instance.new("Frame")
toastHolder.Size = UDim2.fromOffset(640, 260)
toastHolder.Position = UDim2.new(0.5, 0, 1, -100)
toastHolder.AnchorPoint = Vector2.new(0.5, 1)
toastHolder.BackgroundTransparency = 1
toastHolder.Parent = gui
local toastLayout = Instance.new("UIListLayout")
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.Padding = UDim.new(0, 6)
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Parent = toastHolder

local toastCount = 0
local function showToast(text: string, kind: string)
	toastCount += 1
	local frame = Instance.new("Frame")
	frame.LayoutOrder = toastCount
	frame.Size = UDim2.fromOffset(620, 44)
	frame.BackgroundColor3 = TOAST_COLORS[kind] or TOAST_COLORS.info
	frame.BackgroundTransparency = 0.1
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
	local label = newLabel(frame, text, UDim2.new(1, -16, 1, -8), UDim2.fromOffset(8, 4), Color3.new(1, 1, 1))
	label.TextWrapped = true
	frame.Parent = toastHolder
	local children = toastHolder:GetChildren()
	local frames = {}
	for _, child in children do
		if child:IsA("Frame") then
			table.insert(frames, child)
		end
	end
	if #frames > 4 then
		table.sort(frames, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
		frames[1]:Destroy()
	end
	task.delay(4.5, function()
		if frame.Parent then
			TweenService:Create(frame, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			task.wait(0.45)
			frame:Destroy()
		end
	end)
end

local lastCash = nil
local function render(snapshot)
	cashLabel.Text = Format.money(snapshot.cash)
	if lastCash and snapshot.cash > lastCash then
		cashLabel.TextColor3 = Color3.fromRGB(255, 255, 140)
		TweenService:Create(cashLabel, TweenInfo.new(0.5), { TextColor3 = Color3.fromRGB(120, 255, 140) }):Play()
	end
	lastCash = snapshot.cash
	incomeLabel.Text = "+" .. Format.rate(snapshot.income) .. "   pad " .. Format.money(snapshot.padCash)
	rankLabel.Text = snapshot.title .. "  x" .. snapshot.multiplier .. "  (rebirths " .. snapshot.rebirths .. ")"
	slotsLabel.Text = "Base " .. snapshot.used .. "/" .. snapshot.slots .. " slots"
	if #snapshot.carried > 0 then
		carryLabel.Text = "Carrying: " .. table.concat(snapshot.carried, ", ") .. " - get home!"
		carryLabel.TextColor3 = Color3.fromRGB(255, 160, 120)
	else
		carryLabel.Text = "Buy brainrots on the lane and walk them home"
		carryLabel.TextColor3 = Color3.new(1, 1, 1)
	end
	local lockText = if snapshot.lockStatus == "locked" then "LOCKED " .. snapshot.lockLeft .. "s" elseif snapshot.lockStatus == "cooldown" then "Lock in " .. snapshot.lockLeft .. "s" else "LOCK BASE [L]"
	buttons.Lock.Text = lockText
	local function costText(kind: string, label: string)
		local cost = snapshot.costs[kind]
		return label .. " Lv" .. snapshot.levels[kind] .. "\n" .. (if cost < 0 then "MAX" else Format.money(cost))
	end
	buttons.Speed.Text = costText("Speed", "Speed")
	buttons.Slots.Text = costText("Slots", "Slots")
	buttons.LockTime.Text = costText("LockTime", "Lock Time")
	buttons.Rebirth.Text = "REBIRTH\n" .. Format.money(snapshot.rebirthCost)
	buttons.Rebirth.BackgroundColor3 = if snapshot.cash >= snapshot.rebirthCost then Color3.fromRGB(255, 80, 200) else Color3.fromRGB(110, 50, 95)
end

Net.event("StateSync").OnClientEvent:Connect(render)
Net.event("Toast").OnClientEvent:Connect(showToast)
