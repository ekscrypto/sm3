# SM3 - ShangMi 3 Cryptographic Hash Function

A pure Swift implementation of the SM3 cryptographic hash algorithm for Swift 6.2+.

## Overview

SM3 is a cryptographic hash function published by the Chinese National Cryptography Administration as **GM/T 0004-2012**. It produces a 256-bit (32-byte) hash value and is used in various cryptographic applications including digital signatures, message authentication, and random number generation.

**Standards:**
- GM/T 0004-2012 (Chinese National Standard)
- GB/T 32905-2016
- ISO/IEC 10118-3:2018
- IETF Draft: [draft-sca-cfrg-sm3](https://datatracker.ietf.org/doc/html/draft-sca-cfrg-sm3)

## Features

- ✅ Pure Swift implementation (no C/Objective-C dependencies)
- ✅ Swift 6.2 with strict concurrency
- ✅ Comprehensive test coverage with official test vectors
- ✅ Both one-shot and streaming APIs
- ✅ Optimized bit operations
- ✅ Ready for SIMD optimization

## Installation

### Swift Package Manager

Add SM3 to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ekscrypto/sm3.git", from: "1.0.0")
]
```

## Usage

### One-Shot Hashing

```swift
import SM3
import Foundation

let data = "abc".data(using: .utf8)!
let hash = SM3.hash(data: data)

// Convert to hex string
let hashHex = hash.map { String(format: "%02x", $0) }.joined()
print(hashHex)
// Output: 66c7f0f462eeedd9d1f2d46bdc10e4e24167c4875cf2f7a2297da02b8f4ba8e0
```

### Streaming API

```swift
import SM3
import Foundation

var hasher = SM3()

// Hash data in chunks
hasher.update(data: chunk1)
hasher.update(data: chunk2)
hasher.update(data: chunk3)

// Get final hash
let hash = hasher.finalize()
```

## Test Vectors

The implementation has been validated against official SM3 test vectors:

| Input | SM3 Hash |
|-------|----------|
| `""` (empty) | `1ab21d8355cfa17f8e61194831e81a8f22bec8c728fefb747ed035eb5082aa2b` |
| `"abc"` | `66c7f0f462eeedd9d1f2d46bdc10e4e24167c4875cf2f7a2297da02b8f4ba8e0` |
| `"abcd"` × 16 | `debe9ff92275b8a138604889c18e5a4d6fdb70e5387e5765293dcba39c0c5732` |
| Sample text | `6bb5ff84416dc1edf21c7b0c36d7adfdebe9378702a8982dd6ff0842188b67a5` |

## Implementation Details

### Algorithm Structure

1. **Message Padding**: Appends `0x80`, zero padding, and 64-bit message length
2. **Message Expansion**: Expands each 512-bit block to 68 words (W) and 64 words (W')
3. **Compression**: 64 rounds of compression using boolean and permutation functions
4. **Output**: 256-bit hash value

### Key Components

- **Initial Hash Value (IV)**: 8 × 32-bit constants
- **Step Constants**: T₀ = `0x79cc4519`, T₁₆ = `0x7a879d8a`
- **Boolean Functions**: FF_j and GG_j (vary by round)
- **Permutation Functions**: P₀ and P₁
- **Bit Operations**: Circular left shift (rotate)

### Performance

- **Block Size**: 512 bits (64 bytes)
- **Output Size**: 256 bits (32 bytes)
- **Pure Swift**: No external dependencies
- **Optimizations**: SIMD8 for W' generation where data dependencies allow
- **Throughput**: ~120 MB/s for large data (see PERFORMANCE.md for details)

See Benchmarks below

## Security

SM3 provides security comparable to SHA-256:
- Current best cryptanalytic attacks reach ~31% of compression rounds for collisions
- ~47% for preimage attacks
- No practical attacks known against full SM3

## References

1. GM/T 0004-2012: SM3 Cryptographic Hash Algorithm
2. ISO/IEC 10118-3:2018
3. IETF Draft: https://datatracker.ietf.org/doc/html/draft-sca-cfrg-sm3
4. Research notes: See [CLAUDE.md](CLAUDE.md) for implementation details

## Contributing

Contributions are welcome! Please ensure:
- All tests pass
- Code follows Swift 6.2 conventions
- Changes are documented
- Test vectors validate correctness

## Acknowledgments

- Chinese National Cryptography Administration for the SM3 specification
- Reference implementations: emmansun/gmsm (Go), Crypto++ (C++), and others

## Benchmarks
```
swift run -c release sm3-benchmark
Building for production...
[1/1] Write swift-version--58304C5D6DBC2206.txt
Build of product 'sm3-benchmark' complete! (0.12s)
SM3 Performance Benchmark
=========================
System Information:
  CPU: Apple M2 Max
  Architecture: Apple Silicon (ARM64)
  CPU Cores: 12
  Max Frequency: Not available
  Swift version: SM3Benchmark/main.swift

Benchmarking: Tiny (64 bytes / 1 block)
  Data size: 64 bytes
  Iterations: 10000
  Total time: 0.022s
  Average: 0.002ms
  Throughput: 29.12 MB/s

Benchmarking: Small (1 KB)
  Data size: 1024 bytes
  Iterations: 1000
  Total time: 0.011s
  Average: 0.011ms
  Throughput: 96.80 MB/s

Benchmarking: Medium (64 KB)
  Data size: 65536 bytes
  Iterations: 100
  Total time: 0.057s
  Average: 0.566ms
  Throughput: 115.88 MB/s

Benchmarking: Large (1 MB)
  Data size: 1048576 bytes
  Iterations: 10
  Total time: 0.089s
  Average: 8.931ms
  Throughput: 117.41 MB/s

Benchmarking: XLarge (10 MB)
  Data size: 10485760 bytes
  Iterations: 3
  Total time: 0.262s
  Average: 87.424ms
  Throughput: 119.94 MB/s

==================================================
SUMMARY
==================================================

System: Apple M2 Max
Architecture: Apple Silicon (ARM64)
CPU Cores: 12
Implementation: SIMD-optimized (W' generation)

Benchmark                             Throughput
--------------------------------------------------
Tiny (64 bytes / 1 block)             29.12 MB/s
Small (1 KB)                          96.80 MB/s
Medium (64 KB)                        115.88 MB/s
Large (1 MB)                          117.41 MB/s
```

