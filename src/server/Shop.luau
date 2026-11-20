-- Brainrot Rush: the shop. Four upgrades, bought with money, each one more
-- expensive the more of it you already own: more base slots, faster income,
-- a longer base lock, and faster walking.

local GameState = require(script.Parent.GameState)
local Remotes = require(script.Parent.Remotes)

local Shop = {}

Shop.UPGRADES = {
	ExtraSlot = {
		name = "Extra Slot",
		desc = "+1 brainrot slot on your base",
		baseCost = 500,
	},
	IncomeBoost = {
		name = "Income Boost",
		desc = "+25% income from every brainrot",
		baseCost = 800,
	},
	StrongerLock = {
		name = "Stronger Lock",
		desc = "+15 seconds on your base lock",
		baseCost = 600,
	},
	SpeedBoots = {
		name = "Speed Boots",
		desc = "+4 walk speed",
		baseCost = 400,
	},
}

-- How many of an upgrade the player already owns, from the state it changes.
local function ownedCount(player, upgradeName)
	local record = GameState.getPlayerData(player)
	if upgradeName == "ExtraSlot" then
		return record.extraSlots
	elseif upgradeName == "IncomeBoost" then
		return math.floor(record.incomeBoost / 0.25 + 0.5)
	elseif upgradeName == "StrongerLock" then
		return math.floor((record.lockSeconds - 30) / 15 + 0.5)
	elseif upgradeName == "SpeedBoots" then
		return math.floor(record.walkSpeedBonus / 4 + 0.5)
	end
	return 0
end

-- The current price: base cost times (owned + 1).
function Shop.priceFor(player, upgradeName)
	local upgrade = Shop.UPGRADES[upgradeName]
	if not upgrade then
		return nil
	end
	return upgrade.baseCost * (ownedCount(player, upgradeName) + 1)
end

-- The shop list for the client: name, description, price and owned count.
function Shop.getShop(player)
	local list = {}
	for key, upgrade in pairs(Shop.UPGRADES) do
		table.insert(list, {
			key = key,
			name = upgrade.name,
			desc = upgrade.desc,
			price = Shop.priceFor(player, key),
			owned = ownedCount(player, key),
		})
	end
	table.sort(list, function(a, b)
		return a.price < b.price
	end)
	return list
end

-- Buys an upgrade. Returns true when the purchase goes through.
function Shop.buyUpgrade(player, upgradeName)
	local upgrade = Shop.UPGRADES[upgradeName]
	if not upgrade then
		return false
	end
	local price = Shop.priceFor(player, upgradeName)
	if not GameState.spendMoney(player, price) then
		return false
	end
	local record = GameState.getPlayerData(player)
	if upgradeName == "ExtraSlot" then
		record.extraSlots += 1
	elseif upgradeName == "IncomeBoost" then
		record.incomeBoost += 0.25
	elseif upgradeName == "StrongerLock" then
		record.lockSeconds += 15
	elseif upgradeName == "SpeedBoots" then
		record.walkSpeedBonus += 4
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16 + record.walkSpeedBonus
		end
	end
	local events = Remotes.get()
	if events then
		events.Notify:FireClient(player, upgrade.name .. " bought!")
		events.HudUpdate:FireClient(player, record.money, GameState.totalIncomePerSecond(player))
	end
	return true
end

return Shop
