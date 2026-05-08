# Changelog

All notable changes to Satset will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioned per [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.3] — 2026-05-08

### Fixed

- **Wally Distribution**: Excluded `README.md` and `CHANGELOG.md` from the installation package to further reduce size and clutter.

## [0.3.2] — 2026-05-08

### Added

- **Nested Structs**: Introduced `Satset.struct()`, allowing developers to wrap schemas into reusable `Type` objects for complex, nested data structures.
- **Readable Type Aliases**: Added long-form aliases (`float64`, `uint8`, `string`, etc.) to improve schema readability and developer experience.

### Fixed

- **Wally Distribution**: Refined the `exclude` list in `wally.toml` to prevent development artifacts (`CHANGELOG`, `scratch`, `comparison`) from being included in the installation package.
- **Schema Compiler**: Fixed edge cases in `buildFixedDecoder` for schemas with 0 fields or 4+ fields, ensuring robust decoding across all packet sizes.

## [0.3.1] — 2026-05-08

This update introduces a zero-allocation decoding pipeline by switching to a callback-dispatch architecture. This shift allows the library to handle high-frequency data throughput without increasing the memory footprint. We've also cleaned up internal requires and adjusted global access patterns to better align with the Luau compiler's default optimization behavior.

### Added

- **Zero-Allocation Decoding**: Implemented a callback-based pipeline that bypasses table creation during packet processing. This reduces GC pressure significantly, maintaining a stable 1 KB memory footprint even under 50M+ operations.
- **Luau Compiler Alignment**: Adjusted global access patterns in the hot path to ensure the Luau compiler can apply its standard optimization opcodes without interference.

### Changed

- **Relative Requires**: Standardized internal module resolution to use relative paths. This improves portability and resolves LSP resolution issues when using Satset as a dependency in Rojo or Wally environments.

### Fixed

- **Roblox Pathing**: Replaced string-based relative requires with standard Roblox instance-based paths (`script.Parent`). This resolves critical errors when requiring Satset modules inside Roblox Studio and ensures full compatibility with `.rbxm` distribution.
- **Float Sanitization**: Corrected edge cases in the core types module where `NaN` or `Infinity` values could bypass the protection guard.
- **Type Resolution**: Fixed several Luau type-inference warnings and documentation typos in `Types/init.luau`.

## [0.2.0] — 2026-05-05

This version focuses on bandwidth efficiency and more flexible batching. The biggest addition is a dual-mode batching engine—now you can choose between **Stability** (chunking payloads to keep frame-rates consistent) and **Latency** (raw throughput without segmentation). We've also added several high-efficiency data types like `f16` and bit-packed booleans for those who want to optimize down to the bit.

### Added

- **Dual-Mode Batching**: You now have full control via `reliableThreshold`. Stability mode segments large payloads so Roblox doesn't "choke," while Latency mode bypasses segmentation to let Zstd compression work much more effectively.
- **Data Type Optimizations**: Added `f16` and `Vector3F16` for syncing data that doesn't need full 32-bit precision.
- **Boolean Bit-packing**: Boolean arrays now use only 1 bit per element. This is a massive bandwidth saver for bulk data.
- **NetRay Adapter**: The benchmark suite now supports NetRay (IDL-compiled).
- **Auto-label PRs**: A new GitHub Action automatically labels PRs based on branch name prefixes.

### Changed

- **Benchmark Overhaul**: The benchmark system is now more modular, using a cleaner adapter-based design.
- **Document Restoration**: Fully restored and updated the README and technical guides to match the 0.2.0 standards.
- **MTU Logic**: Improved how large batches are handled in Stability mode for better reliability.
- **Tooling**: Updated `rokit.toml` to include Lune and tidied up `.gitignore` to keep local testing folders out of the repo.

## [0.1.3] — 2026-05-01

This update introduces significant protocol optimizations, high-performance serialization fast-paths, and refined documentation.

