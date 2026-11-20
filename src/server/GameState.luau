-- Brainrot Rush: the single place all game state lives.
-- One record per player: money, the brainrots on their base, rebirths,
-- upgrades, and the base lock. Every other module reads and writes through
-- these functions, so the state is never copied in two places.

local BrainrotData = require(script.Parent.BrainrotData)

local GameState = {}

local playerData = {} -- [userId] = record
local nextBrainrotId = 1

local function newRecord(player)
	return {
		player = player,
		money = BrainrotData.START_MONEY,
		brainrots = {}, -- [brainrotId] = brainrot record
		rebirths = 0,
		extraSlots = 0,
		incomeBoost = 0, -- +0.25 per Income Boost upgrade
		lockSeconds = 30, -- base lock duration, grows with the Stronger Lock upgrade
		lockUntil = 0, -- os.clock() timestamp the lock ends, 0 = not locked
		lockCooldownUntil = 0,
		walkSpeedBonus = 0,
		baseIndex = nil, -- the base plot this player owns
	}
end

function GameState.getPlayerData(player)
	local record = playerData[player.UserId]
	if not record then
		record = newRecord(player)
		playerData[player.UserId] = record
	end
	return record
end

function GameState.removePlayer(player)
	playerData[player.UserId] = nil
end

function GameState.newBrainrotId()
	local id = nextBrainrotId
	nextBrainrotId += 1
	return id
end

-- How many brainrots this player's base can hold.
function GameState.maxSlots(player)
	local record = GameState.getPlayerData(player)
	return BrainrotData.BASE_SLOTS + record.extraSlots + record.rebirths
end

function GameState.freeSlots(player)
	local record = GameState.getPlayerData(player)
	local used = 0
	for _ in pairs(record.brainrots) do
		used += 1
	end
	return GameState.maxSlots(player) - used
end

function GameState.addMoney(player, amount)
	local record = GameState.getPlayerData(player)
	record.money += amount
	return record.money
end

-- Takes money when the player can afford it; returns true on success.
function GameState.spendMoney(player, amount)
	local record = GameState.getPlayerData(player)
	if record.money < amount then
		return false
	end
	record.money -= amount
	return true
end

-- Puts a brainrot record on the player's base. Returns false when the base is full.
function GameState.addBrainrot(player, brainrot)
	local record = GameState.getPlayerData(player)
	if GameState.freeSlots(player) <= 0 then
		return false
	end
	record.brainrots[brainrot.id] = brainrot
	brainrot.ownerUserId = player.UserId
	brainrot.state = "base"
	return true
end

-- Takes a brainrot off the player's base (stolen, or sold back). Returns the record.
function GameState.removeBrainrot(player, brainrotId)
	local record = GameState.getPlayerData(player)
	local brainrot = record.brainrots[brainrotId]
	if brainrot then
		record.brainrots[brainrotId] = nil
	end
	return brainrot
end

function GameState.getBrainrot(player, brainrotId)
	local record = GameState.getPlayerData(player)
	return record.brainrots[brainrotId]
end

-- The income multiplier from this player's rebirths and Income Boost upgrades.
function GameState.incomeMultiplier(player)
	local record = GameState.getPlayerData(player)
	return (1 + record.rebirths * BrainrotData.REBIRTH_INCOME_BONUS) * (1 + record.incomeBoost)
end

-- Money per second across everything on this player's base.
function GameState.totalIncomePerSecond(player)
	local record = GameState.getPlayerData(player)
	local total = 0
	for _, brainrot in pairs(record.brainrots) do
		total += BrainrotData.incomeFor(brainrot.character, brainrot.mutation, record.rebirths) * (1 + record.incomeBoost)
	end
	return total
end

-- Locks the player's base against stealing until the duration runs out.
-- Returns false while the lock is on cooldown.
function GameState.lockBase(player)
	local record = GameState.getPlayerData(player)
	local now = os.clock()
	if now < record.lockCooldownUntil then
		return false
	end
	record.lockUntil = now + record.lockSeconds
	record.lockCooldownUntil = record.lockUntil + 60
	return true
end

function GameState.isBaseLocked(player)
	local record = GameState.getPlayerData(player)
	return os.clock() < record.lockUntil
end

function GameState.lockSecondsLeft(player)
	local record = GameState.getPlayerData(player)
	return math.max(0, record.lockUntil - os.clock())
end

-- Rebirth: wipes money and brainrots, grants a permanent income bonus and a slot.
-- Returns true on success, false when the player cannot afford it yet.
function GameState.doRebirth(player)
	local record = GameState.getPlayerData(player)
	local count = 0
	for _ in pairs(record.brainrots) do
		count += 1
	end
	if record.money < BrainrotData.REBIRTH_MONEY_COST or count < BrainrotData.REBIRTH_BRAINROT_COST then
		return false
	end
	record.money = BrainrotData.START_MONEY
	record.brainrots = {}
	record.rebirths += 1
	return true
end

return GameState
