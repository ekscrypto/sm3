import Foundation

// MARK: - SIMD Optimizations

extension SM3 {

    // MARK: - SIMD Bit Operations

    /// Rotate left (circular shift) for SIMD8<UInt32>
    @inline(__always)
    internal static func rotateLeft(_ vector: SIMD8<UInt32>, by amount: UInt32) -> SIMD8<UInt32> {
        let normalizedAmount = amount % 32
        return (vector &<< normalizedAmount) | (vector &>> (32 - normalizedAmount))
    }

    // MARK: - SIMD Message Expansion

    /// Expand W array - scalar version to avoid data dependencies
    /// W[j] depends on W[j-3], which prevents effective SIMD parallelization
    internal static func expandMessageSIMD(W: inout [UInt32]) {
        for j in 16..<68 {
            let term1 = W[j - 16] ^ W[j - 9] ^ Self.rotateLeft(W[j - 3], by: 15)
            let term2 = Self.P1(term1)
            W[j] = term2 ^ Self.rotateLeft(W[j - 13], by: 7) ^ W[j - 6]
        }
    }

    /// Generate W' array using SIMD8 (8 XORs per instruction)
    internal static func generateWPrimeSIMD(W: [UInt32], WPrime: inout [UInt32]) {
        var j = 0
        // Process 8 words at a time
        while j <= 56 {
            let w_j = SIMD8<UInt32>(W[j], W[j+1], W[j+2], W[j+3],
                                     W[j+4], W[j+5], W[j+6], W[j+7])
            let w_j_plus_4 = SIMD8<UInt32>(W[j+4], W[j+5], W[j+6], W[j+7],
                                            W[j+8], W[j+9], W[j+10], W[j+11])

            let result = w_j ^ w_j_plus_4

            for i in 0..<8 {
                WPrime[j+i] = result[i]
            }

            j += 8
        }

        // Handle remaining words (should be 0 since 64 % 8 == 0)
        while j < 64 {
            WPrime[j] = W[j] ^ W[j + 4]
            j += 1
        }
    }
}
