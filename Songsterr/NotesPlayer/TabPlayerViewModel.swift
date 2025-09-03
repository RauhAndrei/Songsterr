import SwiftUI
import AVFAudio

final class TabPlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var loopEnabled = false
    @Published var sliderX: CGFloat = 40
    @Published var loopStart: Int = 0
    @Published var loopEnd: Int = 0
    
    var notes: [TabNote] = []
    private var audioEngine = AVAudioEngine()
    private var timer: Timer?
    private var currentIndex = 0
    private var currentGroupIndex = 0
    
    init() {
        notes = [
            TabNote(string: 6, fret: 0, position: 0, duration: 0.6),
            TabNote(string: 5, fret: 3, position: 0, duration: 0.6),
            TabNote(string: 4, fret: 0, position: 1, duration: 0.6),
            TabNote(string: 3, fret: 0, position: 2, duration: 0.6),
            TabNote(string: 2, fret: 0, position: 3, duration: 0.6),
            TabNote(string: 1, fret: 7, position: 4, duration: 1.0)
        ] // mock notes
        
        loopStart = 0
        loopEnd = notes.count - 1
    }
    
    private var groupedNotes: [[TabNote]] {
        var groups: [[TabNote]] = []
        var dict: [Int: [TabNote]] = [:]
        for note in notes {
            dict[note.position, default: []].append(note)
        }
        let sortedKeys = dict.keys.sorted()
        for key in sortedKeys {
            groups.append(dict[key]!)
        }
        return groups
    }

    private var positionToGroupIndex: [Int: Int] {
        Dictionary(uniqueKeysWithValues:
            groupedNotes.enumerated().compactMap { gi, arr in
                guard let pos = arr.first?.position else { return nil }
                return (pos, gi)
            }
        )
    }

    private var loopStartGroup: Int {
        positionToGroupIndex[notes[loopStart].position] ?? 0
    }
    private var loopEndGroup: Int {
        positionToGroupIndex[notes[loopEnd].position] ?? max(0, groupedNotes.count - 1)
    }
    
    private func xForGroup(_ gi: Int) -> CGFloat {
        let pos = groupedNotes[gi].first?.position ?? 0
        return CGFloat(pos) * 60 + 40
    }
    
    func start() {
        guard !isPlaying else { return }
        isPlaying = true
        currentGroupIndex = loopStartGroup
        sliderX = xForGroup(currentGroupIndex)
        playCurrent()
    }
    
    func stop() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        sliderX = CGFloat(notes[loopStart].position) * 60 + 40
    }
    
    private func playCurrent() {
        let groups = groupedNotes

        guard isPlaying, currentGroupIndex <= loopEndGroup else {
            if loopEnabled {
                restartLoop()
            } else {
                stop()
            }
            return
        }

        let chord = groups[currentGroupIndex]
        playChord(notes: chord)

        let duration = chord.first?.duration ?? 0.5

        let nextX = (currentGroupIndex < loopEndGroup)
            ? xForGroup(currentGroupIndex + 1)
            : xForGroup(currentGroupIndex)

        withAnimation(.linear(duration: duration)) {
            sliderX = nextX
        }

        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.currentGroupIndex += 1
            self.playCurrent()
        }
    }

    private func playChord(notes: [TabNote]) {
        for note in notes {
            play(note: note)
        }
    }
    
    private func restartLoop() {
        currentGroupIndex = loopStartGroup
        sliderX = xForGroup(currentGroupIndex)
        playCurrent()
    }
    
    //TODO: вынести в общий сервис по логике работы со звуком
    private func play(note: TabNote) {
        let baseFrequencies: [Double] = [329.63, 246.94, 196.00, 146.83, 110.00, 82.41]
        let stringIndex = 6 - note.string
        let baseFreq = baseFrequencies[stringIndex]
        let freq = baseFreq * pow(2.0, Double(note.fret) / 12.0)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let player = AVAudioPlayerNode()
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(44100 * note.duration))!
        buffer.frameLength = buffer.frameCapacity
        
        let samples = buffer.floatChannelData![0]
        let sampleRate = Float(format.sampleRate)
        for i in 0..<Int(buffer.frameLength) {
            samples[i] = sin(2.0 * .pi * Float(freq) * Float(i) / sampleRate)
        }
        
        audioEngine.attach(player)
        audioEngine.connect(player, to: audioEngine.mainMixerNode, format: format)
        
        if !audioEngine.isRunning {
            try? audioEngine.start()
        }
        
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        player.play()
    }
}
