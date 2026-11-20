-- Input: keyboard shortcuts (L locks the base) and hides steal prompts on the player's own brainrots.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local player = Players.LocalPlayer
local request = Net.event("Request")

local function onLockKey(_, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin then
		request:FireServer("Lock")
	end
	return Enum.ContextActionResult.Pass
end
ContextActionService:BindAction("LockBase", onLockKey, false, Enum.KeyCode.L)

-- You cannot steal from yourself, so your own steal prompts never show.
local function hideOwnStealPrompt(instance: Instance)
	if instance:IsA("ProximityPrompt") and instance.Name == "StealPrompt" then
		if instance:GetAttribute("OwnerUserId") == player.UserId then
			instance.Enabled = false
		end
	end
end
for _, descendant in workspace:GetDescendants() do
	hideOwnStealPrompt(descendant)
end
workspace.DescendantAdded:Connect(hideOwnStealPrompt)
