import Cocoa
import SwiftUI
import AVKit

class WallpaperManager: ObservableObject {
    static let shared = WallpaperManager()
    
    private var window: NSWindow?
    @Published var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    
    private init() {} // Singleton
    
    /// Creates the wallpaper window if not already created
    private func createWallpaperWindow() {
        
        guard window == nil, let screen = NSScreen.main else { return }
        
        let newWindow = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow))) // Behind icons
        newWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        newWindow.ignoresMouseEvents = true
        newWindow.makeKeyAndOrderFront(nil)
        
        self.window = newWindow
    }
    
    /// Sets or updates the wallpaper video URL
    func setWallpaperVideo(url: URL) {
        if !isValidMovieFile(at: url){
            return
        }
        
        if window == nil {
            createWallpaperWindow()
        }
        
        let playerItem = AVPlayerItem(url: url)
        
        if player != nil {
            // If player exists, replace the current item
            looper = nil
            player?.removeAllItems()
            looper = AVPlayerLooper(player: player!, templateItem: playerItem)
        } else {
            // Otherwise, create a new looping player
            player = AVQueuePlayer()
            looper = AVPlayerLooper(player: player!, templateItem: playerItem)
            
            let playerView = AVPlayerView()
            playerView.player = player
            playerView.controlsStyle = .none
            playerView.videoGravity = .resizeAspectFill
            
            window?.contentView = NSHostingView(rootView: PlayerWrapper(playerView: playerView))
            
        }
        player!.play()
    }
    
    /// Mute or unmute the wallpaper video
    func toggleMute() {
        player?.isMuted.toggle()
        objectWillChange.send()
    }
    
    func togglePlaying() {
        if player?.rate == 0 {
            player?.play()
        } else {
            player?.pause()
        }
        objectWillChange.send()
    }
    
    func destroy(){
        looper = nil
        player?.removeAllItems()
        player = nil
        window?.contentView = nil
    }
    
    
}

struct PlayerWrapper: NSViewRepresentable {
    let playerView: AVPlayerView
    
    func makeNSView(context: Context) -> AVPlayerView {
        return playerView
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {}
}
