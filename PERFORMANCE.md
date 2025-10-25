# SM3 Performance Benchmarks

This document tracks the performance of different SM3 implementations.

## Test Environment

- **Platform**: Apple Silicon (arm64e-apple-macos14.0)
- **Swift Version**: 6.2
- **Build Configuration**: Release (-O)
- **Date**: 2025-10-25

## Baseline: Scalar Implementation

Pure Swift implementation without SIMD optimizations.

### Throughput Results

| Benchmark                    | Data Size  | Iterations | Throughput |
|------------------------------|------------|------------|------------|
| Tiny (64 bytes / 1 block)    | 64 B       | 10,000     | 21.86 MB/s |
| Small (1 KB)                 | 1 KB       | 1,000      | 82.40 MB/s |
| Medium (64 KB)               | 64 KB      | 100        | 112.81 MB/s|
| Large (1 MB)                 | 1 MB       | 10         | 120.00 MB/s|
| XLarge (10 MB)               | 10 MB      | 3          | 123.39 MB/s|

### Analysis

- **Peak throughput**: ~120 MB/s for large data blocks
- **Small data overhead**: Significant overhead for tiny blocks (21.86 MB/s) due to setup costs
- **Throughput scaling**: Performance stabilizes around 1 MB, indicating good efficiency for multi-block processing

### Comparison to Reference Implementations

Based on research:
- **Go (emmansun/gmsm) Scalar**: ~250 MB/s (estimated)
- **Go (emmansun/gmsm) SIMD (AVX2)**: ~384.5 MB/s (+53% improvement)

Our scalar implementation achieves ~48% of the Go scalar performance, which is reasonable given:
- Swift's safety overhead
- Different compiler optimizations
- Platform differences

## Final Implementation

Swift's native SIMD types are used where data dependencies allow, primarily for W' generation.

### Key Insights

**Why Not Full SIMD?**
- **W array expansion**: Has sequential data dependencies (W[j] depends on W[j-3])
- **W' array generation**: Perfect for SIMD (simple XOR with no dependencies)
- **Compression function**: Sequential by design (each round depends on previous)

**Current Optimization**:
- W' generation uses `SIMD8<UInt32>` (processes 8 XORs per instruction)
- W expansion remains scalar due to data dependencies
- Compression function remains scalar (algorithm requirement)

### Final Performance

The implementation achieves ~120 MB/s throughput for large data blocks, which is reasonable for a pure Swift implementation prioritizing:
- Correctness and clarity
- Cross-platform compatibility
- Zero dependencies
- Safety and maintainability

**For comparison**:
- Go (emmansun/gmsm) Scalar: ~250 MB/s
- Go (emmansun/gmsm) SIMD: ~385 MB/s
- Our Swift implementation: ~120 MB/s (48% of Go scalar)

The performance difference is acceptable given Swift's safety guarantees and the lack of platform-specific optimizations.

## Benchmark Reproduction

To reproduce these benchmarks:

```bash
swift build -c release
.build/release/sm3-benchmark
```

Or run directly:

```bash
swift run -c release sm3-benchmark
```

## Notes

- Benchmarks run with reduced iterations to keep runtime reasonable
- Results may vary based on system load and thermal conditions
- Release builds with optimizations (-O) are required for accurate measurements
