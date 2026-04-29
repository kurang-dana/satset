-- This file is part of the Satset networking library and is licensed under MIT License; see LICENSE.txt for details
-- Packet — the public API for stateless, fire-and-forget networking.

local Batcher = require(script.Parent.Parent.Core.Batcher)
local SchemaCompiler = require(script.Parent.Parent.Serialization.SchemaCompiler)
local Serializer = require(script.Parent.Parent.Serialization.Serializer)
local Types = require(script.Parent.Parent.Types)

local RunService = game:GetService("RunService")

-- [ Constants ]

local IS_SERVER = RunService:IsServer()

-- [ Types ]

export type PacketConfig = {
	name: string,
	schema: { [string]: Types.Type<any> },
	reliable: boolean?,
}

type PacketDef = {
	id: number,
	name: string,
	compiled: SchemaCompiler.CompiledSchema,
	reliable: boolean,
	listeners: { (data: { [string]: any }, sender: Player?) -> () },
}

export type Packet = {
	fireServer: (self: Packet, data: { [string]: any }) -> (),
	fireClient: (self: Packet, player: Player, data: { [string]: any }) -> (),
	fireAllClients: (self: Packet, data: { [string]: any }) -> (),
	listen: (self: Packet, callback: (data: { [string]: any }, sender: Player?) -> ()) -> (),
}

-- [ State ]

local packetRegistry: { [number]: PacketDef } = {}
local packetsByName: { [string]: PacketDef } = {}
local nextPacketId = 1

local Packet = {}

-- [ Public API ]

--[[
	Defines a new packet type with a fixed schema.
	
	Packets are stateless: you fire them and forget about them. They are 
	automatically batched into a single remote call per frame to save 
	bandwidth and CPU.
]]
function Packet.definePacket(config: PacketConfig): Packet
	local id = nextPacketId
	nextPacketId += 1

	local compiled = SchemaCompiler.compile(config.schema)

	local def: PacketDef = {
		id = id,
		name = config.name,
		compiled = compiled,
		reliable = if config.reliable ~= nil then config.reliable else true,
		listeners = {},
	}

	packetRegistry[id] = def
	packetsByName[config.name] = def

	local self = {}

	function self:fireServer(data: { [string]: any })
		assert(not IS_SERVER, "[Satset] fireServer can only be called from the client")
		local payload = Serializer.encode(compiled, data)
		Batcher.enqueueForServer(id, payload, def.reliable)
	end

	function self:fireClient(player: Player, data: { [string]: any })
		assert(IS_SERVER, "[Satset] fireClient can only be called from the server")
		local payload = Serializer.encode(compiled, data)
		Batcher.enqueueForPlayer(player, id, payload, def.reliable)
	end

	function self:fireAllClients(data: { [string]: any })
		assert(IS_SERVER, "[Satset] fireAllClients can only be called from the server")
		local payload = Serializer.encode(compiled, data)
		Batcher.enqueueForAllPlayers(id, payload)
	end

	function self:listen(callback: (data: { [string]: any }, sender: Player?) -> ())
		table.insert(def.listeners, callback)
	end

	return self :: any
end

-- [ Internal API ]

--[[
	Decodes and dispatches a single packet to its registered listeners.
]]
function Packet._dispatchSingle(packetId: number, payload: buffer, sender: Player?)
	local def = packetRegistry[packetId]
	if not def then
		return
	end

	local data = Serializer.decode(def.compiled, payload)
	if not data then
		return
	end

	for _, listener in def.listeners do
		listener(data, sender)
	end
end

--[[
	Processes a reliable batch of packets.
]]
function Packet._dispatch(batchPayload: buffer, sender: Player?)
	local entries = Batcher.decodeBatch(batchPayload)

	for _, entry in entries do
		Packet._dispatchSingle(entry.id, entry.payload, sender)
	end
end

--[[
	Processes an unreliable batch, including staleness checks.
]]
function Packet._dispatchUnreliable(batchPayload: buffer, sender: Player?)
	local entries = Batcher.decodeUnreliableBatch(batchPayload, sender)
	if not entries then
		return
	end

	for _, entry in entries do
		Packet._dispatchSingle(entry.id, entry.payload, sender)
	end
end

return Packet
