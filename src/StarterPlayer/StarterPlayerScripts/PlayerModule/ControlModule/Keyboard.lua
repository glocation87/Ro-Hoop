--!nonstrict
--[[
	Keyboard Character Control - This module handles controlling your avatar from a keyboard

	2018 PlayerScripts Update - AllYourBlox
--]]

--[[ Roblox Services ]]--
local Timer = require(game.ReplicatedStorage.libs.Timer);
local ClientSignals = require(game:GetService("ReplicatedStorage").util:WaitForChild("ClientSignals"));
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local CommonUtils = script.Parent.Parent:WaitForChild("CommonUtils")
local FlagUtil = require(CommonUtils:WaitForChild("FlagUtil"))
local FFlagUserUpdateInputConnections = FlagUtil.getUserFlag("UserUpdateInputConnections")

--[[ Constants ]]--
local ZERO_VECTOR3 = Vector3.new()

--[[ The Module ]]--
local BaseCharacterController = require(script.Parent:WaitForChild("BaseCharacterController"))
local Keyboard = setmetatable({}, BaseCharacterController)
Keyboard.__index = Keyboard

function Keyboard.new(CONTROL_ACTION_PRIORITY)
	local self = setmetatable(BaseCharacterController.new() :: any, Keyboard)

	self.CONTROL_ACTION_PRIORITY = CONTROL_ACTION_PRIORITY

	if not FFlagUserUpdateInputConnections then
		self.textFocusReleasedConn = nil
		self.textFocusGainedConn = nil
		self.windowFocusReleasedConn = nil
	end
	self.jumpRequestConn = nil
	self.jumpShootConn = nil
	
	self.forwardValue  = 0
	self.backwardValue = 0
	self.leftValue = 0
	self.rightValue = 0

	self.jumpEnabled = false
	self.jumpRequested = false
	self.jumpDebounce = false
	
	self.debounceTimer = Timer.new(6)
	self.releaseTimer = Timer.new(2)
	return self
end

function Keyboard:Enable(enable: boolean)
	if not FFlagUserUpdateInputConnections then
		if not UserInputService.KeyboardEnabled then
			return false
		end
	end

	if enable == self.enabled then
		-- Module is already in the state being requested. True is returned here since the module will be in the state
		-- expected by the code that follows the Enable() call. This makes more sense than returning false to indicate
		-- no action was necessary. False indicates failure to be in requested/expected state.
		return true
	end

	self.forwardValue  = 0
	self.backwardValue = 0
	self.leftValue = 0
	self.rightValue = 0
	self.moveVector = ZERO_VECTOR3 
	--self.jumpRequested = false
	self:UpdateJump()

	if enable then
		self:BindContextActions()
		self:ConnectFocusEventListeners()
		self.debounceTimer.Tick:Connect(function()
			self.jumpDebounce = false
			self.debounceTimer:Stop()
		end)
		self.releaseTimer.Tick:Connect(function()
			ClientSignals.JumpRelease:Fire()
			self.releaseTimer:Stop()
		end)
	else
		if FFlagUserUpdateInputConnections then
			self._connections:disconnectAll()
		else
			self:UnbindContextActions()
			self:DisconnectFocusEventListeners()
			self.debounceTimer:Destroy()
			self.releaseTimer:Destroy()
		end
	end

	self.enabled = enable
	return true
end

function Keyboard:UpdateMovement(inputState)
	if self.jumpRequested or inputState == Enum.UserInputState.Cancel then
		self.moveVector = ZERO_VECTOR3
	else
		self.moveVector = Vector3.new(self.leftValue + self.rightValue, 0, self.forwardValue + self.backwardValue)
	end
end

function Keyboard:UpdateJump()
	--self.isJumping = self.jumpRequested
end

function Keyboard:IsCharacter()
	local player = game.Players.LocalPlayer
	if (player.Character and player.Character:IsDescendantOf(workspace)) then
		return player.Character
	end
	return nil
end

function Keyboard:PlayerHasBall()
	local character = self:IsCharacter()
	if (not character) then 
		return false
	end
	
	local ball = character:FindFirstChild("Basketball")
	if (not ball) then
		return false, print("Basketball not descendant of character "..character.Name)
	end
	
	return true
end

