local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.libs.Knit)

local Service = Knit.CreateService { Name = "BallhandlingService", Client = {}}

--//Private
local function enableBasketballAnim(character, condition)
	if (condition) then
		character.Animate.Enabled = false
		character.BasketballAnimate.Enabled = true
	else
		character.BasketballAnimate.Enabled = false
		character.Animate.Enabled = true
	end
end

--//Client
function Service.Client:DetachPlayerBall(player)
	local valid, character = self.Server:ValidatePlayerCharacter(player)
	if (valid == false) then
		return valid, warn("Player character not initialized")
	end
	
	local rootPart = character.HumanoidRootPart
	rootPart["Basketball"].Enabled = false
	
	local basketBall = character.Basketball
	basketBall.CanCollide = true
	basketBall.CanTouch = true
	basketBall.Trail.Enabled = true
	
	basketBall:SetNetworkOwner(player)
	local conn
	local initialHit = nil
	conn = basketBall.Touched:Connect(function(part)
		if (initialHit == nil) then 
			initialHit = tick()
		end
		if (tick() - initialHit) > 0.75 then
			basketBall.CanCollide = false
			basketBall.CanTouch = false
			basketBall.Trail.Enabled = false
			rootPart["Basketball"].Enabled = true
			conn:Disconnect()
		elseif (part == workspace.Hoop) then
			task.delay(0.25, function()
				basketBall.CanCollide = false
				basketBall.CanTouch = false
				basketBall.Trail.Enabled = false
				rootPart["Basketball"].Enabled = true
			end)
			part.Sparks:Emit(90)
			conn:Disconnect()
		end
	end)
	return true
end

--//Server
function Service:ValidatePlayerCharacter(player)
	local character = player.Character
	local humanoid = character.Humanoid;
	if not humanoid then
		warn("Humanoid nil");
		return false, nil
	end

	local humanoidRootPart = character.HumanoidRootPart;
	if not humanoidRootPart then
		warn("HumanoidRootPart nil");
		return false, nil
	end
	
	return true, character
end

function Service:KnitInit()
end

return Service