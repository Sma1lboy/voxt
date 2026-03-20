import XCTest
@testable import Voxt

final class RecordingStartPlannerTests: XCTestCase {
    func testMLXAudioNotDownloadedBlocksRecordingStart() {
        let decision = RecordingStartPlanner.resolve(
            selectedEngine: .mlxAudio,
            mlxModelState: .notDownloaded
        )

        XCTAssertEqual(decision, .blocked(.mlxModelNotInstalled))
    }

    func testMLXAudioErrorBlocksRecordingStart() {
        let decision = RecordingStartPlanner.resolve(
            selectedEngine: .mlxAudio,
            mlxModelState: .error("broken")
        )

        XCTAssertEqual(decision, .blocked(.mlxModelUnavailable))
    }

    func testMLXAudioDownloadedStartsWithMLXAudio() {
        let decision = RecordingStartPlanner.resolve(
            selectedEngine: .mlxAudio,
            mlxModelState: .downloaded
        )

        XCTAssertEqual(decision, .start(.mlxAudio))
    }

    func testMLXAudioDownloadingBlocksRecordingStart() {
        let decision = RecordingStartPlanner.resolve(
            selectedEngine: .mlxAudio,
            mlxModelState: .downloading(
                progress: 0.5,
                completed: 10,
                total: 20,
                currentFile: "weights.bin",
                completedFiles: 1,
                totalFiles: 2
            )
        )

        XCTAssertEqual(decision, .blocked(.mlxModelDownloading))
    }

    func testDictationStartIgnoresMLXModelState() {
        let decision = RecordingStartPlanner.resolve(
            selectedEngine: .dictation,
            mlxModelState: .notDownloaded
        )

        XCTAssertEqual(decision, .start(.dictation))
    }
}
