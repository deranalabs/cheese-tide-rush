-- Ledger: the Dock Ledger collection panel, the slim rarity ladder in the HUD corner and the NEW IN THE LEDGER banner.
-- Reads the cast from Cast/Rarity and the player's found set and base income from StateSync snapshots (the server owns both).
-- Toggled with the I key, the LEDGER button it adds to the HUD's bottom bar, or its X; hidden panels never block the game.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cast = require(Shared.Cast)
local Rarity = require(Shared.Rarity)
local Format = require(Shared.Format)
local Net = require(Shared.Net)
local Style = require(script.Parent.Style)

local CARD_W, CARD_H, GAP = 118, 100, 8
local TOTAL = #Cast.CHARACTERS

-- Cast grouped by rarity, lowest first; each rarity is one column of the ledger.
local columns: { [string]: { number } } = {}
local rows = 0
for _, rarityName in Rarity.ORDER do
	columns[rarityName] = {}
end
for index, def in Cast.CHARACTERS do
	table.insert(columns[def.rarity], index)
	rows = math.max(rows, #columns[def.rarity])
end

local gui = Style.screen("Ledger", 5)

---------------------------------------------------------------- the panel
local gridW = #Rarity.ORDER * (CARD_W + GAP) - GAP
local panelW = gridW + 24
local panelH = 164 + rows * (CARD_H + GAP) - GAP + 14
local panel = Style.paper(gui, UDim2.fromOffset(panelW, panelH), UDim2.new(0.5, 0, 0.5, -20), Vector2.new(0.5, 0.5))
panel.Name = "LedgerPanel"
panel.Visible = false
Style.hazard(panel, UDim2.new(1, -24, 0, 12), UDim2.fromOffset(12, 8))

Style.label(panel, "DOCK LEDGER", UDim2.fromOffset(280, 46), UDim2.fromOffset(16, 24), Style.INK)
local foundLabel = Style.label(panel, "FOUND 0 / " .. TOTAL, UDim2.fromOffset(260, 46), UDim2.fromOffset(310, 24), Style.TIDE_RED)
local incomeLabel = Style.label(panel, "BASE $0/s", UDim2.fromOffset(250, 46), UDim2.fromOffset(584, 24), Color3.fromRGB(30, 130, 60))

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(46, 46)
close.Position = UDim2.new(1, -58, 0, 24)
close.BackgroundColor3 = Style.TIDE_RED
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextScaled = true
close.Font = Enum.Font.FredokaOne
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 10)
close.Parent = panel

-- one honest line of counts, straight from the data modules
local countsText = TOTAL .. " BRAINROTS   |   " .. #Rarity.ORDER .. " RARITIES   |   " .. #Rarity.MUTATIONS .. " MUTATIONS"
Style.label(panel, countsText, UDim2.new(1, -32, 0, 26), UDim2.fromOffset(16, 74), Style.INK)

