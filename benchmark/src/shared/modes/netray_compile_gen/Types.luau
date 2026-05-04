--!strict
--!native
--!optimize 2
-- Name: Types
-- Purpose: Generated Luau types for NetRay schema
-- Generated-by: NetRay-Compiler

export type TypeBranding = "Off" | "On"
export type ActiveTypeBranding = "Off"
export type Brand<T, B> = T & { __brand: B }
export type u8 = number
export type i8 = number
export type u16 = number
export type i16 = number
export type u32 = number
export type i32 = number
export type f16 = number
export type f32 = number
export type f64 = number

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type EventSender1<T> = {
	Fire: (T) -> boolean,
}
export type EventReceiver1<T> = {
	On: ((T) -> ()) -> Connection,
}
export type EventDuplex1<T> = EventSender1<T> & EventReceiver1<T>

export type NetStats = {
	GetReliableDropped: () -> number,
	GetUnreliableDropped: () -> number,
	GetReliableQueueSize: () -> number,
	GetUnreliableQueueSize: () -> number,
}

export type Net_Booleans_reliable_Args = () -> { boolean }
export type Net_Booleans_reliable_TupleHandler = ({ boolean }) -> ()
export type Net_Booleans_reliable_ClientEventCallback = (data: { boolean }) -> ()
export type Net_Booleans_reliable_ServerEventCallback = (player: Player, data: { boolean }) -> ()
export type Net_Booleans_reliable_ClientApi = {
	Fire: ({ boolean }) -> boolean,
}
export type Net_Booleans_reliable_ServerApi = {
	On: (Net_Booleans_reliable_ServerEventCallback) -> Connection,
}

export type Net_Entities_reliable_Args = () -> { { id: u8, x: u8, y: u8, z: u8, orientation: u8, animation: u8 } }
export type Net_Entities_reliable_TupleHandler = (
	{ { id: u8, x: u8, y: u8, z: u8, orientation: u8, animation: u8 } }
) -> ()
export type Net_Entities_reliable_ClientEventCallback = (
	data: { { id: u8, x: u8, y: u8, z: u8, orientation: u8, animation: u8 } }
) -> ()
export type Net_Entities_reliable_ServerEventCallback = (
	player: Player,
	data: { { id: u8, x: u8, y: u8, z: u8, orientation: u8, animation: u8 } }
) -> ()
export type Net_Entities_reliable_ClientApi = {
	Fire: ({ { id: u8, x: u8, y: u8, z: u8, orientation: u8, animation: u8 } }) -> boolean,
}
export type Net_Entities_reliable_ServerApi = {
	On: (Net_Entities_reliable_ServerEventCallback) -> Connection,
}

export type Net_Vectors_reliable_Args = () -> { Vector3 }
export type Net_Vectors_reliable_TupleHandler = ({ Vector3 }) -> ()
export type Net_Vectors_reliable_ClientEventCallback = (data: { Vector3 }) -> ()
export type Net_Vectors_reliable_ServerEventCallback = (player: Player, data: { Vector3 }) -> ()
export type Net_Vectors_reliable_ClientApi = {
	Fire: ({ Vector3 }) -> boolean,
}
export type Net_Vectors_reliable_ServerApi = {
	On: (Net_Vectors_reliable_ServerEventCallback) -> Connection,
}

export type Net_Strings_reliable_Args = () -> { string }
export type Net_Strings_reliable_TupleHandler = ({ string }) -> ()
export type Net_Strings_reliable_ClientEventCallback = (data: { string }) -> ()
export type Net_Strings_reliable_ServerEventCallback = (player: Player, data: { string }) -> ()
export type Net_Strings_reliable_ClientApi = {
	Fire: ({ string }) -> boolean,
}
export type Net_Strings_reliable_ServerApi = {
	On: (Net_Strings_reliable_ServerEventCallback) -> Connection,
}

export type Net_Mixed_reliable_Args = (
) -> {
	id: u8,
	health: u8,
	position: Vector3,
	velocity: Vector3,
	name: string,
	isRunning: boolean,
	animation: u8,
	team: u8,
}
export type Net_Mixed_reliable_TupleHandler = (
	{
		id: u8,
		health: u8,
		position: Vector3,
		velocity: Vector3,
		name: string,
		isRunning: boolean,
		animation: u8,
		team: u8,
	}
) -> ()
export type Net_Mixed_reliable_ClientEventCallback = (
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
) -> ()
export type Net_Mixed_reliable_ServerEventCallback = (
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
) -> ()
export type Net_Mixed_reliable_ClientApi = {
	Fire: (
		{
			id: u8,
			health: u8,
			position: Vector3,
			velocity: Vector3,
			name: string,
			isRunning: boolean,
			animation: u8,
			team: u8,
		}
	) -> boolean,
}
export type Net_Mixed_reliable_ServerApi = {
	On: (Net_Mixed_reliable_ServerEventCallback) -> Connection,
}

export type Net_SingleValue_reliable_Args = () -> u8
export type Net_SingleValue_reliable_TupleHandler = (u8) -> ()
export type Net_SingleValue_reliable_ClientEventCallback = (data: u8) -> ()
export type Net_SingleValue_reliable_ServerEventCallback = (player: Player, data: u8) -> ()
export type Net_SingleValue_reliable_ClientApi = {
	Fire: (u8) -> boolean,
}
export type Net_SingleValue_reliable_ServerApi = {
	On: (Net_SingleValue_reliable_ServerEventCallback) -> Connection,
}

