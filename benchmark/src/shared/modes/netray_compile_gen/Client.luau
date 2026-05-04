--!strict
--!native
--!optimize 2
--!nolint LocalShadow
--#selene: allow(shadowing)
-- Name: Client
-- Purpose: Generated runtime for client networking
-- Generated-by: NetRay-Compiler
-- Version: 0.1.1

local Types = require(script.Parent.Types)
type u8 = typeof(Types.u8)
type i8 = typeof(Types.i8)
type u16 = typeof(Types.u16)
type i16 = typeof(Types.i16)
type u32 = typeof(Types.u32)
type i32 = typeof(Types.i32)
type f16 = typeof(Types.f16)
type f32 = typeof(Types.f32)
type f64 = typeof(Types.f64)
type NetRoot = typeof(Types.NetClient)
type NetStats = typeof(Types.NetStats)
type Connection = typeof(Types.Connection)
type Net_Booleans_reliable_ClientApi = typeof(Types.Net_Booleans_reliable_ClientApi)
type Net_Booleans_reliable_ClientEventCallback = typeof(Types.Net_Booleans_reliable_ClientEventCallback)
type Net_Entities_reliable_ClientApi = typeof(Types.Net_Entities_reliable_ClientApi)
type Net_Entities_reliable_ClientEventCallback = typeof(Types.Net_Entities_reliable_ClientEventCallback)
type Net_Vectors_reliable_ClientApi = typeof(Types.Net_Vectors_reliable_ClientApi)
type Net_Vectors_reliable_ClientEventCallback = typeof(Types.Net_Vectors_reliable_ClientEventCallback)
type Net_Strings_reliable_ClientApi = typeof(Types.Net_Strings_reliable_ClientApi)
type Net_Strings_reliable_ClientEventCallback = typeof(Types.Net_Strings_reliable_ClientEventCallback)
type Net_Mixed_reliable_ClientApi = typeof(Types.Net_Mixed_reliable_ClientApi)
type Net_Mixed_reliable_ClientEventCallback = typeof(Types.Net_Mixed_reliable_ClientEventCallback)
type Net_SingleValue_reliable_ClientApi = typeof(Types.Net_SingleValue_reliable_ClientApi)
type Net_SingleValue_reliable_ClientEventCallback = typeof(Types.Net_SingleValue_reliable_ClientEventCallback)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Reliable = ReplicatedStorage:WaitForChild("NetRay_RELIABLE") :: RemoteEvent
local Unreliable = ReplicatedStorage:WaitForChild("NetRay_UNRELIABLE") :: UnreliableRemoteEvent
local FunctionRemote = ReplicatedStorage:WaitForChild("NetRay_FUNCTION") :: RemoteFunction

local function WithCount(...)
	return select("#", ...), ...
end

local DEFAULT_ARENA_CAPACITY = 65536
local create = buffer.create
local copy = buffer.copy
local len = buffer.len
local writeu8 = buffer.writeu8

local writef32 = buffer.writef32
local writestring = buffer.writestring
local readu8 = buffer.readu8

local band = bit32.band
local bor = bit32.bor
local rshift = bit32.rshift
local lshift = bit32.lshift

local ERR_BOUNDS = "E_BOUNDS"
local ERR_SCHEMA = "E_SCHEMA"
local ERR_TAG = "E_TAG"
local ERR_TYPE = "E_TYPE"
local SEGMENT_MARKER_ID = 0

local function VarUIntSize(value)
	if value < 128 then
		return 1
	end
	if value < 16384 then
		return 2
	end
	if value < 2097152 then
		return 3
	end
	if value < 268435456 then
		return 4
	end
	return 5
end

local function WriteVarUInt(payload, offset, value)
	if value < 128 then
		writeu8(payload, offset, value)
		return offset + 1
	end
	if value < 16384 then
		writeu8(payload, offset, bor(band(value, 127), 128))
		writeu8(payload, offset + 1, band(rshift(value, 7), 127))
		return offset + 2
	end
	if value < 2097152 then
		writeu8(payload, offset, bor(band(value, 127), 128))
		writeu8(payload, offset + 1, bor(band(rshift(value, 7), 127), 128))
		writeu8(payload, offset + 2, band(rshift(value, 14), 127))
		return offset + 3
	end
	if value < 268435456 then
		writeu8(payload, offset, bor(band(value, 127), 128))
		writeu8(payload, offset + 1, bor(band(rshift(value, 7), 127), 128))
		writeu8(payload, offset + 2, bor(band(rshift(value, 14), 127), 128))
		writeu8(payload, offset + 3, band(rshift(value, 21), 127))
		return offset + 4
	end
	writeu8(payload, offset, bor(band(value, 127), 128))
	writeu8(payload, offset + 1, bor(band(rshift(value, 7), 127), 128))
	writeu8(payload, offset + 2, bor(band(rshift(value, 14), 127), 128))
	writeu8(payload, offset + 3, bor(band(rshift(value, 21), 127), 128))
	writeu8(payload, offset + 4, band(rshift(value, 28), 15))
	return offset + 5
end

local function ReadVarUInt(payload, payloadLength, offset)
	local next1 = offset + 1
	if next1 > payloadLength then
		error(ERR_BOUNDS)
	end
	local b1 = readu8(payload, offset)
	if b1 < 128 then
		return b1, next1
	end
	local next2 = next1 + 1
	if next2 > payloadLength then
		error(ERR_BOUNDS)
	end
	local b2 = readu8(payload, next1)
	local value = band(b1, 127) + lshift(band(b2, 127), 7)
	if b2 < 128 then
		return value, next2
	end
	local next3 = next2 + 1
	if next3 > payloadLength then
		error(ERR_BOUNDS)
	end
	local b3 = readu8(payload, next2)
	value += lshift(band(b3, 127), 14)
	if b3 < 128 then
		return value, next3
	end
	local next4 = next3 + 1
	if next4 > payloadLength then
		error(ERR_BOUNDS)
	end
	local b4 = readu8(payload, next3)
	value += lshift(band(b4, 127), 21)
	if b4 < 128 then
		return value, next4
	end
	local next5 = next4 + 1
	if next5 > payloadLength then
		error(ERR_BOUNDS)
	end
	local b5 = readu8(payload, next4)
	if b5 >= 16 then
		error(ERR_SCHEMA)
	end
	value += lshift(b5, 28)
	return value, next5
