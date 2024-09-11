--//Libraries
local Knit = require(game:GetService("ReplicatedStorage").libs.Knit);

--//Instructions
Knit.AddControllers(script);

Knit.Start():catch(warn):await();
