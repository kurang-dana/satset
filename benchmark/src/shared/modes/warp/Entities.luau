local Buffer = require(script.Parent.lib).Buffer.Schema

return Buffer.array(Buffer.struct({
	id = Buffer.u8,
	x = Buffer.u8,
	y = Buffer.u8,
	z = Buffer.u8,
	orientation = Buffer.u8,
	animation = Buffer.u8,
}))
