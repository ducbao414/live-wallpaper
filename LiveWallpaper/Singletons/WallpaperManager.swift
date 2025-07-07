import Cocoa
import SwiftUI
import AVKit

class WallpaperManager: ObservableObject {
    static let shared = WallpaperManager()
    
    private var window: NSWindow?
    @Published var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    
    private var timer:Timer?
    private var didAutoPaused = false
    
    private init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    // Call the function on the main thread
            DispatchQueue.main.async {
                if isOvercast() {
                    self?.autoPauseVideo()
                } else {
                    self?.autoResumeVideo()
                }
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
        
        print("WallpaperManager init")
        
    } // Singleton
    
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
    
    private func autoPauseVideo(){
        if UserSetting.shared.powerSaver && !didAutoPaused {
            for track in player?.currentItem?.tracks ?? [] {
                if track.assetTrack?.hasMediaCharacteristic(.visual) == true {
                    takeSnapshot()
                    track.isEnabled = false
                    didAutoPaused = true
                    print("auto paused")
                }
            }
        }
    }
    
    private func autoResumeVideo(){
        if didAutoPaused {
            for track in player?.currentItem?.tracks ?? [] {
                removeSnapshot()
                track.isEnabled = true
                didAutoPaused = false
                print("auto resumed")
            }
        }
    }
    
    private func takeSnapshot(){
        guard let playerItem = player?.currentItem,
              let rootView = window?.contentView else {
            return
        }
        // Take a snapshot of the current frame
        let generator = AVAssetImageGenerator(asset: playerItem.asset)
        generator.appliesPreferredTrackTransform = true
        let time = playerItem.currentTime()
        
        let image = try? generator.copyCGImage(at: time, actualTime: nil)
        let snapshot = image.map { NSImage(cgImage: $0, size: .zero) }


        // Overlay the snapshot to simulate a frozen frame
        let imageView = NSImageViewFill()
        imageView.image = snapshot
        imageView.frame = rootView.bounds
        imageView.autoresizingMask = [.width, .height]
        imageView.identifier = NSUserInterfaceItemIdentifier("SnapshotOverlay")

        // Add to root view
        rootView.addSubview(imageView, positioned: .above, relativeTo: nil)
    }
    
    private func removeSnapshot(){
        guard let rootView = window?.contentView else {
            return
        }
        for subview in rootView.subviews {
            if subview.identifier?.rawValue == "SnapshotOverlay" {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.5
                    subview.animator().alphaValue = 0
                }, completionHandler: {
                    subview.removeFromSuperview()
                })
            }
        }
    }
    
    
}

struct PlayerWrapper: NSViewRepresentable {
    let playerView: AVPlayerView
    
    func makeNSView(context: Context) -> AVPlayerView {
        return playerView
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {}
}


class NSImageViewFill : NSImageView {
        
        open override var image: NSImage? {
            set {
                self.layer = CALayer()
                self.layer?.contentsGravity = CALayerContentsGravity.resizeAspectFill
                self.layer?.contents = newValue
                self.wantsLayer = true
                
                super.image = newValue
            }
            
            get {
                return super.image
            }
        }
}

