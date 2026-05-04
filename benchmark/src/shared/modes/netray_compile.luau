local RunService = game:GetService("RunService")

local Benches = require(game:GetService("ReplicatedStorage").Shared.benches)
local IsServer = RunService:IsServer()

local Events = {}
local NetRayAPI

if IsServer then
	NetRayAPI = require(script.Parent.netray_compile_gen.Server)
else
	NetRayAPI = require(script.Parent.netray_compile_gen.Client)
end

for Name in Benches do
	Events[Name] = {
		fire = function(data)
			if not IsServer then
				NetRayAPI[Name].Fire(data)
			end
		end,
		listen = function(callback)
			if IsServer then
				NetRayAPI[Name].On(callback)
			else
				NetRayAPI[Name].On(callback)
			end
		end,
	}
end

return Events
