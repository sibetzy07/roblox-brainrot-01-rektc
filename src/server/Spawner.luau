-- Brainrot Rush: spawns brainrots on the conveyor, walks them west to east,
-- and handles the click that claims one off the conveyor or steals one off a base.
-- A brainrot is a blocky 3D model: body, head, legs, one accessory part, and a
-- floating label with its name, rarity and money per second.

local BrainrotData = require(script.Parent.BrainrotData)
local GameState = require(script.Parent.GameState)
local Steal = require(script.Parent.Steal)

local Spawner = {}

local SPAWN_INTERVAL = 6
local CONVEYOR_WALK_SECONDS = 24
local CLAIM_DISTANCE = 32

local world = nil

-- One accessory part per character, so the cast reads as different creatures.
local function buildAccessory(accessory, body, bodyColor)
	local part = nil
	if accessory == "Fin" then
		part = Instance.new("Part")
		part.Shape = Enum.PartType.Wedge
		part.Size = Vector3.new(2, 2, 3)
		part.Position = body.Position + Vector3.new(0, 2, 0)
	elseif accessory == "Wings" then
		part = Instance.new("Part")
		part.Size = Vector3.new(6, 1, 3)
		part.Position = body.Position + Vector3.new(0, 1, 0)
	elseif accessory == "Rings" then
		part = Instance.new("Part")
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(1, 8, 8)
		part.Position = body.Position + Vector3.new(0, 0, 0)
	elseif accessory == "Tutu" then
		part = Instance.new("Part")
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(1, 6, 6)
		part.Position = body.Position + Vector3.new(0, -1, 0)
	elseif accessory == "Cup" then
		part = Instance.new("Part")
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(2, 2, 2)
		part.Position = body.Position + Vector3.new(0, 3, 0)
	elseif accessory == "Banana" then
		part = Instance.new("Part")
		part.Size = Vector3.new(1, 3, 1)
		part.Position = body.Position + Vector3.new(2, 1, 0)
	elseif accessory == "Pizza" then
		part = Instance.new("Part")
		part.Shape = Enum.PartType.Wedge
		part.Size = Vector3.new(2, 1, 2)
		part.Position = body.Position + Vector3.new(0, 2, 0)
	elseif accessory == "Cactus" then
		part = Instance.new("Part")
		part.Size = Vector3.new(1, 3, 1)
		part.Position = body.Position + Vector3.new(0, 2, 0)
	elseif accessory == "Fish" then
		part = Instance.new("Part")
		part.Shape = Enum.PartType.Wedge
		part.Size = Vector3.new(2, 2, 2)
		part.Position = body.Position + Vector3.new(0, -2, 0)
	elseif accessory == "Stars" then
		part = Instance.new("Part")
		part.Size = Vector3.new(1, 1, 1)
		part.Position = body.Position + Vector3.new(0, 3, 0)
	elseif accessory == "Rainbow" then
		part = Instance.new("Part")
		part.Size = Vector3.new(4, 1, 1)
		part.Position = body.Position + Vector3.new(0, 2, 0)
	else -- "Log": a wooden beam across the body
		part = Instance.new("Part")
		part.Size = Vector3.new(5, 1, 2)
		part.Position = body.Position + Vector3.new(0, 1, 0)
	end
	part.Name = "Accessory"
	part.Color = bodyColor
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	return part
end

