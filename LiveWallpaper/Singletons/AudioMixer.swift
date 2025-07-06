//
//  AudioMixer.swift
//  LiveWallpaper
//


import AVFoundation

class AudioMixer {
    static let shared = AudioMixer()
    private var players: [String: AVAudioPlayer] = [:]  // Dictionary to store players by filename
    
    func process(mixerEnabled: Bool, sounds: [Sound]){
        if mixerEnabled {
            for sound in sounds {
                if sound.isEnabled {
                    playSound(fileName: sound.name, volume: sound.volume)
                } else {
                    stopSound(fileName: sound.name)
                }
                
            }
        } else {
            stopAll()
        }
    }
    
    private func stopAll() {
        for player in players.values {
            player.stop()
        }
        players.removeAll()
    }
    
    private func stopSound(fileName:String){
        players[fileName]?.stop()
        players.removeValue(forKey: fileName)
    }
    
    private func playSound(fileName: String, volume: Float) {
    
        if let player = players[fileName] {
            player.volume = volume
            player.play()
            return
        }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("Error: \(fileName).mp3 not found in bundle")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1  // Loop indefinitely
            player.volume = volume
            player.prepareToPlay()
            player.play()
            
            players[fileName] = player  // Store the player
        } catch {
            print("Error: Could not play \(fileName) - \(error.localizedDescription)")
        }
    }
}
