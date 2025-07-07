import SwiftUI
import AVKit

enum NavItem: String, CaseIterable {
    case localVideo = "Add Video"
    case recent = "Recents"
    case ambientMixer = "Ambient Sounds"
    case settings = "Settings"
}

struct ContentView: View {
    @State var selectedItem:NavItem? = .recent
    
    let recent = Recent()
    let ambientSounds = AmbientSounds()
    
    var selectedView: some View {
        if selectedItem == .recent {
            AnyView(recent)
        } else if selectedItem == .localVideo {
            AnyView(VideoDropView())
        } else if selectedItem == .ambientMixer {
            AnyView(ambientSounds)
        } else {
            AnyView(SettingView())
        }
    }
    
    var body: some View {
        
        ZStack {
            VStack {
                NavigationView {
                    List(NavItem.allCases, id: \.self) { item in
                        NavigationLink(destination: selectedView, tag: item, selection: $selectedItem) {
                            HStack {
                                Text(item.rawValue)
                                Spacer()
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                    .padding(.top, 0)
                    .frame(minWidth: 200)
                }
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button(action: toggleSidebar) {
                            Image(systemName: "sidebar.left")
                        }
                    }
                }
            }
        }
        
    }
    
   
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

#Preview {
    ContentView()
}
