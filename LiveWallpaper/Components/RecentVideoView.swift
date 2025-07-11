
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
                .scaledToFill()
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
            
        }
        .frame(width:200, height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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

