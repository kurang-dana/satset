local Buffer = require(script.Parent.lib).Buffer.Schema

return Buffer.struct({
	id = Buffer.u8,
	health = Buffer.u8,
	position = Buffer.vector3,
	velocity = Buffer.vector3,
	name = Buffer.string,
	isRunning = Buffer.boolean,
	animation = Buffer.u8,
	team = Buffer.u8,
})
