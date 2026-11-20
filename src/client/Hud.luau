-- Brainrot Rush: the HUD. A top bar (money, income, rebirths) kept clear of
-- Roblox's own top-left menu buttons, a wave warning, and a message line.
-- Main wires the server's RemoteEvents into these update functions.

local Hud = {}

local moneyLabel = nil
local incomeLabel = nil
local rebirthLabel = nil
local waveLabel = nil
local notifyLabel = nil
local notifyUntil = 0

function Hud.build(parent)
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.AnchorPoint = Vector2.new(0.5, 0)
	topBar.Position = UDim2.new(0.5, 0, 0, 12)
	topBar.Size = UDim2.fromOffset(460, 44)
	topBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	topBar.BackgroundTransparency = 0.2
	topBar.BorderSizePixel = 0
	topBar.Parent = parent

	moneyLabel = Instance.new("TextLabel")
	moneyLabel.Name = "MoneyLabel"
	moneyLabel.Size = UDim2.fromOffset(200, 44)
	moneyLabel.Position = UDim2.fromOffset(8, 0)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.Text = "$100"
	moneyLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	moneyLabel.TextSize = 26
	moneyLabel.Font = Enum.Font.FredokaOne
	moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
	moneyLabel.Parent = topBar

	incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Size = UDim2.fromOffset(140, 44)
	incomeLabel.Position = UDim2.fromOffset(210, 0)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = "+$0/s"
	incomeLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	incomeLabel.TextSize = 20
	incomeLabel.Font = Enum.Font.SourceSansBold
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
	incomeLabel.Parent = topBar

	rebirthLabel = Instance.new("TextLabel")
	rebirthLabel.Name = "RebirthLabel"
	rebirthLabel.Size = UDim2.fromOffset(100, 44)
	rebirthLabel.Position = UDim2.fromOffset(352, 0)
	rebirthLabel.BackgroundTransparency = 1
	rebirthLabel.Text = "Rebirths: 0"
	rebirthLabel.TextColor3 = Color3.fromRGB(255, 150, 220)
	rebirthLabel.TextSize = 18
	rebirthLabel.Font = Enum.Font.SourceSansBold
	rebirthLabel.TextXAlignment = Enum.TextXAlignment.Left
	rebirthLabel.Parent = topBar

	waveLabel = Instance.new("TextLabel")
	waveLabel.Name = "WaveWarning"
	waveLabel.AnchorPoint = Vector2.new(0.5, 0)
	waveLabel.Position = UDim2.new(0.5, 0, 0, 66)
	waveLabel.Size = UDim2.fromOffset(420, 44)
	waveLabel.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	waveLabel.BackgroundTransparency = 0.2
	waveLabel.Text = "WAVE INCOMING! RUN HOME!"
	waveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	waveLabel.TextSize = 26
	waveLabel.Font = Enum.Font.FredokaOne
	waveLabel.Visible = false
	waveLabel.Parent = parent

	notifyLabel = Instance.new("TextLabel")
	notifyLabel.Name = "NotifyLabel"
	notifyLabel.AnchorPoint = Vector2.new(0.5, 1)
	notifyLabel.Position = UDim2.new(0.5, 0, 1, -120)
	notifyLabel.Size = UDim2.fromOffset(520, 32)
	notifyLabel.BackgroundTransparency = 1
	notifyLabel.Text = ""
	notifyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	notifyLabel.TextStrokeTransparency = 0
	notifyLabel.TextSize = 20
	notifyLabel.Font = Enum.Font.SourceSansBold
	notifyLabel.Parent = parent
end

function Hud.updateMoney(money, incomePerSecond)
	if moneyLabel then
		moneyLabel.Text = "$" .. math.floor(money)
	end
	if incomeLabel then
		incomeLabel.Text = "+$" .. math.floor(incomePerSecond) .. "/s"
	end
end

function Hud.updateRebirths(rebirths)
	if rebirthLabel then
		rebirthLabel.Text = "Rebirths: " .. rebirths
	end
end

function Hud.showWaveWarning(seconds)
	if not waveLabel then
		return
	end
	waveLabel.Text = "WAVE INCOMING IN " .. seconds .. "s! RUN HOME!"
	waveLabel.Visible = true
end

function Hud.showWaveStarted()
	if not waveLabel then
		return
	end
	waveLabel.Text = "WAVE! GET TO YOUR BASE!"
	waveLabel.Visible = true
end

function Hud.hideWaveWarning()
	if waveLabel then
		waveLabel.Visible = false
	end
end

function Hud.notify(message)
	if not notifyLabel then
		return
	end
	notifyLabel.Text = message
	notifyUntil = os.clock() + 4
	task.delay(4, function()
		if os.clock() >= notifyUntil and notifyLabel then
			notifyLabel.Text = ""
		end
	end)
end

return Hud
