import Foundation

/// SM3 Cryptographic Hash Function
///
/// SM3 is a cryptographic hash function published by the Chinese National Cryptography Administration
/// as GM/T 0004-2012. It produces a 256-bit (32-byte) hash value.
///
/// References:
/// - GM/T 0004-2012 (Chinese National Standard)
/// - ISO/IEC 10118-3:2018
/// - IETF Draft: draft-sca-cfrg-sm3
public struct SM3 {

    // MARK: - Constants

    /// Initial hash value (IV) - 8 x 32-bit words
    private static let initialHashValue: [UInt32] = [
        0x7380166f, 0x4914b2b9, 0x172442d7, 0xda8a0600,
        0xa96f30bc, 0x163138aa, 0xe38dee4d, 0xb0fb0e4e
    ]

    /// Step constant T_j for rounds 0-15
    private static let T0: UInt32 = 0x79cc4519

    /// Step constant T_j for rounds 16-63
    private static let T16: UInt32 = 0x7a879d8a

    // MARK: - State

    /// Current hash state (8 x 32-bit words)
    private var state: [UInt32]

    /// Buffer for incomplete blocks
    private var buffer: Data

    /// Total length of message in bits
    private var bitLength: UInt64

    // MARK: - Initialization

    /// Create a new SM3 hasher
    public init() {
        self.state = Self.initialHashValue
        self.buffer = Data()
        self.bitLength = 0
    }

    // MARK: - Public API

    /// Compute SM3 hash of data in one shot
    /// - Parameter data: The data to hash
    /// - Returns: 32-byte hash value
    public static func hash(data: Data) -> Data {
        var hasher = SM3()
        hasher.update(data: data)
        return hasher.finalize()
    }

    /// Update the hash with additional data
    /// - Parameter data: Data to add to the hash
    public mutating func update(data: Data) {
        bitLength += UInt64(data.count) * 8
        buffer.append(data)

        // Process complete 512-bit (64-byte) blocks
        while buffer.count >= 64 {
            let prefix = buffer.prefix(64)
            assert(prefix.count == 64)
            processBlock(prefix)
            buffer.removeFirst(64)
        }
    }

    /// Finalize the hash and return the result
    /// - Returns: 32-byte hash value
    public mutating func finalize() -> Data {
        // Pad the final block
        var paddedData = Self.pad(message: buffer, totalBitLength: bitLength)
        assert(paddedData.count % 64 == 0)

        // Process all remaining blocks
        while paddedData.count >= 64 {
            let prefix = paddedData.prefix(64)
            assert(prefix.count == 64)
            processBlock(prefix)
            paddedData.removeFirst(64)
        }

        // Convert state to Data (big-endian)
        var result = Data(capacity: 32)
        for word in state {
            result.append(contentsOf: word.bytes)
        }

        return result
    }

    // MARK: - Block Processing

    /// Process a single 512-bit (64-byte) block
    private mutating func processBlock(_ block: Data) {
        precondition(block.count == 64, "Block must be 64 bytes")

        // 1. Message Expansion
        var W = [UInt32](repeating: 0, count: 68)
        var WPrime = [UInt32](repeating: 0, count: 64)

        // Parse block into 16 big-endian 32-bit words
        // Using withUnsafeBytes for better performance while maintaining safety
        block.withUnsafeBytes { bytes in
            for i in 0..<16 {
                let offset = i * 4
                // Load 4 bytes and interpret as big-endian UInt32
                let word = UInt32(bytes[offset]) << 24 |
                          UInt32(bytes[offset + 1]) << 16 |
                          UInt32(bytes[offset + 2]) << 8 |
                          UInt32(bytes[offset + 3])
                W[i] = word
            }
        }

        // Expand W[16..67]
        for j in 16..<68 {
            let term1 = W[j - 16] ^ W[j - 9] ^ Self.rotateLeft(W[j - 3], by: 15)
            let term2 = Self.P1(term1)
            W[j] = term2 ^ Self.rotateLeft(W[j - 13], by: 7) ^ W[j - 6]
        }

        // Generate W'[0..63]
        for j in 0..<64 {
            WPrime[j] = W[j] ^ W[j + 4]
        }

        // 2. Compression Function
        var A = state[0]
        var B = state[1]
        var C = state[2]
        var D = state[3]
        var E = state[4]
        var F = state[5]
        var G = state[6]
        var H = state[7]

        for j in 0..<64 {
            let Tj = j < 16 ? Self.T0 : Self.T16
            let SS1 = Self.rotateLeft(
                Self.rotateLeft(A, by: 12) &+ E &+ Self.rotateLeft(Tj, by: UInt32(j % 32)),
                by: 7
            )
            let SS2 = SS1 ^ Self.rotateLeft(A, by: 12)
            let TT1 = Self.FF(A, B, C, j: j) &+ D &+ SS2 &+ WPrime[j]
            let TT2 = Self.GG(E, F, G, j: j) &+ H &+ SS1 &+ W[j]

            D = C
            C = Self.rotateLeft(B, by: 9)
            B = A
            A = TT1
            H = G
            G = Self.rotateLeft(F, by: 19)
            F = E
            E = Self.P0(TT2)
        }

        // 3. Update state (XOR with previous state)
        state[0] ^= A
        state[1] ^= B
        state[2] ^= C
        state[3] ^= D
        state[4] ^= E
        state[5] ^= F
        state[6] ^= G
        state[7] ^= H
    }

