-- This file is part of the Satset networking library and is licensed under MIT License; see LICENSE.txt for details
-- Channel — stateful, delta-synced networking with dirty bitmask tracking.

local RunService = game:GetService("RunService")

local SchemaCompiler = require(script.Parent.Parent.Serialization.SchemaCompiler)

-- [ Constants ]

local IS_SERVER = RunService:IsServer()
local FULL_MASK: number = 0xFFFFFFFF

-- [ Types ]

export type ChannelConfig = {
	name: string,
	schema: { [string]: any },
	unreliable: boolean?, -- Use UnreliableRemoteEvent (default true)
	resyncInterval: number?, -- Seconds between full keyframes (default 5)
}

-- Entity: server-side state container with dirty tracking.
export type Entity = {
	set: (self: Entity, fieldName: string, value: any) -> (),
	get: (self: Entity, fieldName: string) -> any,
	getAll: (self: Entity) -> { [string]: any },
	destroy: (self: Entity) -> (),
}

type EntityData = {
	id: number,
	stateBuffer: buffer,
	dirtyMask: number,
	alive: boolean,
}

type ChannelDef = {
	id: number,
	name: string,
	compiled: SchemaCompiler.CompiledSchema,
	unreliable: boolean,
	resyncInterval: number,
	entities: { [number]: EntityData },
	lastResync: number,
	subscribers: { (entityId: number, state: { [string]: any }) -> () },
	clientState: { [number]: buffer },
}

-- [ State ]

local channelRegistry: { [number]: ChannelDef } = {}
local channelsByName: { [string]: ChannelDef } = {}
local nextChannelId = 1

local Channel = {}

-- [ Public API ]

--[[
	Defines a new stateful channel.
	
	Channels are for data that changes frequently and needs to be 
	synchronized (like player health, positions, or vehicle states). 
	They are much more bandwidth-efficient than packets because they only 
	send what has changed.
]]
function Channel.defineChannel(config: ChannelConfig): any
	local compiled = SchemaCompiler.compile(config.schema)

	-- Channels rely on pre-computed offsets, so they require fixed-size types.
	assert(compiled.fixedSize ~= nil, "[Satset] Channel '" .. config.name .. "' requires a fixed-size schema.")

	-- We use a 32-bit bitmask for dirty tracking, which limits us to 32 fields.
	assert(compiled.fieldCount <= 32, "[Satset] Channel '" .. config.name .. "' exceeds the 32-field limit.")

	local id = nextChannelId
	nextChannelId += 1

	local def: ChannelDef = {
		id = id,
		name = config.name,
		compiled = compiled,
		unreliable = if config.unreliable ~= nil then config.unreliable else true,
		resyncInterval = config.resyncInterval or 5,
		entities = {},
		lastResync = 0,
		subscribers = {},
		clientState = {},
	}

	channelRegistry[id] = def
	channelsByName[config.name] = def

	local self = {}

	if IS_SERVER then
		--[[
			Creates a new entity instance for this channel.
		]]
		function self:create(entityId: number, initialData: { [string]: any }?): Entity
			local stateSize = compiled.fixedSize :: number
			local stateBuffer = buffer.create(stateSize)

			local entityData: EntityData = {
				id = entityId,
				stateBuffer = stateBuffer,
				dirtyMask = FULL_MASK, -- Start with a full mask to force an initial keyframe.
				alive = true,
			}

			if initialData then
				for fieldName, value in initialData do
					local fieldDef = compiled.fieldsByName[fieldName]
					if fieldDef then
						fieldDef.type.write(stateBuffer, fieldDef.offset, value)
					end
				end
			end

			def.entities[entityId] = entityData

			local entity = {}

			function entity:set(fieldName: string, value: any)
				local fieldDef = compiled.fieldsByName[fieldName]
				if not fieldDef then
					return
				end

				-- We write directly into the flat buffer. Zero allocations.
				fieldDef.type.write(stateBuffer, fieldDef.offset, value)

				-- Mark the field as dirty so it gets included in the next delta.
				entityData.dirtyMask = bit32.bor(entityData.dirtyMask, bit32.lshift(1, fieldDef.index))
			end

			function entity:get(fieldName: string): any
				local fieldDef = compiled.fieldsByName[fieldName]
				if not fieldDef then
					return nil
				end
				return fieldDef.type.read(stateBuffer, fieldDef.offset)
			end

			function entity:getAll(): { [string]: any }
				local result = {}
				for _, field in compiled.fields do
					result[field.name] = field.type.read(stateBuffer, field.offset)
				end
				return result
			end

			function entity:destroy()
				entityData.alive = false
				def.entities[entityId] = nil
			end

			return entity :: any
		end
	else
		--[[
			Registers a listener for state changes on this channel.
		]]
		function self:subscribe(callback: (entityId: number, state: { [string]: any }) -> ())
			table.insert(def.subscribers, callback)
		end
	end

	return self :: any
