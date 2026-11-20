-- Brainrot Rush: stealing, carrying and the base lock.
-- Click a brainrot on somebody else's base to pick it up, then carry it home:
-- touch your own base pad and it moves in. A locked base cannot be stolen
-- from, and its red gate shows while the lock is on. Die while carrying and
-- the brainrot goes back to the player you stole it from.

local GameState = require(script.Parent.GameState)
local Remotes = require(script.Parent.Remotes)

local Steal = {}

local world = nil

-- Picks a brainrot up off another player's base. Returns true when the steal starts.
function Steal.trySteal(player, brainrot, givenWorld)
	if brainrot.state ~= "base" then
		return false
	end
	local victim = nil
	for _, other in ipairs(game:GetService("Players"):GetPlayers()) do
		if other.UserId == brainrot.ownerUserId then
			victim = other
			break
		end
	end
	if not victim or victim == player then
		return false
	end
	if GameState.isBaseLocked(victim) then
		return false
	end
	if GameState.freeSlots(player) <= 0 then
		return false
	end
	local stolen = GameState.removeBrainrot(victim, brainrot.id)
	if not stolen then
		return false
	end
	brainrot.previousOwnerUserId = victim.UserId
	brainrot.ownerUserId = nil
	brainrot.state = "carried"
	brainrot.carrier = player
	brainrot.slotIndex = nil
	Steal.markCarried(brainrot)
	local events = Remotes.get()
	if events then
		events.Notify:FireClient(player, "Stolen! Run home before the wave!")
		events.Notify:FireClient(victim, player.Name .. " stole your " .. brainrot.character.name .. "!")
	end
	return true
end

-- Gives a carried brainrot back to the player it was stolen from, when the
-- carrier dies or leaves. Destroyed when that base has no free slot.
function Steal.returnCarried(brainrot)
	local previousOwner = nil
	for _, other in ipairs(game:GetService("Players"):GetPlayers()) do
		if other.UserId == brainrot.previousOwnerUserId then
			previousOwner = other
			break
		end
	end
	if previousOwner then
		local Spawner = require(script.Parent.Spawner)
		if Spawner.placeOnBase(previousOwner, brainrot) then
			return
		end
	end
	brainrot.model:Destroy()
end

-- Shows or hides a base's red lock gate.
function Steal.setBaseLockVisual(baseIndex, locked)
	local base = world.bases[baseIndex]
	if not base then
		return
	end
	base.lockGate.Transparency = locked and 0.3 or 1
	base.lockGate.CanCollide = locked
end

-- The carried brainrots live in a module table, since no base owns them.
local carried = {}

function Steal.markCarried(brainrot)
	carried[brainrot.id] = brainrot
end

function Steal.unmarkCarried(brainrot)
	carried[brainrot.id] = nil
end

-- The brainrot a player is carrying right now, if any.
function Steal.getCarriedBy(player)
	for _, brainrot in pairs(carried) do
		if brainrot.carrier == player then
			return brainrot
		end
	end
	return nil
end

-- Drops a carried brainrot: it goes back to the player it was stolen from.
function Steal.dropCarried(brainrot)
	Steal.unmarkCarried(brainrot)
	Steal.returnCarried(brainrot)
end

-- Follows every carried brainrot above its carrier; drops it back when the
-- carrier's character is gone.
local function followLoop()
	while true do
		for id, brainrot in pairs(carried) do
			local carrier = brainrot.carrier
			local character = carrier and carrier.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if brainrot.state == "carried" and root then
				brainrot.model:PivotTo(root.CFrame + Vector3.new(0, 4, 0))
			elseif brainrot.state == "carried" then
				Steal.unmarkCarried(brainrot)
				Steal.returnCarried(brainrot)
			end
		end
		task.wait(0.1)
	end
end

-- Touching your own base pad while carrying deposits the brainrot there.
local function onBaseTouched(baseIndex, otherPart)
	local character = otherPart.Parent
	local player = character and game:GetService("Players"):GetPlayerFromCharacter(character)
	if not player then
		return
	end
	local record = GameState.getPlayerData(player)
	if record.baseIndex ~= baseIndex then
		return
	end
	for id, brainrot in pairs(carried) do
		if brainrot.carrier == player and brainrot.state == "carried" then
			local Spawner = require(script.Parent.Spawner)
			Steal.unmarkCarried(brainrot)
			if not Spawner.placeOnBase(player, brainrot) then
				Steal.returnCarried(brainrot)
			end
			return
		end
	end
end

function Steal.setup(givenWorld)
	world = givenWorld
	for i, base in ipairs(world.bases) do
		base.pad.Touched:Connect(function(otherPart)
			onBaseTouched(i, otherPart)
		end)
	end
	task.spawn(followLoop)
end

return Steal
