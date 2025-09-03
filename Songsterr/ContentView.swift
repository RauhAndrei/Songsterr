import SwiftUI

// MARK: - Main View
struct ContentView: View {
    @StateObject var player = TabPlayerViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            TablatureView(player: player)
            
            HStack {
                Button(player.isPlaying ? "⏹ Stop" : "▶️ Play") {
                    if player.isPlaying {
                        player.stop()
                    } else {
                        player.start()
                    }
                }
                .padding()
                
                Toggle("Loop", isOn: $player.loopEnabled)
                    .padding()
            }
        }
        .padding()
    }
}



