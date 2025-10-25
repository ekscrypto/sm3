import SM3
import Foundation
import Darwin

// MARK: - System Information

struct SystemInfo {
    static func getCPUInfo() -> (String, String) {
        var size: size_t = 0
        
        // Get CPU brand string
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var cpuBrand = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &cpuBrand, &size, nil, 0)
        let brandString = String(cString: cpuBrand).trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Get CPU architecture
        var cpuType: cpu_type_t = 0
        size = MemoryLayout<cpu_type_t>.size
        sysctlbyname("hw.cputype", &cpuType, &size, nil, 0)
        
        let architecture: String
        switch cpuType {
        case CPU_TYPE_ARM64:
            architecture = "Apple Silicon (ARM64)"
        case CPU_TYPE_X86_64:
            architecture = "Intel (x86_64)"
        default:
            architecture = "Unknown (\(cpuType))"
        }
        
        return (brandString, architecture)
    }
    
    static func getSystemSpecs() -> (Int, Double) {
        var size: size_t = 0
        
        // Get CPU count
        var cpuCount: Int32 = 0
        size = MemoryLayout<Int32>.size
        sysctlbyname("hw.ncpu", &cpuCount, &size, nil, 0)
        
        // Get CPU frequency (in Hz)
        var cpuFreq: UInt64 = 0
        size = MemoryLayout<UInt64>.size
        sysctlbyname("hw.cpufrequency_max", &cpuFreq, &size, nil, 0)
        let cpuFreqGHz = Double(cpuFreq) / 1_000_000_000.0
        
        return (Int(cpuCount), cpuFreqGHz)
    }
}

print("SM3 Performance Benchmark")
print("=========================")

// Display system information
let (cpuBrand, architecture) = SystemInfo.getCPUInfo()
let (cpuCount, cpuFreq) = SystemInfo.getSystemSpecs()

print("System Information:")
print("  CPU: \(cpuBrand)")
print("  Architecture: \(architecture)")
print("  CPU Cores: \(cpuCount)")
if cpuFreq > 0 {
    print("  Max Frequency: \(String(format: "%.2f", cpuFreq)) GHz")
} else {
    print("  Max Frequency: Not available")
}
print("  Swift version: \(#file)")
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
print("System: \(cpuBrand)")
print("Architecture: \(architecture)")
print("CPU Cores: \(cpuCount)")
if cpuFreq > 0 {
    print("Max Frequency: \(String(format: "%.2f", cpuFreq)) GHz")
}
print("Implementation: SIMD-optimized (W' generation)")
print()
print("Benchmark".padding(toLength: 35, withPad: " ", startingAt: 0) + "   Throughput")
print(String(repeating: "-", count: 50))

for result in results {
    let name = result.name.padding(toLength: 35, withPad: " ", startingAt: 0)
    let throughput = String(format: "%.2f MB/s", result.throughputMBps)
    print("\(name)   \(throughput)")
}

print()
print("SM3 benchmark complete!")
print("Note: W' generation uses SIMD8 optimization, W expansion is scalar due to data dependencies.")
