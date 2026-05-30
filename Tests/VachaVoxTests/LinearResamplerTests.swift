import XCTest
@testable import VachaVox

final class LinearResamplerTests: XCTestCase {
    func testReturnsOriginalSamplesWhenRatesMatch() {
        let samples: [Float] = [0, 0.5, 1]

        XCTAssertEqual(LinearResampler.resample(samples: samples, from: 16_000, to: 16_000), samples)
    }

    func testDownsamplesToExpectedCount() {
        let samples = Array(repeating: Float(0.25), count: 48_000)

        let output = LinearResampler.resample(samples: samples, from: 48_000, to: 16_000)

        XCTAssertEqual(output.count, 16_000)
    }
}
