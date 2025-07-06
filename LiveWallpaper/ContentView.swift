import SwiftUI
import AVKit

enum NavItem: String, CaseIterable {
    case localVideo = "Add Video"
    case recent = "Recents"
    case ambientMixer = "Ambient Sounds"
    case settings = "Settings"
}

struct ContentView: View {
    @State var selectedItem:NavItem = .recent
    
    let recent = Recent()
    let ambientSounds = AmbientSounds()
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedItem) { // Bind selection
                ForEach(NavItem.allCases, id: \.self) { item in
                    Text(item.rawValue)
                        .tag(item.rawValue) // Tag is necessary for selection tracking
                }
            }
            .navigationSplitViewColumnWidth(ideal:200)
            
            .listStyle(SidebarListStyle()) // Makes it look more like Finder's sidebar
        } detail: {
            if selectedItem == .recent {
                recent
            } else if selectedItem == .localVideo {
                VideoDropView()
            } else if selectedItem == .ambientMixer {
                ambientSounds
            } else {
                SettingView()
            }
        }
        
    }
}

#Preview {
    ContentView()
}
