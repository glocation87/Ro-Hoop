local RunService = game:GetService("RunService");
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players");
local Knit = require(game:GetService("ReplicatedStorage").libs.Knit);
local ClientSignals = require(ReplicatedStorage.util:WaitForChild("ClientSignals"));
local CharacterController = Knit.CreateController { Name = "CharacterController" }

--//Properties
CharacterController.ActiveCharacter = nil;
CharacterController.JumpshotRequest = false;
CharacterController.Key = "CharacterController"
CharacterController._Connections = {};

--//Methods
--/Private

--/Public
function CharacterController:GetCharacter() 
	if (game.Players.LocalPlayer.Character ~= nil) then
		return game.Players.LocalPlayer.Character;
	else
		return game.Players.LocalPlayer.CharacterAdded:Wait();
	end
	return nil, warn("Player character not found, returned nil", 1);
end

function CharacterController:InitializeCharacter()
	if (not self.ActiveCharacter) then
		return
	end
	local humanoid = self.ActiveCharacter:FindFirstChild("Humanoid")
	if (not humanoid) then
		humanoid = self.ActiveCharacter:WaitForChild("Humanoid", 10)
	end

	if (not humanoid) then
		return print("No humanoid object found")
	end
end

function CharacterController:Bind()
	RunService:BindToRenderStep(self.Key, Enum.RenderPriority.Character.Value, function(dt) 
		self:Run(dt)
	end);
end

function CharacterController:Unbind()
	RunService:UnbindFromRenderStep(self.Key);
end

function CharacterController:Run(dt)
	local humanoid = self.ActiveCharacter.Humanoid;
	if not humanoid then
		warn("Humanoid nil");
		return
	end

	local humanoidRootPart = self.ActiveCharacter.HumanoidRootPart;
	if not humanoidRootPart then
		warn("HumanoidRootPart nil");
		return
	end
	
	
end

function CharacterController:InitConnections()
	self._Connections.JumpRequest = ClientSignals.JumpRequest:Connect(function(packet)
		self.JumpshotRequest = packet
	end)
end

function CharacterController:CleanConnections()
	
end


function CharacterController:KnitStart() 
	self.ActiveCharacter = self:GetCharacter();
	self:InitializeCharacter()
	
end

return CharacterController