export type NetClient = {
	Booleans: Net_Booleans_reliable_ClientApi,
	Entities: Net_Entities_reliable_ClientApi,
	Vectors: Net_Vectors_reliable_ClientApi,
	Strings: Net_Strings_reliable_ClientApi,
	Mixed: Net_Mixed_reliable_ClientApi,
	SingleValue: Net_SingleValue_reliable_ClientApi,
	StepReplication: () -> (),
	Stats: NetStats,
}

export type NetServer = {
	Booleans: Net_Booleans_reliable_ServerApi,
	Entities: Net_Entities_reliable_ServerApi,
	Vectors: Net_Vectors_reliable_ServerApi,
	Strings: Net_Strings_reliable_ServerApi,
	Mixed: Net_Mixed_reliable_ServerApi,
	SingleValue: Net_SingleValue_reliable_ServerApi,
	StepReplication: () -> (),
	Stats: NetStats,
}

export type Net = NetClient | NetServer

local Types = {
	u8 = (0 :: any) :: u8,
	i8 = (0 :: any) :: i8,
	u16 = (0 :: any) :: u16,
	i16 = (0 :: any) :: i16,
	u32 = (0 :: any) :: u32,
	i32 = (0 :: any) :: i32,
	f16 = (0 :: any) :: f16,
	f32 = (0 :: any) :: f32,
	f64 = (0 :: any) :: f64,
	Connection = ({ Connected = true, Disconnect = function(_self) end } :: any) :: Connection,
	NetStats = ({
		GetReliableDropped = function()
			return 0
		end,
		GetUnreliableDropped = function()
			return 0
		end,
		GetReliableQueueSize = function()
			return 0
		end,
		GetUnreliableQueueSize = function()
			return 0
		end,
	} :: any) :: NetStats,
	Net_Booleans_reliable_ClientEventCallback = (
			(function(...) end) :: any
		) :: Net_Booleans_reliable_ClientEventCallback,
	Net_Booleans_reliable_ServerEventCallback = (
			(function(...) end) :: any
		) :: Net_Booleans_reliable_ServerEventCallback,
	Net_Booleans_reliable_ClientApi = ({} :: any) :: Net_Booleans_reliable_ClientApi,
	Net_Booleans_reliable_ServerApi = ({} :: any) :: Net_Booleans_reliable_ServerApi,
	Net_Entities_reliable_ClientEventCallback = (
			(function(...) end) :: any
		) :: Net_Entities_reliable_ClientEventCallback,
	Net_Entities_reliable_ServerEventCallback = (
			(function(...) end) :: any
		) :: Net_Entities_reliable_ServerEventCallback,
	Net_Entities_reliable_ClientApi = ({} :: any) :: Net_Entities_reliable_ClientApi,
	Net_Entities_reliable_ServerApi = ({} :: any) :: Net_Entities_reliable_ServerApi,
	Net_Vectors_reliable_ClientEventCallback = ((function(...) end) :: any) :: Net_Vectors_reliable_ClientEventCallback,
	Net_Vectors_reliable_ServerEventCallback = ((function(...) end) :: any) :: Net_Vectors_reliable_ServerEventCallback,
	Net_Vectors_reliable_ClientApi = ({} :: any) :: Net_Vectors_reliable_ClientApi,
	Net_Vectors_reliable_ServerApi = ({} :: any) :: Net_Vectors_reliable_ServerApi,
	Net_Strings_reliable_ClientEventCallback = ((function(...) end) :: any) :: Net_Strings_reliable_ClientEventCallback,
	Net_Strings_reliable_ServerEventCallback = ((function(...) end) :: any) :: Net_Strings_reliable_ServerEventCallback,
	Net_Strings_reliable_ClientApi = ({} :: any) :: Net_Strings_reliable_ClientApi,
	Net_Strings_reliable_ServerApi = ({} :: any) :: Net_Strings_reliable_ServerApi,
	Net_Mixed_reliable_ClientEventCallback = ((function(...) end) :: any) :: Net_Mixed_reliable_ClientEventCallback,
	Net_Mixed_reliable_ServerEventCallback = ((function(...) end) :: any) :: Net_Mixed_reliable_ServerEventCallback,
	Net_Mixed_reliable_ClientApi = ({} :: any) :: Net_Mixed_reliable_ClientApi,
	Net_Mixed_reliable_ServerApi = ({} :: any) :: Net_Mixed_reliable_ServerApi,
	Net_SingleValue_reliable_ClientEventCallback = (
			(function(...) end) :: any
		) :: Net_SingleValue_reliable_ClientEventCallback,
	Net_SingleValue_reliable_ServerEventCallback = (
			(function(...) end) :: any
		) :: Net_SingleValue_reliable_ServerEventCallback,
	Net_SingleValue_reliable_ClientApi = ({} :: any) :: Net_SingleValue_reliable_ClientApi,
	Net_SingleValue_reliable_ServerApi = ({} :: any) :: Net_SingleValue_reliable_ServerApi,
	NetClient = ({} :: any) :: NetClient,
	NetServer = ({} :: any) :: NetServer,
	Net = ({} :: any) :: Net,
}

return table.freeze(Types)
