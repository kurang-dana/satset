# Introduction

**Satset** is a high-performance, buffer-backed hybrid networking library for Roblox. It is designed to be the fastest and most efficient way to synchronize data between the server and clients, combining the best patterns from industry leaders like Blink, Zap, and ByteNet.

## Why Satset?

Roblox's native `RemoteEvent` system is powerful but can be inefficient for high-frequency data (like character positions or combat state). Satset solves this by:

- **Buffer-backed serialization**: Uses Luau `buffer` for zero-allocation, tightly packed data.
- **Automatic batching**: Combines multiple packet fires into a single remote call per frame.
- **Stateful Channels**: Efficiently synchronizes state changes using bitmask-based delta compression.
- **Security-first**: Built-in rate limiting (Guard) and data sanitization.
- **Developer Experience**: Simple, type-safe API that doesn't require a complex build step for most use cases.

## "Sat set, sampai."

The name comes from Indonesian slang meaning "quick and efficient." Our goal is to get your data from A to B as fast and reliably as possible, with no overhead.
