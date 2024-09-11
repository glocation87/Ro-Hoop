local RunService = game:GetService("RunService");
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players");
local Player = Players.LocalPlayer
local Knit = require(game:GetService("ReplicatedStorage").libs.Knit);
local ClientSignals = require(ReplicatedStorage.util:WaitForChild("ClientSignals"));
local Keyboard = require(game:GetService("ReplicatedStorage").libs.Input).Keyboard
local MovementController = Knit.CreateController { Name = "MovementController" }
local CameraController;
local CharacterController;

--//Properties
MovementController.Camera = nil;
MovementController.ActiveCharacter = nil;
MovementController.Key = "MovementController"
MovementController.OriginalRootC0 = nil;
MovementController.TiltAmplitude = 10;
MovementController.JumpShotRequest = false;
MovementController._Connections = {}

--//Methods
--/Private
local function angleBetweenVectors(a, b)
	return math.acos( ( a:Dot(b) ) / (a.Magnitude * b.Magnitude) );
end

local function quadraticLerp(a, b, t)
	return a + (b - a) * (3 * t^2 - 2 * t^3)
end

--/Public
function MovementController:Bind()
	RunService:BindToRenderStep(self.Key, Enum.RenderPriority.Character.Value, function(dt) 
		self:Run(dt);
	end);
end

function MovementController:Unbind()
	RunService:UnbindFromRenderStep(self.Key);
end

function MovementController:Run(dt)
	local humanoid = self.ActiveCharacter.Humanoid;
	if not humanoid then
		warn("Humanoid is nil");
		return;
	end

	local humanoidRootPart = self.ActiveCharacter.HumanoidRootPart;
	if not humanoidRootPart then
		warn("HumanoidRootPart is nil");
		return;
	end

	local rootJoint = humanoidRootPart.RootJoint;
	if not rootJoint then
		warn("RootJoint is nil");
		return;
	end

	local angularVelocity = humanoidRootPart.AngularVelocity;
	if not angularVelocity then
		warn("AngularVelocity is nil");
		return;
	end
	
	local moveDirection = humanoid.MoveDirection;
	local lookDirection = humanoidRootPart.CFrame.LookVector;
	
	
	if moveDirection.Magnitude > 0.1 then
		local angle = angleBetweenVectors(moveDirection.Unit, lookDirection);

		local crossProduct = lookDirection:Cross(moveDirection);
		local tiltDirection = crossProduct.Y >= 0 and 1 or -1;

		local tiltY = math.clamp(tiltDirection * angle * self.TiltAmplitude, -6, 6);
		
		--rootJoint.C0 = rootJoint.C0:Lerp(self.OriginalRootC0 * CFrame.Angles(0, math.rad(tiltY), 0), dt*5);
	else

		--rootJoint.C0 = rootJoint.C0:Lerp(self.OriginalRootC0, dt*5);
	end
	
	if (self.JumpShotRequest) then
		--return
	end
	
	if Keyboard:IsKeyDown(Enum.KeyCode.LeftShift) and (humanoid:GetMoveVelocity().Magnitude > 1) then
		humanoid.WalkSpeed = quadraticLerp(humanoid.WalkSpeed, 20, 0.25);
		angularVelocity.MaxTorque = quadraticLerp(angularVelocity.MaxTorque, 2500, 0.5);
		Player.CameraMaxZoomDistance = quadraticLerp(Player.CameraMaxZoomDistance, 12, 0.12)
		Player.CameraMinZoomDistance = quadraticLerp(Player.CameraMinZoomDistance, 12, 0.12)
		self.Camera.FieldOfView = quadraticLerp(self.Camera.FieldOfView, 80, 0.12)
	else
		humanoid.WalkSpeed = quadraticLerp(humanoid.WalkSpeed, 10, 0.25);
		angularVelocity.MaxTorque = quadraticLerp(angularVelocity.MaxTorque, 5000, 0.5);
		Player.CameraMaxZoomDistance = quadraticLerp(Player.CameraMaxZoomDistance, 9, 0.12)
		Player.CameraMinZoomDistance = quadraticLerp(Player.CameraMinZoomDistance, 9, 0.12)
		self.Camera.FieldOfView = quadraticLerp(self.Camera.FieldOfView, 70, 0.12)
	end
end

function MovementController:InitConnections()
	self._Connections.JumpRequest = ClientSignals.JumpRequest:Connect(function(condition)
		if (condition) then
			self.JumpShotRequest = true;
		end
	end)
	self:Bind();
end

function MovementController:CleanConnections()
	
end

function MovementController:KnitInit() 
	CameraController = Knit.GetController("CameraController");
	CharacterController = Knit.GetController("CharacterController");
end

function MovementController:KnitStart() 
	self.Camera = CameraController:GetCamera();
	self.ActiveCharacter = CharacterController:GetCharacter();
	if (self.ActiveCharacter:FindFirstChild("HumanoidRootPart")) then
		self.OriginalRootC0 = self.ActiveCharacter.HumanoidRootPart.RootJoint.C0;
	end
	
	self:InitConnections();
end

return MovementController
