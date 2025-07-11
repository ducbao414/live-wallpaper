//
//  Settings.swift
//  LiveWallpaper
//


import SwiftUI

struct SettingView: View {
    
    @ObservedObject var userSetting = UserSetting.shared
    
    
    var body: some View {
        ScrollView {
            VStack {
                Text("General")
                    .fontWeight(.bold)
                    .frame(maxWidth:.infinity, alignment: .leading)
                    .padding(.vertical, 10)
                
//                Toggle("Launch at login", isOn: $userSetting.launchAtLogin)
//                    .toggleStyle(.checkbox)
//                    .frame(maxWidth: .infinity, alignment: .leading)
                
                
                Toggle("Do not show this window when launch", isOn: $userSetting.doNotShowWindow)
                    .toggleStyle(.checkbox)
                    .frame(maxWidth: .infinity, alignment: .leading)
//                shippingbox.fill
                Text("\(appDisplayName()) will run in the background.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                (
                    Text("You can access its main UI through this ")
                    + Text(Image(systemName: "shippingbox.fill"))
                    + Text(" icon on the menubar.")
                ).frame(maxWidth: .infinity, alignment: .leading)
                
                Toggle("Power Saving Mode", isOn: $userSetting.powerSaver)
                    .toggleStyle(.checkbox)
                    .padding(.top)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("""
                    The video wallpaper's rendering will automatically pause when its window is fully (or near fully) obscured by other applications, reducing GPU/CPU usage and power consumption. 
                    Audio playback remains active.
                    """)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Toggle("Adaptive Theme", isOn: $userSetting.adaptiveMode)
                    .toggleStyle(.checkbox)
                    .padding(.top)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("""
                    Adapt to your device dark/light theme
                    """)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("App Data")
                    .fontWeight(.bold)
                    .frame(maxWidth:.infinity, alignment: .leading)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                
                HStack {
                    Text("Added videos may take up space on your hard drive. Click the button below to clean them up.")
                        .frame(maxWidth:400, alignment: .leading)
                    Spacer()
                }
                HStack {
                    Button {
                        confirmAndClearAppData()
                    } label: {
                        Text("Clear App Data")
                            .foregroundStyle(.red)
                    }
                    .padding(.top, 5)
                    
                    Spacer()
                }
                
                
                
                
                
            }
        }
        
        .padding()
        .navigationTitle("Settings")
        .frame(minWidth: 500, minHeight: 400)
    }
    
    func copyToClipboard(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
    
    func confirmAndClearAppData() {
        let alert = NSAlert()
        alert.messageText = "Clear App Data"
        alert.informativeText = "This will delete added videos and other settings. Are you sure to continue?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn { // "OK" button
            do {
                // try resetDirectory(at: path)
                WallpaperManager.shared.destroy()
                UserSetting.shared.resetVideoAndRecent()
                try recreateAppDataFolder()
                print("Directory reset successfully.")
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        } else {
            print("Operation canceled.")
        }
    }

}

