import Testing
@testable import Murmur

@Test func versionExists() {
    #expect(!MurmurInfo.version.isEmpty)
}
