//
//  Recents.swift
//  LiveWallpaper
//


import SwiftUI

struct Recent: View {
    
    init() {
        print("DetailView initialized")
    }
    
    @ObservedObject var userSetting = UserSetting.shared
    
    
    let columns = [
        GridItem(.adaptive(minimum: 200), spacing: 10)
    ]
    
    var body: some View {
        VStack(spacing: 10) {
            
            if userSetting.recent.isEmpty {
                VStack {
                    Text("Nothing here yet.")
                        .frame(maxWidth: 300)
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text(
                    """
                    If you don't have a suitable video, check out Pexels and Pixabay.
                    They offer high-quality, visually stunning videos for free.
                    """)
                    .frame(maxWidth: 300)
                    .foregroundStyle(.tertiary)
                    .font(.title2)
                    .padding()
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(userSetting.recent.reversed(), id: \.self.id) { video in
                            RecentVideoView(video: video)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(String(video.id) == userSetting.video.id ? Color.accentColor : Color.clear, lineWidth: 4)
                                )
                                .onTapGesture {
                                    print(video)
                                    WallpaperManager.shared.setWallpaperVideo(video: video)
                                    UserSetting.shared.setVideo(video)
                                    
                                }
                        }
                    }
                    .padding(8)
                }
                .padding()
            }
            
        }
        .frame(minWidth: 500, minHeight: 400)
        .navigationTitle("Recently Used")
        
        
        
    }
    
    
}


#Preview {
    Recent()
}
