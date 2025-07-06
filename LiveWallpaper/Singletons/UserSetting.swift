//
//  UserSetting.swift
//  LiveWallpaper
//


import Foundation

struct Video: Codable, Equatable, Hashable {
    let id:String
    let url:String
    let type:VideoType
    let thumbnail:String
}

enum VideoType: String, Codable {
    case pixabay
    case local
    case youtube
}


struct Sound: Codable {
    var name:String
    var isEnabled: Bool
    var volume: Float
}

class UserSetting: ObservableObject {
    static let shared = UserSetting()
    
    @Published var video:Video = Video(id: "", url: "", type: .pixabay, thumbnail: "")
    @Published var recent:[Video] = []
    
    @Published var mixerEnabled = false {
        didSet {
            defaults.set(mixerEnabled, forKey: "mixerEnabled")
            AudioMixer.shared.process(mixerEnabled: mixerEnabled, sounds: sounds)
        }
    }
    
    @Published var sounds:[Sound] = [] {
        didSet {
            print("sounds did set")
            if let encoded = try? JSONEncoder().encode(sounds) {
                defaults.set(encoded, forKey: "sounds")
            }
            AudioMixer.shared.process(mixerEnabled: mixerEnabled, sounds: sounds)
        }
    }
    
    @Published var launchAtLogin = false {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
        }
    }
    
    @Published var doNotShowWindow = false {
        didSet {
            defaults.set(doNotShowWindow, forKey: "doNotShowWindow")
        }
    }
    
    var attemptId = ""
    
    private let defaults = UserDefaults.standard
    
    init(){
        self.video = getVideo()
        self.recent = getRecent()
        self.mixerEnabled = getMixerEnabled()
        self.sounds = getSounds()
        self.launchAtLogin = getlaunchAtLogin()
        self.doNotShowWindow = getdoNotShowWindow()
    }

    
    func setVideo(_ video: Video) {
        if let encoded = try? JSONEncoder().encode(video) {
            defaults.set(encoded, forKey: "video")
            self.video = video
        }
        
        var recent = getRecent()
        if !recent.contains(video) {
            recent.append(video)
            if let encoded = try? JSONEncoder().encode(recent) {
                defaults.set(encoded, forKey: "recent")
                self.recent = recent
            }
        }
    }
    
    func resetVideoAndRecent(){
        video = Video(id: "", url: "", type: .pixabay, thumbnail: "")
        recent = []
        if let encoded = try? JSONEncoder().encode(video) {
            defaults.set(encoded, forKey: "video")
        }
        if let encoded = try? JSONEncoder().encode(recent) {
            defaults.set(encoded, forKey: "recent")
        }
    }
    
    func getVideo() -> Video {
        if let savedData = defaults.data(forKey: "video"),
           let video = try? JSONDecoder().decode(Video.self, from: savedData) {
            return video
        }
        return Video(id: "", url: "", type: .pixabay, thumbnail: "")
    }
    
    func getRecent() -> [Video] {
        if let savedData = defaults.data(forKey: "recent"),
           let videos = try? JSONDecoder().decode([Video].self, from: savedData) {
            return videos
        }
        return []
    }
    
    func getMixerEnabled() -> Bool {
        return defaults.bool(forKey: "mixerEnabled")
    }
    
    func getlaunchAtLogin() -> Bool {
        return defaults.bool(forKey: "launchAtLogin")
    }
    
    func getdoNotShowWindow() -> Bool {
        return defaults.bool(forKey: "doNotShowWindow")
    }
    
    func getSounds() -> [Sound] {
        if let savedData = defaults.data(forKey: "sounds"),
           let sounds = try? JSONDecoder().decode([Sound].self, from: savedData) {
            return sounds
        }
        
        let mp3s = [
            "rain","thunder","fire", "beach", "seagull",
            "wind", "bird", "creek", "cricket", "snow",
            "firework", "foghorn","fan", "owls", "palm",
            "playground", "coffee", "restaurant",
             "train",  "wolves", "bowl", "chimes",
        ]
        
        for mp3 in mp3s {
            sounds.append(Sound(name: mp3, isEnabled: false, volume: 0.5))
        }
        return sounds
    }
    
    

}
