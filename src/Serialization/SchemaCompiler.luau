--!optimize 2
-- This file is part of the Satset networking library and is licensed under MIT License; see LICENSE.txt for details
-- SchemaCompiler — transforms a schema dictionary into a deterministic ordered structure.

local Types = require(script.Parent.Parent.Types)

-- [ Types ]

export type FieldDef = {
	name: string,
	type: Types.Type<any>,
	offset: number, -- Byte offset in the state buffer (only for fixed-size schemas)
	index: number, -- 0-based field index used for bitmask operations
}

export type CompiledSchema = {
	fields: { FieldDef },
	fixedSize: number?, -- nil if any field is variable-sized
	fieldCount: number,
	fieldsByName: { [string]: FieldDef }, -- O(1) lookup for runtime access
	encoder: ((b: buffer, offset: number, data: { [string]: any }) -> ())?, -- compiled fast-path encoder
	decoder: ((b: buffer, offset: number) -> { [string]: any })?, -- compiled fast-path decoder
}

local SchemaCompiler = {}

-- [ Private ]

--[[
	Generates a specialized encoder closure for fixed-size schemas.
	
	Instead of looping over fields at runtime, we capture each field's 
	name, write function, and byte offset as closure upvalues. Luau 
	optimizes immutable upvalue captures as by-value, making this 
	equivalent to hand-written code.
]]
local function buildFixedEncoder(fields: { FieldDef }): (b: buffer, offset: number, data: { [string]: any }) -> ()
	local count = #fields

	-- 1 field — most common for simple packets (SingleValue, Booleans, Vectors, etc.)
	if count == 1 then
		local f1 = fields[1]
		local name1, write1, off1 = f1.name, f1.type.write, f1.offset
		return function(b: buffer, offset: number, data: { [string]: any })
			write1(b, offset + off1, data[name1])
		end
	elseif count == 2 then
		local f1, f2 = fields[1], fields[2]
		local name1, write1, off1 = f1.name, f1.type.write, f1.offset
		local name2, write2, off2 = f2.name, f2.type.write, f2.offset
		return function(b: buffer, offset: number, data: { [string]: any })
			write1(b, offset + off1, data[name1])
			write2(b, offset + off2, data[name2])
		end
	elseif count == 3 then
		local f1, f2, f3 = fields[1], fields[2], fields[3]
		local name1, write1, off1 = f1.name, f1.type.write, f1.offset
		local name2, write2, off2 = f2.name, f2.type.write, f2.offset
		local name3, write3, off3 = f3.name, f3.type.write, f3.offset
		return function(b: buffer, offset: number, data: { [string]: any })
			write1(b, offset + off1, data[name1])
			write2(b, offset + off2, data[name2])
			write3(b, offset + off3, data[name3])
		end
	elseif count == 4 then
		local f1, f2, f3, f4 = fields[1], fields[2], fields[3], fields[4]
		local name1, write1, off1 = f1.name, f1.type.write, f1.offset
		local name2, write2, off2 = f2.name, f2.type.write, f2.offset
		local name3, write3, off3 = f3.name, f3.type.write, f3.offset
		local name4, write4, off4 = f4.name, f4.type.write, f4.offset
		return function(b: buffer, offset: number, data: { [string]: any })
			write1(b, offset + off1, data[name1])
			write2(b, offset + off2, data[name2])
			write3(b, offset + off3, data[name3])
			write4(b, offset + off4, data[name4])
		end
	end

	-- 5+ fields: use a pre-built array of captured closures with offsets.
	-- Still faster than the generic path because we avoid getSize() calls
	-- and the offset is pre-computed.
	local names = table.create(count)
	local writes = table.create(count)
	local offsets = table.create(count)
	for i, field in fields do
		names[i] = field.name
		writes[i] = field.type.write
		offsets[i] = field.offset
	end

	return function(b: buffer, offset: number, data: { [string]: any })
		for i = 1, count do
			writes[i](b, offset + offsets[i], data[names[i]])
		end
	end
