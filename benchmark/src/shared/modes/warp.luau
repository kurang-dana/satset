-- Warp benchmark mode (v1.0.14 API).
-- Warp uses string identifiers and separate Server/Client constructors that return event objects.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Benches = require(ReplicatedStorage.Shared.benches)
local Warp = require(ReplicatedStorage.DevPackages.Warp)

local IsServer = RunService:IsServer()
local Events = {}

for Name in Benches do
	local eventName = "WarpBench_" .. Name
	local warpEvent
	if IsServer then
		warpEvent = Warp.Server(eventName)
	else
		-- This yields on the client until the server registers the event.
		-- This is acceptable during require() as the runner waits.
		warpEvent = Warp.Client(eventName)
	end

	Events[Name] = {
		-- Internal fire/listen for consistency with other adapters
		fire = function(data)
			if not IsServer then
				-- Warp Client Fire: (reliable, ...)
				warpEvent:Fire(true, data)
			end
		end,
		listen = function(callback)
			-- Warp Connect: (callback)
			warpEvent:Connect(callback)
		end,

		-- Runner expects Fire/Connect for Warp (as seen in init.client/init.server)
		Fire = function(self, reliable, data)
			if not IsServer then
				warpEvent:Fire(reliable, data)
			end
		end,
		Connect = function(self, callback)
			warpEvent:Connect(callback)
		end,
	}
end

return Events