-- The floating label: name on top, rarity in its colour, money per second below.
local function buildLabel(brainrot, body)
	local mutation = BrainrotData.MUTATIONS[brainrot.mutation]
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.fromOffset(150, 70)
	gui.StudsOffset = Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = body
	gui.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromOffset(150, 24)
	nameLabel.Position = UDim2.fromOffset(0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = brainrot.character.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Parent = gui

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.fromOffset(150, 20)
	rarityLabel.Position = UDim2.fromOffset(0, 24)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = brainrot.character.rarity .. "  |  " .. brainrot.mutation
	rarityLabel.TextColor3 = BrainrotData.rarityColor(brainrot.character.rarity)
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.TextSize = 15
	rarityLabel.Font = Enum.Font.SourceSansBold
	rarityLabel.Parent = gui

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Size = UDim2.fromOffset(150, 20)
	incomeLabel.Position = UDim2.fromOffset(0, 44)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = "$" .. brainrot.income .. "/s"
	incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	incomeLabel.TextStrokeTransparency = 0
	incomeLabel.TextSize = 16
	incomeLabel.Font = Enum.Font.SourceSansBold
	incomeLabel.Parent = gui

	return gui
end

-- Builds the brainrot's 3D model and its record. The model is anchored and
-- moved by the spawner or the steal loop, never by physics.
function Spawner.buildBrainrotModel(character, mutation)
	local brainrot = {
		id = GameState.newBrainrotId(),
		character = character,
		mutation = mutation,
		income = BrainrotData.incomeFor(character, mutation, 0),
		state = "conveyor",
		ownerUserId = nil,
		previousOwnerUserId = nil,
		carrier = nil,
		slotIndex = nil,
		model = nil,
	}

	local model = Instance.new("Model")
	model.Name = character.name .. "_" .. brainrot.id

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 3, 2)
	body.Color = character.body
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 2, 2)
	head.Color = character.body
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.Position = Vector3.new(0, 2.5, 0)
	head.Parent = model

	for _, side in ipairs({ -1, 1 }) do
		local leg = Instance.new("Part")
		leg.Name = "Leg" .. side
		leg.Size = Vector3.new(1, 1.5, 1)
		leg.Color = Color3.fromRGB(60, 60, 60)
		leg.Material = Enum.Material.SmoothPlastic
		leg.Anchored = true
		leg.Position = Vector3.new(side * 0.8, -2, 0)
		leg.Parent = model
	end

	local accessory = buildAccessory(character.accessory, body, character.body)
	accessory.Parent = model

	-- A mutated brainrot glows in its mutation colour.
	if mutation ~= "Normal" then
		local mutationData = BrainrotData.MUTATIONS[mutation]
		body.Material = Enum.Material.Neon
		body.Color = mutationData.color
	end

	buildLabel(brainrot, body)

	local click = Instance.new("ClickDetector")
	click.Name = "BrainrotClick"
	click.MaxActivationDistance = CLAIM_DISTANCE
	click.Parent = body

	model.PrimaryPart = body
	model.Parent = workspace.BrainrotWorld
	brainrot.model = model

	click.MouseClick:Connect(function(player)
		Spawner.onBrainrotClicked(player, brainrot)
	end)

	return brainrot
end

-- The first free slot on a player's base, and its world position.
local function findFreeSlot(player)
	local record = GameState.getPlayerData(player)
	local base = world.bases[record.baseIndex]
	if not base then
		return nil, nil
	end
	for i = 1, #base.slots do
		local taken = false
		for _, owned in pairs(record.brainrots) do
			if owned.slotIndex == i then
				taken = true
				break
			end
		end
		if not taken then
			return i, base.slots[i]
		end
	end
	return nil, nil
end

-- Puts a brainrot record on a player's base, at a free slot, and moves its model there.
function Spawner.placeOnBase(player, brainrot)
	local slotIndex, slotPos = findFreeSlot(player)
	if not slotIndex then
		return false
	end
	if not GameState.addBrainrot(player, brainrot) then
		return false
	end
	brainrot.slotIndex = slotIndex
	brainrot.state = "base"
	brainrot.carrier = nil
	local record = GameState.getPlayerData(player)
	brainrot.income = BrainrotData.incomeFor(brainrot.character, brainrot.mutation, record.rebirths)
	brainrot.model:PivotTo(CFrame.new(slotPos))
	return true
end

-- A click on a brainrot: claim it off the conveyor, or steal it off a base.
function Spawner.onBrainrotClicked(player, brainrot)
	if brainrot.state == "conveyor" then
		local price = BrainrotData.priceFor(brainrot.character)
		if GameState.freeSlots(player) <= 0 then
			return
		end
		if not GameState.spendMoney(player, price) then
			return
		end
		Spawner.placeOnBase(player, brainrot)
	elseif brainrot.state == "base" then
		Steal.trySteal(player, brainrot, world)
	end
end

-- Walks a brainrot along the conveyor from its current X to the end.
-- Stops early when it is claimed or stolen; despawns at the end.
local function walkBrainrot(brainrot)
	local model = brainrot.model
	local startX = model.PrimaryPart.Position.X
	local endX = world.conveyorEnd.X
	local steps = CONVEYOR_WALK_SECONDS * 10
	for step = 1, steps do
		if brainrot.state ~= "conveyor" then
			return
		end
		local t = step / steps
		local x = startX + (endX - startX) * t
		model:PivotTo(CFrame.new(x, world.conveyorStart.Y, world.conveyorStart.Z))
		task.wait(0.1)
	end
	if brainrot.state == "conveyor" then
		brainrot.model:Destroy()
	end
end

-- Spawns one brainrot at the west end of the conveyor and walks it east.
local function spawnOne()
	local character = BrainrotData.rollCharacter()
	local mutation = BrainrotData.rollMutation()
	local brainrot = Spawner.buildBrainrotModel(character, mutation)
	brainrot.model:PivotTo(CFrame.new(world.conveyorStart))
	task.spawn(walkBrainrot, brainrot)
end

function Spawner.start(givenWorld)
	world = givenWorld
	task.spawn(function()
		while true do
			spawnOne()
			task.wait(SPAWN_INTERVAL)
		end
	end)
end

return Spawner