    // MARK: - Boolean Functions

    /// FF_j function - varies based on round j
    @inline(__always)
    private static func FF(_ X: UInt32, _ Y: UInt32, _ Z: UInt32, j: Int) -> UInt32 {
        if j < 16 {
            return X ^ Y ^ Z
        } else {
            return (X & Y) | (X & Z) | (Y & Z)
        }
    }

    /// GG_j function - varies based on round j
    @inline(__always)
    private static func GG(_ X: UInt32, _ Y: UInt32, _ Z: UInt32, j: Int) -> UInt32 {
        if j < 16 {
            return X ^ Y ^ Z
        } else {
            return (X & Y) | (~X & Z)
        }
    }

    // MARK: - Permutation Functions

    /// P0 permutation function
    @inline(__always)
    private static func P0(_ X: UInt32) -> UInt32 {
        return X ^ rotateLeft(X, by: 9) ^ rotateLeft(X, by: 17)
    }

    /// P1 permutation function
    @inline(__always)
    private static func P1(_ X: UInt32) -> UInt32 {
        return X ^ rotateLeft(X, by: 15) ^ rotateLeft(X, by: 23)
    }

    // MARK: - Bit Operations

    /// Rotate left (circular shift)
    @inline(__always)
    public static func rotateLeft(_ value: UInt32, by amount: UInt32) -> UInt32 {
        let normalizedAmount = amount % 32
        return (value << normalizedAmount) | (value >> (32 - normalizedAmount))
    }

    // MARK: - Padding

    /// Pad message according to SM3 specification
    /// - Parameter message: Message to pad
    /// - Returns: Padded message (multiple of 64 bytes)
    public static func pad(message: Data) -> Data {
        let bitLength = UInt64(message.count) * 8
        return pad(message: message, totalBitLength: bitLength)
    }

    /// Pad message with explicit bit length
    private static func pad(message: Data, totalBitLength: UInt64) -> Data {
        var padded = message

        // Append the '1' bit (0x80)
        padded.append(0x80)

        // Calculate padding length
        // We need: message + 0x80 + zeros + 8 bytes (length) ≡ 0 (mod 64)
        // So: (message.count + 1 + k + 8) % 64 == 0
        // Therefore: k = (64 - (message.count + 1 + 8) % 64) % 64
        let currentLength = message.count + 1 // +1 for the 0x80 byte
        let paddingNeeded = (64 - ((currentLength + 8) % 64)) % 64

        // Append zeros
        padded.append(Data(repeating: 0, count: paddingNeeded))

        // Append length as 64-bit big-endian
        padded.append(contentsOf: totalBitLength.bytes)

        return padded
    }
}

// MARK: - Extensions

extension UInt32 {
    /// Convert UInt32 to bytes (big-endian)
    fileprivate var bytes: [UInt8] {
        return [
            UInt8((self >> 24) & 0xFF),
            UInt8((self >> 16) & 0xFF),
            UInt8((self >> 8) & 0xFF),
            UInt8(self & 0xFF)
        ]
    }
}

extension UInt64 {
    /// Convert UInt64 to bytes (big-endian)
    fileprivate var bytes: [UInt8] {
        return [
            UInt8((self >> 56) & 0xFF),
            UInt8((self >> 48) & 0xFF),
            UInt8((self >> 40) & 0xFF),
            UInt8((self >> 32) & 0xFF),
            UInt8((self >> 24) & 0xFF),
            UInt8((self >> 16) & 0xFF),
            UInt8((self >> 8) & 0xFF),
            UInt8(self & 0xFF)
        ]
    }
}
