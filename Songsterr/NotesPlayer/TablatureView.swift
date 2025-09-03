import SwiftUI

struct TablatureView: View {
    @ObservedObject var player: TabPlayerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            ZStack(alignment: .topLeading) {
                // Струны
                VStack(spacing: 12) {
                    ForEach(0..<6) { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(height: 1)
                    }
                }
                .padding(.vertical, 4)
                
                // Ползунок
                Image(.cursor)
                    .frame(width: 4, height: 100)
                    .position(x: player.sliderX, y: 40)
                
                // Ноты
                ForEach(player.notes) { note in
                    Text("\(note.fret)")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 20, height: 20)
                        .position(x: CGFloat(note.position) * 60 + 40,
                                  y: CGFloat(note.string - 1) * 12 + 8)
                }
                
                // Левая граница
                Image(.loopHandleLeft)
                    .resizable()
                    .frame(width: 10, height: 100)
                    .position(x: CGFloat(player.notes[player.loopStart].position) * 60 + 10, y: 35)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if let nearest = nearestNote(to: value.location.x, notes: player.notes) {
                                    if nearest <= player.loopEnd {
                                        player.loopStart = nearest
                                    }
                                }
                            }
                    )

                // Правая граница
                Image(.loopHandleRight)
                    .resizable()
                    .frame(width: 10, height: 100)
                    .position(x: CGFloat(player.notes[player.loopEnd].position) * 60 + 80, y: 35)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if let nearest = nearestNote(to: value.location.x, notes: player.notes) {
                                    if nearest >= player.loopStart {
                                        player.loopEnd = nearest
                                    }
                                }
                            }
                    )
            }
            .frame(height: 70)
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.green, lineWidth: 2))
        }
    }
    
    private func nearestNote(to x: CGFloat, notes: [TabNote]) -> Int? {
        let index = notes.enumerated().min(by: { abs(CGFloat($0.element.position) * 60 + 40 - x) <
                                                abs(CGFloat($1.element.position) * 60 + 40 - x) })?.offset
        return index
    }
}