-- rarity ladder ribbon: one segment per rarity, lowest to highest, above its column
local ladderSegments = {}
for col, rarityName in Rarity.ORDER do
	local seg = Instance.new("Frame")
	seg.Size = UDim2.fromOffset(CARD_W, 50)
	seg.Position = UDim2.fromOffset(12 + (col - 1) * (CARD_W + GAP), 106)
	seg.BackgroundColor3 = Rarity.INFO[rarityName].color
	Instance.new("UICorner", seg).CornerRadius = UDim.new(0, 8)
	local edge = Instance.new("UIStroke", seg)
	edge.Color = Style.INK
	edge.Thickness = 2
	seg.Parent = panel
	Style.label(seg, string.upper(rarityName), UDim2.new(1, -8, 0, 24), UDim2.fromOffset(4, 2), Style.INK)
	local count = Style.label(seg, "0/" .. #columns[rarityName], UDim2.new(1, -8, 0, 22), UDim2.fromOffset(4, 26), Style.INK)
	local star = Style.label(seg, "★", UDim2.fromOffset(30, 30), UDim2.new(1, -24, 0, -12), Color3.fromRGB(255, 200, 0), Style.INK)
	star.Visible = false
	ladderSegments[rarityName] = { count = count, star = star }
end

-- one card per character
local cards = {}
for col, rarityName in Rarity.ORDER do
	local color = Rarity.INFO[rarityName].color
	for row, index in columns[rarityName] do
		local def = Cast.get(index)
		local card = Instance.new("Frame")
		card.Name = "Card" .. index
		card.Size = UDim2.fromOffset(CARD_W, CARD_H)
		card.Position = UDim2.fromOffset(12 + (col - 1) * (CARD_W + GAP), 164 + (row - 1) * (CARD_H + GAP))
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
		local border = Instance.new("UIStroke", card)
		border.Color = color
		border.Thickness = 4
		card.Parent = panel
		local ribbon = Instance.new("Frame")
		ribbon.Size = UDim2.new(1, 0, 0, 22)
		ribbon.BackgroundColor3 = color
		ribbon.BorderSizePixel = 0
		Instance.new("UICorner", ribbon).CornerRadius = UDim.new(0, 6)
		ribbon.Parent = card
		Style.label(ribbon, string.upper(rarityName), UDim2.new(1, -8, 1, -4), UDim2.fromOffset(4, 2), Style.INK)
		local name = Style.label(card, def.name, UDim2.new(1, -10, 0, 44), UDim2.fromOffset(5, 26), Style.INK)
		name.TextWrapped = true
		local income = Style.label(card, Format.rate(Cast.incomeOf(index)), UDim2.new(1, -10, 0, 24), UDim2.fromOffset(5, 72), Color3.fromRGB(30, 130, 60))
		cards[index] = { card = card, name = name, income = income, def = def }
	end
end

local function paintCard(index: number, isFound: boolean)
	local entry = cards[index]
	if isFound then
		entry.card.BackgroundColor3 = Style.PAPER_DARK
		entry.name.Text = entry.def.name
		entry.name.TextColor3 = Style.INK
		entry.income.Visible = true
	else
		entry.card.BackgroundColor3 = Style.SILHOUETTE
		entry.name.Text = "???"
		entry.name.TextColor3 = Color3.fromRGB(110, 105, 120)
		entry.income.Visible = false
	end
end

---------------------------------------------------------------- the slim ladder in the HUD corner
local corner = Style.paper(gui, UDim2.fromOffset(214, 40 + #Rarity.ORDER * 30), UDim2.new(0, 16, 1, -100), Vector2.new(0, 1))
corner.Name = "RarityLadder"
Style.label(corner, "CAST TIERS", UDim2.new(1, -16, 0, 28), UDim2.fromOffset(8, 6), Style.INK)
local cornerCounts = {}
for rank, rarityName in Rarity.ORDER do
	local y = 36 + (#Rarity.ORDER - rank) * 30 -- highest at the top of the ladder
	local chip = Instance.new("Frame")
	chip.Size = UDim2.fromOffset(22, 22)
	chip.Position = UDim2.fromOffset(10, y + 2)
	chip.BackgroundColor3 = Rarity.INFO[rarityName].color
	Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 5)
	local chipEdge = Instance.new("UIStroke", chip)
	chipEdge.Color = Style.INK
	chipEdge.Thickness = 2
	chip.Parent = corner
	local text = Style.label(corner, string.upper(rarityName), UDim2.fromOffset(126, 24), UDim2.fromOffset(38, y + 1), Style.INK)
	text.TextXAlignment = Enum.TextXAlignment.Left
	local count = Style.label(corner, "0/" .. #columns[rarityName], UDim2.fromOffset(42, 24), UDim2.fromOffset(164, y + 1), Style.INK)
	count.TextXAlignment = Enum.TextXAlignment.Right
	cornerCounts[rarityName] = count
end

---------------------------------------------------------------- the LEDGER button on the HUD's bottom bar
local ledgerButton = Instance.new("TextButton")
ledgerButton.Name = "Ledger"
ledgerButton.LayoutOrder = 100
ledgerButton.Size = UDim2.fromOffset(162, 74)
ledgerButton.BackgroundColor3 = Style.PAPER
ledgerButton.Text = "LEDGER\n0/" .. TOTAL
ledgerButton.TextColor3 = Style.INK
ledgerButton.TextScaled = true
ledgerButton.Font = Enum.Font.FredokaOne
Instance.new("UICorner", ledgerButton).CornerRadius = UDim.new(0, 12)
local pad = Instance.new("UIPadding", ledgerButton)
pad.PaddingTop = UDim.new(0, 6)
pad.PaddingBottom = UDim.new(0, 6)
local buttonEdge = Instance.new("UIStroke", ledgerButton)
buttonEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
buttonEdge.Color = Style.NEON
buttonEdge.Thickness = 3
task.spawn(function()
	local hud = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Hud", 30)
	local bar = hud and hud:WaitForChild("Buttons", 30)
	ledgerButton.Parent = bar or gui
end)

local function toggle()
	panel.Visible = not panel.Visible
	corner.Visible = not panel.Visible -- the full ladder is in the panel; never stack two panels
end
ledgerButton.Activated:Connect(toggle)
close.Activated:Connect(toggle)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.I then
		toggle()
	end
end)

---------------------------------------------------------------- NEW IN THE LEDGER banner
local bannerQueue = 0
local function banner(index: number)
	local def = Cast.get(index)
	local color = Rarity.INFO[def.rarity].color
	local delaySeconds = bannerQueue * 1.4
	bannerQueue += 1
	task.delay(delaySeconds, function()
		bannerQueue -= 1
		local frame = Style.paper(gui, UDim2.fromOffset(600, 62), UDim2.new(0.5, 0, 0, -80), Vector2.new(0.5, 0))
		frame:FindFirstChildWhichIsA("UIStroke").Color = color
		frame:FindFirstChildWhichIsA("UIStroke").Thickness = 4
		Style.hazard(frame, UDim2.new(0, 14, 1, -12), UDim2.fromOffset(6, 6), color)
		Style.label(frame, "NEW IN THE LEDGER: " .. string.upper(def.name) .. ", " .. string.upper(def.rarity), UDim2.new(1, -44, 1, -14), UDim2.fromOffset(28, 7), Style.INK)
		TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0, 252) }):Play()
		task.wait(3.2)
		TweenService:Create(frame, TweenInfo.new(0.3), { Position = UDim2.new(0.5, 0, 0, -80) }):Play()
		task.wait(0.35)
		frame:Destroy()
	end)