end

local function CreateConnection(disconnectFn: () -> ()): Connection
	local active = true
	local connection = {} :: any
	connection.Connected = true
	function connection:Disconnect()
		if not active then
			return
		end
		active = false
		connection.Connected = false
		disconnectFn()
	end
	return connection :: Connection
end

local MAX_RELIABLE_ID = 6
local MAX_UNRELIABLE_ID = 0
local MAX_FUNCTION_ID = 0
local RELIABLE_DISPATCH = table.create(MAX_RELIABLE_ID)
local UNRELIABLE_DISPATCH = table.create(MAX_UNRELIABLE_ID)
local RELIABLE_SKIP = table.create(MAX_RELIABLE_ID)
local UNRELIABLE_SKIP = table.create(MAX_UNRELIABLE_ID)
local FUNCTION_DISPATCH = table.create(MAX_FUNCTION_ID)

local RELIABLE_ARENA_CAPACITY = DEFAULT_ARENA_CAPACITY
local RELIABLE_ARENA = create(RELIABLE_ARENA_CAPACITY)
local RELIABLE_CURSOR = 0
local RELIABLE_QUEUE_SIZE = 0
local RELIABLE_DROPPED = 0
local RELIABLE_SEGMENT_HEADER_BYTES = 2
local RELIABLE_SEGMENT_MIN_COUNT = 4
local RELIABLE_SEGMENT_MIN_TAIL_BYTES = 3

local function FlushReliable()
	if RELIABLE_CURSOR == 0 then
		RELIABLE_QUEUE_SIZE = 0
		return
	end
	local payloadToSend = create(RELIABLE_CURSOR)
	local payloadOffset = RELIABLE_CURSOR
	if RELIABLE_QUEUE_SIZE >= RELIABLE_SEGMENT_MIN_COUNT then
		-- Only scan runs when the batch is large enough to amortize segment headers.
		local sourceOffset = 0
		payloadOffset = 0
		while sourceOffset < RELIABLE_CURSOR do
			local runStart = sourceOffset
			local messageId = readu8(RELIABLE_ARENA, sourceOffset)
			sourceOffset += 1
			local skip = RELIABLE_SKIP[messageId]
			local firstBodyEnd = skip(RELIABLE_ARENA, RELIABLE_CURSOR, sourceOffset)
			local runEnd = firstBodyEnd
			local runCount = 1
			if RELIABLE_CURSOR - firstBodyEnd < RELIABLE_SEGMENT_MIN_TAIL_BYTES then
				-- Remaining bytes cannot fit enough repeated IDs to make segmentation pay off.
				local tailSize = RELIABLE_CURSOR - runStart
				if tailSize > 0 then
					copy(payloadToSend, payloadOffset, RELIABLE_ARENA, runStart, tailSize)
					payloadOffset += tailSize
				end
				break
			end
			while runEnd < RELIABLE_CURSOR do
				local nextMessageId = readu8(RELIABLE_ARENA, runEnd)
				if nextMessageId ~= messageId then
					break
				end
				local nextBodyStart = runEnd + 1
				runEnd = skip(RELIABLE_ARENA, RELIABLE_CURSOR, nextBodyStart)
				runCount += 1
			end
			if runCount * 1 > RELIABLE_SEGMENT_HEADER_BYTES + VarUIntSize(runCount) then
				writeu8(payloadToSend, payloadOffset, SEGMENT_MARKER_ID)
				payloadOffset += 1
				writeu8(payloadToSend, payloadOffset, messageId)
				payloadOffset += 1
				payloadOffset = WriteVarUInt(payloadToSend, payloadOffset, runCount)
				local copyCursor = sourceOffset
				local bodyEnd = firstBodyEnd
				while true do
					local bodySize = bodyEnd - copyCursor
					if bodySize > 0 then
						copy(payloadToSend, payloadOffset, RELIABLE_ARENA, copyCursor, bodySize)
						payloadOffset += bodySize
					end
					if bodyEnd >= runEnd then
						break
					end
					copyCursor = bodyEnd + 1
					bodyEnd = skip(RELIABLE_ARENA, RELIABLE_CURSOR, copyCursor)
				end
			else
				local runSize = runEnd - runStart
				if runSize > 0 then
					copy(payloadToSend, payloadOffset, RELIABLE_ARENA, runStart, runSize)
					payloadOffset += runSize
				end
			end
			sourceOffset = runEnd
		end
	else
		-- For tiny batches, a direct copy is cheaper than any merge scan.
		copy(payloadToSend, 0, RELIABLE_ARENA, 0, RELIABLE_CURSOR)
	end
	if payloadOffset < RELIABLE_CURSOR then
		local compactPayload = create(payloadOffset)
		copy(compactPayload, 0, payloadToSend, 0, payloadOffset)
		payloadToSend = compactPayload
	end
	Reliable:FireServer(payloadToSend)
	RELIABLE_CURSOR = 0
	RELIABLE_QUEUE_SIZE = 0
end

local UNRELIABLE_ARENA_CAPACITY = DEFAULT_ARENA_CAPACITY
local UNRELIABLE_ARENA = create(UNRELIABLE_ARENA_CAPACITY)
local UNRELIABLE_CURSOR = 0
local UNRELIABLE_QUEUE_SIZE = 0
local UNRELIABLE_DROPPED = 0
local UNRELIABLE_SEGMENT_HEADER_BYTES = 2
local UNRELIABLE_SEGMENT_MIN_COUNT = 4
local UNRELIABLE_SEGMENT_MIN_TAIL_BYTES = 3

