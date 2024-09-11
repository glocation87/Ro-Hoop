local Knit = require(game:GetService("ReplicatedStorage").libs.Knit);
local Signal = require(Knit.Util.Signal)
local ClientSignals = {
	JumpRequest = Signal.new();
	JumpRelease = Signal.new();
	JumpShoot = Signal.new();
	PlayTaunt = Signal.new();
	TransitionUI = Signal.new();
}
return ClientSignals
