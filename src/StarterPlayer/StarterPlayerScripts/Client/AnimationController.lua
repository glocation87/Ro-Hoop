local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService");
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players");
local Knit = require(game:GetService("ReplicatedStorage").libs.Knit);
local ClientSignals = require(ReplicatedStorage.util:WaitForChild("ClientSignals"));
local AnimationController = Knit.CreateController { Name = "AnimationController" }
local CharacterController
local Animations = game.ReplicatedStorage:WaitForChild("animations")

--// Properties
AnimationController.Camera = nil
AnimationController.ActiveCharacter = nil
AnimationController.Key = "AnimationController"
AnimationController.CurrentAnimTrack = nil
AnimationController.ActiveBallHolding = false
AnimationController._LoadedAnimations = {}
AnimationController._Connections = {}
--// Methods
--/ Private

--/ Public
-- These are interfaced for external use
function AnimationController:PlayWithEvents(name, transition, arr) 
	local animTrack = self._LoadedAnimations[name]
	if not animTrack then
		return warn("Animation not found")
	end
	
	if self.CurrentAnimTrack then
		self.CurrentAnimTrack:Stop()
		self.CurrentAnimTrack = nil
	end
	self.CurrentAnimTrack = animTrack
	self.CurrentAnimTrack:Play(transition)
	self.CurrentAnimTrack.Ended:Connect(function()
		self.CurrentAnimTrack = nil
	end)
	for eventName, callback in pairs(arr) do
		self.CurrentAnimTrack:GetMarkerReachedSignal(eventName):Connect(function(paramString) 
			callback(paramString, self.CurrentAnimTrack)
		end)
	end
end

function AnimationController:Play(name, transition)
	local animTrack = self._LoadedAnimations[name]
	if not animTrack then
		return warn("Animation not found")
	end

	if self.CurrentAnimTrack then
		self.CurrentAnimTrack:Stop()
		self.CurrentAnimTrack = nil
	end
	self.CurrentAnimTrack = animTrack
	self.CurrentAnimTrack:Play(transition)
	self.CurrentAnimTrack.Ended:Connect(function()
		self.CurrentAnimTrack = nil
	end)
end

function AnimationController:InitAnimations()
	local humanoid = self.ActiveCharacter.Humanoid
	if not humanoid then
		return warn("Humanoid not found, cannot initialize animations")
	end
	
	for _, anim in pairs(Animations:GetChildren()) do
		self._LoadedAnimations[anim.Name] = humanoid:LoadAnimation(anim)
	end
end

function AnimationController:Bind()
	RunService:BindToRenderStep(self.Key, Enum.RenderPriority.Character.Value, function(dt)
		self:Run(dt)
	end)
end

function AnimationController:Unbind()
	RunService:UnbindFromRenderStep(self.Key)
end

function AnimationController:Run(dt)
	if not self.ActiveCharacter then return end

	local humanoidRootPart = self.ActiveCharacter.HumanoidRootPart
	local humanoid = self.ActiveCharacter.Humanoid

	if not humanoidRootPart or not humanoid then return end
	if self.ActiveBallHolding then
		
	end
end

function AnimationController:InitConnections() 
	self._Connections.JumpRequest = ClientSignals.JumpRequest:Connect(function(condition)
		if (condition) then
			local events = {
				["HoldBall"] = function(paramString, animTrack)
					animTrack:AdjustSpeed(0)
					self.ActiveBallHolding = true
				end,
				
				["ReleaseBall"] = function(paramString, animTrack)
					ClientSignals.JumpShoot:Fire("Shot")
					self.ActiveBallHolding = false
				end,
				
				["UnlockMovement"] = function(paramString, animTrack)
					ClientSignals.JumpShoot:Fire("Release")
				end,
			}
			self:PlayWithEvents("Jumpshot", 0.1, events)
		end
	end)
	
	self._Connections.JumpRelease = ClientSignals.JumpRelease:Connect(function()
		if not self.CurrentAnimTrack then
			return
		end
		if (self.CurrentAnimTrack.Name == "Jumpshot") then
			self.CurrentAnimTrack:AdjustSpeed(1)
		end
	end)
	
	self._Connections.Taunts = ClientSignals.PlayTaunt:Connect(function()
		self:Play("BallTaunt", 0.2)
	end)
	
	self:Bind();
end

function AnimationController:CleanConnections() 

end

function AnimationController:KnitInit()
	CharacterController = Knit.GetController("CharacterController")
end

function AnimationController:KnitStart()
	self.Camera = workspace.CurrentCamera
	self.ActiveCharacter = CharacterController:GetCharacter()
	
	self:InitAnimations()
	self:InitConnections()
end

return AnimationController
