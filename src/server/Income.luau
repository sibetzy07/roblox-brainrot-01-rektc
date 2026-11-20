-- Brainrot Rush: the money tick. Every second, each brainrot standing on a
-- player's base pays its money per second into that player's money, and the
-- client HUD is told the new total.

local GameState = require(script.Parent.GameState)
local Remotes = require(script.Parent.Remotes)

local Income = {}

function Income.start()
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
				local earned = GameState.totalIncomePerSecond(player)
				if earned > 0 then
					local money = GameState.addMoney(player, earned)
					local leaderstats = player:FindFirstChild("leaderstats")
					local moneyValue = leaderstats and leaderstats:FindFirstChild("Money")
					if moneyValue then
						moneyValue.Value = math.floor(money)
					end
					local events = Remotes.get()
					if events then
						events.HudUpdate:FireClient(player, money, earned)
					end
				end
			end
		end
	end)
end

return Income
