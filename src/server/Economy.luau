-- Economy: every second each base's brainrots fill its cash pad; standing on the pad collects it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared.Format)
local Net = require(Shared.Net)
local PlayerState = require(script.Parent.PlayerState)
local Base = require(script.Parent.Base)

local Economy = {}

local lastCollectToast: { [Player]: number } = {}

local function isStandingOnPad(player: Player, plot): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local offset = plot.cashPad.CFrame:PointToObjectSpace(root.Position)
	return math.abs(offset.X) < 4 and math.abs(offset.Z) < 3.5 and offset.Y < 6
end

local function tickIncome()
	for player, state in PlayerState.all() do
		local plot = Base.plots()[state.plotIndex]
		local income = PlayerState.incomePerSecond(state)
		state.padCash += income
		state.totalEarned += income
		if state.padCash > 0 and isStandingOnPad(player, plot) then
			local amount = state.padCash
			state.padCash = 0
			PlayerState.addCash(player, amount)
			if os.clock() - (lastCollectToast[player] or 0) > 8 then
				lastCollectToast[player] = os.clock()
				Net.toast(player, "Collected " .. Format.money(amount) .. "!", "cash")
			end
		end
		plot.cashText.Text = Format.money(state.padCash) .. "\n+" .. Format.rate(income)
		if income > 0 then
			state.dirty = true
		end
	end
end

function Economy.start()
	task.spawn(function()
		while true do
			task.wait(1)
			tickIncome()
		end
	end)
end

return Economy
