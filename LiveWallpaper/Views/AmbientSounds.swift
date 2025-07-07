import SwiftUI


struct AmbientSounds: View {
    
    @ObservedObject var userSetting = UserSetting.shared
    
    let columns = [GridItem(.adaptive(minimum: 150))]
    
    var body: some View {
        ZStack {
            
            VStack {
                Toggle("Enable Ambient Sounds Mixer", isOn: $userSetting.mixerEnabled)
                    .toggleStyle(.switch)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .padding(.horizontal, 30)
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach($userSetting.sounds, id: \.name) { $sound in
                            VStack {
                                Text(sound.name)
                                    .font(.headline)
                                    .foregroundColor(sound.isEnabled ? .white : .gray)
                                
                                if sound.isEnabled {
                                    Slider(value:$sound.volume, in: 0...1)
                                        .frame(width: 120)
                                }
                            }
                            .padding()
                            .frame(width: 150, height: 100)
                            .background(sound.isEnabled ? Color.accentColor : Color.secondary.opacity(0.5))
                            .cornerRadius(12)
                            .onTapGesture {
                                sound.isEnabled.toggle()
                            }
                        }
                    }
                    .padding()
                }
                .disabledStyle(!userSetting.mixerEnabled)
            }
            
        }
        .navigationTitle("Ambient Sounds")
        .frame(minWidth: 500, minHeight: 400)
    }
}

