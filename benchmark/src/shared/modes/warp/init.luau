-- Warp benchmark mode (v1.0.14 API).
-- Warp uses string identifiers and separate Server/Client constructors that return event objects.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Benches = require(ReplicatedStorage.Shared.benches)
local Warp = require(script.lib)

local IsServer = RunService:IsServer()
local Events = {}

for Name in Benches do
	local eventName = "WarpBench_" .. Name
	local warpEvent
	if IsServer then
		warpEvent = Warp.Server()
	else
		-- This yields on the client until the server registers the event.
		-- This is acceptable during require() as the runner waits.
		warpEvent = Warp.Client()
		warpEvent.awaitReady()
	end

	local schema = require(script:FindFirstChild(Name))
	warpEvent.useSchema(Name, schema)

	Events[Name] = {
		fire = function(data)
			if not IsServer then
				warpEvent.Fire(Name, true, data)
			end
		end,
		listen = function(callback)
			warpEvent.Connect(Name, callback)
		end,
		Connect = function(self, callback)
			warpEvent.Connect(Name, callback)
		end,
		Fire = function(self, reliable, data)
			if not IsServer then
				warpEvent.Fire(Name, reliable, data)
			end
		end,
	}
end

return Events
