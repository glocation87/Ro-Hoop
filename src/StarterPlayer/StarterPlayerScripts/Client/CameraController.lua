local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players");
local Knit = require(game:GetService("ReplicatedStorage").libs.Knit);
local ClientSignals = require(ReplicatedStorage.util:WaitForChild("ClientSignals"));
local CameraController = Knit.CreateController { Name = "CameraController" }
local CharacterController

--// Properties
CameraController.Camera = nil
CameraController.ActiveCharacter = nil
CameraController.Key = "CameraController"
CameraController.MinFOV = 70  
CameraController.MaxFOV = 100  
CameraController.SpeedThreshold = 10 
CameraController.LerpSpeed = 5  
CameraController.JumpShotRequest = false;
CameraController.LastCustomCFrame = nil;
CameraController._Connections = {}
--// Methods
--/ Private
local function getMousePosition3D()
	local camera = workspace.CurrentCamera
	local mousePosition = UserInputService:GetMouseLocation()

	local unitRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)

	local maxDistance = 50
	local direction = unitRay.Direction * maxDistance 

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {workspace}
	raycastParams.FilterType = Enum.RaycastFilterType.Include

	local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * maxDistance, raycastParams)

	if raycastResult then
		local hitPosition = raycastResult.Position
		local clampedDistance = math.min((hitPosition - camera.CFrame.Position).Magnitude, maxDistance)
		return unitRay.Origin + unitRay.Direction * clampedDistance
	else
		return unitRay.Origin + direction
	
	end
end

local function quadraticLerp(a, b, t)
	return a + (b - a) * (3 * t^2 - 2 * t^3)
end

--/ Public
function CameraController:GetCamera()
	return self.Camera
end

function CameraController:GetMouse3D()
	return getMousePosition3D()
end

function CameraController:Bind()
	RunService:BindToRenderStep(self.Key, Enum.RenderPriority.Camera.Value + 1, function(dt)
		self:Run(dt)
	end)
end

function CameraController:Unbind()
	RunService:UnbindFromRenderStep(self.Key)
end

function CameraController:Run(dt)
	if not self.ActiveCharacter then return end

	local humanoidRootPart = self.ActiveCharacter.HumanoidRootPart
	local humanoid = self.ActiveCharacter.Humanoid

	if not humanoidRootPart or not humanoid then return end
	
	if (self.JumpShotRequest and self.Camera.CameraType == Enum.CameraType.Scriptable) then
		local mouse = game.Players.LocalPlayer:GetMouse()
		local screenWidth, screenHeight = workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y
		local mouseX = mouse.X - screenWidth / 2
		local mouseY = mouse.Y - screenHeight / 2

		local rotationFactor = 0.01 
		local rotateX = math.rad(-mouseY * rotationFactor)
		local rotateY = math.rad(-mouseX * rotationFactor)

		local pos = (self.Camera.CameraSubject.CFrame * CFrame.new(5, 1, 3)).Position
		local direction = humanoidRootPart.CFrame.LookVector
		
		local cameraLookAt = CFrame.new(pos, pos + direction) 
		cameraLookAt = cameraLookAt * CFrame.Angles(rotateX, rotateY, 0)
		
		self.Camera.CFrame = self.Camera.CFrame:Lerp(cameraLookAt, 0.1)
		self.Camera.FieldOfView = quadraticLerp(self.Camera.FieldOfView, 40, 0.12)
	end
end

function CameraController:InitConnections() 
	self._Connections.JumpRequest = ClientSignals.JumpRequest:Connect(function(condition)
		if (condition) then
			self.JumpShotRequest = true;
		end
	end)
	self._Connections.HoldShot = ClientSignals.HoldShot:Connect(function()
		self.LastCustomCFrame = self.Camera.CFrame;
		self.Camera.CameraType = Enum.CameraType.Scriptable
	end)
	self._Connections.JumpRelease = ClientSignals.JumpRelease:Connect(function()
		self.Camera.CameraType = Enum.CameraType.Custom
		self.JumpShotRequest = false;
	end)
	self:Bind();
end

function CameraController:CleanConnections() 

end

function CameraController:KnitInit()
	CharacterController = Knit.GetController("CharacterController")
	self.Camera = workspace.CurrentCamera
end

function CameraController:KnitStart()
	
	self.ActiveCharacter = CharacterController:GetCharacter()
	self.Camera.CameraSubject = self.ActiveCharacter:FindFirstChild("Torso")

	self:InitConnections()
end

return CameraController
