//
//  LiveWallpaperApp.swift
//  LiveWallpaper
//


import SwiftUI

@main
struct LiveWallpaperApp: App {
    
    let userSetting = UserSetting.shared
    
    
    var body: some Scene {
//        Window("Wallpaper",id: "MainWindow") {
//            ContentView()
//        }
//        .defaultSize(width:900, height:500)
//        .windowResizability(.contentMinSize) // Respect min frame size
        
        MenuBarExtra("Menu", systemImage: "shippingbox.fill") {
            MenuBarView()
        }
    }
    
    init() {
        runOnLaunch()
        DispatchQueue.main.async {
            if !UserSetting.shared.doNotShowWindow {
                WindowManager.showWindow()
                
            }
        }
    }
    
    func runOnLaunch(){
        print("applaunch \(userSetting.video)")
        if let url = constructURL(from: userSetting.video.url){
            WallpaperManager.shared.setWallpaperVideo(url: url)
        }
    }
    
    
}


struct MenuBarView: View {
    
    @ObservedObject var wallpaperManager = WallpaperManager.shared
    @ObservedObject var userSetting = UserSetting.shared
    
    var body: some View {
        VStack {
            Button("Open Main UI") {
                WindowManager.showWindow()
            }
            
            Divider()
            
            Toggle("Ambient Sounds", isOn: $userSetting.mixerEnabled)
                .toggleStyle(.checkbox)
            
            Button {
                wallpaperManager.toggleMute()
            } label: {
                HStack {
                    if wallpaperManager.player?.isMuted == true {
                        Text("Unmute Wallpaper")
                    } else {
                        Text("Mute Wallpaper")
                    }
                    
                }
            }
            .disabled(wallpaperManager.player == nil)
            
            Button {
                wallpaperManager.togglePlaying()
            } label: {
                HStack {
                    if wallpaperManager.player?.rate == 0 {
                        Text("Resume Wallpaper")
                    } else {
                        Text("Pause Wallpaper")
                    }
                    
                }
            }
            .disabled(wallpaperManager.player == nil)
            
            Divider()
            
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        
        
    }
    
//    private func openMainWindow() {
//        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "MainWindow" }) {
//            window.makeKeyAndOrderFront(nil)
//            NSApp.activate(ignoringOtherApps: true)
//        } else {
//            openWindow(id: "MainWindow")
//            NSApp.activate(ignoringOtherApps: true)
//        }
//        
//    }
}
