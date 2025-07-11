
//
//  RecentVideoView'.swift
//  LiveWallpaper
//


import SwiftUI
import AVKit

struct ThumbnailImage: View {
    let path: String

    var body: some View {
        if let image = NSImage(contentsOfFile: path) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 200, height: 150)
                .clipped()
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 200, height: 150)
        }
    }
}

struct RecentVideoView: View {
    let video:Video
    
    @State private var isHovered = false
    @State private var hoverTask: DispatchWorkItem?
    
    @State private var showDeleteBtn = false
    var body: some View {
        ZStack {
            
            ThumbnailImage(path: video.thumbnail)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(Rectangle())
            
            if isHovered {
                let videoURL = constructURL(from: video.url)
                
                InlineVideoPlayer(url: videoURL!)
                    .frame(width: 200, height: 150)
                    .clipped()
            }
            
            if showDeleteBtn {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "trash.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .padding(10)
                            .background(.thinMaterial, in: Circle())
                            .foregroundColor(.white)
                            .onTapGesture {
                                confirmAndDeleteVideo(video)
                            }
                            .padding()
                    
                    }
                    Spacer()
                }
            }
            
        }
        .frame(width:200, height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onHover { hovering in
            
            if hovering {
                startHoverDelay()
                showDeleteBtn = true
            } else {
                cancelHoverDelay()
                isHovered = false
                showDeleteBtn = false
            }
        }
    }
    
    private func confirmAndDeleteVideo(_ video: Video) {
        let alert = NSAlert()
        alert.messageText = "Remove Wallpaper"
        alert.informativeText = "Removing this wallpaper won't delete your original video file. Your original video will remain intact."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn { // "OK" button
            do {
                // try resetDirectory(at: path)
                if video == UserSetting.shared.video {
                    WallpaperManager.shared.destroy()
                    
                    let empty = Video(id: "", url: "", type: .pixabay, thumbnail: "")
                    UserSetting.shared.video = empty
                    
                    if let encoded = try? JSONEncoder().encode(empty) {
                        UserDefaults.standard.set(encoded, forKey: "video")
                    }
                }
                
                UserSetting.shared.deleteVideo(video)
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        } else {
            print("Operation canceled.")
        }
    }
    
    private func startHoverDelay() {
        // Cancel any existing scheduled task
        hoverTask?.cancel()
        
        let task = DispatchWorkItem {
            isHovered = true
        }
        hoverTask = task
        
        // Delay execution
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: task) // 2 seconds delay
    }
    
    private func cancelHoverDelay() {
        hoverTask?.cancel()
        hoverTask = nil
    }
    
}

