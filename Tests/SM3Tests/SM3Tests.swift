import Testing
import Foundation
@testable import SM3

@Suite("SM3 Hash Function Tests")
struct SM3Tests {

    // MARK: - Test Vector 1: "abc"

    @Test("Hash of abc")
    func testHashABC() async throws {
        let input = "abc".data(using: .utf8)!
        let expected = "66c7f0f462eeedd9d1f2d46bdc10e4e24167c4875cf2f7a2297da02b8f4ba8e0"

        let hash = SM3.hash(data: input)
        let hashHex = hash.map { String(format: "%02x", $0) }.joined()

        #expect(hashHex == expected)
    }

    // MARK: - Test Vector 2: Empty String

    @Test("Hash of empty string")
    func testHashEmptyString() async throws {
        let input = Data()
        let expected = "1ab21d8355cfa17f8e61194831e81a8f22bec8c728fefb747ed035eb5082aa2b"

        let hash = SM3.hash(data: input)
        let hashHex = hash.map { String(format: "%02x", $0) }.joined()

        #expect(hashHex == expected)
    }

    // MARK: - Test Vector 3: "abcd" repeated 16 times

    @Test("Hash of abcd repeated 16 times")
    func testHashABCDRepeated() async throws {
        let input = String(repeating: "abcd", count: 16).data(using: .utf8)!
        let expected = "debe9ff92275b8a138604889c18e5a4d6fdb70e5387e5765293dcba39c0c5732"

        let hash = SM3.hash(data: input)
        let hashHex = hash.map { String(format: "%02x", $0) }.joined()

        #expect(hashHex == expected)
    }

    // MARK: - Test Vector 4: Sample Sentence

    @Test("Hash of Yoda quote")
    func testHashYodaQuote() async throws {
        let input = "Yoda said, Do or do not. There is not try.".data(using: .utf8)!
        let expected = "6bb5ff84416dc1edf21c7b0c36d7adfdebe9378702a8982dd6ff0842188b67a5"

        let hash = SM3.hash(data: input)
        let hashHex = hash.map { String(format: "%02x", $0) }.joined()

        #expect(hashHex == expected)
    }

    // MARK: - Streaming API Tests

    @Test("Streaming hash matches single hash")
    func testStreamingAPI() async throws {
        let input = "abc".data(using: .utf8)!

        // Single hash
        let singleHash = SM3.hash(data: input)

        // Streaming hash
        var hasher = SM3()
        hasher.update(data: input)
        let streamHash = hasher.finalize()

        #expect(singleHash == streamHash)
    }

    @Test("Streaming with multiple updates")
    func testStreamingMultipleUpdates() async throws {
        let part1 = "ab".data(using: .utf8)!
        let part2 = "c".data(using: .utf8)!
        let expected = "66c7f0f462eeedd9d1f2d46bdc10e4e24167c4875cf2f7a2297da02b8f4ba8e0"

        var hasher = SM3()
        hasher.update(data: part1)
        hasher.update(data: part2)
        let hash = hasher.finalize()
        let hashHex = hash.map { String(format: "%02x", $0) }.joined()

        #expect(hashHex == expected)
    }

    @Test("Streaming with many small updates")
    func testStreamingManySmallUpdates() async throws {
        let input = "abc".data(using: .utf8)!
        let expected = "66c7f0f462eeedd9d1f2d46bdc10e4e24167c4875cf2f7a2297da02b8f4ba8e0"

        var hasher = SM3()
        for byte in input {
            hasher.update(data: Data([byte]))
        }
        let hash = hasher.finalize()
        let hashHex = hash.map { String(format: "%02x", $0) }.joined()

        #expect(hashHex == expected)
    }

    // MARK: - Edge Cases

    @Test("Hash output is always 32 bytes")
    func testHashOutputLength() async throws {
        let testInputs = [
            Data(),
            "a".data(using: .utf8)!,
            "abc".data(using: .utf8)!,
            Data(repeating: 0, count: 1000),
            Data(repeating: 0xFF, count: 10000)
        ]

        for input in testInputs {
            let hash = SM3.hash(data: input)
            #expect(hash.count == 32)
        }
    }

    @Test("Different inputs produce different hashes")
    func testDifferentInputsDifferentHashes() async throws {
        let input1 = "abc".data(using: .utf8)!
        let input2 = "abd".data(using: .utf8)!

        let hash1 = SM3.hash(data: input1)
        let hash2 = SM3.hash(data: input2)

        #expect(hash1 != hash2)
    }

    @Test("Large input - 1MB")
    func testLargeInput() async throws {
        // Create 1MB of data
        let input = Data(repeating: 0x42, count: 1024 * 1024)

        let hash = SM3.hash(data: input)

        #expect(hash.count == 32)
        // Hash should be deterministic
        let hash2 = SM3.hash(data: input)
        #expect(hash == hash2)
    }

