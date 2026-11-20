-- Brainrot Rush: the RemoteEvents and RemoteFunction the client and server
-- talk through. Created once, on first use, in ReplicatedStorage.
--   HudUpdate (server -> client): money and income per second.
--   WaveEvent (server -> client): "warning", "start" or "end" for the wave.
--   Notify (server -> client): a short message to show the player.
--   LockBase (client -> server): lock my base against stealing.
--   Rebirth (client -> server): spend money and brainrots on a rebirth.
--   BuyUpgrade (client -> server): buy a shop upgrade by key.
--   GetShop (RemoteFunction): the shop list with current prices.

local Remotes = {}

local events = nil

local function createEvent(name, parent)
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = parent
	return event
end

function Remotes.setup()
	if events then
		return events
	end
	local folder = Instance.new("Folder")
	folder.Name = "BrainrotRemotes"
	folder.Parent = game:GetService("ReplicatedStorage")
	local getShop = Instance.new("RemoteFunction")
	getShop.Name = "GetShop"
	getShop.Parent = folder
	events = {
		HudUpdate = createEvent("HudUpdate", folder),
		WaveEvent = createEvent("WaveEvent", folder),
		Notify = createEvent("Notify", folder),
		LockBase = createEvent("LockBase", folder),
		Rebirth = createEvent("Rebirth", folder),
		BuyUpgrade = createEvent("BuyUpgrade", folder),
		GetShop = getShop,
	}
	return events
end

function Remotes.get()
	if not events then
		return Remotes.setup()
	end
	return events
end

return Remotes
