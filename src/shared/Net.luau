-- Net: the RemoteEvents both sides share; the server creates them, the client waits for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

local EVENT_NAMES = { "StateSync", "Toast", "TideWarning", "Request" }

local function remotesFolder(): Folder
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild("Remotes")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "Remotes"
			for _, name in EVENT_NAMES do
				local event = Instance.new("RemoteEvent")
				event.Name = name
				event.Parent = folder
			end
			folder.Parent = ReplicatedStorage
		end
		return folder
	end
	return ReplicatedStorage:WaitForChild("Remotes")
end

function Net.event(name: string): RemoteEvent
	return remotesFolder():WaitForChild(name) :: RemoteEvent
end

-- Server helpers: short coloured messages on one or all screens.
function Net.toast(player: Player, text: string, kind: string?)
	Net.event("Toast"):FireClient(player, text, kind or "info")
end

function Net.toastAll(text: string, kind: string?)
	Net.event("Toast"):FireAllClients(text, kind or "info")
end

return Net
