-- This file is part of the Satset networking library and is licensed under MIT License; see LICENSE.txt for details
-- Batcher — handles per-frame packet batching and unreliable transport hardening.

local RunService = game:GetService("RunService")

local Bridge = require(script.Parent.Bridge)

-- [ Constants ]

local IS_SERVER = RunService:IsServer()

-- UnreliableRemoteEvent has a limit around 1000 bytes.
-- We cap at 900 to stay safe.
local UNRELIABLE_MTU = 900

-- [ Types ]

type QueueEntry = { id: number, payload: buffer }

-- [ State ]

-- We use separate queues for reliable and unreliable to respect transport semantics.
local serverReliable: { [Player]: { QueueEntry } } = {}
local serverUnreliable: { [Player]: { QueueEntry } } = {}
local broadcastReliable: { QueueEntry } = {}

local clientReliable: { QueueEntry } = {}
local clientUnreliable: { QueueEntry } = {}

-- Monotonic sequence counters to prevent out-of-order execution on unreliable channels.
local serverSeqCounters: { [Player]: number } = {}
local clientSeqCounter: number = 0

-- Tracking the last received sequence to discard stale packets.
local lastReceivedSeq: { [Player]: number } = {}
local lastServerSeq: number = 0

local Batcher = {}

-- [ Private Logic ]

--[[
	Encodes a list of packets into a single reliable batch buffer.
	
	Wire format:
	[u8 packetCount]
	...[u8 id][u16 size][payload]
]]
local function encodeBatch(queue: { QueueEntry }): buffer?
	local count = #queue
	if count == 0 then
		return nil
	end

	local totalSize = 1
	for _, entry in queue do
		totalSize += 1 + 2 + buffer.len(entry.payload)
	end

	local b = buffer.create(totalSize)
	local cursor = 0

	buffer.writeu8(b, cursor, count)
	cursor += 1

	for _, entry in queue do
		local payloadLen = buffer.len(entry.payload)
		buffer.writeu8(b, cursor, entry.id)
		cursor += 1
		buffer.writeu16(b, cursor, payloadLen)
		cursor += 2
		buffer.copy(b, cursor, entry.payload, 0, payloadLen)
		cursor += payloadLen
	end

	return b
end

