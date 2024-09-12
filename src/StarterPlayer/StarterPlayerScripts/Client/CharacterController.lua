local RunService = game:GetService("RunService");
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players");
local Knit = require(game:GetService("ReplicatedStorage").libs.Knit);
local ClientSignals = require(ReplicatedStorage.util:WaitForChild("ClientSignals"));
local CharacterController = Knit.CreateController { Name = "CharacterController" }
local CameraController

--//Properties
CharacterController.ActiveCharacter = nil;
CharacterController.JumpshotRequest = false;
CharacterController.Key = "CharacterController"
CharacterController.MousePosition = Vector3.new();
CharacterController._Connections = {};

--//Methods
--/Private


--/Public
function CharacterController:RelignPlayerCharacter()
	local alignOrientation = self.ActiveCharacter.HumanoidRootPart.AlignOrientation;
	if not alignOrientation then
		warn("AlignOrientation nil");
		return
	end
	alignOrientation.Enabled = false
	alignOrientation.LookAtPosition = Vector3.new()
end

function CharacterController:AlignPlayerCharacter()
	local alignOrientation = self.ActiveCharacter.HumanoidRootPart.AlignOrientation;
	if not alignOrientation then
		warn("AlignOrientation nil");
		return
	end

	local originCF = self.ActiveCharacter.HumanoidRootPart.CFrame
	alignOrientation.Enabled = true
	alignOrientation.LookAtPosition = Vector3.new(self.MousePosition.X, originCF.Position + originCF.LookVector, self.MousePosition.Z)
end

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
		--self.JumpshotRequest = packet
		self.MousePosition = CameraController:GetMouse3D()
		
	end)
	self._Connections.JumpRelease = ClientSignals.JumpRelease:Connect(function(packet)
		self:RelignPlayerCharacter()
		self.MousePosition = Vector3.new()
	end)
	self._Connections.HoldShot = ClientSignals.HoldShot:Connect(function()
		print('yeah ok')
		self:AlignPlayerCharacter()
	end)
end

function CharacterController:CleanConnections()
	
end

function CharacterController:KnitInit()
	CameraController = Knit.GetController("CameraController")
end

function CharacterController:KnitStart() 
	self.ActiveCharacter = self:GetCharacter();
	self:InitializeCharacter()
	self:InitConnections()
end

return CharacterController