-- Brainrot Rush: server entry. Builds the world, starts the spawner, the
-- money tick and the wave, and wires the client's buttons (lock, rebirth,
-- shop) to the server. Players get the first free base plot, leaderstats,
-- and their walk speed from their Speed Boots.

local Players = game:GetService("Players")

local BrainrotData = require(script.Parent.BrainrotData)
local GameState = require(script.Parent.GameState)
local WorldBuilder = require(script.Parent.WorldBuilder)
local Spawner = require(script.Parent.Spawner)
local Income = require(script.Parent.Income)
local Steal = require(script.Parent.Steal)
local Wave = require(script.Parent.Wave)
local Rebirth = require(script.Parent.Rebirth)
local Shop = require(script.Parent.Shop)
local Remotes = require(script.Parent.Remotes)

local events = Remotes.setup()
local world = WorldBuilder.build()

Spawner.start(world)
Income.start()
Wave.start(world)
Steal.setup(world)

-- The first free base plot for a joining player, or nil when all four are taken.
local function claimBase(player)
	local record = GameState.getPlayerData(player)
	for i, base in ipairs(world.bases) do
		if base.owner == nil then
			base.owner = player
			record.baseIndex = i
			return i
		end
	end
	record.baseIndex = nil
	return nil
end

local function freeBase(player)
	local record = GameState.getPlayerData(player)
	if record.baseIndex then
		local base = world.bases[record.baseIndex]
		if base and base.owner == player then
			base.owner = nil
		end
	end
end

local function onPlayerAdded(player)
	claimBase(player)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local moneyValue = Instance.new("IntValue")
	moneyValue.Name = "Money"
	moneyValue.Value = BrainrotData.START_MONEY
	moneyValue.Parent = leaderstats
	local rebirthsValue = Instance.new("IntValue")
	rebirthsValue.Name = "Rebirths"
	rebirthsValue.Value = 0
	rebirthsValue.Parent = leaderstats

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		local record = GameState.getPlayerData(player)
		humanoid.WalkSpeed = 16 + record.walkSpeedBonus
	end)

	events.Notify:FireClient(player, "Welcome to Brainrot Rush! Click a brainrot on the conveyor to claim it.")
end

local function onPlayerRemoving(player)
	local carried = Steal.getCarriedBy(player)
	if carried then
		Steal.dropCarried(carried)
	end
	freeBase(player)
	GameState.removePlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Lock my base: 30 seconds (longer with the Stronger Lock upgrade), then a cooldown.
events.LockBase.OnServerEvent:Connect(function(player)
	local record = GameState.getPlayerData(player)
	if not record.baseIndex then
		return
	end
	if GameState.lockBase(player) then
		Steal.setBaseLockVisual(record.baseIndex, true)
		events.Notify:FireClient(player, "Base locked for " .. record.lockSeconds .. " seconds!")
		task.delay(record.lockSeconds, function()
			Steal.setBaseLockVisual(record.baseIndex, false)
		end)
	else
		events.Notify:FireClient(player, "Lock is on cooldown. Wait a little!")
	end
end)

-- Rebirth: spend $10,000 and five brainrots for +50% income and +1 slot.
events.Rebirth.OnServerEvent:Connect(function(player)
	if not Rebirth.tryRebirth(player) then
		events.Notify:FireClient(player, "Rebirth needs $10,000 and 5 brainrots on your base.")
	end
end)

-- Buy a shop upgrade by its key (ExtraSlot, IncomeBoost, StrongerLock, SpeedBoots).
events.BuyUpgrade.OnServerEvent:Connect(function(player, upgradeKey)
	if typeof(upgradeKey) ~= "string" then
		return
	end
	if not Shop.buyUpgrade(player, upgradeKey) then
		events.Notify:FireClient(player, "Not enough money for that upgrade.")
	end
end)

-- The shop list with current prices, for the client UI.
events.GetShop.OnServerInvoke = function(player)
	return Shop.getShop(player)
end

print("Brainrot Rush server ready: 4 bases, conveyor running, wave every 90 seconds.")
