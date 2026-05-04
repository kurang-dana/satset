--!strict
--!native
--!optimize 2
--!nolint LocalShadow
--#selene: allow(shadowing)
-- Name: Server
-- Purpose: Generated runtime for server networking
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
type NetRoot = typeof(Types.NetServer)
type NetStats = typeof(Types.NetStats)
type Connection = typeof(Types.Connection)
type Net_Booleans_reliable_ServerApi = typeof(Types.Net_Booleans_reliable_ServerApi)
type Net_Booleans_reliable_ServerEventCallback = typeof(Types.Net_Booleans_reliable_ServerEventCallback)
type Net_Entities_reliable_ServerApi = typeof(Types.Net_Entities_reliable_ServerApi)
type Net_Entities_reliable_ServerEventCallback = typeof(Types.Net_Entities_reliable_ServerEventCallback)
type Net_Vectors_reliable_ServerApi = typeof(Types.Net_Vectors_reliable_ServerApi)
type Net_Vectors_reliable_ServerEventCallback = typeof(Types.Net_Vectors_reliable_ServerEventCallback)
type Net_Strings_reliable_ServerApi = typeof(Types.Net_Strings_reliable_ServerApi)
type Net_Strings_reliable_ServerEventCallback = typeof(Types.Net_Strings_reliable_ServerEventCallback)
type Net_Mixed_reliable_ServerApi = typeof(Types.Net_Mixed_reliable_ServerApi)
type Net_Mixed_reliable_ServerEventCallback = typeof(Types.Net_Mixed_reliable_ServerEventCallback)
type Net_SingleValue_reliable_ServerApi = typeof(Types.Net_SingleValue_reliable_ServerApi)
type Net_SingleValue_reliable_ServerEventCallback = typeof(Types.Net_SingleValue_reliable_ServerEventCallback)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local function FindOrCreateRemote(className, remoteName)
	local existing = ReplicatedStorage:FindFirstChild(remoteName)
	if existing ~= nil then
		if existing.ClassName ~= className then
			error(("Remote '%s' exists as '%s', expected '%s'"):format(remoteName, existing.ClassName, className))
		end
		return existing
	end
	local remote = Instance.new(className)
	remote.Name = remoteName
	remote.Parent = ReplicatedStorage
	return remote
end

local Reliable = FindOrCreateRemote("RemoteEvent", "NetRay_RELIABLE") :: RemoteEvent
local Unreliable = FindOrCreateRemote("UnreliableRemoteEvent", "NetRay_UNRELIABLE") :: UnreliableRemoteEvent
local FunctionRemote = FindOrCreateRemote("RemoteFunction", "NetRay_FUNCTION") :: RemoteFunction

local function WithCount(...)
	return select("#", ...), ...
end

local DEFAULT_ARENA_CAPACITY = 65536
local create = buffer.create
local copy = buffer.copy
local len = buffer.len
local writeu8 = buffer.writeu8

local readu8 = buffer.readu8

local readf32 = buffer.readf32
local readstring = buffer.readstring
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
	Reliable:FireAllClients(payloadToSend)
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
	Unreliable:FireAllClients(payloadToSend)
	UNRELIABLE_CURSOR = 0
	UNRELIABLE_QUEUE_SIZE = 0
end

local Net_Booleans_reliable_1: Net_Booleans_reliable_ServerApi = {} :: Net_Booleans_reliable_ServerApi
local MESSAGE_ID_Net_Booleans_reliable_1 = 1

