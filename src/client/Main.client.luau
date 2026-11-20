-- Brainrot Rush: client entry. Builds the HUD and the shop panel, wires the
-- bottom buttons (lock, rebirth, shop), and listens for the server's money,
-- wave and message events.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = require(script.Parent.Hud)
local ShopUI = require(script.Parent.ShopUI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local events = {
	HudUpdate = remotes:WaitForChild("HudUpdate"),
	WaveEvent = remotes:WaitForChild("WaveEvent"),
	Notify = remotes:WaitForChild("Notify"),
	LockBase = remotes:WaitForChild("LockBase"),
	Rebirth = remotes:WaitForChild("Rebirth"),
	BuyUpgrade = remotes:WaitForChild("BuyUpgrade"),
	GetShop = remotes:WaitForChild("GetShop"),
}

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

Hud.build(gui)
ShopUI.build(gui, events)

-- How to play, bottom-left, out of the way of the buttons.
local hint = Instance.new("TextLabel")
hint.Name = "HowToPlay"
hint.AnchorPoint = Vector2.new(0, 1)
hint.Position = UDim2.new(0, 12, 1, -12)
hint.Size = UDim2.fromOffset(420, 56)
hint.BackgroundTransparency = 1
hint.Text = "Click a brainrot on the conveyor to claim it.\nSteal from unlocked bases - and lock yours!"
hint.TextColor3 = Color3.fromRGB(255, 255, 255)
hint.TextStrokeTransparency = 0
hint.TextSize = 16
hint.Font = Enum.Font.SourceSansBold
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Parent = gui

-- Bottom buttons: lock, rebirth, shop.
local function makeButton(name, text, x, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, x, 1, -16)
	button.Size = UDim2.fromOffset(140, 44)
	button.BackgroundColor3 = color
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 20
	button.Font = Enum.Font.SourceSansBold
	button.Parent = gui
	return button
end

local lockButton = makeButton("LockButton", "LOCK BASE", -150, Color3.fromRGB(200, 60, 60))
lockButton.MouseButton1Click:Connect(function()
	events.LockBase:FireServer()
end)

local rebirthButton = makeButton("RebirthButton", "REBIRTH", 0, Color3.fromRGB(200, 60, 180))
rebirthButton.MouseButton1Click:Connect(function()
	events.Rebirth:FireServer()
end)

local shopButton = makeButton("ShopButton", "SHOP", 150, Color3.fromRGB(255, 140, 0))
shopButton.MouseButton1Click:Connect(function()
	if ShopUI.isOpen() then
		ShopUI.close()
	else
		ShopUI.open()
	end
end)

-- Server events.
events.HudUpdate.OnClientEvent:Connect(function(money, incomePerSecond)
	Hud.updateMoney(money, incomePerSecond)
end)

events.WaveEvent.OnClientEvent:Connect(function(kind, seconds)
	if kind == "warning" then
		Hud.showWaveWarning(seconds)
	elseif kind == "start" then
		Hud.showWaveStarted()
	elseif kind == "end" then
		Hud.hideWaveWarning()
	end
end)

events.Notify.OnClientEvent:Connect(function(message)
	Hud.notify(message)
end)

print("Brainrot Rush client ready.")
