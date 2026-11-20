-- Brainrot Rush: builds the whole 3D world when the server starts.
-- Layout (studs, ground at y = 0):
--   Conveyor along X at z = -30, brainrots walk west to east on it.
--   Spawn pad west (-70, 0), shop pad east (70, 0).
--   Four base plots along the south (z = 45), one per player, each with
--   six slots where collected brainrots stand and earn money.
--   Trees, pillars, clouds and a big entrance sign dress the map.
-- build() returns the world table every other module works with.

local WorldBuilder = {}

local BASE_CENTERS = {
	Vector3.new(-60, 0, 45),
	Vector3.new(-20, 0, 45),
	Vector3.new(20, 0, 45),
	Vector3.new(60, 0, 45),
}
local BASE_SIZE = Vector3.new(30, 1, 24)
local SLOTS_PER_BASE = 6
local CONVEYOR_START = Vector3.new(-70, 5.75, -30)
local CONVEYOR_END = Vector3.new(70, 5.75, -30)
local SPAWN_POSITION = Vector3.new(-70, 0, 0)
local SHOP_POSITION = Vector3.new(70, 0, 0)

local function makePart(name, size, position, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.Parent = parent
	return part
end

-- A flat text sign on a part: a SurfaceGui facing the players.
local function makeSign(part, text, textColor, textSize)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Adornee = part
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = gui
	return gui
end

-- One base plot: pad, low walls, six slot pads, a number sign, a lock gate
-- that turns visible while the owner's lock is on.
local function buildBase(index, center, folder)
	local base = {}
	base.index = index
	base.center = center
	base.slots = {}
	base.owner = nil

	local pad = makePart("BasePad" .. index, BASE_SIZE, center, Color3.fromRGB(120, 200, 120), Enum.Material.Grass, folder)
	base.pad = pad

	-- Low walls on the north and south edges so the plot reads as a base.
	makePart("BaseWall" .. index .. "North", Vector3.new(30, 3, 1), center + Vector3.new(0, 2, -12), Color3.fromRGB(90, 160, 90), Enum.Material.SmoothPlastic, folder)
	makePart("BaseWall" .. index .. "South", Vector3.new(30, 3, 1), center + Vector3.new(0, 2, 12), Color3.fromRGB(90, 160, 90), Enum.Material.SmoothPlastic, folder)

	-- Six slot pads in two rows of three, where brainrots stand and earn.
	for row = 0, 1 do
		for col = 0, 2 do
			local slotPos = center + Vector3.new(-9 + col * 9, 1, -5 + row * 10)
			local slot = makePart("Slot" .. index .. "_" .. (row * 3 + col + 1), Vector3.new(7, 1, 7), slotPos, Color3.fromRGB(220, 220, 220), Enum.Material.SmoothPlastic, folder)
			slot.CanCollide = false
			-- The stored slot is the model's pivot: pad top (y = 1.5) plus 2.75,
			-- so the brainrot's legs rest on the pad instead of sinking into it.
			table.insert(base.slots, slotPos + Vector3.new(0, 3.25, 0))
		end
	end

	-- Number sign on a post at the back of the plot.
	local post = makePart("BaseSign" .. index, Vector3.new(8, 5, 1), center + Vector3.new(0, 4, -13), Color3.fromRGB(60, 60, 90), Enum.Material.SmoothPlastic, folder)
	makeSign(post, "BASE " .. index, Color3.fromRGB(255, 255, 255), 32)
	base.sign = post

	-- Lock gate: a red transparent wall across the front, hidden until locked.
	local gate = makePart("LockGate" .. index, Vector3.new(30, 6, 1), center + Vector3.new(0, 4, 12), Color3.fromRGB(255, 60, 60), Enum.Material.Neon, folder)
	gate.Transparency = 1
	gate.CanCollide = false
	base.lockGate = gate

	return base
end

-- The conveyor: a long bed with rails and legs, plus start and end signs.
local function buildConveyor(folder)
	local bed = makePart("ConveyorBed", Vector3.new(140, 2, 10), Vector3.new(0, 2, -30), Color3.fromRGB(80, 80, 90), Enum.Material.SmoothPlastic, folder)
	bed.CanCollide = false
	makePart("ConveyorRailNorth", Vector3.new(140, 2, 1), Vector3.new(0, 4, -35), Color3.fromRGB(255, 180, 40), Enum.Material.SmoothPlastic, folder)
	makePart("ConveyorRailSouth", Vector3.new(140, 2, 1), Vector3.new(0, 4, -25), Color3.fromRGB(255, 180, 40), Enum.Material.SmoothPlastic, folder)
	for x = -60, 60, 20 do
		makePart("ConveyorLeg" .. x, Vector3.new(2, 2, 8), Vector3.new(x, 1, -30), Color3.fromRGB(60, 60, 70), Enum.Material.SmoothPlastic, folder)
	end
	local startSign = makePart("ConveyorStartSign", Vector3.new(1, 6, 8), Vector3.new(-72, 5, -30), Color3.fromRGB(60, 200, 90), Enum.Material.SmoothPlastic, folder)
	makeSign(startSign, "SPAWN", Color3.fromRGB(255, 255, 255), 32)
	local endSign = makePart("ConveyorEndSign", Vector3.new(1, 6, 8), Vector3.new(72, 5, -30), Color3.fromRGB(220, 60, 60), Enum.Material.SmoothPlastic, folder)
	makeSign(endSign, "END", Color3.fromRGB(255, 255, 255), 32)
	return bed
end

-- The shop: a platform with a counter and a big SHOP sign.
local function buildShop(folder)
	local pad = makePart("ShopPad", Vector3.new(24, 1, 24), SHOP_POSITION, Color3.fromRGB(255, 200, 80), Enum.Material.SmoothPlastic, folder)
	local counter = makePart("ShopCounter", Vector3.new(16, 4, 4), SHOP_POSITION + Vector3.new(0, 2.5, -8), Color3.fromRGB(150, 90, 40), Enum.Material.Wood, folder)
	local sign = makePart("ShopSign", Vector3.new(18, 6, 1), SHOP_POSITION + Vector3.new(0, 8, -10), Color3.fromRGB(255, 140, 0), Enum.Material.Neon, folder)
	makeSign(sign, "SHOP", Color3.fromRGB(255, 255, 255), 48)
	return pad
end

-- The spawn area: a pad on the west side. The SpawnLocation itself is a
-- static part in default.project.json, so players have a spawn from the start.
local function buildSpawn(folder)
	local pad = makePart("SpawnPad", Vector3.new(20, 1, 20), SPAWN_POSITION, Color3.fromRGB(140, 180, 255), Enum.Material.SmoothPlastic, folder)
	return pad
end

-- Trees, pillars, clouds and the big entrance arch.
local function buildDecorations(folder)
	local treeSpots = {
		Vector3.new(-85, 0, -55), Vector3.new(-85, 0, 20), Vector3.new(-85, 0, 70),
		Vector3.new(85, 0, -55), Vector3.new(85, 0, 20), Vector3.new(85, 0, 70),
		Vector3.new(-40, 0, -60), Vector3.new(40, 0, -60), Vector3.new(0, 0, 70),
	}
	for i, spot in ipairs(treeSpots) do
		local trunk = Instance.new("Part")
		trunk.Name = "TreeTrunk" .. i
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Size = Vector3.new(2, 8, 2)
		trunk.Position = spot + Vector3.new(0, 4, 0)
		trunk.Color = Color3.fromRGB(120, 70, 30)
		trunk.Material = Enum.Material.Wood
		trunk.Anchored = true
		trunk.Parent = folder
		local leaves = Instance.new("Part")
		leaves.Name = "TreeLeaves" .. i
		leaves.Shape = Enum.PartType.Ball
		leaves.Size = Vector3.new(8, 8, 8)
		leaves.Position = spot + Vector3.new(0, 11, 0)
		leaves.Color = Color3.fromRGB(60, 180, 70)
		leaves.Material = Enum.Material.SmoothPlastic
		leaves.Anchored = true
		leaves.Parent = folder
	end

	-- Entrance arch over the middle of the map, with the game's name.
	local pillarL = makePart("ArchPillarLeft", Vector3.new(3, 18, 3), Vector3.new(-14, 9, 10), Color3.fromRGB(255, 120, 160), Enum.Material.SmoothPlastic, folder)
	local pillarR = makePart("ArchPillarRight", Vector3.new(3, 18, 3), Vector3.new(14, 9, 10), Color3.fromRGB(255, 120, 160), Enum.Material.SmoothPlastic, folder)
	local beam = makePart("ArchBeam", Vector3.new(31, 4, 3), Vector3.new(0, 19, 10), Color3.fromRGB(255, 120, 160), Enum.Material.SmoothPlastic, folder)
	makeSign(beam, "BRAINROT RUSH", Color3.fromRGB(255, 255, 255), 48)

	-- Clouds drifting high above the map.
	for i = 1, 5 do
		local cloud = makePart("Cloud" .. i, Vector3.new(18, 4, 10), Vector3.new(-70 + i * 35, 45, -60 + i * 8), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, folder)
		cloud.CanCollide = false
	end
end

-- The wave: a huge translucent blue wall, parked off the map until a wave starts.
local function buildWave(folder)
	local wave = makePart("WaveWall", Vector3.new(220, 26, 4), Vector3.new(0, 13, -110), Color3.fromRGB(40, 120, 255), Enum.Material.Neon, folder)
	wave.Transparency = 1
	wave.CanCollide = false
	return wave
end

function WorldBuilder.build()
	local folder = Instance.new("Folder")
	folder.Name = "BrainrotWorld"
	folder.Parent = workspace

	local world = {}
	world.folder = folder
	world.conveyorStart = CONVEYOR_START
	world.conveyorEnd = CONVEYOR_END
	world.spawnPosition = SPAWN_POSITION
	world.shopPosition = SHOP_POSITION

	buildConveyor(folder)
	buildShop(folder)
	buildSpawn(folder)
	buildDecorations(folder)
	world.wavePart = buildWave(folder)

	world.bases = {}
	for i, center in ipairs(BASE_CENTERS) do
		world.bases[i] = buildBase(i, center, folder)
	end

	return world
end

return WorldBuilder
