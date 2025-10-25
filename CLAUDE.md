# SM3 Swift Implementation Project

## Project Description

This project implements the ShangMi 3 (SM3) cryptographic hash algorithm as a Swift Package. The implementation must:
- Use Swift 6.2
- Be entirely implemented in Swift (no C or Objective-C)
- No third-party libraries
- Produce 256-bit hash values
- Be compatible with official SM3 specifications

## SM3 Algorithm Overview

SM3 is a cryptographic hash function published by the Chinese National Cryptography Administration on 2010-12-17 as **GM/T 0004-2012: SM3 cryptographic hash algorithm**. It is also standardized in:
- GB/T 32905-2016 (Chinese standard)
- ISO/IEC 10118-3:2018 (International standard)
- IETF Draft: draft-sca-cfrg-sm3

### Key Characteristics
- **Output Size:** 256 bits (32 bytes)
- **Block Size:** 512 bits (64 bytes)
- **Input Limit:** Messages up to 2^64 bits
- **Construction:** Merkle-Damgård with Davies-Meyer compression function
- **Security Level:** Similar to SHA-256

## Technical Specification

### Constants

#### Initial Hash Value (IV)
```
0x7380166f, 0x4914b2b9, 0x172442d7, 0xda8a0600,
0xa96f30bc, 0x163138aa, 0xe38dee4d, 0xb0fb0e4e
```

#### Step Constants (T_j)
- For j = 0 to 15: `0x79cc4519`
- For j = 16 to 63: `0x7a879d8a`

### Boolean Functions

#### FF_j (Message Schedule Function)
- For j = 0 to 15: `FF_j(X,Y,Z) = X ⊕ Y ⊕ Z`
- For j = 16 to 63: `FF_j(X,Y,Z) = (X ∧ Y) ∨ (X ∧ Z) ∨ (Y ∧ Z)`

#### GG_j (Compression Function)
- For j = 0 to 15: `GG_j(X,Y,Z) = X ⊕ Y ⊕ Z`
- For j = 16 to 63: `GG_j(X,Y,Z) = (X ∧ Y) ∨ (¬X ∧ Z)`

### Permutation Functions

#### P₀(X)
```
P₀(X) = X ⊕ (X <<< 9) ⊕ (X <<< 17)
```
Where `<<<` denotes circular left shift (rotate left).

#### P₁(X)
```
P₁(X) = X ⊕ (X <<< 15) ⊕ (X <<< 23)
```

## Algorithm Steps

### 1. Message Padding

Given a message M of length l bits:

1. Append a single "1" bit to the message
2. Append k "0" bits where k is the smallest non-negative solution to:
   ```
   l + 1 + k ≡ 448 (mod 512)
   ```
3. Append the 64-bit big-endian representation of l
4. Result: padded message with length ≡ 0 (mod 512)

### 2. Message Expansion

For each 512-bit block, divide into 16 words W₀...W₁₅ (32-bit big-endian), then expand to 68 words:

```
For j = 16 to 67:
  W_j = P₁(W_{j-16} ⊕ W_{j-9} ⊕ (W_{j-3} <<< 15))
        ⊕ (W_{j-13} <<< 7) ⊕ W_{j-6}
```

Generate W' array (64 words):
```
For j = 0 to 63:
  W'_j = W_j ⊕ W_{j+4}
```

### 3. Compression Function

Initialize working variables A,B,C,D,E,F,G,H with current hash value V_i.

For j = 0 to 63:
```
SS1 = ((A <<< 12) + E + (T_j <<< (j mod 32))) <<< 7
SS2 = SS1 ⊕ (A <<< 12)
TT1 = FF_j(A,B,C) + D + SS2 + W'_j
TT2 = GG_j(E,F,G) + H + SS1 + W_j

D = C
C = B <<< 9
B = A
A = TT1

H = G
G = F <<< 19
F = E
E = P₀(TT2)
```

After all 64 rounds:
```
V_{i+1} = (A||B||C||D||E||F||G||H) ⊕ V_i
```

### 4. Output

After processing all message blocks, the final hash value is:
```
H = V_n = (A||B||C||D||E||F||G||H)
```

## Test Vectors

### Test Vector 1: "abc"
**Input:** `"abc"` (UTF-8: 0x616263)
**Expected Output:**
```
66c7f0f462eeedd9d1f2d46bdc10e4e24167c4875cf2f7a2297da02b8f4ba8e0
```

### Test Vector 2: 512 repetitions of "abcd"
**Input:** `"abcd"` repeated 512 times (2048 bytes)
**Expected Output:**
```
debe9ff92275b8a138604889c18e5a4d6fdb70e5387e5765293dcba39c0c5732
```

### Test Vector 3: Sample sentence
**Input:** `"Yoda said, Do or do not. There is not try."`
**Expected Output:**
```
6bb5ff84416dc1edf21c7b0c36d7adfdebe9378702a8982dd6ff0842188b67a5
```

### Test Vector 4: Empty string
**Input:** `""` (empty string)
**Expected Output:**
```
1ab21d8355cfa17f8e61194831e81a8f22bec8c728fefb747ed035eb5082aa2b
```

