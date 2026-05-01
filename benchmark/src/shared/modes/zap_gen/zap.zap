opt server_output = "server.luau"
opt client_output = "client.luau"

type Entity = struct {
    id: u8,
    x: u8,
    y: u8,
    z: u8,
    orientation: u8,
    animation: u8
}

type MixedStruct = struct {
    id: u8,
    health: u8,
    position: Vector3,
    velocity: Vector3,
    name: string,
    isRunning: boolean,
    animation: u8,
    team: u8
}

event Booleans = {
    from: Client,
    type: Reliable,
    call: SingleSync,
    data: boolean[]
}

event Entities = {
    from: Client,
    type: Reliable,
    call: SingleSync,
    data: Entity[]
}

event Vectors = {
    from: Client,
    type: Reliable,
    call: SingleSync,
    data: Vector3[]
}

event Strings = {
    from: Client,
    type: Reliable,
    call: SingleSync,
    data: string[]
}

event Mixed = {
    from: Client,
    type: Reliable,
    call: SingleSync,
    data: MixedStruct
}

event SingleValue = {
    from: Client,
    type: Reliable,
    call: SingleSync,
    data: u8
}