end

-- [ Internal API ]

--[[
	Encodes only the changed fields for an entity.
]]
local function encodeDelta(def: ChannelDef, entityData: EntityData): buffer?
	local mask = entityData.dirtyMask
	if mask == 0 then
		return nil
	end

	local payloadSize = 0
	for _, field in def.compiled.fields do
		if bit32.band(mask, bit32.lshift(1, field.index)) ~= 0 then
			payloadSize += field.type.size
		end
	end

	local headerSize = 1 + 4 + 4
	local b = buffer.create(headerSize + payloadSize)

	buffer.writeu8(b, 0, def.id)
	buffer.writeu32(b, 1, entityData.id)
	buffer.writeu32(b, 5, mask)

	local cursor = headerSize
	for _, field in def.compiled.fields do
		if bit32.band(mask, bit32.lshift(1, field.index)) ~= 0 then
			buffer.copy(b, cursor, entityData.stateBuffer, field.offset, field.type.size)
			cursor += field.type.size
		end
	end

	entityData.dirtyMask = 0
	return b
end

--[[
	Encodes the entire state of an entity. 
	
	Used for initial synchronization and periodic resyncs to prevent drift.
]]
local function encodeKeyframe(def: ChannelDef, entityData: EntityData): buffer
	local stateSize = def.compiled.fixedSize :: number
	local headerSize = 1 + 4 + 4
	local b = buffer.create(headerSize + stateSize)

	buffer.writeu8(b, 0, def.id)
	buffer.writeu32(b, 1, entityData.id)
	buffer.writeu32(b, 5, FULL_MASK)

	buffer.copy(b, headerSize, entityData.stateBuffer, 0, stateSize)
	return b
end

--[[
	Processes incoming state updates from the server.
]]
function Channel._applyUpdate(b: buffer)
	local bufLen = buffer.len(b)
	if bufLen < 9 then
		return
	end

	local channelId = buffer.readu8(b, 0)
	local entityId = buffer.readu32(b, 1)
	local mask = buffer.readu32(b, 5)

	local def = channelRegistry[channelId]
	if not def then
		return
	end

	local stateSize = def.compiled.fixedSize :: number
	if not def.clientState[entityId] then
		def.clientState[entityId] = buffer.create(stateSize)
	end
	local clientBuf = def.clientState[entityId]

	local cursor = 9
	if mask == FULL_MASK then
		if cursor + stateSize <= bufLen then
			buffer.copy(clientBuf, 0, b, cursor, stateSize)
		end
	else
		for _, field in def.compiled.fields do
			if bit32.band(mask, bit32.lshift(1, field.index)) ~= 0 then
				if cursor + field.type.size <= bufLen then
					buffer.copy(clientBuf, field.offset, b, cursor, field.type.size)
					cursor += field.type.size
				end
			end
		end
	end

	if #def.subscribers > 0 then
		local state = {}
		for _, field in def.compiled.fields do
			state[field.name] = field.type.read(clientBuf, field.offset)
		end
		for _, callback in def.subscribers do
			xpcall(callback, function(err)
				warn(`[Satset] Channel '{def.name}' subscriber error: {err}`)
			end, entityId, state)
		end
	end
end

--[[
	Collects all pending updates for all channels. 
	
	This runs every frame on the server to push out deltas.
]]
function Channel._flush(): { buffer }
	if not IS_SERVER then
		return {}
	end

	local results: { buffer } = {}
	local now = os.clock()

	for _, def in channelRegistry do
		local isResyncFrame = (now - def.lastResync) >= def.resyncInterval

		for _, entityData in def.entities do
			if not entityData.alive then
				continue
			end

			if isResyncFrame then
				table.insert(results, encodeKeyframe(def, entityData))
				entityData.dirtyMask = 0
			else
				local delta = encodeDelta(def, entityData)
				if delta then
					table.insert(results, delta)
				end
			end
		end

		if isResyncFrame then
			def.lastResync = now
		end
	end

	return results
end

function Channel._getRegistry(): { [number]: ChannelDef }
	return channelRegistry
end

return Channel