## Reference Implementations

### Go Language
- **emmansun/gmsm** - https://github.com/emmansun/gmsm
  - Comprehensive ShangMi cipher suite
  - SIMD optimizations (AVX2, AVX, SSE2, NEON)
  - MIT License
  - Good reference for optimization techniques

- **sammyne/sm3** - https://github.com/sammyne/sm3
  - Pure Go implementation
  - Simple, readable code structure

### C Language
- **zhao07/libsm3** - https://github.com/zhao07/libsm3
  - Reference C implementation
  - Clear algorithm structure

### C++
- **Crypto++ Library**
  - SM3 implementation in the Crypto++ suite
  - Well-documented API
  - Extensive testing

### Python
- **siddontang/pygmcrypto** - https://github.com/siddontang/pygmcrypto
  - C implementation with Python bindings

## Implementation Notes for Swift

### Data Types
- Use `UInt32` for all 32-bit word operations
- Use `UInt64` for message length tracking
- All multi-byte values are **big-endian**

### Bit Operations Required
- Circular left shift (rotate left): `<<<`
- XOR: `⊕` (use `^` in Swift)
- AND: `∧` (use `&` in Swift)
- OR: `∨` (use `|` in Swift)
- NOT: `¬` (use `~` in Swift)
- Addition: modulo 2^32 (natural for UInt32)

### Swift Implementation Considerations
1. **Endianness:** Use `bigEndian` property or byte swapping
2. **Rotate Left:** Implement as: `(value << n) | (value >> (32 - n))`
3. **Array Access:** W array needs 68 elements, W' needs 64 elements
4. **Memory Safety:** Swift 6.2's strict concurrency will help prevent data races
5. **Performance:** Consider using inline functions for frequently called operations
6. **Protocol Conformance:** Consider conforming to Hashable protocol patterns

## SIMD Optimization for Apple Hardware

### Why SIMD for SM3?

The Go implementation (emmansun/gmsm) achieves ~53% performance improvement using SIMD instructions (AVX2 on x86, NEON on ARM64). Swift can achieve similar or better results on Apple Silicon using native SIMD types.

### What the Go Implementation Parallelizes

According to the Go SIMD optimization documentation, the primary parallelized operations are:

1. **Message Schedule Computation**: Calculating multiple W words simultaneously
2. **P₁ Permutation Function**: The most computation-heavy operation
   - Multiple rotations: 15-bit and 23-bit circular shifts
   - XOR operations across multiple words
3. **W[-13] and W[-3] Rotations**: 7-bit and 15-bit shifts in parallel
4. **Vector XOR Operations**: Multiple XOR combinations computed simultaneously

**Performance**: The Go AVX2 implementation achieves ~384.5 MB/s throughput.

### Swift SIMD Capabilities

Swift 5+ includes built-in SIMD types that compile directly to hardware instructions:

