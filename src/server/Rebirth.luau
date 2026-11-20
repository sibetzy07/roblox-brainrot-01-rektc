-- Brainrot Rush: rebirth. Spend $10,000 and five brainrots to reset your
-- money and your base, and gain a permanent +50% income and one more base slot.
-- Rebirths stack, so the climb never ends.

local BrainrotData = require(script.Parent.BrainrotData)
local GameState = require(script.Parent.GameState)
local Remotes = require(script.Parent.Remotes)

local Rebirth = {}

-- Tries a rebirth. Returns true when it goes through.
function Rebirth.tryRebirth(player)
	local record = GameState.getPlayerData(player)
	local count = 0
	for _ in pairs(record.brainrots) do
		count += 1
	end
	if record.money < BrainrotData.REBIRTH_MONEY_COST or count < BrainrotData.REBIRTH_BRAINROT_COST then
		return false
	end
	-- Clear the base's models before the state is wiped.
	for _, brainrot in pairs(record.brainrots) do
		if brainrot.model then
			brainrot.model:Destroy()
		end
	end
	GameState.doRebirth(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local rebirthsValue = leaderstats and leaderstats:FindFirstChild("Rebirths")
	if rebirthsValue then
		rebirthsValue.Value = record.rebirths
	end
	local events = Remotes.get()
	if events then
		events.Notify:FireClient(player, "Rebirth " .. record.rebirths .. "! +50% income, +1 slot!")
		events.HudUpdate:FireClient(player, record.money, 0)
	end
	return true
end

-- What a rebirth costs, and what it gives, for the client UI.
function Rebirth.getInfo(player)
	local record = GameState.getPlayerData(player)
	local count = 0
	for _ in pairs(record.brainrots) do
		count += 1
	end
	return {
		moneyCost = BrainrotData.REBIRTH_MONEY_COST,
		brainrotCost = BrainrotData.REBIRTH_BRAINROT_COST,
		money = record.money,
		brainrots = count,
		rebirths = record.rebirths,
		canAfford = record.money >= BrainrotData.REBIRTH_MONEY_COST and count >= BrainrotData.REBIRTH_BRAINROT_COST,
	}
end

return Rebirth