local function FlushUnreliable()
	if UNRELIABLE_CURSOR == 0 then
		UNRELIABLE_QUEUE_SIZE = 0
		return
	end
	local payloadToSend = create(UNRELIABLE_CURSOR)
	local payloadOffset = UNRELIABLE_CURSOR
	if UNRELIABLE_QUEUE_SIZE >= UNRELIABLE_SEGMENT_MIN_COUNT then
		-- Only scan runs when the batch is large enough to amortize segment headers.
		local sourceOffset = 0
		payloadOffset = 0
		while sourceOffset < UNRELIABLE_CURSOR do
			local runStart = sourceOffset
			local messageId = readu8(UNRELIABLE_ARENA, sourceOffset)
			sourceOffset += 1
			local skip = UNRELIABLE_SKIP[messageId]
			local firstBodyEnd = skip(UNRELIABLE_ARENA, UNRELIABLE_CURSOR, sourceOffset)
			local runEnd = firstBodyEnd
			local runCount = 1
			if UNRELIABLE_CURSOR - firstBodyEnd < UNRELIABLE_SEGMENT_MIN_TAIL_BYTES then
				-- Remaining bytes cannot fit enough repeated IDs to make segmentation pay off.
				local tailSize = UNRELIABLE_CURSOR - runStart
				if tailSize > 0 then
					copy(payloadToSend, payloadOffset, UNRELIABLE_ARENA, runStart, tailSize)
					payloadOffset += tailSize
				end
				break
			end
			while runEnd < UNRELIABLE_CURSOR do
				local nextMessageId = readu8(UNRELIABLE_ARENA, runEnd)
				if nextMessageId ~= messageId then
					break
				end
				local nextBodyStart = runEnd + 1
				runEnd = skip(UNRELIABLE_ARENA, UNRELIABLE_CURSOR, nextBodyStart)
				runCount += 1
			end
			if runCount * 1 > UNRELIABLE_SEGMENT_HEADER_BYTES + VarUIntSize(runCount) then
				writeu8(payloadToSend, payloadOffset, SEGMENT_MARKER_ID)
				payloadOffset += 1
				writeu8(payloadToSend, payloadOffset, messageId)
				payloadOffset += 1
				payloadOffset = WriteVarUInt(payloadToSend, payloadOffset, runCount)
				local copyCursor = sourceOffset
				local bodyEnd = firstBodyEnd
				while true do
					local bodySize = bodyEnd - copyCursor
					if bodySize > 0 then
						copy(payloadToSend, payloadOffset, UNRELIABLE_ARENA, copyCursor, bodySize)
						payloadOffset += bodySize
					end
					if bodyEnd >= runEnd then
						break
					end
					copyCursor = bodyEnd + 1
					bodyEnd = skip(UNRELIABLE_ARENA, UNRELIABLE_CURSOR, copyCursor)
				end
			else
				local runSize = runEnd - runStart
				if runSize > 0 then
					copy(payloadToSend, payloadOffset, UNRELIABLE_ARENA, runStart, runSize)
					payloadOffset += runSize
				end
			end
			sourceOffset = runEnd
		end
	else
		-- For tiny batches, a direct copy is cheaper than any merge scan.
		copy(payloadToSend, 0, UNRELIABLE_ARENA, 0, UNRELIABLE_CURSOR)
	end
	if payloadOffset < UNRELIABLE_CURSOR then
		local compactPayload = create(payloadOffset)
		copy(compactPayload, 0, payloadToSend, 0, payloadOffset)
		payloadToSend = compactPayload
	end
	Unreliable:FireServer(payloadToSend)
	UNRELIABLE_CURSOR = 0
	UNRELIABLE_QUEUE_SIZE = 0
end

local Net_Booleans_reliable_1: Net_Booleans_reliable_ClientApi = {} :: Net_Booleans_reliable_ClientApi
local MESSAGE_ID_Net_Booleans_reliable_1 = 1

