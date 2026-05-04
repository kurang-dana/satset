-- Benchmark client. Fires 200 events per frame for 10 seconds per tool per bench.
-- Measures FPS and bandwidth (Kbps) at percentile intervals.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Stats = game:GetService("Stats")

local Satset = require(ReplicatedStorage.references.Satset)
Satset.start({
	batching = {
		reliableThreshold = 60000,
		maxPacketsPerFrame = 20,
	},
})

local MAXIMUM_FRAMERATE = 60

local Benches, Modes

-- Minimize rendering overhead to isolate network performance.
-- Disabe Character AutoLoads in Player service instead

for _, item in Enum.CoreGuiType:GetEnumItems() do
	while true do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(item, false)
		end)
		if ok then
			break
		end
	end
end

type Benchmark = {
	Sent: number,
	Recieve: number,
	Bandwidth: { number },
	NormalizedBandwidth: { number },
	Framerate: { number },
	DrainDuration: number,
}

type Results = {
	[string]: {
		[string]: Benchmark,
	},
}

local function percentile(samples: { number }, pct: number)
	if #samples == 0 then
		return 0
	end
	assert((pct // 1) == pct and pct >= 0 and pct <= 100, "Percentile must be an integer between 0 and 100")

	if pct == 0 then
		return samples[1]
	end

	local index = math.ceil(#samples * pct / 100)
	return samples[math.clamp(index, 1, #samples)]
end

local function measureBaseline(duration: number?): number
	duration = duration or 5

	local started = os.clock()
	local samples = {}

	while os.clock() - started < duration do
		table.insert(samples, Stats.DataSendKbps)
		RunService.Heartbeat:Wait()
	end

	table.sort(samples)

	-- Use p50 baseline to avoid random spikes.
	local index = math.max(1, math.ceil(#samples * 0.5))
	return samples[index]
end

local function waitForDrain(baselineKbps: number): number
	print("Waiting for packets to drain.")

	local started = os.clock()
	local stableStarted: number? = nil

	local tolerance = math.max(1, baselineKbps * 0.25)
	local threshold = baselineKbps + tolerance

	local stableDuration = 3
	local timeout = 60

	while true do
		local current = Stats.DataSendKbps
		local now = os.clock()

		if current <= threshold then
			stableStarted = stableStarted or now

			if now - stableStarted >= stableDuration then
				break
			end
		else
			stableStarted = nil
		end

		if now - started >= timeout then
			warn(`Timed out waiting for drain. Current: {current}, threshold: {threshold}`)
			break
		end

		RunService.Heartbeat:Wait()
	end

	return os.clock() - started
end

local function runBenchmark(tool: string, bench: string): Benchmark
	local total = 0
	local frames = 0
	local bandwidth = {}
	local normalizedBandwidth = {}
	local framerates = {}

	local sent = 0
	local data = Benches[bench]
	local events = Modes[tool]
	local event = events[bench]
	local method

	local lowerTool = string.lower(tool)
	if lowerTool == "roblox" then
		method = function(d)
			event:FireServer(d)
		end
	elseif lowerTool == "bridgenet2" then
		method = function(d)
			event:Fire(d)
		end
	elseif lowerTool == "warp" then
		method = function(d)
			event:Fire(true, d)
		end
	else
		method = event.fire or event.Fire or event.send
	end

	local connection = RunService.PostSimulation:Connect(function(dt: number)
		total += dt
		frames += 1

		if total >= 1 then
			local actualKbps = Stats.DataSendKbps
			local fps = frames / total
			local scale = MAXIMUM_FRAMERATE / math.max(1, fps)
			local scaledKbps = actualKbps * scale

			table.insert(bandwidth, actualKbps)
			table.insert(normalizedBandwidth, scaledKbps)
			table.insert(framerates, frames)

			total = 0
			frames = 0
		end

		for _ = 1, 200 do
			sent += 1
			method(data)
		end
	end)

	task.wait(10)
	connection:Disconnect()
	print("> Finished running with " .. tool)

	table.sort(bandwidth)
	table.sort(normalizedBandwidth)
	table.sort(framerates)

	local frameratePercentiles = {}
	local bandwidthPercentiles = {}
	local normalizedBandwidthPercentiles = {}

	for _, pct in { 50, 0, 80, 90, 95, 100 } do
		table.insert(bandwidthPercentiles, percentile(bandwidth, pct))
		table.insert(normalizedBandwidthPercentiles, percentile(normalizedBandwidth, pct))
		table.insert(frameratePercentiles, percentile(framerates, pct))
	end

	return {
		Sent = sent,
		Recieve = 0,
		Bandwidth = bandwidthPercentiles,
		NormalizedBandwidth = normalizedBandwidthPercentiles,
		Framerate = frameratePercentiles,
	}
end

local function runAll()
	Benches = require(ReplicatedStorage.Shared.benches)
	Modes = require(ReplicatedStorage.Shared.modes)
	local results: Results = {}

	print("Measuring baseline bandwidth...")
	local baselineKbps = measureBaseline(5)
	print(`Baseline DataSendKbps: {baselineKbps}`)

	for bench in Benches do
		warn("Running " .. bench .. " benchmark")
		results[bench] = {}

		for tool in Modes do
			print("> Running with " .. tool)
			results[bench][tool] = runBenchmark(tool, bench)
			local drainDuration = waitForDrain(baselineKbps)
			results[bench][tool].DrainDuration = drainDuration
		end

		waitForDrain(baselineKbps)
	end

	-- Pull server-side receive counts for loss calculation.
	local serverReceived = ReplicatedStorage.Shared.GetRecieved:InvokeServer()
	for bench, tools in serverReceived do
		for tool, count in tools do
			if results[bench] and results[bench][tool] then
				results[bench][tool].Recieve = count
			end
		end
	end

	print("Finished running benchmarks, generating results...")
	ReplicatedStorage.Shared.Generate:FireServer(HttpService:JSONEncode(results))
end

task.wait(2)
runAll()