    @Test("Multi-block input - 128 bytes with 2 blocks")
    func testMultiBlock() async throws {
        // 128 bytes = exactly 2 blocks
        let input = Data(repeating: 0xAB, count: 128)
        let hash = SM3.hash(data: input)

        #expect(hash.count == 32)

        // Verify consistency
        let hash2 = SM3.hash(data: input)
        #expect(hash == hash2)
    }

    @Test("Multi-block with streaming - 256 bytes with 4 blocks")
    func testMultiBlockStreaming() async throws {
        let input = Data(repeating: 0xCD, count: 256)

        // One-shot
        let hashOneShot = SM3.hash(data: input)

        // Streaming in 64-byte chunks
        var hasher = SM3()
        for i in stride(from: 0, to: 256, by: 64) {
            hasher.update(data: input[i..<i+64])
        }
        let hashStreaming = hasher.finalize()

        #expect(hashOneShot == hashStreaming)
    }

    @Test("Very large input - 10MB")
    func testVeryLargeInput() async throws {
        // Create 10MB of patterned data
        let pattern = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07])
        var input = Data()
        for _ in 0..<(10 * 1024 * 1024 / pattern.count) {
            input.append(pattern)
        }

        let hash = SM3.hash(data: input)

        #expect(hash.count == 32)
        #expect(input.count == 10 * 1024 * 1024)

        // Verify deterministic
        let hash2 = SM3.hash(data: input)
        #expect(hash == hash2)
    }
}

// MARK: - Bit Operations Tests

@Suite("SM3 Bit Operations Tests")
struct SM3BitOperationsTests {

    @Test("Rotate left by 0 returns same value")
    func testRotateLeftZero() {
        let value: UInt32 = 0x12345678
        let result = SM3.rotateLeft(value, by: 0)
        #expect(result == value)
    }

    @Test("Rotate left by 32 returns same value")
    func testRotateLeftFull() {
        let value: UInt32 = 0x12345678
        let result = SM3.rotateLeft(value, by: 32)
        #expect(result == value)
    }

    @Test("Rotate left by 1")
    func testRotateLeftOne() {
        let value: UInt32 = 0x12345678
        let expected: UInt32 = 0x2468ACF0
        let result = SM3.rotateLeft(value, by: 1)
        #expect(result == expected)
    }

    @Test("Rotate left by 8")
    func testRotateLeftEight() {
        let value: UInt32 = 0x12345678
        let expected: UInt32 = 0x34567812
        let result = SM3.rotateLeft(value, by: 8)
        #expect(result == expected)
    }

    @Test("Rotate left by 15")
    func testRotateLeftFifteen() {
        let value: UInt32 = 0x80000001
        let expected: UInt32 = 0x0000C000
        let result = SM3.rotateLeft(value, by: 15)
        #expect(result == expected)
    }

    @Test("Rotate left preserves all bits")
    func testRotateLeftPreservesBits() {
        let value: UInt32 = 0xAAAA5555
        for shift in 0..<32 {
            let result = SM3.rotateLeft(value, by: UInt32(shift))
            #expect(result.nonzeroBitCount == value.nonzeroBitCount)
        }
    }
}

// MARK: - Padding Tests

@Suite("SM3 Padding Tests")
struct SM3PaddingTests {

    @Test("Padding for empty message")
    func testPaddingEmpty() {
        let input = Data()
        let padded = SM3.pad(message: input)

        // Empty message should pad to 64 bytes (512 bits)
        // 0 bytes + 1 bit + padding + 8 bytes length = 64 bytes
        #expect(padded.count == 64)

        // First byte should be 0x80 (the '1' bit followed by zeros)
        #expect(padded[0] == 0x80)

        // Last 8 bytes should be length (0 in this case)
        let lastEight = padded.suffix(8)
        #expect(lastEight.allSatisfy { $0 == 0 })
    }

    @Test("Padding for abc")
    func testPaddingABC() {
        let input = "abc".data(using: .utf8)!
        let padded = SM3.pad(message: input)

        // 3 bytes + 1 bit + padding + 8 bytes length = 64 bytes
        #expect(padded.count == 64)

        // First 3 bytes should be 'abc'
        #expect(padded[0] == 0x61) // 'a'
        #expect(padded[1] == 0x62) // 'b'
        #expect(padded[2] == 0x63) // 'c'

        // Next byte should be 0x80
        #expect(padded[3] == 0x80)

        // Last 8 bytes should be length in bits (24 = 0x18)
        #expect(padded[63] == 0x18)
    }

    @Test("Padding length is multiple of 64")
    func testPaddingMultipleOf64() {
        let testSizes = [0, 1, 3, 55, 56, 63, 64, 100, 512, 1000]

        for size in testSizes {
            let input = Data(repeating: 0x42, count: size)
            let padded = SM3.pad(message: input)
            #expect(padded.count % 64 == 0)
        }
    }
}
