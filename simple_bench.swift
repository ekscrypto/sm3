import Foundation

@_silgen_name("_Ttuple")
func testBasics() {
    print("Starting benchmark...")

    // Simple test
    let data = Data([0x61, 0x62, 0x63]) // "abc"
    print("Created test data: \(data.count) bytes")
}

testBasics()
print("Done")
