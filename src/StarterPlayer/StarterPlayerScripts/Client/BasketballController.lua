--//Locals
local RunService = game:GetService("RunService");
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players");
local Knit = require(game:GetService("ReplicatedStorage").libs.Knit);
local ClientSignals = require(ReplicatedStorage.util:WaitForChild("ClientSignals"));
local BasketballController = Knit.CreateController { Name = "BasketballController" }
local CharacterController
local CameraController
local BasketballService
--//Test
local HoopObject = workspace:WaitForChild("Hoop")
--//Constants
local MAX_BALL_SPEED = 40
local INITIAL_BALL_SPEED = 1 -- 30 being the max
local VISUALIZER_STEP = 0.025
--//Properties
BasketballController.ActiveCharacter = nil;
BasketballController.ActiveBall = nil;
BasketballController.JumpshotRequest = false;
BasketballController.BallInMotion = false;
BasketballController.VisualizeShot = false;
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
    local distance = vector.Magnitude
    local direction = vector.Unit

    -- Dynamically adjust the height based on the distance
    local heightFactor = math.max(distance * 0.5, 1) -- Ensure height is significant even if distance is small
    return start + (direction * distance * 0.5) + Vector3.new(0, heightFactor, 0)
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

local function spawnNeonBall(position)
    local ball = Instance.new("Part")
    ball.Size = Vector3.new(0.25, 0.25, 0.25)
    ball.Position = position
    ball.Shape = Enum.PartType.Ball
    ball.Material = Enum.Material.Neon
	ball.Transparency = 0.2
    ball.BrickColor = BrickColor.new("White")
    ball.Anchored = true
    ball.CanCollide = false
	ball.CanTouch = false
    ball.Parent = workspace.Debris
    Debris:AddItem(ball, 0.007)
end

--/Public
function BasketballController:Rebound()
	self._Connections.BallTouched:Disconnect()
	self.BallInMotion = false
	self.Alpha = 0
	self.BallSpeed = INITIAL_BALL_SPEED
	local lastVelocityMagnitude = self.ActiveBall.AssemblyLinearVelocity.Magnitude
	self.ActiveBall.AssemblyLinearVelocity = self.ActiveBall.AssemblyLinearVelocity.Unit * math.clamp(lastVelocityMagnitude, 0, (self.InitialPos - self.EndPos).Magnitude)
end


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

function BasketballController:ShootBall()
	local basketball = self:GetBall()
	local humanoidRootPart = self.ActiveCharacter.HumanoidRootPart
	if (basketball and humanoidRootPart) then
		self.ActiveBall = basketball
		BasketballService:DetachPlayerBall():andThen(function()
			self.InitialPos = basketball.Position
			self.ControlPos = calculateControlPos(self.InitialPos, self.EndPos)
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
				self:Rebound()
			end)
		end)
	end
end

function BasketballController:DrawCurve()
	local basketball = self:GetBall()
	self.InitialPos = basketball.Position
	self.EndPos = CameraController:GetMouse3D()
	self.ControlPos = calculateControlPos(self.InitialPos, self.EndPos)
	while (self.VisualizeShot) do
		RunService.Heartbeat:Wait()
		
		task.spawn(function()
			for t = 0.01, 1, VISUALIZER_STEP do
				if (self.VisualizeShot == false) then
					break
				end
				RunService.Heartbeat:Wait()
				spawnNeonBall(quadraticBezier(t, self.InitialPos, self.ControlPos, self.EndPos))
			end
		end)
		self.InitialPos = basketball.Position
		self.EndPos = CameraController:GetMouse3D()
		self.ControlPos = calculateControlPos(self.InitialPos, self.EndPos)
	end
end

function BasketballController:BindTouchedEvent(object)
	self._Connections.BallTouched = object.Touched:Connect(function(part)
		self:Rebound()
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
		local totalArcLength = calculateArcLength(100, self.InitialPos, self.ControlPos, self.EndPos)
		local adjustedT = reparametrizeByArcLength(self.Alpha, totalArcLength, self.InitialPos, self.ControlPos, self.EndPos)
		local position = quadraticBezier(adjustedT, self.InitialPos, self.ControlPos, self.EndPos)
		self.ActiveBall.Position = position
	end
end

function BasketballController:InitConnections()
	self._Connections.JumpRequest = ClientSignals.JumpRequest:Connect(function(packet)
		self.JumpshotRequest = packet
	end)
	self._Connections.HoldShot = ClientSignals.HoldShot:Connect(function()
		self.VisualizeShot = true
		self:DrawCurve()
	end)
	self._Connections.JumpRelease = ClientSignals.JumpRelease:Connect(function(packet)
		self.VisualizeShot = false
	end)
	self._Connections.JumpShoot = ClientSignals.JumpShoot:Connect(function(packet)
		if (packet == "Shot") then
			self:ShootBall()
		end
	end)

	self:Bind()
end

function BasketballController:CleanConnections()

end

function BasketballController:KnitInit()
	CameraController = Knit.GetController("CameraController")
	CharacterController = Knit.GetController("CharacterController")
	BasketballService = Knit.GetService("BallhandlingService")
end


function BasketballController:KnitStart() 
	self.ActiveCharacter = CharacterController:GetCharacter()
	self:InitConnections()
end

return BasketballController