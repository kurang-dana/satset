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
}

local SchemaCompiler = {}

-- [ Public API ]

--[[
	Compiles a user-defined schema into an optimized internal format.
	
	Luau does not guarantee table iteration order, so we sort the fields 
	alphabetically. This ensures that the server and client always agree 
	on where data is located in the buffer.
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

	return {
		fields = fields,
		fixedSize = if isFixedSize then totalFixed else nil,
		fieldCount = #fields,
		fieldsByName = fieldsByName,
	}
end

return SchemaCompiler
