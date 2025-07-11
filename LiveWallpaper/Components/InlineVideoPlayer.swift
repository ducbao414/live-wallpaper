//
//  InlineVideoPlayer.swift
//  LiveWallpaper
//


import SwiftUI
import AVKit

struct InlineVideoPlayer: NSViewRepresentable {
    let url: URL
    
    class Coordinator {
        var player: AVPlayer?
        
        init(player: AVPlayer?) {
            self.player = player
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(player: nil)
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        let player = AVPlayer(url: url)
        let playerLayer = AVPlayerLayer(player: player)
        
        for track in player.currentItem?.tracks ?? [] {
            if track.assetTrack?.hasMediaCharacteristic(.audible) == true {
                track.isEnabled = false
            }
        }
        player.volume = 0.0
        
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = view.bounds
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
        view.layer = CALayer()
        view.layer?.addSublayer(playerLayer)
        
        player.play() // Auto play
        context.coordinator.player = player // Store player in coordinator
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.player?.pause() // Stop video when view is removed
        coordinator.player = nil
    }
}