#### Available Types
- `SIMD2<T>`, `SIMD4<T>`, `SIMD8<T>`, `SIMD16<T>`, `SIMD32<T>`, `SIMD64<T>`
- `T` can be `UInt32` (perfect for SM3's 32-bit words)
- On Apple Silicon, these compile directly to **NEON instructions**

#### Supported Operations
```swift
// Arithmetic (masked, wrapping)
let result = a &+ b  // Vector addition
let result = a &- b  // Vector subtraction
let result = a &* b  // Vector multiplication

// Bitwise operations
let result = a & b   // AND
let result = a | b   // OR
let result = a ^ b   // XOR
let result = ~a      // NOT

// Shifts (but NOT rotations - need custom implementation)
let result = a << 5  // Left shift
let result = a >> 5  // Right shift
```

#### Performance Characteristics
- **2-10x speedup** for data-parallel operations
- Zero overhead abstraction - compiles to native SIMD instructions
- Auto-vectorization: Swift compiler can automatically vectorize some operations

### Optimization Strategy for SM3

#### Level 1: Scalar Implementation (Baseline)
- Standard UInt32 operations
- Clear, readable code
- Easy to verify correctness
- **Target**: Correct implementation first

#### Level 2: SIMD Message Expansion
Most promising optimization target:

```swift
// Process 4 W words at once using SIMD4<UInt32>
func expandMessageSIMD4(W: inout [UInt32]) {
    for j in stride(from: 16, to: 68, by: 4) {
        // Load 4 words into SIMD registers
        let w_j_minus_16 = SIMD4<UInt32>(W[j-16], W[j-15], W[j-14], W[j-13])
        let w_j_minus_9 = SIMD4<UInt32>(W[j-9], W[j-8], W[j-7], W[j-6])
        // ... compute 4 words in parallel
    }
}
```

**Benefits**:
- Message expansion has minimal data dependencies between iterations
- Perfect for SIMD processing
- Each P₁ permutation can be computed independently

#### Level 3: SIMD W' Array Generation
```swift
// Compute W'[j] = W[j] ^ W[j+4] in parallel
func generateWPrimeSIMD8(W: [UInt32]) -> [UInt32] {
    var WPrime = [UInt32](repeating: 0, count: 64)
    for j in stride(from: 0, to: 64, by: 8) {
        let w_j = SIMD8<UInt32>( /* load 8 words */ )
        let w_j_plus_4 = SIMD8<UInt32>( /* load 8 words */ )
        let result = w_j ^ w_j_plus_4  // 8 XORs in one instruction
        // ... store result
    }
}
```

#### Level 4: Multi-Block Parallel Hashing
Process multiple independent message blocks simultaneously:

```swift
// Hash 4 blocks in parallel (SIMD-across-blocks)
func hashMultipleBlocks(_ blocks: [[UInt8]]) -> [[UInt8]] {
    // Use SIMD4<UInt32> where each lane processes one block
    // Requires significant refactoring but maximum throughput
}
```

### Implementation Notes for Rotations

Swift doesn't have built-in rotation operators, but they can be implemented efficiently:

```swift
@inline(__always)
func rotateLeft(_ value: UInt32, by amount: UInt32) -> UInt32 {
    return (value << amount) | (value >> (32 - amount))
}

// SIMD version for rotating vectors
@inline(__always)
func rotateLeft(_ vector: SIMD4<UInt32>, by amount: UInt32) -> SIMD4<UInt32> {
    return (vector << amount) | (vector >> (32 - amount))
}
```

### Recommended Approach

1. **Phase 1**: Implement scalar version
   - Verify correctness with all test vectors
   - Profile to identify hotspots

2. **Phase 2**: Add SIMD message expansion
   - Use `SIMD4<UInt32>` or `SIMD8<UInt32>`
   - Benchmark against scalar version
   - Expected: 30-50% improvement

3. **Phase 3**: Optimize based on profiling
   - Add SIMD to other hotspots
   - Consider multi-block processing for batch operations

### Advantages Over Accelerate Framework

**Why SIMD types are better than Accelerate for SM3:**

1. **Type Safety**: SIMD types are type-safe at compile time
2. **Simplicity**: No need to manage vDSP buffers or setup
3. **Portability**: SIMD types work on all platforms (iOS, macOS, Linux)
4. **Cryptographic Operations**: Accelerate/vDSP is designed for DSP operations (FFT, convolution), not bitwise crypto operations
5. **Direct Hardware Mapping**: SIMD types compile directly to NEON on Apple Silicon
6. **Inline-able**: Can be inlined by compiler for zero overhead

**Accelerate framework limitations:**
- vDSP focuses on floating-point DSP operations
- No direct support for bitwise rotations or crypto-specific operations
- Overhead of function calls to Accelerate library
- Not designed for the type of operations SM3 requires

### Expected Performance

Based on the Go SIMD implementation results:
- **Baseline (scalar)**: ~250 MB/s (estimated)
- **SIMD4 message expansion**: ~350-400 MB/s (40-60% improvement)
- **Full SIMD optimization**: ~450-500 MB/s (80-100% improvement)

On Apple Silicon (M1/M2/M3) with NEON instructions, we may achieve even better results due to:
- Unified memory architecture
- Wide execution units
- Advanced branch prediction
- L1/L2 cache optimization

### Swift Package Structure
```
SM3/
├── Package.swift
├── README.md
├── CLAUDE.md (this file)
├── Sources/
│   └── SM3/
│       ├── SM3.swift (main algorithm)
│       ├── SM3+Extensions.swift (convenience methods)
│       └── Internal/
│           ├── Constants.swift
│           ├── BitOperations.swift
│           └── Padding.swift
└── Tests/
    └── SM3Tests/
        ├── SM3Tests.swift
        └── TestVectors.swift
```

### API Design Ideas
```swift
// Hash a string
let hash = SM3.hash(data: "abc".data(using: .utf8)!)

// Hash data
let data = Data([0x61, 0x62, 0x63])
let hash = SM3.hash(data: data)

// Streaming API
var hasher = SM3()
hasher.update(data: data1)
hasher.update(data: data2)
let hash = hasher.finalize()
```

## Object Identifiers (OIDs)
- **GM/T OID:** 1.2.156.10197.1.401
- **ISO OID:** 1.0.10118.3.0.65

## Security Notes
Current cryptanalytic attacks can reach approximately:
- 31% of compression function steps for collision attacks
- 47% for preimage attacks

This demonstrates security resistance comparable to or exceeding SHA-2 variants. No practical attacks are known against full SM3.

## Standards References
1. GM/T 0004-2012 (Chinese National Standard)
2. GB/T 32905-2016 (Chinese National Standard)
3. ISO/IEC 10118-3:2018
4. IETF Draft: https://datatracker.ietf.org/doc/html/draft-sca-cfrg-sm3
5. Wikipedia: https://en.wikipedia.org/wiki/SM3_(hash_function)

## Research Completed
- Algorithm specification reviewed
- Multiple reference implementations analyzed
- Test vectors collected and verified
- Implementation strategy defined
- Swift package structure planned

**Research Date:** 2025-10-25
