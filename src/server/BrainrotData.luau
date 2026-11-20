-- Brainrot Rush: the cast, the rarity ladder, mutations and income.
-- Every character is an absurd meme-born brainrot. A character standing on a
-- player's base earns money every second; rarer characters and mutations pay more.

local BrainrotData = {}

BrainrotData.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Brainrot God", "Secret" }

BrainrotData.RARITIES = {
	Common = { weight = 40, color = Color3.fromRGB(170, 170, 170), price = 25 },
	Rare = { weight = 25, color = Color3.fromRGB(80, 160, 255), price = 120 },
	Epic = { weight = 15, color = Color3.fromRGB(180, 90, 255), price = 400 },
	Legendary = { weight = 10, color = Color3.fromRGB(255, 180, 40), price = 1200 },
	Mythic = { weight = 6, color = Color3.fromRGB(255, 80, 160), price = 3500 },
	["Brainrot God"] = { weight = 3, color = Color3.fromRGB(255, 215, 0), price = 9000 },
	Secret = { weight = 1, color = Color3.fromRGB(0, 230, 200), price = 25000 },
}

-- The cast. body is the character's main colour; accessory names the extra
-- part the factory builds for it (a fin, wings, rings and so on).
BrainrotData.CHARACTERS = {
	{ name = "Tung Tung Sahur", rarity = "Common", income = 5, body = Color3.fromRGB(150, 100, 50), accessory = "Log" },
	{ name = "Noobini Pizzanini", rarity = "Common", income = 4, body = Color3.fromRGB(230, 200, 120), accessory = "Pizza" },
	{ name = "Tralalero Tralala", rarity = "Rare", income = 15, body = Color3.fromRGB(90, 140, 255), accessory = "Fin" },
	{ name = "Chimpanzini Bananini", rarity = "Rare", income = 12, body = Color3.fromRGB(240, 220, 60), accessory = "Banana" },
	{ name = "Bombardiro Crocodilo", rarity = "Epic", income = 40, body = Color3.fromRGB(80, 200, 90), accessory = "Wings" },
	{ name = "Lirili Larila", rarity = "Epic", income = 35, body = Color3.fromRGB(120, 220, 120), accessory = "Cactus" },
	{ name = "Ballerina Cappuccina", rarity = "Legendary", income = 100, body = Color3.fromRGB(255, 170, 200), accessory = "Tutu" },
	{ name = "Cappuccino Assassino", rarity = "Legendary", income = 90, body = Color3.fromRGB(120, 70, 40), accessory = "Cup" },
	{ name = "La Vaca Saturno Saturnita", rarity = "Mythic", income = 250, body = Color3.fromRGB(240, 240, 250), accessory = "Rings" },
	{ name = "Trippi Troppi", rarity = "Mythic", income = 220, body = Color3.fromRGB(255, 150, 90), accessory = "Fish" },
	{ name = "Giraffa Celeste", rarity = "Brainrot God", income = 600, body = Color3.fromRGB(255, 215, 0), accessory = "Stars" },
	{ name = "Los Tralaleritos", rarity = "Secret", income = 1500, body = Color3.fromRGB(0, 230, 200), accessory = "Rainbow" },
}

BrainrotData.MUTATIONS = {
	Normal = { chance = 70, mult = 1, color = Color3.fromRGB(255, 255, 255) },
	Gold = { chance = 18, mult = 2, color = Color3.fromRGB(255, 215, 0) },
	Diamond = { chance = 9, mult = 4, color = Color3.fromRGB(120, 220, 255) },
	Rainbow = { chance = 3, mult = 8, color = Color3.fromRGB(255, 120, 220) },
}

BrainrotData.REBIRTH_INCOME_BONUS = 0.5 -- +50% income per rebirth
BrainrotData.REBIRTH_MONEY_COST = 10000
BrainrotData.REBIRTH_BRAINROT_COST = 5
BrainrotData.START_MONEY = 100
BrainrotData.BASE_SLOTS = 6

local rng = Random.new()

-- Rolls a rarity from the weighted ladder, then a character of that rarity.
function BrainrotData.rollCharacter()
	local total = 0
	for _, rarity in ipairs(BrainrotData.RARITY_ORDER) do
		total += BrainrotData.RARITIES[rarity].weight
	end
	local roll = rng:NextNumber() * total
	local picked = "Common"
	for _, rarity in ipairs(BrainrotData.RARITY_ORDER) do
		roll -= BrainrotData.RARITIES[rarity].weight
		if roll <= 0 then
			picked = rarity
			break
		end
	end
	local pool = {}
	for _, character in ipairs(BrainrotData.CHARACTERS) do
		if character.rarity == picked then
			table.insert(pool, character)
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end

-- Rolls a mutation: most characters are Normal, a few are Gold, Diamond or Rainbow.
function BrainrotData.rollMutation()
	local roll = rng:NextInteger(1, 100)
	local acc = 0
	for name, mutation in pairs(BrainrotData.MUTATIONS) do
		acc += mutation.chance
		if roll <= acc then
			return name
		end
	end
	return "Normal"
end

-- Money per second for one character, with its mutation and the owner's rebirth bonus.
function BrainrotData.incomeFor(character, mutationName, rebirthCount)
	local mutation = BrainrotData.MUTATIONS[mutationName] or BrainrotData.MUTATIONS.Normal
	local rebirthMult = 1 + rebirthCount * BrainrotData.REBIRTH_INCOME_BONUS
	return character.income * mutation.mult * rebirthMult
end

-- The price to buy a character off the conveyor, from its rarity.
function BrainrotData.priceFor(character)
	return BrainrotData.RARITIES[character.rarity].price
end

-- The colour that marks a rarity on labels and slots.
function BrainrotData.rarityColor(rarity)
	local entry = BrainrotData.RARITIES[rarity]
	if entry then
		return entry.color
	end
	return Color3.fromRGB(255, 255, 255)
end

return BrainrotData
