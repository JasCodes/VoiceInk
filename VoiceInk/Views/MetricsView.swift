import SwiftUI
import SwiftData
import Charts
import KeyboardShortcuts

struct MetricsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transcription.timestamp) private var transcriptions: [Transcription]
    @EnvironmentObject private var whisperState: WhisperState
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    // License VM removed
    
    var body: some View {
        VStack {
            // Trial message blocks removed

            MetricsContent(
                transcriptions: Array(transcriptions)
                // License state removed
            )
        }
        .background(Color(.controlBackgroundColor))
    }
}
