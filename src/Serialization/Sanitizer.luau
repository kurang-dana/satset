--!strict
-- This file is part of the Satset networking library and is licensed under MIT License; see LICENSE.txt for details
-- Sanitizer — server-side input validation layer.

local Sanitizer = {}

-- [ Public API ]

--[[
	Validates that a floating point value is finite. 
	
	This prevents NaN or Infinity from entering your game state, 
	which can cause subtle bugs or even crashes in physics.
]]
function Sanitizer.sanitizeFloat(value: number): number
	-- NaN is the only value in Luau that does not equal itself.
	if value ~= value then
		return 0
	end

	-- We also strip out infinity since it's rarely what you actually want.
	if value == math.huge or value == -math.huge then
		return 0
	end

	return value
end

--[[
	Ensures that a buffer read will not exceed the buffer's length.
]]
function Sanitizer.checkBounds(b: buffer, cursor: number, readSize: number): boolean
	return cursor >= 0 and (cursor + readSize) <= buffer.len(b)
end

--[[
	Validates a decoded data table against a list of expected field types.
	
	This is a higher-level check that ensures strings are actually strings 
	 and numbers are finite. It mutates the table in place to keep things fast.
]]
function Sanitizer.sanitizeDecoded(
	data: { [string]: any },
	fieldTypes: { { name: string, luauType: string } }
): { [string]: any }
	for _, field in fieldTypes do
		local value = data[field.name]

		if value == nil then
			continue
		end

		if field.luauType == "number" then
			if type(value) ~= "number" then
				data[field.name] = 0
			else
				data[field.name] = Sanitizer.sanitizeFloat(value)
			end
		elseif field.luauType == "string" then
			if type(value) ~= "string" then
				data[field.name] = ""
			end
		elseif field.luauType == "boolean" then
			if type(value) ~= "boolean" then
				data[field.name] = false
			end
		end
	end

	return data
end

return Sanitizer
