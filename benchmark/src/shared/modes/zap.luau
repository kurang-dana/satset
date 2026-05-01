local RunService = game:GetService("RunService")

local Benches = require(game:GetService("ReplicatedStorage").Shared.benches)
local IsServer = RunService:IsServer()

local Events = {}
local ZapAPI

if IsServer then
	ZapAPI = require(script.Parent.zap_gen.server)
else
	ZapAPI = require(script.Parent.zap_gen.client)
end

for Name in Benches do
	Events[Name] = {
		fire = function(data)
			if not IsServer then
				ZapAPI[Name].Fire(data)
			end
		end,
		listen = function(callback)
			ZapAPI[Name].SetCallback(callback)
		end,
	}
end

return Events
