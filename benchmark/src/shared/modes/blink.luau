local RunService = game:GetService("RunService")

local Benches = require(game:GetService("ReplicatedStorage").Shared.benches)
local IsServer = RunService:IsServer()

local Events = {}
local BlinkAPI

if IsServer then
	BlinkAPI = require(script.Parent.blink_gen.server)
else
	BlinkAPI = require(script.Parent.blink_gen.client)
end

for Name in Benches do
	Events[Name] = {
		fire = function(data)
			if not IsServer then
				BlinkAPI[Name].Fire(data)
			end
		end,
		listen = function(callback)
			if IsServer then
				BlinkAPI[Name].On(callback)
			else
				BlinkAPI[Name].On(callback)
			end
		end,
	}
end

return Events