local function Encode_Net_Booleans_reliable_1(data)
	local prefixSize = 0
	local varSize = 0
	local arrayLen_1 = #data
	if arrayLen_1 > 4294967295 then
		error(ERR_SCHEMA)
	end
	prefixSize += VarUIntSize(arrayLen_1)
	varSize += ((arrayLen_1 + 7) // 8)
	local totalSize = 1 + prefixSize + varSize
	local payload = create(totalSize)
	writeu8(payload, 0, MESSAGE_ID_Net_Booleans_reliable_1)
	local prefixOffset = 1
	local fixedOffset = prefixOffset + prefixSize
	local varOffset = fixedOffset
	prefixOffset = WriteVarUInt(payload, prefixOffset, arrayLen_1)
	local arrayPackedByteCount_5 = ((arrayLen_1 + 7) // 8)
	local arrayValueIndex_7 = 1
	for arrayPackedIndex_6 = 1, arrayPackedByteCount_5 do
		local arrayPackedByte_10 = 0
		local arrayBitMask_9 = 1
		for arrayBitIndex_8 = 1, 8 do
			if arrayValueIndex_7 > arrayLen_1 then
				break
			end
			if data[arrayValueIndex_7] then
				arrayPackedByte_10 = bor(arrayPackedByte_10, arrayBitMask_9)
			end
			arrayValueIndex_7 += 1
			arrayBitMask_9 = lshift(arrayBitMask_9, 1)
		end
		writeu8(payload, varOffset, arrayPackedByte_10)
		varOffset += 1
	end
	return payload
end

local Handler_Net_Booleans_reliable_1: ((data: { boolean }) -> ())? = nil
local HandlerToken_Net_Booleans_reliable_1 = 0

local function Skip_Net_Booleans_reliable_1(payload, payloadLength, offset)
	local prefixCursor_1 = offset
	local arrayCount_2
	arrayCount_2, prefixCursor_1 = ReadVarUInt(payload, payloadLength, prefixCursor_1)
	local fixedCursor_3 = prefixCursor_1
	local varCursor_4 = fixedCursor_3
	if varCursor_4 > payloadLength then
		error(ERR_BOUNDS)
	end
	local skipArrayPackedByteCount_5 = ((arrayCount_2 + 7) // 8)
	local skipArrayPackedNext_6 = varCursor_4 + skipArrayPackedByteCount_5
	if skipArrayPackedNext_6 > payloadLength then
		error(ERR_BOUNDS)
	end
	varCursor_4 = skipArrayPackedNext_6
	offset = varCursor_4
	return offset
end

RELIABLE_SKIP[1] = Skip_Net_Booleans_reliable_1

function Net_Booleans_reliable_1.Fire(data: { boolean }): boolean
	local __nr_prefixSize = 0
	local __nr_varSize = 0
	local arrayLen_1 = #data
	if arrayLen_1 > 4294967295 then
		error(ERR_SCHEMA)
	end
	__nr_prefixSize += VarUIntSize(arrayLen_1)
	__nr_varSize += ((arrayLen_1 + 7) // 8)
	local __nr_totalSize = 1 + __nr_prefixSize + __nr_varSize
	local __nr_base = RELIABLE_CURSOR
	local __nr_required = __nr_base + __nr_totalSize
	if __nr_required > RELIABLE_ARENA_CAPACITY then
		local nextCapacity = RELIABLE_ARENA_CAPACITY
		while nextCapacity < __nr_required do
			nextCapacity *= 2
		end
		local nextArena = create(nextCapacity)
		if RELIABLE_CURSOR > 0 then
			copy(nextArena, 0, RELIABLE_ARENA, 0, RELIABLE_CURSOR)
		end
		RELIABLE_ARENA = nextArena
		RELIABLE_ARENA_CAPACITY = nextCapacity
	end
	RELIABLE_CURSOR = __nr_required
	local __nr_payload = RELIABLE_ARENA
	writeu8(__nr_payload, __nr_base, MESSAGE_ID_Net_Booleans_reliable_1)
	local __nr_prefix = __nr_base + 1
	local __nr_fixed = __nr_prefix + __nr_prefixSize
	local __nr_var = __nr_fixed
	__nr_prefix = WriteVarUInt(__nr_payload, __nr_prefix, arrayLen_1)
	local arrayPackedByteCount_5 = ((arrayLen_1 + 7) // 8)
	local arrayValueIndex_7 = 1
	for arrayPackedIndex_6 = 1, arrayPackedByteCount_5 do
		local arrayPackedByte_10 = 0
		local arrayBitMask_9 = 1
		for arrayBitIndex_8 = 1, 8 do
			if arrayValueIndex_7 > arrayLen_1 then
				break
			end
			if data[arrayValueIndex_7] then
				arrayPackedByte_10 = bor(arrayPackedByte_10, arrayBitMask_9)
			end
			arrayValueIndex_7 += 1
			arrayBitMask_9 = lshift(arrayBitMask_9, 1)
		end
		writeu8(__nr_payload, __nr_var, arrayPackedByte_10)
		__nr_var += 1
	end
	RELIABLE_QUEUE_SIZE += 1
	return true
end

local Net_Entities_reliable_2: Net_Entities_reliable_ClientApi = {} :: Net_Entities_reliable_ClientApi
local MESSAGE_ID_Net_Entities_reliable_2 = 2

local function Encode_Net_Entities_reliable_2(data)
	local prefixSize = 0
	local varSize = 0
	local arrayLen_1 = #data
	if arrayLen_1 > 4294967295 then
		error(ERR_SCHEMA)
	end
	prefixSize += VarUIntSize(arrayLen_1)
	for arrayIndex_2 = 1, arrayLen_1 do
		varSize += 1
		varSize += 1
		varSize += 1
		varSize += 1
		varSize += 1
		varSize += 1
	end
	local totalSize = 1 + prefixSize + varSize
	local payload = create(totalSize)
	writeu8(payload, 0, MESSAGE_ID_Net_Entities_reliable_2)
	local prefixOffset = 1
	local fixedOffset = prefixOffset + prefixSize
	local varOffset = fixedOffset
	prefixOffset = WriteVarUInt(payload, prefixOffset, arrayLen_1)
	for arrayIndex_4 = 1, arrayLen_1 do
		writeu8(payload, varOffset, data[arrayIndex_4].id)
		varOffset += 1
		writeu8(payload, varOffset, data[arrayIndex_4].x)
		varOffset += 1
		writeu8(payload, varOffset, data[arrayIndex_4].y)
		varOffset += 1
		writeu8(payload, varOffset, data[arrayIndex_4].z)
		varOffset += 1
		writeu8(payload, varOffset, data[arrayIndex_4].orientation)
		varOffset += 1
		writeu8(payload, varOffset, data[arrayIndex_4].animation)
		varOffset += 1
	end
	return payload
end

local Handler_Net_Entities_reliable_2: ((data: { { id: u8, x: u8, y: u8, z: u8, orientation: u8, animation: u8 } }) -> ())? =
	nil
local HandlerToken_Net_Entities_reliable_2 = 0

local function Skip_Net_Entities_reliable_2(payload, payloadLength, offset)
	local prefixCursor_1 = offset
	local arrayCount_2
	arrayCount_2, prefixCursor_1 = ReadVarUInt(payload, payloadLength, prefixCursor_1)
	local fixedCursor_3 = prefixCursor_1
	local varCursor_4 = fixedCursor_3
	if varCursor_4 > payloadLength then
		error(ERR_BOUNDS)
	end
	for skipArrayIndex_5 = 1, arrayCount_2 do
		local skipNext_6 = varCursor_4 + 1
		if skipNext_6 > payloadLength then
			error(ERR_BOUNDS)
		end
		varCursor_4 = skipNext_6
		local skipNext_7 = varCursor_4 + 1
		if skipNext_7 > payloadLength then
			error(ERR_BOUNDS)
		end
		varCursor_4 = skipNext_7
		local skipNext_8 = varCursor_4 + 1
		if skipNext_8 > payloadLength then
			error(ERR_BOUNDS)
		end
		varCursor_4 = skipNext_8
		local skipNext_9 = varCursor_4 + 1
		if skipNext_9 > payloadLength then
			error(ERR_BOUNDS)
		end
		varCursor_4 = skipNext_9
		local skipNext_10 = varCursor_4 + 1
		if skipNext_10 > payloadLength then
			error(ERR_BOUNDS)
		end
		varCursor_4 = skipNext_10
		local skipNext_11 = varCursor_4 + 1
		if skipNext_11 > payloadLength then
			error(ERR_BOUNDS)
		end
		varCursor_4 = skipNext_11
	end
	offset = varCursor_4
	return offset
end

RELIABLE_SKIP[2] = Skip_Net_Entities_reliable_2

function Net_Entities_reliable_2.Fire(
	data: { { id: u8, x: u8, y: u8, z: u8, orientation: u8, animation: u8 } }
): boolean
	local __nr_prefixSize = 0
	local __nr_varSize = 0
	local arrayLen_1 = #data
	if arrayLen_1 > 4294967295 then
		error(ERR_SCHEMA)
	end
	__nr_prefixSize += VarUIntSize(arrayLen_1)
	for arrayIndex_2 = 1, arrayLen_1 do
		__nr_varSize += 1
		__nr_varSize += 1
		__nr_varSize += 1
		__nr_varSize += 1
		__nr_varSize += 1
		__nr_varSize += 1
	end
	local __nr_totalSize = 1 + __nr_prefixSize + __nr_varSize
	local __nr_base = RELIABLE_CURSOR
	local __nr_required = __nr_base + __nr_totalSize
	if __nr_required > RELIABLE_ARENA_CAPACITY then
		local nextCapacity = RELIABLE_ARENA_CAPACITY
		while nextCapacity < __nr_required do
			nextCapacity *= 2
		end
		local nextArena = create(nextCapacity)
		if RELIABLE_CURSOR > 0 then
			copy(nextArena, 0, RELIABLE_ARENA, 0, RELIABLE_CURSOR)
		end
		RELIABLE_ARENA = nextArena
		RELIABLE_ARENA_CAPACITY = nextCapacity
	end
	RELIABLE_CURSOR = __nr_required
	local __nr_payload = RELIABLE_ARENA
	writeu8(__nr_payload, __nr_base, MESSAGE_ID_Net_Entities_reliable_2)
	local __nr_prefix = __nr_base + 1
	local __nr_fixed = __nr_prefix + __nr_prefixSize
	local __nr_var = __nr_fixed
	__nr_prefix = WriteVarUInt(__nr_payload, __nr_prefix, arrayLen_1)
	for arrayIndex_4 = 1, arrayLen_1 do
		writeu8(__nr_payload, __nr_var, data[arrayIndex_4].id)
		__nr_var += 1
		writeu8(__nr_payload, __nr_var, data[arrayIndex_4].x)
		__nr_var += 1
		writeu8(__nr_payload, __nr_var, data[arrayIndex_4].y)
		__nr_var += 1
		writeu8(__nr_payload, __nr_var, data[arrayIndex_4].z)
		__nr_var += 1
		writeu8(__nr_payload, __nr_var, data[arrayIndex_4].orientation)
		__nr_var += 1
		writeu8(__nr_payload, __nr_var, data[arrayIndex_4].animation)
		__nr_var += 1
	end
	RELIABLE_QUEUE_SIZE += 1
	return true
end

local Net_Vectors_reliable_3: Net_Vectors_reliable_ClientApi = {} :: Net_Vectors_reliable_ClientApi
local MESSAGE_ID_Net_Vectors_reliable_3 = 3

local function Encode_Net_Vectors_reliable_3(data)
	local prefixSize = 0
	local varSize = 0
	local arrayLen_1 = #data
	if arrayLen_1 > 4294967295 then
		error(ERR_SCHEMA)
	end
	prefixSize += VarUIntSize(arrayLen_1)
	for arrayIndex_2 = 1, arrayLen_1 do
		local vectorValue_4 = data[arrayIndex_2]
		varSize += 12
	end
	local totalSize = 1 + prefixSize + varSize
	local payload = create(totalSize)
	writeu8(payload, 0, MESSAGE_ID_Net_Vectors_reliable_3)
	local prefixOffset = 1
	local fixedOffset = prefixOffset + prefixSize
	local varOffset = fixedOffset
	prefixOffset = WriteVarUInt(payload, prefixOffset, arrayLen_1)
	for arrayIndex_5 = 1, arrayLen_1 do
		local vectorValue_6 = data[arrayIndex_5]
		writef32(payload, varOffset, vectorValue_6.X)
		varOffset += 4
		writef32(payload, varOffset, vectorValue_6.Y)
		varOffset += 4
		writef32(payload, varOffset, vectorValue_6.Z)
		varOffset += 4
	end
	return payload
end

local Handler_Net_Vectors_reliable_3: ((data: { Vector3 }) -> ())? = nil
local HandlerToken_Net_Vectors_reliable_3 = 0

local function Skip_Net_Vectors_reliable_3(payload, payloadLength, offset)
	local prefixCursor_1 = offset
	local arrayCount_2
	arrayCount_2, prefixCursor_1 = ReadVarUInt(payload, payloadLength, prefixCursor_1)
	local fixedCursor_3 = prefixCursor_1
	local varCursor_4 = fixedCursor_3
	if varCursor_4 > payloadLength then
		error(ERR_BOUNDS)
	end
	for skipArrayIndex_5 = 1, arrayCount_2 do
		local skipVectorNext_6 = varCursor_4 + 12
		if skipVectorNext_6 > payloadLength then
			error(ERR_BOUNDS)
		end
		varCursor_4 = skipVectorNext_6
	end
	offset = varCursor_4
	return offset
end

RELIABLE_SKIP[3] = Skip_Net_Vectors_reliable_3

function Net_Vectors_reliable_3.Fire(data: { Vector3 }): boolean
	local __nr_prefixSize = 0
	local __nr_varSize = 0
	local arrayLen_1 = #data
	if arrayLen_1 > 4294967295 then
		error(ERR_SCHEMA)
	end
	__nr_prefixSize += VarUIntSize(arrayLen_1)
	for arrayIndex_2 = 1, arrayLen_1 do
		local vectorValue_4 = data[arrayIndex_2]
		__nr_varSize += 12
	end
	local __nr_totalSize = 1 + __nr_prefixSize + __nr_varSize
	local __nr_base = RELIABLE_CURSOR
	local __nr_required = __nr_base + __nr_totalSize
	if __nr_required > RELIABLE_ARENA_CAPACITY then
		local nextCapacity = RELIABLE_ARENA_CAPACITY
		while nextCapacity < __nr_required do
			nextCapacity *= 2
		end
		local nextArena = create(nextCapacity)
		if RELIABLE_CURSOR > 0 then
			copy(nextArena, 0, RELIABLE_ARENA, 0, RELIABLE_CURSOR)
		end
		RELIABLE_ARENA = nextArena
		RELIABLE_ARENA_CAPACITY = nextCapacity
	end
	RELIABLE_CURSOR = __nr_required
	local __nr_payload = RELIABLE_ARENA
	writeu8(__nr_payload, __nr_base, MESSAGE_ID_Net_Vectors_reliable_3)
	local __nr_prefix = __nr_base + 1
	local __nr_fixed = __nr_prefix + __nr_prefixSize
	local __nr_var = __nr_fixed
	__nr_prefix = WriteVarUInt(__nr_payload, __nr_prefix, arrayLen_1)
	for arrayIndex_5 = 1, arrayLen_1 do
		local vectorValue_6 = data[arrayIndex_5]
		writef32(__nr_payload, __nr_var, vectorValue_6.X)
		__nr_var += 4
		writef32(__nr_payload, __nr_var, vectorValue_6.Y)
		__nr_var += 4
		writef32(__nr_payload, __nr_var, vectorValue_6.Z)
		__nr_var += 4
	end
	RELIABLE_QUEUE_SIZE += 1
	return true
end

local Net_Strings_reliable_4: Net_Strings_reliable_ClientApi = {} :: Net_Strings_reliable_ClientApi
local MESSAGE_ID_Net_Strings_reliable_4 = 4

local function Encode_Net_Strings_reliable_4(data)
	local prefixSize = 0
	local varSize = 0
	local arrayLen_1 = #data
	if arrayLen_1 > 4294967295 then
		error(ERR_SCHEMA)
	end
	prefixSize += VarUIntSize(arrayLen_1)
	for arrayIndex_2 = 1, arrayLen_1 do
		local stringLen_4 = #data[arrayIndex_2]
		if stringLen_4 > 4294967295 then
			error(ERR_SCHEMA)
		end
		varSize += VarUIntSize(stringLen_4) + stringLen_4
	end
	local totalSize = 1 + prefixSize + varSize
	local payload = create(totalSize)
	writeu8(payload, 0, MESSAGE_ID_Net_Strings_reliable_4)
	local prefixOffset = 1
	local fixedOffset = prefixOffset + prefixSize
	local varOffset = fixedOffset
	prefixOffset = WriteVarUInt(payload, prefixOffset, arrayLen_1)
	for arrayIndex_5 = 1, arrayLen_1 do
		local stringLen_6 = #data[arrayIndex_5]
		varOffset = WriteVarUInt(payload, varOffset, stringLen_6)
		writestring(payload, varOffset, data[arrayIndex_5])
		varOffset += stringLen_6
	end
	return payload
end

local Handler_Net_Strings_reliable_4: ((data: { string }) -> ())? = nil
local HandlerToken_Net_Strings_reliable_4 = 0

local function Skip_Net_Strings_reliable_4(payload, payloadLength, offset)
	local prefixCursor_1 = offset
	local arrayCount_2
	arrayCount_2, prefixCursor_1 = ReadVarUInt(payload, payloadLength, prefixCursor_1)
	local fixedCursor_3 = prefixCursor_1
	local varCursor_4 = fixedCursor_3
	if varCursor_4 > payloadLength then
		error(ERR_BOUNDS)
	end
	for skipArrayIndex_5 = 1, arrayCount_2 do
		local skipStringLen_6
		skipStringLen_6, varCursor_4 = ReadVarUInt(payload, payloadLength, varCursor_4)
		if skipStringLen_6 > 4294967295 then
			error(ERR_SCHEMA)
		end
		local skipStringNext_7 = varCursor_4 + skipStringLen_6
		if skipStringNext_7 > payloadLength then
			error(ERR_BOUNDS)
		end
		varCursor_4 = skipStringNext_7
	end
	offset = varCursor_4
	return offset
end

RELIABLE_SKIP[4] = Skip_Net_Strings_reliable_4

function Net_Strings_reliable_4.Fire(data: { string }): boolean
	local __nr_prefixSize = 0
	local __nr_varSize = 0
	local arrayLen_1 = #data
	if arrayLen_1 > 4294967295 then
		error(ERR_SCHEMA)
	end
	__nr_prefixSize += VarUIntSize(arrayLen_1)
	for arrayIndex_2 = 1, arrayLen_1 do
		local stringLen_4 = #data[arrayIndex_2]
		if stringLen_4 > 4294967295 then
			error(ERR_SCHEMA)
		end
		__nr_varSize += VarUIntSize(stringLen_4) + stringLen_4
	end
	local __nr_totalSize = 1 + __nr_prefixSize + __nr_varSize
	local __nr_base = RELIABLE_CURSOR
	local __nr_required = __nr_base + __nr_totalSize
	if __nr_required > RELIABLE_ARENA_CAPACITY then
		local nextCapacity = RELIABLE_ARENA_CAPACITY
		while nextCapacity < __nr_required do
			nextCapacity *= 2
		end
		local nextArena = create(nextCapacity)
		if RELIABLE_CURSOR > 0 then
			copy(nextArena, 0, RELIABLE_ARENA, 0, RELIABLE_CURSOR)
		end
		RELIABLE_ARENA = nextArena
		RELIABLE_ARENA_CAPACITY = nextCapacity
	end
	RELIABLE_CURSOR = __nr_required
	local __nr_payload = RELIABLE_ARENA
	writeu8(__nr_payload, __nr_base, MESSAGE_ID_Net_Strings_reliable_4)
	local __nr_prefix = __nr_base + 1
	local __nr_fixed = __nr_prefix + __nr_prefixSize
	local __nr_var = __nr_fixed
	__nr_prefix = WriteVarUInt(__nr_payload, __nr_prefix, arrayLen_1)
	for arrayIndex_5 = 1, arrayLen_1 do
		local stringLen_6 = #data[arrayIndex_5]
		__nr_var = WriteVarUInt(__nr_payload, __nr_var, stringLen_6)
		writestring(__nr_payload, __nr_var, data[arrayIndex_5])
		__nr_var += stringLen_6
	end
	RELIABLE_QUEUE_SIZE += 1
	return true
end

local Net_Mixed_reliable_5: Net_Mixed_reliable_ClientApi = {} :: Net_Mixed_reliable_ClientApi
local MESSAGE_ID_Net_Mixed_reliable_5 = 5

local function Encode_Net_Mixed_reliable_5(data)
	local totalSize = 1
	totalSize += 1
	totalSize += 1
	local vectorValue_1 = data.position
	totalSize += 12
	local vectorValue_2 = data.velocity
	totalSize += 12
	local stringLen_3 = #data.name
	if stringLen_3 > 4294967295 then
		error(ERR_SCHEMA)
	end
	totalSize += VarUIntSize(stringLen_3) + stringLen_3
	totalSize += 1
	totalSize += 1
	totalSize += 1
	local payload = create(totalSize)
	writeu8(payload, 0, MESSAGE_ID_Net_Mixed_reliable_5)
	local offset = 1
	writeu8(payload, offset, data.id)
	offset += 1
	writeu8(payload, offset, data.health)
	offset += 1
	local vectorValue_4 = data.position
	writef32(payload, offset, vectorValue_4.X)
	offset += 4
	writef32(payload, offset, vectorValue_4.Y)
	offset += 4
	writef32(payload, offset, vectorValue_4.Z)
	offset += 4
	local vectorValue_5 = data.velocity
	writef32(payload, offset, vectorValue_5.X)
	offset += 4
	writef32(payload, offset, vectorValue_5.Y)
	offset += 4
	writef32(payload, offset, vectorValue_5.Z)
	offset += 4
	offset = WriteVarUInt(payload, offset, stringLen_3)
	writestring(payload, offset, data.name)
	offset += stringLen_3
	writeu8(payload, offset, data.isRunning and 1 or 0)
	offset += 1
	writeu8(payload, offset, data.animation)
	offset += 1
	writeu8(payload, offset, data.team)
	offset += 1
	return payload
end

local Handler_Net_Mixed_reliable_5: ((
	data: {
		id: u8,
		health: u8,
		position: Vector3,
		velocity: Vector3,
		name: string,
		isRunning: boolean,
		animation: u8,
		team: u8,
	}
) -> ())? =
	nil
local HandlerToken_Net_Mixed_reliable_5 = 0

local function Skip_Net_Mixed_reliable_5(payload, payloadLength, offset)
	local skipNext_1 = offset + 1
	if skipNext_1 > payloadLength then
		error(ERR_BOUNDS)
	end
	offset = skipNext_1
	local skipNext_2 = offset + 1
	if skipNext_2 > payloadLength then
		error(ERR_BOUNDS)
	end
	offset = skipNext_2
	local skipVectorNext_3 = offset + 12
	if skipVectorNext_3 > payloadLength then
		error(ERR_BOUNDS)
	end
	offset = skipVectorNext_3
	local skipVectorNext_4 = offset + 12
	if skipVectorNext_4 > payloadLength then
		error(ERR_BOUNDS)
	end
	offset = skipVectorNext_4
	local skipStringLen_5
	skipStringLen_5, offset = ReadVarUInt(payload, payloadLength, offset)
	if skipStringLen_5 > 4294967295 then
		error(ERR_SCHEMA)
	end
	local skipStringNext_6 = offset + skipStringLen_5
	if skipStringNext_6 > payloadLength then
		error(ERR_BOUNDS)
	end
	offset = skipStringNext_6
	local skipBoolNext_7 = offset + 1
	if skipBoolNext_7 > payloadLength then
		error(ERR_BOUNDS)
	end
	offset = skipBoolNext_7
	local skipNext_8 = offset + 1
	if skipNext_8 > payloadLength then
		error(ERR_BOUNDS)
	end
	offset = skipNext_8
	local skipNext_9 = offset + 1
	if skipNext_9 > payloadLength then
		error(ERR_BOUNDS)
	end
	offset = skipNext_9
	return offset
end

RELIABLE_SKIP[5] = Skip_Net_Mixed_reliable_5

function Net_Mixed_reliable_5.Fire(data: {
	id: u8,
	health: u8,
	position: Vector3,
	velocity: Vector3,
	name: string,
	isRunning: boolean,
	animation: u8,
	team: u8,
}): boolean
	local __nr_totalSize = 1
	__nr_totalSize += 1
	__nr_totalSize += 1
	local vectorValue_1 = data.position
	__nr_totalSize += 12
	local vectorValue_2 = data.velocity
	__nr_totalSize += 12
	local stringLen_3 = #data.name
	if stringLen_3 > 4294967295 then
		error(ERR_SCHEMA)
	end
	__nr_totalSize += VarUIntSize(stringLen_3) + stringLen_3
	__nr_totalSize += 1
	__nr_totalSize += 1
	__nr_totalSize += 1
	local __nr_base = RELIABLE_CURSOR
	local __nr_required = __nr_base + __nr_totalSize
	if __nr_required > RELIABLE_ARENA_CAPACITY then
		local nextCapacity = RELIABLE_ARENA_CAPACITY
		while nextCapacity < __nr_required do
			nextCapacity *= 2
		end
		local nextArena = create(nextCapacity)
		if RELIABLE_CURSOR > 0 then
			copy(nextArena, 0, RELIABLE_ARENA, 0, RELIABLE_CURSOR)
		end
		RELIABLE_ARENA = nextArena
		RELIABLE_ARENA_CAPACITY = nextCapacity
	end
	RELIABLE_CURSOR = __nr_required
	local __nr_payload = RELIABLE_ARENA
	writeu8(__nr_payload, __nr_base, MESSAGE_ID_Net_Mixed_reliable_5)
	local __nr_p = __nr_base + 1
	writeu8(__nr_payload, __nr_p, data.id)
	__nr_p += 1
	writeu8(__nr_payload, __nr_p, data.health)
	__nr_p += 1
	local vectorValue_4 = data.position
	writef32(__nr_payload, __nr_p, vectorValue_4.X)
	__nr_p += 4
	writef32(__nr_payload, __nr_p, vectorValue_4.Y)
	__nr_p += 4
	writef32(__nr_payload, __nr_p, vectorValue_4.Z)
	__nr_p += 4
	local vectorValue_5 = data.velocity
	writef32(__nr_payload, __nr_p, vectorValue_5.X)
	__nr_p += 4
	writef32(__nr_payload, __nr_p, vectorValue_5.Y)
	__nr_p += 4
	writef32(__nr_payload, __nr_p, vectorValue_5.Z)
	__nr_p += 4
	__nr_p = WriteVarUInt(__nr_payload, __nr_p, stringLen_3)
	writestring(__nr_payload, __nr_p, data.name)
	__nr_p += stringLen_3
	writeu8(__nr_payload, __nr_p, data.isRunning and 1 or 0)
	__nr_p += 1
	writeu8(__nr_payload, __nr_p, data.animation)
	__nr_p += 1
	writeu8(__nr_payload, __nr_p, data.team)
	__nr_p += 1
	RELIABLE_QUEUE_SIZE += 1
	return true
end

local Net_SingleValue_reliable_6: Net_SingleValue_reliable_ClientApi = {} :: Net_SingleValue_reliable_ClientApi
local MESSAGE_ID_Net_SingleValue_reliable_6 = 6

local function Encode_Net_SingleValue_reliable_6(data)
	local totalSize = 2
	local payload = create(totalSize)
	writeu8(payload, 0, MESSAGE_ID_Net_SingleValue_reliable_6)
	local offset = 1
	local fixedWriteBase_1 = offset
	writeu8(payload, fixedWriteBase_1, data)
	return payload
end

local Handler_Net_SingleValue_reliable_6: ((data: u8) -> ())? = nil
local HandlerToken_Net_SingleValue_reliable_6 = 0

local function Skip_Net_SingleValue_reliable_6(payload, payloadLength, offset)
	local skipNext_1 = offset + 1
	if skipNext_1 > payloadLength then
		error(ERR_BOUNDS)
	end
	offset = skipNext_1
	return offset
end

RELIABLE_SKIP[6] = Skip_Net_SingleValue_reliable_6

function Net_SingleValue_reliable_6.Fire(data: u8): boolean
	local __nr_totalSize = 2
	local __nr_base = RELIABLE_CURSOR
	local __nr_required = __nr_base + __nr_totalSize
	if __nr_required > RELIABLE_ARENA_CAPACITY then
		local nextCapacity = RELIABLE_ARENA_CAPACITY
		while nextCapacity < __nr_required do
			nextCapacity *= 2
		end
		local nextArena = create(nextCapacity)
		if RELIABLE_CURSOR > 0 then
			copy(nextArena, 0, RELIABLE_ARENA, 0, RELIABLE_CURSOR)
		end
		RELIABLE_ARENA = nextArena
		RELIABLE_ARENA_CAPACITY = nextCapacity
	end
	RELIABLE_CURSOR = __nr_required
	local __nr_payload = RELIABLE_ARENA
	writeu8(__nr_payload, __nr_base, MESSAGE_ID_Net_SingleValue_reliable_6)
	local __nr_p = __nr_base + 1
	local fixedWriteBase_1 = __nr_p
	writeu8(__nr_payload, fixedWriteBase_1, data)
	RELIABLE_QUEUE_SIZE += 1
	return true
end

local function StepReplication()
	FlushReliable()
	FlushUnreliable()
end

RunService.Heartbeat:Connect(StepReplication)

Reliable.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "buffer" then
		return
	end
	local payloadLength = len(payload)
	if payloadLength < 1 then
		return
	end
	local offset = 0
	while offset < payloadLength do
		local messageId = readu8(payload, offset)
		offset += 1
		local segmentCount = 1
		local dispatch
		if messageId == SEGMENT_MARKER_ID then
			if offset >= payloadLength then
				return
			end
			messageId = readu8(payload, offset)
			offset += 1
			dispatch = RELIABLE_DISPATCH[messageId]
			if dispatch == nil then
				return
			end
			segmentCount, offset = ReadVarUInt(payload, payloadLength, offset)
			if segmentCount < 1 then
				return
			end
		else
			dispatch = RELIABLE_DISPATCH[messageId]
			if dispatch == nil then
				return
			end
		end
		for _segmentIndex = 1, segmentCount do
			local nextOffset = dispatch(payload, payloadLength, offset)
			offset = nextOffset
		end
	end
end)

Unreliable.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "buffer" then
		return
	end
	local payloadLength = len(payload)
	if payloadLength < 1 then
		return
	end
	local offset = 0
	while offset < payloadLength do
		local messageId = readu8(payload, offset)
		offset += 1
		local segmentCount = 1
		local dispatch
		if messageId == SEGMENT_MARKER_ID then
			if offset >= payloadLength then
				return
			end
			messageId = readu8(payload, offset)
			offset += 1
			dispatch = UNRELIABLE_DISPATCH[messageId]
			if dispatch == nil then
				return
			end
			segmentCount, offset = ReadVarUInt(payload, payloadLength, offset)
			if segmentCount < 1 then
				return
			end
		else
			dispatch = UNRELIABLE_DISPATCH[messageId]
			if dispatch == nil then
				return
			end
		end
		for _segmentIndex = 1, segmentCount do
			local nextOffset = dispatch(payload, payloadLength, offset)
			offset = nextOffset
		end
	end
end)

FunctionRemote.OnClientInvoke = function(payload, ...)
	if typeof(payload) ~= "buffer" then
		error(ERR_TYPE)
	end
	local payloadLength = len(payload)
	if payloadLength < 1 then
		error(ERR_BOUNDS)
	end
	local messageId = readu8(payload, 0)
	local dispatch = FUNCTION_DISPATCH[messageId]
	if dispatch == nil then
		error(ERR_SCHEMA)
	end
	return dispatch(payload, payloadLength)
end

local Stats: NetStats = {
	GetReliableDropped = function()
		return RELIABLE_DROPPED
	end,
	GetUnreliableDropped = function()
		return UNRELIABLE_DROPPED
	end,
	GetReliableQueueSize = function()
		return RELIABLE_QUEUE_SIZE
	end,
	GetUnreliableQueueSize = function()
		return UNRELIABLE_QUEUE_SIZE
	end,
}

local Net = {
	Booleans = Net_Booleans_reliable_1,
	Entities = Net_Entities_reliable_2,
	Vectors = Net_Vectors_reliable_3,
	Strings = Net_Strings_reliable_4,
	Mixed = Net_Mixed_reliable_5,
	SingleValue = Net_SingleValue_reliable_6,
}

Net.StepReplication = StepReplication
Net.Stats = Stats
local NetTyped: NetRoot = Net

return table.freeze(NetTyped)
