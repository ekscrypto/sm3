import SM3
import Foundation

print("SM3 Performance Benchmark")
print("=========================")
print("Swift version: \(#file)")
print()

struct BenchmarkResult {
    let name: String
    let dataSize: Int
    let iterations: Int
    let totalTime: TimeInterval

    var averageTime: TimeInterval {
        totalTime / Double(iterations)
    }

    var throughputMBps: Double {
        let bytesPerSecond = Double(dataSize * iterations) / totalTime
        return bytesPerSecond / 1_000_000.0
    }
}

func benchmark(name: String, dataSize: Int, iterations: Int) -> BenchmarkResult {
    print("Benchmarking: \(name)")
    print("  Data size: \(dataSize) bytes")
    print("  Iterations: \(iterations)")

    // Generate test data
    let data = Data((0..<dataSize).map { UInt8($0 % 256) })

    // Warm up
    _ = SM3.hash(data: data)

    // Run benchmark
    let start = Date()
    for _ in 0..<iterations {
        _ = SM3.hash(data: data)
    }
    let totalTime = Date().timeIntervalSince(start)

    let result = BenchmarkResult(
        name: name,
        dataSize: dataSize,
        iterations: iterations,
        totalTime: totalTime
    )

    print("  Total time: \(String(format: "%.3f", result.totalTime))s")
    print("  Average: \(String(format: "%.3f", result.averageTime * 1000))ms")
    print("  Throughput: \(String(format: "%.2f", result.throughputMBps)) MB/s")
    print()

    return result
}

// Run benchmarks (reduced iterations for initial baseline)
let benchmarks: [(String, Int, Int)] = [
    ("Tiny (64 bytes / 1 block)", 64, 10_000),
    ("Small (1 KB)", 1_024, 1_000),
    ("Medium (64 KB)", 64 * 1024, 100),
    ("Large (1 MB)", 1_024 * 1024, 10),
    ("XLarge (10 MB)", 10 * 1024 * 1024, 3)
]

var results: [BenchmarkResult] = []

for (name, size, iterations) in benchmarks {
    let result = benchmark(name: name, dataSize: size, iterations: iterations)
    results.append(result)
}

// Summary
print(String(repeating: "=", count: 50))
print("SUMMARY")
print(String(repeating: "=", count: 50))
print()
print("Implementation: Scalar (baseline)")
print()
print("Benchmark".padding(toLength: 35, withPad: " ", startingAt: 0) + "   Throughput")
print(String(repeating: "-", count: 50))

for result in results {
    let name = result.name.padding(toLength: 35, withPad: " ", startingAt: 0)
    let throughput = String(format: "%.2f MB/s", result.throughputMBps)
    print("\(name)   \(throughput)")
}

print()
print("Baseline benchmark complete!")
print("Save these results for comparison with SIMD implementation.")
