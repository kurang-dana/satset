-- Benchmark server. Receives data from all modes and validates correctness.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Satset = require(ReplicatedStorage.references.Satset)
Satset.start({
	batching = {
		reliableThreshold = 60000,
		maxPacketsPerFrame = 20,
	},
})

local Benches = require(game:GetService("ReplicatedStorage").Shared.benches)
local Modes = require(ReplicatedStorage.Shared.modes)

local compareTables: (a: any, b: any) -> boolean

local function compareValues(a: any, b: any): boolean
	if type(a) == "table" or type(b) == "table" then
		return compareTables(a, b)
	end
	if type(a) == "number" and type(b) == "number" then
		return math.abs(a - b) < 0.5
	end
	if typeof(a) == "Vector3" and typeof(b) == "Vector3" then
		return (a - b).Magnitude < 1.0
	end
	if typeof(a) == "Vector2" and typeof(b) == "Vector2" then
		return (a - b).Magnitude < 1.0
	end
	return a == b
end

function compareTables(a, b)
	if a == b then
		return true
	end
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return false
	end

	local keys = {}
	for key, value in a do
		local other = b[key]
		if other == nil or not compareValues(value, other) then
			return false
		end
		keys[key] = true
	end

	for key in b do
		if not keys[key] then
			return false
		end
	end

	return true
end

-- Track received counts per bench per tool for loss calculation.
local received = {}
for name, data in Benches do
	local benchReceived = {}
	received[name] = benchReceived

	local function onReceive(tool: string)
		benchReceived[tool] = 0

		return function(player, value)
			benchReceived[tool] += 1
			if benchReceived[tool] > 1 then
				return
			end

			-- ByteNet swaps argument order.
			if tool == "bytenet" then
				player, value = value, player
			end

			if not compareValues(data, value) then
				warn("Received incorrect data with " .. tool .. " for " .. name)
				print("Expected:", data)
				print("Received:", value)
			else
				print("> " .. tool .. " passed " .. name .. " validation!")
			end
		end
	end

	for tool, events in Modes do
		local lowerTool = string.lower(tool)
		local event = events[name]

		local callback = onReceive(tool)

		if lowerTool == "roblox" or lowerTool == "packet" then
			-- roblox and packet use .OnServerEvent
			event.OnServerEvent:Connect(callback)
		elseif lowerTool == "bridgenet2" or lowerTool == "warp" then
			-- bridgenet2 and warp use standard :Connect()
			event:Connect(callback)
		elseif event.listen then
			-- satset and bytenet use .listen()
			event.listen(callback)
		elseif event.On then -- netray_compile/blink
			event.On(callback)
		end
	end
end

-- Client pulls received counts to compute packet loss.
ReplicatedStorage.Shared.GetRecieved.OnServerInvoke = function()
	return received
end

-- Client sends JSON results, server writes them out.
ReplicatedStorage.Shared.Generate.OnServerEvent:Connect(function(_player, json)
	local output = Instance.new("StringValue")
	output.Name = "Result"
	output.Value = json
	output.Parent = game
	print("Generated results")
end)