--[[
	Encodes packets into one or more unreliable batches, ensuring MTU safety.
	Each batch gets its own sequence number.
	
	Wire format:
	[u16 sequenceNumber][u8 packetCount]
	...[u8 id][u16 size][payload]
]]
local function encodeUnreliableBatches(queue: { QueueEntry }, seqCounter: number): ({ buffer }, number)
	if #queue == 0 then
		return {}, seqCounter
	end

	local batches: { buffer } = {}
	local currentEntries: { QueueEntry } = {}
	local currentSize = 3

	for _, entry in queue do
		local entrySize = 1 + 2 + buffer.len(entry.payload)

		-- If this packet would push us over the limit, we flush the current sub-batch.
		if currentSize + entrySize > UNRELIABLE_MTU and #currentEntries > 0 then
			seqCounter = (seqCounter + 1) % 65536
			local b = buffer.create(currentSize)
			local cursor = 0

			buffer.writeu16(b, cursor, seqCounter)
			cursor += 2
			buffer.writeu8(b, cursor, #currentEntries)
			cursor += 1

			for _, e in currentEntries do
				local pLen = buffer.len(e.payload)
				buffer.writeu8(b, cursor, e.id)
				cursor += 1
				buffer.writeu16(b, cursor, pLen)
				cursor += 2
				buffer.copy(b, cursor, e.payload, 0, pLen)
				cursor += pLen
			end

			table.insert(batches, b)
			table.clear(currentEntries)
			currentSize = 3
		end

		table.insert(currentEntries, entry)
		currentSize += entrySize
	end

	-- Flush any remaining packets.
	if #currentEntries > 0 then
		seqCounter = (seqCounter + 1) % 65536
		local b = buffer.create(currentSize)
		local cursor = 0

		buffer.writeu16(b, cursor, seqCounter)
		cursor += 2
		buffer.writeu8(b, cursor, #currentEntries)
		cursor += 1

		for _, e in currentEntries do
			local pLen = buffer.len(e.payload)
			buffer.writeu8(b, cursor, e.id)
			cursor += 1
			buffer.writeu16(b, cursor, pLen)
			cursor += 2
			buffer.copy(b, cursor, e.payload, 0, pLen)
			cursor += pLen
		end

		table.insert(batches, b)
	end

	return batches, seqCounter
end

-- [ Internal API ]

--[[
	Splits a reliable batch back into individual packets.
]]
function Batcher.decodeBatch(b: buffer): { QueueEntry }
	local results = {}
	local cursor = 0
	local bufLen = buffer.len(b)

	if bufLen < 1 then
		return results
	end

	local count = buffer.readu8(b, cursor)
	cursor += 1

	for _ = 1, count do
		if cursor + 3 > bufLen then
			break
		end

		local id = buffer.readu8(b, cursor)
		cursor += 1
		local payloadLen = buffer.readu16(b, cursor)
		cursor += 2

		if cursor + payloadLen > bufLen then
			break
		end

		local payload = buffer.create(payloadLen)
		buffer.copy(payload, 0, b, cursor, payloadLen)
		cursor += payloadLen

		table.insert(results, { id = id, payload = payload })
	end

	return results
end

--[[
	Decodes an unreliable batch and checks for staleness.
	If the packet is too old, it returns nil.
]]
function Batcher.decodeUnreliableBatch(b: buffer, sender: Player?): { QueueEntry }?
	local bufLen = buffer.len(b)
	if bufLen < 3 then
		return nil
	end

	local seq = buffer.readu16(b, 0)

	local lastSeq: number
	if IS_SERVER then
		lastSeq = lastReceivedSeq[sender :: Player] or 0
	else
		lastSeq = lastServerSeq
	end

	-- We use a half-window comparison to handle 16-bit wraparound correctly.
	local diff = (seq - lastSeq) % 65536
	if diff == 0 or diff > 32768 then
		return nil -- Stale or duplicate.
	end

	if IS_SERVER then
		lastReceivedSeq[sender :: Player] = seq
	else
		lastServerSeq = seq
	end

	local results = {}
	local cursor = 2

	local count = buffer.readu8(b, cursor)
	cursor += 1

	for _ = 1, count do
		if cursor + 3 > bufLen then
			break
		end

		local id = buffer.readu8(b, cursor)
		cursor += 1
		local payloadLen = buffer.readu16(b, cursor)
		cursor += 2

		if cursor + payloadLen > bufLen then
			break
		end

		local payload = buffer.create(payloadLen)
		buffer.copy(payload, 0, b, cursor, payloadLen)
		cursor += payloadLen

		table.insert(results, { id = id, payload = payload })
	end

	return results
end

-- [ Enqueue API ]

function Batcher.enqueueForPlayer(player: Player, packetId: number, payload: buffer, reliable: boolean)
	if reliable then
		if not serverReliable[player] then
			serverReliable[player] = {}
		end
		table.insert(serverReliable[player], { id = packetId, payload = payload })
	else
		if not serverUnreliable[player] then
			serverUnreliable[player] = {}
		end
		table.insert(serverUnreliable[player], { id = packetId, payload = payload })
	end
end

function Batcher.enqueueForAllPlayers(packetId: number, payload: buffer)
	table.insert(broadcastReliable, { id = packetId, payload = payload })
end

function Batcher.enqueueForServer(packetId: number, payload: buffer, reliable: boolean)
	if reliable then
		table.insert(clientReliable, { id = packetId, payload = payload })
	else
		table.insert(clientUnreliable, { id = packetId, payload = payload })
	end
end

-- [ Flush ]

local function flush()
	if IS_SERVER then
		local reliableRemote = Bridge.getReliable()
		local unreliableRemote = Bridge.getUnreliable()

		for player, queue in serverReliable do
			if #queue > 0 then
				local batch = encodeBatch(queue)
				if batch then
					reliableRemote:FireClient(player, batch)
				end
				table.clear(queue)
			end
		end

		for player, queue in serverUnreliable do
			if #queue > 0 then
				local seq = serverSeqCounters[player] or 0
				local batches, newSeq = encodeUnreliableBatches(queue, seq)
				serverSeqCounters[player] = newSeq

				for _, batch in batches do
					unreliableRemote:FireClient(player, batch)
				end

				table.clear(queue)
			end
		end

		if #broadcastReliable > 0 then
			local batch = encodeBatch(broadcastReliable)
			if batch then
				reliableRemote:FireAllClients(batch)
			end
			table.clear(broadcastReliable)
		end
	else
		if #clientReliable > 0 then
			local batch = encodeBatch(clientReliable)
			if batch then
				Bridge.getReliable():FireServer(batch)
			end
			table.clear(clientReliable)
		end

		if #clientUnreliable > 0 then
			local batches, newSeq = encodeUnreliableBatches(clientUnreliable, clientSeqCounter)
			clientSeqCounter = newSeq

			for _, batch in batches do
				Bridge.getUnreliable():FireServer(batch)
			end

			table.clear(clientUnreliable)
		end
	end
end

--[[
	Connects the flush logic to the frame lifecycle.
]]
function Batcher.init()
	RunService.PostSimulation:Connect(flush)
end

--[[
	Purges a player's state when they disconnect.
]]
function Batcher.removePlayer(player: Player)
	serverReliable[player] = nil
	serverUnreliable[player] = nil
	serverSeqCounters[player] = nil
	lastReceivedSeq[player] = nil
end

return Batcher
