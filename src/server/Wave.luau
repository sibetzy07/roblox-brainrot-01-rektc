-- Brainrot Rush: the threat. Every 90 seconds a tsunami wave sweeps the map
-- from north to south. Your own base (and the spawn pad) are safe; anywhere
-- else the wave knocks the brainrot you are carrying out of your hands and
-- slows you down. The warning gives you ten seconds to dash home.

local GameState = require(script.Parent.GameState)
local Steal = require(script.Parent.Steal)
local Remotes = require(script.Parent.Remotes)

local Wave = {}

local WAVE_INTERVAL = 90
local WARNING_SECONDS = 10
local SWEEP_SECONDS = 6
local SLOW_SPEED = 8
local SLOW_SECONDS = 5
local BASE_HALF_X = 15
local BASE_HALF_Z = 12
local SPAWN_SAFE_RADIUS = 14

local world = nil

-- True when the player's character stands inside their own base, or on the spawn pad.
local function isInSafeZone(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return true
	end
	local pos = root.Position
	local record = GameState.getPlayerData(player)
	local base = record.baseIndex and world.bases[record.baseIndex]
	if base then
		local c = base.center
		if math.abs(pos.X - c.X) <= BASE_HALF_X and math.abs(pos.Z - c.Z) <= BASE_HALF_Z then
			return true
		end
	end
	local s = world.spawnPosition
	if (pos - s).Magnitude <= SPAWN_SAFE_RADIUS then
		return true
	end
	return false
end

-- The wave hits a player out in the open: their carried brainrot is lost back
-- to its owner, and they walk slowly for a few seconds.
local function hitPlayer(player)
	local carried = Steal.getCarriedBy(player)
	if carried then
		Steal.dropCarried(carried)
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local record = GameState.getPlayerData(player)
		humanoid.WalkSpeed = SLOW_SPEED
		task.delay(SLOW_SECONDS, function()
			if humanoid.Parent then
				humanoid.WalkSpeed = 16 + record.walkSpeedBonus
			end
		end)
	end
end

local function sweepWave()
	local wave = world.wavePart
	wave.Transparency = 0.4
	wave.CanCollide = false
	local startZ = -110
	local endZ = 90
	local steps = SWEEP_SECONDS * 10
	for step = 1, steps do
		local t = step / steps
		local z = startZ + (endZ - startZ) * t
		wave.Position = Vector3.new(0, 13, z)
		for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and math.abs(root.Position.Z - z) < 6 and not isInSafeZone(player) then
				hitPlayer(player)
			end
		end
		task.wait(0.1)
	end
	wave.Transparency = 1
end

function Wave.start(givenWorld)
	world = givenWorld
	task.spawn(function()
		while true do
			task.wait(WAVE_INTERVAL)
			local events = Remotes.get()
			if events then
				events.WaveEvent:FireAllClients("warning", WARNING_SECONDS)
			end
			task.wait(WARNING_SECONDS)
			if events then
				events.WaveEvent:FireAllClients("start")
			end
			sweepWave()
			if events then
				events.WaveEvent:FireAllClients("end")
			end
		end
	end)
end

return Wave
