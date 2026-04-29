# Development Patterns

Satset follows strict performance and safety constraints. These patterns ensure the library stays efficient under high-throughput conditions.

## Zero-allocation hot path

Allocations during the sync cycle are prohibited. Satset uses native Luau `buffer` operations for all throughput to avoid garbage collection (GC) overhead.

* **The Problem**: Table and string allocations trigger GC pauses. When syncing hundreds of entities, these pauses cause frame drops.
* **The Pattern**: Reuse pre-allocated buffers. Avoid creating tables or strings during encoding and decoding.

## Deterministic byte alignment

Satset doesn't transmit type metadata or field names. Server and client must share an identical understanding of the buffer layout.

* **The Pattern**: `SchemaCompiler` sorts field definitions alphabetically before calculating memory offsets. This guarantees that different environments produce the same binary schema, regardless of how the Luau table is ordered.

## Mandatory input sanitization

Network data is untrusted. All numeric inputs must be validated before they reach the server state.

* **The Problem**: Malformed packets with `NaN` or `Infinity` can corrupt physics and state calculations.
* **The Pattern**: All floating-point types pass through `Sanitizer.sanitizeFloat()`. Values that fail validation are clamped to `0`.

## Bit-density optimization

Choose data types based on bit-density.

* **The Pattern**: Use the smallest applicable type (e.g., `u8` for values 0-255). Use quantized types like `Vector3Quantized` for spatial data when full float precision isn't necessary.

## Explicit delta tracking

State sync is an explicit, bitmask-tracked process, not an automatic "magic" sync.

* **The Pattern**: `Channels` track modified fields using a 32-bit mask. Only dirty fields are sent. Syncing happens during `PostSimulation` to maximize batching efficiency.

## Defensive buffer reads

Every buffer read includes a bounds check.

* **The Pattern**: The `Serializer` verifies buffer length before every read. Out-of-bounds attempts throw errors immediately to prevent undefined behavior.

## Naming conventions

Satset uses a specific naming convention to maintain code clarity across the library:

* **PascalCase**: Used for Modules, Class definitions, and Luau Types (e.g., `SchemaCompiler`, `SatsetConfig`).
* **camelCase**: Used for public API methods, local variables, and object properties (e.g., `definePacket`, `channelId`, `maxTokens`).
* **_camelCase** (Leading underscore): Used for internal/private state or functions that should not be accessed by the public API (e.g., `_guard`, `_applyUpdate`).
* **SCREAMING_SNAKE_CASE**: Used for constants and environment flags (e.g., `IS_SERVER`, `MTU_LIMIT`).