end

--[[
	Generates a specialized decoder closure for fixed-size schemas.
]]
local function buildFixedDecoder(fields: { FieldDef }): (b: buffer, offset: number) -> { [string]: any }
	local count = #fields

	-- 1 field
	if count == 1 then
		local f1 = fields[1]
		local name1, read1, off1 = f1.name, f1.type.read, f1.offset
		return function(b: buffer, offset: number): { [string]: any }
			return { [name1] = read1(b, offset + off1) }
		end
	elseif count == 2 then
		local f1, f2 = fields[1], fields[2]
		local name1, read1, off1 = f1.name, f1.type.read, f1.offset
		local name2, read2, off2 = f2.name, f2.type.read, f2.offset
		return function(b: buffer, offset: number): { [string]: any }
			return {
				[name1] = read1(b, offset + off1),
				[name2] = read2(b, offset + off2),
			}
		end
	elseif count == 3 then
		local f1, f2, f3 = fields[1], fields[2], fields[3]
		local name1, read1, off1 = f1.name, f1.type.read, f1.offset
		local name2, read2, off2 = f2.name, f2.type.read, f2.offset
		local name3, read3, off3 = f3.name, f3.type.read, f3.offset
		return function(b: buffer, offset: number): { [string]: any }
			return {
				[name1] = read1(b, offset + off1),
				[name2] = read2(b, offset + off2),
				[name3] = read3(b, offset + off3),
			}
		end
	end

	-- 4+ fields: pre-built arrays
	local names = table.create(count)
	local reads = table.create(count)
	local offsets = table.create(count)
	for i, field in fields do
		names[i] = field.name
		reads[i] = field.type.read
		offsets[i] = field.offset
	end

	return function(b: buffer, offset: number): { [string]: any }
		local data = {}
		for i = 1, count do
			data[names[i]] = reads[i](b, offset + offsets[i])
		end
		return data
	end
end

-- [ Public API ]

--[[
	Compiles a user-defined schema into an optimized internal format.
	
	Luau does not guarantee table iteration order, so we sort the fields 
	alphabetically. This ensures that the server and client always agree 
	on where data is located in the buffer.
	
	For fixed-size schemas, we also generate specialized encoder/decoder 
	closures that eliminate the per-fire field loop overhead.
]]
function SchemaCompiler.compile(schema: { [string]: Types.Type<any> }): CompiledSchema
	local fields: { FieldDef } = {}
	local isFixedSize = true
	local totalFixed = 0

	-- We collect fields into an array so we can sort them.
	for name, typeInfo in schema do
		table.insert(fields, {
			name = name,
			type = typeInfo,
			offset = 0,
			index = 0,
		})
	end

	-- Alphabetical sorting is our "standard" for deterministic ordering.
	table.sort(fields, function(a, b)
		return a.name < b.name
	end)

	local fieldsByName: { [string]: FieldDef } = {}
	local currentOffset = 0

	for i, field in fields do
		field.index = i - 1

		if not field.type.isFixed then
			isFixedSize = false
		else
			field.offset = currentOffset
			currentOffset += field.type.size
			totalFixed += field.type.size
		end

		fieldsByName[field.name] = field
	end

	-- Generate compiled encoder/decoder for fixed-size schemas.
	local encoder: ((b: buffer, offset: number, data: { [string]: any }) -> ())? = nil
	local decoder: ((b: buffer, offset: number) -> { [string]: any })? = nil

	if isFixedSize then
		encoder = buildFixedEncoder(fields)
		decoder = buildFixedDecoder(fields)
	end

	return {
		fields = fields,
		fixedSize = if isFixedSize then totalFixed else nil,
		fieldCount = #fields,
		fieldsByName = fieldsByName,
		encoder = encoder,
		decoder = decoder,
	}
end

return SchemaCompiler
