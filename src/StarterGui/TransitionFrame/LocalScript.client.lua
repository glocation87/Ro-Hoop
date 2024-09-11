local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local frame = script.Parent.Frame

function quadraticLerp(a, b, t)
	return a + (b - a) * (3 * t^2 - 2 * t^3)
end

while frame.BackgroundTransparency < 0.95 do
	wait()
	frame.Size = UDim2.new(quadraticLerp(frame.Size.X.Scale, 0, 0.25), 0, quadraticLerp(frame.Size.Y.Scale, 0, 0.2), 0)
	frame.BackgroundTransparency = quadraticLerp(frame.BackgroundTransparency, 1, 0.2)
	frame.Rotation = quadraticLerp(frame.Rotation, 360, 0.2)
end

script.Parent:Destroy()