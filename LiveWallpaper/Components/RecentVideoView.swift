
//
//  RecentVideoView'.swift
//  LiveWallpaper
//


import SwiftUI
import AVKit

struct RecentVideoView: View {
    @State var video:Video
    
    @State private var isHovered = false
    @State private var hoverTask: DispatchWorkItem?
    
    var body: some View {
        ZStack {
            CachedAsyncImage(
                url: constructURL(from: video.thumbnail)!,
                size: CGSize(width: 200, height: 150)
            ) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 200, height: 150)
            }
            if isHovered {
                let videoURL = constructURL(from: video.url)
                
                InlineVideoPlayer(url: videoURL!)
                    .frame(width: 200, height: 150)
                    .clipped()
            }
            
        }
        .frame(width:200, height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            print(video)
            WallpaperManager.shared.setWallpaperVideo(url: constructURL(from: video.url)!)
            UserSetting.shared.setVideo(video)
            
        }
        .onHover { hovering in
            if hovering {
                startHoverDelay()
            } else {
                cancelHoverDelay()
                isHovered = false
            }
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