### Added

- **Header Stripping**: Implemented automatic 2-byte size header removal for fixed-size packets, significantly reducing protocol overhead for simple event types.
- **Specialized Fast-Paths**: Added optimized serialization paths for arrays of primitive types (`u8`, `f32`, `boolean`, `string8`, `string16`), reducing per-element CPU cost by up to 50%.
- **Zero-Allocation Dispatch**: Updated packet processing to use direct `pcall(func, arg1)` instead of anonymous closures, eliminating millions of temporary allocations on the hot path.

### Changed

- **Bounds Check Optimization**: Removed manual Lua-level branching for fixed-size schema fields, leveraging native buffer bounds checks for improved execution speed.
- **Map Optimization**: Improved serialization performance for maps with fixed-size keys and values.
- **Benchmark Results**: Updated documentation with latest stress-test data and clarified "Compression Illusion" artifacts related to LZ4.
- **Documentation**: Standardized linking of external libraries to their respective sources across all benchmark tables.

## [0.1.2] — 2026-04-30

This update focuses on **Hardening** and **Production Readiness**. We've implemented strict defensive programming to ensure Satset can survive malicious network traffic and internal script errors without crashing the server.

### Added

- **Initialization Guard**: `Satset.start()` now prevents multiple calls, protecting the engine from state corruption.
- **Listener Resilience**: All packet listeners and channel subscribers are now isolated using `xpcall`. An error in one script won't break the entire networking layer.
- **Bounds Checking**: Added strict validation for `string8`, `string16`, `array`, and `map` types to prevent buffer over-reads from malformed packets.
- **CI/CD Automation**: Release workflow now builds and attaches versioned `.rbxm` assets automatically.

### Changed

- **Documentation**: Added a detailed Contributor Checklist and updated security guides.

### Fixed

- Resolved type-inference errors and Selene linting warnings in the benchmark harness.
- Fixed a bug where a single failing listener could halt the entire dispatch loop.

## [0.1.1] — 2026-04-30

- **Documentation**: Implementation of `development-patterns.md` and `architecture.md` (df06036) by @protheeuz
- **CI/CD**: Added automatic labeling and first-time contributor welcome workflows (df06036) by @protheeuz

## [0.1.0] — 2026-04-29

This release is the foundation. I've focused on two things: making the serialization fast by avoiding table allocations, and making the network layer "hardened" so clients can't crash the server with bad data. The core feature is the new Channel system, which handles delta-compression by only sending what actually changed.

### Added

- **Serialization Engine**: A zero-allocation buffer pipeline. It avoids the GC overhead common in other libraries. (a0f0f37) by @protheeuz
- **Hybrid Transport**: Stateless packets for events and stateful channels for syncing data over time. (a0f0f37) by @protheeuz
- **Tight Packing**: Added a `u4` type (4-bit) and quantized Vector3/Vector2 types. (a0f0f37) by @protheeuz
- **CFrame Compression**: 18-byte implementation using "smallest-three" reconstruction. (a0f0f37) by @protheeuz
- **Batching**: Bundles all remote calls into a single invocation per frame. (a0f0f37) by @protheeuz
- **Unreliable Protection**: Sequence numbers (u16) on unreliable packets. (a0f0f37) by @protheeuz
- **Benchmark Tool**: An in-Studio harness to compare bandwidth and FPS against ByteNet and native Roblox remotes. (a0f0f37) by @protheeuz

### Changed

- **Hardened Floats**: All float types (f32, f64, Vectors, CFrames) now clamp `NaN` and `Infinity` to `0`. This prevents malicious clients from poisoning server-side physics or math.
- **Rate Limiter API**: Guard now uses `maxTokens` (burst) and `refillRate` (tokens/sec).

### Security

- **Token Bucket**: Server-side rate limiting is enabled by default to prevent packet flooding.
- **Validation**: Every incoming payload is checked against its schema and buffer bounds before processing.
