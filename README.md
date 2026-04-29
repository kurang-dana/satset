# Satset ![CI](https://github.com/protheeuz/satset/actions/workflows/build.yml/badge.svg)
====

**sat·set** /sat-sèt/ *adjective (slang)* — Indonesian colloquialism for being rapid, efficient, and quick to act.

> *"Sat set, sampai."* — Indonesian for "Swiftly done."

Satset is a high-performance networking library for Roblox. It handles the heavy lifting of buffer serialization and state synchronization so you don't have to. It connects the world of low-level data packing (like ByteNet or Zap) with high-level state sync, offering a unified API for both stateless events and delta-compressed channels.

We built this on a simple philosophy: **if it's on the hot path, it shouldn't allocate.** By using native Luau `buffer` operations and focusing on O(1) operations, Satset stays fast even when you're syncing hundreds of entities every frame.

# Features

### Hybrid Networking Engine

Satset gives you two ways to talk to the network:

- **Packets (Stateless)**: Great for one-off events like "PlayerJumped" or "EffectSpawned." We batch these automatically every frame, so you're not hammering the engine with dozens of RemoteEvent calls.
- **Channels (Stateful)**: This is the core of Satset. You define a schema, and we track the changes for you. When you update a field, we only send the delta (the dirty fields) using a bitmask. It's significantly lighter on bandwidth than sending the whole table every time.

### Built for speed

- **Zero-GC Pipeline**: We do all the work in pre-allocated buffers. No temporary tables are created during encode or decode, which keeps the garbage collector from slowing down your game.
- **FASTCALL Integration**: The codebase is written to take advantage of the Luau VM's fastcalls. We localize all the `buffer` and `math` builtins so you get near-native execution speed.
- **Per-frame Batching**: We don't fire remotes the second you call them. Instead, we wait until `PostSimulation` to flush everything in one go. One remote call per player, per frame. Period.

### Hardened by default

- **Unreliable Transport**: For data that doesn't need to be perfect (like positions), we use `UnreliableRemoteEvent`. We include sequence numbers and stale packet checks so you don't have to deal with out-of-order data.
- **MTU Safety**: If a batch gets too big, we split it up automatically. You don't have to worry about hitting the 900-byte limit and losing data.
- **Leaky Bucket Guard**: We've included a built-in rate limiter for the server. It stops exploiters from flooding your remotes and crashing your instances.

# Usage

### Installation

Add Satset to your `wally.toml`:

```toml
Satset = "mathtech/satset@0.1.0"
```

Or use Rokit:

```bash
rokit add mathtech/satset
```

### Getting Started

You need to initialize Satset on both the server and client:

```luau
local Satset = require(path.to.Satset)

Satset.start({
    guard = {
        maxTokens = 60,
        refillRate = 30
    }
})
```

### Packets (Stateless)

```luau
local Types = Satset.Types

local DamagePacket = Satset.definePacket({
    name = "Damage",
    schema = {
        targetId = Types.u32,
        amount = Types.u16
    },
    reliable = true
})

-- Sending
DamagePacket:fireClient(player, { targetId = 123, amount = 50 })

-- Listening
DamagePacket:listen(function(data, sender)
    print(data.amount, "damage from", sender)
end)
```

### Channels (Stateful)

```luau
local PlayerState = Satset.defineChannel({
    name = "PlayerState",
    schema = {
        health = Types.u16,
        armor = Types.u8,
        position = Types.Vector3Quantized(2048)
    },
    unreliable = true,
    resyncInterval = 5 -- Periodic full sync to prevent drift
})

-- Server: Create and Update
local entity = PlayerState:create(player.UserId)
entity:set("health", 85) -- Only the 2-byte health field is sent.

-- Client: Subscribe
PlayerState:subscribe(function(entityId, state)
    print("Entity", entityId, "is at", state.position)
end)
```

# Dependencies

Satset is pure Luau and doesn't rely on any external libraries. It does require an environment that supports the Luau `buffer` library and `UnreliableRemoteEvent`.

# License

Satset is distributed under the terms of the [MIT License](https://github.com/protheeuz/satset/blob/main/LICENSE).

When Satset is integrated into external projects, we ask that you honor the license agreement and include Satset attribution into the user-facing product documentation.