local function Decode_Net_Booleans_reliable_1(payload, payloadLength, offset)
	local decoded_data
	local prefixCursor_1 = offset
	local arrayCount_2
	arrayCount_2, prefixCursor_1 = ReadVarUInt(payload, payloadLength, prefixCursor_1)
	local fixedCursor_3 = prefixCursor_1
	local varCursor_4 = fixedCursor_3
	if varCursor_4 > payloadLength then
		error(ERR_BOUNDS)
	end
	local arrayValues_6 = table.create(arrayCount_2)
	local arrayPackedByteCount_8 = ((arrayCount_2 + 7) // 8)
	local arrayPackedCursor_9 = varCursor_4
	local arrayPackedNext_10 = arrayPackedCursor_9 + arrayPackedByteCount_8
	if arrayPackedNext_10 > payloadLength then
		error(ERR_BOUNDS)
	end
	local arrayUnpackIndex_12 = 1
	for arrayPackedIndex_11 = 1, arrayPackedByteCount_8 do
		local arrayPackedByte_13 = readu8(payload, arrayPackedCursor_9)
		arrayPackedCursor_9 += 1
		local arrayBitMask_15 = 1
		for arrayBitIndex_14 = 1, 8 do
			if arrayUnpackIndex_12 > arrayCount_2 then
				break
			end
			arrayValues_6[arrayUnpackIndex_12] = band(arrayPackedByte_13, arrayBitMask_15) ~= 0
			arrayUnpackIndex_12 += 1
			arrayBitMask_15 = lshift(arrayBitMask_15, 1)
		end
	end
	varCursor_4 = arrayPackedCursor_9
	decoded_data = arrayValues_6
	offset = varCursor_4
	return decoded_data, offset
end

local Handler_Net_Booleans_reliable_1: ((player: Player, data: { boolean }) -> ())? = nil
local HandlerToken_Net_Booleans_reliable_1 = 0

function Net_Booleans_reliable_1.On(callback: Net_Booleans_reliable_ServerEventCallback): Connection
	if type(callback) ~= "function" then
		error(ERR_TYPE)
	end
	HandlerToken_Net_Booleans_reliable_1 += 1
	local token = HandlerToken_Net_Booleans_reliable_1
	Handler_Net_Booleans_reliable_1 = callback
	return CreateConnection(function()
		if HandlerToken_Net_Booleans_reliable_1 == token then
			HandlerToken_Net_Booleans_reliable_1 += 1
			Handler_Net_Booleans_reliable_1 = nil
		end
	end)
end

RELIABLE_DISPATCH[1] = function(player, payload, payloadLength, offset)
	local decoded_data, nextOffset = Decode_Net_Booleans_reliable_1(payload, payloadLength, offset)
	local callback = Handler_Net_Booleans_reliable_1
	if callback == nil then
		return nextOffset
	end
	callback(player, decoded_data)
	return nextOffset
end

local Net_Entities_reliable_2: Net_Entities_reliable_ServerApi = {} :: Net_Entities_reliable_ServerApi
local MESSAGE_ID_Net_Entities_reliable_2 = 2

local function Decode_Net_Entities_reliable_2(payload, payloadLength, offset)
	local decoded_data
	local prefixCursor_1 = offset
	local arrayCount_2
	arrayCount_2, prefixCursor_1 = ReadVarUInt(payload, payloadLength, prefixCursor_1)
	local fixedCursor_3 = prefixCursor_1
	local varCursor_4 = fixedCursor_3
	if varCursor_4 > payloadLength then
		error(ERR_BOUNDS)
	end
	local arrayValues_6 = table.create(arrayCount_2)
	for arrayIndex_5 = 1, arrayCount_2 do
		local arrayValue_7
		local structValue_8 = {}
		local structField_9
		local fieldNext_10 = varCursor_4 + 1
		if fieldNext_10 > payloadLength then
			error(ERR_BOUNDS)
		end
		structField_9 = readu8(payload, varCursor_4) :: u8
		varCursor_4 = fieldNext_10
		structValue_8["id"] = structField_9
		local structField_11
		local fieldNext_12 = varCursor_4 + 1
		if fieldNext_12 > payloadLength then
			error(ERR_BOUNDS)
		end
		structField_11 = readu8(payload, varCursor_4) :: u8
		varCursor_4 = fieldNext_12
		structValue_8["x"] = structField_11
		local structField_13
		local fieldNext_14 = varCursor_4 + 1
		if fieldNext_14 > payloadLength then
			error(ERR_BOUNDS)
		end
		structField_13 = readu8(payload, varCursor_4) :: u8
		varCursor_4 = fieldNext_14
		structValue_8["y"] = structField_13
		local structField_15
		local fieldNext_16 = varCursor_4 + 1
		if fieldNext_16 > payloadLength then
			error(ERR_BOUNDS)
		end
		structField_15 = readu8(payload, varCursor_4) :: u8
		varCursor_4 = fieldNext_16
		structValue_8["z"] = structField_15
		local structField_17
		local fieldNext_18 = varCursor_4 + 1
		if fieldNext_18 > payloadLength then
			error(ERR_BOUNDS)
		end
		structField_17 = readu8(payload, varCursor_4) :: u8
		varCursor_4 = fieldNext_18
		structValue_8["orientation"] = structField_17
		local structField_19
		local fieldNext_20 = varCursor_4 + 1
		if fieldNext_20 > payloadLength then
			error(ERR_BOUNDS)
		end
		structField_19 = readu8(payload, varCursor_4) :: u8
		varCursor_4 = fieldNext_20
		structValue_8["animation"] = structField_19
		arrayValue_7 = structValue_8
		arrayValues_6[arrayIndex_5] = arrayValue_7
	end
	decoded_data = arrayValues_6
	offset = varCursor_4
	return decoded_data, offset
end

local Handler_Net_Entities_reliable_2: ((player: Player, data: { { id: u8, x: u8, y: u8, z: u8, orientation: u8, animation: u8 } }) -> ())? =
	nil
local HandlerToken_Net_Entities_reliable_2 = 0

function Net_Entities_reliable_2.On(callback: Net_Entities_reliable_ServerEventCallback): Connection
	if type(callback) ~= "function" then
		error(ERR_TYPE)
	end
	HandlerToken_Net_Entities_reliable_2 += 1
	local token = HandlerToken_Net_Entities_reliable_2
	Handler_Net_Entities_reliable_2 = callback
	return CreateConnection(function()
		if HandlerToken_Net_Entities_reliable_2 == token then
			HandlerToken_Net_Entities_reliable_2 += 1
			Handler_Net_Entities_reliable_2 = nil
		end
	end)
end

RELIABLE_DISPATCH[2] = function(player, payload, payloadLength, offset)
	local decoded_data, nextOffset = Decode_Net_Entities_reliable_2(payload, payloadLength, offset)
	local callback = Handler_Net_Entities_reliable_2
	if callback == nil then
		return nextOffset
	end
	callback(player, decoded_data)
	return nextOffset
end

local Net_Vectors_reliable_3: Net_Vectors_reliable_ServerApi = {} :: Net_Vectors_reliable_ServerApi
local MESSAGE_ID_Net_Vectors_reliable_3 = 3

local function Decode_Net_Vectors_reliable_3(payload, payloadLength, offset)
	local decoded_data
	local prefixCursor_1 = offset
	local arrayCount_2
	arrayCount_2, prefixCursor_1 = ReadVarUInt(payload, payloadLength, prefixCursor_1)
	local fixedCursor_3 = prefixCursor_1
	local varCursor_4 = fixedCursor_3
	if varCursor_4 > payloadLength then
		error(ERR_BOUNDS)
	end
	local arrayValues_6 = table.create(arrayCount_2)
	for arrayIndex_5 = 1, arrayCount_2 do
		local arrayValue_7
		local vectorNext_8 = varCursor_4 + 12
		if vectorNext_8 > payloadLength then
			error(ERR_BOUNDS)
		end
		local vectorX_9 = readf32(payload, varCursor_4)
		local vectorY_10 = readf32(payload, varCursor_4 + 4)
		local vectorZ_11 = readf32(payload, varCursor_4 + 8)
		arrayValue_7 = Vector3.new(vectorX_9, vectorY_10, vectorZ_11)
		varCursor_4 = vectorNext_8
		arrayValues_6[arrayIndex_5] = arrayValue_7
	end
	decoded_data = arrayValues_6
	offset = varCursor_4
	return decoded_data, offset
end

local Handler_Net_Vectors_reliable_3: ((player: Player, data: { Vector3 }) -> ())? = nil
local HandlerToken_Net_Vectors_reliable_3 = 0

function Net_Vectors_reliable_3.On(callback: Net_Vectors_reliable_ServerEventCallback): Connection
	if type(callback) ~= "function" then
		error(ERR_TYPE)
	end
	HandlerToken_Net_Vectors_reliable_3 += 1
	local token = HandlerToken_Net_Vectors_reliable_3
	Handler_Net_Vectors_reliable_3 = callback
	return CreateConnection(function()
		if HandlerToken_Net_Vectors_reliable_3 == token then
			HandlerToken_Net_Vectors_reliable_3 += 1
			Handler_Net_Vectors_reliable_3 = nil
		end
	end)
end

RELIABLE_DISPATCH[3] = function(player, payload, payloadLength, offset)
	local decoded_data, nextOffset = Decode_Net_Vectors_reliable_3(payload, payloadLength, offset)
	local callback = Handler_Net_Vectors_reliable_3
	if callback == nil then
		return nextOffset
	end
	callback(player, decoded_data)
	return nextOffset
end

local Net_Strings_reliable_4: Net_Strings_reliable_ServerApi = {} :: Net_Strings_reliable_ServerApi
local MESSAGE_ID_Net_Strings_reliable_4 = 4

local function Decode_Net_Strings_reliable_4(payload, payloadLength, offset)
	local decoded_data
	local prefixCursor_1 = offset
	local arrayCount_2
	arrayCount_2, prefixCursor_1 = ReadVarUInt(payload, payloadLength, prefixCursor_1)
	local fixedCursor_3 = prefixCursor_1
	local varCursor_4 = fixedCursor_3
	if varCursor_4 > payloadLength then
		error(ERR_BOUNDS)
	end
	local arrayValues_6 = table.create(arrayCount_2)
	for arrayIndex_5 = 1, arrayCount_2 do
		local arrayValue_7
		local stringLen_8
		stringLen_8, varCursor_4 = ReadVarUInt(payload, payloadLength, varCursor_4)
		if stringLen_8 > 4294967295 then
			error(ERR_SCHEMA)
		end
		local stringNext_9 = varCursor_4 + stringLen_8
		if stringNext_9 > payloadLength then
			error(ERR_BOUNDS)
		end
		arrayValue_7 = readstring(payload, varCursor_4, stringLen_8)
		varCursor_4 = stringNext_9
		arrayValues_6[arrayIndex_5] = arrayValue_7
	end
	decoded_data = arrayValues_6
	offset = varCursor_4
	return decoded_data, offset
end

local Handler_Net_Strings_reliable_4: ((player: Player, data: { string }) -> ())? = nil
local HandlerToken_Net_Strings_reliable_4 = 0

function Net_Strings_reliable_4.On(callback: Net_Strings_reliable_ServerEventCallback): Connection
	if type(callback) ~= "function" then
		error(ERR_TYPE)
	end
	HandlerToken_Net_Strings_reliable_4 += 1
	local token = HandlerToken_Net_Strings_reliable_4
	Handler_Net_Strings_reliable_4 = callback
	return CreateConnection(function()
		if HandlerToken_Net_Strings_reliable_4 == token then
			HandlerToken_Net_Strings_reliable_4 += 1
			Handler_Net_Strings_reliable_4 = nil
		end
	end)
end

RELIABLE_DISPATCH[4] = function(player, payload, payloadLength, offset)
	local decoded_data, nextOffset = Decode_Net_Strings_reliable_4(payload, payloadLength, offset)
	local callback = Handler_Net_Strings_reliable_4
	if callback == nil then
		return nextOffset
	end
	callback(player, decoded_data)
	return nextOffset
end

local Net_Mixed_reliable_5: Net_Mixed_reliable_ServerApi = {} :: Net_Mixed_reliable_ServerApi
local MESSAGE_ID_Net_Mixed_reliable_5 = 5

local function Decode_Net_Mixed_reliable_5(payload, payloadLength, offset)
	local decoded_data
	local structValue_1 = {}
	local structField_2
	local fieldNext_3 = offset + 1
	if fieldNext_3 > payloadLength then
		error(ERR_BOUNDS)
	end
	structField_2 = readu8(payload, offset) :: u8
	offset = fieldNext_3
	structValue_1["id"] = structField_2
	local structField_4
	local fieldNext_5 = offset + 1
	if fieldNext_5 > payloadLength then
		error(ERR_BOUNDS)
	end
	structField_4 = readu8(payload, offset) :: u8
	offset = fieldNext_5
	structValue_1["health"] = structField_4
	local structField_6
	local vectorNext_7 = offset + 12
	if vectorNext_7 > payloadLength then
		error(ERR_BOUNDS)
	end
	local vectorX_8 = readf32(payload, offset)
	local vectorY_9 = readf32(payload, offset + 4)
	local vectorZ_10 = readf32(payload, offset + 8)
	structField_6 = Vector3.new(vectorX_8, vectorY_9, vectorZ_10)
	offset = vectorNext_7
	structValue_1["position"] = structField_6
	local structField_11
	local vectorNext_12 = offset + 12
	if vectorNext_12 > payloadLength then
		error(ERR_BOUNDS)
	end
	local vectorX_13 = readf32(payload, offset)
	local vectorY_14 = readf32(payload, offset + 4)
	local vectorZ_15 = readf32(payload, offset + 8)
	structField_11 = Vector3.new(vectorX_13, vectorY_14, vectorZ_15)
	offset = vectorNext_12
	structValue_1["velocity"] = structField_11
	local structField_16
	local stringLen_17
	stringLen_17, offset = ReadVarUInt(payload, payloadLength, offset)
	if stringLen_17 > 4294967295 then
		error(ERR_SCHEMA)
	end
	local stringNext_18 = offset + stringLen_17
	if stringNext_18 > payloadLength then
		error(ERR_BOUNDS)
	end
	structField_16 = readstring(payload, offset, stringLen_17)
	offset = stringNext_18
	structValue_1["name"] = structField_16
	local structField_19
	local boolNext_20 = offset + 1
	if boolNext_20 > payloadLength then
		error(ERR_BOUNDS)
	end
	local rawBool_21 = readu8(payload, offset)
	offset = boolNext_20
	structField_19 = rawBool_21 == 1
	structValue_1["isRunning"] = structField_19
	local structField_22
	local fieldNext_23 = offset + 1
	if fieldNext_23 > payloadLength then
		error(ERR_BOUNDS)
	end
	structField_22 = readu8(payload, offset) :: u8
	offset = fieldNext_23
	structValue_1["animation"] = structField_22
	local structField_24
	local fieldNext_25 = offset + 1
	if fieldNext_25 > payloadLength then
		error(ERR_BOUNDS)
	end
	structField_24 = readu8(payload, offset) :: u8
	offset = fieldNext_25
	structValue_1["team"] = structField_24
	decoded_data = structValue_1
	return decoded_data, offset
end

local Handler_Net_Mixed_reliable_5: ((
	player: Player,
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

function Net_Mixed_reliable_5.On(callback: Net_Mixed_reliable_ServerEventCallback): Connection
	if type(callback) ~= "function" then
		error(ERR_TYPE)
	end
	HandlerToken_Net_Mixed_reliable_5 += 1
	local token = HandlerToken_Net_Mixed_reliable_5
	Handler_Net_Mixed_reliable_5 = callback
	return CreateConnection(function()
		if HandlerToken_Net_Mixed_reliable_5 == token then
			HandlerToken_Net_Mixed_reliable_5 += 1
			Handler_Net_Mixed_reliable_5 = nil
		end
	end)
end

RELIABLE_DISPATCH[5] = function(player, payload, payloadLength, offset)
	local decoded_data, nextOffset = Decode_Net_Mixed_reliable_5(payload, payloadLength, offset)
	local callback = Handler_Net_Mixed_reliable_5
	if callback == nil then
		return nextOffset
	end
	callback(player, decoded_data)
	return nextOffset
end

local Net_SingleValue_reliable_6: Net_SingleValue_reliable_ServerApi = {} :: Net_SingleValue_reliable_ServerApi
local MESSAGE_ID_Net_SingleValue_reliable_6 = 6

local function Decode_Net_SingleValue_reliable_6(payload, payloadLength, offset)
	local decoded_data
	local fixedBlock_1 = offset
	local fixedBlockNext_2 = fixedBlock_1 + 1
	if fixedBlockNext_2 > payloadLength then
		error(ERR_BOUNDS)
	end
	offset = fixedBlockNext_2
	decoded_data = readu8(payload, fixedBlock_1) :: u8
	return decoded_data, offset
end

local Handler_Net_SingleValue_reliable_6: ((player: Player, data: u8) -> ())? = nil
local HandlerToken_Net_SingleValue_reliable_6 = 0

function Net_SingleValue_reliable_6.On(callback: Net_SingleValue_reliable_ServerEventCallback): Connection
	if type(callback) ~= "function" then
		error(ERR_TYPE)
	end
	HandlerToken_Net_SingleValue_reliable_6 += 1
	local token = HandlerToken_Net_SingleValue_reliable_6
	Handler_Net_SingleValue_reliable_6 = callback
	return CreateConnection(function()
		if HandlerToken_Net_SingleValue_reliable_6 == token then
			HandlerToken_Net_SingleValue_reliable_6 += 1
			Handler_Net_SingleValue_reliable_6 = nil
		end
	end)
end

RELIABLE_DISPATCH[6] = function(player, payload, payloadLength, offset)
	local decoded_data, nextOffset = Decode_Net_SingleValue_reliable_6(payload, payloadLength, offset)
	local callback = Handler_Net_SingleValue_reliable_6
	if callback == nil then
		return nextOffset
	end
	callback(player, decoded_data)
	return nextOffset
end

local function StepReplication()
	FlushReliable()
	FlushUnreliable()
end

RunService.Heartbeat:Connect(StepReplication)

Reliable.OnServerEvent:Connect(function(player, payload)
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
			local nextOffset = dispatch(player, payload, payloadLength, offset)
			offset = nextOffset
		end
	end
end)

Unreliable.OnServerEvent:Connect(function(player, payload)
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
			local nextOffset = dispatch(player, payload, payloadLength, offset)
			offset = nextOffset
		end
	end
end)

FunctionRemote.OnServerInvoke = function(player, payload, ...)
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
	return dispatch(player, payload, payloadLength)
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
