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
    
    private var isPlayingBeforeSleep = false
    
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
        
        let workspace = NSWorkspace.shared.notificationCenter
        // Register for wake notification
        workspace.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        // Register for sleep notification
        workspace.addObserver(
            self,
            selector: #selector(handleSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        
    } // Singleton
    
    @objc private func handleWake() {
        print("System woke from sleep")
        // Your wake action here
        if isPlayingBeforeSleep {
            print("resume player")
            player?.play()
            objectWillChange.send()
        }
        
    }
    
    @objc private func handleSleep() {
        print("System is about to sleep")
        // Your sleep action here
        if player?.rate != 0 {
            isPlayingBeforeSleep = true
        } else {
            isPlayingBeforeSleep = false
        }
    }
    
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
    func setWallpaperVideo(video: Video) {
        guard let url = constructURL(from: video.url) else {return}
        
        if !isValidMovieFile(at: url){
            return
        }
        
        for track in player?.currentItem?.tracks ?? [] {
            removeSnapshot()
            track.isEnabled = true
            didAutoPaused = false
        }
        
        if window == nil {
            createWallpaperWindow()
        }
        
        let playerItem = AVPlayerItem(url: url)
        
        looper?.disableLooping()
        looper = nil
        player?.removeAllItems()
        player = AVQueuePlayer()
        looper = AVPlayerLooper(player: player!, templateItem: playerItem)
        
        let playerView = PlayerLayerView(player: player!, video: video)
        let hostView = NSHostingView(rootView: playerView)
        animateContentViewTransition(window: window, newContentView: hostView)
        
        player!.play()
    }
    

    private func animateContentViewTransition(window: NSWindow?, newContentView: NSView) {
        guard let window = window else {return}
        // Ensure both old and new views are layer-backed
        window.contentView?.wantsLayer = true
        newContentView.wantsLayer = true
        
        // Start with the new view invisible
        newContentView.alphaValue = 0
        
        // Temporarily add the new view as a subview of the current content view
        window.contentView?.addSubview(newContentView)
        
        // Match the new view's frame to the window's content view
        newContentView.frame = window.contentView?.bounds ?? .zero
        newContentView.autoresizingMask = [.width, .height]
        
        // Animate the transition
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5 // Adjust duration as needed (e.g., 0.5 seconds)
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            // Fade out the old content view
            window.contentView?.subviews.forEach { view in
                if view != newContentView {
                    view.animator().alphaValue = 0
                }
            }
            
            // Fade in the new content view
            newContentView.animator().alphaValue = 1
        } completionHandler: {
            // After animation, set the new view as the content view
            window.contentView = newContentView
            
            // Reset alpha to ensure consistency
            newContentView.alphaValue = 1
        }
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
        
        let showDarkLayer: Bool = {
            guard UserSetting.shared.adaptiveMode else { return false }

            let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark
            ? true: false
        }()
        
        if showDarkLayer {
            imageView.layer?.addSublayer(createAdaptiveDarkModeOverlay(rect: rootView.bounds, characteristics: UserSetting.shared.video.attrs))
        }
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

