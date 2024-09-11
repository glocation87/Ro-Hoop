local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players");
local Knit = require(game:GetService("ReplicatedStorage").libs.Knit);
local ClientSignals = require(ReplicatedStorage.util:WaitForChild("ClientSignals"));
local BasketballController = Knit.CreateController { Name = "BasketballController" }
local CharacterController
local BasketballService
--//Test
local HoopObject = workspace:WaitForChild("Hoop")
--//Constants
local MAX_BALL_SPEED = 40
local INITIAL_BALL_SPEED = 1 -- 30 being the max
--//Properties
BasketballController.ActiveCharacter = nil;
BasketballController.ActiveBall = nil;
BasketballController.JumpshotRequest = false;
BasketballController.BallInMotion = false;
BasketballController.BallSpeed = INITIAL_BALL_SPEED;
BasketballController.Alpha = 0;
BasketballController.Key = "BasketballController"
BasketballController.InitialPos = Vector3.new()
BasketballController.ControlPos = Vector3.new()
BasketballController.EndPos = Vector3.new()
BasketballController.LastPosition = Vector3.new()
BasketballController.LastVelocity = Vector3.new()
BasketballController.InitialTick = nil
BasketballController._Connections = {};

--//Methods
--/Private
local function debugPoints(p1, p2, p3)
	
end
local function calculateControlPos(start, _end)
	local vector = _end - start
	local direction, magnitude = vector.Unit, vector.Magnitude * 0.5
	return start + (direction * magnitude) + Vector3.new(0, magnitude*0.5, 0)
end

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

function quadraticLerp(a, b, t)
	return a + (b - a) * (3 * t^2 - 2 * t^3)
end

local function quadraticBezier(t, a, b, c)
	return (1 - t)^2 * a + 2 * (1 - t) * t * b + t^2 * c
end

local function quadraticBezierDerivative(t, a, b, c)
	return 2 * (1 - t) * (b - a) + 2 * t * (c - b)
end

local function reparametrizeByArcLength(t, totalLength, P0, P1, P2)
	local targetDistance = t * totalLength
	local currentDistance = 0
	local lastPoint = P0
	local steps = 100 --Adjust the number of steps for accuracy

	for i = 1, steps do
		local stepT = i / steps
		local currentPoint = quadraticBezier(stepT, P0, P1, P2)
		local segmentLength = (currentPoint - lastPoint).Magnitude
		currentDistance = currentDistance + segmentLength

		if currentDistance >= targetDistance then
			return stepT 
		end

		lastPoint = currentPoint
	end

	return 1
end

local function calculateArcLength(steps, P0, P1, P2)
	local length = 0
	local lastPoint = P0

	for i = 1, steps do
		local t = i / steps
		local currentPoint = quadraticBezier(t, P0, P1, P2)
		length = length + (currentPoint - lastPoint).Magnitude
		lastPoint = currentPoint
	end

	return length
end

--/Public
function BasketballController:GetBall()
	if (not self.ActiveCharacter) then 
		return nil
	end

	local ball = self.ActiveCharacter:FindFirstChild("Basketball")
	if (not ball) then
		return nil
	end

	return ball
end

function BasketballController:BindTouchedEvent(object)
	self._Connections.BallTouched = object.Touched:Connect(function(part)
		self._Connections.BallTouched:Disconnect()
		self.BallInMotion = false
		self.Alpha = 0
		self.BallSpeed = INITIAL_BALL_SPEED
		local lastVelocityMagnitude = self.ActiveBall.AssemblyLinearVelocity.Magnitude
		self.ActiveBall.AssemblyLinearVelocity = self.ActiveBall.AssemblyLinearVelocity.Unit * math.clamp(lastVelocityMagnitude, 0, (self.InitialPos - self.EndPos).Magnitude)
	end)
end

function BasketballController:Bind()
	RunService:BindToRenderStep(self.Key.."Shot", Enum.RenderPriority.Character.Value, function(dt) 
		self:OnShot(dt)
	end);
end

function BasketballController:Unbind()
	RunService:UnbindFromRenderStep(self.Key.."Shot");
end

function BasketballController:OnShot(dt)
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

	if self.BallInMotion then
		--self.Alpha = self.Alpha + dt * self.BallSpeed 
		--self.Alpha = math.clamp(self.Alpha, 0, 1)
		
		local totalArcLength = calculateArcLength(100, self.InitialPos, self.ControlPos, self.EndPos)
		local adjustedT = reparametrizeByArcLength(self.Alpha, totalArcLength, self.InitialPos, self.ControlPos, self.EndPos)
		local position = quadraticBezier(adjustedT, self.InitialPos, self.ControlPos, self.EndPos)
		--local velocity = quadraticBezierDerivative(self.Alpha, self.InitialPos, self.ControlPos, self.EndPos)
		self.ActiveBall.Position = position
	end
end

function BasketballController:InitConnections()
	self._Connections.JumpRequest = ClientSignals.JumpRequest:Connect(function(packet)
		self.JumpshotRequest = packet
	end)
	
	self._Connections.JumpShoot = ClientSignals.JumpShoot:Connect(function(packet)
		if (packet == "Shot") then
			local basketball = self:GetBall()
			local humanoidRootPart = self.ActiveCharacter.HumanoidRootPart
			if (basketball and humanoidRootPart) then
				self.ActiveBall = basketball
				self.InitialPos = basketball.Position
				self.EndPos = HoopObject.Position
				self.ControlPos = calculateControlPos(self.InitialPos, self.EndPos)
				BasketballService:DetachPlayerBall():andThen(function()
					self.BallInMotion = true
					self:BindTouchedEvent(self.ActiveBall)
					task.spawn(function()
						for i = 0, 1, self.BallSpeed/MAX_BALL_SPEED do
							if (self.BallInMotion == false) then
								self.Alpha = 0
								break
							end
							task.wait()
							self.Alpha = i
						end	
					end)
				end)
				
			end
		end
	end)

	self:Bind()
end

function BasketballController:CleanConnections()

end

function BasketballController:KnitInit()
	CharacterController = Knit.GetController("CharacterController")
	BasketballService = Knit.GetService("BallhandlingService")
end


function BasketballController:KnitStart() 
	self.ActiveCharacter = CharacterController:GetCharacter()
	self:InitConnections()
end

return BasketballController