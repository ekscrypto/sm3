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
    .package(url: "https://github.com/yourusername/sm3.git", from: "1.0.0")
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
- **Future**: SIMD optimization planned for 2-10x speedup

## Security

SM3 provides security comparable to SHA-256:
- Current best cryptanalytic attacks reach ~31% of compression rounds for collisions
- ~47% for preimage attacks
- No practical attacks known against full SM3

## Development

### Building

```bash
swift build
```

### Testing

```bash
swift test
```

### Project Structure

```
SM3/
├── Package.swift
├── README.md
├── CLAUDE.md                    # Implementation research & notes
├── Sources/
│   └── SM3/
│       └── SM3.swift            # Core implementation
└── Tests/
    └── SM3Tests/
        └── SM3Tests.swift       # Test suite
```

## Future Enhancements

### Phase 2: SIMD Optimization

Planned optimizations using Swift's native SIMD types:

- **Message Expansion**: Process 4-8 W words in parallel using `SIMD4<UInt32>` or `SIMD8<UInt32>`
- **W' Generation**: Compute W'[j] = W[j] ⊕ W[j+4] in parallel (8 XORs per instruction)
- **Multi-Block Processing**: Process multiple independent blocks simultaneously

**Expected Performance**: 40-100% improvement on Apple Silicon (NEON instructions)

## License

[Your License Here]

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
