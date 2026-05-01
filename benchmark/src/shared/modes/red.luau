local RunService = game:GetService("RunService")
local Red = require(game:GetService("ReplicatedStorage").Red)

local Benches = require(game:GetService("ReplicatedStorage").Shared.benches)
local IsServer = RunService:IsServer()

local Events = {}
local NetAPI

if IsServer then
	NetAPI = Red.Server("RedBenchmark")
else
	NetAPI = Red.Client("RedBenchmark")
end

for Name in Benches do
	Events[Name] = {
		fire = function(data)
			if not IsServer then
				NetAPI:Fire(Name, data)
			end
		end,
		listen = function(callback)
			NetAPI:On(Name, callback)
		end,
	}
end

return Events