end

---------------------------------------------------------------- state
local known: { [number]: boolean }? = nil
local function render(snapshot)
	local found = {}
	for _, index in snapshot.found or {} do
		found[index] = true
	end
	local foundCount = 0
	for index in cards do
		local isFound = found[index] == true
		paintCard(index, isFound)
		if isFound then
			foundCount += 1
			if known and not known[index] then
				banner(index)
			end
		end
	end
	known = found
	for _, rarityName in Rarity.ORDER do
		local have = 0
		for _, index in columns[rarityName] do
			if found[index] then
				have += 1
			end
		end
		local total = #columns[rarityName]
		ladderSegments[rarityName].count.Text = have .. "/" .. total
		ladderSegments[rarityName].star.Visible = have == total
		cornerCounts[rarityName].Text = have .. "/" .. total
		cornerCounts[rarityName].TextColor3 = if have == total then Color3.fromRGB(190, 130, 0) else Style.INK
	end
	foundLabel.Text = "FOUND " .. foundCount .. " / " .. TOTAL
	incomeLabel.Text = "BASE " .. Format.rate(snapshot.income)
	ledgerButton.Text = "LEDGER\n" .. foundCount .. "/" .. TOTAL
end

for index in cards do
	paintCard(index, false)
end
Net.event("StateSync").OnClientEvent:Connect(render)
