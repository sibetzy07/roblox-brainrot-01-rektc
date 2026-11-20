-- Brainrot Rush: the shop panel. Lists the four upgrades with their current
-- prices (asked from the server), a Buy button each, and a Rebirth button
-- with its cost. Hidden until the player opens it.

local ShopUI = {}

local panel = nil
local listFrame = nil
local rebirthButton = nil
local events = nil

local function makeButton(name, text, size, position, color, parent)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 20
	button.Font = Enum.Font.SourceSansBold
	button.Parent = parent
	return button
end

function ShopUI.build(parent, remotes)
	events = remotes

	panel = Instance.new("Frame")
	panel.Name = "ShopPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(460, 380)
	panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = parent

	local title = Instance.new("TextLabel")
	title.Name = "ShopTitle"
	title.Size = UDim2.fromOffset(460, 44)
	title.Position = UDim2.fromOffset(0, 0)
	title.BackgroundTransparency = 1
	title.Text = "SHOP  |  UPGRADES"
	title.TextColor3 = Color3.fromRGB(255, 200, 80)
	title.TextSize = 26
	title.Font = Enum.Font.FredokaOne
	title.Parent = panel

	listFrame = Instance.new("Frame")
	listFrame.Name = "ShopList"
	listFrame.Size = UDim2.fromOffset(440, 220)
	listFrame.Position = UDim2.fromOffset(10, 50)
	listFrame.BackgroundTransparency = 1
	listFrame.Parent = panel

	rebirthButton = makeButton(
		"RebirthButton",
		"REBIRTH: $10,000 + 5 brainrots",
		UDim2.fromOffset(440, 44),
		UDim2.fromOffset(10, 280),
		Color3.fromRGB(200, 60, 180),
		panel
	)
	rebirthButton.TextSize = 17
	rebirthButton.MouseButton1Click:Connect(function()
		events.Rebirth:FireServer()
	end)

	local closeButton = makeButton("CloseButton", "CLOSE", UDim2.fromOffset(120, 36), UDim2.fromOffset(170, 332), Color3.fromRGB(90, 90, 110), panel)
	closeButton.MouseButton1Click:Connect(function()
		panel.Visible = false
	end)
end

-- Refreshes the shop list from the server and shows the panel.
function ShopUI.open()
	if not panel then
		return
	end
	local shop = events.GetShop:InvokeServer()
	for _, child in ipairs(listFrame:GetChildren()) do
		child:Destroy()
	end
	local y = 0
	for _, item in ipairs(shop) do
		local row = Instance.new("Frame")
		row.Name = "ShopRow_" .. item.key
		row.Size = UDim2.fromOffset(440, 48)
		row.Position = UDim2.fromOffset(0, y)
		row.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
		row.BorderSizePixel = 0
		row.Parent = listFrame

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.fromOffset(200, 24)
		nameLabel.Position = UDim2.fromOffset(10, 2)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = item.name .. "  (owned " .. item.owned .. ")"
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 18
		nameLabel.Font = Enum.Font.SourceSansBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.fromOffset(280, 20)
		descLabel.Position = UDim2.fromOffset(10, 26)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = item.desc
		descLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
		descLabel.TextSize = 15
		descLabel.Font = Enum.Font.SourceSans
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = row

		local buyButton = makeButton(
			"Buy_" .. item.key,
			"BUY $" .. item.price,
			UDim2.fromOffset(130, 36),
			UDim2.fromOffset(300, 6),
			Color3.fromRGB(60, 180, 80),
			row
		)
		buyButton.MouseButton1Click:Connect(function()
			events.BuyUpgrade:FireServer(item.key)
			task.wait(0.3)
			ShopUI.open()
		end)

		y += 52
	end
	panel.Visible = true
end

function ShopUI.isOpen()
	return panel and panel.Visible
end

function ShopUI.close()
	if panel then
		panel.Visible = false
	end
end

return ShopUI
