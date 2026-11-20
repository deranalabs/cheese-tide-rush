-- Rebirth: trades cash, brainrots and upgrades for a permanent income multiplier and a new title.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Net = require(Shared.Net)
local PlayerState = require(script.Parent.PlayerState)
local Base = require(script.Parent.Base)
local Carry = require(script.Parent.Carry)
local Upgrades = require(script.Parent.Upgrades)

local Rebirth = {}

function Rebirth.cost(state): number
	return math.floor(Config.REBIRTH_BASE_COST * Config.REBIRTH_COST_GROWTH ^ state.rebirths)
end

-- A floating title over the player's head, e.g. "Brie Baron x1.5".
function Rebirth.applyTitle(player: Player)
	local state = PlayerState.get(player)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not state or not head then
		return
	end
	local gui = head:FindFirstChild("TitleTag")
	if not gui then
		gui = Instance.new("BillboardGui")
		gui.Name = "TitleTag"
		gui.Size = UDim2.fromScale(5, 0.9)
		gui.StudsOffset = Vector3.new(0, 2.2, 0)
		gui.LightInfluence = 0
		gui.MaxDistance = 80
		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255, 220, 80)
		local stroke = Instance.new("UIStroke", label)
		stroke.Thickness = 3
		label.Parent = gui
		gui.Parent = head
	end
	gui.Text.Text = PlayerState.title(state) .. "  x" .. PlayerState.incomeMultiplier(state)
end

function Rebirth.tryRebirth(player: Player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	local cost = Rebirth.cost(state)
	if state.cash < cost then
		Net.toast(player, "Rebirth needs " .. Format.money(cost) .. " cash", "bad")
		return
	end
	Carry.dropAll(player)
	Base.clearUnits(player)
	Upgrades.reset(player)
	state.cash = Config.STARTING_CASH
	state.padCash = 0
	state.rebirths += 1
	PlayerState.markDirty(player)
	Rebirth.applyTitle(player)
	Net.toastAll(player.DisplayName .. " was REBORN as " .. PlayerState.title(state) .. "! Income x" .. PlayerState.incomeMultiplier(state), "epic")
end

return Rebirth