function Keyboard:BindContextActions()

	-- Note: In the previous version of this code, the movement values were not zeroed-out on UserInputState. Cancel, now they are,
	-- which fixes them from getting stuck on.
	-- We return ContextActionResult.Pass here for legacy reasons.
	-- Many games rely on gameProcessedEvent being false on UserInputService.InputBegan for these control actions.
	local handleMoveForward = function(actionName, inputState, inputObject)
		self.forwardValue = (inputState == Enum.UserInputState.Begin) and -1 or 0
		self:UpdateMovement(inputState)
		return Enum.ContextActionResult.Pass
	end

	local handleMoveBackward = function(actionName, inputState, inputObject)
		self.backwardValue = (inputState == Enum.UserInputState.Begin) and 1 or 0
		self:UpdateMovement(inputState)
		return Enum.ContextActionResult.Pass
	end

	local handleMoveLeft = function(actionName, inputState, inputObject)
		self.leftValue = (inputState == Enum.UserInputState.Begin) and -1 or 0
		self:UpdateMovement(inputState)
		return Enum.ContextActionResult.Pass
	end

	local handleMoveRight = function(actionName, inputState, inputObject)
		self.rightValue = (inputState == Enum.UserInputState.Begin) and 1 or 0
		self:UpdateMovement(inputState)
		return Enum.ContextActionResult.Pass
	end

	local handleJumpAction = function(actionName, inputState, inputObject)
		--self.jumpRequested = self.jumpEnabled and (inputState == Enum.UserInputState.Begin)
		if (self:PlayerHasBall() == false) then 
			return
		end
		
		if inputState == Enum.UserInputState.Begin then
			if self.jumpDebounce or self.releaseTimer:IsRunning() then
				return Enum.ContextActionResult.Pass
			end 
			self.moveVector = ZERO_VECTOR3
			ClientSignals.JumpRequest:Fire(true)
		elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
			if self.jumpDebounce == false then
				return Enum.ContextActionResult.Pass
			end
			ClientSignals.JumpRequest:Fire(false)
		end
		return Enum.ContextActionResult.Pass
	end
	
	local handleTauntAction = function(actionName, inputState, inputObject)
		if inputState == Enum.UserInputState.Begin then
			ClientSignals.PlayTaunt:Fire()
		end
		
		return Enum.ContextActionResult.Pass
	end

	-- TODO: Revert to KeyCode bindings so that in the future the abstraction layer from actual keys to
	-- movement direction is done in Lua
	ContextActionService:BindActionAtPriority("moveForwardAction", handleMoveForward, false,
		self.CONTROL_ACTION_PRIORITY, Enum.PlayerActions.CharacterForward)
	ContextActionService:BindActionAtPriority("moveBackwardAction", handleMoveBackward, false,
		self.CONTROL_ACTION_PRIORITY, Enum.PlayerActions.CharacterBackward)
	ContextActionService:BindActionAtPriority("moveLeftAction", handleMoveLeft, false,
		self.CONTROL_ACTION_PRIORITY, Enum.PlayerActions.CharacterLeft)
	ContextActionService:BindActionAtPriority("moveRightAction", handleMoveRight, false,
		self.CONTROL_ACTION_PRIORITY, Enum.PlayerActions.CharacterRight)
	ContextActionService:BindActionAtPriority("jumpAction", handleJumpAction, false,
		self.CONTROL_ACTION_PRIORITY, Enum.PlayerActions.CharacterJump)
	--ContextActionService:BindAction("ballTauntAction", handleTauntAction, false, Enum.KeyCode.V)

	if FFlagUserUpdateInputConnections then
		self._connections:connectManual("moveForwardAction", function() ContextActionService:UnbindAction("moveForwardAction") end)
		self._connections:connectManual("moveBackwardAction", function() ContextActionService:UnbindAction("moveBackwardAction") end)
		self._connections:connectManual("moveLeftAction", function() ContextActionService:UnbindAction("moveLeftAction") end)
		self._connections:connectManual("moveRightAction", function() ContextActionService:UnbindAction("moveRightAction") end)
		self._connections:connectManual("jumpAction", function() ContextActionService:UnbindAction("jumpAction") end)
	end
end

function Keyboard:UnbindContextActions() -- remove with FFlagUserUpdateInputConnections
	ContextActionService:UnbindAction("moveForwardAction")
	ContextActionService:UnbindAction("moveBackwardAction")
	ContextActionService:UnbindAction("moveLeftAction")
	ContextActionService:UnbindAction("moveRightAction")
	ContextActionService:UnbindAction("jumpAction")
end

function Keyboard:ConnectFocusEventListeners()
	local function onFocusReleased()
		self.moveVector = ZERO_VECTOR3
		self.forwardValue  = 0
		self.backwardValue = 0
		self.leftValue = 0
		self.rightValue = 0
		--self.jumpRequested = false
		self:UpdateJump()
	end

	local function onTextFocusGained(textboxFocused)
		--self.jumpRequested = false
		self:UpdateJump()
	end

	if FFlagUserUpdateInputConnections then
		self._connections:connect("textBoxFocusReleased", UserInputService.TextBoxFocusReleased, onFocusReleased)
		self._connections:connect("textBoxFocused", UserInputService.TextBoxFocused, onTextFocusGained)
		self._connections:connect("windowFocusReleased", UserInputService.WindowFocused, onFocusReleased)
	else
		self.textFocusReleasedConn = UserInputService.TextBoxFocusReleased:Connect(onFocusReleased)
		self.textFocusGainedConn = UserInputService.TextBoxFocused:Connect(onTextFocusGained)
		self.windowFocusReleasedConn = UserInputService.WindowFocused:Connect(onFocusReleased)
	end

	self.jumpRequestConn = ClientSignals.JumpRequest:Connect(function(packet)
		if (packet == false) then
			self.debounceTimer:Start()
		else
			self.jumpDebounce = packet
			self.jumpRequested = true
			self.releaseTimer:Start()
		end
	end)
	
	self.jumpShootConn = ClientSignals.JumpShoot:Connect(function(packet)
		if (packet == "Release") then
			self.jumpRequested = false
		end
	end)
end

function Keyboard:DisconnectFocusEventListeners() -- remove with FFlagUserUpdateInputConnections
	if self.textFocusReleasedConn then
		self.textFocusReleasedConn:Disconnect()
		self.textFocusReleasedConn = nil
	end
	if self.textFocusGainedConn then
		self.textFocusGainedConn:Disconnect()
		self.textFocusGainedConn = nil
	end
	if self.windowFocusReleasedConn then
		self.windowFocusReleasedConn:Disconnect()
		self.windowFocusReleasedConn = nil
	end
	if self.jumpRequestConn then
		self.jumpRequestConn:Disconnect()
		self.jumpRequestConn = nil
	end

end

return Keyboard
