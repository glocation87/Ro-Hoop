local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.libs.Knit)

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character.Animate.Enabled = false
		character.BasketballAnimate.Enabled = true
		local humanoid = character:WaitForChild("Humanoid")
		local humanoidDescription = game.Players:GetHumanoidDescriptionFromUserId(player.UserId)
		humanoid:ApplyDescription(humanoidDescription)
	end)
end)

Knit.AddServices(script)
Knit.Start():catch(warn)